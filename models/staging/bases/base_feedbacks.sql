{{ config(materialized='ephemeral') }}

select
    feedback_id as event_id,
    user_id,
    course_id,
    to_timestamp(submitted_at) as event_timestamp,
    'feedback' as event_type,
    null as event_subtype,
    rating as feedback_rating,
    helpful_votes as feedback_helpful_votes
from {{ source('bronze','feedbacks') }}
