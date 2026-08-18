-- Purpose:
--   Create the PostgreSQL database structure for InsightFlow.
--
-- Scope:
--   1. Create database schemas
--   2. Create Raw Layer tables
--   3. Create Analytics Layer tables
--   4. Define primary keys
--   5. Define Analytics Layer foreign keys
--   6. Define structural constraints

-- 1. CREATE SCHEMAS
-- ============================================================

CREATE SCHEMA IF NOT EXISTS raw;

CREATE SCHEMA IF NOT EXISTS analytics;


-- 2. RAW LAYER
-- ============================================================


-- ============================================================
-- 2.1 RAW CUSTOMERS
--
-- Grain:
--   One row = one source customer record
--
-- Primary Key:
--   customer_id
--
-- Note:
--   customer_unique_id is retained as the business customer
--   identifier but is NOT the Raw Layer primary key.
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);


-- ============================================================
-- 2.2 RAW ORDERS
--
-- Grain:
--   One row = one order
--
-- Primary Key:
--   order_id
--
-- Logical Relationship:
--   customer_id → raw.customers.customer_id
--
-- IMPORTANT:
--   No foreign key constraint is enforced in the Raw Layer.
--   Referential integrity is validated during ETL.
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(30),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);


-- ============================================================
-- 2.3 RAW ORDER ITEMS
--
-- Grain:
--   One row = one purchased item within an order
--
-- Primary Key:
--   (order_id, order_item_id)
--
-- Logical Relationships:
--   order_id   → raw.orders.order_id
--   product_id → raw.products.product_id
--   seller_id  → raw.sellers.seller_id
--
-- IMPORTANT:
--   No foreign key constraints are enforced in the Raw Layer.
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.order_items (
    order_id VARCHAR(50) NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    seller_id VARCHAR(50) NOT NULL,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12,2),
    freight_value NUMERIC(12,2),

    PRIMARY KEY (order_id, order_item_id)
);


-- ============================================================
-- 2.4 RAW PAYMENTS
--
-- Grain:
--   One row = one payment record
--
-- Primary Key:
--   (order_id, payment_sequential)
--
-- Logical Relationship:
--   order_id → raw.orders.order_id
--
-- IMPORTANT:
--   No foreign key constraint is enforced in the Raw Layer.
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.payments (
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INTEGER NOT NULL,
    payment_type VARCHAR(30),
    payment_installments INTEGER,
    payment_value NUMERIC(12,2),

    PRIMARY KEY (order_id, payment_sequential)
);


-- ============================================================
-- 2.5 RAW PRODUCTS
--
-- Grain:
--   One row = one product
--
-- Primary Key:
--   product_id
--
-- Note:
--   The original product category value is preserved.
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g NUMERIC(12,3),
    product_length_cm NUMERIC(12,2),
    product_height_cm NUMERIC(12,2),
    product_width_cm NUMERIC(12,2)
);


-- ============================================================
-- 2.6 RAW SELLERS
--
-- Grain:
--   One row = one seller
--
-- Primary Key:
--   seller_id
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);


-- ============================================================
-- 2.7 RAW REVIEWS
--
-- Grain:
--   One row = one review record associated with an order
--
-- Primary Key:
--   (review_id, order_id)
--
-- Logical Relationship:
--   order_id → raw.orders.order_id
--
-- IMPORTANT:
--   No foreign key constraint is enforced in the Raw Layer.
--
-- Review ID Duplication:
--   review_id is intentionally NOT used as a standalone PK
--   because the source dataset contains repeated review_id
--   values across multiple orders.
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.reviews (
    review_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,

    PRIMARY KEY (review_id, order_id)
);


-- ============================================================
-- 2.8 RAW GEOLOCATION
--
-- Grain:
--   One row = one geographic reference record
--
-- Primary Key:
--   None
--
-- Reason:
--   The source dataset contains substantial full-row
--   duplication and does not provide a reliable single-column
--   natural key.
--
-- The table remains Raw-only for the MVP.
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat NUMERIC(12,8),
    geolocation_lng NUMERIC(12,8),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);


-- ============================================================
-- 2.9 RAW CATEGORY TRANSLATION
--
-- Grain:
--   One row = one product-category translation mapping
--
-- Primary Key:
--   product_category_name
--
-- Note:
--   The translated category is incorporated into
--   analytics.dim_product during ETL.
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);


-- 3. ANALYTICS LAYER
-- ============================================================


-- ============================================================
-- 3.1 ANALYTICS DIM_CUSTOMER
--
-- Grain:
--   One row = one unique business customer
--
-- Primary Key:
--   customer_unique_id
--
-- D001:
--   customer_unique_id is the business customer identity
--   used in the Analytics Layer.
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.dim_customer (
    customer_unique_id VARCHAR(50) PRIMARY KEY,
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);


-- ============================================================
-- 3.2 ANALYTICS DIM_PRODUCT
--
-- Grain:
--   One row = one product
--
-- Primary Key:
--   product_id
--
-- Note:
--   product_category_name_english is derived from
--   raw.category_translation during ETL.
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.dim_product (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g NUMERIC(12,3),
    product_length_cm NUMERIC(12,2),
    product_height_cm NUMERIC(12,2),
    product_width_cm NUMERIC(12,2)
);


-- ============================================================
-- 3.3 ANALYTICS DIM_SELLER
--
-- Grain:
--   One row = one seller
--
-- Primary Key:
--   seller_id
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.dim_seller (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);


-- ============================================================
-- 3.4 ANALYTICS FACT_ORDERS
--
-- Grain:
--   One row = one order
--
-- Primary Key:
--   order_id
--
-- Foreign Key:
--   customer_unique_id
--       → analytics.dim_customer.customer_unique_id
--
-- D002:
--   has_timeline_anomaly identifies known order timeline
--   anomalies without modifying the original timestamps.
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.fact_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(30),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,

    has_timeline_anomaly BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT fk_fact_orders_customer
        FOREIGN KEY (customer_unique_id)
        REFERENCES analytics.dim_customer(customer_unique_id)
);


-- ============================================================
-- 3.5 ANALYTICS FACT_ORDER_ITEMS
--
-- Grain:
--   One row = one purchased item
--
-- Primary Key:
--   (order_id, order_item_id)
--
-- Foreign Keys:
--   order_id
--       → analytics.fact_orders.order_id
--
--   product_id
--       → analytics.dim_product.product_id
--
--   seller_id
--       → analytics.dim_seller.seller_id
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.fact_order_items (
    order_id VARCHAR(50) NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    seller_id VARCHAR(50) NOT NULL,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12,2),
    freight_value NUMERIC(12,2),

    PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT fk_fact_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES analytics.fact_orders(order_id),

    CONSTRAINT fk_fact_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES analytics.dim_product(product_id),

    CONSTRAINT fk_fact_order_items_seller
        FOREIGN KEY (seller_id)
        REFERENCES analytics.dim_seller(seller_id)
);


-- ============================================================
-- 3.6 ANALYTICS FACT_PAYMENTS
--
-- Grain:
--   One row = one payment record
--
-- Primary Key:
--   (order_id, payment_sequential)
--
-- Foreign Key:
--   order_id
--       → analytics.fact_orders.order_id
--
-- D003:
--   has_installments_anomaly identifies known payment
--   installment anomalies without modifying original values.
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.fact_payments (
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INTEGER NOT NULL,
    payment_type VARCHAR(30),
    payment_installments INTEGER,
    payment_value NUMERIC(12,2),

    has_installments_anomaly BOOLEAN NOT NULL DEFAULT FALSE,

    PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT fk_fact_payments_order
        FOREIGN KEY (order_id)
        REFERENCES analytics.fact_orders(order_id)
);


-- ============================================================
-- 3.7 ANALYTICS FACT_REVIEWS
--
-- Grain:
--   One row = one review record associated with an order
--
-- Primary Key:
--   (review_id, order_id)
--
-- Foreign Key:
--   order_id
--       → analytics.fact_orders.order_id
--
-- The composite key follows the approved review key strategy.
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.fact_reviews (
    review_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,

    PRIMARY KEY (review_id, order_id),

    CONSTRAINT fk_fact_reviews_order
        FOREIGN KEY (order_id)
        REFERENCES analytics.fact_orders(order_id)
);
