# Dataset Assessment Report

| Metadata     | Value                            |
| ------------ | -------------------------------- |
| Project      | InsightFlow                      |
| Phase        | Dataset Acquisition & Assessment |
| Version      | 1.0                              |
| Status       | Completed                        |
| Last Updated | 2026-08-12                       |

---

# 1. Purpose

This document summarizes the overall assessment of the Olist E-Commerce dataset before database design and analytical development.

The assessment evaluates dataset completeness, structural consistency, data quality, and business suitability to determine whether the dataset is ready for downstream processes including database implementation, SQL analytics, dashboard development, feature engineering, and machine learning.

Detailed investigations are documented separately within the project notebooks and Architecture Decision Records (ADR).

---

# 2. Assessment Scope

The assessment covers the following areas:

- Dataset structure and inventory
- Dataset relationships
- Data completeness
- Missing value assessment
- Duplicate assessment
- Timeline consistency
- Payment validation
- Business entity identification
- Overall dataset readiness

---

# 3. Dataset Overview

The InsightFlow project utilizes the public Olist Brazilian E-Commerce Dataset.

The assessment includes nine relational datasets representing different business entities throughout the customer purchasing lifecycle.

| Dataset              | Business Entity          |
| -------------------- | ------------------------ |
| Customers            | Customer information     |
| Orders               | Order lifecycle          |
| Order Items          | Purchased products       |
| Payments             | Payment transactions     |
| Reviews              | Customer feedback        |
| Products             | Product catalog          |
| Sellers              | Seller information       |
| Geolocation          | Geographic reference     |
| Category Translation | Product category mapping |

The dataset provides sufficient coverage for customer analytics, sales analytics, logistics analysis, and predictive modelling.

---

# 4. Dataset Relationship Assessment

The assessment confirmed that the datasets form a consistent relational structure centered around the Orders table.

Primary business relationships include:

Customers
→ Orders

Orders
→ Order Items

Orders
→ Payments

Orders
→ Reviews

Order Items
→ Products

Order Items
→ Sellers

Products
→ Category Translation

Geolocation serves as a lookup dataset supporting customer and seller location analysis.

The overall relational structure is considered appropriate for relational database implementation.

---

# 5. Initial Data Quality Summary

Initial profiling identified generally good data quality with only a small number of localized anomalies.

| Assessment Area       | Result                                             |
| --------------------- | -------------------------------------------------- |
| Missing Values        | Present only in expected business scenarios        |
| Duplicate Records     | No significant duplicate business records detected |
| Data Types            | Consistent after timestamp conversion              |
| Referential Structure | Consistent across datasets                         |
| Timeline Consistency  | Minor anomalies identified                         |
| Payment Validation    | Minor anomalies identified                         |

No evidence of widespread dataset corruption was observed.

---

# 6. Assessment Findings

## 6.1 Customer Identity

The Customers dataset contains two identifier columns:

- customer_id
- customer_unique_id

The assessment concluded that customer_unique_id represents the business customer identifier and should be used for customer-level analytics such as segmentation, repeat purchase analysis, churn prediction, and customer lifetime value.

**Decision Reference**

D001 — Customer Identity Strategy

---

## 6.2 Order Timeline Consistency

The Orders dataset contains a small number of chronological inconsistencies affecting approximately 1.39% of orders.

Investigation showed that:

- most affected orders were successfully delivered;
- business impact was limited;
- no objective evidence existed to determine which timestamps should be corrected.

The preferred strategy is therefore to preserve original timestamps while explicitly identifying anomalous records.

**Decision Reference**

D002 — Order Timeline Anomaly Handling Strategy

---

## 6.3 Payment Record Validation

The Payments dataset contains two distinct types of anomalies requiring different
handling strategies.

### 6.3.1 Payment Value Anomaly (9 records)

Investigation through order-level validation confirmed that the 9 payment records
with payment_value = 0 represent valid business scenarios:

- 6 records are voucher transactions where the zero value reflects split payment
  structure; order-level totals remain consistent with order values.
- 3 records are associated with cancelled orders with no order items; the zero
  value correctly represents orders with no completed transactions.

**Resolution:** Retain records without flag. No data modification required.

### 6.3.2 Payment Installments Anomaly (2 records)

Two payment records contain payment_installments = 0 despite having positive
payment_value. Pattern analysis of 4,526 records with sequential >= 2 showed
that 95% contain installments >= 1, indicating that zero installments in these
2 records represent genuinely unexplained edge cases rather than a systematic
pattern.

**Resolution:** Retain records with explicit anomaly flag for transparency.

**Decision Reference**

D003 — Payment Record Anomaly Handling Strategy

---

## 6.4 Relationship Validation Summary

Relationship validation was performed to support the database architecture
design in Phase 2.

The following relationships were validated against the source dataset:

| Relationship         | Cardinality | Key Finding                                                 |
| -------------------- | ----------- | ----------------------------------------------------------- |
| Customer → Order     | 1:1 (Raw)   | 99,441 customers, maximum 1 order per `customer_id`         |
| Order → Order Item   | 1:0..N      | 775 orders without items; maximum 21 items/order            |
| Order → Payment      | 1:0..N      | 1 order without payment; maximum 29 payments/order          |
| Order → Review       | 1:0..N      | 768 orders without review; 547 orders with multiple reviews |
| Product → Order Item | 1:N         | 0 orphan product references                                 |
| Seller → Order Item  | 1:N         | 0 orphan seller references                                  |

All tested child-to-parent relationships contained zero orphan records.

These findings were used as evidence for the relationship design documented
in `docs/architecture/03_relationship_design.md`.

# 7. Overall Assessment

The completed assessment indicates that the Olist dataset demonstrates a high level of structural integrity and is suitable for the objectives of the InsightFlow project.

Although several localized data quality issues were identified, all investigated anomalies were successfully documented and appropriate handling strategies were established through dedicated Architecture Decision Records.

No identified issue prevents the dataset from supporting:

- Customer Analytics
- Sales Analytics
- Supply Chain Analysis
- Dashboard Development
- Feature Engineering
- Machine Learning

---

# 8. Dataset Readiness

| Assessment Area       | Status                                |
| --------------------- | ------------------------------------- |
| Dataset Structure     | ✅ Ready                              |
| Business Mapping      | ✅ Ready                              |
| Data Relationships    | ✅ Ready                              |
| Data Quality          | ✅ Ready (Minor documented anomalies) |
| Database Design       | ✅ Ready                              |
| ETL Development       | ✅ Ready                              |
| SQL Analytics         | ✅ Ready                              |
| Dashboard Development | ✅ Ready                              |
| Machine Learning      | ✅ Ready                              |

**Overall Status**

✅ **The dataset is approved for Phase 2 – Database Design.**

---

# 9. References

## Project Documents

- Company Overview
- Product Vision
- Business Requirements
- Functional Requirements
- Non-Functional Requirements
- Dataset Strategy

## Investigation Notebooks

- 00_data_profiling.ipynb
- 01_dataset_assessment.ipynb

## Architecture Decision Records

- D001 — Customer Identity Strategy
- D002 — Order Timeline Anomaly Handling Strategy
- D003 — Payment Record Anomaly Handling Strategy
