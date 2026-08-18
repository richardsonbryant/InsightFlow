# InsightFlow

> **End-to-end Customer Analytics Platform** — from raw transactional data
> to SQL analytics, dashboards, and machine learning.
> Built on the Olist Brazilian E-Commerce Dataset.

![Status](https://img.shields.io/badge/Status-In%20Progress-orange)
![Phase](https://img.shields.io/badge/Current%20Phase-SQL%20Analytics-blue)
![Python](https://img.shields.io/badge/Python-3.13-blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-blue)
![License](https://img.shields.io/badge/License-MIT-green)

---

## What This Project Demonstrates

Most analytics portfolio projects start at the dashboard or model stage.
InsightFlow documents the **complete analytical lifecycle** — including the
decisions that are usually invisible:

- How business requirements translate into database design
- How data quality issues are investigated and resolved before modeling
- How analytical decisions are documented and justified
- How SQL analytics are validated against business definitions

Every significant decision is recorded as an **Architecture Decision Record
(ADR)** with context, alternatives considered, and consequences.

---

## Business Problem

NovaCart, a fictional Brazilian e-commerce company, is experiencing rapid
customer growth but low retention. Customers make one purchase and never
return. InsightFlow is designed to answer:

- Who are the customers at risk of churning?
- What distinguishes high-value customers from one-time buyers?
- How can customer segments be used to drive retention strategies?

---

## Dataset

**Olist Brazilian E-Commerce Public Dataset** (Kaggle)

Nine relational tables covering the complete customer purchasing lifecycle —
99,441 orders, 96,096 unique customers, 32,951 products, 3,095 sellers.
Data covers September 2016 – October 2018.

---

## Project Architecture

```text
Business Requirements (BRD)
         │
         ▼
Dataset Assessment & Decision Log
         │
         ▼
PostgreSQL Database (Raw + Analytics Layer)
         │
         ▼
ETL Pipeline (Raw → Analytics)
         │
         ▼
SQL Analytics
         │
         ▼
Power BI Dashboard          Machine Learning (Phase 4)
```

---

## Current Progress

| Phase       | Description                       | Status         |
| ----------- | --------------------------------- | -------------- |
| **Phase 1** | Dataset Acquisition & Assessment  | ✅ Complete    |
| **Phase 2** | Database Design & Implementation  | ✅ Complete    |
| **Phase 3** | SQL Analytics                     | ✅ Complete    |
| **Phase 4** | RFM Segmentation & Churn Modeling | 🔄 In Progress |
| **Phase 5** | Power BI Dashboard                | ⏳ Planned     |

### Phase 1 — Dataset Acquisition & Assessment ✅

- Business Requirements Document (BRD)
- Data profiling across 9 relational datasets
- Data quality investigation and reporting
- **3 Architecture Decision Records** (D001–D003)

### Phase 2 — Database Design & Implementation ✅

- Two-layer PostgreSQL architecture (Raw + Analytics)
- 9 Raw tables + 7 Analytics tables (3 dimensions, 4 facts)
- ETL pipeline: 7 transformation scripts with anomaly flag derivation
- Full validation: row counts, FK integrity, flag distribution

### Phase 3 — SQL Analytics ✅

- Executive metrics (revenue, orders, AOV) — monthly time series
- Sales trends (MoM growth, YoY growth, order status distribution)
- Product & category performance with revenue share
- Customer behavioral base, new vs returning, cohort retention analysis

---

## Key Design Decisions

| Decision                                                                         | Summary                                                                                              |
| -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| [D001 — Customer Identity](docs/decisions/D001_customer_identifier_selection.md) | `customer_unique_id` adopted as business identifier; `customer_id` retained as transaction-level key |
| [D002 — Timeline Anomaly](docs/decisions/D002_order_timeline_strategy.md)        | 1,382 orders with inconsistent timestamps retained with `has_timeline_anomaly` flag                  |
| [D003 — Payment Anomaly](docs/decisions/D003_payment_record_anomaly_strategy.md) | Differentiated treatment: payment value anomalies explained; installments anomaly flagged            |

---

## Repository Structure

```text
InsightFlow/
│
├── docs/
│   ├── requirements/          # BRD, functional & non-functional requirements
│   ├── assessments/           # Dataset assessment, data quality, data dictionary
│   ├── decisions/             # Architecture Decision Records (D001–D003)
│   └── architecture/          # Business entities, key strategy, ERD, DB design
│
├── notebooks/
│   ├── 00_data_profiling.ipynb
│   └── 01_dataset_assessment.ipynb
│
├── database/
│   ├── schema.sql             # CREATE TABLE (Raw + Analytics)
│   ├── indexes.sql
│   ├── seeds/                 # CSV → Raw Layer loading
│   ├── etl/                   # Raw → Analytics transformation
│   └── validation/            # Raw and Analytics validation queries
│
├── sql/
│   └── analytics/
│       ├── 01_executive_metrics.sql
│       ├── 02_sales_trends.sql
│       ├── 03_product_analytics.sql
│       └── 04_customer_analytics.sql
│
├── dashboard/                 # Power BI files (Phase 5)
├── models/                    # ML models (Phase 4)
├── data/
│   ├── raw/                   # Gitignored — see Setup
│   └── processed/
│
├── requirements.txt
└── README.md
```

---

## Setup & Reproduction

### Prerequisites

- Python 3.13+
- PostgreSQL 17+
- Kaggle account (for dataset download)

### Steps

**1. Clone the repository**

```bash
git clone https://github.com/YOUR_USERNAME/insightflow.git
cd insightflow
```

**2. Install dependencies**

```bash
pip install -r requirements.txt
```

**3. Download the dataset**

Download the [Olist Brazilian E-Commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
from Kaggle and place all CSV files in `data/raw/`.

**4. Create the PostgreSQL database**

```bash
createdb insightflow
psql -d insightflow -f database/schema.sql
psql -d insightflow -f database/indexes.sql
```

**5. Load raw data**

```bash
psql -d insightflow -f database/seeds/load_data.sql
```

**6. Run ETL**

```bash
psql -d insightflow -f database/etl/08_run_all.sql
```

**7. Validate**

```bash
psql -d insightflow -f database/validation/raw_validation.sql
psql -d insightflow -f database/validation/analytics_validation.sql
```

---

## Technologies

| Category        | Tools            |
| --------------- | ---------------- |
| Database        | PostgreSQL 17    |
| Language        | Python 3.13, SQL |
| Analytics       | Pandas, Jupyter  |
| Visualization   | Power BI         |
| Version Control | Git, GitHub      |

---

## Author

**Richardson Bryant**
Data Analytics Portfolio Project
[GitHub](https://github.com/YOUR_USERNAME)
