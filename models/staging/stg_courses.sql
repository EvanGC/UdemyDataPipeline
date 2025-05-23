{{ config(materialized='view') }}

with src as (
    select
      course_id as course_id,
      category,
      level,
      cast(duration_hours as float) as duration_hours,
      language,
      instructor_id,
      cast(price as decimal(10,2))  as price,
      to_date(release_date) as release_date,
      cast(is_certified as boolean) as is_certified,
      to_timestamp(updated_at) as updated_at
    from {{ source('bronze','courses') }}
)

select
  {{ dbt_utils.generate_surrogate_key(['course_id']) }}  as course_sk,
  *
from src
