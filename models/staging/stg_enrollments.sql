with raw as (
  select * from {{ source('bronze', 'enrollments') }}
)

select
  raw.enrollment_id :: int as enrollment_id,
  raw.user_id :: int as user_id,
  raw.course_id :: int as course_id,
  raw.enrollment_date as enrollment_date,
  raw.source as enrollment_source,
  raw.is_trial as is_trial,
  raw.completed as completed,
  raw.updated_at as updated_at
from raw