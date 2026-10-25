# Report496 — إعادة التحقيق وتحديد رقع Loader/Picker الجراحية

**Event ID:** LVE-2026-10-25-496  
**Date:** 2026-10-25  
**Target:** `papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/loader.html`  
**Reference:** `papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/picker.html`  
**Operational scope:** Runsheet lifecycle, resumable loading draft, quantity contract, completion, cancellation, reopen, tenant isolation.  
**Status:** LIVE SOURCE + LIVE PRODUCTION SNAPSHOT RE-READ / ROOT CAUSES CONFIRMED / OWNER-ONLY HTML PATCH REQUIRED / REOPEN EDGE TENANT DEFECT CONFIRMED / NO PRODUCTION MUTATION / NOT CLOSED.

---

## 1. PRE-CHANGE SELF-AUDIT

| Dimension | Status | Evidence |
|---|---|---|
| Business understanding | CONFIRMED | Loader handles Picked → Loading → Loaded and Loaded → Loading reopen; Picker is a behavioral reference, not a copy target. |
| Architecture understanding | CONFIRMED | Loader uses shared `RW_Auth`, `RW_API`, Supabase reads and Edge endpoints; physical stock effects belong to PostgreSQL Core, not HTML. |
| Database understanding | CONFIRMED for inspected facts | Live Production SQL read at `2026-10-25 17:16:35.487218+00`, PostgreSQL 17.6; public.users has `id`, `company_id`, `auth_id`, `status`, `email`; runsheets has company/status/loader/vehicle/cycle context; loading Core is SECURITY DEFINER and EXECUTE is restricted to service_role/postgres for inspected RPCs. |
| Historical understanding | CONFIRMED for latest report lineage | Read writing-block.md §§26–29 and task-specific §§B–J, Report492–495, CURRENT_STATE.md. |
| Production understanding | CONFIRMED for fresh Edge metadata/source and SQL snapshot | Read the live Edge registry and retrieved live source for start-loading, complete-loading, cancel-loading, reopen-loading; read live RPC definition and ACL. |
| Current source understanding | CONFIRMED | Re-fetched operational Loader, Picker, Core from erp-frontend/main. |
| Execution confidence | High for static/API defects; not sufficient for runtime closure | No authenticated browser E2E, no active isolated staging E2E, no Cloudflare served-HTML fingerprint. |
| HTML mutation authority | OWNER-ONLY | writing-block.md explicitly forbids direct edits to operational loader.html and picker.html in this task. |
| Production write authority for this cycle | Not exercised | The identified reopen tenant-context fix needs coordinated source/provenance/test evidence; no untested production deployment or business operation was initiated. |

### Sources freshly read

- `doc/Draft/Reprots/writing-block.md`, including the explicit target, forbidden files, surgical replacement requirements, and output requirements.
- `CURRENT_STATE.md` and reports 492, 493, 494, 495.
- `erp-frontend/main:companies/company-1/warehouse/loader.html`
- `erp-frontend/main:companies/company-1/warehouse/picker.html`
- `erp-frontend/main:companies/company-1/core.js`
- Live Supabase Edge registry and source: `start-loading`, `complete-loading`, `cancel-loading`, `reopen-loading`.
- Live PostgreSQL schema for `public.users` and `public.runsheets`, definition and ACL for `complete_runsheet_reopen_loading`, and triggers on `runsheets`, `run_sheet_details`, `order_details`.

## 2. Fresh source identity — do not use the stale mirror as the application

| Artifact | Repository path | Current Git blob SHA | Result |
|---|---|---|---|
| Loader (operational) | `erp-frontend/companies/company-1/warehouse/loader.html` | `f478a78b9e5999cf44f7f65e06341b3036bfdcc9` | Current target; 811 lines / 50,979 characters returned. |
| Picker (operational reference) | `erp-frontend/companies/company-1/warehouse/picker.html` | `d483bd15b36585b975b63c2ef641481a01d5d084` | Reference only; 55,069 characters returned. |
| Shared Core | `erp-frontend/companies/company-1/core.js` | `ff2f581d9900543c16f7cb026e13446520c0329d` | Read-only dependency. |

The `rawaie-erp-New/Current/PWA/warehouse/loader.html` and sibling path variants were not found at the queried paths. Report495's historical mirror identifiers refer to a different path layout and must not be treated as the live operational app. The canonical source for this task is the `erp-frontend` repository above.

The latest operational Loader source already includes the vehicle selection flow and sends `{runsheet_code, vehicle_id}` to `start-loading`. This supersedes the stale premise from earlier reports that vehicle selection was absent. Do not remove or reimplement it.

## 3. Live Production snapshot (read in this session)

| Edge Function | Version | Status | verify_jwt | ezbr_sha256 |
|---|---:|---|---|---|
| start-loading | 6 | ACTIVE | true | `b0e1736ac7606c1c0b81dfdccd75cc90dbad955651961a24019b6e3c4a1988e1` |
| complete-loading | 11 | ACTIVE | true | `c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286` |
| cancel-loading | 5 | ACTIVE | true | `65fdfe2066dac1779c1e82b27a958a13d71604808af8a33ca12779ac5b7c0c89` |
| reopen-loading | 2 | ACTIVE | true | `89cac4219673154832b294d74b810c98154b7a46464a893eb8f119439e358350` |

These are live deployment package digests, not Git SHAs. No Git-to-production byte parity is claimed.

### Live Core facts

- `public.users` contains `id uuid NOT NULL`, `company_id uuid NOT NULL`, `email`, `status`, and nullable `auth_id uuid`. The application identity must be resolved through the authenticated Auth user and `public.users.auth_id`; the application FK/ownership identifier is `public.users.id`.
- `complete_runsheet_reopen_loading(uuid,text,text,text)` is `SECURITY DEFINER`. Its inspected body locks the company-scoped runsheet, checks `Loaded` and `loading_cycle_id`, calls `post_stock_movement` for Unloading, then changes the runsheet to `Loading` with a new cycle ID.
- For the inspected loading RPCs, `anon` and `authenticated` have no EXECUTE; `service_role` does. The intended trust chain is authenticated HTTP → Edge validates JWT and user/company → service_role RPC → Core → stock movement.
- Trigger `trg_sync_run_sheet_details` on `order_details` invokes `sync_run_sheet_details()`; do not introduce a direct browser write to `run_sheet_details.qty_loaded` as a workaround.
- Production was queried read-only; no runsheet, inventory, stock, or log rows were modified.

## 4. Confirmed defects and correct scope

### D1 — Loading progress is not durably saved locally

Dexie is already loaded by Loader (`dexie.min.js`), but the current Loader does not use it to persist/restore an in-progress session. `_startSession` builds only an in-memory object; `editLoadedItem` changes that object and rerenders. Reloading/closing the page can therefore lose unsubmitted quantity edits and notes.

**Required owner patch:** use a Loader-specific Dexie database/store, keyed by runsheet and guarded by `company_id + runsheet_id + loader_id + vehicle_id + loading_cycle_id + loader_start`. Persist after each edit and on pause. Restore only if all identity values match the live runsheet/user/cycle. Delete stale drafts if any identity differs. Clear a draft only after confirmed successful completion or confirmed cancellation. A local pause must not call `cancel-loading`, alter server status, reset the cycle, or move stock.

### D2 — Completion submits zero-quantity rows that Production rejects

Loader currently appends every session row to `its`, including `loadedQty: 0`. Live `complete-loading v11` explicitly rejects any submitted item whose `loaded_qty <= 0`. Thus a valid partial load can fail if even one unshipped item is included.

**Required owner patch:** keep all rows for the confirmation summary, but build the HTTP request from positive rows only. If no positive rows remain, stop before HTTP and explain that the current Core contract requires at least one positive quantity. Do not create a zero-quantity stock movement.

**Contract limitation:** the Edge normalizer accepts camelCase `itemCode/loadedQty` and snake_case `item_code/loaded_qty`; the Loader's existing camelCase payload is accepted. The defect is the zero rows, not the casing.

### D3 — UI permits quantity above picked quantity

The quantity input uses `max=qty_ordered`; its handler permits values above `qty_picked` when a note is entered. Live Core enforces the picked capacity and rejects over-picking. The note does not override that invariant.

**Required owner patch:** UI input maximum and pre-confirm validation must use `qty_picked`. Remove the branch that permits an above-picked quantity after a note. If the business later authorizes loading above picked capacity, that is a separate Core/business contract change, not a UI-only exception.

### D4 — Reopen request omits required idempotency identity

The live `reopen-loading v2` requires both `runsheet_code` and `operation_id`. Current Loader calls it with only `runsheet_code`, so the request fails the deployed contract.

**Required owner patch:** after user confirmation, generate `crypto.randomUUID()` once and send `{runsheet_code, operation_id}`. Retain/reuse the same ID for a retry of that same attempt; do not generate a fresh ID for a retry. Scope the preliminary status query to `company_id` and the current loader identity where the data model supports it.

### D5 — Reopen Edge chooses company from app_settings.limit(1)

Live `reopen-loading v2` and `cancel-loading v5` resolve company context through `app_settings.select('company_id').limit(1)` rather than mapping the authenticated Auth user to `public.users.auth_id`. This is not an acceptable tenant identity derivation for a multi-company system. The browser must not repair this by submitting a trusted `company_id`.

**Required backend repair:** align `reopen-loading` to `start-loading`/`complete-loading` identity resolution: validate Bearer token with `auth.getUser(token)`; resolve exactly one `public.users` row via `.eq('auth_id', user.id)`; require `id`, `company_id`, and active status; derive company/email from that row; call the existing Core RPC with the derived company and supplied `operation_id`. Do not accept a client-supplied company ID. Before Production deployment, preserve the exact deployed source, create the canonical Current artifact, run static checks and a safe isolated E2E, then deploy and re-read the live version/source. This report does not claim this backend repair was deployed.

### D6 — Completed list is missing explicit tenant scope

Current `renderCompletedTab` filters `status='Loaded'` and `loader_id`, but omits `company_id` and falls back to email despite the application FK using `public.users.id`.

**Required owner patch:** filter by `company_id = currentUser.company_id` and `loader_id = currentUser.id`, and surface query errors instead of rendering them as an empty list. Do not rely on email fallback.

### D7 — Pause and cancellation have different business semantics

`cancel-loading` invokes the server cancellation RPC and resets the Loading context to Picked; it is not a pause operation. Local pause must only persist a draft and return to the list. Cancellation clears local draft only after a confirmed `success:true`; timeout/ambiguous response must preserve the draft.

## 5. Responsibility matrix

| Responsibility | Current evidence | Required disposition |
|---|---|---|
| Vehicle selection before start | Present in latest operational Loader; Edge/Core enforce vehicle context | RETAINED — do not regress. |
| Company-scoped runsheet opening | Present in current `openRunsheet` query and active-loader ownership check | RETAINED; add explicit scope to completed/reopen reads. |
| Item description/image/unit relation | Present in current detail query via `items!run_sheet_details_item_id_fkey(description, image_url, name, unit)` | RETAINED — no schema change required for display. |
| Local loading draft persistence | No store/read/write in Loader despite Dexie being loaded | MISSING — add guarded local persistence. |
| Positive-only completion payload | Current request contains zero rows | MISSING — filter request rows and block all-zero completion. |
| Picked-quantity ceiling | Current UI max is ordered quantity and allows above-picked with note | CONFLICT — enforce Core's picked capacity in UI. |
| Reopen operation identity | Current payload omits `operation_id` | MISSING — send stable UUID per attempt. |
| Reopen tenant identity | Production Edge uses first app_settings company | CONFLICT — derive from authenticated public.users row. |
| Completed-list tenant scope | Current query omits company_id | MISSING — explicit company and canonical user scope. |
| Physical stock movement | Core RPC uses `post_stock_movement` | RETAINED — never write physical stock from HTML. |
| Pause | No pause/draft-resume operation | MISSING — local-only; must not call cancel endpoint. |
| Notes persistence | Live Edge normalizes only item code and loaded quantity; notes are dropped | UNVERIFIED / CONTRACT GAP — do not claim notes persist. Any decision to persist notes requires an explicit Edge+Core/data contract, not a UI claim. |

## 6. Exact owner-patch targets (operational Loader only)

The owner must re-fetch the operational file immediately before applying changes and verify SHA `f478a78b9e5999cf44f7f65e06341b3036bfdcc9`. If SHA differs, stop applying this patch package and reconcile the new source first.

**File:** `papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/loader.html`  
**Forbidden to mutate by assistant:** `loader.html`, `picker.html`, `main.html`.  
**Do not copy Picker wholesale.** Implement only the following source elements in the Loader's existing design and lifecycle.

### Patch A — Add a Loader-only Dexie store

**Anchor:** after the script line `<script src="../core.js"></script>` is not appropriate because that is HTML head; the database setup belongs inside the existing inline script before `var App = {`.

Insert this exact block immediately before `var App = {`:

```javascript
var RW_LoaderDB = null;
try {
    if (typeof Dexie !== 'undefined') {
        RW_LoaderDB = new Dexie('RW_Loader');
        RW_LoaderDB.version(1).stores({
            sessions: 'runsheet_code, company_id, loader_id, runsheet_id, loading_cycle_id'
        });
    }
} catch (loaderDbInitError) {
    console.error('Loader local draft database initialization failed:', loaderDbInitError);
}
```

Do not treat an unavailable database as a successful save. Pause must be disabled or show an explicit error when `RW_LoaderDB` is unavailable.

### Patch B — Replace _startSession to restore only a matching cycle

**Anchor:** `_startSession: function(code, rs, items) {` (currently around line 285; re-find by exact text after re-fetch).

Replace that method with a promise-aware version that:
1. constructs session identity from `rs.company_id`, `rs.id`, `rs.loader_id`, `rs.vehicle_id`, `rs.loading_cycle_id`, and `rs.loader_start`;
2. builds the same existing item model (item_code/name/unit/description/image_url/unit_price/qty_ordered/qty_picked/qty_loaded/notes);
3. loads `sessions.get(code)`;
4. restores only `qty_loaded` and `notes` when every identity field matches; otherwise deletes the stale draft;
5. renders after the Dexie read completes and saves the reconstructed session.

The existing function has a compact but semantically important item mapping. Preserve all existing fields and image data. Do not restore a draft by runsheet code alone.

### Patch C — Persist each quantity edit and constrain it to picked capacity

**Anchor:** `editLoadedItem: function(idx, pre) {` in current Loader.

Within `preConfirm`, use `max=qty_picked` and reject values above `it.qty_picked`; remove the branch that accepts above-picked quantity when a note is present. After updating `qty_loaded` and `notes`, persist the full `session` with `RW_LoaderDB.sessions.put(session)` and render only after that promise succeeds. If the write fails, show an error and keep the in-memory state visible; never display a false “saved” success. Notes remain local-only until the backend contract is changed to persist them.

### Patch D — Add local-only pause

Add `pauseLoading` and a button in `renderActiveSession` labelled `حفظ مؤقت والعودة للقائمة`. Pause must:
- save the full session to Dexie and await success;
- stop the timer;
- set only `App.session = null`;
- return to pending list;
- never call `cancel-loading` or mutate server status, `loading_cycle_id`, `qty`, `allocated_qty`, or `inventory_log`.

If the save fails, do not clear the session.

### Patch E — Build summary from all rows, send only positive rows

**Anchor:** `completeLoading: function() {` (currently around line 774).

Preserve the current summary of complete/partial/zero rows. Before the confirmation dialog, construct a separate request array from items where `qty_loaded > 0`. If the request array is empty, stop and show an actionable warning without making HTTP. Validate each submitted quantity against `qty_picked`. The Edge payload must keep the currently supported camelCase keys `itemCode` and `loadedQty`, or use snake_case consistently. On confirmed success, delete the Dexie draft and clear session. On failure or ambiguous timeout, retain the draft.

### Patch F — Clear draft only after confirmed cancel

**Anchor:** `cancelLoading: function(code) {` (currently around line 711).

After the callback returns `success:true`, delete the local draft for that runsheet and clear session/timer. If cancellation fails or its result is ambiguous, keep the draft. Do not treat a timeout as proof the server did not cancel.

### Patch G — Company-scope completed and reopen reads

**Anchor:** `renderCompletedTab: function() {` (currently around line 792).

Require `currentUser.company_id` and `currentUser.id`; query `runsheets` with both `.eq('company_id', currentUser.company_id)` and `.eq('loader_id', currentUser.id)` plus status Loaded. Check `r.error` and show an error state instead of silently rendering an empty list.

**Anchor:** `reopenLoading: function(code) {` (currently around line 795).

The status lookup must include company scope and the canonical current user identity as appropriate. After user confirmation, generate one `operation_id = crypto.randomUUID()`, call `reopen-loading` with `{runsheet_code: code, operation_id: operation_id}`, and reuse that ID for retries of the same request. On success, remove the previous-cycle draft only after the Edge returns success, then reload the active runsheet so the new `loading_cycle_id` forms a new draft identity. Do not send a client-supplied `company_id` as authority.

**Important:** UI patch alone does not fix the backend tenant-context defect in D5. Do not claim multi-company-safe reopen until the Edge identity resolution is repaired and verified.

## 7. Static/runtime test matrix

None of these tests was executed in this cycle; all are OPEN.

1. **Full-file parse:** extract every inline script from the final saved Loader and parse it; verify no syntax errors.
2. **Normal start:** Picked → preview → click start → choose active same-company vehicle → start-loading success; verify vehicle/cycle fields.
3. **Draft resume:** edit multiple quantities, pause, return to list, reopen the same active Loading runsheet; quantities and notes restore only for the matching cycle.
4. **Stale draft rejection:** alter test identity/cycle in isolated staging; stale draft must be discarded and server values used.
5. **Partial completion:** with at least one positive row and one zero row, request payload includes only positive rows; HTTP succeeds and Core uses central stock movement.
6. **All-zero completion:** UI blocks before HTTP; no RPC, stock, or log mutation.
7. **Quantity ceiling:** value above picked is blocked before HTTP; no server call.
8. **Reopen payload:** request includes a stable UUID `operation_id`; retries reuse the same ID.
9. **Tenant isolation:** two-company fixture: user A cannot list/open/reopen company B's runsheet; forged browser company IDs have no authority.
10. **Cancel semantics:** successful cancel resets server state and clears draft; failure/timeout preserves draft.
11. **Stock invariance for pause/preview:** before/after `stock_branches.qty`, `allocated_qty`, and `inventory_log` deltas all equal zero.
12. **Runtime delivery:** verify Cloudflare serves the intended commit; record HTTP/browser network, console, response, and source identity.
13. **Baseline restoration:** remove only test-created isolated fixtures; verify no leftover rows or stock delta.

## 8. Governance and execution ledger

- Re-read live Production Edge registry/source and SQL in this cycle.
- No operational HTML was changed; this is mandatory under the task's explicit owner-only rule.
- No Edge deployment or database mutation was performed; no isolated staging/runtime proof was available in the current execution evidence.
- No test harness or production fixture was created.
- No claim is made that Cloudflare serves the latest operational Git source.
- No claim is made that any E2E passed.
- `ezbr_sha256` is not equated with Git blob/commit SHA.

## 9. FINAL SELF-AUDIT

### What I Proved
- Operational Loader and Picker identities were re-fetched directly from their canonical repository.
- Latest Loader already has vehicle selection and item relation join.
- Production `complete-loading v11` rejects zero-quantity items; current UI submits them.
- Current UI allows above-picked quantities while Core rejects them.
- `reopen-loading v2` requires `operation_id`, absent from current UI request.
- Live `reopen-loading` chooses company via `app_settings.limit(1)`, rather than authenticated `public.users.auth_id`.
- Loading Core ACL is not directly executable by anon/authenticated; Edge's service-role path is the intended boundary.
- Current UI does not persist draft state, despite Dexie being loaded.
- The governance file forbids assistant edits to operational Loader/Picker/Main in this task.

### What I Did Not Prove
- Cloudflare's served HTML identity or deployment parity.
- Successful authenticated browser/HTTP E2E.
- Successful isolated Staging tests.
- That notes are persisted by the current Edge/Core contract.
- That reopen-loading is tenant-safe across multiple companies.
- That the proposed owner patches have been applied.

### What I Fixed
No operational code was modified because the task explicitly assigns the source patch to the owner. This report replaces the previous non-executable high-level patch plan with an evidence-based, exact-anchor patch package and test matrix. The Production tenant-context issue is documented as a backend defect requiring canonical source recovery, safe isolated test, and verified deployment.

### What I Initially Missed
- Dexie is already loaded; the actual defect is the lack of Loader draft persistence/use, not a missing library.
- The latest operational Loader has vehicle selection and item joins, so older reports asserting those features are absent were stale.
- The Current mirror path is not the canonical operational source.

### What Could Still Be Wrong
- Cloudflare may serve an artifact older than current Git.
- Edge source or operational HTML may change after this read.
- The retry semantics of Core may not return a duplicate result after a completed state transition.
- The loading notes contract is unresolved and must not be represented as persisted.

**Final confidence:** High for static/API contract findings; medium for full lifecycle interpretation; low for runtime closure because browser/staging E2E was not run.  
**Final closure status:** `OPEN — OWNER HTML PATCH + REOPEN EDGE TENANT REPAIR + ISOLATED E2E + SERVED-ARTIFACT VERIFICATION REQUIRED`. No `100% CLOSED` claim.


---

## 10. READY-TO-PASTE OWNER PATCHES — COMPLETE REPLACEMENT TEXT

**This appendix makes the patch operationally precise.** Re-fetch the target before applying and stop if its blob SHA is not `f478a78b9e5999cf44f7f65e06341b3036bfdcc9`. The owner-only restriction remains in force: these blocks are instructions for the owner to apply, not changes made by this assistant.

### A. Add the local draft store

Insert immediately before `var App = {` inside Loader's inline script:

```javascript
var RW_LoaderDB = null;
try {
    if (typeof Dexie !== 'undefined') {
        RW_LoaderDB = new Dexie('RW_Loader');
        RW_LoaderDB.version(1).stores({
            sessions: 'runsheet_code, company_id, loader_id, runsheet_id, loading_cycle_id'
        });
    }
} catch (loaderDbInitError) {
    console.error('Loader local draft database initialization failed:', loaderDbInitError);
}
```

### B. Replace `_startSession` in full

Replace the exact method beginning `_startSession: function(code, rs, items) {` and ending at its matching method-closing `},`:

```javascript
_startSession: function(code, rs, items) {
    var self = this;
    var session = {
        runsheet_code: code,
        company_id: rs.company_id,
        loader_id: rs.loader_id,
        runsheet_id: rs.id,
        vehicle_id: rs.vehicle_id || null,
        loading_cycle_id: rs.loading_cycle_id || null,
        loader_start: rs.loader_start || null,
        start_time: rs.loader_start || new Date().toISOString(),
        items: []
    };

    for (var i = 0; i < items.length; i++) {
        var it = items[i];
        var product = it.items || {};
        if (Array.isArray(product)) product = product[0] || {};

        session.items.push({
            item_code: it.item_code,
            item_name: it.item_name || product.name || '',
            unit: it.unit || product.unit || 'حبة',
            description: product.description || '',
            image_url: product.image_url || '',
            unit_price: Number(it.unit_price) || 0,
            qty_ordered: Number(it.qty_ordered) || 0,
            qty_picked: Number(it.qty_picked) || 0,
            qty_loaded: Number(it.qty_loaded) || 0,
            notes: it.notes || ''
        });
    }

    function sameIdentity(saved) {
        return !!saved &&
            saved.runsheet_code === session.runsheet_code &&
            saved.company_id === session.company_id &&
            saved.loader_id === session.loader_id &&
            saved.runsheet_id === session.runsheet_id &&
            String(saved.vehicle_id || '') === String(session.vehicle_id || '') &&
            String(saved.loading_cycle_id || '') === String(session.loading_cycle_id || '') &&
            String(saved.loader_start || '') === String(session.loader_start || '');
    }

    if (!RW_LoaderDB) {
        self.session = session;
        RW_UI.toast('الحفظ المؤقت غير متاح على هذا الجهاز؛ ستظل التعديلات في الذاكرة الحالية فقط', 'warning');
        self.renderActiveSession();
        return;
    }

    RW_LoaderDB.sessions.get(code).then(function(saved) {
        if (sameIdentity(saved)) {
            var byCode = {};
            for (var i = 0; i < saved.items.length; i++) {
                byCode[String(saved.items[i].item_code)] = saved.items[i];
            }
            for (var j = 0; j < session.items.length; j++) {
                var current = session.items[j];
                var previous = byCode[String(current.item_code)];
                if (previous) {
                    current.qty_loaded = Number(previous.qty_loaded) || 0;
                    current.notes = previous.notes || '';
                }
            }
        } else if (saved) {
            return RW_LoaderDB.sessions.delete(code).then(function() {
                return null;
            });
        }
        return null;
    }).then(function() {
        self.session = session;
        return RW_LoaderDB.sessions.put(session);
    }).then(function() {
        self.renderActiveSession();
    }).catch(function(err) {
        console.error('Loader draft restore/save failed:', err);
        self.session = session;
        RW_UI.toast('تعذر استعادة الحفظ المؤقت. تم عرض بيانات الخادم دون ادعاء حفظ التعديلات المحلية.', 'error');
        self.renderActiveSession();
    });
},
```

### C. Replace `editLoadedItem` in full

This replacement enforces the Production/Core picked-quantity ceiling and waits for local persistence before reporting a successful save. Notes are local-only until a supported backend field is implemented.

```javascript
editLoadedItem: function(idx, pre) {
    var s = this;
    if (!s.session || !s.session.items[idx]) return;
    var it = s.session.items[idx];
    var cur = (typeof pre !== 'undefined') ? pre : it.qty_loaded;

    Swal.fire({
        title: '<span class="text-slate-800">' + it.item_name + '</span>',
        html: '<div class="text-center mb-3">' +
            s._loaderImageHTML(it, 'w-full max-w-xs', 'h-72', 'object-contain') +
            '</div><div class="text-right text-sm space-y-2">' +
            '<div class="flex justify-between"><span class="text-slate-400">محضّر</span><strong>' + it.qty_picked + '</strong></div>' +
            '<div class="flex justify-between"><span class="text-slate-400">مطلوب</span><strong>' + it.qty_ordered + '</strong></div>' +
            (it.unit ? '<div class="flex justify-between"><span class="text-slate-400">الوحدة</span><strong>' + it.unit + '</strong></div>' : '') +
            '</div><div class="mt-4 text-right">' +
            '<label class="block text-xs font-bold text-slate-500 mb-2">الكمية المحمّلة</label>' +
            '<input id="swal-qty" type="number" class="swal2-input !rounded-xl !text-center !font-bold !text-lg" value="' + cur + '" min="0" max="' + it.qty_picked + '">' +
            '<label class="block text-xs font-bold text-slate-500 mb-2 mt-4">ملاحظات محلية</label>' +
            '<input id="swal-notes" class="swal2-input !rounded-xl" value="' + (it.notes || '') + '" placeholder="سبب النقص (يحفظ محليًا فقط)"> </div>',
        showCancelButton: true,
        confirmButtonText: 'حفظ',
        cancelButtonText: 'إلغاء',
        customClass: {
            popup: '!rounded-3xl',
            confirmButton: '!rounded-xl !bg-orange-600 !px-8',
            cancelButton: '!rounded-xl'
        },
        didOpen: function() {
            s._bindLoaderImageFallbacks(Swal.getPopup());
        },
        preConfirm: function() {
            var p = Swal.getPopup();
            var qe = p ? p.querySelector('#swal-qty') : null;
            var ne = p ? p.querySelector('#swal-notes') : null;
            var value = qe ? Number(qe.value) : NaN;
            if (!Number.isFinite(value) || value < 0 || value > Number(it.qty_picked)) {
                Swal.showValidationMessage('الكمية يجب أن تكون بين صفر والكمية المحضّرة.');
                return false;
            }
            return { qty: Math.floor(value), notes: ne ? ne.value.trim() : '' };
        }
    }).then(function(r) {
        if (!r.isConfirmed) return;
        var oldQty = it.qty_loaded;
        var oldNotes = it.notes;
        s.session.items[idx].qty_loaded = r.value.qty;
        s.session.items[idx].notes = r.value.notes;

        if (!RW_LoaderDB) {
            s.renderActiveSession();
            RW_UI.toast('تم التعديل في الجلسة الحالية فقط؛ الحفظ الدائم المحلي غير متاح', 'warning');
            return;
        }

        RW_LoaderDB.sessions.put(s.session).then(function() {
            s.renderActiveSession();
            if (r.value.qty < it.qty_picked && !r.value.notes) {
                Swal.fire({
                    title: 'تنبيه',
                    text: 'الكمية المحمّلة أقل من المحضّرة. هل تريد إضافة سبب؟',
                    icon: 'question',
                    showCancelButton: true,
                    confirmButtonText: 'إضافة سبب',
                    cancelButtonText: 'تخطي',
                    customClass: {
                        popup: '!rounded-3xl',
                        confirmButton: '!rounded-xl !bg-amber-500 !px-6',
                        cancelButton: '!rounded-xl'
                    }
                }).then(function(r2) {
                    if (r2.isConfirmed) s.editLoadedItem(idx, r.value.qty);
                });
            }
        }).catch(function(err) {
            s.session.items[idx].qty_loaded = oldQty;
            s.session.items[idx].notes = oldNotes;
            console.error('Loader draft write failed:', err);
            s.renderActiveSession();
            RW_UI.showError('تعذر حفظ التعديل محليًا؛ أُعيدت القيمة السابقة.');
        });
    });
},
```

### D. Add local-only `pauseLoading`

Insert as a new App method adjacent to `cancelLoading`:

```javascript
pauseLoading: function() {
    var s = this;
    if (!s.session) return;
    if (!RW_LoaderDB) {
        RW_UI.showError('الحفظ المؤقت غير متاح؛ لن يتم إنهاء الجلسة أو مسح بياناتها.');
        return;
    }
    RW_LoaderDB.sessions.put(s.session).then(function() {
        if (s.timerInterval) clearInterval(s.timerInterval);
        s.timerInterval = null;
        s.session = null;
        RW_UI.toast('تم حفظ التحميل مؤقتًا على هذا الجهاز', 'success');
        s.renderPendingTab();
    }).catch(function(err) {
        console.error('Loader pause draft write failed:', err);
        RW_UI.showError('تعذر حفظ الجلسة؛ بقيت الجلسة مفتوحة ولم يتم تغيير حالة الرانشيت.');
    });
},
```

In `renderActiveSession`, insert this button immediately before the existing cancel button:

```javascript
h += '<button onclick="App.pauseLoading()" class="w-full mt-3 bg-amber-50 border border-amber-200 text-amber-700 py-3 rounded-2xl font-bold"><i class="fa-solid fa-pause ml-2"></i> حفظ مؤقت والعودة للقائمة</button>';
```

### E. Replace `completeLoading` in full

The summary still counts all rows; only positive quantities are sent to the deployed Edge contract. The notes field is not represented as persisted.

```javascript
completeLoading: function() {
    var s = this;
    if (!s.session) return;
    if (!navigator.onLine) {
        RW_UI.toast('غير متصل', 'warning');
        return;
    }

    var requestItems = [];
    var fullCount = 0, partialCount = 0, zeroCount = 0;
    var allItems = s.session.items;

    for (var i = 0; i < allItems.length; i++) {
        var it = allItems[i];
        if (it.qty_loaded < 0 || it.qty_loaded > it.qty_picked) {
            RW_UI.showError('الكمية المحمّلة يجب ألا تتجاوز الكمية المحضّرة.');
            return;
        }
        if (it.qty_loaded > 0) {
            requestItems.push({ itemCode: it.item_code, loadedQty: it.qty_loaded });
        }
        if (it.qty_loaded >= it.qty_ordered) fullCount++;
        else if (it.qty_loaded > 0) partialCount++;
        else zeroCount++;
    }

    if (!requestItems.length) {
        RW_UI.showError('لا يمكن إنهاء التحميل دون كمية موجبة واحدة على الأقل. لم يتم إرسال أي طلب.');
        return;
    }

    var summary = '<div class="text-right text-sm"><p>أنت على وشك إنهاء تحميل الرانشيت <strong>' +
        s.session.runsheet_code + '</strong>.</p><div class="mt-3 space-y-1">' +
        '<div>✅ <strong>' + fullCount + '</strong> أصناف مكتملة</div>' +
        '<div>⚠️ <strong>' + partialCount + '</strong> أصناف محمّلة جزئيًا</div>' +
        '<div>❌ <strong>' + zeroCount + '</strong> أصناف لم تُحمّل</div></div>' +
        '<p class="text-xs text-amber-700 mt-3">ملاحظات النقص محلية ولا تُرسل إلى عقد التحميل الحالي.</p></div>';

    Swal.fire({
        title: 'تأكيد إنهاء التحميل',
        html: summary,
        icon: 'info',
        showCancelButton: true,
        confirmButtonText: 'تأكيد',
        cancelButtonText: 'إلغاء',
        customClass: {
            popup: '!rounded-3xl',
            confirmButton: '!rounded-xl !bg-orange-600 !px-8',
            cancelButton: '!rounded-xl'
        }
    }).then(function(r) {
        if (!r.isConfirmed) return;
        var cb = document.querySelector('.swal2-confirm');
        if (cb) {
            cb.disabled = true;
            cb.innerText = 'جارٍ...';
        }
        RW_UI.showLoader();
        RW_API.call('complete-loading', {
            runsheet_code: s.session.runsheet_code,
            items: requestItems
        }, function(json) {
            RW_UI.hideLoader();
            if (json && json.success) {
                var tq = 0, tv = 0;
                for (var j = 0; j < requestItems.length; j++) {
                    tq += requestItems[j].loadedQty;
                    for (var k = 0; k < allItems.length; k++) {
                        if (allItems[k].item_code === requestItems[j].itemCode) {
                            tv += requestItems[j].loadedQty * (Number(allItems[k].unit_price) || 0);
                            break;
                        }
                    }
                }
                var code = s.session.runsheet_code;
                function finishUi() {
                    Swal.fire({
                        icon: 'success',
                        title: 'تم إنهاء التحميل',
                        html: '<div class="text-right"><p>تم تحميل <strong>' + requestItems.length +
                            ' صنف</strong></p><p>إجمالي الكمية: <strong>' + tq +
                            '</strong></p><p>القيمة التقديرية: <strong>' +
                            RW_UI.formatNumber(tv) + ' EGP</strong></p></div>',
                        confirmButtonText: 'حسنًا',
                        customClass: { popup: '!rounded-3xl', confirmButton: '!rounded-xl !bg-orange-600' }
                    });
                    s.session = null;
                    if (s.timerInterval) clearInterval(s.timerInterval);
                    s.timerInterval = null;
                    s.renderPendingTab();
                }
                if (RW_LoaderDB) {
                    RW_LoaderDB.sessions.delete(code).then(finishUi).catch(function(err) {
                        console.error('Loader completed draft cleanup failed:', err);
                        finishUi();
                        RW_UI.toast('اكتمل التحميل، لكن تعذر حذف المسودة المحلية القديمة', 'warning');
                    });
                } else {
                    finishUi();
                }
            } else {
                RW_UI.showError((json && json.msg) || 'فشل إنهاء التحميل. احتُفظ بالمسودة المحلية.');
            }
        });
    });
},
```

### F. Replace `cancelLoading` in full

```javascript
cancelLoading: function(code) {
    var s = this;
    RW_UI.showConfirm('إلغاء تحميل ' + code + '؟ ستعود حالة الرانشيت إلى جاهز للتحضير.', function() {
        RW_UI.showLoader();
        RW_API.call('cancel-loading', { runsheet_code: code }, function(json) {
            RW_UI.hideLoader();
            if (json && json.success) {
                function resetUi() {
                    RW_UI.toast('تم الإلغاء', 'success');
                    s.session = null;
                    if (s.timerInterval) clearInterval(s.timerInterval);
                    s.timerInterval = null;
                    s.renderPendingTab();
                }
                if (RW_LoaderDB) {
                    RW_LoaderDB.sessions.delete(code).then(resetUi).catch(function(err) {
                        console.error('Loader cancelled draft cleanup failed:', err);
                        resetUi();
                        RW_UI.toast('أُلغيت العملية، لكن تعذر حذف المسودة المحلية القديمة', 'warning');
                    });
                } else {
                    resetUi();
                }
            } else {
                RW_UI.showError((json && json.msg) || 'تعذر تأكيد الإلغاء؛ احتُفظ بالمسودة المحلية.');
            }
        });
    });
},
```

### G. Replace `renderCompletedTab` in full

```javascript
renderCompletedTab: function() {
    var s = this;
    var u = s.currentUser;
    if (!u || !u.company_id || !u.id) {
        RW_UI.showError('تعذر تحديد الشركة أو المستخدم الحالي.');
        return;
    }
    RW_UI.showSkeleton('mainContent', 1, 'card');
    supabase.from('runsheets')
        .select('runsheet_code,run_date,status')
        .eq('company_id', u.company_id)
        .eq('status', 'Loaded')
        .eq('loader_id', u.id)
        .order('run_date', { ascending: false })
        .limit(50)
        .then(function(r) {
            if (r.error) {
                console.error('Loader completed runsheets query failed:', r.error);
                RW_UI.showError('تعذر تحميل الرانشيتات المكتملة.');
                return;
            }
            s.completedRunsheets = r.data || [];
            s.renderCompletedList(s.completedRunsheets);
        }).catch(function(err) {
            console.error('Loader completed runsheets request failed:', err);
            RW_UI.showError('تعذر تحميل الرانشيتات المكتملة.');
        });
},
```

### H. Replace `reopenLoading` in full — UI payload correction only

This corrects the required payload and company-scopes the read. It does **not** solve the backend tenant-identity defect by itself.

```javascript
reopenLoading: function(code) {
    var s = this;
    var u = s.currentUser;
    if (!u || !u.company_id || !u.id || !code) {
        RW_UI.showError('تعذر تحديد الشركة أو المستخدم أو الرانشيت.');
        return;
    }

    supabase.from('runsheets')
        .select('status,runsheet_code,company_id,loader_id')
        .eq('company_id', u.company_id)
        .eq('runsheet_code', code)
        .eq('loader_id', u.id)
        .maybeSingle()
        .then(function(r) {
            if (r.error || !r.data || r.data.status !== 'Loaded') {
                if (r.error) console.error('Loader reopen precheck failed:', r.error);
                Swal.fire({
                    title: 'لا يمكن إعادة الفتح',
                    text: 'تعذر التحقق من أن الرانشيت مكتمل ويتبع حسابك الحالي.',
                    icon: 'warning',
                    customClass: { popup: '!rounded-3xl' }
                });
                s.renderCompletedTab();
                return;
            }

            RW_UI.showConfirm('إعادة فتح ' + code + '؟ سيتم عكس حركة التحميل وفق Core.', function() {
                var storageKey = 'rw-loader-reopen:' + u.company_id + ':' + code;
                var operationId = '';
                try {
                    operationId = localStorage.getItem(storageKey) || '';
                    if (!operationId) {
                        operationId = crypto.randomUUID();
                        localStorage.setItem(storageKey, operationId);
                    }
                } catch (storageError) {
                    RW_UI.showError('تعذر حفظ معرف العملية لإعادة المحاولة بأمان؛ لم يتم إرسال الطلب.');
                    return;
                }

                RW_UI.showLoader();
                RW_API.call('reopen-loading', {
                    runsheet_code: code,
                    operation_id: operationId
                }, function(j) {
                    RW_UI.hideLoader();
                    if (j && j.success) {
                        try { localStorage.removeItem(storageKey); } catch (_) {}
                        if (RW_LoaderDB) {
                            RW_LoaderDB.sessions.delete(code).catch(function(err) {
                                console.error('Old Loader cycle draft cleanup failed:', err);
                            });
                        }
                        RW_UI.toast('تمت إعادة فتح التحميل', 'success');
                        s.renderPendingTab();
                    } else {
                        RW_UI.showError((j && j.msg) || 'فشلت إعادة الفتح؛ أُبقي معرف العملية لاستخدامه في إعادة المحاولة.');
                    }
                });
            });
        }).catch(function(err) {
            console.error('Loader reopen precheck request failed:', err);
            RW_UI.showError('تعذر التحقق من حالة الرانشيت.');
        });
},
```

### I. Exact existing payload issue

The current completion loop is the line starting:

`for(var i=0;i<s.session.items.length;i++) { var it=s.session.items[i]; its.push({itemCode:it.item_code,loadedQty:it.qty_loaded,notes:it.notes}); ... }`

Do not make a partial edit that leaves the request array coupled to the summary. Replace the whole `completeLoading` method with Patch E above.

### J. Backend reopen-loading tenant-context repair

Production source proves the live defect; however, the canonical Current artifact for `reopen-loading` was not found in the queried Current paths. Do not deploy an ad hoc production-only edit. First recover the exact deployed source into the official Current location, preserving its present RPC/payload contract; then replace the `app_settings.limit(1)` identity derivation with the same authenticated-user mapping pattern used by live `start-loading v6` and `complete-loading v11`:

- validate the Bearer token with `supabase.auth.getUser(token)`;
- fetch `public.users` using `.eq('auth_id', user.id).maybeSingle()`;
- require the row's `id`, `company_id`, and active status;
- derive `p_company_id` and `p_user_email` from that row, never from the browser;
- preserve the required `runsheet_code + operation_id` contract;
- verify the current function's authorization/ownership semantics against Core before deployment.

The live `cancel-loading v5` has the same `app_settings.limit(1)` tenant-context pattern. It is a sibling defect, but do not silently expand the current Loader patch to rewrite it without the same source recovery and test discipline. Track it as an immediate related security follow-up in the current-state record.

**Do not claim 100% closure until the owner has applied these HTML changes, the reopen Edge source has been recovered and repaired, and isolated authenticated E2E plus served-artifact verification pass.**
