-- Purpose:
--   Clear Analytics Layer before rebuilding it from Raw Layer.

TRUNCATE TABLE
    analytics.fact_reviews,
    analytics.fact_payments,
    analytics.fact_order_items,
    analytics.fact_orders,
    analytics.dim_seller,
    analytics.dim_product,
    analytics.dim_customer;