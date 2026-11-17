-- JCV · Encuesta de Bienestar de Jóvenes (AMG) + bitácora del asistente.
-- Vive en el proyecto Supabase de CCL DEV, aislado en el schema jcv.
-- Idempotente: se puede correr dos veces.
--
-- Seguridad: las tablas no tienen permisos para nadie más que su dueño y
-- tienen RLS sin políticas (niega todo). Solo se entra por las funciones
-- SECURITY DEFINER de abajo, y hoy solo service_role (la Edge Function)
-- puede ejecutarlas. Del cliente nunca salen filas, solo agregados.
--
-- Después de correrla: Dashboard → Settings → API → Exposed schemas → agregar jcv.

create schema if not exists jcv;

-- Catálogo de preguntas (sale del diccionario de JCV).
create table if not exists jcv.preguntas (
  variable text primary key,                 -- 'Q_6', 'T_Q_11_1', ...
  orden    integer not null,                 -- orden del cuestionario
  tema     text not null check (tema in (
             'bienestar', 'educacion-trabajo', 'tiempo-libre', 'hogar-familia',
             'salud', 'seguridad', 'comunidad', 'transporte')),
  texto    text not null,
  opciones jsonb not null                    -- [{"codigo": 1, "etiqueta": "..."}] en orden
);

-- Una fila por persona encuestada. Códigos iguales a FilterCatalog de la app.
-- No se guarda colonia, fecha, duración ni respuestas abiertas.
create table if not exists jcv.personas (
  id        integer primary key,
  fuente    text not null check (fuente in ('AMG', 'TEC')),
  municipio text check (municipio in ('GDL', 'ZAP', 'TLQ', 'TON', 'TLJ', 'ELS')),
  edad      text check (edad in ('15-19', '20-24', '25-29')),
  sexo      text check (sexo in ('F', 'M', 'O')),
  estrato   text check (estrato in ('BAJO', 'MEDIO', 'ALTO')),
  factor    numeric not null check (factor > 0)  -- factor de expansión
);

-- Formato largo: una fila por persona y pregunta contestada.
create table if not exists jcv.respuestas (
  variable   text not null references jcv.preguntas (variable),
  persona_id integer not null references jcv.personas (id) on delete cascade,
  valor      smallint not null,
  primary key (variable, persona_id)          -- también es el índice de jcv.grafica
);

-- Cada pregunta que le hacen al asistente. Anónima: la IP va con hash y sal.
create table if not exists jcv.bitacora (
  id            bigint generated always as identity primary key,
  creado        timestamptz not null default now(),
  ip_hash       text not null,
  pregunta      text not null check (length(pregunta) between 1 and 300),
  bloqueada     boolean not null default false,  -- excedió el límite por minuto
  variable      text,                            -- pregunta de la encuesta que usó Haiku
  uso_plantilla boolean                          -- true: se descartó el texto de Haiku
);
create index if not exists bitacora_ip_creado_idx on jcv.bitacora (ip_hash, creado);

alter table jcv.preguntas  enable row level security;
alter table jcv.personas   enable row level security;
alter table jcv.respuestas enable row level security;
alter table jcv.bitacora   enable row level security;


-- Porcentajes ponderados con el factor de expansión, contando "No sabe/No
-- contestó" en la base, igual que los cruces que publica JCV. n es sin ponderar.
-- muestra_pequena: n < 30 (aviso). insuficiente: Tec con n < 30, no se publican
-- porcentajes (umbral de privacidad). Regresa null si la variable no existe.
create or replace function jcv.grafica(
  p_variable  text,
  p_fuente    text default 'AMG',
  p_municipio text default null,
  p_edad      text default null,
  p_sexo      text default null,
  p_estrato   text default null
) returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with base as (
    select r.valor, p.factor
    from jcv.respuestas r
    join jcv.personas p on p.id = r.persona_id
    where r.variable = p_variable
      and p.fuente = p_fuente
      and (p_municipio is null or p.municipio = p_municipio)
      and (p_edad      is null or p.edad      = p_edad)
      and (p_sexo      is null or p.sexo      = p_sexo)
      and (p_estrato   is null or p.estrato   = p_estrato)
  ),
  total as (
    select count(*)::int as n, sum(factor) as peso,
           (p_fuente = 'TEC' and count(*) < 30) as insuficiente
    from base
  ),
  conteo as (
    select valor, sum(factor) as peso from base group by valor
  )
  select jsonb_build_object(
    'variable', q.variable,
    'tema', q.tema,
    'texto', q.texto,
    'fuente', p_fuente,
    'n', t.n,
    'muestra_pequena', t.n < 30,
    'insuficiente', t.insuficiente,
    'opciones', (
      select jsonb_agg(
               jsonb_build_object(
                 'codigo', (o ->> 'codigo')::int,
                 'etiqueta', o ->> 'etiqueta',
                 'porcentaje', case
                   when t.insuficiente or t.n = 0 then null
                   else round(100 * coalesce(c.peso, 0) / t.peso, 1)
                 end)
               order by e.ord)
      from jsonb_array_elements(q.opciones) with ordinality as e (o, ord)
      left join conteo c on c.valor = (o ->> 'codigo')::int
    )
  )
  from jcv.preguntas q
  cross join total t
  where q.variable = p_variable
    and p_fuente in ('AMG', 'TEC');
$$;

-- Catálogo para el system prompt del asistente.
create or replace function jcv.catalogo()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(
           jsonb_build_object(
             'variable', variable,
             'tema', tema,
             'texto', texto,
             'opciones', (select jsonb_agg(o ->> 'etiqueta') from jsonb_array_elements(opciones) o))
           order by orden), '[]'::jsonb)
  from jcv.preguntas;
$$;

-- Registra la pregunta y aplica el límite: 10 por minuto por IP.
-- Regresa el id de la bitácora, o null si esa IP ya pasó el límite.
-- Las bloqueadas también se guardan, así quien insiste sigue bloqueado.
create or replace function jcv.anotar_pregunta(p_ip_hash text, p_pregunta text)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_bloqueada boolean;
  v_id bigint;
begin
  select count(*) >= 10 into v_bloqueada
  from jcv.bitacora
  where ip_hash = p_ip_hash and creado > now() - interval '1 minute';

  insert into jcv.bitacora (ip_hash, pregunta, bloqueada)
  values (p_ip_hash, left(p_pregunta, 300), v_bloqueada)
  returning id into v_id;

  return case when v_bloqueada then null else v_id end;
end;
$$;

-- Al terminar: qué pregunta de la encuesta se usó y si cayó a plantilla.
create or replace function jcv.completar_pregunta(
  p_id bigint, p_variable text, p_uso_plantilla boolean
) returns void
language sql
security definer
set search_path = ''
as $$
  update jcv.bitacora
  set variable = p_variable, uso_plantilla = p_uso_plantilla
  where id = p_id;
$$;


-- Permisos. Al final y explícitos: CREATE OR REPLACE / DROP pueden dejar
-- EXECUTE a PUBLIC (la trampa de v6.20 en CCL).
revoke all on schema jcv from public, anon, authenticated;
revoke all on all tables in schema jcv from public, anon, authenticated, service_role;
revoke all on all functions in schema jcv from public, anon, authenticated;
alter default privileges in schema jcv revoke execute on functions from public;

grant usage on schema jcv to service_role;
grant execute on function
  jcv.grafica(text, text, text, text, text, text),
  jcv.catalogo(),
  jcv.anotar_pregunta(text, text),
  jcv.completar_pregunta(bigint, text, boolean)
  to service_role;
