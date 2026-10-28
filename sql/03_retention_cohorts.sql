-- =====================================================
-- 03_retention_cohorts.sql
-- Monthly retention: users grouped by the month they first appeared.
-- Months are calculated in UTC to avoid time-zone shifts.
-- Note: the data starts on 24 Sep 2020, so the Sep cohort is partial.
-- =====================================================

WITH first_seen AS (
  SELECT user_id, DATE_TRUNC('month', MIN(event_time) AT TIME ZONE 'UTC') AS cohort_month
  FROM events_clean
  GROUP BY user_id
),
activity AS (
  SELECT DISTINCT user_id, DATE_TRUNC('month', event_time AT TIME ZONE 'UTC') AS active_month
  FROM events_clean
),
cohort_data AS (
  SELECT
    f.cohort_month,
    (EXTRACT(YEAR FROM a.active_month) * 12 + EXTRACT(MONTH FROM a.active_month))
      - (EXTRACT(YEAR FROM f.cohort_month) * 12 + EXTRACT(MONTH FROM f.cohort_month)) AS month_number,
    COUNT(DISTINCT a.user_id) AS users
  FROM first_seen f
  JOIN activity a ON f.user_id = a.user_id
  GROUP BY 1, 2
)
SELECT
  cohort_month::date AS cohort_month,
  month_number::int  AS month_number,
  users,
  ROUND(100.0 * users / FIRST_VALUE(users) OVER (PARTITION BY cohort_month ORDER BY month_number), 2) AS retention_pct
FROM cohort_data
ORDER BY cohort_month, month_number;
