-- ============================================================
-- 02_data_exploration.sql (PostgreSQL 18)
-- First-pass checks on raw_transactions before writing the
-- cleaning view. These numbers are what shaped the cleaning
-- decisions in 03_cleaned_transactions_view.sql.
-- ============================================================

-- How many rows have no CustomerID (guest checkouts)?
SELECT COUNT(*) FROM raw_transactions WHERE customer_id IS NULL;
-- 135,080

-- How many invoices are cancellations? ILIKE used so a
-- lowercase 'c' prefix doesn't slip through uncounted.
SELECT COUNT(*) AS total_cancelled_orders
FROM raw_transactions
WHERE invoice_no ILIKE 'C%';
-- 9,288

-- How many line items have negative quantity in total
-- (cancellations + anything else)?
SELECT COUNT(*) AS total_negative_quantity
FROM raw_transactions
WHERE quantity < 0;
-- 10,624

-- Split that negative-quantity total into cancellations vs
-- everything else, to see how much of it is genuine customer
-- returns vs internal stock adjustments/errors.
SELECT
    COUNT(CASE WHEN invoice_no ILIKE 'C%' THEN 1 END) AS customer_returns,
    COUNT(CASE WHEN invoice_no NOT ILIKE 'C%' THEN 1 END) AS stock_adjustments_and_errors,
    COUNT(*) AS total_negative_records
FROM raw_transactions
WHERE quantity < 0;
-- customer_returns: 9,288 | stock_adjustments_and_errors: 1,336 | total: 10,624

-- How many rows have a unit price of zero or less? These are
-- system errors, damage write-offs, and giveaways rather than
-- genuine sales, so cleaned_transactions excludes them entirely.
SELECT COUNT(*) AS zero_or_negative_price_rows
FROM raw_transactions
WHERE unit_price <= 0;
-- 2,521

-- How many rows have a missing product description?
SELECT COUNT(*) AS missing_description_rows
FROM raw_transactions
WHERE description IS NULL;
-- 1,454

-- Dissect the non-cancellation negative-quantity rows further,
-- using the description text to categorize why stock left the
-- system (damage, loss, adjustment, giveaway, etc.).
SELECT
    CASE
        WHEN t.invoice_no LIKE 'C%' THEN 'Customer Cancellation'
        WHEN t.description ILIKE '%damage%' THEN 'Damaged Goods Write-off'
        WHEN t.description ILIKE '%lost%' THEN 'Lost Stock'
        WHEN t.description ILIKE '%found%' THEN 'Inventory Found Adjustment'
        WHEN t.description ILIKE '%adjust%' THEN 'Manual Stock Adjustment'
        WHEN t.description ILIKE '%sample%' THEN 'Marketing Sample / Giveaway'
        WHEN t.description ILIKE '%?%' OR t.description ILIKE '%check%' THEN 'Flagged for Audit Review'
        WHEN t.description IS NULL THEN 'Missing Description'
        ELSE 'Uncategorized Return or Adjustment'
    END AS inventory_reduction_reason,
    COUNT(*) AS transaction_count,
    SUM(t.quantity) AS total_units_removed,
    ROUND(SUM(t.quantity * t.unit_price)::numeric, 2) AS financial_impact
FROM raw_transactions t
WHERE t.quantity < 0
GROUP BY inventory_reduction_reason
ORDER BY transaction_count DESC;
-- Customer Cancellation: 9,288 rows / -277,574 units / -£896,812.49
-- Missing Description: 862 rows / -46,156 units / £0.00
-- Flagged for Audit Review: 189 rows / -32,897 units / £0.00
-- Uncategorized Return or Adjustment: 140 rows / -99,975 units / £0.00
-- (remaining categories omitted here — see full result set)

-- Non-product StockCodes: postage, manual adjustments, fees,
-- and other operational codes mixed into the product table.
-- These are flagged (not deleted) in the cleaned view as
-- is_non_product, and excluded from product rankings, but kept
-- in revenue totals since that money is real.
SELECT stock_code, COUNT(*) AS row_count
FROM raw_transactions
WHERE stock_code IN ('POST', 'DOT', 'M', 'D', 'C2', 'BANK CHARGES', 'AMAZONFEE', 'CRUK', 'S', 'B')
GROUP BY stock_code
ORDER BY row_count DESC;
-- 10,000+ rows combined across these codes
