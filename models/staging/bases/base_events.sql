{{ config(
    materialized = 'incremental',
    schema = 'bronze',
    unique_key = 'event_sk',
    on_schema_change = 'append_new_columns'
) }}

with enrollments as (
    select
      enrollment_id as event_id,
      user_id,
      course_id,
      to_timestamp(enrollment_date) as event_timestamp,
      'enrollment' as event_type,
      null as event_subtype
    from {{ source('bronze','enrollments') }}
),

completions as (
    select
      completion_id as event_id,
      user_id,
      course_id,
      to_timestamp(completion_date) as event_timestamp,
      'completion' as event_type,
      null as event_subtype
    from {{ source('bronze','completions') }}
),

views as (
    select
      view_id as event_id,
      user_id,
      course_id,
      to_timestamp(view_date) as event_timestamp,
      'view' as event_type,
      null as event_subtype
    from {{ source('bronze','views') }}
),

interactions as (
    select
      interaction_id as event_id,
      user_id,
      course_id,
      to_timestamp(timestamp) as event_timestamp,
      'interaction' as event_type,
      event_type as event_subtype
    from {{ source('bronze','user_interactions') }}
),

feedbacks as (
    select
      feedback_id as event_id,
      user_id,
      course_id,
      to_timestamp(submitted_at) as event_timestamp,
      'feedback' as event_type,
      null as event_subtype
    from {{ source('bronze','feedbacks') }}
),

all_events as (
    select * from enrollments
    union all
    select * from completions
    union all
    select * from views
    union all
    select * from interactions
    union all
    select * from feedbacks
)

select
  {{ codegen.generate_surrogate_key([
      'event_id',
      'user_id',
      'course_id',
      'event_type',
      'event_timestamp'
    ]) }} as event_sk,
  event_id,
  user_id,
  course_id,
  event_timestamp,
  event_type,
  event_subtype
from all_events

{% if is_incremental() %}
  where event_timestamp > (
    select max(event_timestamp)
    from {{ this }}
  )
{% endif %}
