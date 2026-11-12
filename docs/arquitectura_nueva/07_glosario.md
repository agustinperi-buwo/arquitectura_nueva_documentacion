# 07 · Glosario

[← Índice](README.md)

| Término | Definición |
|---|---|
| **Arquitectura vieja** | Datasets por categoría (`medios`, `influencers`, `institucionales`, …) con tablas de texto. Sigue activa durante el paralelo. |
| **Arquitectura nueva** | Dataset `posteos_unificado` descripto en esta documentación. |
| **Captura** | Una lectura de un posteo por un scraper en un momento (`scraped_at`). Un posteo tiene una o más. |
| **Corte de día argentino** | Asignar un posteo al día de `time_created − 3 h`. |
| **Cuenta monitoreada** | Cuenta presente en `cuentas` y en al menos un proyecto. |
| **`cuenta_match`** | Regla con la que se vinculó una fila a una cuenta (`id`, `username`, `alias`, `nombre_normalizado`, `sin_cuenta`). |
| **Día UTC** | Corte por fecha UTC de `time_created` (arquitectura vieja). |
| **Enunciador** | Actor de la matriz de enunciadores (subproyecto `enunciadores`, 2021-07 a 2025-12). |
| **Entidad** | Persona u organización detrás de una o más cuentas; se identifica con `nombre_normalizado`. |
| **Idempotente** | Correr la carga dos veces deja el mismo resultado (MERGE por clave). |
| **MERGE** | Sentencia de BigQuery que inserta o actualiza según coincida la clave. |
| **Paralelo** | Período en que ambas arquitecturas se alimentan del mismo scrapeo para compararlas. |
| **Poda de partición** | Lectura solo de las particiones mensuales que cubre el filtro de fecha. |
| **Relación (X)** | Reply, quote o retweet de una cuenta hacia otro tweet (`x_relaciones`). |
| **Retweet con envoltorio** | Retweet capturado como tweet propio con texto `RT @autor: …`. |
| **Retweet sin envoltorio** | Id del tweet original asociado a la cuenta sin que exista un tweet propio del retweet. |
| **`SCRAPEO_COMPARTIDO`** | Variable que amplía las ventanas de los scrapers para que un scrapeo sirva a ambas arquitecturas. |
| **Snapshot** | Copia cruda de los posts de una corrida (`data/snapshots/<fecha>/posts_<red>__<hora>.csv`), guardada antes del filtro de la vieja. |
| **Staging** | Tabla temporal `_stg_*` usada por los cargadores antes del MERGE. |
| **Tweet referido** | Tweet citado, respondido o retuiteado por una cuenta monitoreada (`tweets_referidos`). |
