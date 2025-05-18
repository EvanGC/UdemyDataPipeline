{{ config(
    materialized = 'view',
    schema = 'silver'
) }}

with raw as (
    select
      event_sk,
      event_id,
      user_id,
      course_id,
      event_timestamp,
      event_type,
      event_subtype
    from {{ ref('base_events') }}
),

-- derivamos atributos de fecha/hora
parsed as (
    select
      *,
      date_trunc('day', event_timestamp)::date as event_date,
      date_part('hour', event_timestamp) as event_hour
    from raw
),

-- incorporamos campaña solo en enrollments
with_campaign as (
    select
      p.*,
      enrl.source as enrollment_source,
      enrl.is_trial as enrollment_is_trial,
      enrl.completed as enrollment_completed,
      cam.campaign_name as campaign_name
    from parsed p
    left join {{ source('bronze', 'enrollments') }} as enrl
      on p.event_type = 'enrollment'
      and p.event_id = enrl.enrollment_id
    left join {{ source('bronze', 'campaigns') }} as cam
      on enrl.campaign_id = cam.campaign_id
)

select * from with_campaign
