# 02.4 · Comentarios y transcripciones

[← Diccionario](README.md)

---

## `comentarios`

| Atributo | Valor |
|---|---|
| Propósito | Comentarios (y respuestas) recibidos por los posteos de las cuentas monitoreadas |
| Grano | Un comentario |
| Clave lógica | `red` + `post_id` + `comment_id` |
| Partición | `TIMESTAMP_TRUNC(timestamp, MONTH)` — **fecha del comentario**, no del posteo |
| Clustering | `red`, `post_id`, `comment_id` |
| Filas (04/11/2026) | 15.311.315 (5,2 GB) — tabla más grande del modelo |
| Escriben | `13_B2i_crear_comentarios.sql`, `16_B2zc_completar_cuenta_comentarios.sql`, `28_X4f_cuenta_comentarios_x_test.sql` (migración); `bq_unificado.sql_comentarios` vía `cargar_snapshots.py`; `sync_unificado.py --solo-comentarios` (comentarios IG de la cola manual, que solo suben a la arquitectura vieja) |
| Leen | Normalización de texto (`comentarios_normalizados`), inferencia de autores (`autores`), análisis |

| Columna | Tipo | Descripción |
|---|---|---|
| `red` | STRING | Red. |
| `post_id` | STRING | Posteo comentado (→ `posteos`). |
| `comment_id` | STRING | Id nativo del comentario. |
| `parent_id` | STRING | `comment_id` del comentario al que responde. NULL en comentarios de primer nivel. |
| `cuenta_id` | STRING | Cuenta **dueña del posteo** (no el autor del comentario). Se completa desde `posteos` y, si falta, desde el `account_id` del CSV. |
| `post_url` | STRING | URL del posteo comentado. |
| `username` | STRING | Usuario del autor del comentario. |
| `nickname` | STRING | Nombre visible del autor. |
| `author_id` | STRING | Id nativo del autor (→ `autores`). |
| `text` | STRING | Texto original del comentario. |
| `timestamp` | TIMESTAMP | Fecha del comentario (UTC). Partición. |
| `likes` | INT64 | Me gusta del comentario (en la última captura). |
| `replies_count` | INT64 | Respuestas que recibió. |
| `scraped_at` | TIMESTAMP | Captura más reciente del comentario. |
| `cargado_ts` | TIMESTAMP | Momento de carga. |

**Reglas**
- Una fila por comentario: ante recapturas se conserva la de `scraped_at` más reciente y el `MERGE` actualiza solo `likes`, `replies_count` y `scraped_at`. La arquitectura vieja guardaba una fila por captura: **comparar con totales de comentarios distintos, no con filas por día**.
- Comentarios de X sobre “retweets sin envoltorio” son respuestas al tweet original de autores ajenos: cuelgan del id del original.
- La partición es por fecha del comentario: para traer los comentarios de un posteo filtrar por `timestamp` en un rango que arranque en la fecha de publicación.

```sql
-- Comentarios de los posteos de una cuenta en noviembre
SELECT c.post_id, COUNT(*) AS comentarios
FROM `cordoba-489013.posteos_unificado.comentarios` c
WHERE c.red = 'facebook' AND c.cuenta_id = '<cuenta_id>'
  AND c.timestamp >= TIMESTAMP('2026-11-01') AND c.timestamp < TIMESTAMP('2026-12-01')
GROUP BY c.post_id;
```

---

## `transcripciones`

| Atributo | Valor |
|---|---|
| Propósito | Texto hablado de los videos (subtítulos o reconocimiento de voz) |
| Grano | Un posteo de video |
| Clave lógica | `red` + `post_id` |
| Partición / clustering | — / `red`, `post_id` |
| Filas (04/11/2026) | 15.820 (206,3 MB) |
| Escriben | `12_B2g_crear_transcripciones.sql` y `31_quitar_proyecto_id_dataset_origen_transcripciones.sql` (migración); `sync_unificado.py`. **No hay cargador diario propio todavía**: `transcripciones/bigquery_upload.py` escribe solo en la arquitectura vieja. |

| Columna | Tipo | Descripción |
|---|---|---|
| `red` | STRING | `youtube`, `tiktok`, `instagram` (videos). |
| `post_id` | STRING | Posteo transcripto. |
| `account_id_origen` | STRING | Id de cuenta del origen. |
| `username` | STRING | Usuario de la cuenta. |
| `url` | STRING | URL del video. |
| `texto` | STRING | Transcripción completa. Fuente: subtítulos en español; si no hay, Whisper (es) como respaldo. |
| `cuenta_id` | STRING | Cuenta resuelta. |
| `cuenta_match` | STRING | Regla de resolución de la cuenta. |
| `cargado_ts` | TIMESTAMP | Momento de carga. |

**Reglas**: deduplicación por (`red`, `post_id`) conservando el texto más largo.
