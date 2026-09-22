-- ============================================================
-- 03_cleaned_transactions_view.sql (PostgreSQL 18)
-- Single cleaning view on top of raw_transactions. raw_transactions
-- itself is never edited — everything downstream (exploration,
-- RFM, reporting) reads from cleaned_transactions instead.
-- ============================================================

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

-- Notes:
--   - Cancellations are flagged (is_cancellation), not deleted — needed to
--     calculate cancellation rate as its own metric.
--   - Rows with unit_price <= 0 ARE excluded here (2,521 rows), since these
--     represent system warehouse errors, damages, and lost stock adjustments
--     rather than genuine sales revenue.
--   - Non-product and operational overhead codes (POST, DOT, M, BANK CHARGES,
--     etc.) are flagged (is_non_product) and excluded from product rankings,
--     but kept in revenue totals since that money is real.
--   - Guest checkouts (no customer_id) are retained here for product- and
--     country-level analysis, but excluded per-query wherever customer-level
--     analysis happens (RFM, retention), since there's no customer identity
--     to segment.
--   - Row count: 541,909 (raw) -> 539,388 (cleaned), after the unit_price
--     filter above.
