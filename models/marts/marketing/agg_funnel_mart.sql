{{ config(materialized='table', schema='gold') }}

WITH base AS (
  SELECT * FROM {{ ref('fct_user_course_funnel') }}
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
  stage,
  value,
  CASE
    WHEN stage = 'enrolled' THEN
      -- If enrolled_users > 0 for this stage, it's 100% of itself. Otherwise, 0%.
      CASE WHEN value > 0 THEN 100.00 ELSE 0.00 END
    ELSE
      -- For other stages, calculate percentage of enrolled_users.
      -- Use NULLIF to prevent division by zero, resulting in NULL if no enrollments.
      -- Multiply by 100.0 to ensure floating point arithmetic before division for precision.
      ROUND(value::NUMERIC * 100.0 / NULLIF(enrolled_users, 0), 2)
  END AS pct_of_enrolled
FROM per_course
CROSS JOIN LATERAL (
  VALUES
    ('enrolled', enrolled_users), -- Ensured these are actual counts
    ('viewed', viewed_users),
    ('completed', completed_users),
    ('feedback', feedback_users)
) AS steps(stage, value)
ORDER BY
  course_key,
  category,
  marketing_source,
  CASE stage
    WHEN 'enrolled'  THEN 1
    WHEN 'viewed'    THEN 2
    WHEN 'completed' THEN 3
    WHEN 'feedback'  THEN 4
    ELSE 5 -- Should not happen with current VALUES clause
  END