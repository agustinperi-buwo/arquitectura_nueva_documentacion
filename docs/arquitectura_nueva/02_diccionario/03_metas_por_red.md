# 02.3 · Metadatos por red

[← Diccionario](README.md)

Campos que solo existen en una red. Una fila por **captura** (igual que `posteos_capturas`). La red no figura como columna: la define la tabla.

**Atributos comunes a las cinco tablas**

| Atributo | Valor |
|---|---|
| Grano | Una captura de un posteo de esa red |
| Clave lógica | `post_id` + `scraped_at` |
| Partición | `TIMESTAMP_TRUNC(time_created, MONTH)` |
| Clustering | `post_id` |
| Unión | `posteos_capturas` por `post_id` + `scraped_at` (y `red` = red de la tabla) |

**Columnas comunes**

| Columna | Tipo | Descripción |
|---|---|---|
| `post_id` | STRING | Id del posteo. |
| `scraped_at` | TIMESTAMP | Momento de la captura (UTC). |
| `scraped_ts_inferido` | BOOL | `TRUE` si el registro histórico no tenía momento de captura y se le asignó el de la última captura del posteo. |
| `time_created` | TIMESTAMP | Publicación (UTC). Partición. |
| `cargado_ts` | TIMESTAMP | Momento de carga. |

**Unir la última captura con su meta**

```sql
SELECT p.post_id, p.like_count, m.share_count, m.reaction_count
FROM `cordoba-489013.posteos_unificado.posteos` p
JOIN `cordoba-489013.posteos_unificado.meta_facebook` m
  ON m.post_id = p.post_id AND m.scraped_at = p.scraped_at
 AND m.time_created >= TIMESTAMP('2026-11-01') AND m.time_created < TIMESTAMP('2026-12-01')
WHERE p.red = 'facebook'
  AND p.time_created >= TIMESTAMP('2026-11-01') AND p.time_created < TIMESTAMP('2026-12-01');
```

> Si la meta tiene `scraped_ts_inferido = TRUE`, el `scraped_at` puede no coincidir con ninguna captura exacta: en ese caso unir por `post_id` y tomar la meta de mayor `scraped_at`.

---

## `meta_facebook` — ~340 mil filas

| Columna | Tipo | Descripción |
|---|---|---|
| `angry_count` | INT64 | Reacciones “me enoja”. |
| `haha_count` | INT64 | Reacciones “me divierte”. |
| `wow_count` | INT64 | Reacciones “me asombra”. |
| `love_count` | INT64 | Reacciones “me encanta”. |
| `sad_count` | INT64 | Reacciones “me entristece”. |
| `care_count` | INT64 | Reacciones “me importa”. |
| `share_count` | INT64 | Veces compartido. |
| `reaction_count` | INT64 | Total de reacciones. |
| `post_type` | STRING | Tipo de publicación (foto, video, enlace, estado…). |
| `attachment_url` | STRING | URL del adjunto. |
| `link_url` | STRING | URL del enlace compartido. |
| `link_title` | STRING | Título del enlace compartido. |
| `photo_url` | STRING | URL de la imagen. |
| `actors` | STRING | Páginas o personas que figuran como autoras/coautoras (serializado). |

## `meta_instagram` — ~65 mil filas

| Columna | Tipo | Descripción |
|---|---|---|
| `typename` | STRING | Tipo de media (imagen, video, carrusel) según la API. |
| `shortcode` | STRING | Código corto de la URL (`instagram.com/p/<shortcode>`). |
| `title` | STRING | Título del reel/video cuando existe. |
| `tagged_users` | STRING | Usuarios etiquetados (serializado). |

> Posteos colaborativos: un mismo `post_id` puede aparecer publicado por dos cuentas. En `posteos` el dueño es siempre la cuenta monitoreada; los colaboradores quedan en la meta.

## `meta_tiktok` — ~45 mil filas

| Columna | Tipo | Descripción |
|---|---|---|
| `save_count` | INT64 | Guardados. |
| `sharecount` | INT64 | Compartidos. |
| `artist` | STRING | Artista del audio. |
| `uploader` | STRING | Usuario que subió el video. |
| `uploader_id` | STRING | Id del usuario que subió el video (insumo de `cuenta_id`). |
| `title` | STRING | Título/descripción corta. |
| `width` | FLOAT64 | Ancho del video (px). |
| `height` | FLOAT64 | Alto del video (px). |
| `filesize` | FLOAT64 | Tamaño del archivo (bytes). |
| `duration` | FLOAT64 | Duración (segundos). |

> Consideración de calidad: en TikTok, los posteos anteriores al 21/09/2026 tienen `time_created` desplazado −3 h.

## `meta_x` — ~540 mil filas

| Columna | Tipo | Descripción |
|---|---|---|
| `tipo_tweet` | STRING | `original`, `reply` o `quote` (los retweets no llegan a esta tabla). |
| `retweet_count` | INT64 | Retweets. |
| `quote_count` | INT64 | Citas. |
| `view_count` | INT64 | Vistas. |
| `bookmark_count` | INT64 | Guardados. |
| `lang` | STRING | Idioma detectado por X. |
| `is_quote_status` | BOOL | Marca de cita informada por la API. |
| `in_reply_to_user` | STRING | Username al que responde. |
| `tweet_url` | STRING | URL del tweet. |
| `media` | STRING | Medios adjuntos (serializado). |
| `hashtags` | STRING | Hashtags (serializado). |
| `user_mentions` | STRING | Menciones (serializado). |
| `is_retweet` | BOOL | Marca de retweet (los retweets no se guardan en `posteos`; ver `x_relaciones`). |
| `retweeted_user` | STRING | Username retuiteado. |
| `retweeted_tweet_id` | STRING | Id del tweet retuiteado. |
| `retweeted_user_id` | STRING | Id del autor retuiteado. |
| `retweeted_created_at` | STRING | Fecha del tweet retuiteado (texto). |
| `is_quote` | BOOL | Es cita. |
| `quoted_tweet_id` | STRING | Id del tweet citado. |
| `quoted_user` | STRING | Username citado. |
| `quoted_user_id` | STRING | Id del autor citado. |
| `quoted_text` | STRING | Texto del tweet citado. |
| `quoted_created_at` | STRING | Fecha del tweet citado (texto). |
| `quoted_like_count` | INT64 | Likes del tweet citado. |
| `quoted_url` | STRING | URL del tweet citado. |
| `is_reply` | BOOL | Es respuesta. |
| `in_reply_to_tweet_id` | STRING | Id del tweet respondido. |
| `in_reply_to_user_id` | STRING | Id del autor respondido. |
| `conversation_id` | STRING | Id del hilo. |

> Para analizar relaciones usar `x_relaciones` + `tweets_referidos`; las columnas `retweeted_*`, `quoted_*` e `in_reply_to_*` son informativas.

## `meta_youtube` — ~50 mil filas

| Columna | Tipo | Descripción |
|---|---|---|
| `duration_secs` | INT64 | Duración (segundos). |
| `definition` | STRING | `hd` / `sd`. |
| `caption` | BOOL | Tiene subtítulos. |
| `title` | STRING | Título del video. |
| `category_id` | STRING | Categoría de YouTube. |
| `tags` | STRING | Etiquetas (serializado). |
| `topic_categories` | STRING | Categorías temáticas (URLs de Wikipedia, serializado). |
| `aspect_ratio` | FLOAT64 | Relación de aspecto (permite distinguir shorts verticales). |
| `tipo` | STRING | Tipo de publicación (video, short, etc.). |
