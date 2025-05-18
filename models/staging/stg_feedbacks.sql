with raw as (
  select * from {{ source('bronze', 'feedbacks') }}
)

select
  raw.feedback_id :: int as feedback_id,
  raw.user_id :: int as user_id,
  raw.course_id :: int as course_id,
  raw.rating :: int as rating,
  raw.submitted_at as submitted_at,
  raw.helpful_votes :: int as helpful_votes,
from raw