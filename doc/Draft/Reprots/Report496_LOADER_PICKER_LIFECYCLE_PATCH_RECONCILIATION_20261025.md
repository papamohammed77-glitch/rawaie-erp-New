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
