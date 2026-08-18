-- Revenue Definition:
--   price + freight_value
--
-- Net Definition:
--   order_status = 'delivered'
--
-- Timeline Anomalies (D002):
--   Included. They represent valid business transactions and
--   do not affect the revenue definition.
--
-- Date Filtering:
--   No period is hardcoded.
--   Power BI can apply date/month/year filters downstream.
--

-- ============================================================
-- SECTION 1 + 2
-- MONTHLY GROWTH + YEAR-OVER-YEAR GROWTH
-- ============================================================

WITH monthly_metrics AS (

    SELECT
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS month_start,

        -- ----------------------------------------------------
        -- Net Revenue
        -- Delivered orders only.
        -- Revenue = price + freight_value
        -- ----------------------------------------------------
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

        -- ----------------------------------------------------
        -- Net Orders
        -- Delivered orders only.
        -- ----------------------------------------------------
        COUNT(
            DISTINCT CASE
                WHEN o.order_status = 'delivered'
                THEN o.order_id
            END
        ) AS net_orders

    FROM analytics.fact_orders o

    LEFT JOIN analytics.fact_order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_purchase_timestamp IS NOT NULL

    GROUP BY
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )
),

growth_metrics AS (

    SELECT
        month_start,

        net_revenue,

        net_orders,

        -- ====================================================
        -- Month-over-Month Comparison
        --
        -- Previous available month.
        -- ====================================================

        LAG(net_revenue) OVER (
            ORDER BY month_start
        ) AS previous_month_revenue,

        LAG(net_orders) OVER (
            ORDER BY month_start
        ) AS previous_month_orders,

        -- ====================================================
        -- Year-over-Year Comparison
        --
        -- Partition by calendar month so that:
        --
        -- January 2017 → January 2016
        -- January 2018 → January 2017
        --
        -- Missing months do not shift the comparison.
        --
        -- If a previous-year observation does not exist,
        -- the result remains NULL.
        -- ====================================================

        LAG(net_revenue) OVER (
            PARTITION BY EXTRACT(
                MONTH FROM month_start
            )
            ORDER BY month_start
        ) AS previous_year_revenue,

        LAG(net_orders) OVER (
            PARTITION BY EXTRACT(
                MONTH FROM month_start
            )
            ORDER BY month_start
        ) AS previous_year_orders

    FROM monthly_metrics
)

SELECT
    month_start,

    -- ========================================================
    -- Current Month
    -- ========================================================

    net_revenue,

    net_orders,

    -- ========================================================
    -- Month-over-Month
    -- ========================================================

    previous_month_revenue,

    CASE
        WHEN previous_month_revenue IS NULL
             OR previous_month_revenue = 0
        THEN NULL

        ELSE
            (
                (
                    net_revenue
                    - previous_month_revenue
                )
                / previous_month_revenue
            ) * 100
    END AS mom_revenue_growth_pct,

    previous_month_orders,

    CASE
        WHEN previous_month_orders IS NULL
             OR previous_month_orders = 0
        THEN NULL

        ELSE
            (
                (
                    net_orders
                    - previous_month_orders
                )
                / previous_month_orders::NUMERIC
            ) * 100
    END AS mom_orders_growth_pct,

    -- ========================================================
    -- Year-over-Year
    -- ========================================================

    previous_year_revenue,

    CASE
        WHEN previous_year_revenue IS NULL
             OR previous_year_revenue = 0
        THEN NULL

        ELSE
            (
                (
                    net_revenue
                    - previous_year_revenue
                )
                / previous_year_revenue
            ) * 100
    END AS yoy_revenue_growth_pct,

    previous_year_orders,

    CASE
        WHEN previous_year_orders IS NULL
             OR previous_year_orders = 0
        THEN NULL

        ELSE
            (
                (
                    net_orders
                    - previous_year_orders
                )
                / previous_year_orders::NUMERIC
            ) * 100
    END AS yoy_orders_growth_pct

FROM growth_metrics

ORDER BY
    month_start;


-- ============================================================
-- SECTION 3
-- ORDER STATUS DISTRIBUTION
--
-- Output format:
--
-- month_start
-- order_status
-- order_count
-- pct_of_month_total
--
-- Long format is intentionally used for Power BI flexibility.
-- ============================================================

WITH monthly_status AS (

    SELECT
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS month_start,

        o.order_status,

        COUNT(DISTINCT o.order_id) AS order_count

    FROM analytics.fact_orders o

    WHERE o.order_purchase_timestamp IS NOT NULL

    GROUP BY
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        ),
        o.order_status
)

SELECT
    month_start,

    order_status,

    order_count,

    ROUND(
        (
            order_count::NUMERIC
            /
            SUM(order_count) OVER (
                PARTITION BY month_start
            )
        ) * 100,
        2
    ) AS pct_of_month_total

FROM monthly_status

ORDER BY
    month_start,
    order_count DESC,
    order_status;
