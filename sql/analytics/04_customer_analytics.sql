-- Purpose:
--   Customer-level analytics foundation.
--
-- Business Definitions:
--   Customer identity = customer_unique_id
--   Valid purchase   = delivered orders
--   Revenue          = price + freight_value
--   Units             = COUNT(*) from fact_order_items
--
-- New Customer:
--   Customer's first delivered purchase occurs in month X.
--
-- Returning Customer:
--   Customer's first delivered purchase occurred before month X
--   AND customer has a delivered order in month X.
--
-- Recency Reference:
--   MAX(order_purchase_timestamp) from delivered orders.
--
-- At-Risk:
--   recency_days > 180
--
-- RFM scoring and churn prediction are intentionally NOT
-- calculated here. They belong to Phase 4.
-- ============================================================


-- ============================================================
-- SECTION 1
-- CUSTOMER BEHAVIORAL BASE
--
-- Grain:
--   1 row = 1 customer_unique_id
--
-- Purpose:
--   Reusable customer-level analytical foundation for:
--   - Customer Dashboard
--   - RFM
--   - Segmentation
--   - Churn analysis
--
-- ============================================================

WITH customer_orders AS (

    SELECT
        o.order_id,
        o.customer_unique_id,
        o.order_purchase_timestamp,

        -- ----------------------------------------------------
        -- Order-level revenue
        -- ----------------------------------------------------

        SUM(
            oi.price + oi.freight_value
        ) AS order_revenue,

        -- ----------------------------------------------------
        -- Order-level units
        -- One row in fact_order_items = one unit.
        -- ----------------------------------------------------

        COUNT(*) AS order_units

    FROM analytics.fact_orders o

    INNER JOIN analytics.fact_order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'
      AND o.customer_unique_id IS NOT NULL
      AND o.order_purchase_timestamp IS NOT NULL

    GROUP BY
        o.order_id,
        o.customer_unique_id,
        o.order_purchase_timestamp
),

reference_date AS (

    SELECT
        MAX(order_purchase_timestamp)::DATE
            AS analysis_reference_date

    FROM analytics.fact_orders

    WHERE order_status = 'delivered'
      AND order_purchase_timestamp IS NOT NULL
),

customer_behavioral_base AS (

    SELECT
        co.customer_unique_id,

        -- ----------------------------------------------------
        -- Purchase dates
        -- ----------------------------------------------------

        MIN(
            co.order_purchase_timestamp
        )::DATE AS first_purchase_date,

        MAX(
            co.order_purchase_timestamp
        )::DATE AS last_purchase_date,

        -- ----------------------------------------------------
        -- Customer frequency
        -- ----------------------------------------------------

        COUNT(
            DISTINCT co.order_id
        ) AS total_orders,

        -- ----------------------------------------------------
        -- Customer units
        -- ----------------------------------------------------

        SUM(
            co.order_units
        ) AS total_units,

        -- ----------------------------------------------------
        -- Customer monetary value
        -- ----------------------------------------------------

        SUM(
            co.order_revenue
        ) AS total_revenue,

        -- ----------------------------------------------------
        -- Average Order Value
        -- ----------------------------------------------------

        SUM(
            co.order_revenue
        )
        /
        NULLIF(
            COUNT(DISTINCT co.order_id),
            0
        ) AS avg_order_value,

        -- ----------------------------------------------------
        -- Customer lifetime
        -- ----------------------------------------------------

        (
            MAX(
                co.order_purchase_timestamp
            )::DATE
            -
            MIN(
                co.order_purchase_timestamp
            )::DATE
        ) AS customer_lifetime_days,

        -- ----------------------------------------------------
        -- Recency
        --
        -- Reference:
        --   Maximum delivered purchase date in dataset.
        -- ----------------------------------------------------

        (
            rd.analysis_reference_date
            -
            MAX(
                co.order_purchase_timestamp
            )::DATE
        ) AS recency_days

    FROM customer_orders co

    CROSS JOIN reference_date rd

    GROUP BY
        co.customer_unique_id,
        rd.analysis_reference_date
)

SELECT
    customer_unique_id,

    first_purchase_date,

    last_purchase_date,

    total_orders,

    total_units,

    total_revenue,

    avg_order_value,

    customer_lifetime_days,

    recency_days,

    -- --------------------------------------------------------
    -- Customer activity risk flag
    --
    -- Active:
    --   recency_days <= 180
    --
    -- At-Risk:
    --   recency_days > 180
    -- --------------------------------------------------------

    CASE
        WHEN recency_days > 180
        THEN TRUE
        ELSE FALSE
    END AS is_at_risk

FROM customer_behavioral_base

ORDER BY
    customer_unique_id;


-- ============================================================
-- SECTION 2
-- NEW VS RETURNING CUSTOMERS
--
-- Grain:
--   1 row = 1 month
--
-- Definitions:
--
-- New:
--   first delivered purchase occurs in month X.
--
-- Returning:
--   first delivered purchase occurred before month X
--   AND customer has a delivered order in month X.
--
-- Active:
--   customer has at least one delivered order in month X.
--
-- ============================================================

WITH customer_monthly_activity AS (

    SELECT DISTINCT
        o.customer_unique_id,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS month_start

    FROM analytics.fact_orders o

    WHERE o.order_status = 'delivered'
      AND o.customer_unique_id IS NOT NULL
      AND o.order_purchase_timestamp IS NOT NULL
),

customer_first_purchase AS (

    SELECT
        customer_unique_id,

        MIN(month_start)
            AS first_purchase_month

    FROM customer_monthly_activity

    GROUP BY
        customer_unique_id
),

monthly_customer_status AS (

    SELECT
        cma.month_start,

        cma.customer_unique_id,

        cfp.first_purchase_month,

        CASE
            WHEN cfp.first_purchase_month = cma.month_start
                THEN 'new'

            WHEN cfp.first_purchase_month < cma.month_start
                THEN 'returning'
        END AS customer_status

    FROM customer_monthly_activity cma

    INNER JOIN customer_first_purchase cfp
        ON cma.customer_unique_id =
           cfp.customer_unique_id
)

SELECT
    month_start,

    -- --------------------------------------------------------
    -- New Customers
    -- --------------------------------------------------------

    COUNT(*) FILTER (
        WHERE customer_status = 'new'
    ) AS new_customers,

    -- --------------------------------------------------------
    -- Returning Customers
    -- --------------------------------------------------------

    COUNT(*) FILTER (
        WHERE customer_status = 'returning'
    ) AS returning_customers,

    -- --------------------------------------------------------
    -- Total Active Customers
    -- --------------------------------------------------------

    COUNT(*) AS total_active_customers,

    -- --------------------------------------------------------
    -- New Customer %
    -- --------------------------------------------------------

    ROUND(
        COUNT(*) FILTER (
            WHERE customer_status = 'new'
        )::NUMERIC
        /
        NULLIF(COUNT(*), 0)
        * 100,
        2
    ) AS new_customer_pct,

    -- --------------------------------------------------------
    -- Returning Customer %
    -- --------------------------------------------------------

    ROUND(
        COUNT(*) FILTER (
            WHERE customer_status = 'returning'
        )::NUMERIC
        /
        NULLIF(COUNT(*), 0)
        * 100,
        2
    ) AS returning_customer_pct

FROM monthly_customer_status

GROUP BY
    month_start

ORDER BY
    month_start;


-- ============================================================
-- SECTION 3
-- MONTHLY COHORT RETENTION
--
-- Grain:
--   1 row = 1 cohort_month × activity_month
--
-- Definitions:
--
-- cohort_month:
--   Month of customer's first delivered purchase.
--
-- activity_month:
--   Month in which customer made a delivered purchase.
--
-- months_since_first_purchase:
--   Calendar month difference between cohort and activity.
--
-- Month 0:
--   Original cohort → expected retention = 100%.
--
-- ============================================================

WITH customer_monthly_activity AS (

    SELECT DISTINCT
        o.customer_unique_id,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS activity_month

    FROM analytics.fact_orders o

    WHERE o.order_status = 'delivered'
      AND o.customer_unique_id IS NOT NULL
      AND o.order_purchase_timestamp IS NOT NULL
),

customer_cohorts AS (

    SELECT
        customer_unique_id,

        MIN(activity_month)
            AS cohort_month

    FROM customer_monthly_activity

    GROUP BY
        customer_unique_id
),

cohort_activity AS (

    SELECT
        cc.cohort_month,

        cma.activity_month,

        cma.customer_unique_id,

        -- ----------------------------------------------------
        -- Calendar month difference
        --
        -- Convert YYYY-MM into a continuous month number:
        --
        -- year * 12 + month
        --
        -- This avoids AGE() and makes the calculation explicit.
        -- ----------------------------------------------------

        (
            (
                EXTRACT(
                    YEAR FROM cma.activity_month
                ) * 12
                +
                EXTRACT(
                    MONTH FROM cma.activity_month
                )
            )
            -
            (
                EXTRACT(
                    YEAR FROM cc.cohort_month
                ) * 12
                +
                EXTRACT(
                    MONTH FROM cc.cohort_month
                )
            )
        )::INT AS months_since_first_purchase

    FROM customer_cohorts cc

    INNER JOIN customer_monthly_activity cma
        ON cc.customer_unique_id =
           cma.customer_unique_id

    WHERE cma.activity_month >= cc.cohort_month
),

cohort_size AS (

    SELECT
        cohort_month,

        COUNT(
            DISTINCT customer_unique_id
        ) AS cohort_customers

    FROM cohort_activity

    WHERE months_since_first_purchase = 0

    GROUP BY
        cohort_month
)

SELECT
    ca.cohort_month,

    ca.activity_month,

    ca.months_since_first_purchase,

    cs.cohort_customers,

    COUNT(
        DISTINCT ca.customer_unique_id
    ) AS retained_customers,

    ROUND(
        COUNT(
            DISTINCT ca.customer_unique_id
        )::NUMERIC
        /
        NULLIF(
            cs.cohort_customers,
            0
        )
        * 100,
        2
    ) AS retention_rate_pct

FROM cohort_activity ca

INNER JOIN cohort_size cs
    ON ca.cohort_month =
       cs.cohort_month

GROUP BY
    ca.cohort_month,
    ca.activity_month,
    ca.months_since_first_purchase,
    cs.cohort_customers

ORDER BY
    ca.cohort_month,
    ca.months_since_first_purchase;
