# DAX Measures

The Fields pane holds a full set of measures (`% Revenue UK`, `Avg Frequency by Segment`, `Avg Monetary by Segment`, `Avg Order Value`, `Bundles Purchased Count`, `Cancellation Rate by Orders`, `Cancellation Rate by Value`, `Cancelled Value`, `Free Giveaway Units`, `Free Transaction Rows`, `Gross Sales Value`, `International Country Revenue`, `Median Items Per Order`, `Median Order Value`, `One-Time Customer Count`, `One-Time Customers`, `Orders by Day`, `Orders by Hour`, and more beyond what's captured here). The six below are the ones with notable business logic behind them, transcribed directly from Power BI.

## Total Revenue

```DAX
Total Revenue =
SUM(cleaned_transactions[revenue])
```

Base measure everything else builds on.

## Cancellation Rate by Value

```DAX
Cancellation Rate by Value =
DIVIDE([Cancelled Value], [Gross Sales Value])
```

`[Cancelled Value]` and `[Gross Sales Value]` are their own measures (not shown here), `Cancelled Value` uses `ABS()` on the cancelled-row total since `revenue` is already negative for cancellation rows, and `Gross Sales Value` sums only non-cancelled rows as the denominator. Without the `ABS()`, a naive `SUM()` would understate the true rate.

Reported alongside **Cancellation Rate by Orders** (share of orders on invoices starting with "C") because the two tell different stories — cancelled orders tend to be smaller than average, so the value-based rate (8.41%) comes out lower than the order-count-based rate (16.12%).

## Median Order Value

```DAX
Median Order Value =
CALCULATE(
    PERCENTILE.INC(rfm_customers[monetary], 0.5),
    REMOVEFILTERS(rfm_customers[segment])
)
```

Note this is computed over `rfm_customers[monetary]`- per-customer lifetime revenue, not per-order value. `REMOVEFILTERS(rfm_customers[segment])` keeps the figure stable regardless of which segment a visual is filtered to. Reported alongside the average order value (£494.10) since a handful of large bulk orders pull the mean upward.

## Segment % of Revenue

```DAX
Segment % of Revenue =
DIVIDE([Segment Revenue], CALCULATE([Segment Revenue], ALL(rfm_customers[segment])))
```

Lets any RFM segment's revenue contribution be read instantly when the visual is filtered to that segment, the denominator recalculates across all segments regardless of the current filter context.

## VIP Threshold

```DAX
VIP Threshold =
CALCULATE(
    PERCENTILE.INC(rfm_customers[monetary], 0.9),
    REMOVEFILTERS(rfm_customers)
)
```

Defines VIP as the 90th percentile of customer lifetime spend — the top 10% by total spend.

## Repeat Customer %

```DAX
Repeat Customer % =
VAR CleanRepeatCustomers =
    CALCULATE(
        [Total Customers],
        rfm_customers[Customer Loyalty Status] = "Repeat Customer",
        NOT(ISBLANK(rfm_customers[customer_id]))
    )
VAR CleanTotalCustomers =
    CALCULATE(
        [Total Customers],
        NOT(ISBLANK(rfm_customers[customer_id]))
    )
RETURN
    DIVIDE(CleanRepeatCustomers, CleanTotalCustomers, 0)
```

`rfm_customers[Customer Loyalty Status]` is a Power BI–side column (not part of the SQL `rfm_customers` table) tagging each customer as "Repeat Customer" or otherwise, likely derived from `frequency > 1`, though the exact formula for that column wasn't captured. This measure exists as a cross-check against the RFM segmentation: an early retention calculation contradicted the RFM numbers until both were run against the same cancellation/guest-checkout filters, at which point they agreed.

## Free Giveaway Units

Sourced from the standalone `raw_transactions` table (not `cleaned_transactions`, which excludes `unit_price <= 0` rows entirely) since giveaway lines are exactly the rows the cleaned view filters out.

```DAX
Free Giveaway Units =
CALCULATE(
    SUM(raw_transactions[quantity]),
    raw_transactions[unit_price] <= 0,
    raw_transactions[quantity] > 0
)
```
