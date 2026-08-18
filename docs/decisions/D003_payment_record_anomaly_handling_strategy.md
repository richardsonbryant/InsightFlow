# D003 — Payment Record Anomaly Handling Strategy

| Metadata         | Value                       |
| ---------------- | --------------------------- |
| Date             | 2026-08-11                  |
| Phase            | Dataset Assessment          |
| Category         | Data Quality                |
| Impact Level     | High                        |
| Related Notebook | 01_dataset_assessment.ipynb |

---

# Context

The initial dataset profiling identified several payment records containing unexpected values, including payment records with **payment_value <= 0** and **payment_installments <= 0**.

At first glance, these records appeared to represent invalid payment transactions that could potentially affect revenue analysis, customer analytics, and downstream feature engineering.

However, because the Payment dataset stores **payment records rather than complete order transactions**, additional investigation was required before determining whether these records represented genuine data quality issues or valid business scenarios.

---

# Investigation Summary

The investigation was documented in **01_dataset_assessment.ipynb**.

Key findings are summarized below.

| Finding                              | Result                                                                             |
| ------------------------------------ | ---------------------------------------------------------------------------------- |
| payment_value <= 0                   | 9 records                                                                          |
| payment_installments <= 0            | 2 records                                                                          |
| Unique affected orders               | 8 orders                                                                           |
| Dominant payment type                | Voucher (6 records)                                                                |
| Secondary payment type               | not_defined (3 records)                                                            |
| Zero-installment records             | 2 records                                                                          |
| Order status (payment_value anomaly) | Mostly Delivered; cancelled records only occurred for `payment_type = not_defined` |
| Order status (installment anomaly)   | 100% Delivered                                                                     |
| Order-level payment validation       | Payment totals remained consistent with order values                               |

The investigation showed that the apparent anomalies primarily existed at the **payment record level** rather than the **order level**.

Voucher-related records with zero payment values were still associated with fully paid orders after aggregating all payment records belonging to the same order.

Similarly, records using `payment_type = not_defined` were associated with cancelled orders where no completed transaction occurred.

No evidence was found indicating systematic payment corruption or missing customer payments.

---

# Decision

Payment records will be retained without modification. However, the two
anomaly types require differentiated treatment based on their level of
certainty:

- **Payment Value Anomaly (9 records):** No flag required. Order-level
  consistency validation proved these records represent valid business
  scenarios (voucher payments and cancelled orders). Aggregated
  payment/revenue metrics at the order level are unaffected and require
  no special handling.

- **Installments Anomaly (2 records):** Retained with a derived flag
  (`has_installments_anomaly`) due to unresolved uncertainty. Unlike the
  payment value anomaly, pattern analysis did not reveal a business
  explanation for these records, warranting transparency for downstream
  users.

---

# Decision Rationale

This decision was made based on the following findings:

- Only **11 payment records** (8 unique orders) exhibited zero payment values.
- Most anomalous records belonged to voucher transactions.
- Order-level validation confirmed that total payments remained consistent with total order values.
- Cancelled orders with `payment_type = not_defined` represent valid business outcomes rather than payment failures.
- Zero-installment records occurred only twice and represented isolated edge cases.
- No objective evidence exists to determine that any payment record contains incorrect monetary values.

Therefore, modifying or removing these records would introduce unnecessary assumptions while reducing dataset reproducibility.

---

# Alternatives Considered

## Option 1 — Keep

### Advantages

- Preserves all original payment records.
- No information loss.
- Fully reproducible.

### Disadvantages

- Payment anomalies remain undocumented.
- Downstream users cannot easily distinguish unusual payment records.

**Decision:** Rejected.

---

## Option 2 — Keep + Flag ✅

### Advantages

- Preserves all original payment records.
- Makes payment anomalies transparent.
- Supports optional filtering during downstream analytics.
- Does not introduce unsupported assumptions.
- Maintains reproducibility.

### Disadvantages

- Requires one additional derived attribute.
- Slightly increases query complexity.

**Decision:** Accepted.

---

## Option 3 — Correct

### Advantages

- Produces apparently cleaner payment data.

### Disadvantages

- No evidence identifies which payment values should be corrected.
- Requires modifying original transactional records.
- Reduces auditability and reproducibility.

**Decision:** Rejected.

---

## Option 4 — Drop

### Advantages

- Removes unusual payment records completely.

### Disadvantages

- Removes payment records belonging to otherwise valid customer orders.
- Discards legitimate voucher payment scenarios.
- Removes historical transaction evidence without sufficient justification.

**Decision:** Rejected.

---

# Consequences

The following consequences are accepted as part of this decision:

- Original payment records remain unchanged.
- A derived payment anomaly indicator will be generated during data preparation.
- Revenue analysis will continue using aggregated order-level payments.
- Customer analytics and machine learning models will continue using complete payment history.
- Downstream analyses may optionally exclude flagged payment records where appropriate.

---

# Future Considerations

If future datasets provide additional payment gateway logs or transactional audit trails, the anomaly handling strategy may be revisited.

Future versions of InsightFlow may classify payment anomalies into more specific categories based on operational metadata that is unavailable in the current dataset.

---

# Design Principle

Apparent anomalies observed at the transaction-record level should not automatically be treated as invalid business events.

Whenever possible, data quality assessments should be performed at the business entity level—in this case, the order level—before deciding to modify, remove, or retain transactional records.

When the aggregated business entity remains internally consistent, the preferred strategy is to preserve the original records and explicitly flag unusual cases rather than altering historical transaction data.
