{{ config(materialized='table', schema='gold') }}

with src as (
  select
    user_sk,
    user_id,
    email,
    signup_date,
    gender,
    country,
    age,
    marketing_source,
    is_premium
  from {{ ref('stg_users') }}
)

select * from src
