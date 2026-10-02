<div align="center">

# 🛒 Olist E-Commerce Sales & Operations Intelligence

**An end-to-end business analytics project: Python → SQL Server → interactive Dash dashboard**

![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)
![Pandas](https://img.shields.io/badge/Pandas-150458?logo=pandas&logoColor=white)
![NumPy](https://img.shields.io/badge/NumPy-013243?logo=numpy&logoColor=white)
![SQL Server](https://img.shields.io/badge/SQL_Server-CC2927?logo=microsoftsqlserver&logoColor=white)
![T-SQL](https://img.shields.io/badge/T--SQL-SSMS-5C2D91)
![Plotly](https://img.shields.io/badge/Plotly-3F4F75?logo=plotly&logoColor=white)
![Dash](https://img.shields.io/badge/Dash-008DE4?logo=plotly&logoColor=white)
![Seaborn](https://img.shields.io/badge/Seaborn-4C72B0)

</div>

---

## 📌 Project Objective

Analyze the **Olist Brazilian E-Commerce dataset** to understand sales, customers, product categories, logistics, delivery performance, freight cost and customer satisfaction, and present the findings in a live dashboard.

- Built an **end-to-end business analytics pipeline** using Python, SQL Server and Plotly Dash.
- Focused on **practical business insights**, not machine learning or NLP.

<p align="center">
  <img src="images/dashboard_page1.png" alt="Olist E-Commerce Intelligence dashboard" width="640"/>
</p>

---

## 🗂️ Dataset

[Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce): about 100,000 orders from 2016 to 2018 across 9 relational CSV files.

| Table | Rows | Columns |
|---|---:|---:|
| customers | 99,441 | 5 |
| orders | 99,441 | 8 |
| order_items | 112,650 | 7 |
| products | 32,951 | 9 |
| sellers | 3,095 | 4 |
| payments | 103,886 | 5 |
| reviews | 99,224 | 7 |
| geolocation | 1,000,163 | 5 |
| category_translation | 71 | 2 |

The raw CSVs are not included in this repository. Download them from Kaggle and place them in a `raw_data/` folder.

---

## 🔄 Pipeline

```text
Raw CSVs ─► Cleaning & feature engineering (Pandas) ─► EDA (Matplotlib / Seaborn)
         ─► Load into SQL Server (SQLAlchemy + PyODBC) ─► T-SQL business analysis
         ─► Interactive dashboard (Plotly Dash, reading from SQL Server)
```

### 1. Data Understanding
- Studied the grain of each table and how they relate (orders, customers, products, sellers, order items, payments, reviews, geolocation, category translations).
- Identified the need to **avoid duplicate revenue** when joining order-level and item-level data. Item and payment values are aggregated per order *before* joining.

### 2. Data Cleaning & Preprocessing
- Converted order and delivery columns to proper `datetime`.
- Investigated missing values and duplicates. The only duplicated table was `geolocation` (261,831 duplicate rows).
- **Kept legitimate missing delivery dates** instead of imputing them. Cross-tabulating against `order_status` showed that most are canceled, unavailable or still-shipping orders.
- **Flagged, rather than deleted, delivery-time outliers** (above the 99th percentile, 46 days; 965 orders).
- Translated Portuguese product categories to English (unmapped categories labelled `unknown`).
- Produced two analytical datasets: an **order-level** table (99,441 rows) and an **item-level** table (112,650 rows).

### 3. Feature Engineering

| Feature | Definition |
|---|---|
| `delivery_days` | Purchase → customer delivery, in days |
| `delivery_delay_days` | Delivery date − estimated date (negative = early) |
| `is_late` | Late-delivery indicator (null if not delivered) |
| `delivery_outlier` | Delivery time above the 99th percentile |
| `product_revenue` | Sum of item prices per order |
| `freight_value` | Sum of freight per order |
| `total_order_value` | Product revenue + freight |
| `freight_ratio` | Freight ÷ product revenue |
| `order_month` | Monthly order period |

### 4. Python EDA
Pandas, NumPy, Matplotlib and Seaborn were used to analyze revenue trends, order volume, category performance, state-wise sales, delivery-time distribution, delivery performance, review scores and freight burden.

### 5. SQL Server Integration
- Created an **`Olist_Analytics`** database in Microsoft SQL Server.
- Connected Python to SQL Server with **SQLAlchemy** and **PyODBC**.
- Loaded `order_analysis` and `order_items_analysis` as analytical tables, then verified table structures and row counts.

### 6. SQL Business Analysis (T-SQL)
Covers revenue and AOV, monthly sales, category and state performance, delivery performance, freight and customer analysis, using:

`GROUP BY` · `COUNT(DISTINCT)` · `CASE` · `HAVING` · **CTEs** · `RANK()` · date functions · aggregations · business KPI calculations

### 7. Interactive Dashboard (Plotly Dash)
Connected directly to the SQL Server analytical tables. It includes:

- **KPIs**: total revenue, total orders, AOV, average rating, on-time delivery %
- **Charts**: monthly revenue trend, top categories, top states, delivery performance, review distribution, freight burden by category, revenue vs freight

<p align="center">
  <img src="images/dashboard_page2.png" alt="Dashboard: review distribution and revenue vs freight burden" width="640"/>
</p>

---

## 📊 Key Numbers

**Python analysis (all 99,441 orders)**

| Metric | Value |
|---|---:|
| Unique customers | 96,096 |
| Product revenue | R$ 13.59M |
| Freight | R$ 2.25M |
| Average order value (product revenue ÷ orders) | R$ 136.68 |
| Average review score | 4.09 / 5 |
| Average delivery time | 12.56 days (median 10.22) |
| Average delivery vs. estimate | 11.2 days early |

**Dashboard KPIs (delivered orders only)**

| Metric | Value |
|---|---:|
| Orders | 96,478 |
| Revenue | R$ 13.22M |
| Average rating | 4.16 / 5 |
| On-time / early delivery | **91.9%** (8.1% late) |

---

## 📈 EDA Visuals

### Sales & revenue overview
<p align="center">
  <img src="images/eda_sales_overview.png" alt="Sales and revenue overview" width="760"/>
</p>

### Operations & customer experience
<p align="center">
  <img src="images/eda_operations_cx.png" alt="Operations and customer experience" width="760"/>
</p>

### Category performance
<p align="center">
  <img src="images/eda_category_performance.png" alt="Category performance analysis" width="760"/>
</p>

---

## 💡 Business Insights

- **Revenue grew strongly through 2017 and into 2018**, with several months near R$1M. The drop to almost zero in Sep–Oct 2018 reflects the end of the dataset's observation window, not a business decline, so those months should be excluded from growth conclusions.
- **Revenue is concentrated in a few categories**: health_beauty, watches_gifts, bed_bath_table, sports_leisure and computers_accessories lead.
- **São Paulo (SP) dominates** revenue by a wide margin, followed by RJ and MG, which makes state-level logistics planning important.
- **Most delivered orders arrive on time or early** (91.9%), typically about 12 days ahead of the estimate.
- **Customer ratings are generally positive**, but the sizeable 1-star segment is worth investigating against late deliveries and freight.
- **Freight burden varies a lot by category.** Among top-revenue categories, office_furniture, furniture_decor and housewares carry the highest freight-to-revenue ratio (roughly 23–25%), while watches_gifts is lowest (about 8%).
- **Delivery delays and high-freight categories** are the main areas for operational investigation.

---

## 🧰 Tech Stack

| Area | Tools |
|---|---|
| Programming & analysis | Python, Pandas, NumPy |
| Visualization | Matplotlib, Seaborn, Plotly |
| Database | Microsoft SQL Server, SSMS, T-SQL |
| Connectivity | SQLAlchemy, PyODBC |
| Dashboard | Plotly Dash |

---

## 🚀 Getting Started

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd <your-repo-folder>

# 2. Install dependencies
pip install pandas numpy matplotlib seaborn plotly dash sqlalchemy pyodbc

# 3. Add the Kaggle CSVs to ./raw_data and run the notebook
jupyter notebook Analytics_project.ipynb

# 4. Run the dashboard (needs SQL Server with the Olist_Analytics database loaded)
python app.py
# opens at http://127.0.0.1:8050
```

**Requirements:** Microsoft SQL Server (Express works), SSMS, and the **ODBC Driver 17 for SQL Server**. Update the `server` name in the connection string to match your own instance.

> If your dashboard file is named differently, adjust step 4.

---

## 📁 Project Structure

```text
├── Analytics_project.ipynb     # Cleaning, feature engineering, EDA, SQL Server load
├── app.py                      # Plotly Dash dashboard
├── sql/                        # T-SQL business analysis queries
├── outputs/tables/             # Cleaned datasets and data-quality reports
├── images/                     # Screenshots used in this README
└── README.md
```

---

## 🔮 Future Work

- Customer segmentation and repeat-purchase analysis.
- Seller performance and delivery-delay root-cause analysis.
- Deploy the dashboard publicly.

---

<div align="center">

Olist E-Commerce Analytics | Python • SQL Server • Pandas • Plotly • Dash

</div>
