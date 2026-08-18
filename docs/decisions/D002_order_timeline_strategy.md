# D002 — Order Timeline Anomaly Handling Strategy

| Metadata         | Value                       |
| ---------------- | --------------------------- |
| Date             | 2026-08-11                  |
| Phase            | Dataset Assessment          |
| Category         | Data Modeling               |
| Impact Level     | High                        |
| Related Notebook | 01_dataset_assessment.ipynb |

---

# Context

The initial dataset assessment identified chronological inconsistencies within the Orders dataset.

Two types of timeline anomalies were observed:

1. **order_delivered_carrier_date** occurred earlier than **order_approved_at**
2. **order_delivered_customer_date** occurred earlier than **order_delivered_carrier_date**

These inconsistencies violate the expected business process chronology:

Purchase → Approval → Carrier Pickup → Customer Delivery

Since InsightFlow relies on transaction history for customer analytics, it is necessary to determine whether these anomalies should be preserved, corrected, or removed before downstream processing. However, investigation revealed that order_purchase_timestamp—the foundational column for churn and repeat purchase analysis in InsightFlow—remains unaffected by these anomalies (0 violations in purchase → approved and purchase → delivered rules). This indicates that anomalies are confined to internal logistics timestamps (approved, carrier, delivered) and do not compromise the validity of core business transactions for customer analytics purposes.

---

# Investigation Summary

The investigation was documented in **01_dataset_assessment.ipynb**.

Key findings are summarized below.

| Finding                              | Result                                                                                         |
| ------------------------------------ | ---------------------------------------------------------------------------------------------- |
| Total affected orders                | 1,382 orders                                                                                   |
| Percentage of dataset                | ~1.39%                                                                                         |
| Dominant anomaly                     | Approved → Carrier (1,359 orders)                                                              |
| Secondary anomaly                    | Carrier → Customer (23 orders)                                                                 |
| Revenue contribution                 | ~1.31% of total revenue                                                                        |
| Order status                         | 99.35% Delivered                                                                               |
| Median severity (Approved → Carrier) | 17.17 hours                                                                                    |
| Median severity (Carrier → Customer) | 39.86 hours                                                                                    |
| Business impact                      | Average delivery duration remains comparable and does not indicate systematic business failure |

The investigation indicates that the detected inconsistencies primarily affect timestamp ordering rather than the completion of business transactions. Most anomalous orders were successfully delivered and contributed only a small proportion of total revenue.

---

# Decision

Timeline anomaly records will be **retained** in the dataset.

Instead of modifying or removing affected records, InsightFlow will introduce a dedicated anomaly flag that identifies orders containing timeline inconsistencies.

No original timestamps will be altered.

---

# Decision Rationale

This decision was made for the following reasons:

- The anomalies affect only a small proportion of the dataset (~1.39%).
- Additionally, anomalous orders demonstrate faster average delivery times (median 7 days) compared to normal orders (median 10 days), suggesting that timeline inconsistencies may result from delayed system logging of the approval timestamp rather than actual fulfillment failures.
- Nearly all affected orders represent successfully completed customer transactions (Delivered).
- Revenue associated with anomalous orders is relatively small (~1.31%).
- No objective evidence exists to determine which timestamp is incorrect.
- Modifying timestamps would introduce assumptions not supported by the data.
- Removing valid transactions would unnecessarily reduce historical customer information used for segmentation, retention analysis, and churn modelling.

Retaining the original data while explicitly identifying anomalous records provides the best balance between analytical integrity, transparency, and reproducibility.

---

# Alternatives Considered

## Option 1 — Keep

### Advantages

- Preserves all original records.
- No information loss.
- Fully reproducible.

### Disadvantages

- Timeline anomalies remain invisible.
- Delivery-related analyses may unintentionally include inconsistent records.

**Decision:** Rejected.

---

## Option 2 — Keep + Flag ✅

### Advantages

- Preserves all original data.
- Makes timeline anomalies transparent.
- Enables downstream analyses to include or exclude anomalous records when appropriate.
- Does not introduce unsupported assumptions.
- Maintains reproducibility.

### Disadvantages

- Requires an additional derived field.
- Slightly increases query complexity.

**Decision:** Accepted.

---

## Option 3 — Correct

### Advantages

- Produces chronologically consistent timestamps.

### Disadvantages

- No evidence indicates which timestamp is actually incorrect.
- Requires modifying original business records.
- Reduces reproducibility and auditability.

**Decision:** Rejected.

---

## Option 4 — Drop

### Advantages

- Removes inconsistent records completely.

### Disadvantages

- Removes 1,382 valid customer transactions.
- Reduces historical behavioural information.
- Removes approximately 1.31% of recorded revenue.
- Discards completed business transactions despite successful delivery.

**Decision:** Rejected.

---

# Consequences

The following consequences are accepted as part of this decision:

- Raw source data will remain unchanged.
- A derived timeline anomaly indicator will be created during data preparation.
- Delivery performance analysis may optionally exclude flagged records.
- Customer analytics, segmentation, retention analysis, and churn modelling will continue using the complete transaction history.
- All downstream users can explicitly identify records affected by timeline inconsistencies.

---

## Implementation Details for ETL

The timeline anomaly flag will be implemented as follows:

- **Field Name:** `has_timeline_anomaly`
- **Type:** Boolean (TRUE/FALSE)
- **Logic:** Set to TRUE for any order_id present in either:
  - approved_at > delivered_carrier_date (1,359 orders)
  - delivered_carrier_date > delivered_customer_date (23 orders)
- **Placement:** Derived field created during ETL, not stored in raw database
- **Usage:** Enables downstream analyses to conditionally exclude flagged records when appropriate

---

# Future Considerations

If future datasets provide additional operational logs or trusted event timestamps, the anomaly handling strategy may be re-evaluated.

Should objective evidence become available to identify the correct event sequence, timestamp correction may be considered in a future project version.

---

# Design Principle

When data quality issues do not materially affect the business entity being analysed and there is insufficient evidence to determine the correct value, the preferred strategy is to preserve the original data and explicitly flag affected records rather than modifying or removing them.
