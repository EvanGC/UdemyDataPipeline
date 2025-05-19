{{ config(materialized='view', schema='silver') }}

with src as (
    select
      campaign_id as campaign_id,
      campaign_name,
      to_date(start_date) as start_date,
      to_date(end_date) as end_date,
      budget_usd :: float as budget_usd,
      platform as platform,
      target_audience as target_audience,
      cta as cta,
      impressions :: int as impressions,
      cast(clicks as integer) as clicks,
      cast(signups as integer) as signups,
      cast(enrollments as integer) as enrollments,
      to_timestamp(created_at) as created_at,
      to_timestamp(updated_at) as updated_at
    from {{ source('bronze','campaigns') }}
)

select
  {{ dbt_utils.generate_surrogate_key(['campaign_id']) }}  as campaign_sk,
  *
from src

