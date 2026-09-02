# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Current truth is established from direct Git, Production, deployment/runtime evidence, and verified artifacts.
- Historical reports are evidence, not current truth.
- `Current/PWA/New-main` is the authorized product target for `erp-frontend/companies/company-1/main.html`.
- `Current/PWA/main.html` is a separate protected artifact; do not replace it by filename similarity.
- Historical reports must not be deleted or overwritten.
- No 100% closure without fresh Production/runtime proof.
- In the present P157 continuity round, the owner authorized direct forensic verification of the latest New-main changes and exact surgical correction instructions.

## HISTORICAL CONTINUITY
- P133–P151: authentication, deployment, Service Worker, compatibility-route, and auto-update reconstruction/closures as previously recorded.
- P151 final Git state included the permanent update coordinator; live Cloudflare propagation remained unverified.
- P152: Auth/deployment reconciliation; successful Production auth existed despite browser-side 401; Supabase key rotation was not justified.
- P153: Current-state reconciliation; Report13 Production compatibility migration `20260902023122 / compatibility_company_main_branch_projection_20260902` verified; `main.html` already contained Idempotency-Key + operation_id; Inventory closure remained open.
- P154: Original main1 vs `Current/PWA/main.html` comparison; separate artifact scope.
- P155 / `تقرير16.md`: first direct forensic comparison of `Original/PWA/main/main1.md` vs `Current/PWA/New-main` and initial surgical findings.
- P156 / `تقرير17.md`: corrected forensic pass focused on actual missing/reduced functions and surgical replacement instructions; no target-code modification in that report.
- P157 / `تقرير18.md`: direct verification after the owner-side New-main update; SP-NEW-01/02/04 present, SP-NEW-03/04 structurally affected by misplaced CSS text inside body; exact correction documented.

## CURRENT SOURCE IDENTITIES
- `Original/PWA/main/main1.md` SHA `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.
- `Current/PWA/main.html` SHA `27b777528665dcc985809648f006452c861ae36e` was the previous verified identity; do not infer that this remains unchanged solely from history.
- `Current/PWA/New-main` is the authorized target and has a new latest Git commit `70aaad76c53b6d8fae045e5868938e718b30ee13` as of 2026-09-02 07:18:06 +03:00.
- The latest New-main commit is titled `Update New-main` and contains the four surgical UI changes from P156/P157 review.
- Do not replace `Current/PWA/New-main` with `Current/PWA/main.html` or with Original by filename similarity.

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

## P157 — DIRECT VERIFICATION OF OWNER-SIDE NEW-MAIN SURGICAL UPDATE — 2026-09-02
### Scope
- Target: `Current/PWA/New-main`
- Latest target commit: `70aaad76c53b6d8fae045e5868938e718b30ee13`
- Supporting sources: `MASTER - RAWAEA ERP.md`, `CURRENT_STATE.md`, `doc/Draft/Reprots/تقرير17.md`, `تقرير16.md`, direct Git file content, direct commit diff.
- Historical reports retained.
- Production was not modified by this UI verification round.

### Current verdict
The owner-side update did apply the intended four UI recoveries, but it introduced a structural HTML defect: CSS declarations for the password toggle and login footer were inserted as raw text nodes inside the login `<form>` rather than inside the existing `<style>` block.

### SP-NEW-01 — Notification
- Applied in latest New-main.
- `قراءة الكل` invokes `RW_Notification.markAllRead()`.
- Notification rows invoke `RW_Notification._clickNotif(...)` with `reference_table` and `reference_id`.
- No duplicate notification module/helper is required.

### SP-NEW-02 — Audit
- Applied in latest New-main.
- Current source contains search, action filter, date-from/date-to filters, exact count, 50-row pagination, numbered pages, detail action, old_data and new_data rendering.
- No RW_Table rewrite is authorized or required for this task.

### SP-NEW-03 — Password visibility
- Password toggle HTML is present.
- Existing `window.togglePasswordVisibility` helper is present.
- CSS declarations are currently misplaced in body text immediately after the password field.
- This is the only correction required for the password toggle package.

### SP-NEW-04 — Login footer
- Footer element is present in the login form.
- Footer CSS is currently misplaced in body text after the form.
- This is the same structural correction as SP-NEW-03.

### EXACT REQUIRED CORRECTION
In `Current/PWA/New-main`:
1. Remove the raw CSS text currently located in the login body:
```text
</div>.rw-password-wrap{position:relative;width:100%}
.rw-password-wrap .rw-input{padding-left:52px}
.rw-password-toggle{position:absolute;left:8px;top:50%;transform:translateY(-50%);width:38px;height:38px;border:0;border-radius:10px;background:transparent;color:#64748b;display:grid;place-items:center;cursor:pointer;font-size:17px}
.rw-password-toggle:hover{background:#f1f5f9;color:#2563eb}
```
The password group must be followed directly by:
```html
</div>
<div class="rw-login-options">
```
2. Remove from body:
```text
.rw-login-footer{margin-top:4px;text-align:center;color:#64748b;font-size:11px;font-weight:700;line-height:1.8}
```
3. Add the following rules inside the existing `<style>` block in `<head>`, immediately before `.rw-login-options`:
```css
.rw-password-wrap{position:relative;width:100%}
.rw-password-wrap .rw-input{padding-left:52px}
.rw-password-toggle{position:absolute;left:8px;top:50%;transform:translateY(-50%);width:38px;height:38px;border:0;border-radius:10px;background:transparent;color:#64748b;display:grid;place-items:center;cursor:pointer;font-size:17px}
.rw-password-toggle:hover{background:#f1f5f9;color:#2563eb}
.rw-login-footer{margin-top:4px;text-align:center;color:#64748b;font-size:11px;font-weight:700;line-height:1.8}
```

### What remains unproven
- Cloudflare live served artifact parity after commit `70aaad76...`.
- Browser runtime behavior after the CSS relocation.
- Full runtime closure of all P156 UI packages until the corrected artifact is served and exercised.

### P157 SELF-AUDIT
```text
MASTER RECOVERY                 = VERIFIED
CURRENT_STATE REVIEW            = VERIFIED / UPDATED
RECENT REPORT CHAIN             = VERIFIED
LATEST NEW-MAIN COMMIT          = VERIFIED
NEW-MAIN SOURCE                 = OPENED DIRECTLY
SP-NEW-01                       = APPLIED
SP-NEW-02                       = APPLIED
SP-NEW-03                       = APPLIED / CSS MISPLACED
SP-NEW-04                       = APPLIED / CSS MISPLACED
TARGET CODE MODIFIED THIS ROUND = NO
PRODUCTION MODIFIED             = NO
HISTORICAL REPORTS DELETED      = NO
CLOUDFLARE RUNTIME VERIFIED     = NO
100_PERCENT_CLOSED              = NO

FINAL CURRENT TARGET
= Current/PWA/New-main

NEXT AUTHORIZED ACTION
= Correct the two CSS placement errors only, then re-open and verify the target before runtime verification.
```

## REPORTS
- P155: `doc/Draft/Reprots/تقرير16.md`
- P156: `doc/Draft/Reprots/تقرير17.md`
- P157: `doc/Draft/Reprots/تقرير18.md`
- P157 report commit: `64c25c0b9ef2301ea02e94e50ea5d29d4d49761f`

## REQUIRED NEXT STATE
1. Correct the exact CSS placement defect in `Current/PWA/New-main`.
2. Verify the password toggle and footer rules are inside `<style>` and absent as raw body text.
3. Verify SP-NEW-01 and SP-NEW-02 remain intact.
4. Verify the corrected Git file and commit identity.
5. Then perform runtime verification against the served artifact.
6. Keep Inventory Core Integrity and Cloudflare runtime as separate open tracks.

## FINAL STATE
```text
P155_FORENSIC_COMPARISON        = COMPLETE
P156_SURGICAL_FINDINGS          = COMPLETE
P157_SOURCE_VERIFICATION        = COMPLETE
TARGET_NEW_MAIN_MODIFIED        = OWNER-SIDE COMMIT PRESENT
OWNER_PATCHES_01_02             = APPLIED
PASSWORD_TOGGLE_UI              = APPLIED / CSS PLACEMENT NEEDS CORRECTION
LOGIN_FOOTER                    = APPLIED / CSS PLACEMENT NEEDS CORRECTION
PAGINATION                      = UX REDUCTION ONLY
INVENTORY CORE                  = OPEN
CLOUDFLARE RUNTIME              = OPEN
CLOSED_100_PERCENT              = NO
```