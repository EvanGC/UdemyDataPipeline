{{ config(materialized='ephemeral') }}

with ev as (
  select * from {{ ref('stg_events') }}
),

usr as (
  select
    {{ dbt_utils.generate_surrogate_key(['user_id']) }} as user_sk,
    user_id,
    email,
    signup_date
  from {{ ref('stg_users') }}
),

crs as (
  select
    {{ dbt_utils.generate_surrogate_key(['course_id']) }} as course_sk,
    course_id,
    category,
    level
  from {{ ref('stg_courses') }}
),

cmp as (
  select
    {{ dbt_utils.generate_surrogate_key(['campaign_id']) }} as campaign_sk,
    campaign_id,
    campaign_name
  from {{ ref('stg_campaigns') }}
)

select
  ev.*,
  usr.user_sk,
  usr.email,
  crs.course_sk,
  crs.category,
  crs.level,
  cmp.campaign_sk,
  cmp.campaign_name,
  datediff(day, usr.signup_date, ev.event_timestamp) as days_since_signup
from ev
left join usr on ev.user_id = usr.user_id
left join crs on ev.course_id = crs.course_id
left join cmp on ev.campaign_id = cmp.campaign_id
