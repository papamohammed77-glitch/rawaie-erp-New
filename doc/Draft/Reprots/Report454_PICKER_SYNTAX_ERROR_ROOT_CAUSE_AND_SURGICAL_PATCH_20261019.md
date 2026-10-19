# Report454 — Picker Syntax Error Root Cause and Surgical Patch
**Date:** 2026-10-19  
**Scope:** `erp-frontend/companies/company-1/warehouse/picker.html` only.  
**Owner boundary:** The owner applies the operational HTML patch. No edits to `main.html` or `picker.html` were made by this assistant.

## 1. Fresh source and history
- Current Picker source blob SHA: `f87c539e32074ae0e586e3ccd7ff2add68cffe1f`.
- Latest commit: `0c1ea67bc81ee5e001af69d0366de90ede8795f7` (2026-10-19 20:39:28 UTC), “Enhance picker functionality with operation ID handling”.
- Its parent: `b903c403c8bebf7f98307d22f9c7ca286c72382e`, “Improve error handling and session management in picker”.
- The parent commit patch proves the syntax defect was introduced in `renderPendingTab()` by adding a multi-line literal inside single quotes. The latest operation-id commit did not introduce this defect.
- Historical parent source at `09f62423b7ad7f455a97467d1f9885dce000afa8`, blob `c7ad267d852d415b680aed7716833eea9bcffdf6`, used a valid catch handler and did not contain the broken new error branch.

## 2. Root cause
Inside `App.renderPendingTab()`, the newly added `results[0].error || results[1].error` branch passes a raw line break inside a normal single-quoted JavaScript string:
```js
safeHTML( byId('mainContent'), '

            تعذر تحميل الرانشيتات. حدّث الصفحة أو راجع صلاحياتك واتصالك.
            ' ); return;
```
A normal JavaScript single-quoted string cannot contain literal line terminators. The browser therefore fails to parse the entire inline script at the reported syntax location. The later `App is not defined` error is consequential: parsing failed before the `var App = {...}` declaration could execute. The Tailwind CDN warning and favicon 404 are separate, non-causal issues.

## 3. Exact owner surgical patch
**File:** `erp-frontend/companies/company-1/warehouse/picker.html`  
**Function:** `App.renderPendingTab()`  
**Element:** Error branch immediately after `Promise.all([p1, p2]).then(function(results){`  
**Find this exact text** (whitespace may differ):
```js
if (results[0].error || results[1].error) { console.error('Picker runsheets load error:', { mine: results[0].error || null, available: results[1].error || null }); 
            safeHTML( byId('mainContent'), '

            تعذر تحميل الرانشيتات. حدّث الصفحة أو راجع صلاحياتك واتصالك.
            ' ); return; 
            }
```
**Delete it and replace it completely with:**
```js
if (results[0].error || results[1].error) {
    console.error('Picker runsheets load error:', {
        mine: results[0].error || null,
        available: results[1].error || null
    });
    safeHTML(
        byId('mainContent'),
        '<div class="text-center py-20 text-red-400">تعذر تحميل الرانشيتات. حدّث الصفحة أو راجع صلاحياتك واتصالك.</div>'
    );
    return;
}
```
This keeps the same intended error handling and message while using a valid single-line HTML string. It does not change query behavior, lifecycle, reservations, stock, RPC contracts, or API payloads.

## 4. Production/database cross-check
- Live Supabase project `fiilmooggumokxanwiyx` is active and healthy.
- Live Edge versions observed during this resync: `start-picking v35` (`verify_jwt=true`), `complete-picking v18` (`verify_jwt=true`), `start-loading v5`, `complete-loading v11` (both `verify_jwt=true`).
- Live SQL confirms `complete_runsheet_picking(uuid,text,text,jsonb,uuid)` is service-role-only; `reserve_stock(uuid,uuid,uuid,numeric)` is service-role-only. `post_stock_movement` has both a legacy 9-argument overload (not executable by anon/authenticated/service_role) and a 10-argument idempotent overload (service-role executable). No change to these contracts is required to repair a JavaScript parse error.
- Recent Supabase logs did not establish a server-side cause for this static HTML syntax error. The browser error is directly explained by the current source and parent-commit patch.
- No SQL, schema, ACL, Edge Function, production business data, or test fixtures were changed. Production test data is unnecessary for this compile-time fix and existing runsheets must not be mutated as test fixtures.

## 5. Validation after owner applies the patch
1. Save the file and run a JavaScript syntax check on the complete inline script(s).
2. Reload the served Picker with cache disabled.
3. Confirm there is no `Uncaught SyntaxError` and `App is not defined` no longer appears.
4. Confirm login buttons call `App.togglePass()` and `App.doLogin()`.
5. Exercise both successful runsheet reads and a controlled read-error path; the latter should show the intended Arabic error message.
6. Confirm no changes to `main.html`, no direct inventory mutations, and no production test residue.
7. Re-fetch the file after deployment and record the new blob SHA plus served-artifact/browser evidence.

## 6. Status
**ROOT CAUSE PROVEN / EXACT OWNER PATCH PROVIDED / PRODUCTION CORE CHECKED / SOURCE AND PRODUCTION UNCHANGED / DEPLOYMENT + BROWSER E2E PENDING OWNER APPLICATION.**

## SELF-AUDIT FINAL
- **What I proved:** The current source contains an illegal multiline single-quoted string; the parent commit introduced it; the later operation-id commit is not its origin; the parse failure explains the missing `App` global.
- **What I did not prove:** I did not run a browser against the deployed Cloudflare artifact, and I did not validate the corrected script in the owner's environment because the operational file remains owner-controlled.
- **What I fixed:** Prepared the exact surgical replacement and documented the root cause. No source or Production mutation was made.
- **What I initially missed:** The error was introduced by the prior error-handling patch, not by the latest idempotency patch.
- **What could still be wrong:** Additional syntax/runtime defects may exist elsewhere; the supplied console trace only proves this first parse blocker.
- **Final confidence:** High for this root cause; served runtime closure remains unverified.
- **Final closure status:** `PATCH READY — NOT DEPLOYED / NOT CLOSED`.
