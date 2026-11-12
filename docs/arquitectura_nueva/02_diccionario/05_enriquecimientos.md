# 02.5 · Enriquecimientos

[← Diccionario](README.md)

Salidas de procesos analíticos que corren **fuera** de los cargadores diarios. Se migraron desde la arquitectura vieja (`14_B2k_crear_enriquecimientos.sql`, `15_F1_07_clasificados_bert_v1.sql`).

---

## `posteos_clasificados`

| Atributo | Valor |
|---|---|
| Propósito | Categoría temática asignada a cada posteo por un clasificador |
| Grano | Un posteo clasificado por una versión de modelo |
| Clave lógica | `red` + `post_id` + `modelo_version` |
| Partición / clustering | — / `post_id` |
| Filas (04/11/2026) | 499.537 (35,5 MB) |
| Alcance | Solo cuentas de **medios** (decisión 03/11/2026). Los comentarios tendrán un modelo aparte. |

| Columna | Tipo | Descripción |
|---|---|---|
| `red` | STRING | Red del posteo. |
| `post_id` | STRING | Posteo (→ `posteos`). |
| `categoria` | STRING | Categoría temática predicha. |
| `confianza` | FLOAT64 | Probabilidad de la categoría predicha (0–1). |
| `red_match` | STRING | Red con la que se cruzó el posteo al migrar la clasificación (control del cruce). |
| `modelo_version` | STRING | Versión del modelo. Hoy `bert_v1`. Permite convivir varias versiones. |
| `clasificado_ts` | TIMESTAMP | Momento de la clasificación. |
| `cargado_ts` | TIMESTAMP | Momento de carga. |

```sql
SELECT p.red, k.categoria, COUNT(*) AS posts
FROM `cordoba-489013.posteos_unificado.posteos` p
JOIN `cordoba-489013.posteos_unificado.posteos_clasificados` k
  ON k.red = p.red AND k.post_id = p.post_id AND k.modelo_version = 'bert_v1'
WHERE p.time_created >= TIMESTAMP('2026-10-01') AND p.time_created < TIMESTAMP('2026-11-01')
GROUP BY 1, 2;
```

---

## `comentarios_normalizados`

| Atributo | Valor |
|---|---|
| Propósito | Texto limpio del comentario listo para NLP y destinatario de la respuesta |
| Grano | Un comentario |
| Clave lógica | `red` + `comment_id` |
| Partición / clustering | — / `red`, `comment_id` |
| Filas (04/11/2026) | 13.030.878 (2,5 GB) |

| Columna | Tipo | Descripción |
|---|---|---|
| `red` | STRING | Red. |
| `post_id` | STRING | Posteo comentado. |
| `comment_id` | STRING | Comentario (→ `comentarios`). |
| `author_id` | STRING | Autor. |
| `clean_comment` | STRING | Texto normalizado (sin URLs, menciones, emojis ni ruido, según la versión). |
| `respuesta_a` | STRING | A quién responde el comentario (si es respuesta). |
| `version_norm` | STRING | Versión del proceso de normalización. |
| `fecha_proceso` | TIMESTAMP | Momento del procesamiento. |
| `cargado_ts` | TIMESTAMP | Momento de carga. |

> El respaldo `comentarios_normalizados_v2_backup` (arquitectura vieja) no se borra nunca.

---

## `autores`

| Atributo | Valor |
|---|---|
| Propósito | Atributo demográfico **inferido** de cada autor de comentarios a partir de su nombre público |
| Grano | Un autor de una red |
| Clave lógica | `red` + `author_id` |
| Partición / clustering | — / `red`, `author_id` |
| Filas (04/11/2026) | 8.141.983 (1,1 GB) |

| Columna | Tipo | Descripción |
|---|---|---|
| `red` | STRING | Red. |
| `author_id` | STRING | Autor (→ `comentarios.author_id`). |
| `sex_id` | INT64 | Código del sexo inferido (codificación definida por el proceso de inferencia). |
| `metodo` | STRING | Método de inferencia utilizado. |
| `token` | STRING | Fragmento del nombre usado para inferir. |
| `valores` | STRING | Valores intermedios de la inferencia (serializado). |
| `version_genero` | STRING | Versión del proceso. |
| `fecha_proceso` | TIMESTAMP | Momento del procesamiento. |
| `cargado_ts` | TIMESTAMP | Momento de carga. |

> Es una estimación estadística, no un dato declarado por la persona. Los autores se anonimizan en las etapas de análisis.
