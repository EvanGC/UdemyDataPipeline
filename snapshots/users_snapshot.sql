{% snapshot users_snapshot %}
{{
  config(
    target_schema='gold',
    unique_key='user_id',
    strategy='timestamp',
    updated_at='updated_at',
    hard_deletes='invalidate'
  )
}}
select
  user_id,
  email,
  full_name,
  signup_date,
  gender,
  marketing_source,
  is_premium,
  updated_at
from {{ ref('stg_users') }}
{% endsnapshot %}
