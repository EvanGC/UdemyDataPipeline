{{ config(materialized='table') }}

select
  event_sk,
  event_type,
  event_id,
  user_id,
  course_id,
  event_timestamp,
  event_timestamp::date as event_date,
  campaign_id,
  enrollment_source,
  enrollment_is_trial,
  view_duration,
  completion_score,
  completion_days,
  feedback_rating,
  feedback_helpful_votes
from {{ ref('stg_events') }}
