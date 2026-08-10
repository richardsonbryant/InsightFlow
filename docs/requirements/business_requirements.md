# Business Requirements

## Business Background

NovaCart mengalami pertumbuhan jumlah pelanggan yang cukup pesat, namun
loyalitas pelanggan tidak tumbuh sebanding. Banyak pelanggan hanya
bertransaksi satu kali lalu tidak kembali. Perusahaan membutuhkan
Customer Analytics Platform untuk meningkatkan retensi pelanggan.

## Business Objectives

-   Meningkatkan customer retention rate
-   Menurunkan customer churn rate
-   Mengidentifikasi high-value customer
-   Meningkatkan repeat purchase rate
-   Mendukung strategi retensi yang tersegmentasi

## Stakeholder Analysis

  Stakeholder                Kebutuhan
  -------------------------- ------------------------------------------
  CEO                        Ringkasan performa bisnis & tren retensi
  Marketing Manager          Segmentasi pelanggan
  Customer Success Manager   Pelanggan berisiko churn
  Data Analyst               Monitoring KPI

## KPI Definition

### Growth

-   Revenue
-   Total Orders
-   Average Order Value

### Customer

-   Active Customers
-   New vs Returning Customers
-   Retention Rate
-   Churn Rate

### Value

-   Customer Lifetime Value (CLV)
-   Segment Distribution

### Product

-   Best Selling Category
-   Repeat Purchase Rate per Category

## Business Questions

### Revenue & Growth

-   Bagaimana tren revenue bulanan?
-   Kategori apa penyumbang terbesar?

### Customer & Retention

-   Berapa persen pelanggan baru vs kembali?
-   Siapa pelanggan paling loyal?
-   Berapa banyak pelanggan berisiko churn?

### Churn

-   Karakteristik customer yang cenderung churn?
-   Faktor utama yang memengaruhi churn?

### Segmentation

-   Ada berapa segmen pelanggan?
-   Strategi terbaik untuk tiap segmen?

## Data Requirements

  Entity      Key Fields
  ----------- -----------------------------------------------------------
  Customers   customer_id, city, registration_date
  Orders      order_id, customer_id, order_date, total_amount, category
  Payments    payment_method, payment_value
  Reviews     rating, review_date

### Initial Business Assumption

Customer dianggap churn jika tidak melakukan transaksi selama 180 hari.
Definisi ini akan divalidasi kembali pada fase Dataset Assessment.

## Success Criteria

-   Dashboard menjawab seluruh business questions
-   Model churn memiliki recall yang baik
-   Setiap insight memiliki rekomendasi yang actionable
