# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Current truth is established from direct Git, Production, deployment/runtime evidence, and verified artifacts.
- Historical reports are evidence, not current truth.
- `Current/PWA/New-main` is the authorized product target for `erp-frontend/companies/company-1/main.html`.
- `Current/PWA/main.html` is a separate protected artifact; do not replace it by filename similarity.
- Historical reports must not be deleted or overwritten.
- No 100% closure without fresh Production/runtime proof.
- The governing continuity process is: CURRENT_STATE → LAST VERIFIED EVENT → CURRENT GIT → CURRENT PRODUCTION → DEPLOYMENTS/RUNTIME → RECONCILIATION → CURRENT TARGET → SURGICAL CHANGE → VERIFY → CURRENT_STATE UPDATE.

## HISTORICAL CONTINUITY
- P133–P151: authentication, deployment, Service Worker, compatibility-route, and auto-update reconstruction/closures as previously recorded.
- P151 final Git state included the permanent update coordinator; live Cloudflare propagation remained unverified.
- P152: Auth/deployment reconciliation; successful Production auth existed despite browser-side 401; Supabase key rotation was not justified.
- P153: Current-state reconciliation; Report13 Production compatibility migration `20260902023122 / compatibility_company_main_branch_projection_20260902` verified; `main.html` already contained Idempotency-Key + operation_id; Inventory closure remained open.
- P154: Original main1 vs `Current/PWA/main.html` comparison; separate artifact scope.
- P155 / `تقرير16.md`: first direct forensic comparison of `Original/PWA/main/main1.md` vs `Current/PWA/New-main` and initial surgical findings.
- P156 / `تقرير17.md`: corrected forensic pass focused on actual missing/reduced functions and surgical replacement instructions; no target-code modification in that report.
- P157 / `تقرير18.md`: direct verification after owner-side New-main update; four UI changes were present but password/footer CSS was misplaced in body text.
- P158 / `تقرير19.md`: direct verification after the subsequent owner-side correction commit; CSS was moved correctly into `<style>`, raw CSS body text was removed, but one `</div>` closing `rw-form-group` remains missing before `rw-login-options`.

## CURRENT SOURCE IDENTITIES
- `Original/PWA/main/main1.md` SHA `14b12a471c20ad23a2c18f456dbc4d59783a0d1f`.
- `Current/PWA/main.html` SHA `27b777528665dcc985809648f006452c861ae36e` was the previous verified identity; do not infer that this remains unchanged solely from history.
- `Current/PWA/New-main` current Git blob SHA `963e8a6b498ad4544997339ce5ffbd74b332cb64`.
- Latest verified commit affecting `Current/PWA/New-main`: `c3871ef49e5ed40c550f23359d75c1e380093dbd`, message `Update New-main`, author timestamp `2026-09-02T04:31:33Z`.
- Previous target commit `70aaad76c53b6d8fae045e5868938e718b30ee13` was superseded by `c3871ef...`.
- Latest CURRENT_STATE reconciliation report commit: `5d39122ea73fcceeeb6b3c483bd473bb1ecc2a0d` for `doc/Draft/Reprots/تقرير19.md`.
- Do not replace `Current/PWA/New-main` with `Current/PWA/main.html` or with Original by filename similarity.

## LAST VERIFIED EVENT
```text
EVENT ID        = P158-NEW-MAIN-C3871EF
EVENT TYPE      = Direct source verification
UTC TIMESTAMP   = 2026-09-02T04:31:33Z (latest target commit)
SOURCE          = Current/PWA/New-main + Git history + historical reports + Production migration lineage
GIT SHA         = c3871ef49e5ed40c550f23359d75c1e380093dbd
TARGET BLOB     = 963e8a6b498ad4544997339ce5ffbd74b332cb64
ACTION          = Verify owner-side correction against P157 instructions
RESULT          = CSS relocation fixed; one HTML wrapper closure remains missing
EVIDENCE        = direct New-main source + commit diff + report19
IMPACT          = source is not fully closed; runtime must not be declared passed
NEXT AUTHORIZED ACTION = add exactly one missing `</div>` before `.rw-login-options`, re-open/verify, then runtime verification
```

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

Production migration lineage relevant to prior Inventory work has been re-confirmed from Supabase, including manual-voucher tenant/item hardening, receive-purchase idempotency/tenant work, legacy receive-v2 closure, return/delivery centralization, legacy `post_stock_movement` retirement, and the 20260819 inventory write-boundary closure. This does not constitute final Inventory Core closure by itself.

## P158 — DIRECT VERIFICATION OF OWNER-SIDE NEW-MAIN CORRECTION — 2026-09-02
### Scope
- Target: `Current/PWA/New-main`
- Latest target commit: `c3871ef49e5ed40c550f23359d75c1e380093dbd`
- Current blob: `963e8a6b498ad4544997339ce5ffbd74b332cb64`
- Supporting sources: `MASTER - RAWAEA ERP.md`, `CURRENT_STATE.md`, `تقرير16.md`, `تقرير17.md`, `تقرير18.md`, direct Git file content, direct commit history, Production migration lineage.
- Historical reports retained.
- Production data was not modified by this P158 source-verification round.

### P158 current verdict
The owner-side correction fixed the original CSS placement defect from P157/P157 findings. The password toggle CSS and login footer CSS are now inside the existing `<style>` block and the previous raw CSS text is no longer present in the login body.

However, the resulting HTML structure is not an exact match to the required correction because the outer password `.rw-form-group` is not closed before `.rw-login-options`.

### SP-NEW-01 — Notification
- `RW_Notification` remains singular.
- `قراءة الكل` invokes `RW_Notification.markAllRead()`.
- Notification rows invoke `RW_Notification._clickNotif(...)` using `reference_table` and `reference_id`.
- No duplicate notification helper/module was introduced.
- SOURCE STATUS = VERIFIED.

### SP-NEW-02 — Audit
- Owner-only guard remains present.
- Search, action filter, date-from/date-to filters, `count: 'exact'`, 50-row pagination, numbered pages, previous/next, detail view, `old_data`, and `new_data` remain present in the target source.
- No `RW_Table` rewrite was introduced.
- SOURCE STATUS = VERIFIED.

### SP-NEW-03 — Password visibility
- Password toggle HTML exists.
- Existing `window.togglePasswordVisibility` helper remains the hook.
- Required password CSS rules are now in `<style>`.
- Previous raw CSS body text is removed.
- Remaining defect: missing outer `</div>` for `.rw-form-group` before `.rw-login-options`.
- SOURCE STATUS = PARTIALLY CLOSED.

### SP-NEW-04 — Login footer
- Footer element exists inside the login form.
- Footer CSS is now in `<style>`.
- Remaining defect is the same shared missing `</div>` in the password form-group, not footer CSS placement.
- SOURCE STATUS = PARTIALLY CLOSED.

### EXACT REMAINING CORRECTION
Required source transition:
```html
  </div>
</div>
<div class="rw-login-options">
```
Current source has:
```html
  </div>
<div class="rw-login-options">
```
Only one `</div>` must be inserted between those two lines.

## KNOWN FAILURE MEMORY
- F-06: inserting CSS rules as raw text into HTML body; corrected in P158.
- F-07: CURRENT_STATE becoming stale after owner-side Git changes; reconciled in P158.
- F-08: CSS relocation can still leave HTML nesting errors; source structure must be checked independently of CSS placement.
- Historical Inventory/Receive-Purchase experiments must not be repeated by reconstructing operation identity from mutable `qty_received_before` alone; use explicit operation identity where the current contract supports it.

## CURRENT PRODUCTION / DEPLOYMENT STATUS
- Production migration history was re-read directly from Supabase during continuity recovery.
- No Production business data or inventory rows were modified by P158.
- Cloudflare served-artifact parity for the current `New-main` commit is NOT proven in this round.
- Browser runtime behavior after `c3871ef...` is NOT proven in this round.
- Git/source verification must not be promoted to runtime/production verification.

## REPORTS
- P155: `doc/Draft/Reprots/تقرير16.md`
- P156: `doc/Draft/Reprots/تقرير17.md`
- P157: `doc/Draft/Reprots/تقرير18.md`
- P158: `doc/Draft/Reprots/تقرير19.md`
- P158 report commit: `5d39122ea73fcceeeb6b3c483bd473bb1ecc2a0d`

## REQUIRED NEXT STATE
1. Correct the single missing `</div>` in `Current/PWA/New-main`.
2. Re-open the target file and verify exact login DOM nesting.
3. Verify the five CSS rules are inside `<style>` and absent as raw body text.
4. Verify SP-NEW-01 and SP-NEW-02 remain intact after the correction.
5. Verify current blob and commit identity again.
6. Then perform Cloudflare/browser runtime verification.
7. Keep Inventory Core Integrity as a separate open track.

## FINAL STATE
```text
MASTER_RECOVERY                 = COMPLETE
CURRENT_STATE_RECONCILIATION    = COMPLETE
P158_SOURCE_FORENSIC            = COMPLETE
TARGET_NEW_MAIN_BLOB            = 963e8a6b498ad4544997339ce5ffbd74b332cb64
TARGET_NEW_MAIN_COMMIT          = c3871ef49e5ed40c550f23359d75c1e380093dbd
SP-NEW-01                       = SOURCE VERIFIED
SP-NEW-02                       = SOURCE VERIFIED
SP-NEW-03                       = PARTIAL / ONE HTML CLOSURE ERROR
SP-NEW-04                       = PARTIAL / SHARED HTML CLOSURE ERROR
CSS_RELOCATION                  = VERIFIED
RAW_BODY_CSS                    = REMOVED
CLOUDFLARE_RUNTIME              = OPEN
BROWSER_RUNTIME                 = OPEN
INVENTORY_CORE                  = OPEN
CLOSED_100_PERCENT              = NO
NEXT_AUTHORIZED_ACTION          = INSERT ONE MISSING </div>, RE-VERIFY, THEN RUNTIME VERIFY
```