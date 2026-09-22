# Retail Data Analysis Report

Prepared by Fanan Kwanga

## 1. Setup

This report looks at 541,000+ transactions from a UK-based online gift shop, covering December 2010 to December 2011, to understand what's driving revenue, how valuable customers are, and where the operational risks sit.

## 2. Data Cleaning

- The raw dataset wasn't touched; all cleaning happened in a SQL view
- Cancellations were flagged instead of deleted, since they only made up 1.7% of all transaction line items
- Zero and negative-value rows were left out of revenue calculations
- Guest customers (no CustomerID) stayed in for product and country-level analysis but were excluded from customer segmentation

## 3. Key Findings

### Market Analysis

The UK brings in 84.03% of total revenue (£9.77M), with international markets making up the remaining 15.9%. Among those, the Netherlands leads (£284,661), followed by Ireland (£263,276.82), Germany (£221,698.21), France (£197,403.90), and Australia (£137,007.27). These five are the strongest existing footholds outside the UK, so they'd be the logical starting points if the business wants to diversify geographically and reduce its dependence on a single market.

### Customer Retention

Of 4,371 total customers, 65.58% bought more than once, and they generated £7.79 million — most of the revenue. One-time customers, 34.42% of the base, brought in just £521,110. The business runs on repeat purchasing, not new customer acquisition.

### RFM Segmentation

Customers were grouped with a standardized RFM (Recency, Frequency, Monetary) scoring model into four segments:

| Segment | Customers | % of Revenue |
|---|---|---|
| Loyal | 2,375 | 72.26% |
| Champion | 567 | 23.22% |
| At Risk | 1,344 | 4.41% |
| Lost | 52 | 0.11% |

Loyal and Champion customers together drive most of the revenue, which lines up with the retention numbers above — both point to the same core group of repeat buyers as the real engine of the business.

### VIP Customers

434 customers qualified as VIP (top 10% by lifetime spend). This group generated £5.47 million, or 61.38% of total revenue.

### Cancellations

Cancellations affected 16.12% of orders but only 8.41% of total sales value — meaning cancelled orders were, on average, smaller than typical orders. Both numbers matter: the order-count share tells you how often it happens operationally, the value share tells you how much revenue is actually at stake.

### Average Order Value

The average order value was £494.10.

### Peak Timing

Thursday sees the highest number of orders, and noon is when people order the most.

## 4. Recommendations

### Revenue & Market Strategy

- The 84.03% UK revenue share is a concentration risk. The Netherlands, Ireland, and Germany are the best starting points for international growth since they're already performing the strongest
- Don't over-invest in a small set of "hero" products — revenue is spread across the catalog, not concentrated in a few items

### Customer Retention & Marketing

- Prioritize retention over acquisition. Repeat customers generate the large majority of revenue (£7.79M vs £521K from one-time buyers), so retention spend pays off more than acquisition spend
- Build a loyalty program for the Loyal and Champion segments, since together they drive over 95% of revenue
- Launch a win-back campaign for the At Risk segment (1,344 customers, 4.41% of revenue) before they slide into Lost
- Create a dedicated VIP program for the 434 top-spend customers, who alone generate 61.38% of total revenue
- Schedule promotional emails shortly before noon, the peak ordering hour, to catch customers while they're active

### Operations & Fulfillment

- Staff the warehouse and customer support team most heavily on Thursdays and around midday, when order volume peaks
- Keep monitoring the cancellation rate at the item level (16.12% of orders, 8.41% of sales value) to catch any products with unusually high cancellation activity
- Use the average order value (£494.10) for financial planning, but check the median separately — a small number of large bulk orders can pull the average up and make it look less like a typical order
