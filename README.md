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
<img width="875" height="531" alt="image" src="https://github.com/user-attachments/assets/04d28a3b-f283-4c2c-b027-40dcce5fc9ca" />

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

## How This Was Built

### 1. Data Cleaning

- Raw dataset kept untouched — all cleaning done in a single SQL view, `cleaned_transactions`, built on top of `raw_transactions`
- The view excludes `unit_price <= 0` rows entirely (2,521 rows — system errors, damage write-offs, and giveaways, not genuine sales); cancellations are flagged (`invoice_no LIKE 'C%'`), not deleted — 9,288 of the 541,909 rows (an earlier exploration check used the case-insensitive `ILIKE` to confirm no lowercase `c`-prefixed invoices existed)
- Two more flags carried through rather than filtered out: `is_return` (`quantity < 0` — overlaps with but isn't identical to cancellations) and `is_non_product` (postage/fee codes like `POST`, `DOT`, `BANK CHARGES` — excluded from product rankings but kept in revenue totals, since that money is real)
- Guest customers (null `customer_id`) — 135,080 rows (25%) — kept in `cleaned_transactions` for product/country analysis, excluded per-query wherever a report groups by customer (RFM needs a stable customer identity)

See [`sql/postgresql/02_data_exploration.sql`](sql/postgresql/02_data_exploration.sql) for the checks and [`sql/postgresql/03_cleaned_transactions_view.sql`](sql/postgresql/03_cleaned_transactions_view.sql) for the view itself.

### 2. SQL Analysis

- **RFM segmentation** — Recency, Frequency, Monetary scoring using `NTILE(4)` (quartiles), summed into a score out of 12 and mapped to Champion / Loyal / At Risk / Lost, materialized as the `rfm_customers` table

## Segment Profiles
```
| Segment | Customers | % of Base | Avg Revenue | Avg Orders | Description |
|---|---|---|---|---|---|
| Loyal | 2,375 | 54.75% | £2,711.38 | 5.40 | Core repeat buyers, consistent order frequency |
| Champion | 567 | 13.07% | £3,649.82 | 6.75 | Highest value and highest frequency — best customers |
| At Risk | 1,344 | 30.98% | £292.45 | 1.35 | Low engagement, minimal repeat behavior |
| Lost | 52 | 1.2% | £180.24 | 1.00 | Disengaged, essentially single-purchase |
```
**Total customers analyzed:** 4,338
## Insights

**1. Revenue Concentration**

- Loyal + Champion customers: 2,942 people (67.82% of the base) generate £8.51M (95.48% of total revenue)
- At Risk + Lost customers: 1,396 people (32.18% of the base) generate only £402K (4.52% of total revenue)
- This mirrors the separate retention finding: 65.58% of customers are repeat buyers, generating £7.79M vs £521K from one-time buyers

**2. Segment Opportunities**

- **Loyal (54.75% of customers):** The core of the business — 5.40 average orders per customer, £2,711.38 average revenue. Priority: retention, not acquisition
- **Champion (13.07%):** Smaller group but the highest per-customer value (£3,649.82, 6.75 avg orders) — the natural VIP program target
- **At Risk (30.98%):** Large, low-engagement group (1.35 avg orders, £292.45 avg revenue) — win-back campaign candidates before they slide into Lost
- **Lost (1.2%):** Smallest segment, essentially single-purchase customers (1.00 avg orders) who have disengaged — low near-term recovery priority given the small base

**3. Revenue Distribution**

- Champion customers punch above their size: 13.07% of customers, 23.22% of revenue
- At Risk customers punch below their size: 30.98% of customers, only 4.41% of revenue
- Loyal is both the largest segment and the largest revenue contributor — the segment most worth protecting

- **Seasonality & basket reports** — revenue by month, weekday, and hour of day, plus average order value, items per basket, and cancellation rate (by order count and by value)
- **Product-pair analysis** — self-join on `invoice_no` (top 20 by co-occurrence count) to find products frequently bought together — co-occurrence counting, not full association-rule mining

### 3. Excel

Excel (`data/Online_Retail.xlsx`) was used for a first-pass exploratory look at the raw data before it was loaded into SQL — pivot tables for a rough sense of country and monthly revenue splits, and to sanity-check the SQL output against a second, independent calculation method. Logic and formulas: [`excel/excel_logic.md`](excel/excel_logic.md).

### 4. Power BI

## Power BI Dashboard

### Semantic Model

**Architecture:** Star schema — `cleaned_transactions` as the fact table, related to `Date` and `rfm_customers` as dimensions; `raw_transactions` imported separately and left unrelated.

**Key relationships:**
- `Date[Date]` → `cleaned_transactions[invoice_date]` (1:Many)
- `rfm_customers[customer_id]` → `cleaned_transactions[customer_id]` (1:Many)
- `raw_transactions` — no relationships (queried independently for `Free Giveaway Units` only)

**Critical decisions:**
- Cleaning logic (`is_cancellation`, `is_return`, `is_non_product` flags) lives in a single SQL view, not duplicated across Power BI tables
- `raw_transactions` kept unrelated on purpose — connecting it would risk double-counting rows that `cleaned_transactions` deliberately excludes
- RFM scoring computed once in SQL (`rfm_customers`), not recalculated live in DAX, so segment boundaries stay fixed regardless of report filters

### Dashboard Pages

### Page 1: Corporate Revenue & Market Performance

- **KPIs:** Total Revenue (£9.77M), Total Customers (4K), Revenue Outside UK (£1.56M), Revenue Inside UK (£8.21M)
- Top 10 high-value products by net sales revenue
- Top international markets by sales volume (Netherlands, Ireland, Germany, France, Australia)
- Hourly order velocity — confirms the noon peak
  
<img width="1136" height="611" alt="Screenshot 2026-08-20 220751" src="https://github.com/user-attachments/assets/ec50d57d-49c7-4d59-952d-78acf38e9a3c" />

### Page 2: Customer Loyalty & RFM Segmentation — Segment View

- Share of total customers by RFM segment: Loyal (54.75%), At Risk (30.98%), Champion (13.07%), Lost (1.2%)
- Financial contribution by segment: Loyal (£6.44M, 72.26%), Champion (£2.07M, 23.22%), At Risk (£0.39M, 4.41%), Lost (0.11%)
- Segment profile table with recency/frequency/monetary averages per segment

<img width="1140" height="612" alt="Screenshot 2026-08-20 220928" src="https://github.com/user-attachments/assets/86678319-06f1-4dee-88b3-abda2f38f6d9" />


### Page 3: Customer Loyalty & RFM Segmentation — VIP & Retention View

- **KPIs:** Total Revenue (£9.77M), VIP Revenue (£5.47M), VIP Customer Count (434), VIP % of Customer Revenue (61.38%)
- Audience retention health: Repeat Customers (2.85K, 65.58%) vs One-Time Customers (1.49K, 34.42%)
- Daily sales metrics: orders and revenue by day of week (Thursday highest)

<img width="1147" height="602" alt="Screenshot 2026-08-20 220947" src="https://github.com/user-attachments/assets/a82f155d-8733-4239-b91c-b7bd9d894c8e" />


### Page 4: Fulfillment, Timing & Logistics

- **KPIs:** Avg Order Value (£494.10), Median Order Value (£303.84), Free Giveaway Units (17K)
- Inventory leakage: top products given away at zero/negative price (16,696 units total)
- Top 10 returned/cancelled products by rate
- B2B matrix: bundle purchase counts by product (Regency Cakestand, Jumbo Bag Red Retrospot, White Hanging Heart T-Light Holder lead)

<img width="1147" height="617" alt="Screenshot 2026-08-20 221005" src="https://github.com/user-attachments/assets/3d802bea-06df-4b21-a614-f578dab7e106" />

## Deliverables

- [`docs/stakeholder_report.md`](docs/stakeholder_report.md) — plain-language report for a non-technical audience, findings + recommendations
- [`docs/technical_documentation.md`](docs/technical_documentation.md) — methodology, schema, and design decisions for a technical reviewer (a markdown transcription of the original Word doc, for GitHub readability)
- [`docs/technical_documentation.docx`](docs/technical_documentation.docx) — the original document, with full pgAdmin and Power BI screenshots

## Dataset

[UCI Machine Learning Repository — Online Retail Data Set](https://archive.ics.uci.edu/dataset/352/online+retail). Transactions for a UK-based, registered non-store online retailer, 01/12/2010–09/12/2011, selling mainly unique all-occasion gifts. Included in this repo at `data/Online_Retail.xlsx`.

> **Note on repo size:** the dataset is ~23 MB. That's well under GitHub's hard 100 MB file limit, but if you clone this repo as a starting point for your own fork and plan to add much more binary data (larger exports, additional `.pbix` versions), consider [Git LFS](https://git-lfs.com/) rather than committing large files directly.

## Author

**Fanan Kwanga** — Data & Operations Analyst
