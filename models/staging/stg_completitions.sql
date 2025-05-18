with raw as (
  select * from {{ source('bronze', 'completitions') }}
)

select
  raw.completion_id :: int as completion_id,
  raw.user_id :: int as user_id,
  raw.course_id :: int as course_id,
  raw.completion_date as completion_date,
  raw.score :: float as score,
  raw.time_to_complete_days :: int as time_to_complete_days
from raw