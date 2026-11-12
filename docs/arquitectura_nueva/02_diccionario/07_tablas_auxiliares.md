# 02.7 · Tablas auxiliares

[← Diccionario](README.md)

No forman parte del modelo. No usarlas en consultas de análisis.

| Patrón | Qué es | Ciclo de vida |
|---|---|---|
| `bk_x4b4_posteos`, `bk_x4b4_posteos_capturas`, `bk_x4b4_meta_x` | Retweets con envoltorio retirados de `posteos` en el paso 24 | Borrables al cerrar la Fase 5 (con aprobación) |
| `bk_x4b5_posteos`, `bk_x4b5_posteos_capturas`, `bk_x4b5_meta_x` | Tweets de autores ajenos retirados en el paso 27 | Ídem |
| `_stg_*` | Staging temporal de los cargadores (`bq_unificado.Cargador`) | Vencen en 1 día y se borran al terminar cada carga |
| `bk_<dataset>_20261104` (en otros datasets) | Backups de la arquitectura vieja tomados antes de construir (45 tablas) | Marcha atrás de la migración; se revisan uno por uno |

Además, BigQuery conserva **time travel de 7 días** sobre todas las tablas.
