with raw as (
  select * from {{ source('bronze', 'views') }}
)

select
  raw.view_id :: int as view_id,
  raw.user_id :: int as user_id,
  raw.course_id :: int as course_id,
  raw.view_date as view_date,
  raw.duration_seconds :: int as duration_seconds,
  raw.from_landing_page as from_landing_page,
  raw.session_id as session_id
from raw