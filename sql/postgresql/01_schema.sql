-- ============================================================
-- 01_schema.sql (PostgreSQL 18)
-- Raw table definition for the UCI Online Retail dataset.
-- raw_transactions is never modified after load — all cleaning
-- happens in the cleaned_transactions view (see 02_).
-- ============================================================

CREATE TABLE raw_transactions (
    invoice_no      VARCHAR(20),
    stock_code      VARCHAR(20),
    description     VARCHAR(255),
    quantity        INTEGER,
    invoice_date    TIMESTAMP,
    unit_price      NUMERIC(10,2),
    customer_id     INTEGER,
    country         VARCHAR(100)
);

SELECT * FROM raw_transactions;
