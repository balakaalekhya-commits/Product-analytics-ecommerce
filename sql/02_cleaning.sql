-- =====================================================
-- 02_cleaning.sql
-- Creates events_clean from the raw events table.
-- The raw table is left untouched.
-- =====================================================

-- 1. Build the cleaned table
--    - removes exact duplicate rows (655 found)
--    - labels missing categories and brands as 'unknown'
--    - adds main_category (first part of category_code)
CREATE TABLE events_clean AS
SELECT DISTINCT
  event_time,
  event_type,
  product_id,
  category_id,
  COALESCE(category_code, 'unknown')                     AS category_code,
  COALESCE(split_part(category_code, '.', 1), 'unknown') AS main_category,
  COALESCE(brand, 'unknown')                             AS brand,
  price,
  user_id,
  user_session
FROM events;

-- 2. Compare row counts (885,129 raw vs 884,474 clean)
SELECT 
  (SELECT COUNT(*) FROM events)       AS raw_rows,
  (SELECT COUNT(*) FROM events_clean) AS clean_rows;

-- 3. Check the highest prices for outliers
SELECT product_id, category_code, brand, price, COUNT(*) AS events
FROM events_clean
GROUP BY product_id, category_code, brand, price
ORDER BY price DESC
LIMIT 10;

-- 4. Indexes to speed up later queries
CREATE INDEX idx_clean_user ON events_clean(user_id);
CREATE INDEX idx_clean_type ON events_clean(event_type);
CREATE INDEX idx_clean_time ON events_clean(event_time);
