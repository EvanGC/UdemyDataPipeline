{{ config(materialized='view') }}

with src as (
    select
      cast(instructor_id as int) as instructor_id,
      full_name,
      expertise,
      cast(rating as float) as rating,
      cast(years_of_experience as integer) as years_of_experience,
      cast(verified as boolean) as verified,
      country,
      to_timestamp(created_at) as created_at,
      to_timestamp(updated_at) as updated_at
    from {{ source('bronze','instructors') }}
)

select
  {{ dbt_utils.generate_surrogate_key(['instructor_id']) }}  as instructor_sk,
  *
from src
