# Data Dictionary

| Metadata     | Value                            |
| ------------ | -------------------------------- |
| Project      | InsightFlow                      |
| Phase        | Dataset Acquisition & Assessment |
| Version      | 1.0                              |
| Status       | Completed                        |
| Last Updated | 2026-08-12                       |

---

# 1. Purpose

This document describes the business meaning of the primary attributes used throughout the InsightFlow project.

Rather than documenting every column available in the original Olist dataset, this dictionary focuses on attributes that are actively used during database design, SQL analytics, dashboard development, feature engineering, and machine learning.

---

# 2. Dataset Summary

| Dataset              | Description                                    |
| -------------------- | ---------------------------------------------- |
| Customers            | Customer demographic and location information  |
| Orders               | Customer order lifecycle                       |
| Order Items          | Individual products purchased in each order    |
| Payments             | Payment transactions associated with orders    |
| Reviews              | Customer satisfaction ratings                  |
| Products             | Product catalog information                    |
| Sellers              | Seller information                             |
| Geolocation          | Geographic reference data                      |
| Category Translation | Portuguese-to-English product category mapping |

---

# 3. Customers Dataset

## Business Entity

Customer

| Column                   | Data Type | Description                           | Business Usage            |
| ------------------------ | --------- | ------------------------------------- | ------------------------- |
| customer_id              | String    | Transaction-level customer identifier | Join with Orders          |
| customer_unique_id       | String    | Business customer identifier          | Customer analytics (D001) |
| customer_zip_code_prefix | Integer   | Customer ZIP prefix                   | Geographic analysis       |
| customer_city            | String    | Customer city                         | Regional analysis         |
| customer_state           | String    | Customer state                        | Regional analysis         |

---

# 4. Orders Dataset

## Business Entity

Customer Order

| Column                        | Data Type | Description                  | Business Usage       |
| ----------------------------- | --------- | ---------------------------- | -------------------- |
| order_id                      | String    | Unique order identifier      | Primary business key |
| customer_id                   | String    | Customer reference           | Join with Customers  |
| order_status                  | String    | Current order status         | Operational analysis |
| order_purchase_timestamp      | Timestamp | Purchase datetime            | Time-series analysis |
| order_approved_at             | Timestamp | Payment approval datetime    | Timeline analysis    |
| order_delivered_carrier_date  | Timestamp | Carrier pickup datetime      | Logistics analysis   |
| order_delivered_customer_date | Timestamp | Delivery completion datetime | Delivery KPI         |
| order_estimated_delivery_date | Timestamp | Estimated delivery           | SLA comparison       |

---

# 5. Order Items Dataset

## Business Entity

Purchased Item

| Column              | Data Type | Description                | Business Usage      |
| ------------------- | --------- | -------------------------- | ------------------- |
| order_id            | String    | Related order              | Join                |
| order_item_id       | Integer   | Item sequence within order | Order detail        |
| product_id          | String    | Purchased product          | Product analysis    |
| seller_id           | String    | Seller identifier          | Seller analysis     |
| shipping_limit_date | Timestamp | Shipping deadline          | Logistics           |
| price               | Decimal   | Product price              | Revenue calculation |
| freight_value       | Decimal   | Shipping fee               | Total order value   |

---

# 6. Payments Dataset

## Business Entity

Payment Record

| Column               | Data Type | Description       | Business Usage         |
| -------------------- | --------- | ----------------- | ---------------------- |
| order_id             | String    | Related order     | Join                   |
| payment_sequential   | Integer   | Payment sequence  | Multi-payment analysis |
| payment_type         | String    | Payment method    | Payment analysis       |
| payment_installments | Integer   | Installment count | Payment behaviour      |
| payment_value        | Decimal   | Payment amount    | Revenue analysis       |

---

# 7. Reviews Dataset

## Business Entity

Customer Review

| Column                  | Data Type | Description       | Business Usage        |
| ----------------------- | --------- | ----------------- | --------------------- |
| review_id               | String    | Review identifier | Review reference      |
| order_id                | String    | Related order     | Join                  |
| review_score            | Integer   | Rating (1–5)      | Customer satisfaction |
| review_creation_date    | Timestamp | Review creation   | Time analysis         |
| review_answer_timestamp | Timestamp | Review response   | Service quality       |

---

# 8. Products Dataset

## Business Entity

Product

| Column                | Data Type | Description        | Business Usage    |
| --------------------- | --------- | ------------------ | ----------------- |
| product_id            | String    | Product identifier | Join              |
| product_category_name | String    | Category           | Category analysis |
| product_weight_g      | Decimal   | Product weight     | Logistics         |
| product_length_cm     | Decimal   | Product length     | Shipping          |
| product_height_cm     | Decimal   | Product height     | Shipping          |
| product_width_cm      | Decimal   | Product width      | Shipping          |

---

# 9. Sellers Dataset

## Business Entity

Seller

| Column                 | Data Type | Description       | Business Usage      |
| ---------------------- | --------- | ----------------- | ------------------- |
| seller_id              | String    | Seller identifier | Join                |
| seller_zip_code_prefix | Integer   | Seller ZIP prefix | Geographic analysis |
| seller_city            | String    | Seller city       | Regional analysis   |
| seller_state           | String    | Seller state      | Regional analysis   |

---

# 10. Geolocation Dataset

## Business Entity

Geographic Reference

| Column                      | Data Type | Description | Business Usage      |
| --------------------------- | --------- | ----------- | ------------------- |
| geolocation_zip_code_prefix | Integer   | ZIP prefix  | Geographic mapping  |
| geolocation_city            | String    | City        | Geographic analysis |
| geolocation_state           | String    | State       | Geographic analysis |

---

# 11. Category Translation Dataset

## Business Entity

Category Reference

| Column                        | Data Type | Description                  | Business Usage          |
| ----------------------------- | --------- | ---------------------------- | ----------------------- |
| product_category_name         | String    | Original Portuguese category | Join                    |
| product_category_name_english | String    | English category             | Dashboard and reporting |

---

# 12. Business Keys

The following business keys are adopted throughout the InsightFlow project.

| Business Entity | Business Key                   |
| --------------- | ------------------------------ |
| Customer        | customer_unique_id             |
| Order           | order_id                       |
| Product         | product_id                     |
| Seller          | seller_id                      |
| Payment         | (order_id, payment_sequential) |
| Review          | review_id                      |

Customer-level analytics use **customer_unique_id** according to **D001 – Customer Identity Strategy**.

---

# 13. Data Quality Notes

| Dataset   | Note                                                                     | Reference |
| --------- | ------------------------------------------------------------------------ | --------- |
| Customers | Customer identity documented                                             | D001      |
| Orders    | Timeline anomalies documented                                            | D002      |
| Payments  | Payment value anomalies (explained) and installments anomalies (flagged) | D003      |

---

# 14. References

## Related Documents

- Dataset Assessment Report
- Data Quality Report

## Decision Logs

- D001 — Customer Identity Strategy
- D002 — Order Timeline Anomaly Handling Strategy
- D003 — Payment Record Anomaly Handling Strategy
