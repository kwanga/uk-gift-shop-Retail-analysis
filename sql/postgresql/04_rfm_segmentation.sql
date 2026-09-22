-- ============================================================
-- 04_rfm_segmentation.sql (PostgreSQL 18)
-- Builds rfm_customers: one row per customer, scored into
-- quartiles (NTILE(4)) on Recency, Frequency, and Monetary
-- value, then tagged into a segment based on the combined score.
-- ============================================================

DROP TABLE IF EXISTS rfm_customers;

CREATE TABLE rfm_customers AS
WITH max_date_cte AS (
    -- Pre-calculates the absolute latest transaction date in the database a single time.
    SELECT MAX(invoice_date) AS max_system_date FROM cleaned_transactions
),
customer_base AS (
    -- Compresses millions of transaction lines down into one summary record per unique customer, calculating their raw Recency/Frequency/Monetary inputs.
    SELECT
        ct.customer_id,
        MAX(ct.invoice_date) AS last_purchase,
        COUNT(DISTINCT ct.invoice_no) AS frequency,
        SUM(ct.revenue) AS monetary
    FROM cleaned_transactions ct
    WHERE ct.customer_id IS NOT NULL   -- Excludes guest/anonymous checkouts because their habits cannot be tracked over time
      AND ct.is_cancellation = FALSE   -- Excludes canceled orders so the model reflects true financial value and actual purchases
    GROUP BY ct.customer_id
),
scored AS (
    -- Applies statistical window functions to rank customers into four equal statistical quartiles (1 to 4) based on their behavior.
    SELECT
        cb.customer_id,
        cb.last_purchase,
        cb.frequency,
        cb.monetary,
        (m.max_system_date - cb.last_purchase) AS recency_interval,
        -- NTILE(4) splits users into 4 groups. Sorting by ASC ensures the smallest intervals (freshest shoppers) receive the lowest recency_score bucket.
        NTILE(4) OVER (ORDER BY (m.max_system_date - cb.last_purchase) ASC) AS recency_score,
        NTILE(4) OVER (ORDER BY cb.frequency ASC) AS frequency_score,
        NTILE(4) OVER (ORDER BY cb.monetary ASC) AS monetary_score
    FROM customer_base cb
    CROSS JOIN max_date_cte m
)
-- Aggregates the 1-4 individual scores into a master score out of 12, then applies strategic business rules to tag each customer.
SELECT
    s.customer_id,
    s.recency_interval,
    s.frequency,
    ROUND(s.monetary::numeric, 2) AS monetary,
    s.recency_score,
    s.frequency_score,
    s.monetary_score,
    (s.recency_score + s.frequency_score + s.monetary_score) AS rfm_total,
    CASE
        WHEN (s.recency_score + s.frequency_score + s.monetary_score) >= 10 THEN 'Champion'
        WHEN (s.recency_score + s.frequency_score + s.monetary_score) >= 7  THEN 'Loyal'
        WHEN (s.recency_score + s.frequency_score + s.monetary_score) >= 4  THEN 'At Risk'
        ELSE 'Lost'
    END AS segment
FROM scored s;

SELECT COUNT(*) AS final_segmented_customers FROM rfm_customers;

SELECT * FROM rfm_customers;

-- Segment summary: customer count and revenue share by segment
SELECT
    rc.segment,
    COUNT(*) AS total_customers,
    ROUND(
        (100.0 * COUNT(*)) / SUM(COUNT(*)) OVER (),
        1
    ) AS customer_share_pct,
    ROUND(SUM(rc.monetary)::numeric, 2) AS total_segment_revenue,
    ROUND(
        (100.0 * SUM(rc.monetary)) / SUM(SUM(rc.monetary)) OVER (),
        1
    ) AS revenue_share_pct
FROM rfm_customers rc
GROUP BY rc.segment
ORDER BY total_segment_revenue DESC;
-- Loyal:    2,375 customers (54.7%) | £6,439,532.03 (72.3%)
-- Champion:   567 customers (13.1%) | £2,069,448.25 (23.2%)
-- At Risk:  1,344 customers (31.0%) | £393,055.15   (4.4%)
-- Lost:        52 customers (1.2%)  | £9,372.47     (0.1%)
