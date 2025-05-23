{{ config(
    materialized     = 'incremental',
    unique_key       = 'view_id',
    on_schema_change = 'append_new_columns'
) }}

select
    view_id,
    user_id,
    course_id,
    to_timestamp(view_date) as event_timestamp,
    duration_seconds as view_duration,
    session_id as view_session_id
from {{ source('bronze','views') }}


{% if is_incremental() %}
  where view_date > (
    select max(event_timestamp) from {{ this }}
  )
{% endif %}