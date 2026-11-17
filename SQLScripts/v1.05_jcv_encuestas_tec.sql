-- JCV v1.05 · Encuestas del Tec con las mismas preguntas del AMG.
--
-- Las respuestas se guardan como fuente 'TEC' en jcv.personas y jcv.respuestas,
-- así jcv.grafica las compara solas con el AMG (desde 30 respuestas, v1.02).
--
-- Privacidad (RF-ENC-09): la marca de "ya contestó" (jcv.encuestas_hechas) y
-- las respuestas van en tablas distintas, sin nada que las ligue. El
-- dispositivo y la IP solo se guardan con hash.
--
-- Sin login (por ahora): una vez por encuesta y dispositivo, y tope de 300
-- envíos por hora por IP (en la demo todos comparten la Wi-Fi del Tec).
-- Reinstalando la app se podría contestar otra vez; se cierra con Cognito.
-- Idempotente.

create sequence if not exists jcv.personas_tec_id start 10000001;

create table if not exists jcv.encuestas_hechas (
  dispositivo_hash text not null,
  encuesta         text not null,
  ip_hash          text not null,
  creado           timestamptz not null default now(),
  primary key (dispositivo_hash, encuesta)
);
create index if not exists encuestas_hechas_ip_creado_idx on jcv.encuestas_hechas (ip_hash, creado);
alter table jcv.encuestas_hechas enable row level security;

-- Guarda una encuesta contestada. Regresa 'ok' o 'ya_contestada'.
-- Entrada inválida: error 22023. Demasiados envíos desde una IP: error P0429.
create or replace function jcv.guardar_encuesta(
  p_dispositivo text,
  p_encuesta    text,
  p_edad        integer,
  p_sexo        text,
  p_municipio   text,
  p_respuestas  jsonb
) returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_dispositivo_hash text;
  v_ip_hash text;
  v_persona integer;
  v_invalidas integer;
begin
  if p_dispositivo !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
     or p_encuesta !~ '^tec-[a-z-]{1,30}$'
     or p_edad is null or p_edad not between 18 and 29
     or (p_sexo is not null and p_sexo not in ('F', 'M', 'O'))
     or (p_municipio is not null and p_municipio not in ('GDL', 'ZAP', 'TLQ', 'TON', 'TLJ', 'ELS'))
     or jsonb_typeof(p_respuestas) is distinct from 'object'
     or (select count(*) from jsonb_object_keys(p_respuestas)) not between 1 and 40 then
    raise exception 'encuesta inválida' using errcode = '22023';
  end if;

  -- Cada respuesta: una pregunta que existe y un código que es de sus opciones.
  select count(*) into v_invalidas
  from jsonb_each(p_respuestas) as r (variable, valor)
  left join jcv.preguntas q on q.variable = r.variable
  where q.variable is null
     or jsonb_typeof(r.valor) <> 'number'
     or not exists (
       select 1 from jsonb_array_elements(q.opciones) o
       where (o ->> 'codigo')::int = (r.valor #>> '{}')::numeric
     );
  if v_invalidas > 0 then
    raise exception 'respuestas inválidas' using errcode = '22023';
  end if;

  v_dispositivo_hash := encode(extensions.digest('jcv:' || lower(p_dispositivo), 'sha256'), 'hex');
  v_ip_hash := encode(extensions.digest('jcv:' || coalesce(
    split_part(current_setting('request.headers', true)::json ->> 'x-forwarded-for', ',', 1), 'sin-ip'),
    'sha256'), 'hex');

  if (select count(*) from jcv.encuestas_hechas
      where ip_hash = v_ip_hash and creado > now() - interval '1 hour') >= 300 then
    raise exception 'demasiados envíos' using errcode = 'P0429';
  end if;

  insert into jcv.encuestas_hechas (dispositivo_hash, encuesta, ip_hash)
  values (v_dispositivo_hash, p_encuesta, v_ip_hash)
  on conflict do nothing;
  if not found then
    return 'ya_contestada';
  end if;

  insert into jcv.personas (id, fuente, municipio, edad, sexo, estrato, factor)
  values (
    nextval('jcv.personas_tec_id'), 'TEC', p_municipio,
    case when p_edad <= 19 then '15-19' when p_edad <= 24 then '20-24' else '25-29' end,
    p_sexo, null, 1)
  returning id into v_persona;

  insert into jcv.respuestas (variable, persona_id, valor)
  select r.variable, v_persona, (r.valor #>> '{}')::smallint
  from jsonb_each(p_respuestas) as r (variable, valor);

  return 'ok';
end;
$$;

-- Permisos: la secuencia y la tabla nueva, cerradas; solo la función.
revoke all on sequence jcv.personas_tec_id from public, anon, authenticated;
revoke all on jcv.encuestas_hechas from public, anon, authenticated, service_role;
revoke all on function jcv.guardar_encuesta(text, text, integer, text, text, jsonb) from public;
grant execute on function jcv.guardar_encuesta(text, text, integer, text, text, jsonb)
  to anon, service_role;
