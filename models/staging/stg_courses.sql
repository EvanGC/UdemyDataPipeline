with raw as (
  select * from {{ source('bronze', 'courses') }}
)

select
  raw.course_id :: int as course_id,
  raw.category as category,
  raw.level as level,
  raw.duration_hours :: int as duration_hours,
  raw.language as language,
  raw.instructor_id :: int as instructor_id,
  raw.price :: float as price,
  raw.release_date as release_date,
  raw.is_certified as is_certified,
  raw.updated_at as updated_at
from raw