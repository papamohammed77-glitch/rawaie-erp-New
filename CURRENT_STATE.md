# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git, Production Supabase, deployed runtime evidence, and published artifact evidence.
- Historical reports are evidence only; never trust them over direct sources.
- `Current/PWA/New-main` is the authorized product target for `erp-frontend/companies/company-1/main.html`.
- `Current/PWA/main.html` remains protected and untouched.
- Historical reports are sacred and must never be deleted or overwritten.
- Git commit success is never treated as Production runtime proof.
- No 100% closure is declared without fresh Production/runtime evidence.

## HISTORICAL CONTINUITY
- P133: auth bootstrap repair; browser verification remained open.
- P134: deployment-lineage mismatch; runtime showed 401 and `/companies/sw.js` 404.
- P135: direct runtime source repair; target `New-main`; marker `RAWAEA_P135_TARGET`.
- P136: MAIN11 scope repair; shared client exported.
- P137: Service Worker finalized as P137 FINAL, cache namespace `rw-static-v3`.
- P138–P140: repeated reconciliation proved Git/Production runtime inconsistency; Cloudflare lineage remained unproven.
- P141–P143: reconstruction/assembly continued after state drift.
- P144: one-shot New-main Service Worker path repair; evidence preserved in `Current/CTO/20260901_P144_RUNTIME_SURGICAL_REPAIR.json`.
- P145: active Production Supabase key proved valid; 401 remained a served-runtime/deployment boundary issue.
- P146: published deployment boundary repaired with compatibility routes for historical Manifest/SW URLs.
- P150: permanent SW auto-update/cache contract implemented in source and published repository.
- P151: closed P150's remaining New-main coordinator gap by making the SW inject the shared update coordinator into controlled HTML; syntax failure was detected and corrected before final closure.

## DIRECT FORENSIC FINDINGS — 2026-09-02
### Auth/runtime
- Production Supabase `fiilmooggumokxanwiyx` is `ACTIVE_HEALTHY`.
- Current and published Git contain the active Production legacy anon key; credential replacement remains unjustified without new runtime evidence.
- `RW_Auth.login` uses `signInWithPassword`; no defect in that call was proven.
- Last proven runtime state before P150/P151 still had `401 Invalid API key`; the live Cloudflare artifact is not directly readable through an available connector here.

### P146 compatibility boundary
- Published `_redirects` continues to route:
  - `/companies/manifest.json -> /companies/company-1/manifest.json`
  - `/companies/sw.js -> /companies/company-1/sw.js`

## P150/P151 — PERMANENT AUTO-UPDATE CONTRACT
### Historical contract
`Original/PWA/register-sw.js` used:
- immediate registration;
- `registration.update()` every 60 seconds;
- update checks on `visibilitychange`;
- `controllerchange` handling.

`Original/PWA/sw.js` used:
- `skipWaiting()`;
- `clients.claim()`;
- Network Only for HTML/API;
- cache cleanup;
- `RW_SW_UPDATED` notification.

### Current gap proven
`Current/PWA/New-main` does not load `register-sw.js` directly. It registers `./sw.js` inline.

### P150
- Versioned SW cache namespace.
- Immediate activation.
- Automatic reload of in-scope windows after activation.
- Explicit no-cache/no-store deployment headers for app shell/SW identity in `erp-frontend/_headers`.

### P151 final design
`Current/PWA/sw.js` and published `companies/company-1/sw.js` now:
- use build marker `RAWAEA_SW_P151_AUTO_UPDATE_COORDINATOR`;
- use versioned cache `rw-static-RAWAEA_SW_P151_AUTO_UPDATE_COORDINATOR`;
- keep HTML/API/runtime code network-backed;
- activate immediately with `skipWaiting()`;
- claim clients with `clients.claim()`;
- automatically reload all in-scope windows on SW activation;
- inject `register-sw.js` into controlled HTML before `</head>` when the coordinator marker is absent.

The injected script path is derived from the SW registration scope, so nested pages resolve it against the application scope rather than their own directory.

The shared `register-sw.js` in Current and Published now performs:
- immediate `registration.update()`;
- 60-second polling;
- update on visibility;
- update on online;
- automatic reload on `controllerchange`.

The injection approach intentionally avoids destructive editing of the very large protected `New-main` file while still making the coordinator reachable from the actual main application after SW control is established.

## P151 EXECUTION RECORD
- Current SW final commit: `897e3336f3d68a948eba0b6f2aa5478526e42281`
- Published SW final commit: `13f4757bad0bcef2bd35e7d15e22e6c23d9e8498`
- Shared Current register coordinator commit: `ff033853b54af30dd1b26941f831471a71853fa8`
- Shared Published register coordinator commit: `5ed2a1d905fb9fdc479fad5d3ddf2a2f19ae8d3b`
- Published `_headers` commit: `49ad44762b36016151d90059c22dcb0e33d586e6`
- P151 audit report: `doc/Draft/Reprots/تقرير11.md` commit `63325869cf83ba62fb14db2d2492cbf907c64e95`.
- `CURRENT_STATE.md` was updated after P151.

## P151 ERROR / CORRECTION
- First P151 draft contained a missing closing parenthesis in the static-assets `event.respondWith(...)` branch.
- Local `node --check` caught the syntax error.
- The final Current SW was corrected and `node --check` returned `SW_SYNTAX_PASS`.
- The corrected source was then written to Git and mirrored to the published repository.

## IMPORTANT DEPLOYMENT BOUNDARY
- No GitHub Actions run exists for the P150/P151 commits through the available workflow lookup.
- The repository therefore provides no independent CI evidence that Cloudflare has already served P151.
- Direct Cloudflare Worker deployment/source inspection is unavailable in this execution context.
- Consequently `LIVE_CLOUDFLARE_ARTIFACT` and `LIVE_DEVICE_PROPAGATION` remain unverified.

## CURRENT STATUS FLAGS
```text
MASTER_GOVERNANCE_REVIEW         = VERIFIED
CURRENT_STATE_RECONCILED         = VERIFIED / UPDATED_P151
REPORT_HISTORY                   = PRESERVED
SUPABASE_PRODUCTION              = ACTIVE_HEALTHY
SUPABASE_ANON_KEY_IN_CURRENT     = VERIFIED_ACTIVE
SUPABASE_ANON_KEY_IN_PUBLISHED   = VERIFIED_ACTIVE
RW_AUTH_LOGIN_SOURCE             = VERIFIED_NO_DEFECT_PROVEN
BROWSER_LOGIN                    = OPEN / LAST_PROVEN_401
RUNTIME_WORKER_ARTIFACT           = UNKNOWN / DIRECTLY_UNREADABLE_HERE
CLOUDFLARE_DEPLOYMENT_STATE       = UNVERIFIED
MANIFEST_COMPAT_ROUTE             = COMMITTED_P146
LEGACY_SW_COMPAT_ROUTE            = COMMITTED_P146
P150_SOURCE                       = COMPLETE
P151_SOURCE                       = COMPLETE
P151_SYNTAX                       = VERIFIED_PASS
P151_UPDATE_COORDINATOR           = COMPLETE
P151_CDN_POLICY                   = PRESENT
P151_LIVE_PROPAGATION              = UNVERIFIED
PRODUCTION_RUNTIME_AFTER_P151     = NOT_YET_VERIFIED_BY_NEW_BROWSER_EVENT
GOLD                              = UNPROVEN
DIAMOND                           = UNPROVEN
CLOSED_100_PERCENT                = NO
```

## REQUIRED NEXT RUNTIME TEST
A fresh browser/network observation must prove:
1. live `sw.js` returns P151 build marker;
2. live `register-sw.js` returns the P151 coordinator;
3. `/companies/sw.js` is 200;
4. `/companies/manifest.json` is 200;
5. a new SW version automatically activates and existing app windows reload without manual cache clearing;
6. login and session restoration continue to work;
7. no new uncaught console error blocks the shell.

## INVENTORY CONTINUITY
The Global Inventory Core Integrity Sweep remains governed by:

`PHYSICAL STOCK MOVEMENT → post_stock_movement → stock_branches + inventory_log`

with `reserve_stock` limited to reservation responsibility.

Previous forensic work identified additional Writer/tenant closure issues; they remain open until each Writer is independently proven, fixed, deployed, and production-verified. No Inventory 100% claim has been made from reports alone.

## FINAL FORENSIC JUDGMENT
The permanent update architecture is now complete at the **source/Git level**:

```text
NEW SW DETECTED
   ↓
skipWaiting
   ↓
activate
   ↓
clients.claim
   ↓
automatic in-scope reload
   ↓
HTML served through SW
   ↓
register-sw.js injected
   ↓
immediate + periodic update checks
```

This removes the historical requirement for manual cache clearing and the old manual "Update now" interaction.

The only remaining gap is external to the source change itself: direct proof that the live Cloudflare Worker is now serving P151 and that real user devices have consumed the new deployment. Until that runtime fact is observed, `CLOSED_100_PERCENT` remains `NO`.

## P152 — FORENSIC AUTH / DEPLOYMENT RECONCILIATION — 2026-09-02

### Scope
This closure unit was executed from the Master Continuity command rather than from memory or previous percentages. The following were reconciled directly:
- Master governance command;
- continuation directive;
- Reports 9–11 and the complete report directory listing;
- `CURRENT_STATE.md`;
- `Current/PWA/New-main`;
- `Current/PWA/sw.js`;
- `Current/PWA/register-sw.js`;
- `Current/Edge_Functions/create-stock-voucher`;
- `Current/Edge_Functions/receive-purchase`;
- `Current/CTO/20260901_P144_RUNTIME_SURGICAL_REPAIR.json`;
- `erp-frontend/companies/company-1/main.html`;
- `erp-frontend/companies/company-1/sw.js`;
- `erp-frontend/companies/company-1/register-sw.js`;
- `erp-frontend/README.md`;
- Production Supabase Auth/API/Postgres evidence;
- Git history/status evidence available to the executor.

### Current ↔ Published main artifact
Direct Git blob comparison proved:

```text
Current/PWA/New-main
SHA = 5bf6907747d807dfa9f10979f5a63685c8bae64e

erp-frontend/companies/company-1/main.html
SHA = 5bf6907747d807dfa9f10979f5a63685c8bae64e
```

Therefore the two files are byte-identical Git blobs. There is no remaining manual copy operation for the owner to perform between these repositories.

### P151 source proof
Current and Published Service Workers contain the P151 marker:

```text
RAWAEA_SW_P151_AUTO_UPDATE_COORDINATOR
```

Current and Published `register-sw.js` contain the permanent update coordinator behavior.

### Production Supabase Auth proof
Production project `fiilmooggumokxanwiyx` remains active and exposes both:
- legacy `anon` key: enabled;
- publishable key: enabled.

No evidence justified replacing the current key in source.

Production Auth logs also prove a real successful login from:

```text
https://erp-frontend.mh0537413487.workers.dev
```

at:

```text
2026-09-01T16:16:33Z
```

with `/token = 200`, Login event, and `/user = 200` shortly after.

Therefore the current `401 Invalid API key` cannot be attributed solely to a globally invalid Supabase key without contradicting direct Production evidence.

### Browser failure remains real
The new browser evidence still reports:

```text
POST /auth/v1/token?grant_type=password → 401
AuthApiError: Invalid API key
```

This is a genuine Auth-layer rejection and remains unresolved at live-runtime level.

### Runtime lineage finding
The live runtime hostname observed in Auth logs is a Cloudflare Worker hostname:

```text
erp-frontend.mh0537413487.workers.dev
```

`erp-frontend` identifies itself in Git as a Cloudflare Pages frontend. The current execution environment has no direct Cloudflare control-plane connector capable of inspecting the Worker source, deployment version, environment bindings, route mapping, or exact served artifact.

Therefore the unresolved lineage is:

```text
Git source
   ↓
Published repository
   ↓
[UNVERIFIED DEPLOYMENT BRIDGE]
   ↓
Cloudflare Worker live artifact
   ↓
Browser
```

### Important correction
The console marker:

```text
RAWAEA_P135_TARGET New-main
```

is **not** treated as proof of a stale P135 artifact because the marker remained part of the `New-main` source across later stages. Using it as sole stale-runtime evidence would violate the no-assumption rule.

### Current Edge evidence relevant to Inventory
`Current/Edge_Functions/create-stock-voucher` is now a company-context wrapper and routes creation through the manual voucher RPC instead of being a standalone Physical Stock writer.

`Current/Edge_Functions/receive-purchase` now obtains company context from the authenticated user and carries a deterministic/client-supplied `operation_id` into `receive_purchase_atomic`.

These are source findings only; no Inventory Writer is marked 100% closed without independent Production runtime verification.

### What was intentionally NOT changed in P152
Because no defect was proven in the source Login call and no global Supabase key defect was proven, P152 did not:
- replace the Supabase key;
- rewrite `signInWithPassword`;
- add a fallback authentication path;
- disable JWT/auth verification;
- modify protected `Current/PWA/main.html`.

### P152 error / correction record
- Risk initially identified: interpreting the P135 marker as proof of stale runtime. Corrected after source/history reconciliation.
- Unsupported hypothesis rejected: changing the Supabase key merely because the browser reported `Invalid API key`.
- Unsupported hypothesis rejected: rewriting the login call without a proven defect.
- External inspection limitation: Cloudflare Worker deployment/source could not be read through the available connectors. This remains an evidence boundary, not a fabricated success.

### P152 report
Full forensic record:

```text
doc/Draft/Reprots/تقرير12.md
```

Report commit:

```text
9ccd822a02c6d6e40552ce4817cb8568c458f06e
```

## P152 STATUS FLAGS
```text
P152_GOVERNANCE_REVIEW             = VERIFIED
P152_REPORT_CREATED                = VERIFIED
P152_REPORT_HISTORY_PRESERVED      = VERIFIED
CURRENT_MAIN_BLOB                  = 5bf6907747d807dfa9f10979f5a63685c8bae64e
PUBLISHED_MAIN_BLOB                = 5bf6907747d807dfa9f10979f5a63685c8bae64e
CURRENT_PUBLISHED_MAIN_MATCH       = VERIFIED
CURRENT_P151_SW                    = VERIFIED_IN_GIT
PUBLISHED_P151_SW                  = VERIFIED_IN_GIT
CURRENT_REGISTER_COORDINATOR       = VERIFIED_IN_GIT
PUBLISHED_REGISTER_COORDINATOR     = VERIFIED_IN_GIT
SUPABASE_PROJECT                   = ACTIVE_HEALTHY
SUPABASE_LEGACY_ANON               = ENABLED
SUPABASE_PUBLISHABLE               = ENABLED
SAME_WORKER_SUCCESSFUL_AUTH        = PROVEN_2026-09-01T16:16:33Z
CURRENT_BROWSER_AUTH               = OPEN / 401_INVALID_API_KEY
RW_AUTH_SOURCE_DEFECT              = NOT_PROVEN
LIVE_WORKER_ARTIFACT               = UNREADABLE_HERE
LIVE_WORKER_DEPLOYMENT             = UNVERIFIED
GIT_TO_WORKER_LINEAGE              = UNPROVEN
P152_AUTH_CLOSURE                  = OPEN
GLOBAL_INVENTORY_100_PERCENT       = NO
CLOSED_100_PERCENT                 = NO
```

## REQUIRED NEXT CLOSURE
The next closure unit must be **CLOUDFLARE RUNTIME ARTIFACT RECONCILIATION**, not another speculative Login patch.

Required proof:
1. exact Worker route and deployment/version;
2. exact Worker source/environment binding without exposing secrets;
3. live served main artifact fingerprint compared with Git SHA `5bf6907747d807dfa9f10979f5a63685c8bae64e`;
4. live P151 Service Worker marker;
5. live register coordinator;
6. compatibility routes;
7. fresh browser Login after verified live deployment;
8. no new uncaught console error.

Until then:

```text
CLOUDFLARE_RUNTIME_AUTH_CLOSURE = OPEN
```

## P153 — FORENSIC CONTINUITY / MAIN.HTML SURGICAL VERIFICATION — 2026-09-02

### Purpose
This event reconciled the real current state against the Master Continuity command, the Inventory continuation directive, Report 13, and the live Production database contracts. It specifically resolves the owner's question about whether `main.html` currently requires a manual surgical replacement.

### LAST VERIFIED PRODUCTION EVENT
The latest directly verified Production migration remains:

```text
20260902023122
compatibility_company_main_branch_projection_20260902
```

The Production migration history was queried directly and confirmed this version exists.

### CURRENT_STATE DRIFT FOUND
`CURRENT_STATE.md` previously stopped at P152 while `doc/Draft/Reprots/تقرير13` already recorded a Production database repair. Therefore the file was stale relative to the latest documented execution event.

This update closes that documentation drift without rewriting or deleting historical reports.

### MAIN.HTML FINDING — DEFINITIVE
A direct current Git read shows that the current purchase-receiving flow already generates an operation id and sends it in both places:

```javascript
headers:{'Content-Type':'application/json','Authorization':'Bearer '+t,'Idempotency-Key':opId},
body:JSON.stringify({po_code:poCode,itemsReceived:r.value,notes:notes,operation_id:opId})
```

Therefore:

```text
MAIN.HTML_IDEMPOTENCY_KEY = ALREADY PRESENT
MANUAL REPLACEMENT        = NOT REQUIRED
```

A previous statement in the execution conversation claiming that `main.html` did not send `Idempotency-Key` was incorrect. That statement is superseded by direct current-source evidence and must not be used to justify a manual edit.

### MAIN BRANCH COMPATIBILITY FINDING
Current code reads:

```javascript
var c=await supabase.from('companies').select('id,name,logo_url,main_branch_id,main_branch_code').eq('id',u.data.company_id).maybeSingle();
```

This lookup is company-scoped. The historical failure was the absence of the requested columns in `companies`, which Report 13 addressed through a compatibility projection sourced from `app_settings.main_branch_id`. No manual edit to this line is presently justified.

### FILE LINEAGE
Current product target:

```text
Current/PWA/New-main
SHA = 5bf6907747d807dfa9f10979f5a63685c8bae64e
```

Separate protected file:

```text
Current/PWA/main.html
SHA = 27b777528665dcc985809648f006452c861ae36e
```

These are different blobs. They must not be merged, copied, or substituted based only on name similarity.

### CURRENT EDGE CONTRACTS
- `create-stock-voucher` is currently RPC-backed and resolves company context through `users.auth_id`.
- `receive-purchase` currently resolves company context through `users.auth_id`, accepts `operation_id` / `Idempotency-Key`, and calls the operation-aware Production `receive_purchase_atomic` contract.

### PRODUCTION RPC SIGNATURE SNAPSHOT
Current Production PostgreSQL directly reports:

```text
create_manual_stock_voucher_atomic(...10 args)
create_manual_stock_voucher_atomic(...12 args, p_operation_id text)
post_inventory_adjustment_atomic(...7 args)
post_manual_stock_voucher_atomic(...6 args, p_operation_id text)
receive_purchase_atomic(...5 args, p_operation_id uuid)
send_stock_voucher_atomic(...3 args)
```

### INVENTORY STATUS
The Inventory Zero-Debt Sweep remains open. The immutable stock contract is still:

```text
PHYSICAL STOCK MOVEMENT
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

No global Inventory 100% closure is claimed.

### DATA ANOMALY STATUS
Direct Production inspection found cross-company item metadata relationships in `stock_branches` and `inventory_log`. They were not deleted or rewritten because the evidence does not yet prove that all such rows are invalid fixtures rather than legitimate global-item/legacy relationships.

Status:

```text
DETECT = YES
TRACE  = REQUIRED
REPAIR = NOT AUTHORIZED YET
```

### WHAT WAS NOT CHANGED IN P153
- No manual `main.html` patch for `Idempotency-Key`.
- No replacement of `Current/PWA/main.html` with `New-main`.
- No Supabase credential rotation.
- No deletion of historical reports.
- No false Inventory closure claim.

### P153 SELF-AUDIT
```text
MASTER_GOVERNANCE_REVIEW          = VERIFIED
CONTINUATION_PROMPT               = VERIFIED
REPORT_HISTORY                    = PRESERVED
CURRENT_STATE_DRIFT               = FOUND_AND_CORRECTED
REPORT13_PRODUCTION_MIGRATION     = VERIFIED_IN_PRODUCTION
NEW_MAIN_SHA                       = VERIFIED
CURRENT_MAIN_HTML_SHA              = VERIFIED
MAIN_HTML_IDEMPOTENCY_FIX         = ALREADY_PRESENT
MAIN_HTML_MANUAL_PATCH             = NOT_REQUIRED
MAIN_BRANCH_COMPAT_FIX            = DATABASE_SIDE / VERIFIED
RECEIVE_PURCHASE_OPERATION_CONTRACT= VERIFIED_IN_PRODUCTION
CLOUDFLARE_LIVE_ARTIFACT           = UNVERIFIED
GLOBAL_INVENTORY_CLOSURE            = OPEN
```

### NEXT AUTHORIZED STATE
```text
1. Do not manually modify main.html for the already-present Idempotency-Key contract.
2. Continue the GLOBAL INVENTORY CORE INTEGRITY SWEEP one Writer Closure Unit at a time.
3. Preserve the Cloudflare runtime boundary as OPEN until direct evidence exists.
4. Any Production data cleanup must follow source/history/business-impact tracing first.
```

### P153 REPORT
```text
doc/Draft/Reprots/تقرير14.md
```

Report commit:

```text
92d82f54d726f8ac3804e4dff80007b89f786b5d
```
