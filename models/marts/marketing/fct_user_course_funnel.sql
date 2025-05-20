{{ config(materialized='table', schema='gold') }}

with ev as (
  select * 
  from {{ ref('int_event_enriched') }}
),

-- 1) Primera inscripción
enroll as (
  select
    user_id,
    course_id,
    campaign_id,
    min(event_timestamp) as first_enroll_ts
  from ev
  where event_type = 'enrollment'
  group by 1,2,3
),

-- 2) Primera vista **después** de inscribirse
view as (
  select
    e.user_id,
    e.course_id,
    e.campaign_id,
    min(v.event_timestamp) as first_view_ts
  from enroll e
  join ev v
    on v.user_id = e.user_id
   and v.course_id = e.course_id
   and v.event_type = 'view'
   and v.event_timestamp > e.first_enroll_ts
  group by 1,2,3
),

-- 3) Primera completion tras la vista
completion as (
  select
    v.user_id,
    v.course_id,
    v.campaign_id,
    min(c.event_timestamp) as first_completion_ts
  from view v
  join ev c
    on c.user_id = v.user_id
   and c.course_id = v.course_id
   and c.event_type = 'completion'
   and c.event_timestamp > v.first_view_ts
  group by 1,2,3
),

-- 4) Primer feedback tras la completion
feedback as (
  select
    c.user_id,
    c.course_id,
    c.campaign_id,
    min(f.event_timestamp) as first_feedback_ts
  from completion c
  join ev f
    on f.user_id = c.user_id
   and f.course_id = c.course_id
   and f.event_type = 'feedback'
   and f.event_timestamp > c.first_completion_ts
  group by 1,2,3
),

-- 5) Combinamos todo y derivamos flags
funnel as (
  select
    e.user_id,
    e.course_id,
    e.campaign_id,
    e.first_enroll_ts,
    v.first_view_ts,
    c.first_completion_ts,
    f.first_feedback_ts
  from enroll e
  left join view       v on v.user_id = e.user_id and v.course_id = e.course_id and v.campaign_id = e.campaign_id
  left join completion c on c.user_id = e.user_id and c.course_id = e.course_id and c.campaign_id = e.campaign_id
  left join feedback   f on f.user_id = e.user_id and f.course_id = e.course_id and f.campaign_id = e.campaign_id
),

-- 6) Flags y métricas
final as (
  select
    *,
    1 as did_enroll,
    case when first_view_ts       is not null then 1 else 0 end as did_view,
    case when first_completion_ts is not null then 1 else 0 end as did_completion,
    case when first_feedback_ts   is not null then 1 else 0 end as did_feedback
  from funnel
)

select
  *,
  -- tasas encadenadas
  coalesce(did_view::float     / nullif(did_enroll,0),     0) as rate_view,
  coalesce(did_completion::float / nullif(did_view,0),     0) as rate_completion,
  coalesce(did_feedback::float   / nullif(did_completion,0),0) as rate_feedback
from final
