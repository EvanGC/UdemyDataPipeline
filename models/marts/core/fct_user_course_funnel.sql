{{ config(
    materialized='incremental',
    schema='gold',
    unique_key='event_sk',
    on_schema_change='sync_all_columns'
) }}

with events as (
  select * from {{ ref('stg_events') }}
),
views as (
  select
    event_sk,
    case when event_type = 'view' then 1 else 0 end as did_view,
    0 as did_enroll,
    0 as did_complete,
    0 as did_feedback
  from events
  where event_type = 'view'
),
enrolls as (
  select
    event_sk,
    0 as did_view,
    1 as did_enroll,
    0 as did_complete,
    0 as did_feedback
  from events
  where event_type = 'enrollment'
),
completes as (
  select
    event_sk,
    0 as did_view,
    0 as did_enroll,
    1 as did_complete,
    0 as did_feedback
  from events
  where event_type = 'completion'
),
feedbacks as (
  select
    event_sk,
    0 as did_view,
    0 as did_enroll,
    0 as did_complete,
    1 as did_feedback
  from events
  where event_type = 'feedback'
),
base as (
  select * from views
  union all select * from enrolls
  union all select * from completes
  union all select * from feedbacks
),
aggregated as (
  select
    e.user_id,
    e.course_id,
    min(e.event_timestamp) as first_event_time,
    sum(did_view)    as total_views,
    sum(did_enroll)  as total_enrolls,
    sum(did_complete) as total_completes,
    sum(did_feedback) as total_feedbacks
  from {{ ref('stg_events') }} e
  left join base b using (event_sk)
  group by 1,2
)

select
  a.*,
  c.category,
  u.marketing_source,
  c.course_id         as course_key,
  u.user_id           as user_key
from aggregated a
join {{ ref('dim_courses') }} c using (course_id)
join {{ ref('dim_users') }} u using (user_id)

{% if is_incremental() %}
  where a.first_event_time > (
    select max(first_event_time) from {{ this }}
  )
{% endif %}
