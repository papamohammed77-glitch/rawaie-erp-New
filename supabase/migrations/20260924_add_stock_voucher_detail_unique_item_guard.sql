-- RAWAEA ERP — database invariant for manual voucher detail uniqueness
-- Date: 2026-09-24
-- Business contract: one item may occur only once per stock voucher.
-- Existing duplicate count was verified as zero before applying this constraint.

ALTER TABLE public.stock_voucher_details
ADD CONSTRAINT stock_voucher_details_voucher_item_key
UNIQUE (voucher_id,item_id);
