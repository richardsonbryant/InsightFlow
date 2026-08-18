# InsightFlow — Physical Database Design

| Metadata          | Value                                                                                               |
| ----------------- | --------------------------------------------------------------------------------------------------- |
| Date              | 2026-08-13                                                                                          |
| Phase             | Database Design                                                                                     |
| Related Documents | 01_business_entities.md, 02_key_strategy.md, 03_relationship_design.md, 04_erd.md, D001, D002, D003 |

---

## 1. Purpose

This document defines the physical database design for **InsightFlow**.

The purpose of this document is to translate the approved conceptual database model, key strategy, relationship design, and ERD into a concrete PostgreSQL implementation.

The design covers:

- database schemas;
- table structures;
- column definitions;
- PostgreSQL data types;
- primary keys;
- foreign keys;
- unique constraints;
- indexes;
- anomaly flags;
- Raw Layer implementation;
- Analytics Layer implementation.

This document focuses on **physical implementation**.

Business entities, key rationale, relationship cardinality, and conceptual modeling are documented separately in:

- `01_business_entities.md`
- `02_key_strategy.md`
- `03_relationship_design.md`
- `04_erd.md`

---

## 2. Database Technology

InsightFlow uses:

```text
Database Management System : PostgreSQL
```

PostgreSQL is selected because it provides:

- strong relational integrity;
- primary and foreign key constraints;
- composite keys;
- indexing;
- analytical SQL capabilities;
- support for large transactional datasets;
- compatibility with Python-based ETL;
- compatibility with Power BI;
- reproducible local development.

The database is designed as a relational PostgreSQL database rather than a document-oriented or NoSQL system.

---

## 3. Database Architecture

InsightFlow uses a two-layer database architecture:

```text
                    Olist CSV Dataset
                           │
                           ▼
                  ┌─────────────────┐
                  │    RAW LAYER    │
                  │   raw schema    │
                  │                 │
                  │ Source Fidelity │
                  └────────┬────────┘
                           │
                           │ ETL
                           ▼
                  ┌─────────────────┐
                  │ ANALYTICS LAYER │
                  │ analytics schema│
                  │                 │
                  │ Business Model  │
                  └────────┬────────┘
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
          SQL Analytics   Power BI       ML
```

The architecture separates:

1. **source preservation**, and
2. **business-oriented analytical modeling**.

The Raw Layer preserves the original Olist source structure.

The Analytics Layer contains the business-oriented entities used by downstream analytics.

---

## 4. Schema Design

Two PostgreSQL schemas are created:

```sql
CREATE SCHEMA IF NOT EXISTS raw;

CREATE SCHEMA IF NOT EXISTS analytics;
```

### 4.1 Raw Schema

The `raw` schema contains source-level tables.

The following datasets are retained:

| Table                    | Purpose                      |
| ------------------------ | ---------------------------- |
| raw.customers            | Original customer records    |
| raw.orders               | Original order records       |
| raw.order_items          | Original order-item records  |
| raw.payments             | Original payment records     |
| raw.products             | Original product records     |
| raw.sellers              | Original seller records      |
| raw.reviews              | Original review records      |
| raw.geolocation          | Geographic reference data    |
| raw.category_translation | Product category translation |

The Raw Layer is designed primarily for:

- source traceability;
- reproducibility;
- data-quality investigation;
- ETL input;
- preservation of source identifiers.

No business-level transformations are required in this layer.

---

## 5. Raw Layer Physical Design

### 5.1 `raw.customers`

#### Grain

One row represents one source customer record identified by `customer_id`.

#### Primary Key

```text
customer_id
```

#### Structure

```sql
CREATE TABLE raw.customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);
```

#### Notes

`customer_id` is the Raw Layer primary key.

`customer_unique_id` is retained as the business customer identifier.

The distinction follows **D001 — Customer Identity Strategy**.

The Raw Layer does not consolidate multiple `customer_id` records belonging to the same `customer_unique_id`.

---

### 5.2 `raw.orders`

#### Grain

One row represents one order.

#### Primary Key

```text
order_id
```

#### Structure

```sql
CREATE TABLE raw.orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(30),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);
```

#### Logical Relationship

```text
customer_id → raw.customers.customer_id
```

This relationship is not enforced as a database constraint in the Raw Layer.
Referential integrity is validated during ETL.
See **Section 9.1** for the Raw Layer foreign key strategy.

---

### 5.3 `raw.order_items`

#### Grain

One row represents one purchased item within an order.

#### Primary Key

```text
(order_id, order_item_id)
```

#### Structure

```sql
CREATE TABLE raw.order_items (
    order_id VARCHAR(50) NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    seller_id VARCHAR(50) NOT NULL,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12,2),
    freight_value NUMERIC(12,2),

    PRIMARY KEY (order_id, order_item_id)
);
```

#### Logical Relationships

```text
order_id   → raw.orders.order_id
product_id → raw.products.product_id
seller_id  → raw.sellers.seller_id
```

These relationships are not enforced as database constraints in the Raw Layer.
Referential integrity is validated during ETL.
See **Section 9.1** for the Raw Layer foreign key strategy.

---

### 5.4 `raw.payments`

#### Grain

One row represents one payment record.

#### Primary Key

```text
(order_id, payment_sequential)
```

#### Structure

```sql
CREATE TABLE raw.payments (
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INTEGER NOT NULL,
    payment_type VARCHAR(30),
    payment_installments INTEGER,
    payment_value NUMERIC(12,2),

    PRIMARY KEY (order_id, payment_sequential)
);
```

#### Logical Relationship

```text
order_id → raw.orders.order_id
```

This relationship is not enforced as a database constraint in the Raw Layer.
Referential integrity is validated during ETL.
See **Section 9.1** for the Raw Layer foreign key strategy.

---

### 5.5 `raw.products`

#### Grain

One row represents one product.

#### Primary Key

```text
product_id
```

#### Structure

```sql
CREATE TABLE raw.products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g NUMERIC(12,3),
    product_length_cm NUMERIC(12,2),
    product_height_cm NUMERIC(12,2),
    product_width_cm NUMERIC(12,2)
);
```

The original category value is preserved in the Raw Layer.

---

### 5.6 `raw.sellers`

#### Grain

One row represents one seller.

#### Primary Key

```text
seller_id
```

#### Structure

```sql
CREATE TABLE raw.sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);
```

---

### 5.7 `raw.reviews`

#### Grain

One row represents one review record associated with an order.

#### Primary Key

```text
(review_id, order_id)
```

#### Structure

```sql
CREATE TABLE raw.reviews (
    review_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,

    PRIMARY KEY (review_id, order_id)
);
```

#### Logical Relationship

```text
order_id → raw.orders.order_id
```

This relationship is not enforced as a database constraint in the Raw Layer.
Referential integrity is validated during ETL.
See **Section 9.1** for the Raw Layer foreign key strategy.

#### Review ID Duplication

Investigation identified 789 `review_id` values appearing across multiple `order_id` values.

The affected records consistently belong to the same business customer and contain identical review information for the duplicated `review_id`.

This pattern is treated as a known platform characteristic rather than a key failure.

The composite key:

```text
(review_id, order_id)
```

remains valid because it produces zero duplicate records and correctly represents the Raw Layer grain.

Downstream analysis should be aware that some repeated review scores may represent system-generated review assignments rather than independent customer submissions.

---

### 5.8 `raw.geolocation`

#### Grain

One row represents one geographic reference record.

The geolocation dataset contains substantial full-row duplication and does not provide a reliable single-column natural primary key.

Therefore:

```text
Primary Key: None
```

The table remains Raw-only.

A surrogate key is intentionally not introduced because the dataset is not promoted into the Analytics Layer for the MVP.

#### Structure

```sql
CREATE TABLE raw.geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat NUMERIC(12,8),
    geolocation_lng NUMERIC(12,8),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);
```

---

### 5.9 `raw.category_translation`

#### Grain

One row represents one product-category translation mapping.

The table is retained for source traceability but is not promoted as an independent Analytics entity.

#### Structure

```sql
CREATE TABLE raw.category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);
```

The translated category is incorporated into `analytics.dim_product` during ETL.

---

## 6. Analytics Layer Physical Design

The Analytics Layer contains seven analytical tables:

### Dimensions

```text
analytics.dim_customer
analytics.dim_product
analytics.dim_seller
```

### Facts

```text
analytics.fact_orders
analytics.fact_order_items
analytics.fact_payments
analytics.fact_reviews
```

The design maintains a normalized relational structure while adopting dimensional naming and classification for analytical clarity.

---

## 7. Dimension Tables

### 7.1 `analytics.dim_customer`

#### Grain

One row represents one unique business customer.

#### Primary Key

```text
customer_unique_id
```

#### Structure

```sql
CREATE TABLE analytics.dim_customer (
    customer_unique_id VARCHAR(50) PRIMARY KEY,
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);
```

#### Business Identity

The Analytics Layer consolidates source customer records according to:

```text
D001 — Customer Identity Strategy
```

Therefore:

```text
Raw:
customer_id = source record identity

Analytics:
customer_unique_id = business customer identity
```

This allows customer-level analytics such as:

- repeat purchase rate;
- RFM;
- retention;
- churn;
- customer value.

---

### 7.2 `analytics.dim_product`

#### Grain

One row represents one product.

#### Primary Key

```text
product_id
```

#### Structure

```sql
CREATE TABLE analytics.dim_product (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g NUMERIC(12,3),
    product_length_cm NUMERIC(12,2),
    product_height_cm NUMERIC(12,2),
    product_width_cm NUMERIC(12,2)
);
```

#### ETL Transformation

`product_category_name_english` is derived from:

```text
raw.category_translation
```

The translation table is therefore merged into the product dimension during ETL.

---

### 7.3 `analytics.dim_seller`

#### Grain

One row represents one seller.

#### Primary Key

```text
seller_id
```

#### Structure

```sql
CREATE TABLE analytics.dim_seller (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);
```

---

## 8. Fact Tables

### 8.1 `analytics.fact_orders`

#### Grain

One row represents one order.

#### Primary Key

```text
order_id
```

#### Structure

```sql
CREATE TABLE analytics.fact_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(30),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,

    has_timeline_anomaly BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT fk_fact_orders_customer
        FOREIGN KEY (customer_unique_id)
        REFERENCES analytics.dim_customer(customer_unique_id)
);
```

#### D002 Integration

The following derived attribute is implemented:

```text
has_timeline_anomaly
```

The flag identifies orders affected by the approved order timeline strategy documented in:

```text
D002 — Order Timeline Strategy
```

The original timestamp values are preserved.

---

### 8.2 `analytics.fact_order_items`

#### Grain

One row represents one purchased item.

#### Primary Key

```text
(order_id, order_item_id)
```

#### Structure

```sql
CREATE TABLE analytics.fact_order_items (
    order_id VARCHAR(50) NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    seller_id VARCHAR(50) NOT NULL,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12,2),
    freight_value NUMERIC(12,2),

    PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT fk_fact_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES analytics.fact_orders(order_id),

    CONSTRAINT fk_fact_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES analytics.dim_product(product_id),

    CONSTRAINT fk_fact_order_items_seller
        FOREIGN KEY (seller_id)
        REFERENCES analytics.dim_seller(seller_id)
);
```

---

### 8.3 `analytics.fact_payments`

#### Grain

One row represents one payment record.

#### Primary Key

```text
(order_id, payment_sequential)
```

#### Structure

```sql
CREATE TABLE analytics.fact_payments (
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INTEGER NOT NULL,
    payment_type VARCHAR(30),
    payment_installments INTEGER,
    payment_value NUMERIC(12,2),

    has_installments_anomaly BOOLEAN NOT NULL DEFAULT FALSE,

    PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT fk_fact_payments_order
        FOREIGN KEY (order_id)
        REFERENCES analytics.fact_orders(order_id)
);
```

#### D003 Integration

The following derived attribute is implemented:

```text
has_installments_anomaly
```

The flag identifies payment records affected by the approved payment strategy documented in:

```text
D003 — Payment Record Strategy
```

The original payment values remain unchanged.

---

### 8.4 `analytics.fact_reviews`

#### Grain

One row represents one review record associated with an order.

#### Primary Key

```text
(review_id, order_id)
```

#### Structure

```sql
CREATE TABLE analytics.fact_reviews (
    review_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,

    PRIMARY KEY (review_id, order_id),

    CONSTRAINT fk_fact_reviews_order
        FOREIGN KEY (order_id)
        REFERENCES analytics.fact_orders(order_id)
);
```

The composite key is retained in the Analytics Layer because it matches the approved review grain.

---

## 9. Foreign Key Design

### 9.1 Raw Layer Foreign Keys

The Raw Layer does not enforce foreign key constraints at the database level.

Referential integrity in the Raw Layer is validated during ETL rather than
enforced by database constraints. This approach allows flexible CSV loading
without strict dependency ordering and preserves the Raw Layer as a
faithful representation of the source dataset.

The following logical relationships exist but are not enforced as database
constraints:

| Child Table     | FK Column   | Parent Table  | PK Column   |
| --------------- | ----------- | ------------- | ----------- |
| raw.orders      | customer_id | raw.customers | customer_id |
| raw.order_items | order_id    | raw.orders    | order_id    |
| raw.order_items | product_id  | raw.products  | product_id  |
| raw.order_items | seller_id   | raw.sellers   | seller_id   |
| raw.payments    | order_id    | raw.orders    | order_id    |
| raw.reviews     | order_id    | raw.orders    | order_id    |

Referential integrity was validated during Phase 1 assessment and confirmed
zero orphan records across all relationships. Results are documented in
`03_relationship_design.md`.

---

### 9.2 Analytics Layer Foreign Keys

| Child Table      | FK Column          | Parent Table | PK Column          |
| ---------------- | ------------------ | ------------ | ------------------ |
| fact_orders      | customer_unique_id | dim_customer | customer_unique_id |
| fact_order_items | order_id           | fact_orders  | order_id           |
| fact_order_items | product_id         | dim_product  | product_id         |
| fact_order_items | seller_id          | dim_seller   | seller_id          |
| fact_payments    | order_id           | fact_orders  | order_id           |
| fact_reviews     | order_id           | fact_orders  | order_id           |

Relationship cardinality and optionality are documented separately in:

```text
03_relationship_design.md
```

---

## 10. Index Strategy

Primary keys automatically create indexes in PostgreSQL.

Additional indexes are created on frequently used foreign keys and analytical filtering columns.

### 10.1 Raw Layer Indexes

```sql
CREATE INDEX idx_raw_orders_customer_id
ON raw.orders(customer_id);

CREATE INDEX idx_raw_order_items_product_id
ON raw.order_items(product_id);

CREATE INDEX idx_raw_order_items_seller_id
ON raw.order_items(seller_id);

CREATE INDEX idx_raw_payments_order_id
ON raw.payments(order_id);

CREATE INDEX idx_raw_reviews_order_id
ON raw.reviews(order_id);
```

---

### 10.2 Analytics Layer Indexes

```sql
CREATE INDEX idx_fact_orders_customer
ON analytics.fact_orders(customer_unique_id);

CREATE INDEX idx_fact_orders_purchase_timestamp
ON analytics.fact_orders(order_purchase_timestamp);

CREATE INDEX idx_fact_order_items_product
ON analytics.fact_order_items(product_id);

CREATE INDEX idx_fact_order_items_seller
ON analytics.fact_order_items(seller_id);

CREATE INDEX idx_fact_payments_order
ON analytics.fact_payments(order_id);

CREATE INDEX idx_fact_reviews_order
ON analytics.fact_reviews(order_id);
```

These indexes support common analytical operations such as:

- customer transaction history;
- monthly revenue analysis;
- product performance;
- seller performance;
- payment aggregation;
- customer review analysis.

Indexes should be added incrementally based on actual query performance rather than indexing every column by default.

---

## 11. Data Type Strategy

The following PostgreSQL data type conventions are adopted.

| Data Type       | Usage                                  |
| --------------- | -------------------------------------- |
| `VARCHAR`       | Identifiers and short categorical text |
| `CHAR(2)`       | Brazilian state codes                  |
| `INTEGER`       | Counts, sequence numbers, quantities   |
| `NUMERIC(12,2)` | Monetary values                        |
| `NUMERIC(12,3)` | Physical measurements                  |
| `NUMERIC(12,8)` | Geographic coordinates                 |
| `TIMESTAMP`     | Date-time fields                       |
| `BOOLEAN`       | Derived anomaly flags                  |
| `TEXT`          | Long review comments                   |

Monetary fields use `NUMERIC` rather than floating-point types to avoid unnecessary precision issues in financial calculations.

---

## 12. Constraint Strategy

The physical database uses PostgreSQL constraints to enforce structural integrity.

### Primary Keys

Primary keys are defined for all analytical entities that have validated identifiers.

Examples:

```text
dim_customer
    PK = customer_unique_id

dim_product
    PK = product_id

dim_seller
    PK = seller_id

fact_orders
    PK = order_id
```

Composite keys are used where required by table grain:

```text
fact_order_items
    PK = (order_id, order_item_id)

fact_payments
    PK = (order_id, payment_sequential)

fact_reviews
    PK = (review_id, order_id)
```

### Foreign Keys

Foreign keys enforce relationships between analytical entities.

The database therefore prevents analytical records from referencing nonexistent parent entities.

---

## 13. ETL Loading Order

The Analytics Layer should be populated according to dependency order.

Recommended loading sequence:

```text
1. dim_customer
2. dim_product
3. dim_seller
4. fact_orders
5. fact_order_items
6. fact_payments
7. fact_reviews
```

This order ensures that parent dimensions and fact tables exist before dependent foreign keys are populated.

---

## 14. Raw-to-Analytics Transformation

The ETL process follows this general structure:

```text
RAW CSV
   │
   ▼
raw schema
   │
   │ validation
   │ transformation
   │ identity consolidation
   │ anomaly flag derivation
   ▼
analytics schema
```

Key transformations include:

### Customer

```text
raw.customer_id
        │
        ▼
customer identity resolution
        │
        ▼
analytics.customer_unique_id
```

### Product Category

```text
raw.products
       +
raw.category_translation
       │
       ▼
analytics.dim_product
```

### Order Timeline

```text
raw.orders
    │
    ▼
D002 validation
    │
    ▼
has_timeline_anomaly
```

### Payment

```text
raw.payments
    │
    ▼
D003 validation
    │
    ▼
has_installments_anomaly
```

---

## 15. Analytical Usage

The Analytics Layer is designed to support the downstream InsightFlow MVP.

### SQL Analytics

Examples include:

- revenue trend;
- total orders;
- average order value;
- customer purchase frequency;
- repeat purchase rate;
- RFM metrics;
- customer retention;
- churn population;
- product category performance.

### Dashboard

The Analytics Layer provides the primary data source for:

```text
Executive Dashboard
Customer Dashboard
```

### Machine Learning

Customer-level analytical features can be generated from:

```text
dim_customer
        +
fact_orders
        +
fact_order_items
        +
fact_payments
        +
fact_reviews
```

The database therefore serves as the structured foundation for later feature engineering and churn prediction.

---

## 16. Data Quality and Integrity Considerations

The physical design intentionally preserves known data characteristics rather than silently modifying the source data.

### Customer Identity

Multiple Raw customer records may map to the same business customer.

This is handled through:

```text
customer_unique_id
```

in the Analytics Layer.

### Order Timeline

Known order timeline anomalies are retained and represented through:

```text
has_timeline_anomaly
```

### Payment Installments

Known payment anomalies are retained and represented through:

```text
has_installments_anomaly
```

### Review Duplication

Repeated `review_id` values across orders are retained because the approved composite key correctly represents the physical grain.

No records are deleted solely because they participate in these known patterns.

---

## 17. Naming Conventions

The following naming conventions are used.

### Schemas

```text
raw
analytics
```

### Tables

Tables use:

```text
snake_case
```

Dimensions use:

```text
dim_<entity>
```

Facts use:

```text
fact_<business_event>
```

### Columns

Columns use:

```text
snake_case
```

Examples:

```text
customer_unique_id
order_purchase_timestamp
payment_installments
has_timeline_anomaly
```

Primary and foreign key columns retain the same name across parent-child relationships whenever possible.

---

## 18. Physical Design Summary

| Layer     | Table                | Grain                  | Primary Key                    |
| --------- | -------------------- | ---------------------- | ------------------------------ |
| Raw       | customers            | Source customer record | customer_id                    |
| Raw       | orders               | Order                  | order_id                       |
| Raw       | order_items          | Purchased item         | (order_id, order_item_id)      |
| Raw       | payments             | Payment record         | (order_id, payment_sequential) |
| Raw       | products             | Product                | product_id                     |
| Raw       | sellers              | Seller                 | seller_id                      |
| Raw       | reviews              | Review record          | (review_id, order_id)          |
| Raw       | geolocation          | Geographic reference   | None                           |
| Raw       | category_translation | Translation mapping    | None                           |
| Analytics | dim_customer         | Business customer      | customer_unique_id             |
| Analytics | dim_product          | Product                | product_id                     |
| Analytics | dim_seller           | Seller                 | seller_id                      |
| Analytics | fact_orders          | Order                  | order_id                       |
| Analytics | fact_order_items     | Purchased item         | (order_id, order_item_id)      |
| Analytics | fact_payments        | Payment record         | (order_id, payment_sequential) |
| Analytics | fact_reviews         | Review record          | (review_id, order_id)          |

---

## 19. Final Database Architecture

The final physical architecture is:

```text
┌──────────────────────────────────────────────────────────────┐
│                         RAW SCHEMA                           │
├──────────────────────────────────────────────────────────────┤
│ customers                                                    │
│ orders                                                       │
│ order_items                                                  │
│ payments                                                     │
│ products                                                     │
│ sellers                                                      │
│ reviews                                                      │
│ geolocation                                                  │
│ category_translation                                         │
└──────────────────────────────┬───────────────────────────────┘
                               │
                               │ ETL
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                      ANALYTICS SCHEMA                        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  DIMENSIONS                                                  │
│  ├── dim_customer                                            │
│  ├── dim_product                                             │
│  └── dim_seller                                              │
│                                                              │
│  FACTS                                                       │
│  ├── fact_orders                                             │
│  ├── fact_order_items                                        │
│  ├── fact_payments                                           │
│  └── fact_reviews                                            │
│                                                              │
└──────────────────────────────┬───────────────────────────────┘
                               │
                ┌──────────────┼──────────────┐
                ▼              ▼              ▼
          SQL Analytics    Power BI       ML Features
```

The database therefore provides a clear separation between source preservation and business-oriented analytics while maintaining explicit grain, validated keys, referential integrity, and reproducible transformations.

---

## 20. Conclusion

The InsightFlow physical database design translates the approved business entity model and relationship strategy into PostgreSQL implementation.

The design preserves the original Olist data in the Raw Layer while providing a business-oriented Analytics Layer for SQL analytics, dashboards, segmentation, churn modeling, and future analytical extensions.

The final MVP database consists of:

- **9 Raw tables**
- **7 Analytics tables**
- **3 dimension tables**
- **4 fact tables**
- explicit primary keys;
- composite keys where required;
- foreign key relationships;
- analytical indexes;
- anomaly flags for D002 and D003;
- customer identity consolidation based on D001.

This structure is the physical foundation for the next implementation stage: ETL loading, SQL analytics, and downstream InsightFlow analytical workflows.
