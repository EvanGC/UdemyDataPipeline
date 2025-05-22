{{ config(
    materialized='table',
    schema='gold'
) }}

with events_with_ts as (

  select
    fe.user_id,
    fe.course_id,
    fe.event_type,
    fe.event_timestamp,

    -- Calculamos en cada fila el primer timestamp de cada etapa
    min(case when fe.event_type = 'enrollment' then fe.event_timestamp end)
      over(partition by fe.user_id, fe.course_id) as min_enroll_ts,

    min(case when fe.event_type = 'view' then fe.event_timestamp end)
      over(partition by fe.user_id, fe.course_id) as min_view_ts,

    min(case when fe.event_type = 'completion' then fe.event_timestamp end)
      over(partition by fe.user_id, fe.course_id) as min_comp_ts,

    min(case when fe.event_type = 'feedback' then fe.event_timestamp end)
      over(partition by fe.user_id, fe.course_id) as min_fb_ts

  from {{ ref('fct_events') }} fe

),

agg_flags as (

  select
    user_id,
    course_id,

    -- Flags: 1 si existe esa etapa, 0 si no
    max(case when event_type = 'enrollment' then 1 else 0 end)       as did_enroll,
    max(case when event_type = 'view'
             and event_timestamp >= min_enroll_ts then 1 else 0 end) as did_view,
    max(case when event_type = 'completion'
             and event_timestamp >= min_view_ts   then 1 else 0 end) as did_complete,
    max(case when event_type = 'feedback'
             and event_timestamp >= min_comp_ts   then 1 else 0 end) as did_feedback

  from events_with_ts
  group by 1,2

),

pivoted as (

  select
    user_id,
    course_id,
    did_enroll    as enrolled,
    did_view      as viewed,
    did_complete  as completed,
    did_feedback  as feedback

  from agg_flags

),

unpivoted as (

  select
    user_id,
    course_id,
    enrolled,
    viewed,
    completed,
    feedback,
    case
      when enrolled = 1 and viewed = 0 and completed = 0 and feedback = 0 then 'enrollment'
      when enrolled = 1 and viewed = 1 and completed = 0 and feedback = 0 then 'view'
      when enrolled = 1 and viewed = 1 and completed = 1 and feedback = 0 then 'completion'
      when enrolled = 1 and viewed = 1 and completed = 1 and feedback = 1 then 'feedback'
    end as funnel_stage,
  from pivoted

)

SELECT 
  user_id,
  course_id,
  funnel_stage,
  count(*) as event_count
FROM unpivoted
WHERE funnel_stage IS NOT NULL
GROUP BY 1,2,3
ORDER BY 1,2,3