# Excel Logic
Excel's confirmed role, per the project's technical documentation, was **initial exploration**  "a fast way to eyeball nulls, outliers, and value ranges before committing to a cleaning approach." The source workbook is [`../data/Online_Retail.xlsx`](../data/Online_Retail.xlsx). What follows below is a reasonable reconstruction of what that exploration probably looked like, since the exact formulas weren't captured in the documentation.

## 1. Raw Data Checks

- `=COUNTBLANK(CustomerID)`-count of guest/no-ID rows, to confirm the guest-customer share before deciding to exclude them from segmentation
- `=COUNTIF(InvoiceNo, "C*")`- count of cancelled invoices, to confirm the cancellation count against the SQL result (9,288 rows, 1.7% of all line items)
- `=SUMPRODUCT((Quantity<=0)+(UnitPrice<=0))` — count of rows that would need to be excluded from revenue (used to sanity-check the SQL `WHERE quantity > 0 AND unit_price > 0` filter)

## 2. Revenue Cross-Check

A helper column was added to the raw sheet:

```
LineTotal = Quantity * UnitPrice
```

Then a PivotTable: `Country` in rows, `Sum of LineTotal` in values, filtered to exclude cancellations and non-positive lines — this is the manual equivalent of grouping `cleaned_transactions` by country (with `is_cancellation = FALSE` applied), used to confirm the 84.03% UK revenue share.

## 3. Average vs Median Order Value

```
AverageOrderValue = AVERAGEIF(InvoiceTotals, ">0")
MedianOrderValue  = MEDIAN(InvoiceTotals)
```

Where `InvoiceTotals` is a PivotTable output (one row per InvoiceNo, summed LineTotal). This is the same check the Power BI `Median Order Value` measure serves — the median was pulled deliberately alongside the average because a handful of large bulk orders skew the mean upward.

## 4. Cancellation Rate

```
CancellationRate = COUNTIF(InvoiceNo, "C*") / COUNTA(InvoiceNo)
```

Matched against the SQL `is_cancellation` flag in `cleaned_transactions` to confirm the cancellation rate.

## 5. Peak Timing

- `=TEXT(InvoiceDate, "dddd")` helper column, then a PivotTable counting distinct `InvoiceNo` by day, to confirm Thursday as the peak order day
- `=HOUR(InvoiceDate)` helper column, same approach, to confirm noon as the peak order hour

## Notes

- All Excel work was done on a copy of `Online_Retail.xlsx`, the version committed in `data/` and referenced in `sql/postgresql/01_schema.sql` / `sql/mysql/01_schema.sql` was never altered.
- Formulas here are intentionally the "manual" version of what the SQL views do, they exist to confirm the SQL logic, not to replace it. If a number ever disagreed between the two, the SQL was treated as the source of truth and the Excel formula was checked for a filtering mistake.
