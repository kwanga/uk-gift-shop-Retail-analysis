-- ============================================================
-- 06_product_pair_analysis.sql (PostgreSQL 18)
-- Top 20 product pairs by co-occurrence count.
--
-- This is co-occurrence counting, not full association-rule
-- mining: it identifies popular pairings but doesn't distinguish
-- a meaningful relationship from two products that are each
-- independently popular (no support/confidence/lift computed).
-- ============================================================

SELECT
    a.stock_code AS product_a,
    b.stock_code AS product_b,
    COUNT(DISTINCT a.invoice_no) AS times_bought_together
FROM cleaned_transactions a
JOIN cleaned_transactions b
    ON a.invoice_no = b.invoice_no
   AND a.stock_code < b.stock_code
WHERE a.is_cancellation = FALSE
GROUP BY a.stock_code, b.stock_code
ORDER BY times_bought_together DESC
LIMIT 20;

-- Top result: 22386 + 85099B — 825 co-occurrences
