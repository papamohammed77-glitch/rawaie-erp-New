# CURRENT STATE SUPPLEMENT — LVE-2026-11-04-620

**Date:** 2026-11-04 — Africa/Cairo.  
**Base:** LVE616 main CURRENT_STATE plus LVE617–619 supplements.  
**Operational repo HEAD observed:** e8ab54c75572e15e71581212479d22be139c8020.

## Last verified event
Prepared Report620 mapping new Buyer custody operations to existing Edge functions only. Exact deployed sources for all six existing Edge functions were already recovered and archived; no new Edge function is required.

## Edge extension plan
- save-purchase-order v22: add read, Quick Market handover, Buyer custody handover creation, supplier acceptance, accepted-return financial posting; use profileClient for auth.uid()-dependent RPCs; preserve existing PO/PR/RFQ/invoice/return/cash-custody branches.
- receive-purchase v13: mutually exclusive modes for existing PO po_code, Quick Market invoice_id, and Buyer custody receiving_id; preserve PO mode unchanged.
- create-stock-voucher v12: reuse rep_id → p_rep_id for Buyer Delegate; server Trigger/RPC validates custodian.
- send-stock-voucher v20: same request contract; SQL atomic path creates Buyer custody event for Buyer Delegate and no event for Supplier Direct.
- complete-stock-voucher v4: same request contract; linked return completion does not duplicate AP/GL.
- No new Edge function.

## Currency hardening
save-purchase-order v22 currently falls back to EGP if app_settings currency is absent. Change to fail closed on missing/invalid setting. SupplierReturn save and posting functions must resolve and validate company currency server-side.

## Current blockers/findings
- Buyer goods custody ledger not implemented.
- Receiver PO detail query uses po_code where schema has po_id; decimal parsing uses parseInt.
- Quick Market review is PO-only.
- purchase_returns tables expose direct DML grants and PUBLIC ALL policies.
- SupplierReturn UI/column default SAR while company currency EGP; posting functions ignore return_currency.
- Parent recipient column remains locked by main.html governance rule.

## Status
No operational source write, Production DDL/RPC/Trigger/RLS/grant/data change, Edge deployment, Cloudflare deployment, test fixture or authenticated E2E. Full exact RPC/Trigger/source diffs and rollback still require Report614_NEW_P / Master CTO §77.2.

**OPEN / NOT IMPLEMENTED / NOT PRODUCTION READY.**
