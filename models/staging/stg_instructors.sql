with raw as (
  select * from {{ source('bronze', 'instructors') }}
)

select
  raw.instructor_id :: int as instructor_id,
  raw.full_name as full_name,
  raw.expertise as expertise,
  raw.rating as rating,
  raw.years_of_experience as years_of_experience,
  raw.verified as verified,
  raw.country as country,
  raw.created_at as created_at,
  raw.updated_at as updated_at
from raw