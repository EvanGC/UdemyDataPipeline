{{ config(materialized='ephemeral') }}

with events as (
  select * 
  from {{ ref('stg_events') }}
  where event_type = 'enrollment'
)

select
  e.*,
  se.enrollment_timestamp,
  se.enrollment_source,
  se.enrollment_is_trial,
  se.enrollment_completed,
  se.enrollment_updated_at,
  se.campaign_id
from events e
join {{ ref('stg_enrollments') }} as se
  on e.event_id = se.enrollment_id
