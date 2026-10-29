-- =====================================================
-- 05_dashboard_views.sql
-- Views used as data sources for the Power BI dashboard.
-- All months are calculated in UTC.
-- =====================================================

-- 1. User-level conversion funnel
CREATE VIEW v_funnel AS
WITH user_steps AS (
  SELECT
    user_id,
    MAX((event_type = 'view')::int)     AS viewed,
    MAX((event_type = 'cart')::int)     AS carted,
    MAX((event_type = 'purchase')::int) AS purchased
  FROM events_clean
  GROUP BY user_id
)
SELECT 1 AS step_order, 'Viewed a product' AS stage,
       COUNT(*) FILTER (WHERE viewed = 1) AS users
FROM user_steps
UNION ALL
SELECT 2, 'Added to cart',
       COUNT(*) FILTER (WHERE viewed = 1 AND carted = 1)
FROM user_steps
UNION ALL
SELECT 3, 'Purchased',
       COUNT(*) FILTER (WHERE viewed = 1 AND carted = 1 AND purchased = 1)
FROM user_steps;

-- 2. Monthly retention cohorts
CREATE VIEW v_retention AS
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
  TO_CHAR(cohort_month, 'YYYY-MM') AS cohort_month,
  month_number::int AS month_number,
  users,
  ROUND(100.0 * users / FIRST_VALUE(users) OVER (PARTITION BY cohort_month ORDER BY month_number), 2) AS retention_pct
FROM cohort_data;

-- 3. Monthly revenue
CREATE VIEW v_monthly_revenue AS
SELECT
  TO_CHAR(DATE_TRUNC('month', event_time AT TIME ZONE 'UTC'), 'YYYY-MM') AS month,
  ROUND(SUM(price), 2)    AS revenue,
  COUNT(*)                AS purchase_events,
  COUNT(DISTINCT user_id) AS buyers,
  ROUND(AVG(price), 2)    AS avg_item_price
FROM events_clean
WHERE event_type = 'purchase'
GROUP BY 1;

-- 4. Revenue by main category
CREATE VIEW v_category_revenue AS
SELECT
  main_category,
  ROUND(SUM(price), 2) AS revenue,
  COUNT(*)             AS purchases
FROM events_clean
WHERE event_type = 'purchase'
GROUP BY main_category;
