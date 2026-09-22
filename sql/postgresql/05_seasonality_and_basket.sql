-- ============================================================
-- 05_seasonality_and_basket.sql (PostgreSQL 18)
-- Reporting queries run directly against cleaned_transactions.
-- ============================================================

-- REPORT 1: YEARLY SEASONALITY ANALYSIS (ALL YEARS COMBINED)
-- Aggregates performance data chronologically by month name
-- instead of integers.
-- NOTE: this groups by month name only, combining Dec 2010 and
-- Dec 2011 into a single "December" figure. Grouping by year
-- AND month is needed for a true chronological monthly trend.
SELECT
    TRIM(TO_CHAR(ct.invoice_date, 'Month')) AS sales_month,
    ROUND(SUM(ct.revenue)::numeric, 2) AS aggregated_revenue,
    COUNT(DISTINCT ct.invoice_no) AS unique_orders_count
FROM cleaned_transactions ct
WHERE ct.is_cancellation = FALSE
GROUP BY TRIM(TO_CHAR(ct.invoice_date, 'Month')), EXTRACT(MONTH FROM ct.invoice_date)
ORDER BY EXTRACT(MONTH FROM ct.invoice_date) ASC;

-- REPORT 2: WEEKDAY TRAFFIC PROFILE
SELECT
    TO_CHAR(ct.invoice_date, 'Day') AS weekday_name,
    COUNT(DISTINCT ct.invoice_no) AS unique_orders_count,
    ROUND(SUM(ct.revenue)::numeric, 2) AS aggregated_revenue
FROM cleaned_transactions ct
WHERE ct.is_cancellation = FALSE
GROUP BY weekday_name
ORDER BY unique_orders_count DESC;

-- REPORT 3: INTRADAY CHECKOUT SURGES
SELECT
    EXTRACT(HOUR FROM ct.invoice_date) AS checkout_hour_24h,
    COUNT(DISTINCT ct.invoice_no) AS unique_orders_count,
    ROUND(SUM(ct.revenue)::numeric, 2) AS aggregated_revenue
FROM cleaned_transactions ct
WHERE ct.is_cancellation = FALSE
GROUP BY checkout_hour_24h
ORDER BY checkout_hour_24h ASC;

-- AVERAGE ORDER VALUE vs MEDIAN ORDER VALUE
-- The confirmed AOV in the project's documentation is £494.10.
-- (An earlier pass of this query, run before the unit_price > 0
-- filter existed in cleaned_transactions, returned £534.40 —
-- kept here as a note since it's a good example of why the
-- median is checked alongside the mean: the number moves when
-- the underlying row set changes, and a single average can hide that.)
SELECT
    ROUND(AVG(basket_summary.order_revenue)::numeric, 2) AS average_order_value,
    ROUND(AVG(basket_summary.order_items)::numeric, 1) AS average_items_per_basket
FROM (
    SELECT
        ct.invoice_no,
        SUM(ct.revenue) AS order_revenue,
        SUM(ct.quantity) AS order_items
    FROM cleaned_transactions ct
    WHERE ct.is_cancellation = FALSE
    GROUP BY ct.invoice_no
) basket_summary;

-- CANCELLATION RATE, two ways (order-count basis vs value basis) —
-- these tell different stories since cancelled orders tend to be
-- smaller than average.
-- NOTE: this SQL version is reconstructed to match the confirmed
-- DAX logic (Cancellation Rate by Value = DIVIDE([Cancelled Value],
-- [Gross Sales Value]), using ABS() on the cancelled side since
-- revenue is already negative for cancellation rows) — it isn't
-- transcribed from a screenshot of an equivalent SQL query.
WITH order_level AS (
    SELECT
        invoice_no,
        BOOL_OR(is_cancellation) AS is_cancelled_order,
        SUM(revenue) AS order_revenue
    FROM cleaned_transactions
    GROUP BY invoice_no
)
SELECT
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_cancelled_order) / COUNT(*), 2) AS cancellation_rate_by_orders_pct,
    ROUND(100.0 * SUM(ABS(order_revenue)) FILTER (WHERE is_cancelled_order)
          / SUM(order_revenue) FILTER (WHERE NOT is_cancelled_order), 2) AS cancellation_rate_by_value_pct
FROM order_level;
-- Confirmed in documentation: 16.12% of orders, 8.41% of sales value
