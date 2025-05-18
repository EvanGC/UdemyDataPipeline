with raw as (
  select * from {{ source('bronze', 'instructors') }}
)

select
  instructor_id :: int as instructor_id,
  full_name as full_name,
  expertise as expertise,
  rating as rating,
  years_of_experience as years_of_experience,
  verified as verified,
  country as country,
  created_at as created_at,
  updated_at as updated_at
from raw