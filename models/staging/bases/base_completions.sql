{{ config(
    materialized     = 'incremental',
    unique_key       = 'completion_id',
    on_schema_change = 'append_new_columns'
) }}

select
    completion_id,
    user_id,
    course_id,
    to_timestamp(completion_date) as event_timestamp,
    score as completion_score,
    time_to_complete_days as completion_days
from {{ source('bronze','completions') }}


{% if is_incremental() %}
  where completion_date > (
    select max(event_timestamp) from {{ this }}
  )
{% endif %}