-- Purpose:
--   Validate the PostgreSQL Raw Layer after source CSV loading.
--
-- Scope:
--   1. Row count validation
--   2. Primary key / duplicate validation
--   3. Required NULL validation
--   4. Logical relationship validation
--   5. Order-item completeness
--   6. Payment completeness
--   7. Payment sequential consistency
--   8. Domain / value validation
--   9. Order timeline validation
--   10. Review timeline validation
--   11. Order status distribution
--   12. Known review ID duplication
--   13. Geolocation duplication
--   14. Category translation validation
--   15. Product category translation coverage
--   16. Geographic value validation
--   17. Customer identity distribution
--   18. Data completeness profiling
--   19. Validation summary
--
-- IMPORTANT:
--   This script is READ-ONLY.
--
--   It does not:
--     - clean data
--     - deduplicate data
--     - modify source values
--     - perform ETL
--
-- Raw Layer Strategy:
--   Raw foreign key relationships are NOT enforced at the
--   database level.
--
--   Referential integrity is therefore explicitly validated
--   through logical relationship checks.


-- ============================================================
-- 0. VALIDATION HEADER
-- ============================================================

SELECT
    'InsightFlow Raw Layer Validation' AS validation,
    CURRENT_TIMESTAMP AS executed_at;


-- ============================================================
-- 1. ROW COUNT VALIDATION
-- ============================================================
--
-- Expected row counts correspond to the CSV files successfully
-- loaded into the Raw Layer.
--
-- These values are validation references only.
-- No transformation is performed.
-- ============================================================

SELECT
    'raw.customers' AS table_name,
    COUNT(*) AS actual_rows,
    99441 AS expected_rows,
    COUNT(*) = 99441 AS passed
FROM raw.customers

UNION ALL

SELECT
    'raw.orders',
    COUNT(*),
    99441,
    COUNT(*) = 99441
FROM raw.orders

UNION ALL

SELECT
    'raw.order_items',
    COUNT(*),
    112650,
    COUNT(*) = 112650
FROM raw.order_items

UNION ALL

SELECT
    'raw.payments',
    COUNT(*),
    103886,
    COUNT(*) = 103886
FROM raw.payments

UNION ALL

SELECT
    'raw.products',
    COUNT(*),
    32951,
    COUNT(*) = 32951
FROM raw.products

UNION ALL

SELECT
    'raw.sellers',
    COUNT(*),
    3095,
    COUNT(*) = 3095
FROM raw.sellers

UNION ALL

SELECT
    'raw.reviews',
    COUNT(*),
    99224,
    COUNT(*) = 99224
FROM raw.reviews

UNION ALL

SELECT
    'raw.geolocation',
    COUNT(*),
    1000163,
    COUNT(*) = 1000163
FROM raw.geolocation

UNION ALL

SELECT
    'raw.category_translation',
    COUNT(*),
    71,
    COUNT(*) = 71
FROM raw.category_translation;


-- ============================================================
-- 2. PRIMARY KEY / DUPLICATE VALIDATION
-- ============================================================
--
-- PostgreSQL primary keys already prevent duplicate records.
-- These checks provide explicit validation evidence.
-- ============================================================


-- ------------------------------------------------------------
-- 2.1 CUSTOMERS
-- ------------------------------------------------------------

SELECT
    'customers.customer_id' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT customer_id
    FROM raw.customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) duplicates;


-- ------------------------------------------------------------
-- 2.2 ORDERS
-- ------------------------------------------------------------

SELECT
    'orders.order_id' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT order_id
    FROM raw.orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) duplicates;


-- ------------------------------------------------------------
-- 2.3 ORDER ITEMS
-- ------------------------------------------------------------

SELECT
    'order_items.(order_id, order_item_id)' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT
        order_id,
        order_item_id
    FROM raw.order_items
    GROUP BY
        order_id,
        order_item_id
    HAVING COUNT(*) > 1
) duplicates;


-- ------------------------------------------------------------
-- 2.4 PAYMENTS
-- ------------------------------------------------------------

SELECT
    'payments.(order_id, payment_sequential)' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT
        order_id,
        payment_sequential
    FROM raw.payments
    GROUP BY
        order_id,
        payment_sequential
    HAVING COUNT(*) > 1
) duplicates;


-- ------------------------------------------------------------
-- 2.5 PRODUCTS
-- ------------------------------------------------------------

SELECT
    'products.product_id' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT product_id
    FROM raw.products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) duplicates;


-- ------------------------------------------------------------
-- 2.6 SELLERS
-- ------------------------------------------------------------

SELECT
    'sellers.seller_id' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT seller_id
    FROM raw.sellers
    GROUP BY seller_id
    HAVING COUNT(*) > 1
) duplicates;


-- ------------------------------------------------------------
-- 2.7 REVIEWS
-- ------------------------------------------------------------

SELECT
    'reviews.(review_id, order_id)' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT
        review_id,
        order_id
    FROM raw.reviews
    GROUP BY
        review_id,
        order_id
    HAVING COUNT(*) > 1
) duplicates;


-- ------------------------------------------------------------
-- 2.8 CATEGORY TRANSLATION
-- ------------------------------------------------------------

SELECT
    'category_translation.product_category_name' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT product_category_name
    FROM raw.category_translation
    GROUP BY product_category_name
    HAVING COUNT(*) > 1
) duplicates;

SELECT DISTINCT
    p.product_category_name
FROM raw.products p
LEFT JOIN raw.category_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL;


-- ============================================================
-- 3. REQUIRED NULL VALIDATION
-- ============================================================
--
-- These fields are defined as NOT NULL in schema.sql.
--
-- PostgreSQL already prevents NULL values for these fields.
-- The checks below provide explicit validation evidence.
-- ============================================================


-- ------------------------------------------------------------
-- 3.1 CUSTOMERS
-- ------------------------------------------------------------

SELECT
    'customers.customer_id' AS column_name,
    COUNT(*) AS null_rows
FROM raw.customers
WHERE customer_id IS NULL

UNION ALL

SELECT
    'customers.customer_unique_id',
    COUNT(*)
FROM raw.customers
WHERE customer_unique_id IS NULL;


-- ------------------------------------------------------------
-- 3.2 ORDERS
-- ------------------------------------------------------------

SELECT
    'orders.order_id' AS column_name,
    COUNT(*) AS null_rows
FROM raw.orders
WHERE order_id IS NULL

UNION ALL

SELECT
    'orders.customer_id',
    COUNT(*)
FROM raw.orders
WHERE customer_id IS NULL;


-- ------------------------------------------------------------
-- 3.3 ORDER ITEMS
-- ------------------------------------------------------------

SELECT
    'order_items.order_id' AS column_name,
    COUNT(*) AS null_rows
FROM raw.order_items
WHERE order_id IS NULL

UNION ALL

SELECT
    'order_items.order_item_id',
    COUNT(*)
FROM raw.order_items
WHERE order_item_id IS NULL

UNION ALL

SELECT
    'order_items.product_id',
    COUNT(*)
FROM raw.order_items
WHERE product_id IS NULL

UNION ALL

SELECT
    'order_items.seller_id',
    COUNT(*)
FROM raw.order_items
WHERE seller_id IS NULL;


-- ------------------------------------------------------------
-- 3.4 PAYMENTS
-- ------------------------------------------------------------

SELECT
    'payments.order_id' AS column_name,
    COUNT(*) AS null_rows
FROM raw.payments
WHERE order_id IS NULL

UNION ALL

SELECT
    'payments.payment_sequential',
    COUNT(*)
FROM raw.payments
WHERE payment_sequential IS NULL;


-- ------------------------------------------------------------
-- 3.5 PRODUCTS
-- ------------------------------------------------------------

SELECT
    'products.product_id' AS column_name,
    COUNT(*) AS null_rows
FROM raw.products
WHERE product_id IS NULL;


-- ------------------------------------------------------------
-- 3.6 SELLERS
-- ------------------------------------------------------------

SELECT
    'sellers.seller_id' AS column_name,
    COUNT(*) AS null_rows
FROM raw.sellers
WHERE seller_id IS NULL;


-- ------------------------------------------------------------
-- 3.7 REVIEWS
-- ------------------------------------------------------------

SELECT
    'reviews.review_id' AS column_name,
    COUNT(*) AS null_rows
FROM raw.reviews
WHERE review_id IS NULL

UNION ALL

SELECT
    'reviews.order_id',
    COUNT(*)
FROM raw.reviews
WHERE order_id IS NULL;


-- ============================================================
-- 4. LOGICAL RELATIONSHIP VALIDATION
-- ============================================================
--
-- Raw Layer intentionally does NOT enforce foreign keys.
--
-- These queries validate logical relationships explicitly.
--
-- Expected result:
--   orphan_rows = 0
-- ============================================================


-- ------------------------------------------------------------
-- 4.1 ORDERS → CUSTOMERS
-- ------------------------------------------------------------

SELECT
    'orders → customers' AS relationship,
    COUNT(*) AS orphan_rows
FROM raw.orders o
LEFT JOIN raw.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- ------------------------------------------------------------
-- 4.2 ORDER ITEMS → ORDERS
-- ------------------------------------------------------------

SELECT
    'order_items → orders' AS relationship,
    COUNT(*) AS orphan_rows
FROM raw.order_items oi
LEFT JOIN raw.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ------------------------------------------------------------
-- 4.3 ORDER ITEMS → PRODUCTS
-- ------------------------------------------------------------

SELECT
    'order_items → products' AS relationship,
    COUNT(*) AS orphan_rows
FROM raw.order_items oi
LEFT JOIN raw.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- ------------------------------------------------------------
-- 4.4 ORDER ITEMS → SELLERS
-- ------------------------------------------------------------

SELECT
    'order_items → sellers' AS relationship,
    COUNT(*) AS orphan_rows
FROM raw.order_items oi
LEFT JOIN raw.sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- ------------------------------------------------------------
-- 4.5 PAYMENTS → ORDERS
-- ------------------------------------------------------------

SELECT
    'payments → orders' AS relationship,
    COUNT(*) AS orphan_rows
FROM raw.payments p
LEFT JOIN raw.orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ------------------------------------------------------------
-- 4.6 REVIEWS → ORDERS
-- ------------------------------------------------------------

SELECT
    'reviews → orders' AS relationship,
    COUNT(*) AS orphan_rows
FROM raw.reviews r
LEFT JOIN raw.orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- 5. ORDER ITEMS COMPLETENESS
-- ============================================================
--
-- Business expectation:
--   Each order should have at least one order item.
--
-- This is not enforced as a database constraint because the
-- Raw Layer intentionally remains source-faithful.
--
-- Expected result:
--   orphan_orders = 0
-- ============================================================

SELECT
    'orders_without_order_items' AS check_name,
    COUNT(*) AS orphan_orders
FROM raw.orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.order_items oi
    WHERE oi.order_id = o.order_id
);

SELECT
    'orders_without_order_items_by_status' AS check_name,
    o.order_status,
    COUNT(*) AS order_count
FROM raw.orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.order_items oi
    WHERE oi.order_id = o.order_id
)
GROUP BY o.order_status
ORDER BY order_count DESC;

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date
FROM raw.orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.order_items oi
    WHERE oi.order_id = o.order_id
)
AND o.order_status IN ('created', 'invoiced', 'shipped')
ORDER BY o.order_status, o.order_purchase_timestamp;


SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date
FROM raw.orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.order_items oi
    WHERE oi.order_id = o.order_id
)
AND o.order_status IN ('invoiced', 'shipped')
ORDER BY o.order_status, o.order_purchase_timestamp;

SELECT
    o.order_id,
    o.order_status,
    COUNT(DISTINCT oi.order_item_id) AS order_item_count,
    COUNT(DISTINCT p.payment_sequential) AS payment_count,
    COUNT(DISTINCT r.review_id) AS review_count
FROM raw.orders o
LEFT JOIN raw.order_items oi
    ON o.order_id = oi.order_id
LEFT JOIN raw.payments p
    ON o.order_id = p.order_id
LEFT JOIN raw.reviews r
    ON o.order_id = r.order_id
WHERE o.order_id IN (
    'e04f1da1f48bf2bbffcf57b9824f76e1',
    '2ce9683175cdab7d1c95bcbb3e36f478',
    'a68ce1686d536ca72bd2dadc4b8671e5'
)
GROUP BY
    o.order_id,
    o.order_status;

-- ============================================================
-- 6. PAYMENT COMPLETENESS
-- ============================================================
--
-- Business expectation:
--   Each order should have at least one payment record.
--
-- This is validated here rather than enforced through a Raw
-- Layer foreign key.
--
-- Expected result:
--   orders_without_payment = 0
-- ============================================================

SELECT
    'orders_without_payments' AS check_name,
    COUNT(*) AS orders_without_payment
FROM raw.orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.payments p
    WHERE p.order_id = o.order_id
);

SELECT
    'orders_without_payments_detail' AS check_name,
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp
FROM raw.orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.payments p
    WHERE p.order_id = o.order_id
);

SELECT
    o.*,
    COUNT(oi.order_id) AS order_item_count
FROM raw.orders o
LEFT JOIN raw.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_id = 'bfbd0f9bdef84302105ad712db648a6c'
GROUP BY
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date;

-- ============================================================
-- 7. PAYMENT SEQUENTIAL CONSISTENCY
-- ============================================================
--
-- payment_sequential represents the sequence of payment
-- records belonging to an order.
--
-- This check detects gaps such as:
--
--   1, 2, 3      → valid
--   1, 3         → gap
--   1, 2, 4      → gap
--
-- Duplicate sequence values are already prevented by:
--
--   PRIMARY KEY (order_id, payment_sequential)
--
-- Expected result:
--   orders_with_gaps = 0
-- ============================================================

SELECT
    'payment_sequential_gaps' AS check_name,
    COUNT(*) AS orders_with_gaps
FROM (
    SELECT
        order_id
    FROM (
        SELECT
            order_id,
            payment_sequential,
            LAG(payment_sequential) OVER (
                PARTITION BY order_id
                ORDER BY payment_sequential
            ) AS prev_seq
        FROM raw.payments
    ) sequence_check
    WHERE prev_seq IS NOT NULL
      AND payment_sequential - prev_seq > 1
    GROUP BY order_id
) gap_orders;


-- ============================================================
-- 8. DOMAIN / VALUE VALIDATION
-- ============================================================


-- ------------------------------------------------------------
-- 8.1 REVIEW SCORE
--
-- Valid Olist review scores are 1 through 5.
-- ------------------------------------------------------------

SELECT
    'review_score_out_of_range' AS check_name,
    COUNT(*) AS invalid_rows
FROM raw.reviews
WHERE review_score IS NOT NULL
  AND review_score NOT BETWEEN 1 AND 5;


-- ------------------------------------------------------------
-- 8.2 PAYMENT VALUE
--
-- Payment value should not be negative.
-- ------------------------------------------------------------

SELECT
    'negative_payment_value' AS check_name,
    COUNT(*) AS invalid_rows
FROM raw.payments
WHERE payment_value < 0;


-- ------------------------------------------------------------
-- 8.3 PAYMENT INSTALLMENTS
--
-- Installment count should normally be positive when present.
--
-- Known source characteristic:
--   D003 identified 2 records with payment_installments = 0.
--
-- These records are intentionally retained in the Raw Layer
-- and are expected to appear as REVIEW during validation.
--
-- They will be handled according to the approved D003 strategy
-- during ETL.
-- ------------------------------------------------------------
SELECT
    'invalid_payment_installments' AS check_name,
    COUNT(*) AS invalid_rows
FROM raw.payments
WHERE payment_installments IS NOT NULL
  AND payment_installments <= 0;


-- ------------------------------------------------------------
-- 8.4 ORDER ITEM PRICE
--
-- Product price should not be negative.
-- ------------------------------------------------------------

SELECT
    'negative_order_item_price' AS check_name,
    COUNT(*) AS invalid_rows
FROM raw.order_items
WHERE price < 0;


-- ------------------------------------------------------------
-- 8.5 FREIGHT VALUE
--
-- Freight value should not be negative.
-- ------------------------------------------------------------

SELECT
    'negative_freight_value' AS check_name,
    COUNT(*) AS invalid_rows
FROM raw.order_items
WHERE freight_value < 0;


-- ============================================================
-- 9. ORDER TIMELINE VALIDATION
-- ============================================================
--
-- These checks identify inconsistent timestamp sequences.
--
-- IMPORTANT:
--   The Raw Layer does NOT correct these records.
--
--   Known anomalies are retained and handled later during ETL
--   according to the approved D002 strategy.
-- ============================================================


-- ------------------------------------------------------------
-- 9.1 APPROVAL BEFORE PURCHASE
-- ------------------------------------------------------------

SELECT
    'approval_before_purchase' AS check_name,
    COUNT(*) AS anomaly_rows
FROM raw.orders
WHERE order_approved_at IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_approved_at < order_purchase_timestamp;


-- ------------------------------------------------------------
-- 9.2 CARRIER BEFORE PURCHASE
-- ------------------------------------------------------------

SELECT
    'carrier_before_purchase' AS check_name,
    COUNT(*) AS anomaly_rows
FROM raw.orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_carrier_date < order_purchase_timestamp;


-- ------------------------------------------------------------
-- 9.3 CUSTOMER DELIVERY BEFORE PURCHASE
-- ------------------------------------------------------------

SELECT
    'customer_delivery_before_purchase' AS check_name,
    COUNT(*) AS anomaly_rows
FROM raw.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date < order_purchase_timestamp;


-- ------------------------------------------------------------
-- 9.4 CUSTOMER DELIVERY BEFORE CARRIER
-- ------------------------------------------------------------

SELECT
    'customer_delivery_before_carrier' AS check_name,
    COUNT(*) AS anomaly_rows
FROM raw.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date < order_delivered_carrier_date;


-- ------------------------------------------------------------
-- 9.5 ESTIMATED DELIVERY BEFORE PURCHASE
-- ------------------------------------------------------------

SELECT
    'estimated_delivery_before_purchase' AS check_name,
    COUNT(*) AS anomaly_rows
FROM raw.orders
WHERE order_estimated_delivery_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_estimated_delivery_date < order_purchase_timestamp;


-- ============================================================
-- 10. REVIEW TIMELINE VALIDATION
-- ============================================================
--
-- Review answer should occur after review creation.
--
-- Valid:
--
--   review_creation_date
--          ↓
--   review_answer_timestamp
--
-- NULL answer timestamps are allowed.
-- ============================================================

SELECT
    'review_answer_before_creation' AS check_name,
    COUNT(*) AS anomaly_rows
FROM raw.reviews
WHERE review_answer_timestamp IS NOT NULL
  AND review_creation_date IS NOT NULL
  AND review_answer_timestamp < review_creation_date;


-- ============================================================
-- 11. ORDER STATUS DISTRIBUTION
-- ============================================================
--
-- Descriptive validation.
--
-- No order status is automatically classified as invalid here.
-- The purpose is to understand the source distribution before
-- ETL.
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM raw.orders
GROUP BY order_status
ORDER BY order_count DESC;


-- ============================================================
-- 12. REVIEW ID DUPLICATION CHARACTERISTIC
-- ============================================================
--
-- Project documentation identifies duplicated review_id values
-- across multiple orders.
--
-- This is treated as a known source characteristic rather than
-- an automatic key failure.
--
-- The approved Raw Layer key remains:
--
--   (review_id, order_id)
-- ============================================================


-- ------------------------------------------------------------
-- 12.1 Count duplicated review_id values
-- ------------------------------------------------------------

SELECT
    'duplicated_review_ids' AS check_name,
    COUNT(*) AS duplicated_review_id_count
FROM (
    SELECT review_id
    FROM raw.reviews
    GROUP BY review_id
    HAVING COUNT(DISTINCT order_id) > 1
) duplicated;


-- ------------------------------------------------------------
-- 12.2 Review rows affected by duplicated review_id
-- ------------------------------------------------------------

SELECT
    'review_rows_with_duplicated_review_id' AS check_name,
    COUNT(*) AS affected_rows
FROM raw.reviews
WHERE review_id IN (
    SELECT review_id
    FROM raw.reviews
    GROUP BY review_id
    HAVING COUNT(DISTINCT order_id) > 1
);


-- ------------------------------------------------------------
-- 12.3 Check whether duplicated review_id records contain
-- identical review information.
-- ------------------------------------------------------------

SELECT
    review_id,
    COUNT(DISTINCT review_score) AS score_variations,
    COUNT(DISTINCT review_comment_title) AS title_variations,
    COUNT(DISTINCT review_comment_message) AS message_variations,
    COUNT(DISTINCT review_creation_date) AS creation_date_variations,
    COUNT(DISTINCT review_answer_timestamp) AS answer_timestamp_variations
FROM raw.reviews
WHERE review_id IN (
    SELECT review_id
    FROM raw.reviews
    GROUP BY review_id
    HAVING COUNT(DISTINCT order_id) > 1
)
GROUP BY review_id
HAVING
    COUNT(DISTINCT review_score) > 1
    OR COUNT(DISTINCT review_comment_title) > 1
    OR COUNT(DISTINCT review_comment_message) > 1
    OR COUNT(DISTINCT review_creation_date) > 1
    OR COUNT(DISTINCT review_answer_timestamp) > 1
ORDER BY review_id;


-- ============================================================
-- 13. GEOLOCATION DUPLICATION
-- ============================================================
--
-- The geolocation dataset is known to contain substantial
-- full-row duplication.
--
-- Raw Layer intentionally preserves this source behavior.
-- No deduplication is performed here.
-- ============================================================


-- ------------------------------------------------------------
-- 13.1 Total geolocation rows
-- ------------------------------------------------------------

SELECT
    'geolocation_total_rows' AS metric,
    COUNT(*) AS value
FROM raw.geolocation;


-- ------------------------------------------------------------
-- 13.2 Distinct full geolocation rows
-- ------------------------------------------------------------

SELECT
    'geolocation_distinct_rows' AS metric,
    COUNT(*) AS value
FROM (
    SELECT DISTINCT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    FROM raw.geolocation
) distinct_rows;


-- ------------------------------------------------------------
-- 13.3 Duplicate full-row count
-- ------------------------------------------------------------

SELECT
    'geolocation_duplicate_rows' AS metric,
    COUNT(*) -
    COUNT(DISTINCT (
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    )) AS value
FROM raw.geolocation;


-- ============================================================
-- 14. CATEGORY TRANSLATION VALIDATION
-- ============================================================


-- ------------------------------------------------------------
-- 14.1 Missing English translations
-- ------------------------------------------------------------

SELECT
    'missing_category_translation' AS check_name,
    COUNT(*) AS invalid_rows
FROM raw.category_translation
WHERE product_category_name_english IS NULL
   OR TRIM(product_category_name_english) = '';


-- ------------------------------------------------------------
-- 14.2 Empty source category
-- ------------------------------------------------------------

SELECT
    'empty_source_category' AS check_name,
    COUNT(*) AS invalid_rows
FROM raw.category_translation
WHERE product_category_name IS NULL
   OR TRIM(product_category_name) = '';


-- ============================================================
-- 15. PRODUCT CATEGORY TRANSLATION COVERAGE
-- ============================================================
--
-- Checks whether product categories appearing in raw.products
-- have corresponding entries in raw.category_translation.
--
-- This is a logical relationship, not a database FK.
-- ============================================================

SELECT
    'product_categories_without_translation' AS check_name,
    COUNT(*) AS unmatched_categories
FROM (
    SELECT DISTINCT
        p.product_category_name
    FROM raw.products p
    LEFT JOIN raw.category_translation t
        ON p.product_category_name = t.product_category_name
    WHERE p.product_category_name IS NOT NULL
      AND t.product_category_name IS NULL
) unmatched;


-- ============================================================
-- 16. GEOGRAPHIC VALUE VALIDATION
-- ============================================================
--
-- This checks whether latitude and longitude values fall within
-- valid geographic ranges.
--
-- This is NOT the optional geographic master-data coverage
-- check. That check is intentionally deferred because
-- geolocation remains Raw-only for the MVP.
-- ============================================================


-- ------------------------------------------------------------
-- 16.1 Invalid latitude
-- ------------------------------------------------------------

SELECT
    'invalid_geolocation_latitude' AS check_name,
    COUNT(*) AS invalid_rows
FROM raw.geolocation
WHERE geolocation_lat IS NOT NULL
  AND geolocation_lat NOT BETWEEN -90 AND 90;


-- ------------------------------------------------------------
-- 16.2 Invalid longitude
-- ------------------------------------------------------------

SELECT
    'invalid_geolocation_longitude' AS check_name,
    COUNT(*) AS invalid_rows
FROM raw.geolocation
WHERE geolocation_lng IS NOT NULL
  AND geolocation_lng NOT BETWEEN -180 AND 180;


-- ============================================================
-- 17. CUSTOMER IDENTITY DISTRIBUTION
-- ============================================================
--
-- D001:
--
--   customer_id
--       = source customer record
--
--   customer_unique_id
--       = business customer identity
--
-- This section measures the relationship between the two.
-- ============================================================


-- ------------------------------------------------------------
-- 17.1 Source customer records mapped to multiple business
--      customer records.
-- ------------------------------------------------------------

SELECT
    customer_unique_id,
    COUNT(*) AS source_customer_records
FROM raw.customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1
ORDER BY source_customer_records DESC, customer_unique_id
LIMIT 20;


-- ------------------------------------------------------------
-- 17.2 Customer identity summary
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS source_customer_records,
    COUNT(DISTINCT customer_unique_id) AS unique_business_customers,
    COUNT(*) - COUNT(DISTINCT customer_unique_id) AS additional_source_records
FROM raw.customers;


-- ============================================================
-- 18. DATA COMPLETENESS PROFILE
-- ============================================================
--
-- Descriptive profiling of important analytical fields.
--
-- NULL values are not automatically considered invalid because
-- the source dataset legitimately contains missing values.
-- ============================================================


-- ------------------------------------------------------------
-- 18.1 Orders completeness
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_orders,
    COUNT(order_purchase_timestamp) AS purchase_timestamp_present,
    COUNT(order_approved_at) AS approved_timestamp_present,
    COUNT(order_delivered_carrier_date) AS carrier_timestamp_present,
    COUNT(order_delivered_customer_date) AS customer_delivery_timestamp_present,
    COUNT(order_estimated_delivery_date) AS estimated_delivery_timestamp_present
FROM raw.orders;


-- ------------------------------------------------------------
-- 18.2 Reviews completeness
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_reviews,
    COUNT(review_score) AS review_score_present,
    COUNT(review_comment_title) AS comment_title_present,
    COUNT(review_comment_message) AS comment_message_present
FROM raw.reviews;


-- ------------------------------------------------------------
-- 18.3 Products completeness
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_products,
    COUNT(product_category_name) AS category_present,
    COUNT(product_weight_g) AS weight_present,
    COUNT(product_length_cm) AS length_present,
    COUNT(product_height_cm) AS height_present,
    COUNT(product_width_cm) AS width_present
FROM raw.products;


-- ============================================================
-- 19. VALIDATION SUMMARY
-- ============================================================
--
-- PASS:
--   Zero problematic records found.
--
-- REVIEW:
--   Records exist and require interpretation.
--
-- IMPORTANT:
--   A REVIEW result does not automatically mean that the source
--   data is invalid. Some results represent known source
--   characteristics documented in the project architecture.
-- ============================================================

-- 19.1 Referential integrity summary
-- ------------------------------------------------------------

SELECT
    'orders → customers' AS check_name,
    COUNT(*) AS issue_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END AS status
FROM raw.orders o
LEFT JOIN raw.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT
    'order_items → orders',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM raw.order_items oi
LEFT JOIN raw.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'order_items → products',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM raw.order_items oi
LEFT JOIN raw.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT
    'order_items → sellers',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM raw.order_items oi
LEFT JOIN raw.sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL

UNION ALL

SELECT
    'payments → orders',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM raw.payments p
LEFT JOIN raw.orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'reviews → orders',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM raw.reviews r
LEFT JOIN raw.orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 19.2 Completeness summary
-- ------------------------------------------------------------

SELECT
    'orders_without_order_items' AS check_name,
    COUNT(*) AS issue_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END AS status
FROM raw.orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.order_items oi
    WHERE oi.order_id = o.order_id
)

UNION ALL

SELECT
    'orders_without_payments',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM raw.orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.payments p
    WHERE p.order_id = o.order_id
);


-- 19.3 Domain validation summary
-- ------------------------------------------------------------

SELECT
    'review_score_domain' AS check_name,
    COUNT(*) AS issue_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END AS status
FROM raw.reviews
WHERE review_score IS NOT NULL
  AND review_score NOT BETWEEN 1 AND 5

UNION ALL

SELECT
    'negative_payment_values',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM raw.payments
WHERE payment_value < 0

UNION ALL

SELECT
    'negative_product_prices',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM raw.order_items
WHERE price < 0

UNION ALL

SELECT
    'invalid_payment_installments',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM raw.payments
WHERE payment_installments IS NOT NULL
  AND payment_installments <= 0;


-- 19.4 Timeline validation summary
-- ------------------------------------------------------------

SELECT
    'approval_before_purchase' AS check_name,
    COUNT(*) AS issue_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END AS status
FROM raw.orders
WHERE order_approved_at IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_approved_at < order_purchase_timestamp

UNION ALL

SELECT
    'carrier_before_purchase',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM raw.orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_carrier_date < order_purchase_timestamp

UNION ALL

SELECT
    'customer_delivery_before_purchase',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM raw.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date < order_purchase_timestamp

UNION ALL

SELECT
    'customer_delivery_before_carrier',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM raw.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date < order_delivered_carrier_date

UNION ALL

SELECT
    'estimated_delivery_before_purchase',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM raw.orders
WHERE order_estimated_delivery_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_estimated_delivery_date < order_purchase_timestamp

UNION ALL

SELECT
    'review_answer_before_creation',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END
FROM raw.reviews
WHERE review_answer_timestamp IS NOT NULL
  AND review_creation_date IS NOT NULL
  AND review_answer_timestamp < review_creation_date;


-- 19.5 Payment sequence validation summary
-- ------------------------------------------------------------

SELECT
    'payment_sequential_gaps' AS check_name,
    COUNT(*) AS issue_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END AS status
FROM (
    SELECT
        order_id
    FROM (
        SELECT
            order_id,
            payment_sequential,
            LAG(payment_sequential) OVER (
                PARTITION BY order_id
                ORDER BY payment_sequential
            ) AS prev_seq
        FROM raw.payments
    ) sequence_check
    WHERE prev_seq IS NOT NULL
      AND payment_sequential - prev_seq > 1
    GROUP BY order_id
) gap_orders;

