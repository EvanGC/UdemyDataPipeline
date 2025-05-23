{{
  config(
    materialized='incremental',
    unique_key='user_id, course_id, first_event_time',
    incremental_strategy='merge',
    on_schema_change='sync_all_columns'
  )
}}

with courses as (
  select
    course_id,
    category
  from {{ ref('dim_courses') }}
),
users as (
  select
    user_id,
    marketing_source
  from {{ ref('dim_users') }}
),
user_funnel as (
  select
    user_id,
    course_id,
    event_type,
    first_event_time,
    total_views,
    total_enrolls,
    total_completes,
    total_feedbacks
  from {{ ref('fct_user_course_funnel') }}
)
select
  a.*,
  c.category,
  u.marketing_source,
  c.course_id         as course_key,
  u.user_id           as user_key
from user_funnel a
join courses c using (course_id)
join users u using (user_id)

{% if is_incremental() %}
  where a.first_event_time > (
    select max(first_event_time) from {{ this }}
  )
{% endif %}
