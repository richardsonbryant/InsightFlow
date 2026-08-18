# Data Quality Report

| Metadata     | Value                            |
| ------------ | -------------------------------- |
| Project      | InsightFlow                      |
| Phase        | Dataset Acquisition & Assessment |
| Version      | 1.0                              |
| Status       | Completed                        |
| Last Updated | 2026-08-12                       |

---

# 1. Purpose

This report documents the data quality assessment performed on the Olist E-Commerce Dataset.

Its objective is to identify potential data quality issues, evaluate their business impact, and document the adopted handling strategies before database implementation and downstream analytical development.

Unlike the Dataset Assessment Report, this document focuses specifically on technical data quality findings.

---

# 2. Assessment Dimensions

The following data quality dimensions were evaluated throughout the assessment process.

| Dimension    | Description                                |
| ------------ | ------------------------------------------ |
| Completeness | Missing values and data availability       |
| Uniqueness   | Duplicate business records                 |
| Consistency  | Logical consistency between related fields |
| Validity     | Invalid or unexpected values               |
| Integrity    | Relationship consistency between datasets  |

---

# 3. Dataset-Level Assessment

| Dataset              | Completeness         | Duplicate | Major Issue                         | Status   |
| -------------------- | -------------------- | --------- | ----------------------------------- | -------- |
| Customers            | Good                 | None      | Customer identifier selection       | Reviewed |
| Orders               | Good                 | None      | Timeline inconsistencies            | Reviewed |
| Order Items          | Good                 | None      | None                                | Passed   |
| Payments             | Good                 | None      | Payment record anomalies            | Reviewed |
| Reviews              | Good                 | None      | None                                | Passed   |
| Products             | Minor Missing Values | None      | Expected missing product attributes | Passed   |
| Sellers              | Good                 | None      | None                                | Passed   |
| Geolocation          | Good                 | None      | None                                | Passed   |
| Category Translation | Good                 | None      | None                                | Passed   |

---

# 4. Identified Data Quality Findings

## Finding 1 — Customer Identifier

### Description

The Customers dataset contains two identifier columns:

- customer_id
- customer_unique_id

Both identifiers are valid but represent different business concepts.

### Business Impact

Selecting the incorrect identifier would produce inaccurate customer-level analytics, including repeat purchase analysis, customer lifetime value, and churn modelling.

### Resolution

Use:

- customer_unique_id for customer analytics
- customer_id for transactional relationships

**Decision Reference**

D001 — Customer Identity Strategy

---

## Finding 2 — Timeline Consistency

### Description

A small proportion of orders contain chronological inconsistencies between operational timestamps.

Affected rules include:

- Delivered Carrier earlier than Approved
- Delivered Customer earlier than Carrier

### Business Impact

The investigation showed minimal impact on completed customer transactions.

Most affected orders remained successfully delivered.

### Resolution

Retain original timestamps and introduce a timeline anomaly flag.

**Decision Reference**

D002 — Order Timeline Anomaly Handling Strategy

---

## Finding 3A — Payment Value Anomaly (Explained)

### Description

9 payment records contain payment_value = 0. Order-level consistency check confirmed
these represent valid business scenarios (voucher payments and cancelled orders).

### Business Impact

No impact. Orders remain financially consistent at the order level.

### Resolution

Retain records without flag. No action required.

---

## Finding 3B — Payment Installments Anomaly (Unexplained)

### Description

2 payment records contain payment_installments = 0 while maintaining positive payment_value.
Pattern analysis showed this does not represent a systematic characteristic of sequential
payments.

### Business Impact

Minimal (2 records only). However, root cause remains unidentified.

### Resolution

Retain records with derived flag (`has_installments_anomaly`) for transparency.

---

# 5. Data Quality Risk Assessment

| Finding                      | Likelihood | Business Impact | Risk Level |
| ---------------------------- | ---------- | --------------- | ---------- |
| Customer Identifier Misuse   | Medium     | High            | High       |
| Timeline Anomalies           | Low        | Medium          | Low        |
| Payment Value Anomaly        | Very Low   | Very Low        | Very Low   |
| Payment Installments Anomaly | Very Low   | Very Low        | Very Low   |

---

# 6. Data Quality Summary

| Category               | Result                   |
| ---------------------- | ------------------------ |
| Missing Values         | Acceptable               |
| Duplicate Records      | No significant issues    |
| Data Types             | Consistent               |
| Relationship Integrity | Passed                   |
| Customer Identity      | Documented               |
| Timeline Consistency   | Minor anomaly documented |
| Payment Validation     | Minor anomaly documented |

Overall data quality is considered suitable for analytical development.

---

# 7. Approved Handling Strategies

| Finding                      | Strategy                      | Reference |
| ---------------------------- | ----------------------------- | --------- |
| Customer Identifier          | Business identifier selection | D001      |
| Timeline Anomaly             | Keep + Flag                   | D002      |
| Payment Value Anomaly        | Retain, No Flag               | D003      |
| Payment Installments Anomaly | Retain + Flag                 | D003      |

---

# 8. Recommendations

The following recommendations will be adopted in subsequent project phases.

- Preserve all original source data.
- Perform anomaly handling during data preparation rather than modifying raw datasets.
- Document all business assumptions through Architecture Decision Records.
- Introduce derived anomaly indicators within the analytical layer.
- Continue validating business entities at the order level before drawing conclusions from individual transactional records.

---

# 9. Conclusion

The data quality assessment identified only a small number of localized issues within the Olist dataset.

None of the identified findings prevent the dataset from supporting the objectives of the InsightFlow project.

All significant issues have been investigated, documented, and assigned explicit handling strategies through D001–D003.

The dataset is therefore considered suitable for database implementation, ETL development, SQL analytics, dashboard construction, feature engineering, and machine learning.

---

# 10. References

## Investigation Notebooks

- 00_data_profiling.ipynb
- 01_dataset_assessment.ipynb

## Architecture Decision Records

- D001 — Customer Identity Strategy
- D002 — Order Timeline Anomaly Handling Strategy
- D003 — Payment Record Anomaly Handling Strategy

## Related Documents

- Dataset Assessment Report
- Business Requirements
- Dataset Strategy
