{{ config(materialized='view', schema='silver') }}

select
  enrollment_id,
  user_id,
  course_id,
  to_timestamp(enrollment_date) as enrollment_timestamp,
  campaign_id,
  source as enrollment_source,
  cast(is_trial as boolean) as enrollment_is_trial,
  cast(completed as boolean) as enrollment_completed,
  to_timestamp(updated_at) as enrollment_updated_at
from {{ source('bronze','enrollments') }}
