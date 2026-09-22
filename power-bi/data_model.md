# Power BI Data Model

`cleaned_transactions` sits at the center as the fact table. `rfm_customers` is a dimension table, one row per customer, joined on `customer_id`. `Date` is a standard date table, joined on `invoice_date`. `raw_transactions` is imported separately and kept unrelated to the rest of the model on purpose, it holds rows (like free giveaways) that `cleaned_transactions` deliberately excludes, and connecting it would risk double-counting.

## Tables

| Table | Role |
|---|---|
| `cleaned_transactions` | Fact table. 539,388 rows (541,909 raw rows minus the 2,521 excluded for `unit_price <= 0`). Columns include `country`, `customer_id`, `day_of_week`, `description`, `Hour of Day` (calculated column), `hour_of_day`, `invoice_date`, `invoice_no`, `is_cancellation`, plus more below the fold in Power BI |
| `rfm_customers` | Dimension table, one row per `customer_id`. Columns include `Customer Loyalty Status` (Power BI–side column), `customer_id`, `frequency`, `frequency_score`, `loyalty_status`, `monetary`, `monetary_score`, `net_revenue`, `recency_interval`, plus `recency_score`, `rfm_total`, and `segment` further down |
| `raw_transactions` | Standalone reference table, not related to anything else in the model. Used only by the `Free Giveaway Units` measure |
| `Date` | Generated calendar table: `Date`, `DayOfWeek`, `Month`, `Year` |

## Relationships

```
Date[Date]              1 ──── * cleaned_transactions[invoice_date]
rfm_customers[customer_id]  1 ──── * cleaned_transactions[customer_id]
```

Both are single-direction, one-to-many, with the dimension table (`Date` / `rfm_customers`) on the "1" side. `raw_transactions` has no relationship lines to any other table in the model.

## Why a Standalone `raw_transactions` Table

`cleaned_transactions` excludes `unit_price <= 0` rows entirely at the view level, so "free giveaway" volume (items given away at zero or negative price) simply isn't present in the fact table. Since that's still a metric worth tracking operationally, `Free Giveaway Units` reads straight from the untouched `raw_transactions` table instead.
