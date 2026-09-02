# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Current truth is established from direct Git, Production, deployment/runtime evidence, and verified artifacts.
- Historical reports are evidence, not current truth.
- `Current/PWA/New-main` is the authorized product target for `erp-frontend/companies/company-1/main.html`.
- `Current/PWA/main.html` is a separate protected artifact; do not replace it by filename similarity.
- Historical reports must not be deleted or overwritten.
- No 100% closure without fresh Production/runtime proof.

## HISTORICAL CONTINUITY
- P133–P151: authentication, deployment, Service Worker, compatibility-route, and auto-update reconstruction/closures as previously recorded.
- P151 final Git state included the permanent update coordinator; live Cloudflare propagation remained unverified.
- P152: Auth/deployment reconciliation; successful Production auth existed despite browser-side 401; Supabase key rotation was not justified.
- P153: Current-state reconciliation; Report13 Production compatibility migration `20260902023122 / compatibility_company_main_branch_projection_20260902` verified; `main.html` already contained Idempotency-Key + operation_id; Inventory closure remained open.
- P154: Original main1 vs `Current/PWA/main.html` comparison; two low-risk UX patches were issued for that separate artifact.
- P155: First direct forensic comparison of `Original/PWA/main/main1.md` vs `Current/PWA/New-main`. The comparison deliberately did not modify New-main or Production data.

## CURRENT SOURCE IDENTITIES
- `Original/PWA/main/main1.md` SHA `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.
- `Current/PWA/main.html` SHA `27b777528665dcc985809648f006452c861ae36e`.
- `Current/PWA/New-main` SHA `27b777528665dcc985809648f006452c861ae36e`.
- Direct verification on 2026-09-02 established that `Current/PWA/main.html` and `Current/PWA/New-main` currently resolve to the same Git blob SHA. This supersedes the older state entry that listed `New-main` at SHA `5bf6907747d807dfa9f10979f5a63685c8bae64e`.

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

## P155 — ORIGINAL main1 vs CURRENT/PWA/New-main — 2026-09-02
### Scope
- Original: `Original/PWA/main/main1.md`
- Target: `Current/PWA/New-main`
- No target-code modification in this comparison.
- No Production data modification for this comparison.
- Historical reports retained.

### Current verdict
`Current/PWA/New-main` is a modern operational reconstruction and is the correct architectural baseline. `Original/PWA/main1` is retained as a historical UX/contract reference. Full replacement or full merge is rejected.

### Preserved / improved responsibilities directly verified
- Authentication/user/company context: Current is more authoritative and company-scoped.
- Owner semantics: Current preserves strict `isOwner + permissions[*] + owner_profile` behavior; do not restore the old broad metadata fallback.
- Tenant data loading: Current company-scopes Items, Customers, Branches, Suppliers and other relevant reads.
- UI permission application: `RW_Permissions_check` and `RW_Permissions_applyUI` are present in Current; no missing utility is proven.
- Workflow: `RW_Workflow` is present and aligned to the current Production `workflow_log` schema; no gap proven.
- Warehouse/core ownership: Current keeps physical stock mutation outside the UI and delegates operational capabilities to Edge/RPC paths.
- Broader functional surface: Dashboard, Items/Stock Matrix, Customers, Suppliers, Branches, Users/Permissions, POS, TeleSales, Orders, Runsheets, Online Store, Purchasing/Receiving, Warehouse, Vouchers, Picking, Loading, Delivery, Returns, Unloading, Settlement, Finance, Reports, HR, CRM, Owner/License, Audit, Notifications.

### Proven Current-vs-Original losses / reductions
1. Notification panel interaction contract is only partially preserved. Current has the module, badge, send, and read methods, but its active `showPanel()` does not reproduce Original's `قراءة الكل` action and click-through to linked records. A later compatibility closure added `_clickNotif` but did not wire the active panel to it.
2. Audit read-model richness is reduced. Current is Owner-only and searchable but lacks Original's action filter, date filters, exact-count pagination, numbered pages, detail action, and old/new JSON detail view.
3. Password visibility UX is absent from the Current login field.
4. Login footer is absent from the Current login form.
5. Generic table pagination is preserved but simplified: Current uses previous/next controls, while Original also exposed numbered pages and visible range. This is UX reduction only, not a core functional gap.

### Surgical work packages issued to owner — no automatic application
- `SP-NEW-01`: replace only the current `RW_Notification.showPanel()` with the self-contained notification panel function recorded in `doc/Draft/Reprots/تقرير16.md`, restoring `قراءة الكل`, row click, read marking, and supported navigation.
- `SP-NEW-02`: replace the current `RW_Audit_renderTab()` and add its direct helper functions/state exactly as recorded in `doc/Draft/Reprots/تقرير16.md`, restoring filters, pagination, detail view, and old/new data inspection while retaining Owner-only access.
- `SP-NEW-03`: add password visibility to the exact `rw-password` group and its local CSS as recorded in `تقرير16.md`.
- `SP-NEW-04`: add the login footer to the exact current login form and local CSS as recorded in `تقرير16.md`.

### Explicitly NOT authorized from Original
- Legacy `meta.permissions || ['*']` wildcard fallback.
- Global `app_settings ... limit(1)` reads when company-scoped identity is available.
- Legacy global data loaders.
- Original Workflow log fields that do not exist in the current Production schema.
- Full Original CSS replacement.
- Full Original file replacement.
- Dashboard `Net Profit` formula correction; the authoritative P&L source remains unproven.

### P155 continuity corrections
- The previous comparison report targeted `Current/PWA/main.html`, not the requested `Current/PWA/New-main`; therefore P154 must not be treated as this pair's final comparison.
- An earlier claim that Current lacked `Idempotency-Key` was false; direct current source shows both `Idempotency-Key` and `operation_id` in the receiving flow.
- The older New-main SHA in `CURRENT_STATE.md` was stale; direct Git now shows SHA `27b777...`, equal to Current/main.html.
- Previous receiving-idempotency experiments were transactional and did not leave permanent test data.

### P155 self-audit
```text
MASTER_REVIEW                         = VERIFIED
MEMORY_RECOVERY                       = VERIFIED
CURRENT_STATE_REVIEW                  = VERIFIED
RECENT_GIT_HISTORY                    = VERIFIED
ORIGINAL main1                        = OPENED DIRECTLY
CURRENT New-main                      = OPENED DIRECTLY
PRODUCTION RELEVANT CONTRACTS         = CHECKED
WORKFLOW PRODUCTION STATE             = CHECKED
NOTIFICATION PRODUCTION STATE         = CHECKED
CURRENT New-main SHA                  = VERIFIED 27b777...
CURRENT main.html SHA                 = VERIFIED 27b777...
TARGET CODE MODIFIED                  = NO
PRODUCTION DATA MODIFIED (COMPARISON) = NO
HISTORICAL REPORTS DELETED            = NO
FULL MERGE                            = REJECTED
PERMISSION GAP                        = NONE PROVEN
WORKFLOW GAP                          = NONE PROVEN
NOTIFICATION GAP                      = PROVEN PARTIAL REGRESSION
AUDIT GAP                             = PROVEN REDUCTION
PASSWORD UX GAP                       = PROVEN
LOGIN FOOTER GAP                      = PROVEN
PAGINATION                            = PRESERVED / UX REDUCED
DASHBOARD P&L                         = UNPROVEN / NO PATCH
INVENTORY CORE 100%                   = NO
CLOUDFLARE LIVE ARTIFACT              = UNVERIFIED
```

## P155 REPORT
`doc/Draft/Reprots/تقرير16.md`
commit `6fa2913d7676833952a7ff07d7412c51893e9421`

## REQUIRED NEXT STATE
1. Owner applies `SP-NEW-01` through `SP-NEW-04` manually, one package at a time, and verifies after each package.
2. Do not replace New-main with Original.
3. Do not reintroduce Legacy wildcard or global tenant reads.
4. Continue Financial/P&L source tracing before any dashboard profit correction.
5. Continue Global Inventory Core Integrity Sweep independently, one Writer Closure Unit at a time.
6. Perform Production data repair only after source/history/business-impact tracing.
7. Keep Cloudflare live-runtime closure open until direct served-artifact proof exists.

## FINAL STATE
```text
P155_COMPARISON                    = COMPLETE
TARGET_NEW_MAIN_MANUAL_PATCH      = NOT APPLIED
ORIGINAL_AS_BASE                   = REJECTED
SURGICAL_NOTIFICATION_PATCH       = READY
SURGICAL_AUDIT_PATCH              = READY
SURGICAL_PASSWORD_PATCH           = READY
SURGICAL_LOGIN_FOOTER_PATCH       = READY
WORKFLOW_PARITY                    = PRESERVED
PERMISSION_PARITY                 = PRESERVED
INVENTORY_CORE                    = OPEN
CLOUDFLARE_RUNTIME                = OPEN
CLOSED_100_PERCENT                = NO
```