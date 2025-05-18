{{ config(
    materialized = 'incremental',
    schema = 'silver',
    unique_key = 'interaction_id',
    on_schema_change = 'append_new_columns'
) }}

select
  interaction_id as interaction_id,
  user_id,
  course_id,
  to_timestamp(timestamp) as interaction_timestamp,
  interaction_type,
  target_id as interaction_target_id,
  channel as interaction_channel,
  device_type as interaction_device_type,
  location as interaction_location,
  referral_source as interaction_referral_source,
  cast(session_duration_seconds as int) as interaction_session_duration_seconds,
  session_id as interaction_session_id,
  to_timestamp(created_at) as interaction_created_at,
  to_timestamp(updated_at) as interaction_updated_at,
  event_category as interaction_event_category
from {{ source('bronze','user_interactions') }}

{% if is_incremental() %}
  where timestamp > (
    select max(interaction_timestamp)
    from {{ this }}
  )
{% endif %}
