# Business Requirements

## Business Background

NovaCart has experienced rapid customer growth; however, customer loyalty has not increased at the same pace. A significant proportion of customers make only a single purchase and never return. To address this challenge, the company requires a **Customer Analytics Platform** that enables data-driven strategies to improve customer retention and long-term customer value.

---

## Business Objectives

- Increase the customer retention rate.
- Reduce the customer churn rate.
- Identify high-value customers.
- Improve the repeat purchase rate.
- Support data-driven, customer segmentation–based retention strategies.

---

## Stakeholder Analysis

| Stakeholder              | Business Needs                                                           |
| ------------------------ | ------------------------------------------------------------------------ |
| CEO                      | Executive overview of business performance and customer retention trends |
| Marketing Manager        | Customer segmentation and campaign targeting                             |
| Customer Success Manager | Identification of customers at risk of churn                             |
| Data Analyst             | KPI monitoring and analytical reporting                                  |

---

## KPI Definitions

### Growth

- Revenue
- Total Orders
- Average Order Value (AOV)

### Customer

- Active Customers
- New vs. Returning Customers
- Customer Retention Rate
- Customer Churn Rate

### Customer Value

- Customer Lifetime Value (CLV)
- Customer Segment Distribution

### Product

- Best-Selling Product Categories
- Repeat Purchase Rate by Product Category

---

## Business Questions

### Revenue & Growth

- How has monthly revenue changed over time?
- Which product categories contribute the most to total revenue?

### Customer & Retention

- What percentage of customers are new versus returning?
- Who are the most loyal customers?
- How many customers are currently at risk of churn?

### Customer Churn

- What characteristics are commonly associated with customers who churn?
- Which factors have the greatest influence on customer churn?

### Customer Segmentation

- How many customer segments can be identified?
- What is the most appropriate retention strategy for each customer segment?

---

## Data Requirements

| Entity    | Key Fields                                                          |
| --------- | ------------------------------------------------------------------- |
| Customers | `customer_id`, `city`, `registration_date`                          |
| Orders    | `order_id`, `customer_id`, `order_date`, `total_amount`, `category` |
| Payments  | `payment_method`, `payment_value`                                   |
| Reviews   | `rating`, `review_date`                                             |

---

## Initial Business Assumption

A customer is initially classified as **churned** if they have not placed a transaction within **180 days**.

This assumption will be validated during the **Dataset Assessment** phase using the available historical transaction data.

---

## Success Criteria

- The dashboard successfully answers all defined business questions.
- The churn prediction model achieves strong recall performance.
- Every analytical insight is accompanied by clear and actionable business recommendations.
