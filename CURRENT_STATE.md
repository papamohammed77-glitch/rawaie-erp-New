# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-11 — MASTER CTO EXECUTION OS / Main1 Continuation

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
- Current governing execution OS = `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`.

## CURRENT GIT TRUTH
- Freshly verified repository HEAD for this continuation: `a582fff10e5c9e24e187c7f77d16db608269f1d8`.
- Main1 current SHA: `4d1b42250cfe2b3a8ec7d02b7b482eca8e27bade`.
- Main1 original SHA: `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.
- Main1 execution log updated in commit: `2a02ba68a87a179c245b5382f91a5b702a3fa447`.
- Main1 Owner Change Set created in commit: `c98b31aad4275b1019fbbed1b5434d3fe634fa9f`.

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

Historical reference files verified present in `Original/PWA/main/` and remain immutable.

## FRESH PRODUCTION SNAPSHOT — 2026-09-11 CONTINUATION
Verified directly at UTC `2026-09-11 06:06:46.569077+00`:
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

## MASTER CTO EXECUTION — MAIN1 CONTINUATION
The current MASTER CTO Governance & Continuous Execution OS was read from start through its explicit END marker before Main1 continuation work.

Main1 Current was read from line 1 through EOF (line 1100).
Main1 Original was read through EOF.

### Main1 forensic result
Main1 is the Shell/Control Plane, not the View implementation layer. `RW_Views` is correctly owned by Main10 and is not duplicated into Main1.

### Proven MAIN1-A — Finance action authorization gap
- Current Main1 Finance submenu is source line 895.
- Seven `showFinanceTab` actions have neither `perm` nor `view`.
- Current `isAllowed(item)` returns true for items with neither property.
- Production permissions prove `finance` for Accountant, `finance_manager` for Finance Manager, and `*` plus `isOwner=true` for Owner.
- Required surgical fix is stored in `doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1.md`.

### Proven MAIN1-B — CRM authorization mismatch
- Current Main1 CRM menu is source line 902.
- Main1 currently checks `RW_Permissions_check('crm')` through its `view` fallback.
- Production has 0 active users with `crm` and 7 with `customers`.
- Main10 maps CRM to `customers`.
- Required Main1 surgery is explicit `perm: 'customers'`.

### Proven MAIN1-C — HR cross-file authorization mismatch
- Current Main1 HR menu is source line 901.
- Production has 1 active HR user carrying `hr`.
- Main10 currently maps `hr` to `users`.
- Required Main1 surgery is explicit `perm: 'hr'`.
- Required Main10 paired surgery is `hr -> hr`; this remains open until Main10 closure to prevent a half-fixed state.

### Verified safe / deliberately unchanged
- `users.auth_id` has UNIQUE constraint, so Main1 `maybeSingle()` is structurally safe.
- JWT role/permissions currently match `public.users.permissions` for all active users with Auth records.
- `notifications` own-user RLS is present; no unproven retrofit made.
- `audit_log` is Owner-protected by RLS; no speculative tenant column added.
- `workflow_rules` is global in the current schema; no invented Company scope was added.
- No duplicate router or second persistent company-state source was introduced.

## OWNER SOURCE CHANGESET
Canonical surgical instructions:
`doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1.md`

The owner source itself remains unchanged in Git because Main1–Main11 are owner-merge domain.

### Main1 closure status
- MASTER read to EOF: CLOSED.
- Main1 Current EOF read: CLOSED.
- Main1 Original EOF read: CLOSED.
- Fresh Production synchronization gate: CLOSED for this continuation.
- Main1 forensic review: CLOSED.
- Main1 source merge: OPEN — owner surgery pending.
- Main1-A Finance: PROVEN / SURGERY READY.
- Main1-B CRM: PROVEN / SURGERY READY.
- Main1-C HR: PROVEN / SURGERY READY + Main10 dependency.
- Assembly: NOT VERIFIED.
- Browser/PWA runtime: NOT VERIFIED.
- Global Gold/Diamond: OPEN.

## EXECUTION EVIDENCE
- Execution log: `doc/Draft/Reprots/CTO_EXECUTION_LOG_20260911_MAIN1.md`.
- Owner Change Set: `doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1.md`.
- MASTER SHA: `b03feec14a417ca9032d714774f2687b4542a373`.
- Fresh Production verification: `2026-09-11 06:06:46.569077+00 UTC`.

## SELF-AUDIT
### Confirmed Facts
- Current Production counts were re-queried directly before Main1 judgment.
- Current Main1 and Original Main1 were read to EOF.
- Auth metadata and database permission records match for active Auth users.
- Main1 Finance, CRM, and HR routing issues are evidenced from source + Production contracts.
- Main10 currently owns `RW_Views`.

### Unknowns / Unverified
- Owner source surgery has not yet been merged.
- Main10 HR dependency has not yet been closed.
- Main2–Main11 full forensic closure is not yet complete.
- Final New-main assembly is not verified.
- Production UI smoke test is not verified.

### FINAL CLOSURE STATUS
`MAIN1 FORENSIC REVIEW = COMPLETE`
`MAIN1 OWNER SOURCE = OPEN — SURGERY PENDING`
`MAIN1 FUNCTIONAL CLOSURE = OPEN — MERGE + CROSS-FILE VERIFICATION PENDING`
`GLOBAL GOLD/DIAMOND = OPEN`
