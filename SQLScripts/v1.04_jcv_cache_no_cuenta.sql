-- JCV v1.04 · Las respuestas del caché no gastan el límite diario.
--
-- Una pregunta que sale de jcv.cache_respuestas no llama a Haiku ni cuesta,
-- así que no cuenta en las 20 por día (dispositivo) ni en las 1000 (IP).
-- El límite por minuto sí las cuenta (anti-spam). desde_cache lo marca
-- completar_pregunta al terminar, así que las preguntas anteriores ya lo traen.
-- Misma firma: los permisos se quedan igual. Idempotente.

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
           when count(*) filter (where not bloqueada and not desde_cache) >= 20 then 'dia'
         end
  into v_bloqueo
  from jcv.bitacora
  where dispositivo_hash = p_dispositivo_hash and creado > now() - interval '1 day';

  if v_bloqueo is null then
    select case
             when count(*) filter (where creado > now() - interval '1 minute') >= 60 then 'minuto'
             when count(*) filter (where not bloqueada and not desde_cache) >= 1000 then 'dia'
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
