{{ config(
    materialized     = 'incremental',
    unique_key       = 'enrollment_id',
    on_schema_change = 'append_new_columns'
) }}

select
    enrollment_id,
    user_id,
    course_id,
    to_timestamp(enrollment_date) as event_timestamp,
    campaign_id,
    source as enrollment_source,
    is_trial as enrollment_is_trial,
    updated_at as enrollment_updated_at
from {{ source('bronze','enrollments') }}

{% if is_incremental() %}
  where enrollment_date > (
    select max(event_timestamp) from {{ this }}
  )
{% endif %}