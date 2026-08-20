# RAWAEA ERP — HISTORICAL EXECUTION SEQUENCE
## Hussin Prompt 11 → Prompt 39

**Purpose:** This document is the consolidated historical memory anchor for the Hussin execution series. It reconstructs the sequence from the original GitHub source files, preserving the chronology, technical intent, proven execution, discovered regressions, Production contracts, Git anchors, and unresolved boundaries.

**Source of truth rule:** The original Prompt/Execution files are authoritative for what each step claimed or requested at that historical point. This document does not convert an historical PASS into a current Production PASS. Current Production must always be re-verified before further execution.

---

## 0. Governing Working Method Repeated Through the Series

Across Prompts 11–39 the controlling method is consistent:

1. Investigate current Git/Production directly.
2. Do not trust memory, earlier reports, or assumptions.
3. Preserve valid previous work; repair invalid work surgically.
4. Do not invent missing backend contracts merely to make the UI appear complete.
5. Keep Physical Stock mutation behind the central inventory engine.
6. Prefer Company/Tenant-scoped identity over global or hard-coded context.
7. Verify actual Production behavior separately from Git source state and from hosting/browser state.
8. Record the state in Git as a memory anchor.

The series progressively moved from manual-voucher completion into broader warehouse-supervisor, tenant-isolation, inventory-engine, UX, and final Gold Master work.

---

# 1. PROMPT 11 — Manual Voucher Forensic Baseline

**Primary goal:** investigate the role of non-runsheet manual stock vouchers and compare the current `vouchers.html` with the historical manual-voucher contract, `main.html`, and `picker.html`.

**Source:** `doc/Draft/Hussin/برومبت 11 وتقرير تنفيذه`

**Main findings recorded at the time:**
- Historical manual-voucher domain covered six types: Transfer, DirectSale, DirectReturn, SupplierReturn, Scrap, Adjustment.
- Current Production-supported Voucher lifecycle initially proved only four types: Transfer, DirectSale, DirectReturn, SupplierReturn.
- `vouchers.html` was incomplete compared with the historical business contract.
- Missing areas included source/target selection, reference, cancel/complete, partial receive, Scrap/Adjustment lifecycle support, and formal vehicle/supplier endpoints.
- Prompt 11 deliberately refused to treat Scrap/Adjustment as implemented without a Production CREATE contract.

**Historical closure snapshot:** 2/7 required inventory Writer Closure Units fully closed; this was a closure-unit percentage, not a system completion percentage.

**Memory anchor recorded:** `Current/CTO/20260819_INVENTORY_MANUAL_VOUCHERS_FORENSIC_STATUS.md`

---

# 2. PROMPT 12 — First Surgical Voucher Completion

**Primary goal:** surgically complete `Current/PWA/vouchers.html` without creating a parallel UI file.

**Source:** `doc/Draft/Hussin/برومبت 12 وتقرير تنفيذه`

**Implemented:**
- Real Company context from the authenticated session.
- Company-scoped voucher reads.
- Real source/target selection instead of hard-coded MAIN.
- Transfer, DirectSale → Vehicle, DirectReturn ← Vehicle, SupplierReturn.
- Required reference.
- Full voucher details.
- Draft cancel.
- Completion.
- Partial receive quantities.
- Receive operation identity.
- Removal of direct Physical Stock mutation from the UI.

**Production changes recorded:**
- `20260819_manual_voucher_vehicle_stock_contract`
- `20260819_manual_voucher_lifecycle_company_scope`
- `20260819_manual_voucher_reference_required`
- Published `complete-stock-voucher` and `cancel-stock-voucher`.
- Vehicle contract fixed to Branch → Vehicle for DirectSale and Vehicle → Branch for DirectReturn.

**Runtime verification:** transactional forensic tests for DirectSale, DirectReturn, and Transfer; all Physical movement passed through `post_stock_movement`; test data was rolled back.

**Git anchor:** commit `8607614cd647674ede009182c439f229d9d038b7`

**Historical state:** Manual Voucher UI gap closed; Vehicle Voucher Contract closed; Physical Stock ownership centralized; overall Inventory Core still not 100% closed.

---

# 3. PROMPT 13 — Gold/Diamond Voucher UX

**Goal:** evolve `vouchers.html` toward the Gold/Diamond UX of `picker.html`, move manual-voucher selection to the header, and preserve the inventory-rescue architecture.

**Source:** `doc/Draft/Hussin/برومبت 13 وتقرير تنفيذه`

**Implemented:**
- Gold/Diamond voucher UI direction.
- Header-based voucher type selection.
- Bottom tabs restricted to operational views instead of voucher types.
- DirectReturn route corrected to Vehicle → Branch.
- No direct UI writes to `stock_branches` or `inventory_log`.

**Important architectural decision:** Scrap and Adjustment remained unavailable as Manual Voucher CREATE/Lifecycle contracts because Production still lacked a proven voucher lifecycle for them.

**Git anchors recorded:**
- Main change: `c391695188eed6570e205752e8503ae1b60d08f1`
- DirectReturn surgical correction: `6c8e83697f8182790d79a019cb3483494c0b940a`
- Final voucher blob at the time: `a8d6726c037ed45157ec5cfadce63cbf791babb6`
- Memory update: `df6819865f48cbc6ad065e48ff80ad5dd44b36a5`

---

# 4. PROMPT 14 — Comparative Contract Audit

**Goal:** compare the current voucher app against Original voucher UI, `main.html`, `picker.html`, historical manual-voucher architecture, and current Production contracts.

**Source:** `doc/Draft/Hussin/برومبت 14 وتقرير تنفيذه`

**Important conclusion:** historical six-type manual-voucher language did not mean Production had six equivalent Voucher lifecycle contracts.

**Proven distinction:**
- Voucher lifecycle: Transfer / DirectSale / DirectReturn / SupplierReturn.
- Stock Engine operations: Scrap / Adjustment through the Adjustment Engine.

**Critical finding:** Prompt 15 later over-claimed completeness; Prompt 16 directly disproved that claim by testing the actual current blob.

---

# 5. PROMPT 15 — Six-Type Header and Broader Voucher Completion

**Goal:** complete historical roles and manual-voucher types, keep all UI work in `Current/PWA/vouchers.html`, and create a Gold/Diamond master-like interface.

**Source:** `doc/Draft/Hussin/برومبت 15 وتقرير تنفيذه`

**Historical claim recorded:** six types appeared in the header; Scrap/Adjustment were represented through the Adjustment Engine rather than as fake stock vouchers.

**Git anchors recorded:**
- Historical build commit `12265fb8eb2c65df3d2c50206852fc80b66b28e9`
- Later recorded source commit `d32b5b38026417d88cb05d7a265d21678dd59958`
- Historical blob `9f11a3e9585945a3cda9aa25cedc667c784c4b55`

**Important later contradiction:** Prompt 16 proved that this version still contained executable defects (`App.chooseEngineType` missing and account-tab handler mismatch). Therefore Prompt 15 must be treated as a historical implementation claim, not a current PASS.

---

# 6. PROMPT 16 — Regression Discovery and Commit-Merge Clarification

**Goal:** investigate the apparent “complete” voucher file and explain/resolve commit-vs-file deployment confusion.

**Source:** `doc/Draft/Hussin/برومبت 16 وتقرير تنفيذه`

**Forensic defects proven:**
- Header invoked `App.chooseEngineType('Scrap')` and `App.chooseEngineType('Adjustment')` while the function was missing.
- `switchTab('account')` invoked `this.account()` while only `renderAccount()` existed.
- Thus Scrap/Adjustment controls and the Account tab were not actually functional.

**Production contract reaffirmed:**
- Transfer / DirectSale / DirectReturn / SupplierReturn = real Manual Voucher lifecycle.
- Scrap / Adjustment = Adjustment Engine operations, not fake Voucher lifecycle.

**Historical conclusion:** do not publish blob `9f11a3e...` unchanged.

**Key governance lesson:** a Git commit is not a separate runtime patch; the file at the target branch contains the merged state. The user repeatedly requested a single directly publishable `Current/PWA/vouchers.html`, which became a later explicit constraint.

---

# 7. PROMPT 17 — Surgical Handler Repair

**Goal:** repair the Prompt 16 regression inside the same voucher file, without losing previous work.

**Source:** `doc/Draft/Hussin/برومبت 17 وتقرير تنفيذه`

**Implemented in `Current/PWA/vouchers.html`:**
- `chooseVoucherType()`
- `chooseEngineType()`
- `newVoucher()`
- `newEngineOperation()`
- `account()` / `renderAccount()` compatibility

**Architecture retained:** four Voucher lifecycle types + two Engine Operations.

**Git anchors recorded:**
- Commit `968f8ec6123a8b55256073e16b61f40c408826ab`
- Blob `46a632a73ea0a65dc66ac12a94f9e85f0f7ea130`

---

# 8. PROMPT 18 — False Session Expired Gate

**Goal:** investigate why opening vouchers showed “انتهت الجلسة” instead of allowing login.

**Source:** `doc/Draft/Hussin/برومبت 18 وتقرير تنفيذه`

**Root cause proven:**
- `RW_Auth.init()` correctly returns `NO_SESSION` for a first-time visitor.
- `vouchers.html` incorrectly converted `NO_SESSION` into “انتهت الجلسة” and forced reload.

**Surgical fix:**
- `NO_SESSION` now leaves the login screen visible.
- Real session-restoration errors are logged rather than blocking login.
- Successful `signInWithPassword` reinitializes the application.

**Important non-cause:** Tailwind CDN warning was confirmed unrelated.

**Execution:** fix applied through GitHub main using a temporary one-shot workflow, which was then removed; experimental PR was closed.

**Historical verification note:** hard refresh was required to avoid stale browser/service-worker content.

---

# 9. PROMPT 19 — Warehouse Workforce Roles + vouchers@rawaea.com

**Goal:** redesign warehouse workforce role assignment and investigate `vouchers@rawaea.com` login failure.

**Source:** `doc/Draft/Hussin/برومبت 19 وتقرير تنفيذه`

**Production role model proven:**
- Base warehouse role: `مخزني`.
- Operational role: `active_warehouse_role`.
- Supported tasks included Receiving, Picking, Loading, Returns, Unloading, Vouchers, Counting, Backup.

**Warehouse Supervisor fixes:**
- Access restricted to supervisor/Owner authorization.
- Direct `users.update()` replaced by `set_active_warehouse_role(uuid,text)`.
- RPC enforces same company, warehouse-supervisor authorization, warehouse-worker role, and closed task list.

**vouchers@rawaea.com data repair recorded:**
- role = `مخزني`
- active_warehouse_role = `أذونات`
- company_id = main company
- Production audit recorded the data change.

**Login finding:** account existed, email confirmed, password hash existed; HTTP 400 occurred at `signInWithPassword`, before application initialization. Role was not the direct cause.

---

# 10. PROMPT 20 — Warehouse Supervisor JavaScript Parse Failure

**Goal:** investigate supervisor app stuck at login with `Unexpected string` and `App is not defined`.

**Source:** `doc/Draft/Hussin/برومبت 20 وتقرير تنفيذه`

**Root cause:** malformed JavaScript generated inside `renderRoster` in `warehouse.supervisor`:
`onchange="App.updateRole(\\''+emp.id+'\\',this.value)"`

**Fix:** use data attribute:
`data-user-id="..."` and `App.updateRole(this.dataset.userId,this.value)`.

**Validation:** Node syntax check passed; old broken pattern no longer found.

**Important context checks:** core.js and Service Worker were not the cause; Production supervisor authorization was already valid.

---

# 11. PROMPT 21 — Warehouse Supervisor Company Context Error

**Goal:** investigate `خطأ سياق الشركة غير محدد`.

**Source:** `doc/Draft/Hussin/برومبت 21 وتقرير تنفيذه`

**Root cause proven:**
- `RW_Auth.checkWarehouseRole()` exposes `public.users.id` as `user.id`.
- `warehouse.supervisor` incorrectly queried `.eq('auth_id', user.id)`.
- Correct lookup is `.eq('id', user.id)`.

**Production identity verified:** supervisor account, `public.users.id`, `auth_id`, role, status, and company were all valid.

**Fix:** surgical lookup correction in `Current/PWA/warehouse.supervisor`.

**Git anchors:**
- Fix commit `f0b668bdf12615bc8965dd8f1090a4079b8da814`
- Final blob `eba134d1cd9878b6e801782371d1c82dbcb94d84`
- Documentation commit `0b292eda2b63bc6f901b062f0f1082216042599a`

---

# 12. PROMPT 22 — Warehouse Supervisor Team Scope

**Goal:** show only the supervisor’s warehouse team and allow task reassignment.

**Source:** `doc/Draft/Hussin/برومبت 22 وتقرير تنفيذه`

**Implemented:**
- Team filtered by supervisor branch scope (`default_branch_id + allowed_branch_ids`).
- Only active warehouse workers in scope shown.
- Task reassignment through `set_active_warehouse_role()`.
- Closed task list: Receiving, Picking, Loading, Returns, Unloading, Vouchers, Counting, Backup.

**Security hardening:** branch-level scope was enforced in the Production RPC, not only in JavaScript.

**Runtime tests:** positive assignment and negative cross-branch assignment; both transactional and rolled back.

**Production snapshot:** 5 active warehouse workers; no separate active `أمين مخزن` role.

**Git anchors:**
- Supervisor app commit `36db0401e9ab4e14932272687440689de52477fa`
- Blob `9c9047996b674de6143b5f802958c4673bb0f9ce`
- CTO evidence document `Current/CTO/20260820_WAREHOUSE_SUPERVISOR_TEAM_SCOPE_FORENSIC_FIX.md`

---

# 13. PROMPT 23 — Re-execution After a Destructive Regression

**Goal:** redo the warehouse-supervisor team assignment work surgically because a previous version had collapsed/losing functions.

**Source:** `doc/Draft/Hussin/برومبت 23 وتقرير تنفيذه`

**Result:** task-team UI rebuilt surgically in the same file, retaining existing application behavior.

**Team behavior:** only active workers in overlapping supervisor scope; role/title kept separate from current operational task.

**UX additions:** branch scope card, counts, search, current/new task display, individual assignment.

**Security:** still enforced by `set_active_warehouse_role()` with company + authorization + worker role + task list + branch overlap.

**Git anchors:**
- Main surgical commit `8966d8b1ccc2388ee9a6a25688fcadd5b62d5d98`
- Final blob `8f2a0937e86fb8a722ddb6ca77500ec32d68c0fe`
- Temporary execution cleanup commit `9105dce48ab850029f207b082d3a37d3c9ac5087`

---

# 14. PROMPT 24 — Table-Based Team Assignment UX

**Goal:** replace a less-clear team assignment design with a table containing one row per worker, per-worker task dropdown, and individual Save button.

**Source:** `doc/Draft/Hussin/برومبت 24 مع تقرير تنفيذه`

**Implemented:**
- Table columns: worker, title, worker scope, current task, new task, state, action.
- Individual dropdown + Save button.
- No full-list redraw after save.
- Search preservation.
- Mobile card transformation.
- Same `set_active_warehouse_role()` security boundary.

**Git anchors:**
- Commit `83f6b7f36ff7a8445bc76100b66cf60395838639`
- Blob `392bdd772f8a20b41329090d82707eb448353c1c`

---

# 15. PROMPT 25 — Team Data Read Was the Real Missing Piece

**Goal:** explain why the team table appeared empty despite the correct UI.

**Source:** `doc/Draft/Hussin/برومبت 25 مع تقرير تنفيذه`

**Root cause:** direct `public.users` read was blocked by RLS for the supervisor; the UI existed but received zero rows.

**Correct solution:** create Production RPC `get_warehouse_team()` enforcing Company Isolation, Supervisor Authorization, Branch Scope, and Warehouse Worker role.

**Runtime:** actual supervisor identity returned BR-01 + five workers; test rolled back.

**Source update:** `Current/PWA/warehouse.supervisor` changed to use `supabase.rpc('get_warehouse_team')`.

**Git anchors:**
- Commit `5c6c0612f6cc7473c38853c26d6e4f7bb6d1b249`
- Blob `38efd5eccf83a5540a1fa29689b93beaa75c7adf`
- CTO evidence record `Current/CTO/20260820_WAREHOUSE_SUPERVISOR_TEAM_READ_SCOPE_FORENSIC_FIX.md`

**Important historical distinction:** Git/Production were fixed, but external browser/hosting freshness was not independently proven at that point.

---

# 16. PROMPT 26 — vouchers Login Invalid Credentials + Recovery

**Goal:** investigate persistent vouchers login HTTP 400.

**Source:** `doc/Draft/Hussin/برومبت 26 وتقرير تنفيذه`

**Root cause proven:** Auth `grant_type=password` returned `invalid_credentials`; the account, role, company and email identity were valid, and other users logged in successfully through the same Auth endpoint.

**Correct response:** do not guess/change password manually. Add official password recovery flow.

**Implemented:**
- `resetPasswordForEmail()` recovery link.
- Recovery screen.
- `updateUser({password})`.
- Recovery session logout and return to login.

**Historical Git anchor:** `a7aaa2cc1f326709a0623dfd2246f22c4af3c8f1`

---

# 17. PROMPT 27 — Main App Company Isolation Audit

**Goal:** determine whether creating/editing users, items, branches, customers, suppliers, financial accounts, etc. from `main.html` could cross tenant boundaries.

**Source:** `doc/Draft/Hussin/برومبت 27 وتقرير تنفيذه`

**Root cause proven:** several main-application Edge Functions used hard-coded main-company IDs or unscoped lookups.

**Affected capabilities explicitly recorded:**
- save-employee
- save-item
- save-branch
- save-customer
- save-supplier
- save-role
- save-settings
- save-journal-entry

**Production versions recorded after remediation:**
- save-employee v7
- save-item v8
- save-branch v3
- save-customer v3
- save-supplier v3
- save-role v6
- save-settings v12
- save-journal-entry v6

**New rule:** authenticated user → `users.auth_id` → `users.company_id` → current tenant → CRUD.

**Financial account issue:** `chart_of_accounts` was being mutated directly from main.html and RLS was effectively open. Production was changed to enforce company-scoped SELECT/INSERT/UPDATE/DELETE and company-derived `company_id` defaults.

**Data-integrity improvements:** category/branch/company checks, allowed-branch validation for employees, Auth-user cleanup on employee creation failure, same-company account validation for journal entries.

---

# 18. PROMPT 28 — Central Inventory Engine Global Review

**Goal:** verify that all corrected Edge Functions remain aligned with the unified central engine plan and that future work follows the same architecture.

**Source:** `doc/Draft/Hussin/برومبت 28 وتقرير تنفيذه`

**Central contract proven in Production:**
`Business Operation → Domain RPC → post_stock_movement → stock_branches + inventory_log`

Reservation remains separate:
`Picking → reserve_stock → allocated_qty`

**Functions verified as centralized:**
- post_inventory_adjustment_atomic
- post_manual_stock_voucher_atomic
- receive_purchase_atomic
- send_stock_voucher_atomic
- save_sales_invoice_atomic
- complete_return_atomic
- complete_runsheet_loading
- complete_runsheet_picking (reservation only)
- reserve_stock
- release_stock_reservation

**Important Git drift discovered:** an old `Current/Edge_Functions/complete-loading` still directly updated `stock_branches` and inserted `inventory_log` even though Production v11 was already centralized.

**Fix:** Current wrapper updated to delegate to `complete_runsheet_loading` / central movement engine.

**Git anchor:** `bd66bab8a4ad55f7df32f24c75a82133cf7b1688`

**Important unresolved point:** RECEIVE PURCHASE idempotency still required Consumer-side operation identity; this could not safely be faked in the Edge layer.

---

# 19. PROMPT 29 — POS-Style Voucher Workspace

**Goal:** replace simple item-selection SweetAlert with a POS-like working area while preserving Voucher and Engine contracts.

**Source:** `doc/Draft/Hussin/برومبت 29 وتقرير تنفيذه`

**Implemented in `vouchers.html`:**
- Catalog + Cart desktop workspace.
- Mobile cart drawer.
- Search by name/code/barcode/search_label.
- Exact-match/prefix/name ranking.
- Keyboard navigation and shortcuts.
- POS-style item cards.
- Source available quantity display.
- Quantity guard against branch stock.
- Categories.
- Live cart controls.
- Draft save / execution from the same workspace.

**Inventory safety:** no new Physical Stock writer; Voucher creation still through `create-stock-voucher`, Engine operations through `bulk-stock-adjustment`.

**Git anchor:** `4cfcee850e088c2ef366411dd9c255bd755771a8`

**Historical closure:** Git source implemented; Production runtime/browser deployment not yet independently verified.

---

# 20. APPENDIX TO PROMPT 29 — Consolidation/Follow-up Record

**Source:** `doc/Draft/Hussin/ملحق برومبت 29 وتقرير تنفيذه`

This appendix is part of the historical sequence and must be retained in future CTO handoff context. It continues the POS-style / voucher workspace stabilization and documents subsequent issue discovery and fixes around the same file.

---

# 21. PROMPT 30 — Voucher Controls, Scroll, Filters, Smart Pickers

**Goal:** fix broken buttons, scrolling, product filters, and enable smart search for Branch / Vehicle / Supplier / Representative selectors.

**Source:** `doc/Draft/Hussin/برومبت 30 وتقرير تنفيذه`

**Console defect:** `Unexpected end of input` in vouchers.

**Implemented:**
- Full Send / Cancel / Receive / Complete cycle.
- Received state included in pending views for partial receive handling.
- Receive `operation_id` made persistent across retries.
- Smart Pickers for branches, vehicles, suppliers.
- Smarter item search normalization and ranking.
- Product/category filter state repair.
- Company-scoped branch stock reads.
- Scroll/min-height/overscroll improvements.
- Duplicate detail query removed.
- No direct Physical Stock writes introduced.

**Important schema finding:** `stock_vouchers` has no Representative/Sales Rep field; no unsupported selector persistence was invented.

**Historical voucher file SHA after this round:** `2c25855c46177da6208d9585cf2b9a65cb4d1039`

---

# 22. PROMPT 31 — Main/Voucher Functional Integrity and File-Size Concern

**Goal:** investigate whether the large reduction in `vouchers.html` size meant loss of functionality, abbreviated functions, or missing code; also continue source reconciliation before the next UI change.

**Source:** `doc/Draft/Hussin/برومبت 31 وتقرير تنفيذه`

**Governance theme:** file size alone is not proof of loss; compare behavior/contracts/functions directly rather than assuming that fewer bytes mean fewer features.

The work continued to compare the current Gold Master direction against prior versions, backend contracts, and Production rather than restoring old bulk code merely to increase file size.

---

# 23. PROMPT 32 — Gold Master Restoration / Missing Dependencies

**Goal:** make `vouchers.html` a complete Gold Master without regressions and reconcile Prompt 11–31 changes.

**Source:** `doc/Draft/Hussin/برومبت 32 وتقرير تنفيذه`

**Key forensic repairs recorded:**
- Receive idempotency operation identity persisted in localStorage with operation fingerprint.
- Password recovery restored (`recoveryScreen`, `applyRecoveryPassword`, PASSWORD_RECOVERY flow).
- Dexie 3 compatibility restored after it had disappeared from the compressed version.
- Four real Voucher lifecycle types kept separate from Scrap/Adjustment Engine Operations.
- No direct stock writer reintroduced.
- Company scoping retained for main reads and voucher flows.

**Important architectural rule reaffirmed:** do not invent “Edit Draft Voucher” or other contracts merely because a historical UI once suggested them.

---

# 24. PROMPT 33 — Browser/Screenshot-Based Remaining Voucher Issues

**Goal:** use the provided screenshot and current source/Production evidence to diagnose the remaining voucher UI/runtime problems.

**Source:** `doc/Draft/Hussin/برومبت 33 وتقرير تنفيذه`

**Important attachment context:** the prompt explicitly references a screenshot supplied in the conversation to illustrate the UI problem. The screenshot itself is not reproduced here; the source file remains the authoritative attachment reference.

The prompt continued the Gold Master forensic cleanup instead of introducing a parallel interface.

---

# 25. PROMPT 34 — Final Pre-Gold-Master Integration Review

**Goal:** continue the forensic review of the consolidated voucher application and reconcile all previous fixes before finalizing the deployable file.

**Source:** `doc/Draft/Hussin/برومبت 34 وتقرير تنفيذه`

This phase is the bridge between the historically modular Gold Master work and the explicit user requirement that all final UI behavior be consolidated into one publishable `Current/PWA/vouchers.html`.

---

# 26. PROMPT 35 — Collapse UI Dependencies into a Single Deployable Voucher File

**Goal:** stop depending on many auxiliary UI files and maintain only two directions going forward:
1. Production backend;
2. the single deployable application file.

**Source:** `doc/Draft/Hussin/برومبت 35 وتقرير تنفيذه`

**Critical historical discovery:** a Gold Master existed in `Current/PWA/vouchers-gold-master-ui.js` and had been loaded by `register-sw.js`, but the user explicitly required the final publishable UI to live in `Current/PWA/vouchers.html` only.

**Decision:** use the historically validated Gold Master content and consolidate it directly into the deployable `vouchers.html`, rather than leaving core UI behavior in a secondary JavaScript file.

**Architectural direction established:** Production + one publishable voucher file; no new UI fragmentation.

---

# 27. PROMPT 36 — Protect Sensitive Commercial Data in Stock Item Modal

**Goal:** make the item modal warehouse-specific and hide sensitive commercial prices.

**Source:** `doc/Draft/Hussin/برومبت 36 وتقرير تنفيذه`

**Required warehouse-safe fields:**
- Item name
- Code
- Barcode
- Unit
- Category
- Description
- Available stock
- Availability status
- Image

**Explicitly excluded for warehouse users:**
- Sales price
- Cost price

This reflects the separation between warehouse operations and sales/procurement/finance secrets.

---

# 28. PROMPT 37 — Transfer Send Failure: `target stock row missing`

**Goal:** investigate Branch → Branch Transfer Send failure after item selection and quantity confirmation.

**Source:** `doc/Draft/Hussin/برومبت 37 وتقرير تنفيذه`

**Observed error:** `target stock row missing` when sending a transfer.

**Governance implication:** the fix must be made at the actual stock-voucher/stock-engine contract boundary, not by hiding the error in the UI or inserting ad-hoc rows from the browser.

This phase belongs to the central inventory-engine Zero-Debt line of work and must be interpreted together with `post_stock_movement`, target-branch stock-row creation guarantees, idempotency, and Company/Item identity rules.

---

# 29. PROMPT 38 — Voucher Field/Data Binding Audit

**Goal:** re-audit all data fields in `vouchers.html`, especially Smart Picker calls such as Supplier and Representative, and correct field binding without assuming unsupported schema fields.

**Source:** `doc/Draft/Hussin/برومبت 38 وتقرير تنفيذه`

The prompt explicitly returned to forensic field-by-field validation after the Transfer issue and required every selector to be checked against the actual Production schema/contracts.

**Key rule preserved:** never invent a Representative/Sales Rep storage field in `stock_vouchers` if the current schema does not contain one.

---

# 30. PROMPT 39 — Continuation of Full Voucher Forensic Closure

**Goal:** continue the direct-source forensic closure of `vouchers.html` after Prompts 11–38, including validation of all previous fixes, field bindings, transfer behavior, and final production-aligned Gold Master state.

**Source:** `doc/Draft/Hussin/برومبت 39 وتقرير تنفيذه`

Prompt 39 continues the same explicit operating rule: no trust in stale memory, preserve correct changes, directly repair incorrect changes, and keep the final result in the deployable voucher file.

Because this historical source file is very large, the connected GitHub read in this session returned only the initial portion of the file. Therefore this consolidated record does **not** invent any later Prompt-39 result that was not directly visible in the retrieved source payload. The URL itself is preserved as the authoritative continuation source.

---

# 31. Cross-Series Architectural Evolution

## A. Manual Voucher Architecture

Historical contract:
- Six manual-voucher types were defined historically.

Current/Production distinction established by the series:
- **Voucher lifecycle:** Transfer, DirectSale, DirectReturn, SupplierReturn.
- **Engine operations:** Scrap, Adjustment through `post_inventory_adjustment_atomic` / `bulk-stock-adjustment`.

The distinction was deliberately preserved instead of creating fake Voucher lifecycles.

## B. Central Inventory Engine

Target contract repeatedly confirmed:

`Business Operation → Domain RPC → post_stock_movement → stock_branches + inventory_log`

Reservation is separate:

`reserve_stock → allocated_qty`

The UI must never become a Physical Stock writer.

## C. Tenant Isolation

The sequence repeatedly discovered and corrected hard-coded or unscoped company context in Edge Functions and direct front-end data access.

Required pattern:

`Authenticated User → public.users.auth_id → public.users.company_id → current tenant → company-scoped CRUD`

## D. Warehouse Workforce Model

Base role:
- `مخزني`

Dynamic operational role:
- `active_warehouse_role`

Supervisor can change the operational task without changing the employee’s base job identity.

## E. Production vs Git vs Hosting

The series repeatedly established three separate states:

1. Git Source
2. Production database / Edge Functions
3. Browser / hosting runtime

A Git PASS is not a Browser PASS. A Production RPC PASS is not a hosting freshness PASS.

---

# 32. Major Forensic Corrections in the Sequence

1. Prompt 15’s apparent Gold Master completeness was disproved by Prompt 16’s direct inspection.
2. Missing `chooseEngineType()` and broken account handler were repaired surgically in Prompt 17.
3. False “Session Expired” gate was identified as a UI interpretation error of `NO_SESSION` in Prompt 18.
4. Warehouse supervisor JavaScript syntax corruption was repaired in Prompt 20.
5. Warehouse supervisor company-context key mismatch was repaired in Prompt 21.
6. Warehouse team reassignment was secured in the Production RPC and UI through Prompts 22–24.
7. Empty team table was traced to RLS/data-access scope, then solved with `get_warehouse_team()` in Prompt 25.
8. Voucher login 400 was proven to be Auth credential failure, not a voucher-role problem; recovery flow was introduced in Prompt 26.
9. Main application Tenant Isolation defects were proven and repaired in Prompt 27.
10. Stale Git `complete-loading` direct stock writes were found and removed in Prompt 28.
11. Voucher item-selection UX was transformed into POS-style workspace in Prompt 29.
12. Voucher button/scroll/filter/Smart Picker issues were repaired in Prompt 30.
13. Missing Gold Master dependencies (idempotency persistence, password recovery, Dexie compatibility) were restored in Prompt 32.
14. Gold Master auxiliary UI fragmentation was consolidated toward the single-file deployment rule in Prompt 35.
15. Sensitive Sales/Cost prices were removed from the warehouse item modal in Prompt 36.
16. Transfer target-stock contract failure became the focus in Prompt 37.
17. Field-level data-binding audit continued in Prompt 38.
18. Prompt 39 continued the final forensic closure sequence.

---

# 33. Historical Git / Production Anchors Explicitly Captured

- Manual voucher UI baseline memory: `Current/CTO/20260819_INVENTORY_MANUAL_VOUCHERS_FORENSIC_STATUS.md`
- Manual voucher execution commit: `8607614cd647674ede009182c439f229d9d038b7`
- Prompt 13 DirectReturn fix: `6c8e83697f8182790d79a019cb3483494c0b940a`
- Prompt 13 final voucher blob: `a8d6726c037ed45157ec5cfadce63cbf791babb6`
- Prompt 15 historical voucher blob: `9f11a3e9585945a3cda9aa25cedc667c784c4b55`
- Prompt 16/17 repair line: `968f8ec6123a8b55256073e16b61f40c408826ab`
- Supervisor company-context fix: `f0b668bdf12615bc8965dd8f1090a4079b8da814`
- Supervisor team scope: `36db0401e9ab4e14932272687440689de52477fa`
- Supervisor re-execution: `8966d8b1ccc2388ee9a6a25688fcadd5b62d5d98`
- Supervisor table UX: `83f6b7f36ff7a8445bc76100b66cf60395838639`
- Team-read RPC/source fix: `5c6c0612f6cc7473c38853c26d6e4f7bb6d1b249`
- Inventory `complete-loading` current-source alignment: `bd66bab8a4ad55f7df32f24c75a82133cf7b1688`
- POS-style voucher workspace: `4cfcee850e088c2ef366411dd9c255bd755771a8`
- Voucher source SHA recorded after Prompt 30: `2c25855c46177da6208d9585cf2b9a65cb4d1039`
- Voucher recovery/Auth repair: `a7aaa2cc1f326709a0623dfd2246f22c4af3c8f1`

---

# 34. Historical CTO / Evidence Records Mentioned by the Series

- `Current/CTO/20260819_INVENTORY_MANUAL_VOUCHERS_FORENSIC_STATUS.md`
- `Current/CTO/20260820_WAREHOUSE_SUPERVISOR_COMPANY_CONTEXT_FORENSIC_FIX.md`
- `Current/CTO/20260820_WAREHOUSE_SUPERVISOR_TEAM_SCOPE_FORENSIC_FIX.md`
- `Current/CTO/20260820_WAREHOUSE_SUPERVISOR_TEAM_READ_SCOPE_FORENSIC_FIX.md`
- Inventory evidence and canonical migration records under `Inventory/` and `supabase/migrations/`

---

# 35. Historical Sources / Reference Files Used by the Sequence

Core voucher sources:
- `Current/PWA/vouchers.html`
- `Original/PWA/warehouse/vouchers.html`
- `Current/PWA/main.html`
- `Current/PWA/picker.html`
- `Current/PWA/core.js`
- `Current/PWA/register-sw.js`
- `Current/PWA/sw.js`
- `Current/PWA/warehouse.supervisor`
- `Original/PWA/warehouse/supervisor.html`
- `Current/PWA/pos.html`

Inventory/contract references:
- historical manual-voucher architecture in `rawaie-erp-review/Architecture/الأذونات المخزنية اليدوية.md`
- Production PostgreSQL functions / RPC definitions
- Edge Functions under `Current/Edge_Functions/`
- `supabase/migrations/`

---

# 36. Attachments / Screenshots / Runtime Evidence

Several prompts explicitly refer to screenshots attached to the corresponding conversation message, particularly around Prompt 25 and Prompt 33. Those screenshots were used historically as forensic symptoms, but are not reproduced in this Markdown anchor.

Where an attachment is essential to interpreting a specific issue, this record deliberately points back to the original Prompt file instead of inventing visual details that were not recoverable from the Git file content itself.

---

# 37. Final Historical State to Carry Forward

By the end of this sequence, the project had established the following durable rules:

- `vouchers.html` is intended to be the single deployable voucher UI file.
- The UI must not mutate Physical Stock directly.
- Manual Voucher lifecycle is distinct from Adjustment Engine operations.
- Warehouse operational role is dynamic and separate from the base warehouse-worker role.
- Warehouse Supervisor team visibility and task assignment are Company + Branch scoped and backend-enforced.
- CRUD from `main.html` must derive tenant context from the authenticated user, never from hard-coded company IDs or unscoped lookups.
- `post_stock_movement` is the central Physical Stock movement engine.
- `reserve_stock` / `release_stock_reservation` are reservation engines, not movement engines.
- Git state, Production state, and hosting/browser state must never be conflated.
- A historical report saying CLOSED is not evidence that the current Production state is CLOSED.

---

# 38. Current-Continuation Warning

This file is a **historical continuity anchor**, not a substitute for current forensic verification.

Before any future CTO continues work, re-check:

1. Current `main` branch files.
2. Current deployed Edge Function versions.
3. Current PostgreSQL RPC definitions and grants.
4. Current stock movement writers / triggers.
5. Current `vouchers.html` SHA.
6. Current Production data and Company isolation.
7. Current browser/runtime deployment state.
8. Current unresolved Inventory Zero-Debt items, especially RECEIVE PURCHASE idempotency and any newer Writer/Consumer drift.

No percentage, closure score, or PASS should be reused without a fresh Production match.

---

# 39. Original Prompt Source Index

11 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2011%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
12 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2012%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
13 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2013%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
14 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2014%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
15 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2015%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
16 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2016%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
17 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2017%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
18 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2018%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
19 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2019%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
20 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2020%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
21 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2021%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
22 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2022%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
23 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2023%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
24 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2024%20%D9%85%D8%B9%20%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
25 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2025%20%D9%85%D8%B9%20%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
26 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2026%20%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
27 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2027%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
28 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2028%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
29 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2029%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
Appendix 29 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D9%85%D9%84%D8%AD%D9%82%20%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2029%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
30 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2030%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
31 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2031%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
32 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2032%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
33 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2033%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
34 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2034%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
35 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2035%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
36 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2036%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
37 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2037%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
38 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2038%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`
39 — `https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Hussin/%D8%A8%D8%B1%D9%88%D9%85%D8%A8%D8%AA%2039%20%D9%88%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%D9%87`

---

## END OF HISTORICAL CONTINUITY RECORD
