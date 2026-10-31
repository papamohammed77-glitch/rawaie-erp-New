# Report570 — Buyer Direct-Edit Gate, Current Contract Reconciliation & Safe Execution Decision

**التاريخ:** 2026-11-01  
**النوع:** CTO Current-Source Revalidation + Production Business-Contract Gate + Direct-Edit Decision  
**المستودع التشغيلي:** papamohammed77-glitch/erp-frontend — main  
**مستودع الحالة:** papamohammed77-glitch/rawaie-erp-New — main  
**Production:** Supabase SMART ERP — fiilmooggumokxanwiyx  
**الحالة:** CURRENT BUYER SOURCE RECONFIRMED / PURCHASE CONTRACT GAPS RECONFIRMED / DIRECT UI EXPANSION BLOCKED BY SERVER AUTHORIZATION + MISSING BUSINESS CONTRACTS / NO OPERATIONAL OR PRODUCTION MUTATION / NOT CLOSED

## 1. Governance and historical review

The execution resumed from CURRENT_STATE.md and its LAST VERIFIED EVENT, not from an old assistant memory.

- Previous checkpoint: LVE-2026-10-31-569 — Buyer Purchasing Workflow Forensic Audit.
- Operational repository HEAD re-read from GitHub: `65799d282acc79359b17a1a13dcd68f62859e1fb`.
- Buyer current blob: `6ba510cff5250ba196528b14237ae400e544771a`.
- Buyer path: `companies/company-1/purchasing/buyer.html`.
- Governance file CURRENT_STATE.md blob before this report: `b1752c5d85862db1a27e88330210ca91b9484cf0`.

### Reports 400–500 and Report545

Report545 was read as the consolidated governance review of the 400–500 report range. It records a direct inventory of 114 numbered reports, identifies duplicate report numbers and missing 490/491, and distills the relevant execution lessons. Its own text explicitly distinguishes that inventory and selected deep reads from opening every report individually; this report does not overstate that work as a full reread of all 114 files.

Relevant principles carried forward:
1. Revalidate live Git and Production before every patch; reports are historical evidence, not current truth.
2. Identify the exact execution owner and allowed mutation layer.
3. A surgical patch must specify exact file, function/marker, replacement boundary, impact, and tests.
4. Keep Source, Production, deployed artifact, and authenticated runtime as separate proof layers.
5. Do not introduce UI actions that call an unverified or unauthorized backend contract.
6. Do not mark a workflow closed from SQL success or source presence alone.

Report500 was read for the parent/core/standalone-app architecture map. It confirms the intended architecture: shared Auth/Profile/Core, central PostgreSQL/RPC/Edge contracts, and operational standalone apps; it also warns that the map is not proof that each app's permissions or E2E integration are complete.

Report421 was reviewed for the financial permission principle: do not grant anonymous access to financial RPCs to mask a client-session/permission error. Reports425/426/431 were consulted as finance/treasury control references. In particular, a cash balance or expense record is not proof of employee custody receipt, handover, and settlement.

Report569 was read in full for the Buyer-specific forensic baseline and contract gap analysis.

## 2. Current source verification

**CONFIRMED**
- Current Git branch HEAD remains `65799d282acc79359b17a1a13dcd68f62859e1fb`.
- Current Buyer blob remains `6ba510cff5250ba196528b14237ae400e544771a`, 15,051 characters / 137 lines.
- Current Buyer has only three tabs: Orders, New Order, Suppliers.
- Existing shared `RW_Auth` login and `RW_Realtime` subscription for `purchase_orders` are present.
- Current `submitPO()` still sends the legacy `{orderHeader, itemsList}` body.
- Production Edge `save-purchase-order` is ACTIVE v7, `verify_jwt=true`, SHA-256 `8e8c419c94796d8b802976ff8f3bb9717c039a8701a1523736cb531b2cc6a6cd`.
- The deployed v7 request contract requires `operation` and `payload`. It does not expose `CREATE_PO`, `SEND_PO`, or `APPROVE_PO`; the available PO creation path is `CONVERT_QUOTATION_TO_PO` after quotation acceptance.
- Production v7 operations include PR, RFQ, quotation, invoice, receipt, returns, payment, summary, reports, settings and data reads.
- A read-only Production schema query reconfirmed the actual columns:
  - `purchase_requests`: request_code/title/request_date/required_by/requested_by/status/notes/attachments/approved_by/approved_at; no department_id.
  - `purchase_request_details`: qty_requested and item identity; no received_qty or remaining_qty.
  - `purchase_orders`: po_code/po_date/supplier_id/supplier_name/total_amount/status/branch_id/created_by/notes; no expected_delivery_date/payment_terms/approved_by/sent_at.
  - `purchase_order_details`: qty_ordered/unit_price/qty_received/line_amount.
  - `suppliers`: supplier identity/contact/address/type/payment/accounts-payable fields; no email, A/B/C rating, supplier visit, or supplier rating fields in this table.
  - `purchase_attachments` exists with document type/id, file metadata and storage path/url.
  - `items` includes barcode, description, image_url and company_id.
  - `purchase_status_history` records action/actor_email/note/created_at, not changed_by/changed_at.
  - `purchase_payments` includes payment_method, but the current payment RPC does not accept it as an explicit argument (as documented in Report569).

## 3. CONFIRMED blockers that make broad UI implementation unsafe

### P0 — server-side authorization is not complete

The live v7 Edge source authenticates the user and resolves company_id, but Report569's byte-level inspection found no server-side permission matrix before service-role RPC execution and GET_DATA reads. Client-side Buyer permission gating is not a substitute for server authorization.

**Consequence:** adding operational buttons for approvals, invoice posting, returns, payments, or unrestricted purchasing reads would expand the visible attack surface without a proven server-side permission boundary.

### P0 — legacy PO form has no matching backend operation

The current form is a supplier + item cart, but v7 has no direct CREATE_PO operation. The valid backend sequence is PR → RFQ → quotation → accept quotation → convert quotation to PO. Mapping the legacy form to another operation would misrepresent the business event and could create the wrong document.

**Consequence:** do not relabel a direct cart save as CREATE_REQUEST, CREATE_QUOTATION, or CONVERT_QUOTATION_TO_PO. Those operations have different required identifiers and business semantics.

### P1 — RLS/profile permission conflict

Report569 documents that the effective profile includes role_permissions while the RLS helper current_user_has_permission does not; Buyer is gated by purchases but directly reads suppliers and items. This must be reconciled before asserting that a buyer account can safely read all required purchasing master data.

### P1 — PR, PO, supplier and custody contracts do not yet match the requested UI

- PR department and received/remaining presentation require a verified join/read model; do not fabricate columns.
- PO expected delivery, terms, approval and sending have no current persisted contract.
- Supplier email, A/B/C rating, visits and rating criteria lack verified persistence contracts.
- Buyer custody is not equivalent to supplier payments, treasury balance, or generic expenses. A dedicated auditable employee-custody lifecycle is not currently established by the verified schema.
- OCR is not a current Edge v7 operation. A camera capture can attach evidence, but extraction must not be presented as active OCR without a verified extraction service and review state.

## 4. Requested six-tab scope — disposition

| Requested area | Current evidence | Safe disposition |
|---|---|---|
| Today dashboard/cards | purchase_get_dashboard exists, but Report569 records unsafe direct RPC ACL/company binding and no buyer-specific alerts/overdue delivery date | Do not expose financial/dashboard read until caller/permission contract is fixed; shortage/overdue metrics need defined source rules |
| Suppliers | Core supplier table exists; rating/category/email/visits not persisted | Existing supplier list can be enhanced only after server read authorization; missing supplier attributes need approved data contract |
| PR | PR and details tables + CREATE/SUBMIT/APPROVE/REJECT operations exist | Read/create workflow can be designed after permission gate and PR history defect/company item guard are repaired and read model is verified |
| PO | PO tables/details exist; PO created from accepted quotation | UI must preserve PR→RFQ→quotation→acceptance→PO; no direct PO create/send/approve action may be invented |
| Buyer custody | No verified employee-custody ledger/workflow | Do not use treasury or supplier payments as a proxy; finance owner must define auditable receipt/spend/settlement contract |
| My account | RW_Auth effective profile is available in shared Core | Profile display can be sourced from Core, but approvals/settlements/reports remain unavailable until their respective contracts are verified |

## 5. Direct-edit decision and mutation ledger

The user explicitly authorized direct editing of `buyer.html` in this task, unlike the historical owner-only delivery tasks. That permission was recognized.

However, permission to edit the HTML does not make unsupported backend operations safe. The exact live source and backend contract were compared, and the blockers above are material, not cosmetic. A broad UI build now would either:
- call the incompatible legacy body and fail;
- mislabel a PR/quotation operation as a PO;
- expose data or financial actions without server-side permission proof; or
- display fabricated supplier, custody, department, approval, or delivery information.

Therefore the surgical decision for this checkpoint is **NO buyer.html write**. This is a deliberate fail-closed decision, not a claim that the requested UI is complete. No operational source, parent main.html, core.js, Edge Function, SQL schema, RLS/ACL, Production business row, or Cloudflare deployment was changed.

## 6. Exact next execution order

1. Establish and verify the server-side permission matrix for `save-purchase-order` v8, covering purchasing reads/writes, supplier reads/writes, approvals, and finance/treasury actions. Derive permissions from trusted effective-profile data; test allow/deny and cross-company cases.
2. Complete caller census and secure `purchase_get_dashboard` without breaking legitimate consumers.
3. Repair and isolate-test the PR history-column defect and company ownership checks on item lookups; verify trigger writes exactly once.
4. Approve business decisions and persistence contracts for PO delivery date/terms/approval/send, supplier category/rating/visits, payment method, and buyer custody.
5. Define read models for PR/PO timelines and received/remaining quantities, supplier price history, dashboard alerts, and account summaries.
6. Only then implement Buyer tabs/modals incrementally in the same file, preserving RW_Auth, RW_Realtime, shared Core and the existing standalone app. Each patch must be minimal and validated against the exact fresh blob.
7. Run static parsing and contract tests, then authenticated browser E2E and cross-app Receiver/Finance/Parent verification. Verify Cloudflare served artifact separately.

## 7. Verification matrix

| Layer | Result |
|---|---|
| GitHub operational source | CONFIRMED — HEAD and Buyer blob re-read |
| Supabase Production schema | CONFIRMED — read-only column inspection |
| Edge v7 request contract | CONFIRMED — live source retrieved; no direct PO op |
| Server-side permission completeness | CONFIRMED GAP per live source audit in Report569 |
| Cloudflare served Buyer artifact | UNVERIFIED |
| Authenticated browser E2E | UNVERIFIED |
| End-to-end PR→RFQ→quotation→PO→Receiver→invoice→payment | UNVERIFIED |
| Business custody workflow | UNKNOWN / no verified dedicated contract |

## 8. Final self-audit

- What changed in Buyer source: **nothing**.
- What changed in Production: **nothing**.
- What changed in deployment/runtime: **nothing**.
- What was freshly verified: current operational HEAD, Buyer blob, live Edge v7 status/source, and purchasing table columns.
- What remains open: P0 server authorization, direct PO semantic mismatch, RLS/effective-profile consistency, PR RPC defects, missing supplier/PO/custody contracts, and all authenticated runtime E2E.
- Closure: **OPEN — SAFE UI IMPLEMENTATION GATED BY BACKEND CONTRACT AND AUTHORIZATION REPAIR.**
