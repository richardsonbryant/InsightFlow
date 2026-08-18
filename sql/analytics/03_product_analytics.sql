-- Purpose:
--   Product and category performance analysis.
--
-- Section 1:
--   Product Performance
--
-- Section 2:
--   Category Performance
--
-- Section 3:
--   Category Trend
--
-- Business Definition:
--   - Net metrics = delivered orders only
--   - Units sold = COUNT(*) from fact_order_items
--   - Revenue = price + freight_value
--   - Average selling price = SUM(price) / units sold
--   - NULL category = 'Uncategorized'
--   - Top-N is handled through rank columns
--   - No hardcoded LIMIT

-- ============================================================
-- SECTION 1
-- PRODUCT PERFORMANCE
--
-- Grain:
--   1 row = 1 product

WITH product_metrics AS (

    SELECT
        oi.product_id,

        COALESCE(
            p.product_category_name_english,
            'Uncategorized'
        ) AS category_name,

        -- ----------------------------------------------------
        -- Net Revenue
        -- Delivered orders only.
        -- ----------------------------------------------------
        SUM(
            oi.price + oi.freight_value
        ) AS net_revenue,

        -- ----------------------------------------------------
        -- Units Sold
        -- One row in fact_order_items = one unit.
        -- ----------------------------------------------------
        COUNT(*) AS units_sold,

        -- ----------------------------------------------------
        -- Orders containing this product
        -- ----------------------------------------------------
        COUNT(
            DISTINCT oi.order_id
        ) AS orders_containing_product,

        -- ----------------------------------------------------
        -- Average selling price per unit
        -- Freight excluded intentionally.
        -- ----------------------------------------------------
        SUM(oi.price)
        /
        NULLIF(
            COUNT(*),
            0
        ) AS avg_selling_price

    FROM analytics.fact_order_items oi

    INNER JOIN analytics.fact_orders o
        ON oi.order_id = o.order_id

    INNER JOIN analytics.dim_product p
        ON oi.product_id = p.product_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        oi.product_id,
        COALESCE(
            p.product_category_name_english,
            'Uncategorized'
        )
)

SELECT
    product_id,
    category_name,
    net_revenue,
    units_sold,
    orders_containing_product,
    avg_selling_price,

    RANK() OVER (
        ORDER BY net_revenue DESC
    ) AS revenue_rank,

    RANK() OVER (
        ORDER BY units_sold DESC
    ) AS units_rank

FROM product_metrics

ORDER BY
    revenue_rank,
    product_id;


-- ============================================================
-- SECTION 2
-- CATEGORY PERFORMANCE
--
-- Grain:
--   1 row = 1 category

WITH category_metrics AS (

    SELECT
        COALESCE(
            p.product_category_name_english,
            'Uncategorized'
        ) AS category_name,

        -- ----------------------------------------------------
        -- Net Revenue
        -- ----------------------------------------------------
        SUM(
            oi.price + oi.freight_value
        ) AS net_revenue,

        -- ----------------------------------------------------
        -- Units Sold
        -- ----------------------------------------------------
        COUNT(*) AS units_sold,

        -- ----------------------------------------------------
        -- Number of distinct orders containing this category
        -- ----------------------------------------------------
        COUNT(
            DISTINCT oi.order_id
        ) AS orders

    FROM analytics.fact_order_items oi

    INNER JOIN analytics.fact_orders o
        ON oi.order_id = o.order_id

    INNER JOIN analytics.dim_product p
        ON oi.product_id = p.product_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        COALESCE(
            p.product_category_name_english,
            'Uncategorized'
        )
)

SELECT
    category_name,
    net_revenue,
    units_sold,
    orders,

    -- --------------------------------------------------------
    -- Share of total net revenue
    -- --------------------------------------------------------
    ROUND(
        (
            net_revenue
            /
            NULLIF(
                SUM(net_revenue) OVER (),
                0
            )
        ) * 100,
        2
    ) AS category_revenue_share_pct,

    RANK() OVER (
        ORDER BY net_revenue DESC
    ) AS revenue_rank

FROM category_metrics

ORDER BY
    revenue_rank,
    category_name;


-- ============================================================
-- SECTION 3
-- CATEGORY TREND
--
-- Grain:
--   1 row = 1 category per month


SELECT
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::DATE AS month_start,

    COALESCE(
        p.product_category_name_english,
        'Uncategorized'
    ) AS category_name,

    -- --------------------------------------------------------
    -- Monthly Net Revenue
    -- --------------------------------------------------------
    SUM(
        oi.price + oi.freight_value
    ) AS net_revenue,

    -- --------------------------------------------------------
    -- Monthly Units Sold
    -- --------------------------------------------------------
    COUNT(*) AS units_sold,

    -- --------------------------------------------------------
    -- Monthly Orders containing this category
    -- --------------------------------------------------------
    COUNT(
        DISTINCT oi.order_id
    ) AS orders

FROM analytics.fact_order_items oi

INNER JOIN analytics.fact_orders o
    ON oi.order_id = o.order_id

INNER JOIN analytics.dim_product p
    ON oi.product_id = p.product_id

WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL

GROUP BY
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    ),
    COALESCE(
        p.product_category_name_english,
        'Uncategorized'
    )

ORDER BY
    month_start,
    net_revenue DESC,
    category_name;
