{{ config(materialized='view', schema='silver') }}

select
  feedback_id,
  user_id,
  course_id,
  to_timestamp(submitted_at) as feedback_timestamp,
  rating :: int as feedback_rating,
  helpful_votes as feedback_helpful_votes,
  comment_body as feedback_comment,
  to_timestamp(created_at) as feedback_created_at,
  to_timestamp(updated_at) as feedback_updated_at
from {{ source('bronze','feedbacks') }}
  