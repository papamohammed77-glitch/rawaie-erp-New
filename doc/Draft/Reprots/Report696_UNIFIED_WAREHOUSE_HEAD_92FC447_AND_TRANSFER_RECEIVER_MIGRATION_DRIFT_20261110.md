# Report696 — استكمال تدقيق المخزن الشامل بعد HEAD 92fc447 واختلاف Migration مسؤول الاستلام

**Recorded:** 2026-11-10 (Africa/Cairo)  
**Previous report:** Report695 — Unified Warehouse / Picker parity / backend gap audit  
**Disposition:** Current HEAD refreshed; latest Warehouse CI verified; migration not reapplied.

## 1. Current operational HEAD refreshed

- Current operational repo: papamohammed77-glitch/erp-frontend, branch main.
- Current HEAD: 92fc4475613b2bed597428191c1ac8b7da428449, commit message: test(warehouse): fix designated receiver migration guard regex, committed 2026-11-10T21:27:13Z.
- Five commits were added after 81bc832. Their subjects include designated standard-transfer receiver enforcement and active-role/assignment guards for loading reopen and cancellation.
- warehouse.html remains blob 31c4f1ae903b389269a4b90afdf310784f77f194; picker.html remains blob a94e18f1c7b2de5dad912011bb32999611976b8e. The five commits did not change either UI file.
- The new tracked Edge files cancel-loading/index.ts (blob fec7145558f0393da7edb08785e3157949ce147e) and reopen-loading/index.ts (blob 86bcd8982ad3d7abfd3665180331245c784216be) now import requireWarehouseRole/assertWarehouseMainBranch, validate the active Loading/Loaded state and loader_id assignment, and call the existing RPC. This addresses the earlier edge-wrapper inconsistency for these two operations. No need to patch either file again.

## 2. Latest Warehouse CI on current HEAD

- Run 42905190791, workflow RAWAEA — Standalone Unified Warehouse E2E, on HEAD 92fc447, completed with conclusion success.
- Job 130141231855 / standalone-warehouse succeeded. Static source/module contract and Playwright browser E2E both completed.
- Fresh log PASS markers include: four responsive tabs; shared auth/session; Picker normalized profile; pending data rendering in Picker/Loader/Returns/Unloader; three count modes; six native operation workspaces; five voucher actions; SupplierReturn contract; branch-receipt request/assignment workflows; logout/re-login; role aliases; main-vs-scoped branch gating.
- Same test limitation as Report695: the browser harness mocks Supabase/auth and fakes DB operations. It is not authenticated production E2E and does not prove stock, inventory_log, AP/GL, treasury, customer/supplier ledger writes.

## 3. Supabase migration registry and live trigger

- Git currently contains supabase/migrations/20261110222000_standard_transfer_requires_designated_branch_receiver.sql, blob 9c7acad5fcea614705c5f348d9f4a1be786ed34b, 381 lines.
- SMART ERP migration history contains version 20261110212138 named standard_transfer_requires_designated_branch_receiver_20261110. The active trigger trg_transfer_responsibility_contract on public.stock_vouchers is enabled (BEFORE DELETE OR UPDATE).
- Live database pg_get_functiondef(public.enforce_transfer_responsibility_contract()) returns 14,754 characters / 416 lines; the Git migration's function section is 13,365 characters / 380 lines. They are not equivalent.

### Specific live-vs-Git semantic difference

Live database function declares receiver_candidates uuid[] and constructs two candidate sets:
- eligible_voucher_role_receivers: active warehouse keepers in exact active role أذونات, with default_branch_id equal to the voucher destination and allowed-branch compatibility.
- eligible_full_role_receivers: active warehouse keepers in active role مخزن شامل, with destination/default-or-single-allowed-branch compatibility.
- eligible_receivers chooses the exact أذونات receiver list first; only when that list is empty does it fall back to the full-role candidates. It orders by user id and binds a single designated receiver.

The Git migration file instead counts and selects only exact أذونات users. It lacks the full-role fallback and candidate-priority CTE. Reapplying this Git migration could therefore replace the richer live rule with a narrower one and break the already deployed full-role receiver fallback.

**Action:** do not rerun or blindly deploy 20261110222000. The active production migration is recorded under a different version, and the tracked SQL is not an exact source representation of the live function. Recover the authoritative applied SQL or update the tracked migration/source to the exact live definition through a separate reviewed source-reconciliation change. Do not alter the live trigger/function in this task.

## 4. Consequences for unified warehouse

- The app-level branch-receipt flow remains covered by current mocked E2E and the live stock_vouchers trigger is enabled.
- The actual production rule prefers a designated أذونات receiver and uses a scoped مخزن شامل fallback only when no eligible أذونات receiver exists. Preserve this priority; do not simplify it to a blanket full-role receiver or to exact-role-only selection.
- This change does not resolve the independent Picker cancel/reopen role mismatch, Returns cancel role mismatch, or the unsafe completed-return reopen endpoint described in Report695.
- Cloudflare dashboard snapshot previously observed Production at commit 3748f4602c54961945c6e1ef74391a27ca3e6004. Current HEAD 92fc447 is still not verified as deployed.

## 5. Production safety and work performed

- Read-only verification only: inspected Git compare, current source blobs, current workflow logs, Supabase migration history, live trigger state and live function definition.
- No migration applied, no Edge function deployed, no operational app file changed, no role/user updated, no voucher or branch receipt created, and no stock/ledger/journal/cash table written.
- No Supabase branch or extra paid test environment created.

## 6. Updated acceptance status

**CONFIRMED:** HEAD 92fc447; warehouse.html and picker.html unchanged since prior audit; latest mocked Warehouse CI PASS; live trigger enabled; live full-role designated receiver fallback exists.

**NOT VERIFIED / BLOCKED:** current Cloudflare deployment parity; authenticated live user E2E; picker cancel/reopen role parity; returns cancel role parity; safe completed-return reversal; legacy reopen-receiving containment; authoritative Git source parity for the applied designated-receiver migration.

**Release remains blocked. Do not mark Warehouse Gold/Diamond or reapply the receiver migration until the live-vs-Git source drift is reconciled.**

Operational HEAD: 92fc4475613b2bed597428191c1ac8b7da428449  
Warehouse blob: 31c4f1ae903b389269a4b90afdf310784f77f194  
Picker blob: a94e18f1c7b2de5dad912011bb32999611976b8e  
CI run: 42905190791 (PASS; mocked Supabase)  
Live migration version: 20261110212138  
Git migration file: 20261110222000_standard_transfer_requires_designated_branch_receiver.sql