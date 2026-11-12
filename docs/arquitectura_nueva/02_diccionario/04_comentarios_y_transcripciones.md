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
| Volumen de referencia | ~15 millones de filas (~5 GB): la tabla más grande del modelo |

| Columna | Tipo | Descripción |
|---|---|---|
| `red` | STRING | Red. |
| `post_id` | STRING | Posteo comentado (→ `posteos`). |
| `comment_id` | STRING | Id nativo del comentario. |
| `parent_id` | STRING | `comment_id` del comentario al que responde. NULL en comentarios de primer nivel. |
| `cuenta_id` | STRING | Cuenta **dueña del posteo** comentado (no el autor del comentario). |
| `post_url` | STRING | URL del posteo comentado. |
| `username` | STRING | Usuario del autor del comentario. |
| `nickname` | STRING | Nombre visible del autor. |
| `author_id` | STRING | Id nativo del autor (→ `autores`). |
| `text` | STRING | Texto original del comentario. |
| `timestamp` | TIMESTAMP | Fecha del comentario (UTC). Partición. |
| `likes` | INT64 | Me gusta del comentario en la última lectura. |
| `replies_count` | INT64 | Respuestas que recibió. |
| `scraped_at` | TIMESTAMP | Última lectura del comentario. |
| `cargado_ts` | TIMESTAMP | Momento de ingreso a BigQuery. |

**Consideraciones**
- Una fila por comentario: si se vuelve a leer, se actualizan `likes`, `replies_count` y `scraped_at`.
- La cobertura de comentarios es parcial: comparar `COUNT(*)` contra `posteos.comment_count` para medirla ([04](../04_guia_de_consultas.md)).
- En X, los comentarios cuelgan del id del tweet comentado.
- Para traer los comentarios de un posteo, filtrar `timestamp` desde la fecha de publicación del posteo.

```sql
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
| Propósito | Texto hablado de los videos |
| Grano | Un posteo de video |
| Clave lógica | `red` + `post_id` |
| Partición / clustering | — / `red`, `post_id` |
| Volumen de referencia | ~16 mil filas (~200 MB) |

| Columna | Tipo | Descripción |
|---|---|---|
| `red` | STRING | Red del video. |
| `post_id` | STRING | Posteo transcripto (→ `posteos`). |
| `account_id_origen` | STRING | Id de cuenta informado por la red. |
| `username` | STRING | Usuario de la cuenta. |
| `url` | STRING | URL del video. |
| `texto` | STRING | Transcripción completa. Se toma de los subtítulos en español y, si no existen, de reconocimiento automático de voz. |
| `cuenta_id` | STRING | Cuenta resuelta. |
| `cuenta_match` | STRING | Regla de resolución de la cuenta. |
| `cargado_ts` | TIMESTAMP | Momento de ingreso a BigQuery. |

Si un video tuvo más de una transcripción, se conserva la más completa.
