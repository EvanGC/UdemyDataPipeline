{{ config(materialized='table') }}

select
  campaign_sk,
  campaign_id,
  campaign_name,
  start_date,
  end_date,
  clicks,
  signups,
  enrollments,
  created_at,
  updated_at
from {{ ref('stg_campaigns') }}
