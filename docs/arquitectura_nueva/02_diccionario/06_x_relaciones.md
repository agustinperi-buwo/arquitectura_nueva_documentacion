# 02.6 · X: relaciones

[← Diccionario](README.md)

Diseño revisado por Franco (30/10/2026) y aplicado en la migración (pasos 18 a 28).

**Regla:** `posteos` guarda solo lo que la cuenta escribió. Ser cita, respuesta o retweet es una **relación**, no un atributo: va en `x_relaciones`. El tweet referido se guarda una vez en `tweets_referidos`, aunque su autor no sea cuenta de interés. Las métricas del original viven solo en `tweets_referidos` (un retweet copia las vistas del original: guardarlas en ambos lados las contaría dos veces).

| Tipo de tweet de la cuenta | `posteos` | `x_relaciones` | `tweets_referidos` |
|---|---|---|---|
| Original | Sí | — | — |
| Reply | Sí | `tipo = reply`, `post_id` = tweet propio | Tweet respondido |
| Quote | Sí | `tipo = quote`, `post_id` = tweet propio | Tweet citado |
| Retweet con id del original | No | `tipo = retweet` | Tweet original |
| Retweet sin id del original | No | — | — → `x_retweets_sin_original` |
| Tweet de autor ajeno capturado en el timeline | No | — | — (respaldo `bk_x4b5_*`) |

---

## `x_relaciones`

| Atributo | Valor |
|---|---|
| Propósito | Quién responde, cita o retuitea a qué tweet |
| Grano | Una relación de una cuenta con un tweet |
| Clave lógica | `cuenta_id` + `tipo` + `tweet_referido_id` + `post_id` (`post_id` agregado a pedido de Franco el 04/11; NULL en `retweet_sin_envoltorio`) |
| Partición / clustering | — / `cuenta_id`, `tipo` |
| Filas (04/11/2026) | 316.571 (40,2 MB) |
| Escriben | `21_X4a`, `23/26_X4b3`, `24_X4b4` (migración); `bq_unificado.sql_x_relaciones` |

| Columna | Tipo | Descripción |
|---|---|---|
| `red` | STRING | Siempre `x`. |
| `cuenta_id` | STRING | Cuenta monitoreada que actúa (→ `cuentas`). Las relaciones sin cuenta resuelta no se cargan. |
| `tipo` | STRING | `reply`, `quote`, `retweet`, `retweet_sin_envoltorio`. |
| `tweet_referido_id` | STRING | Tweet respondido / citado / retuiteado (→ `tweets_referidos.tweet_id`). |
| `autor_referido_id` | STRING | Id del autor del tweet referido. |
| `autor_referido_username` | STRING | Username del autor del tweet referido. |
| `post_id` | STRING | Tweet propio que crea la relación (reply/quote: está en `posteos`; retweet: id del retweet). NULL en `retweet_sin_envoltorio`. |
| `relacion_at` | TIMESTAMP | Momento de la relación (UTC). NULL en `retweet_sin_envoltorio`. |
| `scraped_at` | TIMESTAMP | Captura. |
| `fuente` | STRING | Origen: `timeline_x_20261026`, `posteos_unificado` (histórico migrado), `scraper_diario`. |
| `cargado_ts` | TIMESTAMP | Momento de carga. |

```sql
-- A quién retuitea más cada cuenta
SELECT r.cuenta_id, r.autor_referido_username, COUNT(*) AS retweets
FROM `cordoba-489013.posteos_unificado.x_relaciones` r
WHERE r.tipo = 'retweet' AND r.relacion_at >= TIMESTAMP('2026-10-01')
GROUP BY 1, 2 ORDER BY retweets DESC LIMIT 50;
```

---

## `tweets_referidos`

| Atributo | Valor |
|---|---|
| Propósito | Tweets mencionados por las relaciones (texto y métricas al capturarlos) |
| Grano | Un tweet |
| Clave lógica | `tweet_id` |
| Partición / clustering | — / `tweet_id` |
| Filas (04/11/2026) | 239.872 (105,3 MB) |
| Escriben | `21_X4a`, `23/26_X4b3` (migración); `bq_unificado.sql_tweets_referidos` (se carga **antes** que las relaciones) |
| Regla de captura | Conserva la **primera captura**; si llega otra, solo completa campos vacíos (`COALESCE`). Supuesto pendiente de confirmación de Franco. |

| Columna | Tipo | Descripción |
|---|---|---|
| `red` | STRING | Siempre `x`. |
| `tweet_id` | STRING | Id del tweet. |
| `autor_id` | STRING | Id del autor. |
| `autor_username` | STRING | Username del autor. |
| `texto` | STRING | Texto del tweet. |
| `created_at` | TIMESTAMP | Publicación (UTC). |
| `like_count` | INT64 | Likes al capturarlo. |
| `retweet_count` | INT64 | Retweets. |
| `reply_count` | INT64 | Respuestas. |
| `quote_count` | INT64 | Citas. |
| `view_count` | INT64 | Vistas. |
| `bookmark_count` | INT64 | Guardados. |
| `lang` | STRING | Idioma. |
| `url` | STRING | URL. |
| `fuente` | STRING | `timeline_x_20261026`, `meta_x_historico`, `posteos_sin_cuenta`, `relacion`, `scraper_diario`. |
| `scraped_at` | TIMESTAMP | Captura conservada. |
| `cargado_ts` | TIMESTAMP | Momento de carga. |

---

## `x_retweets_sin_original`

| Atributo | Valor |
|---|---|
| Propósito | Retweets con envoltorio cuyo tweet original no se conoce (el extractor histórico no guardó el id) |
| Grano | Un retweet |
| Clave lógica | `post_id` (por cuenta) |
| Partición / clustering | — / `cuenta_id` |
| Filas (04/11/2026) | 133.187 (63,1 MB) — principalmente cuentas de EE.UU. (jmilei 14.689, nagel4congress 2.736, …) |
| Escriben | `24_X4b4_mover_retweets_fuera_de_posteos_test.sql` |
| Salida prevista | Paso `X4e`: resolver el original con el timeline completo de la cuenta y pasar a `x_relaciones` + `tweets_referidos` |

| Columna | Tipo | Descripción |
|---|---|---|
| `red` | STRING | `x`. |
| `cuenta_id` | STRING | Cuenta que retuiteó. |
| `username` | STRING | Username de la cuenta. |
| `post_id` | STRING | Id del retweet. |
| `retweet_at` | TIMESTAMP | Momento del retweet (UTC). |
| `texto` | STRING | Texto del envoltorio (`RT @autor: …`). |
| `autor_original_username` | STRING | Autor del original (extraído del texto). |
| `autor_original_id` | STRING | Id del autor original si se conoce. |
| `url` | STRING | URL del retweet. |
| `scraped_at` | TIMESTAMP | Captura. |
| `fuente` | STRING | Origen del dato. |
| `cargado_ts` | TIMESTAMP | Momento de carga. |

---

## `x_timeline_stg`

| Atributo | Valor |
|---|---|
| Propósito | Staging del timeline completo de X (todas las columnas como texto) |
| Grano | Un tweet del timeline de una cuenta |
| Filas | 74.595 (49,2 MB), cargado hasta el 27/10/2026 (jmilei y luego cuentas de EE.UU.) |
| Escriben | `18_F1_10_x_preparar.sql` (desde el CSV de `C2_x_timeline_completo.py`) |
| Leen | `19_X2`, `20_X2b`, `21_X4a` |
| Uso | Solo construcción; no consultar para análisis |

Columnas (todas STRING): `cuenta_username`, `cuenta_id_x`, `tweet_id`, `tipo_tweet`, `created_at_utc`, `texto`, `url`, `lang`, `autor_id`, `autor_username`, `retweeted_tweet_id`, `retweeted_user_id`, `retweeted_user`, `retweeted_created_at_utc`, `quoted_tweet_id`, `quoted_user_id`, `quoted_user`, `in_reply_to_tweet_id`, `in_reply_to_user_id`, `in_reply_to_user`, `conversation_id`, `texto_empieza_con_RT`, `like_count`, `retweet_count`, `reply_count`, `quote_count`, `view_count`, `bookmark_count`, `scraped_ts`.
