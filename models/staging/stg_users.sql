with raw as (
  select * 
  from {{ source('bronze', 'users') }}
)

select
  user_id :: int as user_id,
  split_part(full_name, ' ', 1)
    || '_' || substr(md5(email), 1, 8) as pseudonym,
  to_date(signup_date,'yyyy-MM-dd') as signup_date,
  gender as gender,
  country as country,
  age :: int as age,
  employment_status as employment_status,
  interests as interests,
  marketing_source as marketing_source,
  is_premium as is_premium,
  created_at as created_at,
  updated_at as updated_at
from raw