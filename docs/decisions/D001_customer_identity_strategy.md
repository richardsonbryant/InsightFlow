# D001 — Customer Identity Strategy

| Metadata     | Value              |
| ------------ | ------------------ |
| Status       | Accepted           |
| Date         | 2026-08-10         |
| Phase        | Dataset Assessment |
| Category     | Data Modeling      |
| Impact Level | High               |

---

# Context

Dataset Olist menyediakan dua atribut yang berkaitan dengan identitas pelanggan, yaitu `customer_id` dan `customer_unique_id`.

Hasil data profiling menunjukkan:

| Metric                      |  Value |
| --------------------------- | -----: |
| Total Records               | 99,441 |
| Unique `customer_id`        | 99,441 |
| Unique `customer_unique_id` | 96,096 |

Analisis lebih lanjut terhadap distribusi `customer_id` pada setiap `customer_unique_id` menghasilkan temuan berikut.

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

Hasil profiling menunjukkan bahwa sekitar **3.12% pelanggan memiliki lebih dari satu `customer_id`**.

Dengan demikian, `customer_id` tidak dapat diasumsikan sebagai representasi tunggal pelanggan pada level bisnis. Sebaliknya, `customer_unique_id` mampu menghubungkan beberapa `customer_id` yang berasal dari pelanggan yang sama.

Temuan ini konsisten dengan dokumentasi resmi Olist, yang menyatakan bahwa
`customer_id` merepresentasikan instance pelanggan per order, sedangkan
`customer_unique_id` merepresentasikan pelanggan yang sama lintas beberapa order. [1]

InsightFlow merupakan Customer Analytics Platform yang berfokus pada analisis perilaku pelanggan, seperti Customer Segmentation, Repeat Purchase Analysis, Customer Lifetime Value (CLV), Customer Retention, dan Customer Churn. Seluruh analisis tersebut membutuhkan representasi pelanggan yang konsisten di seluruh histori transaksi.

---

# Problem

Identifier pelanggan mana yang harus digunakan sebagai representasi utama (**business identifier**) agar seluruh analisis customer-level menghasilkan metrik yang konsisten, akurat, dan dapat dipertanggungjawabkan?

---

# Alternatives Considered

## Option A — Use `customer_id`

### Advantages

- Mengikuti struktur asli dataset Olist.
- Seluruh foreign key pada dataset secara langsung menggunakan `customer_id`.
- Join antar tabel relatif lebih sederhana.

### Disadvantages

- Riwayat transaksi pelanggan dapat terpecah apabila satu `customer_unique_id` memiliki lebih dari satu `customer_id`.
- Metrik customer-level seperti Repeat Purchase, RFM, CLV, Retention, dan Churn berpotensi menghasilkan representasi pelanggan yang tidak konsisten.

---

## Option B — Use `customer_unique_id`

### Advantages

- Seluruh histori transaksi pelanggan dapat direpresentasikan sebagai satu entitas.
- Konsisten dengan kebutuhan analisis customer-level.
- Mendukung seluruh KPI utama pada Business Requirement InsightFlow.

### Disadvantages

- Membutuhkan proses mapping melalui tabel Customers sebelum analisis dilakukan.
- Menambah sedikit kompleksitas pada proses ETL dibanding menggunakan `customer_id` secara langsung.

---

# Decision

InsightFlow mengadopsi **Hybrid Customer Identity Strategy**.

Keputusan yang diambil adalah sebagai berikut:

- **Raw Layer** tetap mempertahankan struktur asli dataset Olist tanpa perubahan.
- `customer_id` tetap digunakan sebagai **technical identifier** untuk menjaga integritas relasi antar tabel.
- **Analytics Layer** menggunakan `customer_unique_id` sebagai **business identifier** untuk seluruh analisis customer-level.

Pada scope MVP, **tidak dibuat surrogate key tambahan**. `customer_unique_id` digunakan secara langsung sebagai representasi pelanggan pada layer analitik karena telah memenuhi seluruh kebutuhan bisnis dan tidak terdapat requirement yang mengharuskan penggunaan surrogate key.

---

# Decision Rationale

Walaupun hanya sekitar **3.12% pelanggan** memiliki lebih dari satu `customer_id`, keberadaan pelanggan tersebut berdampak langsung terhadap seluruh analisis customer-level.

Apabila `customer_id` digunakan sebagai identifier utama, histori transaksi pelanggan tersebut akan terpecah menjadi beberapa entitas sehingga menghasilkan perhitungan yang tidak konsisten untuk:

- Repeat Purchase Rate
- Customer Lifetime Value (CLV)
- RFM Analysis
- Customer Retention
- Customer Churn

Sebaliknya, penggunaan `customer_unique_id` memungkinkan seluruh histori transaksi pelanggan direpresentasikan sebagai satu entitas tanpa mengubah struktur data mentah.

Alternatif penggunaan surrogate key juga dipertimbangkan. Namun, berdasarkan scope MVP InsightFlow, tidak ditemukan kebutuhan yang mengharuskan implementasi tersebut. Dataset yang digunakan relatif kecil (~100 ribu pelanggan), tidak memiliki requirement Slowly Changing Dimension (SCD), serta tidak membutuhkan optimasi data warehouse tingkat production. Oleh karena itu, penambahan surrogate key dinilai hanya akan menambah kompleksitas ETL tanpa memberikan manfaat yang sebanding pada fase MVP.

---

# Consequences

Keputusan ini menjadi standar untuk seluruh komponen InsightFlow.

## Database Design

- Struktur raw database tetap mengikuti dataset Olist.
- Analytics layer menggunakan `customer_unique_id` sebagai representasi pelanggan.

## ETL Pipeline

- ETL melakukan mapping antara `customer_id` dan `customer_unique_id`.
- Seluruh feature customer dibangun berdasarkan `customer_unique_id`.

## SQL Analytics

Seluruh query customer-level menggunakan:

- `GROUP BY customer_unique_id`

bukan:

- `GROUP BY customer_id`

## Dashboard

Seluruh KPI customer dihitung menggunakan `customer_unique_id`, termasuk:

- Active Customer
- Returning Customer
- Customer Retention
- Customer Churn
- Customer Lifetime Value
- Customer Segmentation

## Machine Learning

Seluruh feature engineering pada level pelanggan menggunakan `customer_unique_id` sebagai entity utama.

---

# Impact

### Affected Components

- Database Design
- ETL Pipeline
- SQL Analytics
- Dashboard
- Machine Learning

### Related Decisions

None (First Architectural Decision)

---

# Next Action

Tahap selanjutnya adalah mengevaluasi kualitas atribut pelanggan pada setiap `customer_unique_id` sebagai bagian dari Data Quality Assessment. Hasil evaluasi tersebut akan digunakan sebagai dasar penyusunan Database Design dan ETL Pipeline.

# References

[1] Olist, Brazilian E-Commerce Public Dataset by Olist — Data Description.
Kaggle. Diakses 11 Agustus 2026.
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/data
