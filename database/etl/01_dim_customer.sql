-- Purpose:
--   Transform Raw customer records into the Analytics
--   customer dimension.
--
-- Grain:
--   1 row = 1 business customer (customer_unique_id)
--
-- D001 — Customer Identity Strategy:
--   customer_id        = source customer record
--   customer_unique_id = business customer identity
--
-- Deduplication strategy:
--   1. Group records by customer_unique_id and address attributes.
--   2. Select the most frequently observed address.
--   3. If frequency is tied, select the address associated
--      with the most recent order.


INSERT INTO analytics.dim_customer (
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)

WITH customer_profiles AS (

    SELECT
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        COUNT(*) AS profile_frequency

    FROM raw.customers c

    GROUP BY
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state
),

profile_recency AS (

    SELECT
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        MAX(o.order_purchase_timestamp) AS latest_order_timestamp

    FROM raw.customers c

    LEFT JOIN raw.orders o
        ON c.customer_id = o.customer_id

    GROUP BY
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state
),

ranked_profiles AS (

    SELECT
        cp.customer_unique_id,
        cp.customer_zip_code_prefix,
        cp.customer_city,
        cp.customer_state,
        cp.profile_frequency,
        pr.latest_order_timestamp,

        ROW_NUMBER() OVER (
            PARTITION BY cp.customer_unique_id
            ORDER BY
                cp.profile_frequency DESC,
                pr.latest_order_timestamp DESC NULLS LAST
        ) AS profile_rank

    FROM customer_profiles cp

    LEFT JOIN profile_recency pr
        ON cp.customer_unique_id = pr.customer_unique_id
        AND cp.customer_zip_code_prefix IS NOT DISTINCT FROM
            pr.customer_zip_code_prefix
        AND cp.customer_city IS NOT DISTINCT FROM
            pr.customer_city
        AND cp.customer_state IS NOT DISTINCT FROM
            pr.customer_state
)

-- 4. Keep exactly one profile per business customer.
-- ------------------------------------------------------------

SELECT
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state

FROM ranked_profiles

WHERE profile_rank = 1;