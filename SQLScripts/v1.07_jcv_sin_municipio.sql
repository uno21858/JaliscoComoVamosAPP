-- JCV v1.07 · Sin filtro por municipio.
--
-- JCV pidió no filtrar por municipio (la encuesta no está diseñada para dar
-- resultados por municipio; El Salto tiene 23 respuestas). La app y el chat
-- ya no lo ofrecen; esto cierra el RPC para quien llame directo con la anon
-- key: con p_municipio, grafica y contar regresan insuficiente, sin
-- porcentajes ni n, y municipio_no_disponible = true.
-- Solo cambia el cuerpo de dos funciones (misma firma): permisos igual.

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
           num_nonnulls(p_municipio, p_edad, p_sexo, p_estrato) > 2 as demasiados,
           p_municipio is not null as con_municipio,
           (count(*) < case when p_fuente = 'TEC' then 30 else 10 end
            or num_nonnulls(p_municipio, p_edad, p_sexo, p_estrato) > 2
            or p_municipio is not null) as insuficiente
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
    'n', case when t.demasiados or t.con_municipio or (p_fuente = 'TEC' and t.insuficiente) then null else t.n end,
    'muestra_pequena', t.n < 30,
    'insuficiente', t.insuficiente,
    'demasiados_filtros', t.demasiados,
    'municipio_no_disponible', t.con_municipio,
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
    'n', case when d.demasiados or p_municipio is not null or (p_fuente = 'TEC' and c.n < 30) then null else c.n end,
    'umbral', case when p_fuente = 'TEC' then 30 else 10 end,
    'bajo_umbral', d.demasiados or p_municipio is not null or c.n < case when p_fuente = 'TEC' then 30 else 10 end,
    'demasiados_filtros', d.demasiados,
    'municipio_no_disponible', p_municipio is not null
  )
  from c
  cross join (select num_nonnulls(p_municipio, p_edad, p_sexo, p_estrato) > 2 as demasiados) d
  where p_fuente in ('AMG', 'TEC');
$$;
