-- RAWAEA ERP — TEST-004
-- Safe verification of complete_manual_stock_voucher_atomic
-- READ THIS BEFORE EXECUTION.
--
-- This test is intentionally split into two stages.
-- Stage A is READ-ONLY and identifies a suitable Draft voucher.
-- DO NOT execute Stage B until Stage A returns exactly ONE suitable test voucher.
--
-- Stage B runs inside an explicit transaction and ends with ROLLBACK,
-- so database changes made by the RPC are not persisted.
-- Do not use this test if the RPC calls external services or non-transactional
-- side effects; this test assumes the RPC is database-only.

-- ============================================================
-- STAGE A — READ-ONLY CANDIDATE DISCOVERY
-- ============================================================
SELECT
    sv.id,
    sv.company_id,
    sv.voucher_code,
    sv.type,
    sv.status,
    sv.from_branch_id,
    sv.to_branch_id,
    sv.from_type,
    sv.from_id,
    sv.to_type,
    sv.to_id,
    sv.reference,
    sv.created_by,
    sv.created_at
FROM public.stock_vouchers sv
WHERE sv.status = 'Draft'
ORDER BY sv.created_at DESC
LIMIT 20;

-- ============================================================
-- STAGE A2 — DETAILS FOR CANDIDATE VOUCHERS
-- ============================================================
SELECT
    sv.voucher_code,
    sv.type,
    sv.status,
    svd.*
FROM public.stock_vouchers sv
JOIN public.stock_voucher_details svd
  ON svd.voucher_id = sv.id
WHERE sv.status = 'Draft'
ORDER BY sv.created_at DESC, svd.voucher_id;

-- ============================================================
-- STAGE B — SAFE TRANSACTIONAL TEST
-- ============================================================
-- Replace ONLY the two placeholders below using values returned by Stage A.
-- Do not change the RPC name/signature.
-- p_user_email should be your test/operator email.

BEGIN;

-- Capture the voucher state BEFORE execution.
SELECT
    id,
    company_id,
    voucher_code,
    type,
    status,
    completed_by,
    completed_at,
    updated_at
FROM public.stock_vouchers
WHERE company_id = '<COMPANY_UUID>'::uuid
  AND voucher_code = '<VOUCHER_CODE>'
FOR UPDATE;

-- Execute the Production RPC under test.
SELECT public.complete_manual_stock_voucher_atomic(
    '<COMPANY_UUID>'::uuid,
    '<VOUCHER_CODE>'::text,
    '<TEST_USER_EMAIL>'::text
);

-- Verify the result produced inside the transaction.
SELECT
    id,
    company_id,
    voucher_code,
    type,
    status,
    completed_by,
    completed_at,
    updated_at
FROM public.stock_vouchers
WHERE company_id = '<COMPANY_UUID>'::uuid
  AND voucher_code = '<VOUCHER_CODE>'
FOR UPDATE;

-- Verify related detail rows still exist.
SELECT *
FROM public.stock_voucher_details
WHERE voucher_id = (
    SELECT id
    FROM public.stock_vouchers
    WHERE company_id = '<COMPANY_UUID>'::uuid
      AND voucher_code = '<VOUCHER_CODE>'
);

-- IMPORTANT: never COMMIT this test.
-- ROLLBACK removes the database changes made by the test.
ROLLBACK;

-- ============================================================
-- STAGE C — POST-ROLLBACK VERIFICATION
-- ============================================================
SELECT
    id,
    company_id,
    voucher_code,
    type,
    status,
    completed_by,
    completed_at,
    updated_at
FROM public.stock_vouchers
WHERE company_id = '<COMPANY_UUID>'::uuid
  AND voucher_code = '<VOUCHER_CODE>';

-- EXPECTATION:
-- Stage B should execute without the previous completed_by column error.
-- Stage B should show the RPC's resulting status/completed_by/completed_at.
-- Stage C should show the ORIGINAL pre-test state because Stage B was rolled back.
--
-- If the RPC raises ANY error before ROLLBACK, issue ROLLBACK manually
-- before doing anything else in the SQL editor.
