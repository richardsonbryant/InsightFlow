-- Purpose:
--   Transform Raw review records into the Analytics
--   review fact table.
--
-- Grain:
--   1 row = 1 review record associated with an order
--
-- Primary Key:
--   (review_id, order_id)
--
-- Review Identity Strategy:
--   review_id is NOT treated as a globally unique key.
--   Investigation identified 789 review_id values appearing
--   across multiple orders.
--
--   The composite key (review_id, order_id) correctly
--   represents the Raw Layer grain and preserves all
--   source records.
--
-- Review content is preserved without modification.


INSERT INTO analytics.fact_reviews (
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp

FROM raw.reviews;