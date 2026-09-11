# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-11 — MASTER CTO EXECUTION OS / Main1 Start

### GOVERNING TARGET — NON-NEGOTIABLE
الهدف هو استكمال المشروع وظيفيًا وتشغيليًا وفق Gold/Diamond، وليس مجرد إكمال UI. الدراسة تسبق التعديل، وCurrent Verified Reality تتفوق على Production ثم Database Contracts ثم Deployments ثم Git/Source، بينما التقارير التاريخية أدلة لا تمثل الحقيقة الحالية وحدها.

الحوكمة التنفيذية:

UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH CONTROL FLOW → IDENTIFY ACTUAL GAP → SURGICAL FIX → TEST → PRODUCTION VERIFY → DOCUMENT → UPDATE STATE.

### SOURCE-OF-TRUTH GOVERNANCE
- Current verified reality outranks historical reports.
- Production Database/Runtime is the execution reference.
- Historical reports are evidence, not current truth.
- `CURRENT_STATE.md` is a continuity checkpoint and must be reconciled against current Git/Production.
- Unknown != bug; Unknown != remove.
- One Closure Unit at a time.
- Parent editable source = `Current/PWA/main2/main1.md ... main11.md`.
- `Original/PWA/main/*` = historical reference only and must never be modified.
- `Current/PWA/New-main` = generated assembly target only.
- Physical Stock contract = `post_stock_movement -> stock_branches + inventory_log`.
- `reserve_stock` / `release_stock_reservation` = Reservation-only.
- Current governing execution OS = `doc/Draft/Reprots/MASTER CTO EXECUTION OS — RAWAEA ERP — Forensic Recovery, Full Functional Completion & Gold-Diamond Closure.md`.

## CURRENT GIT TRUTH
- Freshly verified repository HEAD at execution start: `9772a0c9c882b0c3c25e2d81763ec8229740d5c4`.
- Main1 current SHA: `4d1b42250cfe2b3a8ec7d02b7b482eca8e27bade`.
- Main1 original SHA: `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.
- Main1 execution log commit: `ec65145456579fe60b1315ac116d82fc7f3a37a1`.
- CURRENT_STATE reconciliation commit: this commit.

## CURRENT MAIN1–MAIN11 SOURCE INVENTORY
Current editable files verified present in `Current/PWA/main2/`:
- main1.md = `4d1b42250cfe2b3a8ec7d02b7b482eca8e27bade`
- main2.md = `baee3cc02ae5701e6fbcbad12e57e2930afc4ae4`
- main3.md = `479060e3d4bea5e2203c87f8221bdbc0e2f7d456`
- main4.md = `e89d29e4164c68784c109292f27d4d77df240557`
- main5.md = `c4518d05ada50830e819563a55169843679d3e94`
- main6.md = `3b20758459c28ab0b6c055f9a0ad3992f1bd07e5`
- main7.md = `a65969f6bdc919d4a8d62a6704a7c556b7d35e91`
- main8.md = `2131fbf3096d926b2486acb2ab58a4266ddd1bbc`
- main9.md = `b9f10ae4e727cb9495aaecbe2d752dabf13ec776`
- main10.md = `169025a6836c7fdc7281ea86523b975a84d889f1`
- main11.md = `2adfc787c3e5f0ca56abfcc85232e7a971773c3b`

Historical reference files verified present in `Original/PWA/main/`:
- main1.md = `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`
- main2.md = `45d5e760a4b53e3be574346e3d9d192dbad309af`
- main3.md = `1bfedd3b16abb804d83e2b7d5671f1b31f320a14`
- main4.md = `05bd5f41d011fabcc37ded00bdfa9e87555dc872`
- main5.md = `caffc0187b54444e96491dc6f00a238b2e870b32`
- main6.md = `87287d8da56a5411f9f31243b38b9c06dbf91d2b`
- main7.md = `6f7aef60ac137cd7f6b74281a17835dbd29595be`
- main8.md = `20f77481133d3e55ced949de16f88dadb0a69980`
- main9.md = `288b642d050f8b5ddeb6d43a7fd2a992fb05bb03`
- main10.md = `d57cef3bd7e42f7ba7ddc90bde81bdbabd5579a1`
- main11.md = `cad8bafa94da839ffb3a61f1a4581f52b98289f4`

`Original/PWA/main/*` remains immutable historical reference; no modification was made.

## FRESH PRODUCTION SNAPSHOT — 2026-09-11
Verified directly at UTC `2026-09-11 04:27:11.929726+00`:
- companies = 1
- branches = 2
- users = 24
- items = 17
- customers = 3
- orders = 0
- purchase_orders = 0
- stock_branches = 20
- inventory_log = 3
- audit_log = 1869

## MASTER CTO EXECUTION — CURRENT MAIN1 CYCLE
The linked MASTER CTO EXECUTION OS was read from start to EOF before execution of Main1.

Main1 current source was read from line 1 through EOF.
Original Main1 was read through EOF from the immutable historical blob.

### Confirmed Main1 Current hardening versus Original
- Authenticated user is resolved against `public.users` using `auth_id`.
- Company context is loaded from the authenticated user's database record.
- Inactive users are rejected.
- `RW_STATE.app.company.id` is populated from the database company id.
- App settings are company-scoped.
- Items/customers/branches/suppliers are company-scoped.
- JWT permission arrays were matched against `public.users.permissions` for the active users queried; no observed permission drift was found.

### Proven Main1 defects
#### MAIN1-A — Finance action authorization gap
Finance navigation action objects for treasury/accounts/journal/receipts/payments/transfers/reports have neither `perm` nor `view`. `buildSidebar().isAllowed()` therefore returns true for them regardless of user capability.
Production role contract proves:
- `محاسب` uses `finance`.
- `مدير مالي` uses `finance_manager`.
- `مدير النظام` retains `*` and `isOwner=true`.

Required owner-source surgery is recorded in:
`doc/Draft/Reprots/CTO_EXECUTION_LOG_20260911_MAIN1.md`.

The required change is an alternative-permission array `['finance','finance_manager']` on those seven Finance action entries plus array support in `isAllowed(item)`.
`settlement` remains controlled by its independent `settlement` view permission.

#### MAIN1-B — Cross-file State contract mismatch
Main1 establishes canonical state at `RW_STATE.app.company.id`.
Current Main8 `_companyId()` expects `RW_STATE.app.companyId` or `RW_STATE.user.companyId`.
This is a proven cross-file mismatch. Canonical state must remain `RW_STATE.app.company.id`; Main8 must be repaired to consume that contract rather than adding a second persistent source in Main1.

### Main1 closure status
- MASTER read: CLOSED.
- Current Main1 EOF read: CLOSED.
- Original Main1 EOF read: CLOSED.
- Fresh Git/Production synchronization gate: CLOSED for this cycle.
- Current-vs-Original Main1 pair analysis: CLOSED.
- Production auth/permission source comparison: CLOSED.
- MAIN1-A: PROVEN / owner-source surgery required.
- MAIN1-B: PROVEN / Main8 surgery required.
- Main1 functional closure: NOT CLOSED until owner-source surgery is applied and re-verified.

## EXECUTION LOG
Canonical execution evidence:
`doc/Draft/Reprots/CTO_EXECUTION_LOG_20260911_MAIN1.md`

Execution log commit: `ec65145456579fe60b1315ac116d82fc7f3a37a1`.

## VALIDATION STATUS
- Fresh Production snapshot: VERIFIED 2026-09-11 04:27:11.929726+00 UTC.
- Main1 Current full read: VERIFIED to EOF.
- Main1 Original full read: VERIFIED to EOF.
- Main1 pair review: VERIFIED.
- Original folder modification: none.
- Production business-data mutation in this Main1 forensic cycle: none.
- Main1 owner-source changes: not applied because governing OS requires surgical instructions rather than direct mutation of Main1–Main11 source.
- Main8 source changes: not applied in Main1 closure.
- Assembly: NOT VERIFIED.
- Browser/PWA runtime: NOT VERIFIED.
- Parent Gold/Diamond: NOT CLOSED.

## LAST VERIFIED EVENT
- EVENT: `MASTER-CTO-MAIN1-FORENSIC-20260911`
- Fresh Production verification timestamp: `2026-09-11 04:27:11.929726+00 UTC`.
- Fresh Git HEAD at start: `9772a0c9c882b0c3c25e2d81763ec8229740d5c4`.
- Main1 current SHA: `4d1b42250cfe2b3a8ec7d02b7b482eca8e27bade`.
- Main1 original SHA: `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.
- Execution log commit: `ec65145456579fe60b1315ac116d82fc7f3a37a1`.
- Result: Main1 forensic understanding and pair reconciliation completed; two defects were proven without assumptions; exact source surgery was documented; no Original modification and no unsafe Production data mutation occurred.
- Next required closure action: apply MAIN1-A owner-source surgery, then repair the Main8 consumer mismatch, re-read/verify affected files and continue the MASTER OS closure sequence.

## SELF-AUDIT
### Confirmed Facts
- Current Git and Production were freshly inspected before judgment.
- Main1 Current and Original were read to EOF.
- JWT permission data matches public user permission data for the active users checked.
- Main8 currently references a non-canonical company state field.

### Unknowns / Unverified
- Owner-source surgery is not yet applied.
- Production UI smoke for the current assembled parent is not yet verified.
- Full Main2–Main11 forensic pair closure is not yet verified in this execution cycle.
- Final assembly and runtime are not verified.

### Final Closure Status
`MAIN1 FORENSIC REVIEW = COMPLETE`
`MAIN1 FUNCTIONAL CLOSURE = OPEN — SURGERY PENDING`
`GLOBAL GOLD/DIAMOND = OPEN`
