-- Purpose:
--   Transform Raw product records into the Analytics
--   product dimension.
--
-- Grain:
--   1 row = 1 product_id
--
-- Category strategy:
--   - Preserve the original product_category_name.
--   - Add English translation when available.
--   - Products without translation are retained.
--   - Missing translations remain NULL.
--


INSERT INTO analytics.dim_product (
    product_id,
    product_category_name,
    product_category_name_english,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)

SELECT
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,
    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm

FROM raw.products p

LEFT JOIN raw.category_translation t
    ON p.product_category_name = t.product_category_name;