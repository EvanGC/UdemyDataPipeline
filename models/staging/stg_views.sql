{{ config(materialized='view', schema='silver') }}

select
  view_id,
  user_id,
  course_id,
  to_timestamp(view_date) as view_timestamp,
  cast(duration_seconds as int) as view_duration_seconds,
  cast(from_landing_page as boolean) as view_from_landing_page,
  session_id as view_session_id
from {{ source('bronze','views') }}
