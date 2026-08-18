-- Purpose:
--   Transform Raw order records into the Analytics
--   order fact table.
--
-- Grain:
--   1 row = 1 order
--
-- Customer Identity:
--   customer_id is resolved to customer_unique_id
--   using raw.customers.
--
-- D002 — Order Timeline Strategy:
--   Timeline anomalies are preserved and flagged.
--   Raw timestamps are NOT modified.
--
-- Timeline anomaly rules:
--   1. carrier date before purchase timestamp
--   2. customer delivery before carrier date
--
-- NULL timestamps are not treated as anomalies.


INSERT INTO analytics.fact_orders (
    order_id,
    customer_unique_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    has_timeline_anomaly
)

SELECT
    o.order_id,
    c.customer_unique_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    CASE
        WHEN o.order_delivered_carrier_date IS NOT NULL
            AND o.order_approved_at IS NOT NULL
            AND o.order_delivered_carrier_date < o.order_approved_at
            THEN TRUE
        WHEN o.order_delivered_customer_date IS NOT NULL
            AND o.order_delivered_carrier_date IS NOT NULL
            AND o.order_delivered_customer_date < o.order_delivered_carrier_date
            THEN TRUE
        ELSE FALSE
    END AS has_timeline_anomaly

FROM raw.orders o

INNER JOIN raw.customers c
    ON o.customer_id = c.customer_id;