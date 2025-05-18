{{ config(materialized='ephemeral') }}

with events as (
  select * 
  from {{ ref('stg_events') }}
  where event_type = 'completion'
)

select
  e.*,
  sc.completion_timestamp,
  sc.completion_score,
  sc.completion_time_to_complete_days,
  sc.completion_created_at
from events e
join {{ ref('stg_completions') }} as sc
  on e.event_id = sc.completion_id
