{{ config(
    materialized     = 'incremental',
    unique_key       = 'feedback_id',
    on_schema_change = 'append_new_columns'
) }}

select
    feedback_id,
    user_id,
    course_id,
    to_timestamp(submitted_at) as event_timestamp,
    rating as feedback_rating,
    helpful_votes as feedback_helpful_votes
from {{ source('bronze','feedbacks') }}

{% if is_incremental() %}
  where submitted_at > (
    select max(event_timestamp) from {{ this }}
  )
{% endif %}