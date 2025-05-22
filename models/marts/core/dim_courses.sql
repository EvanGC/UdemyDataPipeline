{{ config(materialized='table') }}

select
  course_sk,
  course_id,
  category,
  level,
  duration_hours,
  language,
  instructor_id,
  price,
  release_date,
  is_certified,
  updated_at
from {{ ref('stg_courses') }}
