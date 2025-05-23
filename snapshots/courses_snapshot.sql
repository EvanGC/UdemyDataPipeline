{% snapshot courses_snapshot %}
{{
  config(
    target_schema='gold',
    target_database=database,
    unique_key='course_id',
    strategy='timestamp',
    updated_at='updated_at',
    hard_deletes='invalidate'
  )
}}

select
  course_id,
  category,
  level,
  duration_hours,
  language,
  instructor_id,
  price,
  release_date,
  is_certified,
  updated_at
from {{ ref('stg_courses') }}
{% endsnapshot %}
