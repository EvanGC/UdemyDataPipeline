{{ config(materialized='view', schema='silver') }}

select
  completion_id,
  user_id,
  course_id,
  to_timestamp(completion_date) as completion_timestamp,
  score :: float as completion_score,
  time_to_complete_days :: int as completion_time_to_complete_days
from {{ source('bronze','completitions') }}
