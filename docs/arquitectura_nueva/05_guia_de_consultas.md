# 05 · Guía de consultas

[← Índice](README.md)

BigQuery cobra por bytes leídos. El modelo está particionado y clusterizado para que una consulta bien escrita lea solo lo necesario.

## Reglas de costo

1. **Configurar siempre *Maximum bytes billed*** en la consola (Más → Configuración de consulta) o `maximum_bytes_billed` en el cliente.
2. **Filtrar por la columna de partición con un rango literal**:
   - `posteos`, `posteos_capturas`, `meta_<red>`: `time_created >= TIMESTAMP('…') AND time_created < TIMESTAMP('…')`
   - `comentarios`: `timestamp >= … AND timestamp < …`
3. **Filtrar por las columnas de clustering** (`red`, `post_id`, `comment_id`, `cuenta_id`) cuando se pueda.
4. **Nunca `SELECT *`** en `comentarios`, `comentarios_normalizados` ni `autores`: pedir solo las columnas necesarias (el costo es por columna leída).
5. Evitar funciones sobre la columna de partición en el `WHERE` (`DATE(time_created) = …` puede impedir la poda; preferir el rango).
6. `LIMIT` no reduce el costo.
7. Para metadatos usar `INFORMATION_SCHEMA` o `__TABLES__` (costo mínimo).
8. Correr el script completo, sin texto seleccionado, con cabecera `PASO / HACE / COSTO / ESPERADO`.

## Tamaño de referencia (04/11/2026)

| Tabla | Tamaño | Cuidado |
|---|---:|---|
| `comentarios` | 5,2 GB | Alto: siempre rango de `timestamp` y columnas puntuales |
| `comentarios_normalizados` | 2,5 GB | Alto: sin partición; filtrar por `red` y unir por `comment_id` |
| `autores` | 1,1 GB | Medio: sin partición |
| `posteos_capturas` | 577 MB | Rango de `time_created` |
| `posteos` | 553 MB | Rango de `time_created` |
| Resto | < 210 MB | — |

## Consultas tipo

### Posteos de un proyecto por día argentino

```sql
SELECT DATE(time_created, 'America/Argentina/Buenos_Aires') AS dia_arg, red, COUNT(*) AS posts
FROM `cordoba-489013.posteos_unificado.v_posteos`
WHERE proyecto_id = 'cordoba'
  AND time_created >= TIMESTAMP('2026-11-03 03:00:00') AND time_created < TIMESTAMP('2026-11-10 03:00:00')
GROUP BY dia_arg, red
ORDER BY dia_arg, red;
```

### Frescura por red

```sql
SELECT red, MAX(time_created) AS ultimo_posteo_utc, MAX(scraped_at) AS ultima_captura_utc,
       COUNTIF(cuenta_id IS NULL) AS sin_cuenta
FROM `cordoba-489013.posteos_unificado.posteos`
WHERE time_created >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 40 DAY)
GROUP BY red;
```

### Cobertura de comentarios (capturados vs. declarados)

```sql
WITH p AS (
  SELECT red, post_id, comment_count
  FROM `cordoba-489013.posteos_unificado.posteos`
  WHERE time_created >= TIMESTAMP('2026-11-01') AND time_created < TIMESTAMP('2026-11-08')
),
c AS (
  SELECT red, post_id, COUNT(*) AS capturados
  FROM `cordoba-489013.posteos_unificado.comentarios`
  WHERE timestamp >= TIMESTAMP('2026-11-01') AND timestamp < TIMESTAMP('2026-11-20')
  GROUP BY red, post_id
)
SELECT p.red, SUM(p.comment_count) AS declarados, SUM(IFNULL(c.capturados, 0)) AS capturados,
       SAFE_DIVIDE(SUM(IFNULL(c.capturados, 0)), SUM(p.comment_count)) AS cobertura
FROM p LEFT JOIN c USING (red, post_id)
GROUP BY p.red;
```

### Presencia multiplataforma de una entidad

```sql
SELECT c.nombre_normalizado, p.red, COUNT(*) AS posts, SUM(p.like_count) AS likes
FROM `cordoba-489013.posteos_unificado.posteos` p
JOIN `cordoba-489013.posteos_unificado.cuentas` c USING (red, cuenta_id)
WHERE c.nombre_normalizado = '<entidad>'
  AND p.time_created >= TIMESTAMP('2026-10-01') AND p.time_created < TIMESTAMP('2026-11-01')
GROUP BY 1, 2;
```

### Hilo de respuestas de un comentario

```sql
SELECT comment_id, parent_id, username, text, timestamp
FROM `cordoba-489013.posteos_unificado.comentarios`
WHERE red = 'instagram' AND post_id = '<post_id>'
  AND timestamp >= TIMESTAMP('2026-11-01') AND timestamp < TIMESTAMP('2026-12-01')
ORDER BY COALESCE(parent_id, comment_id), timestamp;
```

## Scripts de control existentes

| Archivo | Uso |
|---|---|
| `migracion_unificada/G1_esquema_posteos_unificado.sql` | Esquema real, filas y tamaño por tabla |
| `migracion_unificada/G2_frescura_posteos_unificado.sql` | Último posteo y captura por red |
| `ARQ_NUEVA/chequeo_frescura_ambas_*.sql` | Posteos por día argentino, vieja vs. nueva |
| `ARQ_NUEVA/chequeo_comentarios_totales_*.sql` | Comentarios distintos por red, vieja vs. nueva |
| `ARQ_NUEVA/cobertura_semanal_nueva_*.sql` | Cobertura semanal (jueves a hoy, Córdoba) |
| `docs/arquitectura_nueva/sql/D1_relevamiento_documentacion.sql` | Esquema + dominios de valores para actualizar esta documentación |
