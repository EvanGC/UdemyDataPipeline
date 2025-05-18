{% snapshot snap_instructors %}

{{
  config(
    target_schema = 'silver',
    unique_key    = 'instructor_id',
    strategy      = 'timestamp',
    updated_at    = 'updated_at',
    hard_deletes  = 'invalidate'
  )
}}

select
  instructor_id,
  full_name,
  expertise,
  rating,
  years_of_experience,
  verified,
  country,
  created_at,
  updated_at
from {{ ref('stg_instructors') }}

{% endsnapshot %}
