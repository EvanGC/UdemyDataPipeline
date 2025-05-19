{{ config(materialized='view', schema='silver') }}

with enroll as (
  select
    event_id,
    user_id,
    course_id,
    event_timestamp,
    'enrollment' as event_type,
    campaign_id
  from {{ ref('base_enrollments') }}
),

comp as (
  select
    event_id,
    user_id,
    course_id,
    event_timestamp,
    'completion' as event_type,
    null as campaign_id
  from {{ ref('base_completions') }}
),

vw as (
  select
    event_id,
    user_id,
    course_id,
    event_timestamp,
    'view' as event_type,
    null as campaign_id
  from {{ ref('base_views') }}
),

fb as (
  select
    event_id,
    user_id,
    course_id,
    event_timestamp,
    'feedback' as event_type,
    null as campaign_id
  from {{ ref('base_feedbacks') }}
),

ui as (
  select
    event_id,
    user_id,
    course_id,
    event_timestamp,
    'interaction' as event_type,
    null as campaign_id
  from {{ ref('base_interactions') }}
),

all_events as (
  select * from enroll
  union all select * from comp
  union all select * from vw
  union all select * from fb
  union all select * from ui
)

select
  {{ dbt_utils.generate_surrogate_key([
      'event_type',
      'event_id',
      'user_id',
      'course_id',
      'event_timestamp'
    ]) }} as event_sk,
  event_type,
  event_id,
  user_id,
  course_id,
  event_timestamp,
  campaign_id
from all_events
