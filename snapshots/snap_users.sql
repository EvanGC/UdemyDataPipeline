{% snapshot snap_users %}

{{
  config(
    target_schema = 'silver',
    unique_key = 'user_id',
    strategy = 'timestamp',
    updated_at = 'updated_at',
    hard_deletes = 'invalidate'
  )
}}

select
  user_id,
  signup_date,
  age,
  country
  gender,
  marketing_source,
  is_premium,
  created_at,
  updated_at
from {{ ref('stg_users') }}

{% endsnapshot %}
