{{ config(materialized='view', schema='silver') }}

select
  completion_id,
  user_id,
  course_id,
  to_timestamp(completion_date) as completion_timestamp,
  cast(score as float) as completion_score,
  cast(time_to_complete_days as int) as completion_time_to_complete_days,
  to_timestamp(completed_at) as completion_created_at
from {{ source('bronze','completitions') }}
