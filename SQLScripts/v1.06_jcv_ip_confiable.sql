-- JCV v1.06 · IP confiable y tope global en jcv.guardar_encuesta.
--
-- v1.05 tomaba el primer valor de x-forwarded-for, que el cliente puede
-- inventar (probado: con "X-Forwarded-For: 1.2.3.4" llega "1.2.3.4,<real>").
-- Ahora usa cf-connecting-ip (Cloudflare lo pone y rechaza a quien lo mande;
-- probado: "error code: 1000"). Y un tope global de 1000 encuestas por hora,
-- para que rotar IPs no sirva para llenar el Tec de respuestas falsas.
-- Lo de fondo (identidad real) llega con login. Misma firma: permisos igual.

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
  -- IP real: cf-connecting-ip la pone Cloudflare y rechaza a quien la mande.
  -- El primer valor de x-forwarded-for lo puede inventar el cliente; si falta
  -- cf-connecting-ip se usa el último, que agrega el proxy.
  v_ip_hash := encode(extensions.digest('jcv:' || coalesce(
    nullif(current_setting('request.headers', true)::json ->> 'cf-connecting-ip', ''),
    nullif(trim(reverse(split_part(reverse(
      coalesce(current_setting('request.headers', true)::json ->> 'x-forwarded-for', '')), ',', 1))), ''),
    'sin-ip'), 'sha256'), 'hex');

  if (select count(*) from jcv.encuestas_hechas
      where ip_hash = v_ip_hash and creado > now() - interval '1 hour') >= 300 then
    raise exception 'demasiados envíos' using errcode = 'P0429';
  end if;

  -- Tope global: aunque alguien rote IPs, no entran más de 1000 por hora.
  if (select count(*) from jcv.encuestas_hechas where creado > now() - interval '1 hour') >= 1000 then
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
