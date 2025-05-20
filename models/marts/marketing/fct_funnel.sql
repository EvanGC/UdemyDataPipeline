with base as (
  select * from {{ ref('fct_user_course_funnel') }}
),

per_course as (
  select
    course_id,
    count(*)                          as enrolled,
    sum(did_view)                     as viewed,
    sum(did_completion)               as completed,
    sum(did_feedback)                 as feedback
  from base
  group by 1
)

select
  course_id,
  stage,
  value,
  case when stage = 'enrolled' then 100
       else round(value::numeric / enrolled * 100,2)
  end as pct_of_enrolled
from per_course
cross join lateral (
    values
      ('enrolled',  enrolled::bigint),
      ('viewed',    viewed::bigint),
      ('completed', completed::bigint),
      ('feedback',  feedback::bigint)
  ) as steps(stage, value)
order by course_id,
  case stage 
    when 'enrolled'  then 1 
    when 'viewed'    then 2 
    when 'completed' then 3 
    when 'feedback'  then 4 
  end
