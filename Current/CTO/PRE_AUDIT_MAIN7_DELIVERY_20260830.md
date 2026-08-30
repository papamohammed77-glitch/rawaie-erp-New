# PRE-AUDIT — MAIN7 DELIVERY — 2026-08-30

Business Understanding: MAIN7 orchestrates warehouse UI flows; Delivery reads order-level fulfillment detail and invokes the Production delivery capability.
Architecture Understanding: Physical stock mutation remains behind canonical Edge/RPC capabilities; MAIN7 must not mutate stock directly.
Database Understanding: current Production order_details has no company_id; orders carries company_id and order_id is the relation to order_details.
Historical Understanding: Reports 89-102 and the governing execution prompt were reviewed; Report 102 identified the remaining Delivery predicate defect.
Current Git Understanding: current main7.md directly contains one order_details query with an obsolete company_id predicate.
Current Production Understanding: complete-order-delivery is active and its backend resolves company_id from authenticated users before invoking complete_order_delivery_atomic.
Deployment Understanding: main7.md is a source fragment; integrated browser deployment occurs after manual assembly into the final PWA.
Runtime Understanding: source-level contract can be proven directly; full browser E2E is not a claim for an unassembled fragment.

Confirmed Facts:
- main7 current Git contains the obsolete predicate exactly once.
- order_details has no company_id in Production.
- orders is company-scoped in the Delivery flow.
- complete-order-delivery Production capability is active.

Unknowns:
- exact timing of final assembled main.html deployment after fragment merge.

Conflicts:
- historical "solved" claim conflicts with current Git source; current Git wins.

Unverified Claims:
- no browser E2E claimed for this fragment-only closure.

Production Opened: YES
Current Git Opened: YES
Historical Opened: YES
Schema Checked: YES
Triggers Checked: YES (for relevant inventory/audit paths)
RLS Checked: YES (current relevant policy state inspected)
Permissions Checked: YES (relevant capability grants inspected)
Consumers Checked: YES (repository consumer search performed)
Dependencies Checked: YES
Git History Checked: YES (historical closure reports and current workflow state)

DECISION: perform one surgical predicate removal only; do not add schema columns, do not rewrite main7, and do not alter Delivery Edge/RPC behavior.