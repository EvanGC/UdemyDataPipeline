{{ config(materialized='table') }}

WITH base AS (
  SELECT * FROM {{ ref('agg_user_course_funnel') }}
),

per_course AS (
  SELECT
    course_key,
    category,
    marketing_source,
    COUNT(*) AS total_users_in_segment, -- Renamed for clarity, represents users in this specific course/category/marketing_source slice
    SUM(CASE WHEN total_enrolls > 0 THEN 1 ELSE 0 END) AS enrolled_users,
    SUM(CASE WHEN total_views > 0 THEN 1 ELSE 0 END) AS viewed_users,
    SUM(CASE WHEN total_completes > 0 THEN 1 ELSE 0 END) AS completed_users,
    SUM(CASE WHEN total_feedbacks > 0 THEN 1 ELSE 0 END) AS feedback_users
  FROM base
  GROUP BY 1, 2, 3
)

SELECT
  course_key,
  category,
  marketing_source,
  total_users_in_segment,
  enrolled_users,
  viewed_users,
  completed_users,
  feedback_users,
  ROUND(
    (enrolled_users * 1.0 / NULLIF(total_users_in_segment, 0)) * 100, 2
  ) AS enrollment_rate,
  ROUND(
    (viewed_users * 1.0 / NULLIF(total_users_in_segment, 0)) * 100, 2
  ) AS view_rate,
  ROUND(
    (completed_users * 1.0 / NULLIF(total_users_in_segment, 0)) * 100, 2
  ) AS completion_rate,
  ROUND(
    (feedback_users * 1.0 / NULLIF(total_users_in_segment, 0)) * 100, 2
  ) AS feedback_rate
FROM per_course
ORDER BY
  course_key,
  category,
  marketing_source