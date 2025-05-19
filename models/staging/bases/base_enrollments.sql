{{ config(materialized='incremental') }}

select
    enrollment_id as event_id,
    user_id,
    course_id,
    to_timestamp(enrollment_date) as event_timestamp,
    'enrollment' as event_type,
    source as enrollment_source,
    is_trial as enrollment_is_trial,
    completed as enrollment_completed,
    campaign_id
from {{ source('bronze','enrollments') }}
