-- Purpose:
--   Transform Raw seller records into the Analytics
--   seller dimension.
--
-- Grain:
--   1 row = 1 seller_id
--
-- Transformation:
--   Direct 1:1 mapping from raw.sellers.


INSERT INTO analytics.dim_seller (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state

FROM raw.sellers;