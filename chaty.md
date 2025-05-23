---

# Informe Power BI: “Marketing Performance”

## Visión general

Como propietario y analista de datos, este informe está diseñado para:

* **Monitorizar el funnel** (enroll → view → complete → feedback).
* **Segmentar** por campaña, curso y cohorte.
* **Rastrear** crecimiento y retención de usuarios con snapshots.

---

## Pasos para implementar en Power BI

1. **Conexión a Snowflake**

   * `Get Data → Snowflake` → Configura cuenta, warehouse, role, database, schema `gold`.

2. **Selecciona tablas/core models**

   * `dim_date`, `dim_users`, `dim_courses`, `dim_campaigns`
   * `fact_events`, `agg_funnel`
   * `fct_funnel` (mart marketing)

3. **Modelo de datos**

   * Relaciona:

     * `fact_events[event_date]` → `dim_date[date_key]`
     * `fact_events[user_id]` → `dim_users[user_id]`
     * `fact_events[course_id]` → `dim_courses[course_id]`
     * `fact_events[campaign_id]` → `dim_campaigns[campaign_id]`
   * Relaciona `agg_funnel` ↔ `dim_users`, `dim_courses`, `dim_campaigns`.

4. **Medidas DAX clave**

   ```sql
   TotalEnroll    = CALCULATE(SUM(agg_funnel[usercourse_count]), agg_funnel[funnel_stage] = "1. Enrollments")
   TotalViews     = CALCULATE(SUM(agg_funnel[usercourse_count]), agg_funnel[funnel_stage] = "2. Views (after enrollment)")
   TotalComplete  = CALCULATE(SUM(agg_funnel[usercourse_count]), agg_funnel[funnel_stage] = "3. Completions (post view)")
   TotalFeedback  = CALCULATE(SUM(agg_funnel[usercourse_count]), agg_funnel[funnel_stage] = "4. Feedbacks (post completion)")

   RateView       = DIVIDE([TotalViews],[TotalEnroll],0)
   RateComplete   = DIVIDE([TotalComplete],[TotalViews],0)
   RateFeedback   = DIVIDE([TotalFeedback],[TotalComplete],0)
   ```

5. **Página 1: Funnel Dashboard**

   * **KPIs**: Tarjetas con `[TotalEnroll]`, `[TotalViews]`, `[TotalComplete]`, `[TotalFeedback]`.
   * **Funnel visual**: Eje `agg_funnel[funnel_stage]`, Valor `agg_funnel[usercourse_count]`.
   * **Bar chart**: Comparar `RateView`, `RateComplete`, `RateFeedback` como porcentaje.
   * **Slicers**: `dim_campaigns[campaign_name]`, `dim_courses[category]`, `dim_date[year]`.

6. **Página 2: User Snapshot & Cohorte**

   * **Snapshot KPIs**: Tarjetas con `COUNTROWS(VALUES(dim_users[user_id]))` y `PremiumUserGrowth (%)` usando snapshot de `snap_users`.
   * **Line chart**: Usuarios activos (`UsersActivePerDay` precomputado) vs tiempo (`dim_date[date_key]`).
   * **Matrix cohort**: `dim_users[cohort_month]` x `days_since_signup` vs `fct_user_cohort[retention_rate]`.

---

## 4. Uso de `dim_date` en análisis

En Power BI:

* Relaciona `fact_events[event_date]` a `dim_date[date_key]`.
* Crea **Slicers** por `dim_date[year]`, `month`.
* En gráficos de series temporales, usa `dim_date[date_key]` en eje X.

---


## 1. Mejora de la analítica de embudo con slicers

### 1.1 Slicers recomendados

En tu **Página 1 (Funnel Overview)** añade estos **slicers** para filtrar dinámicamente el funnel:

* **Dimensión Fecha** (`dim_date[date_key]`):
  Permite acotar el rango de fechas del evento (de enroll a feedback).
* **Dimensión Curso** (`dim_courses[course_name]`):
  Filtra para ver el funnel de un curso en particular.
* **Dimensión Campaña** (`dim_campaigns[campaign_name]`):
  Segmenta por campañas de marketing.
* **Dimensión Usuario Premium** (`dim_users[is_premium]`):
  Para comparar embudos de usuarios free vs premium.

### 1.2 Lógica optimizada del funnel

En lugar de un simple SELECT de etapas sueltas, crea un **agg\_funnel** que precalcule:

```sql
select
  user_id,
  course_id,
  campaign_id,
  -- flags encadenados
  max(case when event_type='enrollment' then 1 else 0 end)             as did_enroll,
  max(case when event_type='view'       and event_timestamp >= min_enroll_dt then 1 else 0 end) as did_view,
  max(case when event_type='completion' and event_timestamp >= min_view_dt   then 1 else 0 end) as did_complete,
  max(case when event_type='feedback'   and event_timestamp >= min_complete_dt then 1 else 0 end) as did_feedback
from (
  select *,
    min(case when event_type='enrollment' then event_timestamp end) over(partition by user_id,course_id,campaign_id) as min_enroll_dt,
    min(case when event_type='view'       then event_timestamp end) over(partition by user_id,course_id,campaign_id) as min_view_dt,
    min(case when event_type='completion' then event_timestamp end) over(partition by user_id,course_id,campaign_id) as min_complete_dt
  from {{ ref('fact_events') }}
) t
group by user_id, course_id, campaign_id
```

Y luego pivota a etapas:

```sql
with agg as ( … )
select
  funnel_stage,
  count(*) as usercourse_count
from (
  select user_id,course_id,campaign_id,
    1 as enrolled,
    did_view       as viewed,
    did_complete   as completed,
    did_feedback   as feedback
  from agg
) t
unpivot (
  usercourse_count for funnel_stage in (enrolled, viewed, completed, feedback)
)  
```

De esa forma aprovechas *toda* la tabla de hechos, y junto con los slicers obtienes embudos dinámicos.

---

## 2. Revisión de la tabla de hechos (`fact_events`)

### 2.1. Modelo normalizado según dbt best practices

```sql
-- models/marts/core/fact_events.sql
{{ config(materialized='table', schema='gold') }}

select
  fe.event_sk,
  fe.event_id,
  fe.event_timestamp,
  date_trunc('day', fe.event_timestamp)::date as event_date,  -- FK a dim_date
  fe.user_id,     -- FK a dim_users
  fe.course_id,   -- FK a dim_courses
  fe.campaign_id, -- FK a dim_campaigns
  fe.event_type,  -- FK a dim_event_type
  -- Métricas específicas
  fe.view_duration_seconds,
  fe.completion_score,
  fe.feedback_rating,
  fe.interaction_channel,
  fe.interaction_device_type
from {{ ref('stg_events') }} fe
```

#### YML Tests & Docs

```yaml
# models/marts/core/_core__models.yml
version: 2
models:
  - name: fact_events
    description: "Tabla de hechos plana con llaves a todas las dimensiones."
    columns:
      - name: event_sk;          tests: [not_null, unique]
      - name: event_date;        tests: [not_null, relationships: {to: ref('dim_date'), field: date_key}]
      - name: user_id;           tests: [not_null, relationships: {to: ref('dim_users'), field: user_id}]
      - name: course_id;         tests: [not_null, relationships: {to: ref('dim_courses'), field: course_id}]
      - name: campaign_id;       tests: [relationships: {to: ref('dim_campaigns'), field: campaign_id}]
      - name: event_type;        tests: [not_null, relationships: {to: ref('dim_event_type'), field: event_type}]
      - name: view_duration_seconds;   tests: [greater_than_or_equal_to: {value: 0}]
      - name: completion_score;        tests: [greater_than_or_equal_to: {value: 0}]
      - name: feedback_rating;         tests: [accepted_values: {values: [1,2,3,4,5]}]
```

---

## 3. Página 2: User Snapshots

La **Página 2** muestra la evolución de usuarios en el tiempo usando tu **snapshot** `snap_users` y la dimensión `dim_date`.

### 3.1 Medidas DAX en Power BI

* **Total Users**

  ```dax
  TotalUsers = DISTINCTCOUNT(snap_users[user_id])
  ```
* **New Users by Day**

  ```dax
  NewUsers = 
    CALCULATE(
      DISTINCTCOUNT(snap_users[user_id]),
      FILTER(
        ALL(dim_date),
        dim_date[date_key] = snap_users[dbt_valid_from]
      )
    )
  ```
* **Churned Users by Day** (aquellos con `dbt_valid_to` igual a esa fecha)

  ```dax
  ChurnedUsers = 
    CALCULATE(
      DISTINCTCOUNT(snap_users[user_id]),
      FILTER(
        ALL(dim_date),
        dim_date[date_key] = snap_users[dbt_valid_to]
      )
    )
  ```
* **Active Users**

  ```dax
  ActiveUsers = [TotalUsers] - [ChurnedUsers]
  ```

### 3.2 Visuales recomendados

1. **Line chart** de **TotalUsers**, **NewUsers** y **ActiveUsers** vs `dim_date[date_key]`.
2. **Bar chart** acumulado de **NewUsers** por mes (`dim_date[month]`).
3. **KPI Cards**:

   * Usuarios totales actuales
   * Usuarios nuevos del mes
   * Tasa de churn (ChurnedUsers / TotalUsers).

### 3.3 Slicers y filters

* **Rango de fechas** (`dim_date[year]`, `month`)
* **Segmentación por tipo** (`dim_users[is_premium]`, `marketing_source`)

---

## Justificación de pasos

1. **Slicers** en embudo: permiten responder preguntas “How did campaign X perform in May?” o “Did premium users convert better?”
2. **Fact\_events** normalizado: cada métrica de evento vive en su columna y referenciada a dimensiones, mejor rendimiento y claridad.
3. **Página Snapshots**: explota el SCD-2 para ver crecimiento, churn y retención, crucial para decisiones de producto y marketing.

Con esta estructura, todos los análisis son **reproducibles**, **documentados**, **probados** y **modulares**, cumpliendo con las mejores prácticas de dbt y dando a Power BI la flexibilidad necesaria.
