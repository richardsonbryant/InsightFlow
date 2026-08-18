# Key Strategy

| Metadata          | Value                                                         |
| ----------------- | ------------------------------------------------------------- |
| Date              | 2026-08-13                                                    |
| Phase             | Database Design                                               |
| Related Documents | 01_business_entities.md, D001, D002, D003, Dataset Assessment |

---

# 1. Purpose

This document defines the key strategy for the InsightFlow database across the
Raw and Analytics Layers.

The purpose of the key strategy is to determine how each business entity is
uniquely identified, how source-system identifiers are preserved, and how
business identifiers are used for analytical modeling.

The strategy covers:

- Primary Keys (PK)
- Foreign Keys (FK)
- Business Keys (BK)
- Natural Keys
- Composite Keys
- Surrogate Keys

Key selection is based on the defined table grain and validated against the
available Olist data rather than being inferred solely from column names.

---

# 2. Key Strategy Principles

## 2.1 Preserve Source Identifiers in the Raw Layer

The Raw Layer preserves the identifiers provided by the original Olist
dataset.

Source identifiers are not replaced or regenerated during raw data loading.

This supports:

- source traceability;
- reproducibility;
- referential integrity with the original dataset;
- downstream transformation and validation.

The Raw Layer therefore prioritizes source-system fidelity over analytical
convenience.

---

## 2.2 Separate Technical Identity from Business Identity

A source-system identifier and a business identifier may represent different
concepts.

This distinction is particularly important for customer data.

The Olist dataset contains both:

- `customer_id`
- `customer_unique_id`

`customer_id` identifies a source-level customer record, while
`customer_unique_id` represents the business-level customer identity required
for customer analytics.

This distinction follows:

**D001 — Customer Identity Strategy**

The Raw Layer therefore retains `customer_id` as the row-level identifier,
while the Analytics Layer uses `customer_unique_id` as the customer identity.

---

## 2.3 Keys Must Follow Table Grain

A key must uniquely identify a row at the defined grain of the table.

Examples:

- `fact_orders` has a grain of one row per order, therefore `order_id`
  uniquely identifies the row.
- `fact_order_items` has a grain of one row per purchased item, therefore
  `order_id` alone is insufficient.
- `fact_payments` has a grain of one row per payment record, therefore
  `order_id` alone is insufficient.
- `dim_customer` has a grain of one row per business customer, therefore
  `customer_unique_id` must uniquely identify the analytical customer record.

Candidate keys were validated against the dataset before being adopted.

---

## 2.4 Prefer Existing Natural or Business Keys for the MVP

InsightFlow uses existing source-system or business identifiers whenever they
provide sufficient uniqueness and stability.

This avoids introducing artificial identifiers that do not solve a current
business or technical requirement.

The approach is consistent with the project's MVP scope and the decision to
use the original Olist data without synthetic business entities.

---

## 2.5 Use Composite Keys When Required by Source Grain

A composite key is used when no single column uniquely identifies a row.

This applies to entities where a child record is identified within the
context of its parent entity.

The following composite keys were validated against the dataset:

- `(order_id, order_item_id)`
- `(order_id, payment_sequential)`
- `(review_id, order_id)`

Each combination was confirmed to contain zero duplicate records.

---

## 2.6 Surrogate Keys Are Not Used for the MVP

InsightFlow does not introduce generated integer or UUID surrogate keys for
the current MVP.

The decision is based on the following considerations:

- the Olist dataset is historical and static;
- the current project does not require Slowly Changing Dimensions;
- existing natural and business identifiers are sufficient;
- introducing surrogate keys would add ETL mapping complexity;
- the current dataset size does not create a compelling requirement for
  surrogate-key optimization.

A surrogate-key strategy may be reconsidered in a future production-oriented
implementation if requirements change.

---

## 2.7 Raw and Analytics Keys May Differ

The Raw and Analytics Layers serve different purposes.

The Raw Layer prioritizes source-system fidelity.
The Analytics Layer prioritizes business-oriented analytical consistency.

Therefore, the same entity may use different identifiers between the two
layers.

The clearest example is Customer:

```text
RAW LAYER
customer_id
    │
    └── Source-level record identity

ANALYTICS LAYER
customer_unique_id
    │
    └── Business customer identity
```

This difference is intentional and follows D001.

---

# 3. Key Types

| Key Type          | Purpose                                                                    |
| ----------------- | -------------------------------------------------------------------------- |
| Primary Key (PK)  | Uniquely identifies each row within a table                                |
| Foreign Key (FK)  | References a key in another table and maintains referential integrity      |
| Business Key (BK) | Identifies a business entity from a business perspective                   |
| Natural Key       | An existing identifier derived from the source or business domain          |
| Composite Key     | A combination of multiple columns required to uniquely identify a row      |
| Surrogate Key     | An artificial identifier generated independently from source/business data |

---

# 4. Customer Key Validation

Key decisions for the Customer entity required additional validation because
the dataset contains two identifier columns representing different concepts.

Validation results for both columns are documented below.

All other entity key validations are embedded within their respective
subsections in Section 5.

---

## 4.1 `customer_id`

```text
Rows                : 99,441
Unique customer_id  : 99,441
```

Result:

```text
customer_id is unique per row.
```

Therefore:

```text
raw.customers
PK = customer_id
```

---

## 4.2 `customer_unique_id`

```text
Rows                       : 99,441
Unique customer_unique_id  : 96,096
```

Result:

```text
customer_unique_id is NOT unique in the Raw Layer.
```

Therefore it cannot serve as the Raw Layer primary key.

However, after the Analytics Layer consolidates customer records according
to D001, `customer_unique_id` becomes the unique identifier for the
business customer.

Therefore:

```text
analytics.dim_customer
PK = customer_unique_id
```

---

# 5. Entity Key Assignment

## 5.1 Customer

### Raw

```text
Table : raw.customers
PK    : customer_id
BK    : customer_unique_id
```

`customer_id` identifies the source customer record.

`customer_unique_id` is retained as the business identifier because multiple
source customer records can represent the same business customer.

### Analytics

```text
Table : analytics.dim_customer
PK    : customer_unique_id
BK    : customer_unique_id
```

The Analytics Layer consolidates customer records according to the D001
customer identity strategy.

---

## 5.2 Order

### Raw

```text
Table : raw.orders
PK    : order_id
BK    : order_id
```

Validation:

```text
Rows           : 99,441
Unique order_id : 99,441
```

`order_id` uniquely identifies all order records.

### Analytics

```text
Table : analytics.fact_orders
PK    : order_id
BK    : order_id
```

The grain remains one row per order.

The D002 anomaly flag is stored at this grain:

```text
has_timeline_anomaly
```

---

## 5.3 Order Item

### Raw

```text
Table : raw.order_items
PK    : (order_id, order_item_id)
```

`order_id` alone cannot uniquely identify an order item because one order
can contain multiple purchased items.

Validation:

```text
(order_id, order_item_id) → 0 duplicate records
```

The composite key is therefore adopted.

### Analytics

```text
Table : analytics.fact_order_items
PK    : (order_id, order_item_id)
```

The grain remains one row per purchased item.

---

## 5.4 Payment

### Raw

```text
Table : raw.payments
PK    : (order_id, payment_sequential)
```

`order_id` alone cannot uniquely identify a payment record because one order
may contain multiple payment records.

Validation:

```text
(order_id, payment_sequential) → 0 duplicate records
```

The composite key is therefore adopted.

### Analytics

```text
Table : analytics.fact_payments
PK    : (order_id, payment_sequential)
```

The grain remains one row per payment record.

The D003 anomaly flag is stored at this grain:

```text
has_installments_anomaly
```

---

## 5.5 Product

### Raw

```text
Table : raw.products
PK    : product_id
BK    : product_id
```

Validation:

```text
Rows              : 32,951
Unique product_id : 32,951
```

`product_id` uniquely identifies the product entity.

### Analytics

```text
Table : analytics.dim_product
PK    : product_id
BK    : product_id
```

The product dimension incorporates the translated category value from
`raw.category_translation` during ETL.

---

## 5.6 Seller

### Raw

```text
Table : raw.sellers
PK    : seller_id
BK    : seller_id
```

Validation:

```text
Rows             : 3,095
Unique seller_id : 3,095
```

`seller_id` uniquely identifies a seller.

### Analytics

```text
Table : analytics.dim_seller
PK    : seller_id
BK    : seller_id
```

---

## 5.7 Review

### Raw

```text
Table : raw.reviews
```

Validation:

```text
Rows             : 99,224
Unique review_id : 98,410
Unique order_id  : 98,673
```

Neither `review_id` nor `order_id` alone uniquely identifies every row.

Validation of the composite key:

```text
(review_id, order_id) → 0 duplicate records
```

Therefore:

```text
raw.reviews
PK = (review_id, order_id)
```

### Review ID Duplication — Known Platform Characteristic

Further investigation revealed that 789 `review_id` values appear across
more than one `order_id` (764 appearing in 2 orders, 25 appearing in 3
orders), affecting 1,603 total records.

Additional analysis confirmed that in all 789 cases, the duplicate
`review_id` values are always associated with the same
`customer_unique_id`.

Key observations:

- `review_score` is identical for all rows sharing the same `review_id`
- `review_creation_date` and `review_answer_timestamp` are identical
- All duplicate `review_id` values belong to the same customer

This pattern reflects a platform-level behavior where Olist assigns an
identical review record to all active orders of a customer when no manual
review response is submitted.

This is treated as a known platform characteristic rather than a data
quality issue. The composite key `(review_id, order_id)` remains valid
as it produces zero duplicate records and correctly represents the grain
of one review record per order.

Downstream analyses using `review_score` as a customer satisfaction
signal should be aware that some scores may reflect system-generated
reviews rather than explicit customer feedback.

### Analytics

```text
Table : analytics.fact_reviews
PK    : (review_id, order_id)
```

The grain remains one row per review record.

---

# 6. Lookup Key Strategy

## 6.1 Geolocation

The geolocation dataset is retained in the Raw Layer only and is not
promoted to an independent Analytics entity for the MVP.

Profiling showed:

```text
Rows                                : 1,000,163
Unique geolocation_zip_code_prefix  : 19,015
Unique geolocation_lat              : 717,363
Unique geolocation_lng              : 717,615
Unique geolocation_city             : 8,011
Unique geolocation_state            : 27
Full-row duplicate records          : 261,831
```

No single column provides a unique identifier and the full-row duplicate
count confirms that no reliable natural primary key exists.

A surrogate key is not introduced because:

- the table is Raw-only;
- it is not promoted to the Analytics Layer;
- introducing an artificial identifier would modify the source
  representation without a current analytical requirement.

The dataset remains available as source reference data.

---

## 6.2 Category Translation

```text
Rows                              : 71
Unique product_category_name      : 71
Unique product_category_name_english : 71
```

Therefore:

```text
raw.category_translation
Natural Key = product_category_name
```

The table remains Raw-only. The translated category is incorporated into
`analytics.dim_product` during ETL.

---

# 7. Foreign Key Strategy

Foreign keys maintain referential integrity while respecting the separation
between the Raw and Analytics Layers.

## 7.1 Raw Layer Foreign Keys

Raw foreign keys reference identifiers within the Raw Layer and preserve
the original source relationships.

| Child Table     | FK Column             | Parent Table             | PK Column             |
| --------------- | --------------------- | ------------------------ | --------------------- |
| raw.orders      | customer_id           | raw.customers            | customer_id           |
| raw.order_items | order_id              | raw.orders               | order_id              |
| raw.order_items | product_id            | raw.products             | product_id            |
| raw.order_items | seller_id             | raw.sellers              | seller_id             |
| raw.payments    | order_id              | raw.orders               | order_id              |
| raw.reviews     | order_id              | raw.orders               | order_id              |
| raw.products    | product_category_name | raw.category_translation | product_category_name |

---

## 7.2 Analytics Layer Foreign Keys

Analytics foreign keys reference business-oriented keys within the
Analytics Layer.

| Child Table      | FK Column          | Parent Table | PK Column          |
| ---------------- | ------------------ | ------------ | ------------------ |
| fact_orders      | customer_unique_id | dim_customer | customer_unique_id |
| fact_order_items | order_id           | fact_orders  | order_id           |
| fact_order_items | product_id         | dim_product  | product_id         |
| fact_order_items | seller_id          | dim_seller   | seller_id          |
| fact_payments    | order_id           | fact_orders  | order_id           |
| fact_reviews     | order_id           | fact_orders  | order_id           |

The exact relationship cardinality and optionality for each foreign key
are documented in:

`03_relationship_design.md`

---

# 8. Customer Identity Strategy

Customer identity is the most significant key transformation in the
Analytics Layer.

The source dataset contains multiple `customer_id` records associated with
the same `customer_unique_id`.

```text
RAW

customer_id
   │
   ├── Record A  ─┐
   ├── Record B  ─┼── customer_unique_id ── One Business Customer
   └── Record C  ─┘


ANALYTICS

dim_customer
customer_unique_id
        │
        └── One row per business customer
```

This supports customer-level analytical requirements including:

- repeat purchase analysis;
- RFM segmentation;
- retention analysis;
- churn analysis;
- customer lifetime value analysis.

The decision is directly derived from D001.

---

# 9. Composite Key Decisions

Three composite keys are adopted in the current database design.

| Table         | Composite Key                    | Reason                                                                |
| ------------- | -------------------------------- | --------------------------------------------------------------------- |
| `order_items` | `(order_id, order_item_id)`      | One order can contain multiple items                                  |
| `payments`    | `(order_id, payment_sequential)` | One order can contain multiple payment records                        |
| `reviews`     | `(review_id, order_id)`          | Neither `review_id` nor `order_id` alone is unique in the source data |

All three combinations were validated and returned zero duplicate records.

Composite keys are therefore preferred over artificial surrogate identifiers
for the MVP.

---

# 10. Surrogate Key Decision

## Decision

**Surrogate keys are not used in the MVP.**

### Advantages of Surrogate Keys

- simple single-column joins;
- stable internal identifiers;
- support for Slowly Changing Dimensions;
- easier integration of multiple source systems;
- independence from source-system identifiers.

### Disadvantages for the Current Project

- additional ETL mapping complexity;
- additional technical columns without business meaning;
- more complex debugging;
- less direct traceability to the original Olist data;
- complexity without a current business requirement.

Because InsightFlow currently uses a single historical source dataset and
does not require Slowly Changing Dimensions, the benefits do not outweigh
the additional complexity.

### Future Consideration

Surrogate keys may be reconsidered if InsightFlow evolves into a
production data warehouse requiring:

- multiple source systems;
- historical dimension management;
- source identifier changes;
- large-scale warehouse optimization.

---

# 11. Final Key Matrix

| Entity               | Raw PK                           | Raw BK                  | Analytics PK                     | Analytics BK         |
| -------------------- | -------------------------------- | ----------------------- | -------------------------------- | -------------------- |
| Customer             | `customer_id`                    | `customer_unique_id`    | `customer_unique_id`             | `customer_unique_id` |
| Order                | `order_id`                       | `order_id`              | `order_id`                       | `order_id`           |
| Order Item           | `(order_id, order_item_id)`      | —                       | `(order_id, order_item_id)`      | —                    |
| Payment              | `(order_id, payment_sequential)` | —                       | `(order_id, payment_sequential)` | —                    |
| Product              | `product_id`                     | `product_id`            | `product_id`                     | `product_id`         |
| Seller               | `seller_id`                      | `seller_id`             | `seller_id`                      | `seller_id`          |
| Review               | `(review_id, order_id)`          | —                       | `(review_id, order_id)`          | —                    |
| Geolocation          | No natural PK                    | —                       | —                                | —                    |
| Category Translation | `product_category_name`          | `product_category_name` | —                                | —                    |

---

# 12. Key Strategy Summary

The final key strategy follows four major principles:

1. **Preserve source identifiers in the Raw Layer.**
2. **Use business identity in the Analytics Layer where required.**
3. **Use composite keys when the source grain requires multiple columns.**
4. **Avoid surrogate keys unless a real business or architectural
   requirement justifies them.**

The most significant transformation occurs for Customer:

```text
Raw                          Analytics
customer_id              →   customer_unique_id
source record identity       business customer identity
```

For transaction-level entities, the Analytics Layer preserves the same
natural or composite key as the Raw Layer because the analytical grain
remains unchanged.

This keeps the Analytics Layer traceable to the source while supporting
the business-oriented customer identity required by InsightFlow.

---

# 13. Relationship Design Handoff

The key strategy establishes the identifiers required for relationship
modeling.

The next design stage will determine:

- one-to-one relationships;
- one-to-many relationships;
- optionality;
- parent-child relationships;
- foreign key placement;
- relationship cardinality.

These decisions will be documented in:

`03_relationship_design.md`

---

# 14. Conclusion

The InsightFlow key strategy uses validated natural and business identifiers
as the default approach for the MVP.

Source-level identifiers are preserved in the Raw Layer, while
`customer_unique_id` is promoted as the business customer identifier in
the Analytics Layer according to D001.

Composite keys are used for order items, payments, and reviews where
single columns do not provide sufficient uniqueness.

The review_id duplication pattern (789 review_ids appearing across
multiple orders) has been investigated and confirmed as a known
platform-level behavior of the Olist system, where identical review
records are assigned to all active orders of a customer when no manual
review response is submitted.

The geolocation dataset is retained without an artificial primary key
because the source does not provide a reliable natural key and the
dataset is not promoted into the Analytics Layer.

Surrogate keys are intentionally excluded from the MVP to minimize
unnecessary ETL complexity while maintaining traceability to the original
Olist dataset.

This key strategy provides the foundation for relationship modeling,
normalization, ERD development, and physical PostgreSQL implementation.
