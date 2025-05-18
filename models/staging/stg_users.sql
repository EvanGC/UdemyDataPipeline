with raw as (
  select * 
  from {{ source('bronze', 'users') }}
),
-- CTE que une completions con courses para obtener categoría de cada curso completado
user_completions as (
  select
    c.user_id,
    cr.category,
    c.completion_date,
    row_number() over (
      partition by c.user_id 
      order by c.completion_date desc
    ) as rn
  from {{ source('bronze', 'completitions') }} as c
  join {{ source('bronze', 'courses') }}      as cr
    on c.course_id = cr.course_id
)

select
  raw.user_id :: int as user_id,
  lower(raw.email) as email,
  split_part(raw.full_name, ' ', 1)
    || '_' || substr(md5(raw.email), 1, 8) as pseudonym,
  raw.signup_date as signup_date,
  -- Sólo una categoría (interest) del curso más recientemente completado. TODO: MIRAR DONDE PONERLO SI EN GOLD O AQUI
  uc.category as interest,
  raw.marketing_source as marketing_source,
  raw.is_premium as is_premium,
  raw.created_at as created_at,
  raw.updated_at as updated_at
from raw
left join user_completions uc
  on raw.user_id = uc.user_id
  and uc.rn = 1