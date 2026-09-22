# Technical Documentation

> This is a markdown transcription of [`technical_documentation.docx`](technical_documentation.docx) for readability on GitHub. The original Word document has the full screenshots (pgAdmin queries, Power BI Model view, DAX formula screenshots, dashboard pages); this version carries the same content and figures in text form.

## Executive Summary

This project analyzes 541,909 transactions from a UK-based online gift retailer (Dec 2010–Dec 2011) to identify revenue drivers, customer value, and operational risk. Data was cleaned and modeled in PostgreSQL, then visualized in Power BI using DAX measures across four dashboard pages. Key findings include an 84.03% UK revenue concentration, a small customer segment (Loyal + Champion, driving over 95% of revenue) responsible for the majority of value, and clear operational patterns (Thursday/midday peak volume) that inform staffing and marketing timing.

## Project Overview

### Introduction

This project sits in the e-commerce and retail space — specifically online gift and homeware sales, with both everyday individual customers (B2C) and some smaller wholesale buyers (B2B) mixed in. The dataset is transactional and order-level: each row is one product bought on one invoice, showing what was purchased, how much, at what price, when, by whom, and where it shipped. It's the kind of data a retail analyst or BI team would work with day to day, so the skills used here (cleaning, segmentation, product analysis, dashboarding) carry over directly to similar roles in retail, DTC, or marketplace businesses.

### Problem Statement

This project set out to answer a defined set of business questions across three stakeholder roles, using the retail transaction dataset as the source of truth.

**Revenue & Sales Performance (CEO)**
- Which products drive the highest total revenue, and which sell the highest volume?
- What are the busiest months, days, and hours for sales, to inform server capacity and support staffing?
- Which countries generate the most revenue outside the UK, and where might a local distribution center make sense?
- What percentage of total revenue relies solely on the UK, and how exposed is the business to a single-market downturn?

**Marketing & Customer Behavior (Marketing Director)**
- What is the customer retention rate — how many customers buy once versus multiple times?
- Who are the VIP customers (top 10% by total spend), and how can they be targeted for a loyalty program?
- What specific hours of the day do transactions peak, to inform promotional email timing?
- What specific days of the week generate the highest sales, to inform weekend ad spend decisions?

**Inventory & Operations (Operations Manager)**
- Which products have the highest cancellation/return rates?
- What is the average order value, and does it reflect customers buying many cheap items or a few expensive ones?
- Which products are frequently bought together, to support a "frequently bought together" recommendation feature?
- Which days of the week see the highest physical volume of items shipped, to inform warehouse staffing?
- How much revenue is lost to free transactions (items processed at £0.00 due to samples or system errors)?

### Dataset Summary

- **Source:** UCI Machine Learning Repository — Online Retail dataset
- **Size:** 541,909 transaction line items, 8 columns
- **Timeframe:** December 1, 2010 – December 9, 2011
- **Grain:** one row per product line item per invoice (not one row per order)
- **Columns:** InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country

### Data Dictionary

| Column | Data Type | Description |
|---|---|---|
| InvoiceNo | Text | Unique identifier for each order. Invoices starting with "C" indicate a cancelled order. |
| StockCode | Text | Unique identifier for each product. A small number of non-product codes exist (e.g. POST, DOT, M, BANK CHARGES) representing postage, manual adjustments, or fees rather than physical goods. |
| Description | Text | The name of the product. Some rows have a missing description (1,454 rows). |
| Quantity | Whole Number | Number of units purchased in that line item. Negative values indicate a return or cancellation. |
| InvoiceDate | Date/Time | The date and time the transaction occurred. |
| UnitPrice | Decimal Number | Price per unit, in GBP (£). Zero or negative values indicate free giveaways, samples, or data/system adjustments rather than genuine sales. |
| CustomerID | Whole Number | Unique identifier for the customer. Missing for guest checkouts (~25% of rows). |
| Country | Text | The country the order was shipped to. 38 distinct countries are present, with the United Kingdom accounting for the large majority of transactions. |

### Tools Used

| Tool | Role | Why |
|---|---|---|
| Excel | Initial exploration | Fast way to eyeball nulls, outliers, and value ranges before committing to a cleaning approach |
| PostgreSQL | Cleaning & analysis | Reproducible, auditable transformations (a saved view) instead of manual spreadsheet edits; handles 542K rows without performance issues |
| Power BI | Presentation & interactivity | Turns fixed SQL answers into a live, filterable tool stakeholders can explore themselves |
| DAX | Dynamic calculation layer | Lets metrics recalculate per filter selection instead of being frozen at one value |

## Data Cleaning & Preparation (SQL)

`raw_transactions` was created in PostgreSQL to hold the imported dataset unmodified. See [`../sql/postgresql/01_schema.sql`](../sql/postgresql/01_schema.sql).

### Raw Data Issues Found

| Issue | Rows Affected | Notes |
|---|---|---|
| Missing CustomerID | 135,080 (25%) | Guest checkouts — no customer to attribute the order to |
| Cancelled orders | 9,288 (InvoiceNo starts with 'C') | 1.7% of all line items |
| Negative quantity | 10,624 | Overlaps with cancellations but not identical — some are damage/adjustment write-offs |
| Zero/negative UnitPrice | 2,521 | Free giveaways, samples, and data errors mixed together |
| Missing Description | 1,454 | Minor, low-impact |
| Non-product StockCodes | 10,000+ | 'POST', 'DOT', 'M', 'BANK CHARGES' etc. — postage and manual adjustments mixed into the product table |

Queries behind these numbers: [`../sql/postgresql/02_data_exploration.sql`](../sql/postgresql/02_data_exploration.sql).

### Cleaning Logic

All cleaning is implemented as a single SQL view (`cleaned_transactions`) built on top of the untouched `raw_transactions` table, so the source data is never altered and every transformation is auditable and reproducible.

```sql
DROP VIEW IF EXISTS cleaned_transactions;

CREATE VIEW cleaned_transactions AS
SELECT
    t.invoice_no,
    t.stock_code,
    COALESCE(t.description, 'UNKNOWN') AS description,
    t.quantity,
    t.invoice_date,
    t.unit_price,
    t.customer_id,
    t.country,
    (t.quantity * t.unit_price) AS revenue,

    -- Transaction behavioral flags
    CASE WHEN t.invoice_no LIKE 'C%' THEN TRUE ELSE FALSE END AS is_cancellation,
    CASE WHEN t.quantity < 0 THEN TRUE ELSE FALSE END AS is_return,

    -- Operational overhead tracking flag
    CASE
        WHEN t.stock_code IN ('POST', 'DOT', 'M', 'D', 'C2', 'BANK CHARGES', 'AMAZONFEE', 'CRUK', 'S', 'B')
        THEN TRUE
        ELSE FALSE
    END AS is_non_product

FROM raw_transactions t
WHERE t.unit_price > 0; -- Excludes system warehouse errors, damages, and lost stock adjustments
```

- Cancellations are flagged (`is_cancellation`), not deleted. This is needed to calculate cancellation rate as its own metric.
- Rows with `unit_price <= 0` are excluded, since these represent system warehouse errors, damages, and lost stock adjustments rather than genuine sales revenue.
- Non-product and operational overhead codes are flagged (`is_non_product`) and excluded from product rankings. This includes postage and manual adjustments (POST, DOT, M, BANK CHARGES) as well as sample and broken-stock codes (S, B), but these are kept in revenue totals since that money is real.
- Guest checkouts (no CustomerID) are retained for product- and country-level analysis but excluded from customer-level analysis, such as RFM and retention, since no customer identity exists to segment.
- Raw data is never modified. All logic lives in a view aliased for readability (`t`), so any cleaning decision can be revised without re-importing the source data, and the view can be safely re-run at any time via `DROP VIEW IF EXISTS`.

### Before / After Snapshot

| Metric | Raw (`raw_transactions`) | Cleaned (`cleaned_transactions`) |
|---|---|---|
| Row count | 541,909 | 539,388 |
| Non-sales rows included | Yes (zero/negative price) | Excluded |
| Cancellations | Mixed in, unflagged | Flagged (`is_cancellation`) |
| Non-product line items | Mixed in, unflagged | Flagged (`is_non_product`) |

## Analysis Methodology

### RFM Segmentation

Customers were scored on three dimensions, each split into quartiles (1–4) using SQL's `NTILE` window function: Recency (days since last purchase), Frequency (count of distinct invoices), and Monetary (total revenue per customer). The three scores are summed to produce a total between 3 and 12, mapped to four segments: **Champion** (10–12), **Loyal** (7–9), **At Risk** (4–6), **Lost** (3). This threshold approach is a simplification chosen for clarity in a stakeholder-facing report, rather than a statistically derived cutoff or clustering method.

RFM was computed once in SQL and imported into Power BI as a static lookup table (`rfm_customers`), related to the transaction fact table by `customer_id`. See [`../sql/postgresql/04_rfm_segmentation.sql`](../sql/postgresql/04_rfm_segmentation.sql).

Segment results:

| Segment | Customers | % of Customers | Revenue | % of Revenue |
|---|---|---|---|---|
| Loyal | 2,375 | 54.7% | £6,439,532.03 | 72.3% |
| Champion | 567 | 13.1% | £2,069,448.25 | 23.2% |
| At Risk | 1,344 | 31.0% | £393,055.15 | 4.4% |
| Lost | 52 | 1.2% | £9,372.47 | 0.1% |

### Market Basket Analysis

The approach used is co-occurrence counting rather than full association-rule mining. For each pair of products appearing on the same invoice, the number of invoices containing both was counted. This identifies popular pairings but does not distinguish a meaningful relationship from two products that are each independently popular. See [`../sql/postgresql/06_product_pair_analysis.sql`](../sql/postgresql/06_product_pair_analysis.sql). Top result: stock codes 22386 + 85099B, 825 co-occurrences.

### Assumptions & Scope Limitations

- Guest checkouts are excluded from all customer-level analysis, which understates the true customer base, particularly for the UK and Hong Kong.
- Cancellations are excluded from revenue and product analysis but included in order-count-based cancellation rate calculations.
- Month-level time trends require year and month grouping, since the dataset's December spans two different years, one of which is a partial month. (Monthly revenue grouped by month name only combines both Decembers into one figure — see [`../sql/postgresql/05_seasonality_and_basket.sql`](../sql/postgresql/05_seasonality_and_basket.sql).)
- Market basket results are co-occurrence counts only, not statistically validated association rules.

## Data Model & DAX

### Star Schema

`cleaned_transactions` is the fact table at the center of the model. `rfm_customers` sits alongside it as a dimension table, one row per customer, joined by customer ID. `Date` is a standard date table, joined on invoice date. `raw_transactions` is kept separate on purpose, since it holds rows (like free giveaways) that the cleaned view deliberately excludes, and connecting it to the rest of the model would risk double-counting. Full detail: [`../power-bi/data_model.md`](../power-bi/data_model.md).

### Key DAX Measures (with rationale)

Full formulas: [`../power-bi/dax_measures.md`](../power-bi/dax_measures.md).

| Measure | Business Logic |
|---|---|
| `Total Revenue = SUM(cleaned_transactions[revenue])` | Base measure everything else builds on |
| `Cancellation Rate by Value = DIVIDE([Cancelled Value],[Gross Sales Value])` | Uses `ABS()` on cancelled value and a gross (non-cancelled) denominator — revenue is already negative for cancellation rows, so a naive `SUM()` would understate the true rate |
| `Median Order Value = CALCULATE(PERCENTILE.INC(...), ...)` | Average order value is pulled upward by a handful of large bulk orders; median gives a more realistic "typical order" figure |
| `Segment % of Revenue` (`rfm_customers`) | Lets any RFM segment's revenue contribution be seen instantly when filtered |
| `Repeat Customer %` | Verifies retention behavior independently of RFM, as a cross-check between two methods |

### KPI Definitions

- **Total Revenue** — quantity times unit price, added up across every non-cancelled transaction.
- **Average Order Value (AOV)** — total revenue divided by number of orders, reported alongside the median order value, since a handful of really large bulk orders can pull the average up and make it look bigger than what a typical order actually is.
- **Cancellation Rate** — reported two ways: by order count (the share of orders tied to invoices starting with "C") and by value (the share of total sales value those cancelled orders represent). The two numbers tell different stories, since cancelled orders tend to be smaller than average.
- **UK Revenue Concentration** — UK revenue divided by total revenue, used to measure how dependent the business is on a single market.
- **RFM Score** — a way of scoring customers based on how recently they bought, how often, and how much they've spent. Each of those three gets a score from 1 to 4, they get added together, and that total sorts customers into Champion, Loyal, At Risk, or Lost.
- **VIP Threshold** — the top 10% of customers by total spend, used to flag the highest-value group for retention efforts.
- **Repeat Customer Rate** — how many customers came back and bought more than once, versus the ones who only ordered a single time.
- **Free Giveaway Units** — units sold at a £0.00 unit price with a positive quantity, treated as promotional giveaways rather than genuine sales.
- **Market Basket Co-occurrence** — how many separate invoices contain both of two given products, used to identify items frequently bought together.

## Dashboard & Key Insights

The Power BI report has four pages: Business Performance Overview (total revenue, total customers, UK vs international split), Sales Overview (top 10 products, top international markets, hourly order trends), Customer Segmentation (RFM segment share and revenue, segment-level recency/frequency/monetary averages), and VIP & Retention (VIP revenue and count, repeat vs one-time split, order/revenue trends by day of week). See [`../power-bi/uk_retail_store.pbix`](../power-bi/uk_retail_store.pbix).

### Headline Insights

- 84.03% of total revenue comes from the UK, with 15.9% from international markets, led by the Netherlands, Ireland, and Germany — the strongest existing footholds for potential geographic diversification.
- Retention drives revenue, not acquisition: 65.58% of customers are repeat buyers, generating £7.79M of total revenue, compared to £521K from one-time buyers.
- Revenue is customer-concentrated: 434 VIP customers (the top 10% by spend) generate 61.38% of total revenue, representing a clear target for a loyalty program.
- RFM segmentation supports the retention finding: Loyal and Champion segments together account for over 95% of revenue.
- Demand is time-concentrated: Thursday and 12 noon are the peak order day/hour, directly informing staffing and marketing timing.
- Cancellations affected 16.12% of orders but only 8.41% of total sales value, indicating that cancelled orders were, on average, smaller than typical orders.

### Deeper Insight

Looking at all the findings side by side instead of one at a time, a bigger pattern shows up: this business is concentrated almost everywhere you look. Most of the revenue comes from one country. Most of the value comes from one small group of loyal, repeat customers. Even the demand is bunched into a narrow window of time — Thursdays around midday. On their own, each of these looks like a business doing well. But together, they point to a business with very little cushion. If the UK market dipped, if that core customer group started leaving, or if something disrupted operations during peak hours, there's no second market, no backup customer base, and no other time window to soften the hit. That's the kind of risk you only really notice once you stop looking at findings one at a time and start looking at how they connect.

### Decisions These Insights Could Inform

- Whether to pursue international expansion (Netherlands, Ireland, Germany) or deepen focus on the UK market.
- Where to allocate marketing budget between retention and new customer acquisition.
- How to structure warehouse and support staffing schedules by day and hour.
- Whether current inventory purchasing over-weights top sellers at the expense of a broader catalog.

## Challenges & Learnings

- Non-product StockCodes ('POST', 'DOT', 'M') were initially included in the top-products ranking, which would have misrepresented postage as a top-selling product. This was identified through manual inspection of the top 10 results rather than accepting the query output without review.
- A country-level query showed Hong Kong with revenue but zero customers, which initially appeared to be an error. Investigation confirmed the result was accurate: all Hong Kong transactions were guest checkouts with no CustomerID, making the metric correct but easy to misinterpret without further review.
- An early retention calculation contradicted the RFM segmentation computed independently. Re-running the retention query on a consistent base, matching the cancellation and guest-checkout filters used in RFM, resolved the discrepancy and confirmed that repeat customers drive the large majority of identifiable customer revenue. This cross-check proved to be the most valuable verification step in the project: when two methods produce disagreeing results for a similar question, that indicates a need for further verification rather than acceptance of either result.
- Average order value (£494.10) should be interpreted alongside the median, since a small number of large bulk orders inflate the mean and misrepresent a typical order. This underscores the importance of checking both measures when a distribution may not be symmetric.
- Country names in the raw data ('EIRE' instead of 'Ireland') do not geocode correctly in Power BI's map visual by default, requiring a manual mapping step in Power Query rather than a correction at the SQL layer, since this is a presentation-layer issue rather than a data quality issue.
- A recommended improvement for future iterations is conducting the retention-versus-RFM cross-check earlier in the process, rather than after both analyses were finalized, which would have identified the inconsistency sooner and reduced rework.
