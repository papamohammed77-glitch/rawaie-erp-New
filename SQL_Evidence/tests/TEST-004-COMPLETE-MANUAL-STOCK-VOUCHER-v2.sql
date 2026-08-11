-- RAWAEA ERP — TEST-004 v2
-- Purpose: SAFE, READ-ONLY fixture discovery + transactional COMPLETE test.
-- IMPORTANT: Run the ENTIRE script in ONE SQL Editor execution.
-- Do NOT replace placeholders. Stage A discovers a real fixture automatically.
-- The test transaction ALWAYS ends with ROLLBACK.

-- ============================================================
-- STAGE A — FIND A SAFE EXISTING VOUCHER FIXTURE
-- ============================================================
-- We need a voucher that the Production COMPLETE RPC is expected to accept.
-- We prefer Draft vouchers because the CANCEL RPC explicitly works from Draft,
-- but COMPLETE's accepted starting states must be established from its source.
-- This query performs NO mutation.

SELECT
    v.id,
    v.company_id,
    v.voucher_code,
    v.type,
    v.status,
    v.from_branch_id,
    v.to_branch_id,
    v.from_type,
    v.from_id,
    v.to_type,
    v.to_id,
    v.reference,
    v.created_by,
    v.completed_by,
    v.completed_at,
    v.created_at,
    COUNT(d.id) AS detail_count,
    COALESCE(SUM(d.qty), 0) AS detail_qty
FROM public.stock_vouchers v
LEFT JOIN public.stock_voucher_details d
    ON d.voucher_id = v.id
WHERE v.status IN ('Draft', 'Sent')
GROUP BY
    v.id,
    v.company_id,
    v.voucher_code,
    v.type,
    v.status,
    v.from_branch_id,
    v.to_branch_id,
    v.from_type,
    v.from_id,
    v.to_type,
    v.to_id,
    v.reference,
    v.created_by,
    v.completed_by,
    v.completed_at,
    v.created_at
HAVING COUNT(d.id) > 0
ORDER BY v.created_at ASC
LIMIT 10;

-- ============================================================
-- STAGE A2 — SHOW EXACT CANDIDATE FOR TESTING
-- ============================================================
-- Select ONE candidate manually from Stage A output, then set the two
-- session variables below. This stage still performs NO mutation.
-- Replace ONLY these two values after inspecting Stage A:
--   <COMPANY_UUID>
--   <VOUCHER_CODE>

-- ============================================================
-- STAGE B — PRE-TEST VALIDATION (READ ONLY)
-- ============================================================
-- After selecting a real candidate, run this block separately if needed.
-- It must return exactly one voucher and at least one detail row.

-- SELECT
--     v.id,
--     v.company_id,
--     v.voucher_code,
--     v.type,
--     v.status,
--     v.completed_by,
--     v.completed_at,
--     COUNT(d.id) AS detail_count,
--     COALESCE(SUM(d.qty), 0) AS detail_qty
-- FROM public.stock_vouchers v
-- LEFT JOIN public.stock_voucher_details d ON d.voucher_id = v.id
-- WHERE v.company_id = '<COMPANY_UUID>'::uuid
--   AND v.voucher_code = '<VOUCHER_CODE>'::text
-- GROUP BY v.id, v.company_id, v.voucher_code, v.type, v.status,
--          v.completed_by, v.completed_at;

-- ============================================================
-- STAGE C — SAFE TRANSACTIONAL COMPLETE TEST
-- ============================================================
-- Only execute after Stage A returns a candidate and the placeholders below
-- have been replaced with REAL values from Stage A.
-- Execute this entire transaction as ONE unit.
-- NEVER COMMIT.

-- BEGIN;
--
-- SELECT
--     id,
--     company_id,
--     voucher_code,
--     type,
--     status,
--     completed_by,
--     completed_at,
--     updated_at
-- FROM public.stock_vouchers
-- WHERE company_id = '<COMPANY_UUID>'::uuid
--   AND voucher_code = '<VOUCHER_CODE>'::text
-- FOR UPDATE;
--
-- SELECT public.complete_manual_stock_voucher_atomic(
--     '<COMPANY_UUID>'::uuid,
--     '<VOUCHER_CODE>'::text,
--     '<TEST_USER_EMAIL>'::text
-- );
--
-- SELECT
--     id,
--     company_id,
--     voucher_code,
--     type,
--     status,
--     completed_by,
--     completed_at,
--     updated_at
-- FROM public.stock_vouchers
-- WHERE company_id = '<COMPANY_UUID>'::uuid
--   AND voucher_code = '<VOUCHER_CODE>'::text
-- FOR UPDATE;
--
-- SELECT *
-- FROM public.stock_voucher_details
-- WHERE voucher_id = (
--     SELECT id
--     FROM public.stock_vouchers
--     WHERE company_id = '<COMPANY_UUID>'::uuid
--       AND voucher_code = '<VOUCHER_CODE>'::text
-- );
--
-- ROLLBACK;

-- ============================================================
-- EXECUTION RULE
-- ============================================================
-- Run Stage A ONLY first.
-- Do NOT run Stage C until a real candidate exists.
-- If Stage A returns no rows, STOP. Do not invent a voucher or company UUID.
-- This v2 script deliberately keeps mutation stages commented until a real
-- Production fixture has been selected, preventing the previous placeholder
-- UUID error.
