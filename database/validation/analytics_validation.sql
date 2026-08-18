-- Purpose:
--   Validate the Analytics Layer after ETL.
--
-- Scope:
--   1. Row-count validation
--   2. Primary/composite key validation
--   3. Required key NULL validation
--   4. Cross-table relationship validation
--   5. Business-level reconciliation
--   6. D002 timeline anomaly validation
--   7. D003 payment installment anomaly validation


-- 1. ROW COUNT VALIDATION
-- ============================================================

SELECT
    'analytics.dim_customer' AS table_name,
    COUNT(*) AS actual_rows,
    96096 AS expected_rows,
    COUNT(*) = 96096 AS passed
FROM analytics.dim_customer

UNION ALL

SELECT
    'analytics.dim_product',
    COUNT(*),
    32951,
    COUNT(*) = 32951
FROM analytics.dim_product

UNION ALL

SELECT
    'analytics.dim_seller',
    COUNT(*),
    3095,
    COUNT(*) = 3095
FROM analytics.dim_seller

UNION ALL

SELECT
    'analytics.fact_orders',
    COUNT(*),
    99441,
    COUNT(*) = 99441
FROM analytics.fact_orders

UNION ALL

SELECT
    'analytics.fact_order_items',
    COUNT(*),
    112650,
    COUNT(*) = 112650
FROM analytics.fact_order_items

UNION ALL

SELECT
    'analytics.fact_payments',
    COUNT(*),
    103886,
    COUNT(*) = 103886
FROM analytics.fact_payments

UNION ALL

SELECT
    'analytics.fact_reviews',
    COUNT(*),
    99224,
    COUNT(*) = 99224
FROM analytics.fact_reviews;


-- 2. KEY UNIQUENESS VALIDATION
-- ============================================================

-- dim_customer
SELECT
    'dim_customer.customer_unique_id' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT customer_unique_id
    FROM analytics.dim_customer
    GROUP BY customer_unique_id
    HAVING COUNT(*) > 1
) duplicates;


-- dim_product
SELECT
    'dim_product.product_id' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT product_id
    FROM analytics.dim_product
    GROUP BY product_id
    HAVING COUNT(*) > 1
) duplicates;


-- dim_seller
SELECT
    'dim_seller.seller_id' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT seller_id
    FROM analytics.dim_seller
    GROUP BY seller_id
    HAVING COUNT(*) > 1
) duplicates;


-- fact_orders
SELECT
    'fact_orders.order_id' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT order_id
    FROM analytics.fact_orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) duplicates;


-- fact_order_items
SELECT
    'fact_order_items.(order_id, order_item_id)' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT
        order_id,
        order_item_id
    FROM analytics.fact_order_items
    GROUP BY
        order_id,
        order_item_id
    HAVING COUNT(*) > 1
) duplicates;


-- fact_payments
SELECT
    'fact_payments.(order_id, payment_sequential)' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT
        order_id,
        payment_sequential
    FROM analytics.fact_payments
    GROUP BY
        order_id,
        payment_sequential
    HAVING COUNT(*) > 1
) duplicates;


-- fact_reviews
SELECT
    'fact_reviews.(review_id, order_id)' AS check_name,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT
        review_id,
        order_id
    FROM analytics.fact_reviews
    GROUP BY
        review_id,
        order_id
    HAVING COUNT(*) > 1
) duplicates;


-- 3. REQUIRED KEY NULL VALIDATION
-- ============================================================

SELECT
    'dim_customer.customer_unique_id' AS check_name,
    COUNT(*) AS null_rows
FROM analytics.dim_customer
WHERE customer_unique_id IS NULL;


SELECT
    'dim_product.product_id' AS check_name,
    COUNT(*) AS null_rows
FROM analytics.dim_product
WHERE product_id IS NULL;


SELECT
    'dim_seller.seller_id' AS check_name,
    COUNT(*) AS null_rows
FROM analytics.dim_seller
WHERE seller_id IS NULL;


SELECT
    'fact_orders.order_id' AS check_name,
    COUNT(*) AS null_rows
FROM analytics.fact_orders
WHERE order_id IS NULL;


SELECT
    'fact_orders.customer_unique_id' AS check_name,
    COUNT(*) AS null_rows
FROM analytics.fact_orders
WHERE customer_unique_id IS NULL;


SELECT
    'fact_order_items.order_id' AS check_name,
    COUNT(*) AS null_rows
FROM analytics.fact_order_items
WHERE order_id IS NULL;


SELECT
    'fact_order_items.product_id' AS check_name,
    COUNT(*) AS null_rows
FROM analytics.fact_order_items
WHERE product_id IS NULL;


SELECT
    'fact_order_items.seller_id' AS check_name,
    COUNT(*) AS null_rows
FROM analytics.fact_order_items
WHERE seller_id IS NULL;


SELECT
    'fact_payments.order_id' AS check_name,
    COUNT(*) AS null_rows
FROM analytics.fact_payments
WHERE order_id IS NULL;


SELECT
    'fact_payments.payment_sequential' AS check_name,
    COUNT(*) AS null_rows
FROM analytics.fact_payments
WHERE payment_sequential IS NULL;


SELECT
    'fact_reviews.review_id' AS check_name,
    COUNT(*) AS null_rows
FROM analytics.fact_reviews
WHERE review_id IS NULL;


SELECT
    'fact_reviews.order_id' AS check_name,
    COUNT(*) AS null_rows
FROM analytics.fact_reviews
WHERE order_id IS NULL;


-- 4. CROSS-TABLE RELATIONSHIP VALIDATION
-- ============================================================


-- fact_orders → dim_customer
SELECT
    'fact_orders → dim_customer' AS relationship,
    COUNT(*) AS orphan_rows
FROM analytics.fact_orders o
LEFT JOIN analytics.dim_customer c
    ON o.customer_unique_id = c.customer_unique_id
WHERE c.customer_unique_id IS NULL;


-- fact_order_items → fact_orders
SELECT
    'fact_order_items → fact_orders' AS relationship,
    COUNT(*) AS orphan_rows
FROM analytics.fact_order_items oi
LEFT JOIN analytics.fact_orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- fact_order_items → dim_product
SELECT
    'fact_order_items → dim_product' AS relationship,
    COUNT(*) AS orphan_rows
FROM analytics.fact_order_items oi
LEFT JOIN analytics.dim_product p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- fact_order_items → dim_seller
SELECT
    'fact_order_items → dim_seller' AS relationship,
    COUNT(*) AS orphan_rows
FROM analytics.fact_order_items oi
LEFT JOIN analytics.dim_seller s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- fact_payments → fact_orders
SELECT
    'fact_payments → fact_orders' AS relationship,
    COUNT(*) AS orphan_rows
FROM analytics.fact_payments p
LEFT JOIN analytics.fact_orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;


-- fact_reviews → fact_orders
SELECT
    'fact_reviews → fact_orders' AS relationship,
    COUNT(*) AS orphan_rows
FROM analytics.fact_reviews r
LEFT JOIN analytics.fact_orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 5. BUSINESS-LEVEL RECONCILIATION
-- ============================================================


-- Orders without order items
-- Expected result: 775 based on Raw Layer investigation.
-- These records are preserved because they are primarily
-- associated with non-completed order statuses.

SELECT
    'orders_without_order_items' AS check_name,
    COUNT(*) AS affected_orders,
    775 AS expected_orders,
    COUNT(*) = 775 AS passed
FROM analytics.fact_orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM analytics.fact_order_items oi
    WHERE oi.order_id = o.order_id
);


-- Orders without payments
-- Expected result: 1 based on Raw Layer investigation.
-- The affected order is preserved rather than removed.

SELECT
    'orders_without_payments' AS check_name,
    COUNT(*) AS affected_orders,
    1 AS expected_orders,
    COUNT(*) = 1 AS passed
FROM analytics.fact_orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM analytics.fact_payments p
    WHERE p.order_id = o.order_id
);


-- Orders with multiple payment records
-- This is valid because one order can contain multiple
-- payment records.

SELECT
    'orders_with_multiple_payments' AS check_name,
    COUNT(*) AS affected_orders
FROM (
    SELECT order_id
    FROM analytics.fact_payments
    GROUP BY order_id
    HAVING COUNT(*) > 1
) payment_groups;


-- 6. D002 — ORDER TIMELINE ANOMALY VALIDATION
-- ============================================================

SELECT
    'D002_timeline_anomaly_orders' AS check_name,
    COUNT(*) AS anomaly_orders,
    1382 AS expected_orders,
    COUNT(*) = 1382 AS passed
FROM analytics.fact_orders
WHERE has_timeline_anomaly = TRUE;


-- Flag distribution

SELECT
    has_timeline_anomaly,
    COUNT(*) AS order_count
FROM analytics.fact_orders
GROUP BY has_timeline_anomaly
ORDER BY has_timeline_anomaly;


-- 7. D003 — PAYMENT INSTALLMENT ANOMALY VALIDATION
-- ============================================================

SELECT
    'D003_installments_anomaly' AS check_name,
    COUNT(*) AS anomaly_payments,
    2 AS expected_payments,
    COUNT(*) = 2 AS passed
FROM analytics.fact_payments
WHERE has_installments_anomaly = TRUE;


-- Flag distribution

SELECT
    has_installments_anomaly,
    COUNT(*) AS payment_count
FROM analytics.fact_payments
GROUP BY has_installments_anomaly
ORDER BY has_installments_anomaly;

-- 8. REVIEW IDENTITY VALIDATION
-- ============================================================

-- The 789 duplicated review_id values are expected.
-- They must remain because the Analytics grain is:
-- (review_id, order_id).

SELECT
    'duplicated_review_ids' AS check_name,
    COUNT(*) AS duplicated_review_id_count,
    789 AS expected_count,
    COUNT(*) = 789 AS passed
FROM (
    SELECT review_id
    FROM analytics.fact_reviews
    GROUP BY review_id
    HAVING COUNT(DISTINCT order_id) > 1
) duplicated;
