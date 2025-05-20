{{ config(materialized='table', schema='gold') }}

with src as (
  select
    user_sk,
    user_id,
    email,
    full_name,
    signup_date,
    gender,
    marketing_source,
    is_premium,
    created_at,
    updated_at
  from {{ ref('stg_users') }}
)

select * from src
