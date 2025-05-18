with raw as (
  select * from {{ source('bronze', 'campaigns') }}
)

select
  campaign_id :: int as campaign_id,
  campaign_name as campaign_name,
  start_date as start_date,
  end_date as end_date,
  budget_usd :: float as budget_usd,
  platform as platform,
  target_audience as target_audience,
  cta as cta,
  impressions :: int as impressions,
  clicks :: int as clicks,
  signups :: int as signups,
  enrollments :: int as enrollments,
  created_at as created_at,
  updated_at as updated_at
from raw
