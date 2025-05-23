{{ config(materialized='ephemeral') }}

with ee as (
  select
    user_id, course_id, campaign_id,
    min(case when event_type='enrollment' then event_timestamp end) as first_enroll_dt
  from {{ ref('stg_events') }}
  group by 1,2,3
),

fv as (
  select
    ee.*,
    min(case when event_type='view' then event_timestamp end)  as first_view_dt,
    min(case when event_type='completion' then event_timestamp end)  as first_completion_dt
  from ee
  left join {{ ref('stg_events') }} e
    on e.user_id = ee.user_id
   and e.course_id = ee.course_id
   and e.campaign_id = ee.campaign_id
   and e.event_timestamp >= ee.first_enroll_dt
  group by 1,2,3,4
),

fc as (
  select
    fv.*,
    min(case when event_type='feedback' then event_timestamp end) as first_feedback_dt
  from fv
  left join {{ ref('stg_events') }} e
    on e.user_id = fv.user_id
   and e.course_id = fv.course_id
   and e.campaign_id = fv.campaign_id
   and e.event_timestamp >= fv.first_completion_dt
  group by 1,2,3,4,5,6
)

select * from fc
