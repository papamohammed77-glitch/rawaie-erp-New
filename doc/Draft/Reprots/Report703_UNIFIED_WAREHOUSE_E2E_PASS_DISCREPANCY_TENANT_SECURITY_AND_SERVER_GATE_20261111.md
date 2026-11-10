# Report703 — نجاح اختبار المخزن، حماية بلاغات الاختلاف، ومانع الإنهاء الخادمي

**Recorded:** 2026-11-11 (Africa/Cairo)  
**Workstream:** Unified Warehouse / Returns / stock discrepancy tenant isolation / server-side posting gate  
**Disposition:** `FULL MOCKED WAREHOUSE E2E PASS + DISCREPANCY EDGE v4 DEPLOYED AND TRACKED + RLS/COLUMN GRANTS VERIFIED / SERVER-SIDE PENDING-DISCREPANCY COMPLETION GATE NOT IMPLEMENTED / PAGES PRODUCTION BEHIND CURRENT HEAD.

## 1. Checkpoint and operational source

تم الاستكمال من LVE-702 ومن عمل المساعدين المتزامن، دون إعادة بناء الوحدات أو استبدال مساراتها.

- Operational repository: `papamohammed77-glitch/erp-frontend` / `main`
- Verified current HEAD: `4f018bfe42ebfd3aeb668513a8bcb4cb3a29f8fb`
- `companies/company-1/warehouse/warehouse.html`: blob `b41b870d4a5df940043453563ed200e2e295d77c`
- `companies/company-1/warehouse/returns.html`: blob `3c4a35784f633f1c17d9bf1b3076040151d6f167`
- `.github/workflows/warehouse_hub_browser_e2e_20261110.yml`: blob `9efdf8c65c81258d3be712b85af318de1298163b`
- `supabase/functions/report-discrepancy/index.ts`: blob `e1ef1c3f465a842ddbd3a71c423fcce63f877664`
- Previous governance checkpoint: LVE-2026-11-11-702.

The latest branch was re-read after collaborator commits. No operational application or production database mutation was performed by this continuation.

## 2. Current Warehouse end-to-end result

Latest complete Warehouse workflow:
- Run: `42918104973`
- Head SHA: `4f018bfe42ebfd3aeb668513a8bcb4cb3a29f8fb`
- Job: `130185659855` (`standalone-warehouse`)
- Result: **completed / success**
- All steps succeeded: checkout, static source/module contract, Playwright install, local server, Browser E2E, diagnostics upload and cleanup.

### Verified Browser E2E markers

- Four-tab responsive shell and repeated navigation.
- Shared session/authentication and seven native operation bundles; no iframe/child-app navigation or duplicate Supabase client.
- Receiver PO and quick-market queue, sent-vs-accepted quantity limits, mandatory discrepancy reason, UUID idempotency, full rejection (zero accepted quantity), return-to-queue and completed audit history.
- Picker identity/profile rendering and pending data.
- Loader, Returns and Unloader pending lists.
- Completed-return reopen fail-closed UI.
- Discrepancy form derives item and expected quantity from the active runsheet item rather than client-supplied expected values.
- Session-scoped Returns local drafts: zero quantity and cleared notes restore correctly; a different session does not inherit the old draft.
- Counter tabs, vehicle/main/branch scope, general-count denial, session create/populate/save.
- Six native operational spaces, five manual voucher actions, SupplierReturn contract, voucher list/back/menu actions.
- Branch receipt requester/source actions, designated unified-role receiver, search/filter separation.
- Logout/re-login reinitialization, active warehouse-role gate, employee role aliases, and main-vs-scoped-branch gating.

**Test boundary:** the workflow uses mocked Supabase/auth responses and a stateful in-memory Dexie fixture. It is a full browser/UI contract pass, not a live employee transaction against production SMART ERP. It does not establish a real production JWT/RLS/RPC stock movement or actual accounting posting. No QA business fixture was created.

## 3. Tenant-safe discrepancy reporting v4

### Live Edge and source parity

Supabase project: SMART ERP `fiilmooggumokxanwiyx`.

- `report-discrepancy`: v4 ACTIVE, `verify_jwt=true`
- Live Edge SHA-256: `ada779ea5bf84ae2cb15c35407c2c439bc28eb91390a92365d8de3e64a55c8af`
- Live source length: 12,046 characters
- Tracked Git source blob: `e1ef1c3f465a842ddbd3a71c423fcce63f877664`
- Live `index.ts` content and Git `index.ts` content: **BYTE-FOR-BYTE MATCH**.

The v4 function now:
1. Resolves actor by authenticated `auth_id`, verifies Active status, same company and warehouse permission, and accepts only Returns role `مرتجعات` or unified role `مخزن شامل`.
2. Verifies the main warehouse branch is in the user's scope.
3. Loads runsheet by both `id` and actor company, requires `Returning`, and requires `return_handler_id = actor.id`.
4. Resolves the selected expected item from the same runsheet and derives `expected_qty = max(0, qty_loaded - qty_delivered)`.
5. Validates actual quantity and discrepancy type. For `wrong_item`, resolves actual code/barcode from the same company's item catalog and rejects if it is the expected item itself.
6. Inserts a pending discrepancy using the derived company/reporter/item details, then attempts an audit_log insert.

**Audit caveat:** the Edge logs an audit_log insert failure as a warning and still returns success. A discrepancy can therefore exist without its corresponding audit row if that audit write fails. This should be folded into an atomic writer in the next approved database contract change.

## 4. RLS and least-privilege table access

Production migration history contains:
- `20261110221847 secure_stock_discrepancies_tenant_access_20261111`
- `20261110222752 restrict_stock_discrepancy_supervisor_update_columns_20261111`

Live `pg_policies` confirms:
- SELECT: active same-company actor who is the reporter, a same-company supervisor/owner, or the assigned return handler for that same-company runsheet.
- UPDATE: active same-company `supervisor` or `owner` only.
- No authenticated or anonymous INSERT/DELETE policy.

Live PostgreSQL privilege checks returned:

| Privilege | anon | authenticated |
|---|---:|---:|
| SELECT | Denied | Allowed (RLS-scoped) |
| INSERT | Denied | Denied |
| DELETE | Denied | Denied |
| table-wide UPDATE | — | Denied |
| UPDATE `status` column | — | Allowed (RLS supervisor/owner policy) |
| UPDATE `notes` column | — | Allowed (RLS supervisor/owner policy) |
| UPDATE `company_id` column | — | Denied |
| UPDATE `runsheet_id` column | — | Denied |

Service role retains INSERT for the authenticated `report-discrepancy` server function. This closes the earlier client-side broad update/tenant-read/write exposure. The applied SQL migration files and live migration history were reconciled in this review.

## 5. Critical release blocker: pending discrepancy is still a client-only completion gate

Despite the secure v4 reporter and scoped RLS, the final return posting contract is not yet closed.

### Confirmed live behavior

- Standalone and embedded `completeReturn()` query `stock_discrepancies` for pending records before opening the final confirmation.
- On query error, the UI fails closed.
- If pending records exist, the UI tells the handler to wait for supervisor review.
- However, the deployed `complete-return v28` Edge source has **no** reference to `stock_discrepancies`.
- Live SQL functions `public.complete_return_atomic(...)` and `public.complete_sales_return_credit_note_atomic(...)` also have **no** reference to `stock_discrepancies`.
- A read-only scan of public SQL function definitions found no database function referring to the table.
- No trigger on `runsheets`, `run_sheet_details`, or `stock_discrepancies` enforces that pending discrepancy gate.

Consequently, an authenticated caller that invokes the existing `complete-return` Edge route directly, without going through the client UI, can currently bypass a pending discrepancy. This is not a hypothetical UI display issue; the authoritative server posting functions lack the gate.

### Consequences of bypass

`complete_return_atomic` is the transaction that can:
- update `order_details.qty_returned`, reason and driver liability;
- post `SalesReturn` stock movement via `post_stock_movement` / `inventory_log`;
- post inventory/COGS journal entries;
- post customer-ledger reduction or, for eligible POS cash returns, cash-box payment/refund;
- update order totals/status;
- rebuild `run_sheet_details` projection; and
- transition the runsheet from `Returning` to `Returned`.

`complete_sales_return_credit_note_atomic` calls the same core and then creates the Posted credit note. The current UI check alone does not protect these stock and financial effects from a direct endpoint invocation.

## 6. Proposed surgical ChangeSet — CS-WH-703-A (NOT APPLIED)

**Goal:** make a pending discrepancy a database-enforced stop condition for all run-sheet completion paths, without altering the business posting logic.

### A. Atomic discrepancy writer

Introduce a narrowly scoped SECURITY DEFINER database writer (e.g. `report_stock_discrepancy_atomic`) that:
- obtains the target runsheet row with `SELECT ... FOR UPDATE`;
- derives the tenant, active employee and assigned return handler from verified parameters / authoritative tables;
- requires the same company, status `Returning`, and `return_handler_id` equal to reporter;
- verifies item belongs to the runsheet and derives expected quantity in SQL;
- validates discrepancy type/quantity and resolves wrong-item identity in the same company;
- inserts the row and audit_log record in the same transaction;
- is executable by `service_role` only (revoke anon/authenticated/public).
The existing v4 Edge remains the JWT/role boundary but delegates the final write to this RPC. Duplicate client-side validation may remain for fast feedback but is not the security boundary.

### B. Completion gate in the locked SQL core

Modify `complete_return_atomic` only after its existing company-scoped runsheet `FOR UPDATE` lock and status check:
```sql
IF p_runsheet_code IS NOT NULL
   AND EXISTS (
     SELECT 1
     FROM public.stock_discrepancies d
     WHERE d.company_id = p_company_id
       AND d.runsheet_id = v_runsheet.id
       AND d.status = 'pending'
   )
THEN
  RAISE EXCEPTION 'RETURN_PENDING_DISCREPANCY_REQUIRES_SUPERVISOR_REVIEW';
END IF;
```
Keep `complete_sales_return_credit_note_atomic` using the same core; the check is centralized so every run-sheet completion path inherits it. Do not alter POS order-only returns unless they carry a run-sheet ID.

### C. Concurrency and index

The discrepancy writer and completion transaction must lock the **same runsheet row** before deciding:
- If the reporter locks first and commits the pending row, completion waits and then sees it; completion is rejected before stock or finance writes.
- If completion locks first and commits `Returned`, the reporter waits, reads the final state, and rejects the report; no new pending row is created after closure.

Add an index matching the lookup:
`CREATE INDEX ... ON public.stock_discrepancies(company_id, runsheet_id) WHERE status='pending';`
The existing table currently has only its primary-key index, so this partial index is part of the package.

### D. Preserve posting semantics and grants

- Preserve all current stock, ledger, driver-liability, journal, cash/treasury, order, credit-note and idempotency code in `complete_return_atomic`.
- Preserve current RLS/column privileges from migrations 21847 and 22752.
- Preserve existing Edge name and JWT mode; no new Edge Function required.
- Keep `reopen-return` and `reopen-receiving` fail-closed until a full atomic reversal lifecycle exists.
- Do not create a Supabase branch or paid environment.

### E. Acceptance tests / rollback

Read-only and transaction-rollback tests should prove:
1. Same-company assigned handler can report only a valid item in a Returning runsheet.
2. Wrong company, wrong handler, wrong role, inactive employee, unknown item, invalid quantity and invalid discrepancy type are rejected.
3. Existing pending discrepancy blocks `complete-return` before any data effect.
4. A resolved discrepancy allows completion.
5. Report-vs-complete concurrent requests serialize on the runsheet lock; exactly one safe outcome occurs.
6. Failed discrepancy audit insert rolls back the discrepancy row.
7. Compare before/after quantities and rows in `stock_branches`, `inventory_log`, `order_details`, `run_sheet_details`, runsheets, driver liability, customer/supplier ledgers, journal_entries, cash_box, treasury and credit_notes.
8. Confirm existing idempotency, POS refund rules and non-run-sheet order returns remain unchanged.

Rollback plan: reverse only the new writer/grant/index and restore the previous complete-return function definition from the captured live definition; do not reverse existing security policies or collaborator migrations. A tested, reviewed rollback script must accompany the approved ChangeSet.

**Approval status:** this proposal is not deployed and no production SQL/Edge change was executed by this continuation. Master CTO Governance §§77.2–77.3 require the owner to approve this exact ChangeSet before implementation.

## 7. Cloudflare Pages Production parity

Read-only Cloudflare dashboard snapshot still showed:
- Automatic deployments enabled.
- Production/main SHA: `83c0f395c34a5562752bc715a64361e675e2b20d`.
- Deployment shown: `https://e0ea2007.rawaea-erp.pages.dev/`.
- Current Git HEAD `4f018bfe...` was not the Production pointer.

The `83c0f39` artifact includes the earlier completed-return reopen disablement, but does not prove delivery of subsequent Returns local-draft, discrepancy reporting and RLS-related UI/source changes. Do not claim Pages Production parity or user-facing current-HEAD deployment.

## 8. SMART ERP production integrity — read-only snapshot

| Table | Rows |
|---|---:|
| `receiving` | 1 |
| `receiving_details` | 2 |
| `inventory_log` | 78 |
| `stock_branches` | 58 |
| `stock_vouchers` | 0 |
| `supplier_ledger` | 3 |
| `journal_entries` | 21 |
| `buyer_goods_custody_events` | 0 |
| `stock_discrepancies` | 0 |

Only company row remains `الروائع`, ID `00000000-0000-0000-0000-000000000001`. These are read-only counts; no test fixture, discrepancy, receipt, voucher, return completion, stock movement, reservation, ledger, journal, cash/treasury or credit note was created by this continuation.

## 9. Release disposition

- **CONFIRMED:** Warehouse full mocked Browser E2E succeeds on HEAD `4f018bfe`; local-draft zero/session isolation marker passes.
- **CONFIRMED:** `report-discrepancy v4` is deployed, JWT-protected and byte-identical to Git.
- **CONFIRMED:** tenant-scoped RLS and limited update columns are applied; auth cannot insert/delete and cannot update company/runsheet identity.
- **CONFIRMED:** unsafe completed-return and legacy receiving reopen remain fail-closed; picker and Returns cancel/reopen scope guards are deployed as recorded in LVE-702.
- **NOT CLOSED:** pending discrepancy is not checked in the authoritative completion SQL/Edge; direct complete-return call can bypass UI guard.
- **NOT VERIFIED:** Cloudflare Pages Production is behind current Git HEAD.
- **NOT PERFORMED:** authenticated real-employee posting E2E, production business write, or any mutation of stock/accounting data.

**Gold/Diamond status:** NOT CERTIFIED. The server-side completion gate and Pages deployment verification remain required.

## 10. Next actions

1. Present `CS-WH-703-A` for explicit owner approval; do not execute before approval.
2. After approval, implement the transactional report writer + completion gate + partial index, preserve all posting semantics, and deploy only the existing affected contracts.
3. Run concurrency and rollback tests proving no stock/financial write can pass while a discrepancy is pending.
4. Verify Pages Production equals the reviewed operational HEAD and test the published route with an authorized employee read-only session.
5. Resume any additional operational E2E only with an existing safe work item or an explicitly approved reversible fixture.

**Operational HEAD:** `4f018bfe42ebfd3aeb668513a8bcb4cb3a29f8fb`  
**Warehouse E2E:** `42918104973` — SUCCESS / mocked browser & Dexie / current HEAD  
**report-discrepancy:** v4 ACTIVE / Git parity PASS  
**Current Pages Production:** `83c0f395c34a5562752bc715a64361e675e2b20d` (behind HEAD)  
**Previous checkpoint:** LVE-2026-11-11-702.
