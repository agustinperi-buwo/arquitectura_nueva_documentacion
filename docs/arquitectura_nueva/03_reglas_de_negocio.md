# 03 · Reglas de negocio

[← Índice](README.md)

## 1. Resolución de la cuenta

Cada posteo (y transcripción) trae del scraper un id de cuenta (`account_id_origen`), un `username` y a veces un `nombre_normalizado`. La cuenta se resuelve en este orden; la primera regla que encuentra coincidencia gana y queda registrada en `cuenta_match`.

```mermaid
flowchart TD
    A["Fila del scraper<br/>(red, account_id_origen, username, nombre_normalizado)"] --> B{"account_id_origen<br/>= cuentas.cuenta_id?"}
    B -- Sí --> R1["cuenta_match = id"]
    B -- No --> C{"LOWER(username) = username<br/>de UNA sola cuenta de la red?"}
    C -- Sí --> R2["cuenta_match = username"]
    C -- No --> D{"LOWER(username)<br/>en cuentas_alias?"}
    D -- Sí --> R3["cuenta_match = alias"]
    D -- No --> E{"nombre_normalizado = el de<br/>UNA sola cuenta de la red?"}
    E -- Sí --> R4["cuenta_match = nombre_normalizado"]
    E -- No --> R5["cuenta_match = sin_cuenta<br/>cuenta_id = NULL"]
```

- Las búsquedas por `username` y `nombre_normalizado` solo aplican si identifican **una única** cuenta en la red (`HAVING COUNT(*) = 1`).
- Usernames de cuentas con ids ajenos o ambiguos no se resuelven por username.
- `x_relaciones` usa id → username → alias (sin `nombre_normalizado`) y descarta lo que no resuelve.
- `comentarios.cuenta_id` es la cuenta dueña del posteo: se toma de `posteos` y, si el posteo no está, del `account_id` del CSV.

## 2. Fechas y zonas horarias

| Campo | Cómo llega | Cómo se guarda |
|---|---|---|
| `time_created` (posteos) | Texto `dd/mm/aaaa hh:mm:ss` en **UTC** | `TIMESTAMP` UTC |
| `scraped_at` (posteos, metas) | Texto en **hora argentina** (`dd/mm/aaaa hh:mm:ss` o `aaaa-mm-dd hh:mm:ss`), salvo ISO con `Z` (ya UTC) | `TIMESTAMP` UTC (se suman 3 h) |
| `timestamp`, `scraped_at` (comentarios) | Texto sin zona | `TIMESTAMP` tomado como UTC (igual que la arquitectura vieja) |
| Metas sin `scraped_at` (histórico) | — | Se asigna la última captura del posteo y `scraped_ts_inferido = TRUE` |

Argentina = UTC−3 sin horario de verano (`DESFASE_ARG = 3 h`).

## 3. Corte de día

Un posteo pertenece al **día argentino** de su `time_created`:

```
dia_argentino = DATE(time_created - 3 h)
```

| Arquitectura | Corte | Consecuencia |
|---|---|---|
| Vieja | Día UTC | Los posteos de 21:00 a 23:59 ARG caen en el día siguiente y, si la corrida del día siguiente no los recupera, se pierden (Facebook graph ~50/día; X por `LIMITE_DIARIO`; IG por tope de Apify) |
| Nueva | Día argentino | Sin hueco. Con `SCRAPEO_COMPARTIDO=1` la ventana de extracción cubre UTC D 00:00 a D+1 02:59:59 y cada arquitectura recorta lo suyo |

## 4. Deduplicación

| Tabla | Clave | Ante duplicados |
|---|---|---|
| `posteos_capturas` | `red`, `post_id`, `scraped_at` | Migración: mayor `like_count`. Carga diaria: no pisa capturas existentes |
| `posteos` | `red`, `post_id` | Última captura (`scraped_at DESC, cargado_ts DESC`) |
| `meta_<red>` | `post_id`, `scraped_at` | No pisa capturas existentes |
| `comentarios` | `red`, `post_id`, `comment_id` | `scraped_at` más reciente; actualiza `likes`, `replies_count` |
| `transcripciones` | `red`, `post_id` | Texto más largo |
| `x_relaciones` | `cuenta_id`, `tipo`, `tweet_referido_id`, `post_id` | No pisa |
| `tweets_referidos` | `tweet_id` | Primera captura; completa vacíos |

## 5. Proyectos

- Los hechos no tienen proyecto. Proyecto de un posteo = `proyecto_cuentas` de su cuenta.
- Una cuenta en dos proyectos aparece dos veces en `v_posteos`: filtrar por `proyecto_id`.
- Alcance por defecto de los procesos diarios: proyecto `cordoba` (medios, influencers, institucionales).
- Altas nuevas: fila en `proyectos` + cuentas en `cuentas` (con id nativo) o `cuentas_pendientes` (sin id) + `proyecto_cuentas`.

## 6. Vocabulario

| Campo | Valores |
|---|---|
| `red` | `facebook`, `instagram`, `tiktok`, `x`, `youtube` (minúscula; `twitter` → `x`) |
| `cuenta_match` | `id`, `username`, `alias`, `nombre_normalizado`, `sin_cuenta` |
| `x_relaciones.tipo` | `reply`, `quote`, `retweet`, `retweet_sin_envoltorio` |
| `meta_x.tipo_tweet` | `original`, `reply`, `quote` |
| `posteos_clasificados.modelo_version` | `bert_v1` |

## 7. `nombre_normalizado`

Clave canónica de la entidad, común a todas sus redes: nombre completo en **minúscula**, **sin tildes** y **sin lo que va entre paréntesis** (apodos, siglas). Permite agrupar la presencia multiplataforma de un mismo actor.
