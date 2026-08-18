-- Purpose:
--   Create additional indexes to optimize:
--   - ETL joins
--   - Foreign key lookups
--   - Analytical queries
--   - Time-based filtering

-- 1. RAW LAYER INDEXES
-- ============================================================


-- ------------------------------------------------------------
-- 1.1 RAW CUSTOMERS
--
-- customer_unique_id is frequently used during ETL for:
--   raw.customers
--        ↓
--   analytics.dim_customer
--
-- It is NOT a primary key in the Raw Layer, therefore an
-- explicit index is required.
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_raw_customers_unique_id
ON raw.customers(customer_unique_id);


-- ------------------------------------------------------------
-- 1.2 RAW ORDERS
--
-- customer_id is frequently used to connect source orders
-- with source customer records during ETL and validation.
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_raw_orders_customer_id
ON raw.orders(customer_id);


-- ------------------------------------------------------------
-- 1.3 RAW ORDERS — PURCHASE TIMESTAMP
--
-- Supports time-based filtering and source-level validation
-- of order timelines.
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_raw_orders_purchase_timestamp
ON raw.orders(order_purchase_timestamp);


-- ------------------------------------------------------------
-- 1.4 RAW ORDER ITEMS — PRODUCT
--
-- Supports ETL joins and product-level analysis.
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_raw_order_items_product_id
ON raw.order_items(product_id);


-- ------------------------------------------------------------
-- 1.5 RAW ORDER ITEMS — SELLER
--
-- Supports ETL joins and seller-level analysis.
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_raw_order_items_seller_id
ON raw.order_items(seller_id);


-- ------------------------------------------------------------
-- 1.6 RAW PAYMENTS — ORDER
--
-- Supports order-to-payment lookup during ETL and validation.
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_raw_payments_order_id
ON raw.payments(order_id);


-- ------------------------------------------------------------
-- 1.7 RAW REVIEWS — ORDER
--
-- Supports order-to-review lookup during ETL and validation.
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_raw_reviews_order_id
ON raw.reviews(order_id);


-- 2. ANALYTICS LAYER INDEXES
-- ============================================================


-- ------------------------------------------------------------
-- 2.1 FACT ORDERS — CUSTOMER
--
-- Supports customer-level analytics such as:
--   - purchase history
--   - order frequency
--   - RFM
--   - retention
--   - churn features
--
-- Note:
--   customer_unique_id is a foreign key but NOT a primary key,
--   so PostgreSQL does not automatically create an index for it.
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_fact_orders_customer_unique_id
ON analytics.fact_orders(customer_unique_id);


-- ------------------------------------------------------------
-- 2.2 FACT ORDERS — PURCHASE TIMESTAMP
--
-- Supports common analytical queries such as:
--   - monthly revenue
--   - yearly order trends
--   - cohort periods
--   - time-based filtering
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_fact_orders_purchase_timestamp
ON analytics.fact_orders(order_purchase_timestamp);


-- ------------------------------------------------------------
-- 2.3 FACT ORDER ITEMS — PRODUCT
--
-- Supports:
--   - product performance
--   - category performance
--   - product revenue
--   - product-level aggregation
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_fact_order_items_product_id
ON analytics.fact_order_items(product_id);


-- ------------------------------------------------------------
-- 2.4 FACT ORDER ITEMS — SELLER
--
-- Supports:
--   - seller performance
--   - seller revenue
--   - seller order-item volume
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_fact_order_items_seller_id
ON analytics.fact_order_items(seller_id);


-- ------------------------------------------------------------
-- 2.5 FACT PAYMENTS — ORDER
--
-- Supports order-to-payment joins and payment aggregation.
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_fact_payments_order_id
ON analytics.fact_payments(order_id);


-- ------------------------------------------------------------
-- 2.6 FACT REVIEWS — ORDER
--
-- Supports order-to-review joins and customer experience
-- analysis.
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_fact_reviews_order_id
ON analytics.fact_reviews(order_id);

