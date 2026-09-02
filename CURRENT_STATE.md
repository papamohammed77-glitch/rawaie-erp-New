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
- P153: Current-state reconciliation; Report13 Production compatibility migration `20260902023122 / compatibility_company_main_branch_projection_20260902` verified; `main.html` already contained Idempotency-Key + operation_id; Current/Main and New-main were confirmed distinct artifacts; Inventory closure remained open.

## CURRENT SOURCE IDENTITIES
- `Original/PWA/main/main1.md` SHA `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.
- `Current/PWA/main.html` SHA `27b777528665dcc985809648f006452c861ae36e`.
- `Current/PWA/New-main` SHA `5bf6907747d807dfa9f10979f5a63685c8bae64e`.

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

## P154 — ORIGINAL vs CURRENT PWA COMPARISON — 2026-09-02
### Verdict
- `Current/PWA/main.html` is the current operational UI baseline and is functionally much broader than `Original/PWA/main/main1.md`.
- `Original/PWA/main1` is a historical UX/contract reference with stronger login presentation, spacing, password-visibility treatment, and login footer.
- Current is architecturally better aligned with the modern modular/Edge/RPC delegation direction.
- Full Original → Current merge is rejected.
- Surgical parity/enhancement is approved only where the missing responsibility is directly proven.

### Current functional surface verified
Dashboard, Items/Stock Matrix, Customers, Suppliers, Branches, Users/Permissions/Assignments, POS, TeleSales, Orders, Runsheets, Online Store, Purchasing/Receiving, Warehouse workflows, Vouchers, Picking, Loading, Delivery, Returns, Unloading, Settlement, Finance UI, Reports, HR, CRM, Owner/License.

### Original elements worth selective recovery
- Larger login hero/card/logo and more spacious historical presentation.
- Password show/hide UX.
- Login footer.
- Historical permission/workflow/notification contracts remain references only until Current-wide responsibility tracing proves an actual loss.

### Surgical patches issued to owner
#### SP-01 — Password visibility
Open `Current/PWA/main.html`.
Find the exact current password group containing:
```html
<div class="rw-form-group"><label class="rw-form-label" for="rw-password">كلمة المرور</label><input id="rw-password" class="rw-input" type="password" autocomplete="current-password"></div>
```
Replace that group with the password wrapper/button fragment recorded in `doc/Draft/Reprots/تقرير15.md`, and add its `.rw-password-wrap` / `.rw-password-toggle` CSS immediately before `.rw-login-options`.

#### SP-02 — Login footer
Find:
```html
<div id="rw-login-error" class="rw-notice rw-notice-bad hidden"></div></form>
```
Replace with the footer-bearing fragment recorded in `doc/Draft/Reprots/تقرير15.md`, and add the recorded `.rw-login-footer` CSS immediately before `.rw-main-shell`.

These are UX-only changes; they do not modify auth payloads, permissions, stock, accounting, or database contracts.

### Not authorized yet
- SP-03 Dashboard profit metric: current source uses sales minus purchase-order totals; authoritative P&L source not yet proven.
- SP-04 UI permission parity: historical `RW_Permissions_applyUI` exists, but Current-wide responsibility transfer is not fully proven.
- SP-05 Workflow parity: historical workflow contract exists, Current-wide ownership not yet proven.
- SP-06 Notification parity: historical notification contract exists, Current-wide ownership not yet proven.

### Errors preserved
- False earlier claim that Current `main.html` lacked Idempotency-Key was corrected by direct source inspection.
- Current/Main vs New-main lineage confusion was corrected.
- DB repair was not treated as browser/runtime closure.
- Receiving idempotency experimentation exposed ordering/operation-identity concerns; tests were transactional and did not leave test data behind.
- Inventory anomalies were detected but not rewritten without proof.

### P154 self-audit
```text
MASTER_REVIEW                    = VERIFIED
CURRENT_STATE_REVIEW             = VERIFIED
ORIGINAL_READ                    = VERIFIED
CURRENT_MAIN_READ                = VERIFIED
PRODUCTION_RELEVANT_CHECK       = VERIFIED
CURRENT_MAIN_MODIFIED            = NO
PRODUCTION_DATA_MODIFIED        = NO (FOR COMPARISON)
FULL_MERGE                       = REJECTED
SURGICAL_UI_PATCHES              = 2
WORKFLOW_PARITY                  = UNVERIFIED
NOTIFICATION_PARITY              = UNVERIFIED
UI_PERMISSION_PARITY             = UNVERIFIED
DASHBOARD_P&L_SOURCE             = UNVERIFIED
GLOBAL_INVENTORY_100_PERCENT     = NO
CLOUDFLARE_LIVE_ARTIFACT         = UNVERIFIED
```

## P154 REPORT
`doc/Draft/Reprots/تقرير15.md`
commit `011518f3e5c6fe83894989f0c2c1d7ce8a5d5ed4`

## REQUIRED NEXT STATE
1. Do not replace `Current/PWA/main.html` with Original or New-main.
2. Owner may manually apply SP-01 and SP-02 only, then perform UI regression.
3. Perform Current-wide forensic tracing for Workflow, Notifications, and UI permission application before issuing additional patches.
4. Trace the authoritative Finance/P&L source before changing dashboard profit.
5. Continue Global Inventory Core Integrity Sweep one Writer Closure Unit at a time.
6. Keep Cloudflare live-runtime closure open until direct served-artifact proof exists.
7. Perform any Production data repair only after source/history/business-impact tracing.

## FINAL STATE
```text
P154_COMPARISON                    = COMPLETE
CURRENT_MAIN_MANUAL_PATCH         = NOT APPLIED
ORIGINAL_AS_BASE                  = REJECTED
SURGICAL_UI_PARITY                = READY
INVENTORY_CORE                    = OPEN
CLOUDFLARE_RUNTIME                = OPEN
CLOSED_100_PERCENT                = NO
```