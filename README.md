[README.md](https://github.com/user-attachments/files/32434624/README.md)

# Online Retail Customer & Revenue Analytics

End-to-end data analytics project on the UCI Online Retail dataset (541,000+ transactions, UK-based online gift shop, Dec 2010–Dec 2011). Covers SQL-based cleaning and analysis, RFM customer segmentation, market basket analysis, and a Power BI dashboard.


**Stack:** PostgreSQL· Excel · Power BI (DAX)

---

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Key Findings](#key-findings)
- [How This Was Built](#how-this-was-built)
  - [1. Data Cleaning](#1-data-cleaning)
  - [2. SQL Analysis](#2-sql-analysis)
  - [3. Excel](#3-excel)
  - [4. Power BI](#4-power-bi)
- [Deliverables](#deliverables)
- [Dataset](#dataset)
- [Author](#author)

---

## EXECUTIVE SUMMARY
Problem Statement
This project answers three questions for the business:

1. **Where does revenue actually come from** — which markets, which customers, which products?
2. **How valuable is a repeat customer**- compared to a one-time buyer, and can that be quantified?
3. **Where's the operational risk** — cancellations, order timing, customer churn?
   
The business shows a healthy top line but three structural risks sit underneath it:

1. **84.03% of revenue depends on a single market** (UK) — international sales (Netherlands, Ireland, Germany, France, Australia) make up just 15.9%
2. **34.42% of customers buy once and haven't returned** — they generate only £521K, next to £7.79M from repeat buyers
3. **The top 10% of customers (434 people) generate 61.38% of all revenue** — a customer-concentration risk as sharp as the geographic one

Built an end-to-end analytics pipeline demonstrating:

- **Data Engineering:** PostgreSQL cleaning pipeline (`raw_transactions` → `cleaned_transactions` view) with behavioral flags for cancellations, returns, and non-product line items
- **Customer Analytics:** RFM segmentation into 4 behavioral groups (Champion / Loyal / At Risk / Lost) using quartile scoring
- **Operational Analysis:** Cancellation rate reconciled two ways (16.12% by order count vs 8.41% by value) to catch a metric that looks different depending on how it's measured
- **Visualization:** Power BI dashboard across 4 pages — Business Performance, Sales Overview, Customer Segmentation, VIP & Retention

The raw data was never edited directly. All cleaning logic lives in a single SQL view, `cleaned_transactions`, so the transformation is transparent and repeatable filters like excluding cancellations or guest customers are applied per query rather than baked into separate layered views. From there, RFM segmentation and reporting were built in SQL, then modeled in Power BI with DAX measures for the dashboard layer.
## Business Impact

| Metric | Value |
|---|---|
| Revenue Concentration Risk | 84.03% from UK (£9.77M) |
| Retention Value Gap | Repeat customers generate ~15x more revenue than one-time buyers (£7.79M vs £521K) |
| VIP Revenue Concentration | Top 10% of customers (434 people) drive 61.38% of revenue |
| Core Segment Share | Loyal + Champion segments (67.9% of customers) generate 95.5% of revenue |
| Cancellation Rate | 16.12% of orders, but only 8.41% of value — cancelled orders skew smaller than average |


```
Data Pipeline: Raw → Cleaned → Analysis

Raw Source File (Online_Retail.xlsx, 541,910 rows)
    ↓
┌───────────────────────────────────────┐
│ RAW LAYER — raw_transactions           │
└───────────────────────────────────────┘
    ↓
┌───────────────────────────────────────┐
│ CLEANED LAYER — cleaned_transactions   │
└───────────────────────────────────────┘
    ↓
┌───────────────────────────────────────┐
│ ANALYSIS LAYER                         │
└───────────────────────────────────────┘
    ↓
┌───────────────────────────────────────┐
│ PRESENTATION LAYER                     │
└───────────────────────────────────────┘
```
### Where Each Layer Lives

| Pipeline Layer | Implemented In |
|---|---|
| Raw | [`data/Online_Retail.xlsx`](data/Online_Retail.xlsx) → [`sql/postgresql/01_schema.sql`](sql/postgresql/01_schema.sql) |
| Cleaned | [`sql/postgresql/02_data_exploration.sql`](sql/postgresql/02_data_exploration.sql), [`03_cleaned_transactions_view.sql`](sql/postgresql/03_cleaned_transactions_view.sql) |
| Analysis | [`04_rfm_segmentation.sql`](sql/postgresql/04_rfm_segmentation.sql), [`05_seasonality_and_basket.sql`](sql/postgresql/05_seasonality_and_basket.sql), [`06_product_pair_analysis.sql`](sql/postgresql/06_product_pair_analysis.sql) |
| Presentation | [`power-bi/uk_retail_store.pbix`](power-bi/uk_retail_store.pbix), [`dax_measures.md`](power-bi/dax_measures.md) |

## Repository Structure

```
online-retail-analytics/
├── README.md
├── data/
│   └── Online_Retail.xlsx          # raw dataset (541,910 rows)
├── sql/
│   ├── postgresql/
│   │   ├── 01_schema.sql
│   │   ├── 02_data_exploration.sql
│   │   ├── 03_cleaned_transactions_view.sql
│   │   ├── 04_rfm_segmentation.sql
│   │   ├── 05_seasonality_and_basket.sql
│   │   └── 06_product_pair_analysis.sql
│   └── mysql/
│       ├── 01_schema.sql
│       ├── 02_data_exploration.sql
│       ├── 03_cleaned_transactions_view.sql
│       ├── 04_rfm_segmentation.sql
│       ├── 05_seasonality_and_basket.sql
│       └── 06_product_pair_analysis.sql
├── excel/
│   └── excel_logic.md
├── power-bi/
│   ├── uk_retail_store.pbix        # the actual Power BI report
│   ├── data_model.md
│   └── dax_measures.md
└── docs/
    ├── technical_documentation.md
    ├── technical_documentation.docx    # original, with full screenshots
    └── stakeholder_report.md
```
`data/Online_Retail.xlsx` is the raw source file — the same one loaded into `raw_transactions` in `01_schema.sql`. It's committed here so the project is runnable end-to-end straight from the repo, without a separate download step.

## Key Findings

| Area | Finding |
|---|---|
| Market concentration | UK = 84.03% of revenue (£9.77M); Netherlands, Ireland, Germany, France, Australia are the strongest international markets |
| Retention | Repeat customers (65.58% of the base) generate £7.79M vs £521K from one-time buyers |
| RFM segmentation | Loyal + Champion segments (67% of customers) drive ~95% of revenue |
| VIP customers | Top 10% by spend (434 customers) generate 61.38% of total revenue |
| Cancellations | 16.12% of orders, but only 8.41% of sales value — cancelled orders run smaller than average |
| Average Order Value | £494.10, confirmed against the median (a small number of bulk orders pull the mean up) |
| Peak timing | Thursdays, around 12 noon |

Full write-up with recommendations: [`docs/stakeholder_report.md`](docs/stakeholder_report.md).

## Star Schema

**Fact Table:** `cleaned_transactions` (line-item grain — one row per product per invoice, not one row per order)

- Cancellation, return, and non-product flags pre-computed (`is_cancellation`, `is_return`, `is_non_product`)
- Revenue pre-calculated (`quantity * unit_price`)
- Zero/negative-price rows excluded at the view level

**Dimensions:**

- `Date` — generated calendar table (`Date`, `DayOfWeek`, `Month`, `Year`), joined on `invoice_date`
- `rfm_customers` — one row per customer, joined on `customer_id`

**Standalone (not related to the model):**

- `raw_transactions` — unmodified source table, queried independently only for the `Free Giveaway Units` measure

## How This Was Built

### 1. Data Cleaning

- Raw dataset kept untouched — all cleaning done in a single SQL view, `cleaned_transactions`, built on top of `raw_transactions`
- The view excludes `unit_price <= 0` rows entirely (2,521 rows — system errors, damage write-offs, and giveaways, not genuine sales); cancellations are flagged (`invoice_no LIKE 'C%'`), not deleted — 9,288 of the 541,909 rows (an earlier exploration check used the case-insensitive `ILIKE` to confirm no lowercase `c`-prefixed invoices existed)
- Two more flags carried through rather than filtered out: `is_return` (`quantity < 0` — overlaps with but isn't identical to cancellations) and `is_non_product` (postage/fee codes like `POST`, `DOT`, `BANK CHARGES` — excluded from product rankings but kept in revenue totals, since that money is real)
- Guest customers (null `customer_id`) — 135,080 rows (25%) — kept in `cleaned_transactions` for product/country analysis, excluded per-query wherever a report groups by customer (RFM needs a stable customer identity)

See [`sql/postgresql/02_data_exploration.sql`](sql/postgresql/02_data_exploration.sql) for the checks and [`sql/postgresql/03_cleaned_transactions_view.sql`](sql/postgresql/03_cleaned_transactions_view.sql) for the view itself.

### 2. SQL Analysis

- **RFM segmentation** — Recency, Frequency, Monetary scoring using `NTILE(4)` (quartiles), summed into a score out of 12 and mapped to Champion / Loyal / At Risk / Lost, materialized as the `rfm_customers` table
- **Seasonality & basket reports** — revenue by month, weekday, and hour of day, plus average order value, items per basket, and cancellation rate (by order count and by value)
- **Product-pair analysis** — self-join on `invoice_no` (top 20 by co-occurrence count) to find products frequently bought together — co-occurrence counting, not full association-rule mining

### 3. Excel

Excel (`data/Online_Retail.xlsx`) was used for a first-pass exploratory look at the raw data before it was loaded into SQL — pivot tables for a rough sense of country and monthly revenue splits, and to sanity-check the SQL output against a second, independent calculation method. Logic and formulas: [`excel/excel_logic.md`](excel/excel_logic.md).

### 4. Power BI

The full report is in [`power-bi/uk_retail_store.pbix`](power-bi/uk_retail_store.pbix) — open it in Power BI Desktop to explore.

- Star schema: `cleaned_transactions` (fact table) related to `Date` and `rfm_customers` (dimension tables); `raw_transactions` imported separately and left unrelated, used only by the `Free Giveaway Units` measure
- DAX measures for revenue, AOV, cancellation rate by value (vs by order count), a median order value based on `PERCENTILE.INC` over customer lifetime spend, a VIP threshold (90th percentile of spend), and a repeat-customer rate used as a cross-check against the RFM segmentation
- Full measure list and model relationships: [`power-bi/dax_measures.md`](power-bi/dax_measures.md) and [`power-bi/data_model.md`](power-bi/data_model.md)

## Deliverables

- [`docs/stakeholder_report.md`](docs/stakeholder_report.md) — plain-language report for a non-technical audience, findings + recommendations
- [`docs/technical_documentation.md`](docs/technical_documentation.md) — methodology, schema, and design decisions for a technical reviewer (a markdown transcription of the original Word doc, for GitHub readability)
- [`docs/technical_documentation.docx`](docs/technical_documentation.docx) — the original document, with full pgAdmin and Power BI screenshots

## Dataset

[UCI Machine Learning Repository — Online Retail Data Set](https://archive.ics.uci.edu/dataset/352/online+retail). Transactions for a UK-based, registered non-store online retailer, 01/12/2010–09/12/2011, selling mainly unique all-occasion gifts. Included in this repo at `data/Online_Retail.xlsx`.

> **Note on repo size:** the dataset is ~23 MB. That's well under GitHub's hard 100 MB file limit, but if you clone this repo as a starting point for your own fork and plan to add much more binary data (larger exports, additional `.pbix` versions), consider [Git LFS](https://git-lfs.com/) rather than committing large files directly.

## Author

**Fanan Kwanga** — Data & Operations Analyst
