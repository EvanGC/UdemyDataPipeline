{{ config(materialized='ephemeral') }}

select
    interaction_id as event_id,
    user_id,
    course_id,
    to_timestamp(timestamp) as event_timestamp,
    'interaction' as event_type,
    event_type as event_subtype,
    device_type as interaction_device,
    location as interaction_location,
    referral_source as interaction_source,
    session_duration_seconds as interaction_duration,
    session_id as interaction_session_id,
    event_category as interaction_category
from {{ source('bronze','user_interactions') }}
