-- =====================================================
-- 04_revenue_analysis.sql
-- Revenue = sum of price on purchase events (no order ID in the data).
-- Currency is not stated in the dataset.
-- =====================================================

-- 1. Monthly revenue, purchase events, buyers and average item price
SELECT
  TO_CHAR(DATE_TRUNC('month', event_time AT TIME ZONE 'UTC'), 'YYYY-MM') AS month,
  ROUND(SUM(price), 2)       AS revenue,
  COUNT(*)                   AS purchase_events,
  COUNT(DISTINCT user_id)    AS buyers,
  ROUND(AVG(price), 2)       AS avg_item_price
FROM events_clean
WHERE event_type = 'purchase'
GROUP BY 1
ORDER BY 1;

-- 2. Revenue and share by main category
SELECT
  main_category,
  ROUND(SUM(price), 2) AS revenue,
  COUNT(*)             AS purchases,
  ROUND(100.0 * SUM(price) / SUM(SUM(price)) OVER (), 2) AS share_pct
FROM events_clean
WHERE event_type = 'purchase'
GROUP BY main_category
ORDER BY revenue DESC;
