# 01 · Modelo de datos

[← Índice](README.md)

El dataset se organiza en seis dominios:

| Dominio | Tablas | Rol |
|---|---|---|
| Proyectos y cuentas | `proyectos`, `proyecto_cuentas`, `cuentas`, `cuentas_perfil`, `cuentas_alias`, `cuentas_ids_alternativos`, `cuentas_pendientes`, `correcciones_maestro` | Dimensiones: quién es cada cuenta y a qué proyecto pertenece |
| Posteos | `posteos_capturas`, `posteos` | Hechos: cada publicación y su historial de métricas |
| Metadatos por red | `meta_facebook`, `meta_instagram`, `meta_tiktok`, `meta_x`, `meta_youtube` | Campos propios de cada red, por captura |
| Contenido | `comentarios`, `transcripciones` | Comentarios de los posteos y transcripción de videos |
| X | `x_relaciones`, `tweets_referidos`, `x_retweets_sin_original` | Retweets, citas y respuestas como relaciones |
| Enriquecimientos | `posteos_clasificados`, `comentarios_normalizados`, `autores` | Salidas de modelos (clasificación, limpieza de texto, inferencia demográfica) |
| Vistas | `v_posteos`, `v_cuentas_actual` | Lectura para informes |

---

## 1. Diagrama general (claves)

```mermaid
erDiagram
    proyectos ||--o{ proyecto_cuentas : "proyecto_id"
    cuentas ||--o{ proyecto_cuentas : "red + cuenta_id"
    cuentas ||--o{ cuentas_perfil : "red + cuenta_id"
    cuentas ||--o{ cuentas_alias : "red + cuenta_id"
    cuentas ||--o{ cuentas_ids_alternativos : "red + cuenta_id"
    cuentas ||--o{ correcciones_maestro : "red + cuenta_id"
    cuentas |o--o{ posteos : "red + cuenta_id"
    cuentas |o--o{ posteos_capturas : "red + cuenta_id"
    cuentas |o--o{ comentarios : "red + cuenta_id (dueña del post)"
    cuentas |o--o{ transcripciones : "red + cuenta_id"
    posteos ||--|{ posteos_capturas : "red + post_id"
    posteos_capturas ||--o| meta_facebook : "post_id + scraped_at"
    posteos_capturas ||--o| meta_instagram : "post_id + scraped_at"
    posteos_capturas ||--o| meta_tiktok : "post_id + scraped_at"
    posteos_capturas ||--o| meta_x : "post_id + scraped_at"
    posteos_capturas ||--o| meta_youtube : "post_id + scraped_at"
    posteos ||--o{ comentarios : "red + post_id"
    posteos ||--o| transcripciones : "red + post_id"
    posteos ||--o{ posteos_clasificados : "red + post_id"
    comentarios ||--o| comentarios_normalizados : "red + comment_id"
    autores ||--o{ comentarios : "red + author_id"
    cuentas ||--o{ x_relaciones : "cuenta_id (red = x)"
    posteos |o--o{ x_relaciones : "post_id (reply / quote)"
    tweets_referidos ||--o{ x_relaciones : "tweet_id = tweet_referido_id"
    cuentas ||--o{ x_retweets_sin_original : "cuenta_id (red = x)"

    proyectos {
        string proyecto_id PK
    }
    proyecto_cuentas {
        string proyecto_id PK,FK
        string red PK,FK
        string cuenta_id PK,FK
    }
    cuentas {
        string red PK
        string cuenta_id PK
    }
    cuentas_perfil {
        string red PK,FK
        string cuenta_id PK,FK
        timestamp scraped_at PK
    }
    cuentas_alias {
        string red PK
        string alias PK
        string cuenta_id FK
    }
    cuentas_ids_alternativos {
        string red PK
        string id_alternativo PK
        string cuenta_id FK
    }
    correcciones_maestro {
        string red
        string cuenta_id FK
    }
    posteos {
        string red PK
        string post_id PK
        string cuenta_id FK
    }
    posteos_capturas {
        string red PK
        string post_id PK
        timestamp scraped_at PK
        string cuenta_id FK
    }
    meta_facebook {
        string post_id PK
        timestamp scraped_at PK
    }
    meta_instagram {
        string post_id PK
        timestamp scraped_at PK
    }
    meta_tiktok {
        string post_id PK
        timestamp scraped_at PK
    }
    meta_x {
        string post_id PK
        timestamp scraped_at PK
    }
    meta_youtube {
        string post_id PK
        timestamp scraped_at PK
    }
    comentarios {
        string red PK
        string post_id PK
        string comment_id PK
        string author_id FK
        string cuenta_id FK
    }
    transcripciones {
        string red PK
        string post_id PK
    }
    posteos_clasificados {
        string red PK
        string post_id PK
        string modelo_version PK
    }
    comentarios_normalizados {
        string red PK
        string comment_id PK
    }
    autores {
        string red PK
        string author_id PK
    }
    x_relaciones {
        string cuenta_id PK
        string tipo PK
        string tweet_referido_id PK
        string post_id PK
    }
    tweets_referidos {
        string tweet_id PK
    }
    x_retweets_sin_original {
        string cuenta_id
        string post_id PK
    }
```


---

## 2. Dominio: proyectos y cuentas

```mermaid
erDiagram
    proyectos ||--o{ proyecto_cuentas : contiene
    cuentas ||--o{ proyecto_cuentas : pertenece
    cuentas ||--o{ cuentas_perfil : "historial de perfil"
    cuentas ||--o{ cuentas_alias : "alias de username"
    cuentas ||--o{ cuentas_ids_alternativos : "ids alternativos"
    cuentas ||--o{ correcciones_maestro : "correcciones aplicadas"

    proyectos {
        string proyecto_id PK
        string nombre
        string territorio
        string cliente
        date fecha_inicio
        date fecha_fin
    }
    proyecto_cuentas {
        string proyecto_id PK,FK
        string red PK,FK
        string cuenta_id PK,FK
        string origen
        date fecha_alta
        date fecha_baja
    }
    cuentas {
        string red PK
        string cuenta_id PK
        string username
        string nombre_normalizado
        string nombre
        string categoria
        string provincia
        string ciudad
        string cuenta_id_origen
        string revisar
    }
    cuentas_perfil {
        string red PK
        string cuenta_id PK
        timestamp scraped_at PK
        string nombre_normalizado
        string username
        int64 seguidores
        int64 seguidos
        int64 publicaciones
        int64 me_gusta
        int64 vistas_totales
        bool verificado
        string bio
        string ubicacion
        string url
        timestamp ultima_actualizacion
        string cuenta_match
        timestamp cargado_ts
    }
    cuentas_alias {
        string red PK
        string alias PK
        string cuenta_id FK
    }
    cuentas_ids_alternativos {
        string red PK
        string id_alternativo PK
        string cuenta_id FK
        string username
        int64 filas
        string motivo
    }
    correcciones_maestro {
        string red
        string username_maestro
        string username_correcto
        string cuenta_id FK
        string accion
        string motivo
    }
    cuentas_pendientes {
        string red
        string username
        string nombre_normalizado
        string nombre
        string categoria
        string provincia
        string ciudad
    }
```

`cuentas_pendientes` no se relaciona: guarda cuentas conocidas **sin id nativo resuelto**. Cuando se resuelve el id, la cuenta pasa a `cuentas` (+ `proyecto_cuentas`).

---

## 3. Dominio: posteos y metadatos

```mermaid
erDiagram
    posteos ||--|{ posteos_capturas : "1 post = N capturas"
    posteos_capturas ||--o| meta_facebook : "red = facebook"
    posteos_capturas ||--o| meta_instagram : "red = instagram"
    posteos_capturas ||--o| meta_tiktok : "red = tiktok"
    posteos_capturas ||--o| meta_x : "red = x"
    posteos_capturas ||--o| meta_youtube : "red = youtube"

    posteos {
        string red PK
        string post_id PK
        string username
        string name
        string description
        int64 comment_count
        int64 like_count
        int64 playcount
        string url
        string account_id_origen
        string nombre_normalizado
        timestamp scraped_at
        timestamp time_created "particion mensual"
        string cuenta_id FK
        string cuenta_match
        timestamp cargado_ts
        int64 n_capturas
        timestamp cargado_posteos_ts
    }
    posteos_capturas {
        string red PK
        string post_id PK
        timestamp scraped_at PK
        string username
        string name
        string description
        int64 comment_count
        int64 like_count
        int64 playcount
        string url
        string account_id_origen
        string nombre_normalizado
        timestamp time_created "particion mensual"
        string cuenta_id FK
        string cuenta_match
        timestamp cargado_ts
    }
    meta_facebook {
        string post_id PK
        timestamp scraped_at PK
        int64 reaction_count
        int64 share_count
        string post_type
        timestamp time_created "particion mensual"
    }
    meta_instagram {
        string post_id PK
        timestamp scraped_at PK
        string typename
        string shortcode
        string tagged_users
        timestamp time_created "particion mensual"
    }
    meta_tiktok {
        string post_id PK
        timestamp scraped_at PK
        int64 save_count
        int64 sharecount
        float64 duration
        timestamp time_created "particion mensual"
    }
    meta_x {
        string post_id PK
        timestamp scraped_at PK
        string tipo_tweet
        int64 retweet_count
        int64 view_count
        timestamp time_created "particion mensual"
    }
    meta_youtube {
        string post_id PK
        timestamp scraped_at PK
        int64 duration_secs
        string title
        string tipo
        timestamp time_created "particion mensual"
    }
```

Las tablas `meta_<red>` se muestran resumidas; el detalle completo está en [02.3](02_diccionario/03_metas_por_red.md). La red no figura como columna en las metas: la define la tabla.

---

## 4. Dominio: contenido y enriquecimientos

```mermaid
erDiagram
    posteos ||--o{ comentarios : "red + post_id"
    posteos ||--o| transcripciones : "red + post_id"
    posteos ||--o{ posteos_clasificados : "red + post_id"
    comentarios ||--o| comentarios_normalizados : "red + comment_id"
    autores ||--o{ comentarios : "red + author_id"
    comentarios ||--o{ comentarios : "parent_id (respuestas)"

    comentarios {
        string red PK
        string post_id PK
        string comment_id PK
        string parent_id
        string cuenta_id FK
        string post_url
        string username
        string nickname
        string author_id FK
        string text
        timestamp timestamp "particion mensual"
        int64 likes
        int64 replies_count
        timestamp scraped_at
        timestamp cargado_ts
    }
    transcripciones {
        string red PK
        string post_id PK
        string account_id_origen
        string username
        string url
        string texto
        string cuenta_id FK
        string cuenta_match
        timestamp cargado_ts
    }
    posteos_clasificados {
        string red PK
        string post_id PK
        string modelo_version PK
        string categoria
        float64 confianza
        string red_match
        timestamp clasificado_ts
        timestamp cargado_ts
    }
    comentarios_normalizados {
        string red PK
        string comment_id PK
        string post_id
        string author_id
        string clean_comment
        string respuesta_a
        string version_norm
        timestamp fecha_proceso
        timestamp cargado_ts
    }
    autores {
        string red PK
        string author_id PK
        int64 sex_id
        string metodo
        string token
        string valores
        string version_genero
        timestamp fecha_proceso
        timestamp cargado_ts
    }
```

---

## 5. Dominio: X

```mermaid
erDiagram
    cuentas ||--o{ x_relaciones : "cuenta que actúa"
    posteos |o--o{ x_relaciones : "tweet propio (reply / quote)"
    tweets_referidos ||--o{ x_relaciones : "tweet citado / respondido / retuiteado"
    cuentas ||--o{ x_retweets_sin_original : "cuenta que retuiteó"

    x_relaciones {
        string red
        string cuenta_id PK,FK
        string tipo PK "reply | quote | retweet | retweet_sin_envoltorio"
        string tweet_referido_id PK,FK
        string post_id PK "NULL en retweet_sin_envoltorio"
        string autor_referido_id
        string autor_referido_username
        timestamp relacion_at
        timestamp scraped_at
        string fuente
        timestamp cargado_ts
    }
    tweets_referidos {
        string red
        string tweet_id PK
        string autor_id
        string autor_username
        string texto
        timestamp created_at
        int64 like_count
        int64 retweet_count
        int64 reply_count
        int64 quote_count
        int64 view_count
        int64 bookmark_count
        string lang
        string url
        string fuente
        timestamp scraped_at
        timestamp cargado_ts
    }
    x_retweets_sin_original {
        string red
        string cuenta_id FK
        string username
        string post_id PK
        timestamp retweet_at
        string texto
        string autor_original_username
        string autor_original_id
        string url
        timestamp scraped_at
        string fuente
        timestamp cargado_ts
    }
```

```mermaid
flowchart TD
    T["Tweet capturado de una cuenta monitoreada"] --> Q{"¿Es retweet<br/>con envoltorio?"}
    Q -- "Sí, con id del original" --> R1["x_relaciones (tipo = retweet)<br/>+ tweets_referidos (original)"]
    Q -- "Sí, sin id del original" --> R2["x_retweets_sin_original"]
    Q -- "No" --> A{"¿Autor = cuenta monitoreada?"}
    A -- "No (tweet ajeno)" --> F["No se guarda en posteos"]
    A -- "Sí" --> P["posteos + posteos_capturas + meta_x"]
    P --> T2{"¿reply o quote?"}
    T2 -- "Sí" --> R3["x_relaciones (tipo = reply / quote, post_id = tweet propio)<br/>+ tweets_referidos (tweet respondido / citado)"]
    T2 -- "No (original)" --> FIN["Solo posteos"]
```

---

## 6. Cardinalidades

| Origen | Destino | Cardinalidad | Unión |
|---|---|---|---|
| `proyectos` | `proyecto_cuentas` | 1 : N | `proyecto_id` |
| `cuentas` | `proyecto_cuentas` | 1 : N (una cuenta puede estar en varios proyectos) | `red`, `cuenta_id` |
| `cuentas` | `cuentas_perfil` | 1 : N (historial) | `red`, `cuenta_id` |
| `cuentas` | `cuentas_alias` | 1 : 0..N | `red`, `cuenta_id` |
| `cuentas` | `cuentas_ids_alternativos` | 1 : 0..N | `red`, `cuenta_id` |
| `cuentas` | `posteos`, `posteos_capturas`, `transcripciones` | 0..1 : N (`cuenta_id` puede ser NULL) | `red`, `cuenta_id` |
| `cuentas` | `comentarios` | 0..1 : N (cuenta dueña del post comentado) | `red`, `cuenta_id` |
| `posteos` | `posteos_capturas` | 1 : 1..N | `red`, `post_id` |
| `posteos_capturas` | `meta_<red>` | 1 : 0..1 | `post_id`, `scraped_at` (+ red implícita) |
| `posteos` | `comentarios` | 1 : 0..N | `red`, `post_id` |
| `posteos` | `transcripciones` | 1 : 0..1 | `red`, `post_id` |
| `posteos` | `posteos_clasificados` | 1 : 0..N (una por `modelo_version`) | `red`, `post_id` |
| `comentarios` | `comentarios_normalizados` | 1 : 0..1 | `red`, `comment_id` |
| `autores` | `comentarios` | 1 : N | `red`, `author_id` |
| `comentarios` | `comentarios` (respuestas) | 1 : 0..N | `parent_id` = `comment_id` |
| `tweets_referidos` | `x_relaciones` | 1 : N | `tweet_id` = `tweet_referido_id` |
| `posteos` (x) | `x_relaciones` | 0..1 : N | `post_id` |

> BigQuery no impone claves primarias ni foráneas: las claves de este documento son **lógicas**. Su unicidad la garantiza el proceso de carga.

## 7. Partición y clustering

| Tabla | Partición | Clustering |
|---|---|---|
| `posteos_capturas` | `TIMESTAMP_TRUNC(time_created, MONTH)` | `red`, `post_id` |
| `posteos` | `TIMESTAMP_TRUNC(time_created, MONTH)` | `red`, `post_id` |
| `meta_facebook` … `meta_youtube` | `TIMESTAMP_TRUNC(time_created, MONTH)` | `post_id` |
| `comentarios` | `TIMESTAMP_TRUNC(timestamp, MONTH)` | `red`, `post_id`, `comment_id` |
| `transcripciones` | — | `red`, `post_id` |
| `cuentas` | — | `red`, `cuenta_id` |
| `cuentas_perfil` | — | `red`, `cuenta_id` |
| `proyecto_cuentas` | — | `proyecto_id`, `red` |
| `posteos_clasificados` | — | `post_id` |
| `comentarios_normalizados` | — | `red`, `comment_id` |
| `autores` | — | `red`, `author_id` |
| `x_relaciones` | — | `cuenta_id`, `tipo` |
| `tweets_referidos` | — | `tweet_id` |
| `x_retweets_sin_original` | — | `cuenta_id` |
| resto (dimensiones chicas) | — | — |
