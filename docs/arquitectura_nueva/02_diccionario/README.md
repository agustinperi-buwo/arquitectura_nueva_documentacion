# 02 · Diccionario de datos

[← Índice](../README.md)

Cada ficha sigue el mismo formato:

| Campo de la ficha | Significado |
|---|---|
| **Propósito** | Qué representa la tabla |
| **Grano** | Qué es una fila |
| **Clave lógica** | Columnas que identifican una fila (BigQuery no las impone; el proceso de carga garantiza su unicidad) |
| **Partición / clustering** | Organización física: define el costo de las consultas |
| **Volumen de referencia** | Filas y tamaño aproximados (noviembre 2026) |

Tipos: `STRING`, `INT64`, `FLOAT64`, `BOOL`, `DATE`, `TIMESTAMP` (siempre UTC).

| Ficha | Tablas |
|---|---|
| [01 Proyectos y cuentas](01_proyectos_y_cuentas.md) | `proyectos`, `proyecto_cuentas`, `cuentas`, `cuentas_perfil`, `v_cuentas_actual`, `cuentas_alias`, `cuentas_ids_alternativos`, `cuentas_pendientes`, `correcciones_maestro` |
| [02 Posteos](02_posteos.md) | `posteos_capturas`, `posteos`, `v_posteos` |
| [03 Metadatos por red](03_metas_por_red.md) | `meta_facebook`, `meta_instagram`, `meta_tiktok`, `meta_x`, `meta_youtube` |
| [04 Comentarios y transcripciones](04_comentarios_y_transcripciones.md) | `comentarios`, `transcripciones` |
| [05 Enriquecimientos](05_enriquecimientos.md) | `posteos_clasificados`, `comentarios_normalizados`, `autores` |
| [06 X: relaciones](06_x_relaciones.md) | `x_relaciones`, `tweets_referidos`, `x_retweets_sin_original` |

**Tablas internas:** las que empiezan con `bk_` o `_stg_` y `x_timeline_stg` son de uso interno del proceso de carga. No forman parte del modelo ni deben usarse en análisis.
