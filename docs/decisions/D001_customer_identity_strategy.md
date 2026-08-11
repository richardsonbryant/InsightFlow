# D001 — Customer Identity Strategy

| Metadata             | Value                                 |
| -------------------- | ------------------------------------- |
| **Date**             | 2026-08-10                            |
| **Phase**            | Dataset Assessment                    |
| **Category**         | Data Modeling                         |
| **Impact Level**     | High                                  |
| **Related Notebook** | `00_customer_identity_strategy.ipynb` |

---

# Context

The Olist dataset provides two attributes related to customer identity: `customer_id` and `customer_unique_id`.

Data profiling produced the following results:

| Metric                      |  Value |
| --------------------------- | -----: |
| Total Records               | 99,441 |
| Unique `customer_id`        | 99,441 |
| Unique `customer_unique_id` | 96,096 |

Further analysis of the distribution of `customer_id` values per `customer_unique_id` revealed the following:

| Number of `customer_id` | Customers | Percentage |
| ----------------------: | --------: | ---------: |
|                       1 |    93,099 |     96.88% |
|                       2 |     2,745 |      2.86% |
|                       3 |       203 |      0.21% |
|                       4 |        30 |      0.03% |
|                       5 |         8 |      0.01% |
|                       6 |         6 |      0.01% |
|                       7 |         3 |     <0.01% |
|                       9 |         1 |     <0.01% |
|                      17 |         1 |     <0.01% |

The profiling results indicate that approximately **3.12% of customers are associated with more than one `customer_id`**.

Therefore, `customer_id` cannot be considered the true business representation of a customer. Instead, `customer_unique_id` links multiple `customer_id` values belonging to the same customer.

This finding is consistent with the official Olist documentation, which states that `customer_id` represents a customer instance for a specific order, whereas `customer_unique_id` represents the same customer across multiple orders. [1]

InsightFlow is a **Customer Analytics Platform** focused on customer-level analyses such as Customer Segmentation, Repeat Purchase Analysis, Customer Lifetime Value (CLV), Customer Retention, and Customer Churn. All of these analyses require a consistent customer identity across the entire transaction history.

---

# Problem

Which customer identifier should be adopted as the primary **business identifier** to ensure that all customer-level analyses produce consistent, accurate, and reliable metrics?

---

# Alternatives Considered

## Option A — Use `customer_id`

### Advantages

- Preserves the original Olist dataset structure.
- All foreign key relationships directly reference `customer_id`.
- Table joins are relatively straightforward.

### Disadvantages

- Customer transaction history may become fragmented when a single `customer_unique_id` is associated with multiple `customer_id` values.
- Customer-level metrics such as Repeat Purchase Rate, RFM Analysis, CLV, Retention, and Churn may produce inconsistent customer representations.

---

## Option B — Use `customer_unique_id`

### Advantages

- Represents the complete transaction history of each customer as a single entity.
- Aligns with the requirements of customer-level analytics.
- Supports all core business KPIs defined in the InsightFlow Business Requirements.

### Disadvantages

- Requires a mapping step through the **Customers** table before customer-level analysis.
- Introduces slightly more complexity into the ETL process compared to using `customer_id` directly.

---

# Decision

InsightFlow adopts a **Hybrid Customer Identity Strategy**.

The decisions are as follows:

- The **Raw Layer** preserves the original Olist dataset without modification.
- `customer_id` remains the **technical identifier** to maintain referential integrity across tables.
- The **Analytics Layer** uses `customer_unique_id` as the **business identifier** for all customer-level analyses.

Within the MVP scope, **no additional surrogate key will be introduced**. `customer_unique_id` is used directly as the customer identifier in the analytics layer because it fully satisfies the current business requirements, and there is no requirement that justifies introducing a surrogate key.

---

# Decision Rationale

Although only **3.12% of customers** have more than one `customer_id`, these cases have a direct impact on every customer-level analysis.

If `customer_id` were used as the primary customer identifier, the transaction history of these customers would be fragmented across multiple entities, leading to inconsistent calculations for:

- Repeat Purchase Rate
- Customer Lifetime Value (CLV)
- RFM Analysis
- Customer Retention
- Customer Churn

Using `customer_unique_id`, on the other hand, allows the complete transaction history of each customer to be represented as a single business entity without altering the raw dataset structure.

The introduction of a surrogate key was also considered. However, within the MVP scope of InsightFlow, no business or technical requirement justifies its implementation. The dataset is relatively small (approximately **100,000 customers**), does not require Slowly Changing Dimensions (SCD), and does not target production-scale data warehouse optimization. Therefore, adding a surrogate key would increase ETL complexity without providing meaningful business value at this stage.

---

# Consequences

This decision becomes the standard for all InsightFlow components.

## Database Design

- The Raw Database preserves the original Olist schema.
- The Analytics Layer represents customers using `customer_unique_id`.

## ETL Pipeline

- The ETL pipeline maps `customer_id` to `customer_unique_id`.
- All customer-level features are generated using `customer_unique_id`.

## SQL Analytics

All customer-level queries use:

```sql
GROUP BY customer_unique_id
```

instead of:

```sql
GROUP BY customer_id
```

## Dashboard

All customer KPIs are calculated using `customer_unique_id`, including:

- Active Customers
- Returning Customers
- Customer Retention
- Customer Churn
- Customer Lifetime Value (CLV)
- Customer Segmentation

## Machine Learning

All customer-level feature engineering is performed using `customer_unique_id` as the primary entity.

---

# Impact

## Affected Components

- Database Design
- ETL Pipeline
- SQL Analytics
- Dashboard
- Machine Learning

## Related Decisions

None (First Architectural Decision)

---

# Next Action

The next step is to evaluate the quality of customer attributes associated with each `customer_unique_id` as part of the **Data Quality Assessment**. The results of this assessment will serve as the foundation for the Database Design and ETL Pipeline.

---

# References

[1] Olist. _Brazilian E-Commerce Public Dataset by Olist – Data Description_. Kaggle. Accessed August 11, 2026.
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/data
