-- Purpose:
--   Executive-level monthly business metrics.
--
-- Grain:
--   1 row = 1 calendar month
--
-- Metrics:
--   Gross Revenue = SUM(price + freight_value), all orders
--   Net Revenue   = SUM(price + freight_value), delivered orders
--   Gross Orders  = COUNT(DISTINCT order_id), all orders
--   Net Orders    = COUNT(DISTINCT order_id), delivered orders
--   AOV           = Net Revenue / Net Orders
--
-- Timeline anomalies (D002):
--   Included. They represent valid business transactions and
--   do not affect the revenue definition.
--
-- Date filtering:
--   No hardcoded dashboard period.
--   Full historical period is exposed so Power BI can apply
--   filters such as Nov 2017 - Oct 2018, month, or year.
--
-- Revenue source:
--   fact_order_items.price + freight_value
--   NOT fact_payments.payment_value.


SELECT
    EXTRACT(YEAR FROM o.order_purchase_timestamp)::INTEGER
        AS year,

    EXTRACT(MONTH FROM o.order_purchase_timestamp)::INTEGER
        AS month,

    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::DATE AS month_start,

    -- --------------------------------------------------------
    -- Gross Revenue
    -- All orders regardless of order status.
    -- --------------------------------------------------------
    COALESCE(
        SUM(
            oi.price + oi.freight_value
        ),
        0
    ) AS gross_revenue,

    -- --------------------------------------------------------
    -- Net Revenue
    -- Only successfully delivered orders.
    -- --------------------------------------------------------
    COALESCE(
        SUM(
            CASE
                WHEN o.order_status = 'delivered'
                THEN oi.price + oi.freight_value
                ELSE 0
            END
        ),
        0
    ) AS net_revenue,

    -- --------------------------------------------------------
    -- Gross Orders
    -- All orders regardless of status.
    -- --------------------------------------------------------
    COUNT(DISTINCT o.order_id)
        AS gross_orders,

    -- --------------------------------------------------------
    -- Net Orders
    -- Only delivered orders.
    -- --------------------------------------------------------
    COUNT(
        DISTINCT CASE
            WHEN o.order_status = 'delivered'
            THEN o.order_id
        END
    ) AS net_orders,

    -- --------------------------------------------------------
    -- AOV
    -- Net Revenue / Net Orders
    -- --------------------------------------------------------
    COALESCE(
        SUM(
            CASE
                WHEN o.order_status = 'delivered'
                THEN oi.price + oi.freight_value
                ELSE 0
            END
        )
        /
        NULLIF(
            COUNT(
                DISTINCT CASE
                    WHEN o.order_status = 'delivered'
                    THEN o.order_id
                END
            ),
            0
        ),
        0
    ) AS aov

FROM analytics.fact_orders o

LEFT JOIN analytics.fact_order_items oi
    ON o.order_id = oi.order_id

GROUP BY
    EXTRACT(YEAR FROM o.order_purchase_timestamp),
    EXTRACT(MONTH FROM o.order_purchase_timestamp),
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )

ORDER BY
    month_start;