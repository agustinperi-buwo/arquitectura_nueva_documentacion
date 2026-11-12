-- PASO D1 | Relevamiento para la documentacion de GitHub (SOLO LECTURA)
-- HACE: En UNA sola tabla de resultados devuelve: filas y tamano por tabla, esquema real (columnas, tipo, particion,
--       cluster), definicion de las vistas y los valores distintos de las columnas categoricas, para actualizar
--       docs/arquitectura_nueva con cifras y dominios reales.
-- COSTO: estimado < 1,5 GB (lee solo columnas chicas). Maximum bytes billed = 3 GB. Correr completo, sin texto seleccionado.
-- ESPERADO: entre 400 y 900 filas con columnas seccion | tabla | campo | valor | n | extra.
--           Guardar resultados > CSV (archivo local) > docs\arquitectura_nueva\sql\D1_resultado.csv

WITH
a_tablas AS (
  SELECT 'A_tablas' AS seccion, table_id AS tabla, IF(type = 1, 'tabla', 'vista') AS campo,
         CAST(NULL AS STRING) AS valor, row_count AS n, CAST(ROUND(size_bytes / 1e6, 1) AS STRING) AS extra
  FROM `cordoba-489013.posteos_unificado.__TABLES__`
),
b_esquema AS (
  SELECT 'B_esquema', table_name, column_name, data_type, ordinal_position,
         CONCAT(IF(is_partitioning_column = 'YES', 'PARTICION ', ''),
                IFNULL(CONCAT('CLUSTER ', CAST(clustering_ordinal_position AS STRING)), ''))
  FROM `cordoba-489013.posteos_unificado.INFORMATION_SCHEMA.COLUMNS`
),
c_vistas AS (
  SELECT 'C_vista', table_name, 'definicion', CAST(NULL AS STRING), CAST(NULL AS INT64), view_definition
  FROM `cordoba-489013.posteos_unificado.INFORMATION_SCHEMA.VIEWS`
),
d_proyectos AS (
  SELECT 'D_valores', 'proyectos', proyecto_id, CONCAT(IFNULL(nombre, ''), ' | ', IFNULL(territorio, ''), ' | ', IFNULL(cliente, '')),
         CAST(NULL AS INT64), CONCAT(IFNULL(CAST(fecha_inicio AS STRING), ''), ' a ', IFNULL(CAST(fecha_fin AS STRING), ''))
  FROM `cordoba-489013.posteos_unificado.proyectos`
),
d_pc AS (
  SELECT 'D_valores', 'proyecto_cuentas', CONCAT('proyecto_red:', proyecto_id), red, COUNT(*), STRING_AGG(DISTINCT IFNULL(origen, 'NULL'))
  FROM `cordoba-489013.posteos_unificado.proyecto_cuentas` GROUP BY proyecto_id, red
),
d_cuentas AS (
  SELECT 'D_valores', 'cuentas', 'categoria', IFNULL(categoria, 'NULL'), COUNT(*), STRING_AGG(DISTINCT red)
  FROM `cordoba-489013.posteos_unificado.cuentas` GROUP BY categoria
  UNION ALL
  SELECT 'D_valores', 'cuentas', 'provincia', IFNULL(provincia, 'NULL'), COUNT(*), NULL
  FROM `cordoba-489013.posteos_unificado.cuentas` GROUP BY provincia
  UNION ALL
  SELECT 'D_valores', 'cuentas', 'revisar', IFNULL(revisar, 'NULL'), COUNT(*), NULL
  FROM `cordoba-489013.posteos_unificado.cuentas` GROUP BY revisar
  UNION ALL
  SELECT 'D_valores', 'cuentas_pendientes', 'categoria_red', CONCAT(IFNULL(categoria, 'NULL'), ' | ', red), COUNT(*), NULL
  FROM `cordoba-489013.posteos_unificado.cuentas_pendientes` GROUP BY categoria, red
),
d_posteos AS (
  SELECT 'D_valores', 'posteos', 'red_cuenta_match', CONCAT(red, ' | ', IFNULL(cuenta_match, 'NULL')), COUNT(*),
         CONCAT(CAST(MIN(time_created) AS STRING), ' a ', CAST(MAX(time_created) AS STRING), ' | ult captura ', CAST(MAX(scraped_at) AS STRING))
  FROM `cordoba-489013.posteos_unificado.posteos` GROUP BY red, cuenta_match
),
d_metas AS (
  SELECT 'D_valores', 'meta_x', 'tipo_tweet', IFNULL(tipo_tweet, 'NULL'), COUNT(*), CAST(COUNTIF(scraped_ts_inferido) AS STRING)
  FROM `cordoba-489013.posteos_unificado.meta_x` GROUP BY tipo_tweet
  UNION ALL
  SELECT 'D_valores', 'meta_facebook', 'post_type', IFNULL(post_type, 'NULL'), COUNT(*), NULL
  FROM `cordoba-489013.posteos_unificado.meta_facebook` GROUP BY post_type
  UNION ALL
  SELECT 'D_valores', 'meta_instagram', 'typename', IFNULL(typename, 'NULL'), COUNT(*), NULL
  FROM `cordoba-489013.posteos_unificado.meta_instagram` GROUP BY typename
  UNION ALL
  SELECT 'D_valores', 'meta_youtube', 'tipo_definition', CONCAT(IFNULL(tipo, 'NULL'), ' | ', IFNULL(definition, 'NULL')), COUNT(*), NULL
  FROM `cordoba-489013.posteos_unificado.meta_youtube` GROUP BY tipo, definition
),
d_contenido AS (
  SELECT 'D_valores', 'comentarios', 'red', red, COUNT(*),
         CONCAT(CAST(MIN(timestamp) AS STRING), ' a ', CAST(MAX(timestamp) AS STRING), ' | sin cuenta ', CAST(COUNTIF(cuenta_id IS NULL) AS STRING),
                ' | respuestas ', CAST(COUNTIF(parent_id IS NOT NULL) AS STRING))
  FROM `cordoba-489013.posteos_unificado.comentarios` GROUP BY red
  UNION ALL
  SELECT 'D_valores', 'transcripciones', 'red', red, COUNT(*), NULL
  FROM `cordoba-489013.posteos_unificado.transcripciones` GROUP BY red
  UNION ALL
  SELECT 'D_valores', 'cuentas_perfil', 'red', red, COUNT(*), CONCAT('cuentas ', CAST(COUNT(DISTINCT cuenta_id) AS STRING), ' | ult ', CAST(MAX(scraped_at) AS STRING))
  FROM `cordoba-489013.posteos_unificado.cuentas_perfil` GROUP BY red
),
d_enriq AS (
  SELECT 'D_valores', 'posteos_clasificados', 'modelo_categoria', CONCAT(IFNULL(modelo_version, 'NULL'), ' | ', IFNULL(categoria, 'NULL')), COUNT(*),
         CAST(ROUND(AVG(confianza), 3) AS STRING)
  FROM `cordoba-489013.posteos_unificado.posteos_clasificados` GROUP BY modelo_version, categoria
  UNION ALL
  SELECT 'D_valores', 'posteos_clasificados', 'red_match', CONCAT(IFNULL(red, 'NULL'), ' | ', IFNULL(red_match, 'NULL')), COUNT(*), NULL
  FROM `cordoba-489013.posteos_unificado.posteos_clasificados` GROUP BY red, red_match
  UNION ALL
  SELECT 'D_valores', 'comentarios_normalizados', 'red_version', CONCAT(red, ' | ', IFNULL(version_norm, 'NULL')), COUNT(*),
         CAST(COUNTIF(respuesta_a IS NOT NULL) AS STRING)
  FROM `cordoba-489013.posteos_unificado.comentarios_normalizados` GROUP BY red, version_norm
  UNION ALL
  SELECT 'D_valores', 'autores', 'metodo_sex_id', CONCAT(IFNULL(metodo, 'NULL'), ' | ', IFNULL(CAST(sex_id AS STRING), 'NULL'), ' | ', IFNULL(version_genero, 'NULL')), COUNT(*), NULL
  FROM `cordoba-489013.posteos_unificado.autores` GROUP BY metodo, sex_id, version_genero
),
d_x AS (
  SELECT 'D_valores', 'x_relaciones', 'tipo_fuente', CONCAT(tipo, ' | ', IFNULL(fuente, 'NULL')), COUNT(*),
         CONCAT(CAST(MIN(relacion_at) AS STRING), ' a ', CAST(MAX(relacion_at) AS STRING))
  FROM `cordoba-489013.posteos_unificado.x_relaciones` GROUP BY tipo, fuente
  UNION ALL
  SELECT 'D_valores', 'tweets_referidos', 'fuente', IFNULL(fuente, 'NULL'), COUNT(*), NULL
  FROM `cordoba-489013.posteos_unificado.tweets_referidos` GROUP BY fuente
  UNION ALL
  SELECT 'D_valores', 'x_retweets_sin_original', 'fuente', IFNULL(fuente, 'NULL'), COUNT(*), CAST(COUNT(DISTINCT cuenta_id) AS STRING)
  FROM `cordoba-489013.posteos_unificado.x_retweets_sin_original` GROUP BY fuente
)
SELECT * FROM a_tablas
UNION ALL SELECT * FROM b_esquema
UNION ALL SELECT * FROM c_vistas
UNION ALL SELECT * FROM d_proyectos
UNION ALL SELECT * FROM d_pc
UNION ALL SELECT * FROM d_cuentas
UNION ALL SELECT * FROM d_posteos
UNION ALL SELECT * FROM d_metas
UNION ALL SELECT * FROM d_contenido
UNION ALL SELECT * FROM d_enriq
UNION ALL SELECT * FROM d_x
ORDER BY seccion, tabla, campo, valor;
