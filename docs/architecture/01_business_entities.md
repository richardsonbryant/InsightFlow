# Business Entities

| Metadata          | Value                                |
| ----------------- | ------------------------------------ |
| Date              | 2026-08-13                           |
| Phase             | Database Design                      |
| Related Documents | D001, D002, D003, Dataset Assessment |

---

# 1. Purpose

This document defines the business entities that form the foundation of the InsightFlow analytical database.

Rather than directly transforming every source dataset into database tables, the objective of this document is to identify the real business objects represented by the Olist dataset and determine how they should be modeled within the database architecture.

The identified entities serve as the basis for subsequent database design activities, including key strategy, relationship modeling, entity-relationship diagrams (ERD), and PostgreSQL implementation.

---

# 2. Business Context

InsightFlow is designed as an end-to-end customer analytics platform built on the Olist Brazilian E-Commerce Dataset.

The project focuses on transforming raw transactional data into reliable analytical assets capable of supporting customer analytics, sales analysis, logistics monitoring, dashboard reporting, and machine learning.

Instead of modelling datasets as independent CSV files, the database is designed around the underlying business processes occurring within an e-commerce platform.

---

# 3. Business Process Overview

The primary business process represented within the dataset is illustrated below.

```text
Customer
     │
Places Order
     ▼
Order
     │
Contains
     ▼
Order Item
     │
Purchased From
     ▼
Seller
     │
Product
     ▼
Payment
     ▼
Delivery
     ▼
Review
```

Each business entity exists because it represents an important object participating in this lifecycle.

Consequently, the database design follows the business process rather than the physical organization of the original CSV files.

---

# 4. Database Architecture

InsightFlow adopts a two-layer database architecture consisting of a Raw Layer and an Analytics Layer.

```text
                Source CSV
                     │
                     ▼
              RAW LAYER (3NF)
      Preserve Original Source Data
                     │
                ETL Process
                     │
                     ▼
          ANALYTICS LAYER (3NF)
       Business-Oriented Database
```

The two-layer architecture separates data preservation from analytical modeling.

This approach improves reproducibility while allowing business-oriented transformations without modifying the original source data.

---

# 5. Layer Responsibilities

## 5.1 Raw Layer

The Raw Layer preserves the original Olist datasets without structural modification.

Its primary responsibilities include:

- preserving the original source system;
- maintaining referential integrity with the source data;
- providing reproducible datasets for future processing;
- serving as the input layer for ETL.

No business transformations are performed within this layer.

Examples include:

- raw.customers
- raw.orders
- raw.order_items
- raw.payments
- raw.products
- raw.sellers
- raw.reviews
- raw.geolocation
- raw.category_translation

---

## 5.2 Analytics Layer

The Analytics Layer contains business-oriented tables specifically designed for analytical workloads.

Unlike the Raw Layer, this layer may include:

- business identifiers;
- derived attributes;
- anomaly flags;
- standardized business entities.

The Analytics Layer serves as the primary data source for:

- SQL analytics;
- dashboard reporting;
- feature engineering;
- machine learning.

---

# 6. Business Entity Identification

The assessment identified seven core business entities and two supporting lookup entities.

## 6.1 Core Business Entities

| Entity     | Description                                  | Analytics Role |
| ---------- | -------------------------------------------- | -------------- |
| Customer   | Individual customer performing purchases     | Dimension      |
| Order      | Customer transaction                         | Fact           |
| Order Item | Individual purchased product within an order | Fact           |
| Payment    | Payment transaction associated with an order | Fact           |
| Product    | Product catalog                              | Dimension      |
| Seller     | Merchant information                         | Dimension      |
| Review     | Customer feedback after delivery             | Fact           |

These entities represent the primary business objects involved throughout the purchasing lifecycle.

---

## 6.2 Lookup Entities

| Entity               | Purpose                                |
| -------------------- | -------------------------------------- |
| Geolocation          | Geographic reference data              |
| Category Translation | Product category translation reference |

Lookup entities provide supporting information but do not represent independent business objects.

---

# 7. Raw to Analytics Mapping

Not every dataset from the Raw Layer is promoted into an independent analytical table.

| Raw Dataset          | Analytics Table  | Decision          | Rationale                                                                                                                        |
| -------------------- | ---------------- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Customers            | dim_customer     | Keep              | Core business entity                                                                                                             |
| Orders               | fact_orders      | Keep              | Core transaction                                                                                                                 |
| Order Items          | fact_order_items | Keep              | Transaction detail                                                                                                               |
| Payments             | fact_payments    | Keep              | Payment events                                                                                                                   |
| Reviews              | fact_reviews     | Keep              | Customer feedback event                                                                                                          |
| Products             | dim_product      | Keep              | Product dimension                                                                                                                |
| Sellers              | dim_seller       | Keep              | Seller dimension                                                                                                                 |
| Geolocation          | —                | Raw only          | Geographic reference already available in customer table (city, state); not required as separate analytical entity for MVP scope |
| Category Translation | —                | Merged during ETL | Translation values incorporated into product dimension to simplify downstream analytics                                          |

This mapping reflects the analytical requirements of InsightFlow rather than the physical organization of the source dataset.

---

# 8. Phase 1 Decision Integration

The Analytics Layer incorporates selected data-quality decisions established during Phase 1 as derived attributes on the corresponding business entities.

These attributes are not stored in the Raw Layer because the Raw Layer must preserve the original Olist dataset without modification.

| Decision                       | Source Entity | Analytics Table | Derived Attribute        | Grain                    |
| ------------------------------ | ------------- | --------------- | ------------------------ | ------------------------ |
| D002 — Order Timeline Strategy | Orders        | fact_orders     | has_timeline_anomaly     | 1 row = 1 order          |
| D003 — Payment Record Strategy | Payments      | fact_payments   | has_installments_anomaly | 1 row = 1 payment record |

The anomaly attributes are implemented as flags rather than separate anomaly tables because the current MVP only requires anomaly identification at the same grain as the affected business entity.

Detailed anomaly detection rules and the rationale for retaining these records are documented in **D002** and **D003**.

---

# 9. Fact and Dimension Classification

The Analytics Layer adopts a dimensional classification while maintaining a normalized (3NF) relational structure.

## Dimension Tables

Dimension tables describe relatively stable business entities.

| Dimension    | Business Purpose    |
| ------------ | ------------------- |
| dim_customer | Customer attributes |
| dim_product  | Product attributes  |
| dim_seller   | Seller attributes   |

---

## Fact Tables

Fact tables capture business events occurring throughout the purchasing lifecycle.

| Fact             | Business Event      |
| ---------------- | ------------------- |
| fact_orders      | Customer order      |
| fact_order_items | Purchased product   |
| fact_payments    | Payment transaction |
| fact_reviews     | Customer review     |

---

# 10. Grain Definition

A clear grain is defined for every table to ensure analytical consistency.

## Raw Layer

| Table                    | Grain                                                                                                                                                     |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| raw.customers            | One row represents one source customer record (customer_id). This structure is consistent with how the original Olist dataset organizes customer records. |
| raw.orders               | One row represents one order.                                                                                                                             |
| raw.order_items          | One row represents one purchased item.                                                                                                                    |
| raw.payments             | One row represents one payment record.                                                                                                                    |
| raw.products             | One row represents one product.                                                                                                                           |
| raw.sellers              | One row represents one seller.                                                                                                                            |
| raw.reviews              | One row represents one review.                                                                                                                            |
| raw.geolocation          | One row represents one geographic reference record.                                                                                                       |
| raw.category_translation | One row represents one category translation mapping.                                                                                                      |

---

## Analytics Layer

| Table            | Grain                                                                 |
| ---------------- | --------------------------------------------------------------------- |
| dim_customer     | One row represents one unique business customer (customer_unique_id). |
| dim_product      | One row represents one product.                                       |
| dim_seller       | One row represents one seller.                                        |
| fact_orders      | One row represents one order.                                         |
| fact_order_items | One row represents one purchased item.                                |
| fact_payments    | One row represents one payment record.                                |
| fact_reviews     | One row represents one review.                                        |

### Customer Grain Transformation

The difference in customer grain between the Raw and Analytics Layers is intentional and follows **D001 — Customer Identity Strategy**.

In the Raw Layer, `raw.customers` preserves the source structure, where one row represents one source customer record identified by `customer_id`. This structure is consistent with how the original Olist dataset organizes customer records. Because the same `customer_unique_id` may appear across multiple source records, this does not represent one unique business customer per row.

In the Analytics Layer, `dim_customer` consolidates these source records into one row per `customer_unique_id`. This establishes the business customer as the analytical grain required for customer-level metrics such as repeat purchase rate, RFM analysis, retention analysis, and churn prediction.

---

# 11. Design Principles

The following principles guide business entity modeling throughout the project.

- Model business processes rather than CSV files.
- Preserve all original source data within the Raw Layer.
- Separate operational identifiers from business identifiers.
- Define explicit grain for every analytical table.
- Promote only business-relevant entities into the Analytics Layer.
- Keep lookup entities within the Raw Layer unless analytical simplification provides clear value.
- Maintain compatibility with downstream SQL analytics, dashboard reporting, and machine learning.

---

# 12. Scope

This document defines only the business entities and their intended analytical roles.

The following topics are documented separately:

| Topic                                     | Document                  |
| ----------------------------------------- | ------------------------- |
| Primary Keys, Foreign Keys, Business Keys | 02_key_strategy.md        |
| Entity Relationships and Cardinality      | 03_relationship_design.md |
| Entity Relationship Diagram               | 04_erd.md                 |
| Physical Database Design                  | 05_database_design.md     |

---

# 13. Conclusion

The InsightFlow database is designed around the underlying business processes of an e-commerce platform rather than the physical structure of the original datasets.

Seven core business entities and two supporting lookup entities have been identified.

A hybrid Raw–Analytics architecture has been adopted to preserve source data while enabling business-oriented analytical modeling.

Decisions established during Phase 1 assessment are integrated as derived attributes on affected analytical entities.

This document establishes the conceptual foundation for the remaining database design activities, including key strategy, relationship modeling, ERD development, and PostgreSQL implementation.
