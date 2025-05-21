{{ config(materialized='table', schema='gold') }}

with ordered_funnel as (
  select 
    funnel_stage,
    event_count,
    lag(event_count) over(order by funnel_stage) as prev_stage_count
  from {{ ref('agg_funnel') }}
)

select
  funnel_stage,
  event_count,
  case 
    when funnel_stage = '1. Enrollments' then 100.0
    else round(event_count::numeric / nullif(prev_stage_count,0) * 100, 2)
  end as pct_of_prev_stage
from ordered_funnel
