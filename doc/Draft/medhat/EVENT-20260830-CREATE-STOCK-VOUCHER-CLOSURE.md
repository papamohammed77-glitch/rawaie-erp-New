# EVENT — 2026-08-30 — CREATE-STOCK-VOUCHER CLOSURE

EVENT ID: EVT-INV-CREATE-VOUCHER-20260830-01
DATE: 2026-08-30
SOURCE: Current Production Supabase + Current Git + direct source inspection
OBJECTIVE: Close the create-stock-voucher dependency identified by historical MAIN7 closure work without reintroducing a parallel stock writer.

INPUT STATE:
- Historical Report 101 had marked create-stock-voucher as the remaining MAIN7 Production dependency.
- Current Production was re-investigated from PostgreSQL and live Edge Function deployments.
- Current Production inventory was clean: stock_branches=20 rows, negative qty=0, negative allocated=0, available mismatch=0, cross-company branch/item=0, cross-company inventory_log/item=0.

HISTORICAL CONTRACT:
- Physical stock movement must pass through post_stock_movement.
- Manual voucher lifecycle may create/update voucher records, but must not mutate Physical Stock independently.
- Item identity is formally global by UNIQUE(items.item_code).
- Reservation operations remain separate from physical movement.

CURRENT PRODUCTION FACT:
- create-stock-voucher was Production Edge version 9.
- It authenticates the user, derives company context from users.auth_id, normalizes item input, and calls create_manual_stock_voucher_atomic.
- operation_id / Idempotency-Key is accepted and routes to the 12-argument operation-aware contract; legacy requests remain compatible through the 10-argument path.
- Current manual voucher core routes physical movement through post_stock_movement.

CURRENT GIT FACT:
- Current/Edge_Functions/create-stock-voucher was aligned to the deployed Production contract and committed at 265c4f404601a2ad273ef4090f8ce1f42d6f693c.
- Current/PWA/main/main7.md already supplied operation_id when creating a manual voucher, so no destructive rewrite of main7 was required for this closure.

CURRENT EVIDENCE:
- stock_voucher_operations exists and is the operation-identity store used by the 12-argument manual voucher path.
- items.item_code is UNIQUE globally.
- stock_branches has FK/unique controls on branch_id + item_id.
- stock_vouchers has company-scoped voucher uniqueness.
- stock_voucher audit trigger exists.

DISCOVERY:
- Historical Report 101 correctly identified create-stock-voucher as open at that time; Production changed after that report.
- The current deployed Edge was already RPC-backed, so the historical blocker was obsolete.
- Current source still contained older/alternative direct-write history, but it is not the active Production path.
- Global Writer discovery found post_stock_movement as the physical movement writer; reserve_stock/release_stock_reservation are reservation-only; create_vehicle_atomic/setup_van_stock initialize zero-quantity stock rows and do not perform a physical movement.

ROOT CAUSE:
- Historical Production/Git drift: the report described an older direct-write deployment while current Production had already moved to the canonical RPC path.
- The remaining action was synchronization and verification, not another rewrite of the stock engine.

BUSINESS IMPACT:
- Manual voucher creation remains available without creating a second Physical Stock engine.
- Retry safety is strengthened for callers that provide operation identity.

ARCHITECTURAL IMPACT:
- Preserves the single Physical Stock writer contract.
- Keeps manual voucher lifecycle separate from stock mutation.

DATABASE IMPACT:
- No permanent data cleanup was required because current Production inventory invariants were already clean.
- Runtime tests were transactional and rolled back.

EDGE/RPC IMPACT:
- create-stock-voucher deployed to Production version 9 with operation-id aware dispatch.

FRONTEND IMPACT:
- MAIN7 already sends operation_id for manual voucher creation.
- Stand-alone vouchers compatibility path was preserved; it was not force-changed to require operation_id.

CHANGE MADE:
- Deployed create-stock-voucher Production version 9 with operation_id / Idempotency-Key support.
- Aligned Current/Edge_Functions/create-stock-voucher in Git to the deployed contract.

WHY:
- Close the historical dependency while preserving existing consumers and avoiding a breaking contract.

ALTERNATIVES REJECTED:
- Rewriting main7 from scratch: rejected because current main7 already had the required create operation-id behavior and destructive replacement was unnecessary.
- Requiring operation_id for all clients: rejected because stand-alone Vouchers.html still legitimately uses the compatibility path.
- Rebuilding the stock engine: rejected because Production already has the canonical post_stock_movement writer.

MIGRATION:
- Existing Production migration state was respected; no data-destructive migration was introduced for this closure.

DEPLOYMENT:
- Edge Function create-stock-voucher deployed to Production as version 9.

COMMIT:
- 265c4f404601a2ad273ef4090f8ce1f42d6f693c

TEST:
- Direct Production transaction exercised the 12-argument manual voucher contract.
- Reuse of the same operation identity returned duplicate behavior within the transaction.
- Transaction was rolled back.

RUNTIME TEST:
- PostgreSQL/RPC runtime verified.
- Fresh HTTP Edge runtime invocation after version 9 deployment was not available in the current 24-hour Edge log stream; therefore HTTP E2E is not claimed.

PRODUCTION VERIFY:
- Deployment version confirmed in Production.
- Current inventory invariants confirmed after deployment.

DATA CLEANUP:
- No permanent data cleanup was required.
- Historical cross-company inventory contamination is no longer present in current Production.

AUDIT PRESERVATION:
- stock_vouchers is protected by AFTER INSERT/UPDATE/DELETE audit trigger fn_audit_trigger().
- Transactional tests were rolled back, so no test audit pollution remains.

POST-CHANGE STATE:
- create-stock-voucher dependency is closed at the backend contract level.
- Physical Stock remains centralized.

OBSOLETE STATE:
- Historical Report 101 assertion that Production create-stock-voucher was still direct-write is obsolete for the current Production deployment.

REMAINING OPEN ITEMS:
- MAIN7 contains an independent Delivery source defect: it filters order_details by company_id although current Production order_details has no company_id column. This was not modified because it is outside the create-stock-voucher closure and requires a separate full-file-safe closure.
- Fresh browser HTTP E2E for create-stock-voucher was not observed in the current post-deployment Edge log stream.

LATER CORRECTIONS:
- Delivery source correction should be handled as a separate closure unit, preserving the current surviving main7 rather than rewriting history.

CURRENT SURVIVING STATE:
- Production create-stock-voucher: v9, active, RPC-backed.
- Current Git create-stock-voucher: operation-aware and aligned.
- Main7 create path: sends operation_id.
- Production stock invariants: clean.

SOURCE REFERENCES:
- doc/Draft/medhat/تقرير 101
- Current/PWA/main/main7.md
- Current/PWA/vouchers.html
- Current/Edge_Functions/create-stock-voucher
- Production public.create_manual_stock_voucher_atomic
- Production public.post_stock_movement
- Production stock_branches / inventory_log / stock_voucher_operations
