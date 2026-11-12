# Posteos — Arquitectura de datos

Modelo de datos en BigQuery con publicaciones, comentarios y transcripciones de cuentas públicas de **Facebook, Instagram, TikTok, X y YouTube**, organizado para análisis.

| | |
|---|---|
| Proyecto GCP | `cordoba-489013` |
| Dataset | `posteos_unificado` |
| Región | `southamerica-east1` |

## Documentación

👉 **[Empezar acá](docs/arquitectura_nueva/README.md)**

| Documento | Contenido |
|---|---|
| [Modelo de datos](docs/arquitectura_nueva/01_modelo_de_datos.md) | Diagramas entidad-relación y claves |
| [Diccionario de datos](docs/arquitectura_nueva/02_diccionario/) | Ficha de cada tabla y columna |
| [Reglas del modelo](docs/arquitectura_nueva/03_reglas_de_negocio.md) | Cuentas, fechas, día argentino, X |
| [Guía de consultas](docs/arquitectura_nueva/04_guia_de_consultas.md) | Buenas prácticas de costo y ejemplos |
| [Estructura anterior](docs/arquitectura_nueva/05_estructura_anterior.md) | Equivalencias con los datasets por categoría |
| [Glosario](docs/arquitectura_nueva/06_glosario.md) | Términos usados |

## Para empezar

- Para informes por proyecto, usar la vista **`v_posteos`** filtrando por `proyecto_id`.
- Filtrar siempre por fecha (`time_created` en posteos y `timestamp` en comentarios) y configurar **Maximum bytes billed**.
- Todas las fechas están en UTC. Para contar por día argentino: `DATE(time_created, 'America/Argentina/Buenos_Aires')`.
