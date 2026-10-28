-- =====================================================
-- 01_profiling_and_funnel.sql
-- Dataset: e-commerce events (885,129 rows)
-- =====================================================

-- 1. Date range, users, sessions, products
SELECT 
  MIN(event_time) AS first_event,
  MAX(event_time) AS last_event,
  COUNT(DISTINCT user_id) AS users,
  COUNT(DISTINCT user_session) AS sessions,
  COUNT(DISTINCT product_id) AS products
FROM events;

-- 2. Missing values
SELECT
  COUNT(*) FILTER (WHERE category_code IS NULL) AS null_category,
  COUNT(*) FILTER (WHERE brand IS NULL) AS null_brand,
  COUNT(*) FILTER (WHERE user_session IS NULL) AS null_session
FROM events;

-- 3. Price range
SELECT 
  MIN(price) AS min_price, 
  MAX(price) AS max_price, 
  ROUND(AVG(price), 2) AS avg_price
FROM events;

-- 4. User-level conversion funnel: view -> cart -> purchase
WITH user_steps AS (
  SELECT
    user_id,
    MAX((event_type = 'view')::int)     AS viewed,
    MAX((event_type = 'cart')::int)     AS carted,
    MAX((event_type = 'purchase')::int) AS purchased
  FROM events
  GROUP BY user_id
),
funnel AS (
  SELECT
    COUNT(*) FILTER (WHERE viewed = 1)                                  AS viewers,
    COUNT(*) FILTER (WHERE viewed = 1 AND carted = 1)                   AS added_to_cart,
    COUNT(*) FILTER (WHERE viewed = 1 AND carted = 1 AND purchased = 1) AS purchased
  FROM user_steps
)
SELECT
  viewers,
  added_to_cart,
  purchased,
  ROUND(100.0 * added_to_cart / NULLIF(viewers, 0), 2)   AS view_to_cart_pct,
  ROUND(100.0 * purchased / NULLIF(added_to_cart, 0), 2) AS cart_to_purchase_pct,
  ROUND(100.0 * purchased / NULLIF(viewers, 0), 2)       AS overall_conversion_pct
FROM funnel;
