-- Purpose:
--   Transform Raw payment records into the Analytics
--   payment fact table.
--
-- Grain:
--   1 row = 1 payment record
--
-- Primary Key:
--   (order_id, payment_sequential)
--
-- D003 — Payment Record Anomaly Handling Strategy:
--
--   Payment records are preserved without modification.
--
--   payment_value <= 0:
--       No anomaly flag is created.
--       Investigation confirmed that these records can
--       represent valid voucher or cancelled-order scenarios.
--
--   payment_installments <= 0:
--       Retained and flagged using has_installments_anomaly
--       because the business explanation remains unresolved.



INSERT INTO analytics.fact_payments (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,
    has_installments_anomaly
)

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,

    CASE
        WHEN payment_installments <= 0
            THEN TRUE
        ELSE FALSE
    END AS has_installments_anomaly

FROM raw.payments;