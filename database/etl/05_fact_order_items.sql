-- Purpose:
--   Transform Raw order-item records into the Analytics
--   order-item fact table.
--
-- Grain:
--   1 row = 1 order item
--
-- Primary Key:
--   (order_id, order_item_id)
--
-- Transformation:
--   Direct 1:1 mapping from raw.order_items.
--
-- The following source attributes are preserved:
--   - product_id
--   - seller_id
--   - shipping_limit_date
--   - price
--   - freight_value
--
-- No aggregation is performed.
-- Order-item records are not removed because of anomalies
-- in their parent order.



INSERT INTO analytics.fact_order_items (
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
)

SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value

FROM raw.order_items;