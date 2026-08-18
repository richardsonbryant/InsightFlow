# Relationship Design

| Metadata          | Value                                                         |
| ----------------- | ------------------------------------------------------------- |
| Date              | 2026-08-13                                                    |
| Phase             | Database Design                                               |
| Related Documents | 01_business_entities.md, 02_key_strategy.md, D001, D002, D003 |

---

# 1. Purpose

This document defines the relationships between business entities within the
InsightFlow database.

The relationship design determines:

- parent-child relationships;
- foreign key placement;
- cardinality;
- optionality;
- referential integrity;
- differences between Raw and Analytics Layer relationships.

The design is based on the entity definitions established in
`01_business_entities.md` and the key strategy established in
`02_key_strategy.md`.

Relationship cardinality is validated against the Olist dataset rather than
being inferred solely from the conceptual business model.

---

# 2. Relationship Design Principles

## 2.1 Relationships Follow Table Grain

Relationships must be consistent with the grain defined for each table.

For example:

- `fact_orders` has a grain of one row per order;
- `fact_order_items` has a grain of one row per purchased item;
- `fact_payments` has a grain of one row per payment record;
- `fact_reviews` has a grain of one row per review record;
- `dim_customer` has a grain of one row per business customer.

Cardinality is therefore evaluated based on the actual row-level behavior of
the dataset.

---

## 2.2 Foreign Keys Reference Valid Keys

A foreign key must reference a valid primary key or unique business key in the
parent entity.

The key strategy defined in `02_key_strategy.md` determines which identifiers
are available for relationship implementation.

---

## 2.3 Raw and Analytics Relationships Serve Different Purposes

The Raw Layer preserves the source relationships of the Olist dataset.

The Analytics Layer introduces business-oriented relationships where required
by analytical modeling.

The most significant difference occurs for Customer.

In the Raw Layer:

```text
customer_id
```

represents the source-level customer record.

In the Analytics Layer:

```text
customer_unique_id
```

represents the business customer identity established by D001.

---

## 2.4 Cardinality Is Based on Observed Data

The relationship design uses the following cardinality notation:

| Notation | Meaning                                                 |
| -------- | ------------------------------------------------------- |
| 1:1      | One parent corresponds to one child                     |
| 1:N      | One parent corresponds to multiple children             |
| 1:0..N   | One parent may have zero or multiple children           |
| 0..1     | A relationship may be absent or have one related record |

Where applicable, optionality is derived from observed records in the
dataset.

---

# 3. Raw Layer Relationship Model

The Raw Layer preserves the relationships represented by the original Olist
datasets.

The primary relationships are:

```text
Customers
    │
    │ 1:1
    ▼
Orders
    │
    ├─────────────── 1:0..N ──────────────► Order Items
    │
    ├─────────────── 1:0..N ──────────────► Payments
    │
    └─────────────── 1:0..N ──────────────► Reviews

Products
    │
    │ 1:N
    ▼
Order Items

Sellers
    │
    │ 1:N
    ▼
Order Items
```

The Customer → Order relationship requires special interpretation because the
Raw Layer uses `customer_id`, while the Analytics Layer uses
`customer_unique_id`.

Note: The 1:1 cardinality between Customers and Orders in the Raw Layer
reflects the source data structure where each customer_id is associated
with exactly one order_id. This is a characteristic of how the Olist
dataset assigns customer_id per transaction, not a business rule that
limits one customer to one order. The true business relationship
(one customer can place multiple orders) is reflected in the Analytics
Layer through customer_unique_id.

---

# 4. Analytics Layer Relationship Model

The Analytics Layer is organized around business-oriented entities.

The central relationship structure is:

```text
dim_customer
      │
      │ 1:N
      ▼
fact_orders
      │
      ├────────────── 1:0..N ──────────────► fact_order_items
      │
      ├────────────── 1:0..N ──────────────► fact_payments
      │
      └────────────── 1:0..N ──────────────► fact_reviews

dim_product
      │
      │ 1:N
      ▼
fact_order_items

dim_seller
      │
      │ 1:N
      ▼
fact_order_items
```

This structure separates descriptive business entities from transactional
events while preserving the defined 3NF design.

---

# 5. Relationship-by-Relationship Analysis

## 5.1 Customer → Order

### Raw Layer

```text
raw.customers
      1
      │
      │ customer_id
      ▼
raw.orders
      1
```

Validation results:

```text
Orders without customer_id : 0
Orders with orphan customer: 0
Customers with orders      : 99,441
Maximum orders per customer: 1
```

Additional validation confirmed that all 99,441 customer records have
at least one corresponding order record. No customers without orders
were found in the source dataset.

Therefore, within the Raw Layer:

```text
raw.customers
    1
    │
    1
raw.orders
```

The observed source relationship is **1:1** at the `customer_id` level.

The foreign key is:

```text
raw.orders.customer_id
        ↓
raw.customers.customer_id
```

---

### Analytics Layer

The Analytics Layer uses `customer_unique_id` as the business customer
identifier according to D001.

Because multiple source customer records may represent the same business
customer, the Analytics relationship differs from the Raw relationship.

```text
analytics.dim_customer
          1
          │
          │ customer_unique_id
          N
analytics.fact_orders
```

Therefore:

> **Analytics Customer → Order = 1:N**

This difference is intentional and results from the customer identity
transformation established by D001.

---

# 5.2 Order → Order Item

Validation results:

```text
Order items with orphan order : 0
Orders without order items    : 775
Orders with items              : 98,666
Maximum items per order        : 21
```

The relationship is therefore:

```text
Order
  │
  ├── 0 Item
  ├── 1 Item
  └── N Items
```

Cardinality:

> **Order → Order Item = 1:0..N**

The relationship is implemented through:

```text
raw.order_items.order_id
        ↓
raw.orders.order_id
```

and:

```text
analytics.fact_order_items.order_id
        ↓
analytics.fact_orders.order_id
```

The relationship is consistent with the composite key:

```text
(order_id, order_item_id)
```

defined in `02_key_strategy.md`.

The existence of 775 orders without order items means the relationship must
not be modeled as mandatory on the child side for every order.

---

# 5.3 Order → Payment

Validation results:

```text
Payments with orphan order : 0
Orders without payment    : 1
Orders with payment       : 99,440
Maximum payments per order: 29
```

Therefore:

```text
Order
  │
  ├── 0 Payment
  ├── 1 Payment
  └── N Payments
```

Cardinality:

> **Order → Payment = 1:0..N**

The relationship is implemented through:

```text
raw.payments.order_id
        ↓
raw.orders.order_id
```

and:

```text
analytics.fact_payments.order_id
        ↓
analytics.fact_orders.order_id
```

The relationship is consistent with the composite payment key:

```text
(order_id, payment_sequential)
```

defined in `02_key_strategy.md`.

The one order without a payment record confirms that a payment relationship
cannot be treated as mandatory for every order.

---

# 5.4 Order → Review

Validation results:

```text
Reviews with orphan order     : 0
Orders without review         : 768
Orders with one review        : 98,126
Orders with multiple reviews  : 547
Maximum reviews per order     : 3
```

The observed structure is:

```text
Order
  │
  ├── 0 Review
  ├── 1 Review
  └── N Reviews
```

Therefore:

> **Order → Review = 1:0..N**

The relationship is implemented through:

```text
raw.reviews.order_id
        ↓
raw.orders.order_id
```

and:

```text
analytics.fact_reviews.order_id
        ↓
analytics.fact_orders.order_id
```

The relationship is intentionally not modeled as 1:1.

The dataset contains 547 orders with multiple review records, with a maximum
of three review records associated with a single order.

This behavior is consistent with the review-key analysis documented in
`02_key_strategy.md`.

The composite key:

```text
(review_id, order_id)
```

is therefore retained for `fact_reviews`.

---

# 5.5 Product → Order Item

Validation results:

```text
Order items with orphan product : 0
```

Therefore every `product_id` referenced by an order item corresponds to a
valid product record.

The relationship is:

```text
dim_product
     1
     │
     N
fact_order_items
```

Cardinality:

> **Product → Order Item = 1:N**

Foreign key:

```text
analytics.fact_order_items.product_id
        ↓
analytics.dim_product.product_id
```

The same source relationship exists in the Raw Layer:

```text
raw.order_items.product_id
        ↓
raw.products.product_id
```

---

# 5.6 Seller → Order Item

Validation results:

```text
Order items with orphan seller : 0
```

Therefore every `seller_id` referenced by an order item corresponds to a valid
seller record.

The relationship is:

```text
dim_seller
     1
     │
     N
fact_order_items
```

Cardinality:

> **Seller → Order Item = 1:N**

Foreign key:

```text
analytics.fact_order_items.seller_id
        ↓
analytics.dim_seller.seller_id
```

The same source relationship exists in the Raw Layer:

```text
raw.order_items.seller_id
        ↓
raw.sellers.seller_id
```

---

# 6. Foreign Key Placement

The foreign key placement follows the parent-child relationship structure.

## 6.1 Raw Layer

| Child Table       | Foreign Key   | Parent Table    | Parent Key    |
| ----------------- | ------------- | --------------- | ------------- |
| `raw.orders`      | `customer_id` | `raw.customers` | `customer_id` |
| `raw.order_items` | `order_id`    | `raw.orders`    | `order_id`    |
| `raw.order_items` | `product_id`  | `raw.products`  | `product_id`  |
| `raw.order_items` | `seller_id`   | `raw.sellers`   | `seller_id`   |
| `raw.payments`    | `order_id`    | `raw.orders`    | `order_id`    |
| `raw.reviews`     | `order_id`    | `raw.orders`    | `order_id`    |

---

## 6.2 Analytics Layer

| Child Table        | Foreign Key          | Parent Table   | Parent Key           |
| ------------------ | -------------------- | -------------- | -------------------- |
| `fact_orders`      | `customer_unique_id` | `dim_customer` | `customer_unique_id` |
| `fact_order_items` | `order_id`           | `fact_orders`  | `order_id`           |
| `fact_order_items` | `product_id`         | `dim_product`  | `product_id`         |
| `fact_order_items` | `seller_id`          | `dim_seller`   | `seller_id`          |
| `fact_payments`    | `order_id`           | `fact_orders`  | `order_id`           |
| `fact_reviews`     | `order_id`           | `fact_orders`  | `order_id`           |

These relationships provide the structural basis for the PostgreSQL foreign
key constraints defined later in `05_database_design.md`.

---

# 7. Referential Integrity Validation

Relationship validation was performed against the available Olist datasets.

The following results were observed:

| Relationship         | Orphan Records |
| -------------------- | -------------- |
| Order → Customer     | 0              |
| Order Item → Order   | 0              |
| Payment → Order      | 0              |
| Review → Order       | 0              |
| Order Item → Product | 0              |
| Order Item → Seller  | 0              |

This indicates that all tested child records reference valid parent records
within the source datasets.

The absence of orphan records supports the implementation of corresponding
foreign key constraints in the database.

---

# 8. Optionality Summary

The relationship optionality is summarized below.

| Parent   | Child      | Cardinality             | Child Availability                 |
| -------- | ---------- | ----------------------- | ---------------------------------- |
| Customer | Order      | 1:1 Raw / 1:N Analytics | Order has customer                 |
| Order    | Order Item | 1:0..N                  | Some orders have no items          |
| Order    | Payment    | 1:0..N                  | One order has no payment           |
| Order    | Review     | 1:0..N                  | Some orders have no review         |
| Product  | Order Item | 1:N                     | All tested items reference product |
| Seller   | Order Item | 1:N                     | All tested items reference seller  |

The `0..N` relationships are intentional and reflect observed source data
rather than database errors.

---

# 9. Relationship Matrix

## Raw Layer

| Parent      | Child         | Cardinality | Foreign Key              | Integrity |
| ----------- | ------------- | ----------- | ------------------------ | --------- |
| `customers` | `orders`      | 1:1         | `orders.customer_id`     | Valid     |
| `orders`    | `order_items` | 1:0..N      | `order_items.order_id`   | Valid     |
| `orders`    | `payments`    | 1:0..N      | `payments.order_id`      | Valid     |
| `orders`    | `reviews`     | 1:0..N      | `reviews.order_id`       | Valid     |
| `products`  | `order_items` | 1:N         | `order_items.product_id` | Valid     |
| `sellers`   | `order_items` | 1:N         | `order_items.seller_id`  | Valid     |

---

## Analytics Layer

| Parent         | Child              | Cardinality | Foreign Key                      | Integrity       |
| -------------- | ------------------ | ----------- | -------------------------------- | --------------- |
| `dim_customer` | `fact_orders`      | 1:N         | `fact_orders.customer_unique_id` | Valid by design |
| `fact_orders`  | `fact_order_items` | 1:0..N      | `fact_order_items.order_id`      | Valid           |
| `fact_orders`  | `fact_payments`    | 1:0..N      | `fact_payments.order_id`         | Valid           |
| `fact_orders`  | `fact_reviews`     | 1:0..N      | `fact_reviews.order_id`          | Valid           |
| `dim_product`  | `fact_order_items` | 1:N         | `fact_order_items.product_id`    | Valid           |
| `dim_seller`   | `fact_order_items` | 1:N         | `fact_order_items.seller_id`     | Valid           |

---

# 10. Cross-Layer Identity Consideration

Customer is the primary case where the Raw and Analytics relationship
structures differ.

## Raw Layer

```text
customer_id
     │
     ▼
source customer record
     │
     │ 1:1
     ▼
order_id
```

The source dataset contains one order per `customer_id`.

## Analytics Layer

```text
customer_unique_id
        │
        │ 1:N
        ▼
order_id
```

Multiple source customer records can map to the same business customer.

Therefore the Analytics Layer relationship is based on the business identity
defined by D001 rather than directly reproducing the Raw Layer relationship.

This allows customer-level analytical questions to operate at the correct
business grain.

---

# 11. Relationship Design Implications

The relationship design has several implications for the physical database.

## 11.1 Foreign Key Constraints

The validated relationships support the implementation of foreign key
constraints for the corresponding parent-child relationships.

---

## 11.2 Composite Primary Keys

The following relationships depend on composite primary keys established in
`02_key_strategy.md`:

```text
fact_order_items
    PK = (order_id, order_item_id)

fact_payments
    PK = (order_id, payment_sequential)

fact_reviews
    PK = (review_id, order_id)
```

The foreign key to the parent order uses the `order_id` component.

---

## 11.3 Optional Relationships

The following relationships must allow the absence of child records:

```text
Order → Order Item
Order → Payment
Order → Review
```

This means the database design must not incorrectly assume that every order
has at least one child record in these entities.

---

# 12. ERD Handoff

The relationship design provides the logical structure required to construct
the Entity Relationship Diagram.

The ERD should represent:

```text
dim_customer
      │
      │ 1:N
      ▼
fact_orders
      │
      ├── 1:0..N ──► fact_order_items
      │
      ├── 1:0..N ──► fact_payments
      │
      └── 1:0..N ──► fact_reviews

dim_product
      │
      │ 1:N
      ▼
fact_order_items

dim_seller
      │
      │ 1:N
      ▼
fact_order_items
```

The ERD should also show the relevant primary keys and foreign keys defined
in `02_key_strategy.md`.

No new business entities should be introduced during ERD construction unless
a previously undocumented requirement is discovered.

---

# 13. Relationship Design Decisions

The final relationship decisions are:

1. Raw Customer → Order is modeled as 1:1 at the `customer_id` level.
2. Analytics Customer → Order is modeled as 1:N at the
   `customer_unique_id` level.
3. Order → Order Item is modeled as 1:0..N.
4. Order → Payment is modeled as 1:0..N.
5. Order → Review is modeled as 1:0..N.
6. Product → Order Item is modeled as 1:N.
7. Seller → Order Item is modeled as 1:N.
8. All validated child records have valid parent references.
9. Optionality is preserved where the source data demonstrates missing child
   records.
10. Foreign keys are placed on the child entities.

---

# 14. Conclusion

The InsightFlow relationship model is based on the actual structure and
behavior of the Olist dataset.

The Raw Layer preserves the source relationships, while the Analytics Layer
introduces the business-oriented customer relationship established by D001.

The primary transaction relationships are:

```text
Customer → Order
Order → Order Item
Order → Payment
Order → Review
Product → Order Item
Seller → Order Item
```

Relationship validation found no orphan records across the tested
relationships.

However, several relationships are optional:

- 775 orders have no order items;
- 1 order has no payment;
- 768 orders have no review.

The Review entity also demonstrates a one-to-many relationship because 547
orders contain multiple review records, with a maximum of three reviews per
order.

These findings provide the logical foundation for the next stage:

`04_erd.md`

The ERD will visualize the approved entities, keys, relationships,
cardinality, and foreign key placement established by this document.
