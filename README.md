# InsightFlow

> **An end-to-end Customer Analytics Platform built using the Olist Brazilian E-Commerce Dataset.**

![Status](https://img.shields.io/badge/Status-In%20Progress-orange)
![Phase](https://img.shields.io/badge/Current%20Phase-Database%20Design-blue)
![Python](https://img.shields.io/badge/Python-3.13-blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-blue)
![License](https://img.shields.io/badge/License-MIT-green)

---

# Project Overview

InsightFlow is an end-to-end data analytics project that demonstrates how raw transactional data can be transformed into reliable business insights through a structured analytics workflow.

Rather than focusing solely on dashboards or machine learning models, this project emphasizes the complete analytical lifecycle—from business understanding and dataset assessment to database design, ETL, SQL analytics, dashboard development, and explainable machine learning.

The project is developed incrementally, with each phase documented through notebooks, technical reports, and Architecture Decision Records (ADR).

---

# Business Problem

E-commerce companies generate large volumes of transactional data every day. However, raw operational data often contains structural inconsistencies, business ambiguities, and data quality issues that must be resolved before meaningful analytics can be performed.

Many analytics portfolio projects begin directly with dashboard creation or machine learning without demonstrating how analytical data assets are prepared.

InsightFlow addresses this gap by documenting the complete analytical workflow—from understanding business requirements to producing explainable analytical models.

---

# Project Objectives

The project aims to:

- Build a production-inspired analytics workflow
- Design an analytical PostgreSQL database
- Develop reusable SQL analytics
- Create interactive business dashboards
- Engineer customer-level analytical features
- Build machine learning models for customer analytics
- Document important technical decisions using Architecture Decision Records (ADR)

---

# Dataset

**Dataset Source**

Olist Brazilian E-Commerce Public Dataset

The dataset contains nine relational tables covering the complete customer purchasing lifecycle, including:

- Customers
- Orders
- Order Items
- Payments
- Reviews
- Products
- Sellers
- Geolocation
- Product Category Translation

Business Domain:

- Customer Analytics
- Sales Analytics
- Logistics Analytics
- E-Commerce Analytics

---

# Current Progress

## Phase 1 — Dataset Acquisition & Assessment

### Requirements

- [x] Company Overview
- [x] Product Vision
- [x] Business Requirements
- [x] Functional Requirements
- [x] Non-Functional Requirements
- [x] Dataset Strategy

### Dataset Assessment

- [x] Data Profiling
- [x] Dataset Assessment
- [x] Dataset Assessment Report
- [x] Data Quality Report
- [x] Data Dictionary

### Architecture Decision Records

- [x] D001 — Customer Identity Strategy
- [x] D002 — Order Timeline Strategy
- [x] D003 — Payment Record Anomaly Strategy

---

## Phase 2 — Database Design

- [ ] Business Entity Identification
- [ ] ER Diagram
- [ ] Relational Schema
- [ ] PostgreSQL Database
- [ ] Constraints
- [ ] Indexing Strategy

---

## Phase 3 — ETL Pipeline

- [ ] Data Cleaning
- [ ] Feature Engineering
- [ ] ETL Pipeline
- [ ] Data Validation

---

## Phase 4 — SQL Analytics

- [ ] Customer Analytics
- [ ] Sales Analytics
- [ ] Product Analytics
- [ ] Logistics Analytics

---

## Phase 5 — Dashboard Development

- [ ] KPI Dashboard
- [ ] Customer Dashboard
- [ ] Sales Dashboard

---

## Phase 6 — Machine Learning

- [ ] Customer Segmentation
- [ ] Churn Prediction
- [ ] Explainable AI (SHAP)

---

# Project Workflow

```text
Business Understanding
        │
        ▼
Dataset Profiling
        │
        ▼
Dataset Assessment
        │
        ▼
Architecture Decisions (ADR)
        │
        ▼
Database Design
        │
        ▼
ETL Pipeline
        │
        ▼
SQL Analytics
        │
        ▼
Dashboard Development
        │
        ▼
Machine Learning
```

---

# Repository Structure

```text
InsightFlow/
│
├── assets/
├── data/
│   ├── raw/
│   └── processed/
│
├── docs/
│   ├── requirements/
│   ├── decisions/
│   ├── assessments/
│   └── architecture/
│
├── notebooks/
│   ├── 00_data_profiling.ipynb
│   └── 01_dataset_assessment.ipynb
│
├── sql/
│
├── README.md
└── requirements.txt
```

---

# Documentation

The project documentation is organized into four categories.

| Folder              | Description                                       |
| ------------------- | ------------------------------------------------- |
| `docs/requirements` | Business requirements and project planning        |
| `docs/assessments`  | Dataset assessment and data quality documentation |
| `docs/decisions`    | Architecture Decision Records (ADR)               |
| `notebooks`         | Exploratory analysis and investigation notebooks  |

---

# Technologies

- Python
- Pandas
- PostgreSQL
- SQL
- Jupyter Notebook
- Power BI
- Git
- GitHub

---

# Current Status

**Current Phase**

🟦 **Phase 2 — Database Design**

Phase 1 (Dataset Acquisition & Assessment) has been completed successfully.

The next milestone is designing the analytical database that will support ETL, SQL analytics, dashboards, and machine learning.

---

# Roadmap

| Phase                                      | Status         |
| ------------------------------------------ | -------------- |
| Phase 1 — Dataset Acquisition & Assessment | ✅ Completed   |
| Phase 2 — Database Design                  | 🔄 In Progress |
| Phase 3 — ETL Pipeline                     | ⏳ Planned     |
| Phase 4 — SQL Analytics                    | ⏳ Planned     |
| Phase 5 — Dashboard Development            | ⏳ Planned     |
| Phase 6 — Machine Learning                 | ⏳ Planned     |

---

# Author

**Richardson Bryant**

Computer Science Student

Data Analytics Portfolio Project
