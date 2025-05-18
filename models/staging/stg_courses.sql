with raw as (
  select * from {{ source('bronze', 'courses') }}
)

select
  course_id :: int as course_id,
  category as category,
  level as level,
  duration_hours :: int as duration_hours,
  language as language,
  instructor_id :: int as instructor_id,
  price :: float as price,
  release_date as release_date,
  is_certified as is_certified,
  updated_at as updated_at
from raw