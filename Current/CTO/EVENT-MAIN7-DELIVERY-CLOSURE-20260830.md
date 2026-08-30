# EVENT-MAIN7-DELIVERY-CLOSURE-20260830

EVENT ID: MAIN7-DELIVERY-20260830-01
DATE: 2026-08-30
SOURCE: Current Git + Current Production Supabase + direct historical source inspection
OBJECTIVE: Close the remaining MAIN7 Delivery source defect without changing the Production Delivery contract or removing existing MAIN7 capabilities.

INPUT STATE:
- Current/PWA/main/main7.md was opened directly from current Git and its full blob was inspected without relying on a truncated report.
- The known open defect was a company_id predicate on order_details inside _openDeliveryModal().
- Current Production order_details does not contain company_id.
- Current Production complete-order-delivery is ACTIVE (v13), requires JWT, resolves company context through users.auth_id -> users.company_id, and invokes complete_order_delivery_atomic.
- Current Production complete_order_delivery_atomic updates order_details/order state and fulfillment aggregates; it does not perform Physical Stock mutation.

HISTORICAL CONTRACT:
The governing sequence is UNDERSTAND -> HISTORICAL CONTRACT -> CURRENT BEHAVIOR -> DATA/AUTH FLOW -> TARGET -> GAP -> SURGICAL FIX -> VERIFY. MAIN7 is orchestration/UI; Physical Stock mutation remains inside capability Edge/RPC layers.

CURRENT PRODUCTION FACT:
Production is currently a single-company dataset. Current stock invariants show zero negative qty, zero negative allocated_qty, zero available_qty mismatch, and zero branch/item company-cross rows.

CURRENT GIT FACT:
At closure start the invalid order_details.company_id predicate existed exactly once. Git compare proved the closure changed only Current/PWA/main/main7.md by one insertion and one deletion.

CURRENT EVIDENCE:
- order_details has no company_id.
- orders carries company_id and the Delivery query already obtains orders scoped by company_id + runsheet_id.
- order_details is therefore correctly reached through order_id.
- items.item_code has a formal UNIQUE constraint in Production.

DISCOVERY:
A historically reported companyId fix had regressed/reappeared in current main7 source. Current Git was therefore treated as higher-authority evidence than the historical claim.

ROOT CAUSE:
A previous reconstruction retained an obsolete tenant predicate on order_details after tenant ownership had already been established at the parent orders level.

BUSINESS IMPACT:
Delivery detail retrieval could fail because Supabase would reject a filter against a nonexistent order_details.company_id column.

ARCHITECTURAL IMPACT:
No change to the inventory/accounting architecture. Delivery continues to delegate completion to the Production capability.

DATABASE IMPACT:
None. No schema or business data was changed by this closure.

EDGE/RPC IMPACT:
None. The currently deployed complete-order-delivery v13 and complete_order_delivery_atomic remain unchanged.

FRONTEND IMPACT:
Exactly one predicate was removed from MAIN7 Delivery. Order-level company scoping, order_id relation, delivery calculations, stable operation identity, and Edge invocation remain intact.

CHANGE MADE:
Old:
.from('order_details').select('item_code,qty_loaded,qty_delivered').eq('company_id',companyId()).eq('order_id',orders[i].id)

New:
.from('order_details').select('item_code,qty_loaded,qty_delivered').eq('order_id',orders[i].id)

WHY:
The parent orders query is already company-scoped, and order_id is the relational path to its fulfillment detail. Adding a company_id column to order_details would invent unnecessary schema debt.

ALTERNATIVES REJECTED:
- Add company_id to order_details: rejected; unsupported by current schema and unnecessary.
- Replace order_details with run_sheet_details: rejected; would bypass the established order-level fulfillment detail contract.
- Rebuild MAIN7 again from scratch: rejected; would introduce avoidable functional loss.
- Change Production Delivery RPC: rejected; no Production evidence showed a backend Delivery defect.

MIGRATION:
None.

DEPLOYMENT:
The MAIN7 source fix was committed directly in Git commit cc6ea8fe881f5f3e9504adce6bb0c260870942e4. Temporary execution artifacts created during the attempted governed workflow route were subsequently removed/restored; no temporary executor remains.

COMMIT CHAIN:
- PRE-AUDIT: da36071d2bd7b11fa6352d458417052a7ce60bc7
- MAIN7 SURGICAL FIX: cc6ea8fe881f5f3e9504adce6bb0c260870942e4
- RESTORE PRE-TASK WORKFLOW: 7a3dea7b6e73f4f8b0ed0c573b6ba1d1b8fca0c9
- REMOVE TEMP EXECUTOR: 7fa4ae3f1bdb690ac72f1ccfb2b77a7d1660d19b

TEST:
- Git compare base -> fix reported exactly one file changed: Current/PWA/main/main7.md, 1 addition / 1 deletion.
- Full main7 blob was directly fetched and inspected.
- Current Production schema confirms order_details.company_id=false and items.item_code UNIQUE=true.
- MAIN7 source retains the Warehouse API and capability calls and contains no direct inventory_log insert or direct stock_branches update.
- Current Production writer inspection proves post_stock_movement is the sole Physical Stock mutation engine; reserve_stock/release_stock_reservation mutate allocated_qty only.

RUNTIME TEST:
Production Delivery backend contract was inspected directly. A read-only relation probe against orders -> order_details found no current Production order with a runsheet_id, so a positive browser delivery transaction could not be truthfully claimed from live data without fabricating a fixture. No fixture was fabricated.

PRODUCTION VERIFY:
Current Production re-read at 2026-08-30 05:16:52+00 for inventory integrity and current RPC/writer state; Edge versions re-read after the Git change.

DATA CLEANUP:
No data cleanup was justified for this source-only defect. No speculative records were deleted or altered.

AUDIT PRESERVATION:
No business/audit data was modified by the MAIN7 source change. Current stock-voucher audit trigger path remains deployed.

POST-CHANGE STATE:
MAIN7 Delivery no longer references order_details.company_id. Current Git is aligned for this fragment.

OBSOLETE STATE:
The invalid order_details company_id predicate is obsolete.

REMAINING OPEN ITEMS:
1. Final assembly/merge of main7 into the integrated Current/PWA/main.html (user explicitly requested this remain available for later manual merge).
2. Authenticated browser E2E of the assembled PWA Delivery path. This cannot be claimed while the current Production dataset has no eligible runsheet-backed order to exercise safely.
3. Full global writer discovery across every historical repository family remains a broader Inventory Zero-Debt activity; this MAIN7 closure did not pretend that a fragment fix equals global closure.

LATER CORRECTIONS:
None identified for MAIN7 Delivery from current evidence.

CURRENT SURVIVING STATE:
Current/PWA/main/main7.md is repaired in Git while preserving its existing module API and operational capabilities. Production backend was not altered because no backend change was necessary.

SOURCE REFERENCES:
- doc/Draft/medhat/MASTER EXECUTION PROMPT.md
- doc/Draft/medhat/تقرير 102
- Current/PWA/main/main7.md
- Current Production complete-order-delivery v13
- Current Production complete_order_delivery_atomic
- Current Production post_stock_movement
- Current Production RLS/grants/inventory integrity snapshot
