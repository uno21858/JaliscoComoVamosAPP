-- Carga los CSV que genera scripts/importar_amg.py. Reemplaza todo lo anterior.
-- Correr desde la carpeta de salida del script:
--   cd ~/Downloads/jcv_import
--   psql "<session pooler URL de CCL DEV>" -v ON_ERROR_STOP=1 -f <repo>/scripts/cargar_amg.sql
-- ponytail: truncate borra todo; cuando haya filas TEC, cambiar a delete where fuente = 'AMG'.

begin;
truncate jcv.respuestas, jcv.personas, jcv.preguntas;
\copy jcv.preguntas (variable, orden, tema, texto, opciones) from 'preguntas.csv' with (format csv, header true)
\copy jcv.personas (id, fuente, municipio, edad, sexo, estrato, factor) from 'personas.csv' with (format csv, header true)
\copy jcv.respuestas (variable, persona_id, valor) from 'respuestas.csv' with (format csv, header true)
commit;

analyze jcv.preguntas;
analyze jcv.personas;
analyze jcv.respuestas;

select (select count(*) from jcv.preguntas) as preguntas,
       (select count(*) from jcv.personas) as personas,
       (select count(*) from jcv.respuestas) as respuestas;
