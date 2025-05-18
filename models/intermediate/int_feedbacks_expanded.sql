{{ config(materialized='ephemeral') }}

with events as (
  select * 
  from {{ ref('stg_events') }}
  where event_type = 'feedback'
)

select
  e.*,
  sf.feedback_timestamp,
  sf.feedback_rating,
  sf.feedback_helpful_votes,
  sf.feedback_comment,
  sf.feedback_created_at,
  sf.feedback_updated_at
from events e
join {{ ref('stg_feedbacks') }} as sf
  on e.event_id = sf.feedback_id
