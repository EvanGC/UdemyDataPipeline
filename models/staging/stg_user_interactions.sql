with raw as (
  select * from {{ source('bronze', 'user_interactions') }}
)

select
  raw.interaction_id :: int as interaction_id,
  raw.user_id :: int as user_id,
  raw.event_type as event_type,
  raw.event_category as event_category,
  raw.device_type as device_type,
  raw.timestamp as event_timestamp,
  raw.location as location,
  raw.referral_source as referral_source,
  raw.session_duration_seconds :: int as session_duration_seconds,
  raw.session_id as session_id,
  raw.created_at as created_at,
  raw.updated_at as updated_at
from raw