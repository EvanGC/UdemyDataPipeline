{{ config(materialized='ephemeral') }}

with events as (
  select * 
  from {{ ref('stg_events') }}
  where event_type = 'view'
)

select
  e.*,
  sv.view_timestamp,
  sv.view_duration_seconds,
  sv.view_from_landing_page,
  sv.view_session_id
from events e
join {{ ref('stg_views') }} as sv
  on e.event_id = sv.view_id
