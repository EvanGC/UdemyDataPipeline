{{ config(materialized='view', schema='silver') }}

with src as (
    select
      user_id as user_id,
      lower(email) as email,
      full_name,
      to_date(signup_date) as signup_date,
      gender,
      marketing_source,
      country,
      age :: int as age,
      interests as interests,
      cast(is_premium as boolean) as is_premium,
      to_timestamp(created_at)  as created_at,
      to_timestamp(updated_at)  as updated_at
    from {{ source('bronze','users') }}
)

select
  {{ dbt_utils.generate_surrogate_key(['user_id']) }}  as user_sk,
  *
from src
