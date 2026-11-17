-- JCV v1.02 · La pestaña Datos lee la base real con la anon key.
--
-- Umbrales (privacidad, también para el chat):
--   AMG con menos de 10 respuestas: no se publican porcentajes. Con 4 filtros
--     se llega a n = 1 y hay preguntas sensibles (golpes en casa, discriminación
--     por orientación sexual): mostrarlo sería revelar lo que contestó alguien.
--   AMG de 10 a 29: se muestra con aviso de muestra pequeña (RF-DAT-07).
--   Tec con menos de 30: ni porcentajes ni n exacto (RF-DAT-04 y RF-DAT-06).
--
-- anon puede ejecutar grafica, graficas y contar (solo agregados). Las tablas
-- siguen sin permisos para nadie. Idempotente.

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
           (count(*) < case when p_fuente = 'TEC' then 30 else 10 end) as insuficiente
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
    'n', case when p_fuente = 'TEC' and t.insuficiente then null else t.n end,
    'muestra_pequena', t.n < 30,
    'insuficiente', t.insuficiente,
    'opciones', (
      select jsonb_agg(
               jsonb_build_object(
                 'codigo', (o ->> 'codigo')::int,
                 'etiqueta', o ->> 'etiqueta',
                 'porcentaje', case
                   when t.insuficiente then null
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

-- Varias gráficas en una llamada (una temática completa). Tope de 40 para que
-- nadie pida las 172 de golpe. Las variables que no existen se omiten.
create or replace function jcv.graficas(
  p_variables text[],
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
  select coalesce(jsonb_agg(g order by ord), '[]'::jsonb)
  from unnest(p_variables[1:40]) with ordinality as t (variable, ord)
  cross join lateral jcv.grafica(t.variable, p_fuente, p_municipio, p_edad, p_sexo, p_estrato) as g
  where g is not null;
$$;

-- Cuántas personas cumplen los filtros (contador de la hoja de filtros).
-- Tec bajo el umbral: n = null, nunca el número exacto.
create or replace function jcv.contar(
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
  with c as (
    select count(*)::int as n
    from jcv.personas p
    where p.fuente = p_fuente
      and (p_municipio is null or p.municipio = p_municipio)
      and (p_edad      is null or p.edad      = p_edad)
      and (p_sexo      is null or p.sexo      = p_sexo)
      and (p_estrato   is null or p.estrato   = p_estrato)
  )
  select jsonb_build_object(
    'n', case when p_fuente = 'TEC' and c.n < 30 then null else c.n end,
    'umbral', case when p_fuente = 'TEC' then 30 else 10 end,
    'bajo_umbral', c.n < case when p_fuente = 'TEC' then 30 else 10 end
  )
  from c
  where p_fuente in ('AMG', 'TEC');
$$;


-- Permisos: mismo bloque que v1.01 más lo público de esta versión.
revoke all on schema jcv from public, anon, authenticated;
revoke all on all tables in schema jcv from public, anon, authenticated, service_role;
revoke all on all functions in schema jcv from public, anon, authenticated;
alter default privileges in schema jcv revoke execute on functions from public;

grant usage on schema jcv to service_role, anon;
grant execute on function
  jcv.grafica(text, text, text, text, text, text),
  jcv.catalogo(),
  jcv.anotar_pregunta(text, text, text),
  jcv.completar_pregunta(bigint, text, boolean, boolean),
  jcv.cache_leer(text),
  jcv.cache_guardar(text, jsonb),
  jcv.graficas(text[], text, text, text, text, text),
  jcv.contar(text, text, text, text, text)
  to service_role;
grant execute on function
  jcv.grafica(text, text, text, text, text, text),
  jcv.graficas(text[], text, text, text, text, text),
  jcv.contar(text, text, text, text, text)
  to anon;
