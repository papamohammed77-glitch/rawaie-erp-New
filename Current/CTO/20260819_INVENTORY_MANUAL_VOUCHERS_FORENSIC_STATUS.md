# RAWAEA ERP — 2026-08-19 Forensic Status

## Scope
Fresh source-first investigation of:
- `Current/PWA/main.html`
- `Current/PWA/vouchers.html`
- `rawaie-erp-review/Architecture/الأذونات المخزنية اليدوية.md`
- `doc/Draft/Hussin/برومبت 11 وتقريري تنفيذه`
- Production Supabase schema, RPCs, Edge Functions, and runtime verification.

## Proven current facts
1. Manual vouchers are a separate workflow from runsheets. Historical architecture defines: Transfer, DirectSale, DirectReturn, SupplierReturn, Scrap, Adjustment.
2. Current Production manual CREATE contract now supports: Transfer Branch→Branch; DirectSale Branch→Vehicle; DirectReturn Vehicle→Branch; SupplierReturn Branch→Supplier.
3. Vehicle stock is represented by a company branch `VAN-{vehicle_code}`; the live Production vehicle `VEH-92yrzb` has `VAN-VEH-92yrzb` initialized.
4. Physical stock mutations for the manual voucher lifecycle are routed through `post_stock_movement`; no second Physical Stock engine was introduced.
5. `items.item_code` is globally UNIQUE in the deployed schema. The CREATE contract therefore resolves item identity by global `item_code`/`item_id`; Branch/Vehicle/Supplier/header context remains company-scoped.
6. Manual voucher `reference` is now enforced in Production for `source='Manual'` by a database CHECK constraint.

## Production changes actually applied
- Migration `20260819_manual_voucher_vehicle_stock_contract`
  - corrected DirectSale/DirectReturn vehicle semantics;
  - kept all stock mutation through `post_stock_movement`;
  - made direct vehicle movements complete atomically after the movement;
  - retained Transfer as Draft→Sent→Receive→Complete workflow.
- Migration `20260819_manual_voucher_lifecycle_company_scope`
  - removed `app_settings LIMIT 1` dependency from CANCEL/COMPLETE;
  - made both operations company-scoped and idempotent for already-final states.
- Migration `20260819_manual_voucher_reference_required`
  - enforced non-empty reference for manual vouchers.
- Production Edge capabilities `complete-stock-voucher` and `cancel-stock-voucher` were deployed and verified as the runtime capabilities used by the updated UI.

## `vouchers.html` closure implemented
Git commit: `2b31d238d53fe15e7edd3556fe6bc0ea9bb11e41`

The file itself was surgically upgraded; no new UI file was created.

Implemented:
- authenticated company resolution from the current Supabase user;
- company-scoped voucher header reads;
- company-scoped Branch / Vehicle / Supplier reference data;
- real source/target selection instead of hardcoded `MAIN`/empty destination;
- mandatory reference field;
- Transfer / DirectSale / DirectReturn / SupplierReturn type-specific routing;
- read-only historical semantics for unsupported Scrap/Adjustment creation (not invented because current Production CREATE contract does not support them);
- voucher details with source, target, reference, notes, quantities, received quantities and remaining quantities;
- CANCEL capability for Draft;
- COMPLETE capability for Received;
- partial RECEIVE UI with per-line quantities and stable browser operation identity;
- existing Send capability preserved;
- removal of client-side Physical Stock mutation; all movement remains backend/RPC controlled.

## Production runtime verification
A Production-only forensic test was executed inside a PL/pgSQL subtransaction and intentionally rolled back after verification.

Verified in the real deployed database:
- DirectSale: MAIN physical stock decreased by exactly 1; one `DirectSale` inventory log was produced; final voucher status `Completed`.
- DirectReturn: one unit moved Vehicle→MAIN and restored the tested MAIN stock balance; one `DirectReturn` inventory log was produced; final voucher status `Completed`.
- Transfer: Branch→Branch Send produced status `Sent`; RECEIVE completed through `post_manual_stock_voucher_atomic`; status became `Received`; COMPLETE then produced `Completed`.
- All three flows passed through `post_stock_movement`.
- Final Production cleanup check returned:
  - forensic vouchers = 0
  - forensic inventory logs = 0

## Audit / governance
- `stock_vouchers` audit trigger path is `trg_audit_stock_vouchers` → `fn_audit_trigger()`.
- The audit trigger records INSERT/UPDATE/DELETE with JWT email when available and `system` fallback.
- No new parallel stock writer was introduced.
- `main.html` was not modified by this closure.

## Remaining known gaps / conflicts
1. Historical architecture contains Scrap and Adjustment as manual voucher types, but the current deployed CREATE contract does not support them. They are intentionally NOT exposed as fake UI options.
2. Production-only Edge files `complete-stock-voucher` and `cancel-stock-voucher` are now deployed; the canonical `Current/Edge_Functions` directory did not contain those files during this task. This is a documented Production/Current Git drift and should be reconciled in the next governance pass rather than hidden.
3. Purchase receiving idempotency remains a separate closure unit; it was not silently counted as closed by this voucher task.
4. Global Inventory Core Integrity remains incomplete until the remaining writer closure units in the governing directive are independently closed.

## Final status for this task
- Manual voucher UI gap: CLOSED for the capabilities proven by current Production backend.
- Manual voucher vehicle semantics: CLOSED at Production contract level.
- Hardcoded source/target UI defect: CLOSED.
- Mandatory reference gap: CLOSED.
- Cancel / Complete / Partial Receive UI gap: CLOSED for current Production contract.
- Physical Stock ownership: remains centralized through `post_stock_movement`.
- Scrap / Adjustment creation: intentionally NOT CLOSED because the current Production CREATE contract does not support them; no invented behavior was added.

## Memory anchor
This document is the current forensic memory anchor. The next CTO must reread it, verify Production again, and not infer that any remaining historical six-type gaps are implemented merely because the UI is polished.
