{{ config(materialized='ephemeral') }}

select
    completion_id as event_id,
    user_id,
    course_id,
    to_timestamp(completion_date) as event_timestamp,
    'completion' as event_type,
    null as event_subtype,
    score as completion_score,
    time_to_complete_days as completion_days
from {{ source('bronze','completitions') }}
