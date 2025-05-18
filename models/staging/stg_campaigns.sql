with raw as (
  select * from {{ source('bronze', 'campaigns') }}
)

select
  raw.campaign_id :: int as campaign_id,
  raw.campaign_name as campaign_name,
  raw.start_date as start_date,
  raw.end_date as end_date,
  raw.budget_usd :: float as budget_usd,
  raw.platform as platform,
  raw.target_audience as target_audience,
  raw.cta as cta,
  raw.impressions :: int as impressions,
  raw.clicks :: int as clicks,
  raw.signups :: int as signups,
  raw.enrollments :: int as enrollments,
  raw.created_at as created_at,
  raw.updated_at as updated_at
from raw
