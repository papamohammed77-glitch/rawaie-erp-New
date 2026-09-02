# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Current truth is established from direct Git, Production, deployment/runtime evidence, and verified artifacts.
- Historical reports are evidence, not current truth.
- `Current/PWA/New-main` is the authorized product target for `erp-frontend/companies/company-1/main.html`.
- `Current/PWA/main.html` is a separate protected artifact; do not replace it by filename similarity.
- Historical reports must not be deleted or overwritten.
- No 100% closure without fresh Production/runtime proof.
- In the present P156/P157 continuity round, the owner explicitly authorized **forensic reporting + surgical instructions only**; the assistant must not modify the final `Current/PWA/New-main` artifact.

## HISTORICAL CONTINUITY
- P133–P151: authentication, deployment, Service Worker, compatibility-route, and auto-update reconstruction/closures as previously recorded.
- P151 final Git state included the permanent update coordinator; live Cloudflare propagation remained unverified.
- P152: Auth/deployment reconciliation; successful Production auth existed despite browser-side 401; Supabase key rotation was not justified.
- P153: Current-state reconciliation; Report13 Production compatibility migration `20260902023122 / compatibility_company_main_branch_projection_20260902` verified; `main.html` already contained Idempotency-Key + operation_id; Inventory closure remained open.
- P154: Original main1 vs `Current/PWA/main.html` comparison; separate artifact scope.
- P155 / `تقرير16.md`: first direct forensic comparison of `Original/PWA/main/main1.md` vs `Current/PWA/New-main` and initial surgical findings.
- P156 / `تقرير17.md`: corrected forensic pass focused on **actual missing/reduced functions and features**, with full current defective function blocks and surgical replacement instructions; no target-code modification.

## CURRENT SOURCE IDENTITIES
- `Original/PWA/main/main1.md` SHA `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.
- `Current/PWA/main.html` SHA `27b777528665dcc985809648f006452c861ae36e`.
- `Current/PWA/New-main` SHA `27b777528665dcc985809648f006452c861ae36e`.
- Direct verification on 2026-09-02 established that `Current/PWA/main.html` and `Current/PWA/New-main` currently resolve to the same Git blob SHA.
- Latest verified commit touching `Current/PWA/New-main` at the time of P156 was `071a38842f918b9cdb024e03baf8a76cdbe9c837` (`Update New-main`, 2026-09-02 03:22:22Z). Its diff was limited to an HTML timestamp comment and the Supabase publishable key; it is not the source of the historical feature-loss findings.

## INVENTORY CONTINUITY
Contract remains:
```text
PHYSICAL STOCK MOVEMENT
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```
`reserve_stock` is reservation-only.
Direct Production anomalies remain unclosed: 143 `stock_branches` branch/item-company mismatches, 86 `inventory_log` item/company mismatches, and 6 `order_details` item/company mismatches. They were not rewritten without historical/source/business-impact proof.

## P156 — CORRECTED MISSING-FEATURE FORENSIC ROUND — 2026-09-02
### Scope
- Original: `Original/PWA/main/main1.md`
- Target: `Current/PWA/New-main`
- Supporting sources: `MASTER - RAWAEA ERP.md`, `CURRENT_STATE.md`, recent `doc/Draft/Reprots`, Git history, direct Production evidence.
- Historical reports retained.
- Target code was **not modified** in this round.
- Production was **not modified** by this comparison round.

### Current verdict
`Current/PWA/New-main` remains the architectural baseline. `Original/PWA/main/main1.md` remains a historical contract/UX reference. Full Original replacement or merge remains rejected.

### PROVEN MISSING / REDUCED FEATURES
1. **Notification interaction contract — partial regression**
   - Current module exists.
   - `markAllRead`, `markRead`, and `_clickNotif` exist in the Current compatibility surface.
   - The active `showPanel()` does not wire `قراءة الكل` and notification-row click-through to those existing capabilities.
   - Surgical package: `SP-NEW-01` in `doc/Draft/Reprots/تقرير17.md`.
2. **Audit read-model richness — partial regression**
   - Current Owner-only Audit renderer exists.
   - Original functionality included action filter, date-from/date-to filters, exact count, pagination, numbered pages, detail action, and old/new JSON inspection.
   - Current active renderer does not expose that complete read-model interaction surface.
   - Surgical package: `SP-NEW-02` in `doc/Draft/Reprots/تقرير17.md`.
3. **Password visibility UI — function preserved, UI hook missing**
   - Current already contains `window.togglePasswordVisibility` helper.
   - The login HTML no longer contains the toggle button invoking it.
   - Surgical package: `SP-NEW-03` in `doc/Draft/Reprots/تقرير17.md`.
4. **Login footer — UI element missing**
   - Original login contains footer.
   - Current login form does not.
   - Surgical package: `SP-NEW-04` in `doc/Draft/Reprots/تقرير17.md`.
5. **Numbered pagination UX — reduction only**
   - Pagination exists in Current.
   - Current is simpler than Original.
   - Not a Core defect and no `RW_Table` rewrite is authorized by this comparison.

### VERIFIED NOT-MISSING / DO NOT RESTORE FROM ORIGINAL
- Authentication and authoritative user/company context.
- Owner semantics and `isOwner + permissions[*] + owner_profile + license state` contract.
- `RW_Permissions_check` / `RW_Permissions_applyUI`.
- `RW_Workflow` responsibility and current DB alignment.
- POS / TeleSales / Orders / Runsheets / Purchasing / Receiving.
- Warehouse operations: Picking / Loading / Delivery / Returns / Unloading.
- Stock vouchers / inventory counts / settlement.
- Finance module and comprehensive reporting modules.
- Dashboard and Items surfaces; Current is in several areas richer than Original.
- Inventory physical-stock ownership through the Core contract.
- Absence of historical helper names such as `showFinanceTab` is not proof of capability loss; responsibility has moved into current modules.

### EXPLICITLY NOT PROVEN / NO PATCH AUTHORIZED
- Forgot-password implementation loss.
- Remember-me persistence loss.
- Finance capability loss.
- Warehouse capability loss.
- Inventory capability loss from this UI pair.
- Workflow capability loss.
- Permission capability loss.
- Owner capability loss.
- Dashboard Net Profit definition/correction.

### OWNER SURGICAL INSTRUCTIONS
- Apply `SP-NEW-01` through `SP-NEW-04` manually, one at a time, from `doc/Draft/Reprots/تقرير17.md`.
- Each instruction gives the **full current defective function/block** to remove and the **full replacement/addition**.
- Do not create duplicate helper/module definitions where the report explicitly identifies an existing Current implementation.
- Verify each package before applying the next.

### P156 CORRECTIONS TO PREVIOUS ERRORS
- A prior comparison used `Current/PWA/main.html` instead of `Current/PWA/New-main`.
- A prior claim that Current lacked `Idempotency-Key` was false; direct source shows `Idempotency-Key` and `operation_id` in the receiving flow.
- A previous receiving-idempotency experiment established that mutable state alone is not a stable client operation identity; the tests were transactional and did not leave permanent data.
- Earlier Production/DB repairs were not used as proof of UI parity in this report.

### P156 SELF-AUDIT
```text
MASTER RECOVERY                 = VERIFIED
CURRENT_STATE REVIEW            = VERIFIED
RECENT REPORT CHAIN             = VERIFIED
ORIGINAL SOURCE                 = OPENED DIRECTLY
CURRENT NEW-MAIN                = OPENED DIRECTLY
LATEST NEW-MAIN GIT EVENT       = VERIFIED
PRODUCTION EVIDENCE             = REVIEWED
MISSING FEATURES                = SOURCE-TRACED
FULL ORIGINAL MERGE             = REJECTED
TARGET CODE MODIFIED            = NO
PRODUCTION MODIFIED             = NO
HISTORICAL REPORTS DELETED      = NO
NOTIFICATION GAP                = PROVEN PARTIAL REGRESSION
AUDIT GAP                       = PROVEN REDUCTION
PASSWORD UI GAP                 = PROVEN
LOGIN FOOTER GAP                = PROVEN
PAGINATION                      = PRESERVED / UX REDUCED
DASHBOARD P&L                   = UNPROVEN / NO PATCH
INVENTORY CORE 100%             = NO
CLOUDFLARE LIVE ARTIFACT        = UNVERIFIED
```

## REPORTS
- P155: `doc/Draft/Reprots/تقرير16.md`
- P156: `doc/Draft/Reprots/تقرير17.md`
- P156 report commit: `5b3cba5baaa90b4d6f8c631f941ce7ab2f4dcedc`

## REQUIRED NEXT STATE
1. Owner performs the four surgical packages manually from `تقرير17.md`.
2. Verify each package independently before the next.
3. Do not replace New-main with Original.
4. Do not restore Legacy wildcard/global tenant semantics.
5. Continue Financial/P&L source tracing separately.
6. Continue Global Inventory Core Integrity Sweep independently, one Writer Closure Unit at a time.
7. Repair Production data only after source/history/business-impact tracing.
8. Keep Cloudflare live-runtime closure open until direct served-artifact proof exists.

## FINAL STATE
```text
P156_FORENSIC_COMPARISON        = COMPLETE
SURGICAL_FINDINGS               = COMPLETE
SURGICAL_REPORT                 = STORED
TARGET_NEW_MAIN_MODIFIED        = NO
OWNER_MANUAL_PATCHES            = READY
ORIGINAL_AS_BASE                = REJECTED
PERMISSION_PARITY               = PRESERVED
WORKFLOW_PARITY                 = PRESERVED
NOTIFICATION                    = PARTIAL GAP / SP-NEW-01
AUDIT                           = PARTIAL GAP / SP-NEW-02
PASSWORD UX                     = GAP / SP-NEW-03
LOGIN FOOTER                    = GAP / SP-NEW-04
PAGINATION                      = UX REDUCTION ONLY
INVENTORY CORE                  = OPEN
CLOUDFLARE RUNTIME              = OPEN
CLOSED_100_PERCENT              = NO
```