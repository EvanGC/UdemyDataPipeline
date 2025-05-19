{{ config(materialized='ephemeral') }}

select
    view_id as event_id,
    user_id,
    course_id,
    to_timestamp(view_date) as event_timestamp,
    'view' as event_type,
    null as event_subtype,
    duration_seconds as view_duration,
    from_landing_page,
    session_id as view_session_id
from {{ source('bronze','views') }}
