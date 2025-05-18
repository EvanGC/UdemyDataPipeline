{{ config(materialized='ephemeral') }}

with events as (
  select * 
  from {{ ref('stg_events') }}
  where event_type = 'interaction'
)

select
  e.*,
  si.interaction_timestamp,
  si.interaction_type,
  si.interaction_target_id,
  si.interaction_channel,
  si.interaction_device_type,
  si.interaction_location,
  si.interaction_referral_source,
  si.interaction_session_duration_seconds,
  si.interaction_session_id,
  si.interaction_created_at,
  si.interaction_updated_at,
  si.interaction_event_category
from events e
join {{ ref('stg_interactions') }} as si
  on e.event_id = si.interaction_id
