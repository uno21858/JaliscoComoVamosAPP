-- JCV v1.01 · Límite por dispositivo y caché de respuestas.
--
-- Límites (ventana móvil):
--   dispositivo: 10 por minuto y 20 respuestas por día. El id lo genera la app
--                y lo guarda en el teléfono; llega con hash, igual que la IP.
--   IP:          60 por minuto y 1000 por día. Alto a propósito: en la demo
--                todos comparten la Wi-Fi del Tec. Solo frena scripts que
--                inventan ids de dispositivo desde una misma IP.
--   El tope real de dinero es el límite de gasto en la consola de Anthropic.
--
-- Caché: la misma pregunta (normalizada, sin historial) no vuelve a llamar a Haiku.
-- Idempotente. Cambia firmas: DROP + permisos explícitos al final.

alter table jcv.bitacora add column if not exists dispositivo_hash text;
alter table jcv.bitacora add column if not exists desde_cache boolean not null default false;
create index if not exists bitacora_dispositivo_creado_idx on jcv.bitacora (dispositivo_hash, creado);

create table if not exists jcv.cache_respuestas (
  clave     text primary key,      -- versión del prompt + pregunta normalizada
  respuesta jsonb not null,        -- { texto, tema, figura, variable, uso_plantilla }
  creado    timestamptz not null default now()
);
alter table jcv.cache_respuestas enable row level security;


-- Regresa {"id": n} si puede preguntar, o {"bloqueo": "minuto" | "dia"}.
-- El día cuenta solo preguntas respondidas; el minuto cuenta también los
-- intentos bloqueados, así quien insiste sigue bloqueado.
drop function if exists jcv.anotar_pregunta(text, text);
create or replace function jcv.anotar_pregunta(p_ip_hash text, p_dispositivo_hash text, p_pregunta text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_bloqueo text;
  v_id bigint;
begin
  select case
           when count(*) filter (where creado > now() - interval '1 minute') >= 10 then 'minuto'
           when count(*) filter (where not bloqueada) >= 20 then 'dia'
         end
  into v_bloqueo
  from jcv.bitacora
  where dispositivo_hash = p_dispositivo_hash and creado > now() - interval '1 day';

  if v_bloqueo is null then
    select case
             when count(*) filter (where creado > now() - interval '1 minute') >= 60 then 'minuto'
             when count(*) filter (where not bloqueada) >= 1000 then 'dia'
           end
    into v_bloqueo
    from jcv.bitacora
    where ip_hash = p_ip_hash and creado > now() - interval '1 day';
  end if;

  insert into jcv.bitacora (ip_hash, dispositivo_hash, pregunta, bloqueada)
  values (p_ip_hash, p_dispositivo_hash, left(p_pregunta, 300), v_bloqueo is not null)
  returning id into v_id;

  return case when v_bloqueo is null
              then jsonb_build_object('id', v_id)
              else jsonb_build_object('bloqueo', v_bloqueo) end;
end;
$$;

drop function if exists jcv.completar_pregunta(bigint, text, boolean);
create or replace function jcv.completar_pregunta(
  p_id bigint, p_variable text, p_uso_plantilla boolean, p_desde_cache boolean
) returns void
language sql
security definer
set search_path = ''
as $$
  update jcv.bitacora
  set variable = p_variable, uso_plantilla = p_uso_plantilla, desde_cache = p_desde_cache
  where id = p_id;
$$;

create or replace function jcv.cache_leer(p_clave text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select respuesta from jcv.cache_respuestas where clave = p_clave;
$$;

create or replace function jcv.cache_guardar(p_clave text, p_respuesta jsonb)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into jcv.cache_respuestas (clave, respuesta)
  values (p_clave, p_respuesta)
  on conflict (clave) do nothing;
$$;


-- Permisos: mismo bloque que v1.00, con las firmas nuevas.
revoke all on schema jcv from public, anon, authenticated;
revoke all on all tables in schema jcv from public, anon, authenticated, service_role;
revoke all on all functions in schema jcv from public, anon, authenticated;
alter default privileges in schema jcv revoke execute on functions from public;

grant usage on schema jcv to service_role;
grant execute on function
  jcv.grafica(text, text, text, text, text, text),
  jcv.catalogo(),
  jcv.anotar_pregunta(text, text, text),
  jcv.completar_pregunta(bigint, text, boolean, boolean),
  jcv.cache_leer(text),
  jcv.cache_guardar(text, jsonb)
  to service_role;
