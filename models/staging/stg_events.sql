{{ config(materialized='view') }}

{%- set shared_columns = [
    'event_sk',
    'event_type',
    'event_id',
    'user_id',
    'course_id',
    'event_timestamp'
] -%}

{%- set enrollment_columns = [
    'campaign_id',
    'enrollment_source',
    'enrollment_is_trial',
    'enrollment_updated_at'
] -%}

{%- set view_columns = [
    'view_duration'
] -%}

{%- set completion_columns = [
    'completion_score',
    'completion_days'
] -%}

{%- set feedback_columns = [
    'feedback_rating',
    'feedback_helpful_votes'
] -%}

with
  enrollments as (
    select
      {{ dbt_utils.generate_surrogate_key(['enrollment_id','user_id','course_id','event_timestamp']) }} as event_sk,
      'enrollment' as event_type,
      enrollment_id as event_id,
      user_id,
      course_id,
      event_timestamp,
      -- Enrollment specific columns
      campaign_id,
      enrollment_source,
      enrollment_is_trial,
      enrollment_updated_at,
      {{ null_columns(view_columns) }},
      {{ null_columns(completion_columns) }},
      {{ null_columns(feedback_columns) }}
    from {{ ref('base_enrollments') }}
  ),

  views as (
    select
      {{ dbt_utils.generate_surrogate_key(['view_id','user_id','course_id','event_timestamp']) }} as event_sk,
      'view' as event_type,
      view_id as event_id,
      user_id,
      course_id,
      event_timestamp,
      -- Null columns for enrollment
      {{ null_columns(enrollment_columns) }},
      -- View specific columns
      view_duration,
      -- Null columns for other event types
      {{ null_columns(completion_columns) }},
      {{ null_columns(feedback_columns) }}
    from {{ ref('base_views') }}
  ),

  completions as (
    select
      {{ dbt_utils.generate_surrogate_key(['completion_id','user_id','course_id','event_timestamp']) }} as event_sk,
      'completion' as event_type,
      completion_id as event_id,
      user_id,
      course_id,
      event_timestamp,
      -- Null columns for enrollment and views
      {{ null_columns(enrollment_columns) }},
      {{ null_columns(view_columns) }},
      -- Completion specific columns
      completion_score,
      completion_days,
      -- Null columns for other event types
      {{ null_columns(feedback_columns) }}
    from {{ ref('base_completions') }}
  ),

  feedbacks as (
    select
      {{ dbt_utils.generate_surrogate_key(['feedback_id','user_id','course_id','event_timestamp']) }} as event_sk,
      'feedback' as event_type,
      feedback_id as event_id,
      user_id,
      course_id,
      event_timestamp,
      -- Null columns for other event types
      {{ null_columns(enrollment_columns) }},
      {{ null_columns(view_columns) }},
      {{ null_columns(completion_columns) }},
      -- Feedback specific columns
      feedback_rating,
      feedback_helpful_votes
    from {{ ref('base_feedbacks') }}
  )

select * from enrollments
union all 
select * from views
union all 
select * from completions
union all 
select * from feedbacks
