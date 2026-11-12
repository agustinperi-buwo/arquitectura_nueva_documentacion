# 02.6 · X: relaciones

[← Diccionario](README.md)

**Regla:** `posteos` guarda solo lo que la cuenta escribió. Citar, responder o retuitear es una **relación** entre la cuenta y otro tweet: va en `x_relaciones`. El tweet referido se guarda una sola vez en `tweets_referidos`, aunque su autor no sea una cuenta monitoreada. Las métricas del tweet original viven solo en `tweets_referidos` (un retweet replica las vistas del original; guardarlas en ambos lados las contaría dos veces).

| Lo que hizo la cuenta | `posteos` | `x_relaciones` | `tweets_referidos` |
|---|---|---|---|
| Tweet original | Sí | — | — |
| Respuesta (reply) | Sí | `tipo = reply`, `post_id` = tweet propio | Tweet respondido |
| Cita (quote) | Sí | `tipo = quote`, `post_id` = tweet propio | Tweet citado |
| Retweet con original identificado | No | `tipo = retweet` | Tweet original |
| Retweet sin original identificado | No | — | — → `x_retweets_sin_original` |

---

## `x_relaciones`

| Atributo | Valor |
|---|---|
| Propósito | Quién responde, cita o retuitea a qué tweet |
| Grano | Una relación de una cuenta con un tweet |
| Clave lógica | `cuenta_id` + `tipo` + `tweet_referido_id` + `post_id` |
| Partición / clustering | — / `cuenta_id`, `tipo` |
| Volumen de referencia | ~320 mil filas |

| Columna | Tipo | Descripción |
|---|---|---|
| `red` | STRING | Siempre `x`. |
| `cuenta_id` | STRING | Cuenta monitoreada que actúa (→ `cuentas`). |
| `tipo` | STRING | `reply`, `quote`, `retweet`, `retweet_sin_envoltorio`. |
| `tweet_referido_id` | STRING | Tweet respondido / citado / retuiteado (→ `tweets_referidos.tweet_id`). |
| `autor_referido_id` | STRING | Id del autor del tweet referido. |
| `autor_referido_username` | STRING | Usuario del autor del tweet referido. |
| `post_id` | STRING | Tweet propio que genera la relación (en reply/quote está en `posteos`; en retweet es el id del retweet). NULL en `retweet_sin_envoltorio`. |
| `relacion_at` | TIMESTAMP | Momento de la relación (UTC). NULL en `retweet_sin_envoltorio`. |
| `scraped_at` | TIMESTAMP | Momento de la lectura. |
| `fuente` | STRING | Origen del registro. |
| `cargado_ts` | TIMESTAMP | Momento de ingreso a BigQuery. |

```sql
-- Autores más retuiteados por cada cuenta
SELECT r.cuenta_id, r.autor_referido_username, COUNT(*) AS retweets
FROM `cordoba-489013.posteos_unificado.x_relaciones` r
WHERE r.tipo = 'retweet' AND r.relacion_at >= TIMESTAMP('2026-10-01')
GROUP BY 1, 2 ORDER BY retweets DESC LIMIT 50;
```

---

## `tweets_referidos`

| Atributo | Valor |
|---|---|
| Propósito | Tweets citados, respondidos o retuiteados por las cuentas monitoreadas |
| Grano | Un tweet |
| Clave lógica | `tweet_id` |
| Partición / clustering | — / `tweet_id` |
| Volumen de referencia | ~240 mil filas |
| Métricas | Corresponden a la **primera lectura** del tweet; lecturas posteriores solo completan campos vacíos |

| Columna | Tipo | Descripción |
|---|---|---|
| `red` | STRING | Siempre `x`. |
| `tweet_id` | STRING | Id del tweet. |
| `autor_id` | STRING | Id del autor. |
| `autor_username` | STRING | Usuario del autor. |
| `texto` | STRING | Texto del tweet. |
| `created_at` | TIMESTAMP | Publicación (UTC). |
| `like_count` | INT64 | Likes. |
| `retweet_count` | INT64 | Retweets. |
| `reply_count` | INT64 | Respuestas. |
| `quote_count` | INT64 | Citas. |
| `view_count` | INT64 | Vistas. |
| `bookmark_count` | INT64 | Guardados. |
| `lang` | STRING | Idioma. |
| `url` | STRING | URL. |
| `fuente` | STRING | Origen del registro. |
| `scraped_at` | TIMESTAMP | Momento de la lectura conservada. |
| `cargado_ts` | TIMESTAMP | Momento de ingreso a BigQuery. |

```sql
-- Relaciones con el texto del tweet referido
SELECT r.cuenta_id, r.tipo, t.autor_username, t.texto, t.like_count
FROM `cordoba-489013.posteos_unificado.x_relaciones` r
JOIN `cordoba-489013.posteos_unificado.tweets_referidos` t ON t.tweet_id = r.tweet_referido_id
WHERE r.cuenta_id = '<cuenta_id>' AND r.relacion_at >= TIMESTAMP('2026-11-01');
```

---

## `x_retweets_sin_original`

| Atributo | Valor |
|---|---|
| Propósito | Retweets cuyo tweet original no pudo identificarse |
| Grano | Un retweet |
| Clave lógica | `post_id` |
| Partición / clustering | — / `cuenta_id` |
| Volumen de referencia | ~130 mil filas, concentradas en cuentas de Estados Unidos |

| Columna | Tipo | Descripción |
|---|---|---|
| `red` | STRING | `x`. |
| `cuenta_id` | STRING | Cuenta que retuiteó. |
| `username` | STRING | Usuario de la cuenta. |
| `post_id` | STRING | Id del retweet. |
| `retweet_at` | TIMESTAMP | Momento del retweet (UTC). |
| `texto` | STRING | Texto del retweet (`RT @autor: …`). |
| `autor_original_username` | STRING | Autor del original (tomado del texto). |
| `autor_original_id` | STRING | Id del autor original, si se conoce. |
| `url` | STRING | URL del retweet. |
| `scraped_at` | TIMESTAMP | Momento de la lectura. |
| `fuente` | STRING | Origen del registro. |
| `cargado_ts` | TIMESTAMP | Momento de ingreso a BigQuery. |

> Para contar todos los retweets de una cuenta, sumar `x_relaciones` (`tipo` = `retweet`) y `x_retweets_sin_original`.
