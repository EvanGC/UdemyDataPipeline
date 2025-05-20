{{ config(materialized='table', schema='gold') }}

with dates as (
  select
    distinct event_timestamp as date_key
  from {{ ref('stg_events') }}
),

calendar as (
  select
    date_key,
    date_trunc('month', date_key)::date as month,
    date_part('week', date_key) as week_of_year,
    date_part('year', date_key) as year,
    date_part('dow', date_key) as day_of_week
  from dates
)

select * from calendar
