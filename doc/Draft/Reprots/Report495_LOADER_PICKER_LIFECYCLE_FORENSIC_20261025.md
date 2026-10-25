# Report495 — تحقيق تكامل Loader/Picker ودورة حياة الرانشيت من البداية إلى الإغلاق

**Event ID:** LVE-2026-10-25-495  
**Date:** 2026-10-25  
**Scope:** Loader.html ↔ Picker.html ↔ start-loading / complete-loading / cancel-loading / reopen-loading ↔ PostgreSQL Core  
**Status:** SOURCE + LIVE CORE RECONCILED / SURGICAL OWNER PATCH SPECIFIED / PRODUCTION UI E2E OPEN

## 1. PRE-CHANGE SELF-AUDIT

| Dimension | Assessment | Evidence / limitation |
|---|---|---|
| Business understanding | CONFIRMED for loading lifecycle | Loader previews a Picked runsheet, assigns a vehicle, enters Loading, captures loaded quantities, completes stock movement, and exposes completed loads for reopening. |
| Architecture understanding | CONFIRMED | Operational HTML calls shared RW_API contracts; Edge Functions authenticate and call privileged PostgreSQL RPCs. |
| Database understanding | CONFIRMED for inspected contracts | Direct Production SQL inspected loading RPCs, table columns, relevant triggers, and sync_run_sheet_details(). |
| Historical understanding | CONFIRMED for latest related lineage | Reviewed CURRENT_STATE.md, Reports 492–494, and recent Git commits for operational Loader. |
| Production understanding | CONFIRMED for Edge/Core snapshots only | Direct live Edge listing and source retrieval in this session; no authenticated HTTP E2E or served-HTML runtime proof. |
| Current understanding | CONFLICT / DRIFT | rawaie-erp-New/Current/PWA/loader.html is a stale 30,897-byte, 266-line mirror. Operational Loader is in erp-frontend/companies/company-1/warehouse/loader.html, currently 50,979 bytes. These are not interchangeable artifacts. |
| Execution confidence | High for static diagnosis; insufficient for runtime closure | No operational file, Edge Function, or database row was mutated in this task. The governance prompt expressly prohibits direct assistant edits to operational Loader and assigns that source change to the owner. |

### Sources inspected in this cycle

- doc/Draft/Reprots/writing-block.md — governance and scope rules.
- CURRENT_STATE.md — latest checkpoint and subsequent events.
- Report492_LOADER_PICKER_PATCH_RECONCILIATION_20261025.md.
- Report493_LOADING_CONTEXT_VEHICLE_ASSIGNMENT_FORENSIC_20261025.md.
- Report494_LOADER_VEHICLE_SELECTION_FIX_20261025.md.
- Operational erp-frontend/companies/company-1/warehouse/loader.html.
- Operational erp-frontend/companies/company-1/warehouse/picker.html.
- rawaie-erp-New/Current/PWA/loader.html and Current/PWA/picker.html for mirror comparison.
- Production Edge source for start-loading, complete-loading, cancel-loading, reopen-loading.
- Production SQL definitions for start_runsheet_loading, start_runsheet_loading_with_vehicle, complete_runsheet_loading, cancel_runsheet_loading, complete_runsheet_reopen_loading, and sync_run_sheet_details().
- Production table columns and triggers for runsheets, run_sheet_details, order_details, orders, and vehicles.

## 2. Current source and history reconciliation

### Operational source

Repository: papamohammed77-glitch/erp-frontend, branch main.

| Artifact | Current evidence |
|---|---|
| companies/company-1/warehouse/loader.html | Git blob SHA f478a78b9e5999cf44f7f65e06341b3036bfdcc9; 50,979 bytes. |
| companies/company-1/warehouse/picker.html | Git blob SHA d483bd15b36585b975b63c2ef641481a01d5d084; 55,069 bytes. |
| Latest Loader commit | 684a9fa4b157d542c4ac957cfd96edba6fbeec04, 2026-10-25 16:35:14Z, message: Add vehicle loading functionality in loader.html. Parent: 560b6fdd5aa92b023a6779ceb6b314eeba1fb0ab. |
| Previous Loader commit | 560b6fdd5aa92b023a6779ceb6b314eeba1fb0ab, message: Refactor loader HTML for improved item detail handling. |
| Operational Core | companies/company-1/core.js, blob SHA ff2f581d9900543c16f7cb026e13446520c0329d (latest recorded reconciliation; not modified here). |

The current operational Loader already contains the vehicle-selection UI and sends vehicle_id to start-loading. Therefore, Report494's older premise that the current operational Git source lacks vehicle selection is stale. The new commit is real source evidence; it does not prove Cloudflare serves that exact HTML.

### Historical/current mirror conflict

- rawaie-erp-New/Current/PWA/loader.html: blob 7b02f39643bcd45650595c8f5d72787eddcc5703, 30,897 bytes, 266 lines.
- rawaie-erp-New/Current/PWA/picker.html: blob 50934f6f6d4e24c81acc01ed6ddf226b0ee07411, 54,933 bytes.
- Historical Original/PWA/warehouse/loader.html: blob 7e61b04d0d9a480d43763e8b7b21f9cbed78409a.
- Historical Original/PWA/warehouse/picker.html: blob 7626ba320021a607854bf219f4bacd81fc3d1d92.

Current/PWA/loader.html is not the same artifact as operational Loader and does not contain the latest vehicle-selection and item-detail work. Do not overwrite the operational application with this mirror or treat its SHA as operational provenance. Reconcile the canonical mirror only through the approved source-reconciliation process.

## 3. Fresh Production Edge snapshot

Read directly from Supabase project fiilmooggumokxanwiyx during this session:

| Function | Version | Status | verify_jwt | ezbr_sha256 |
|---|---:|---|---|---|
| start-loading | 6 | ACTIVE | true | b0e1736ac7606c1c0b81dfdccd75cc90dbad955651961a24019b6e3c4a1988e1 |
| complete-loading | 11 | ACTIVE | true | c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286 |
| cancel-loading | 5 | ACTIVE | true | 65fdfe2066dac1779c1e82b27a958a13d71604808af8a33ca12779ac5b7c0c89 |
| reopen-loading | 2 | ACTIVE | true | 89cac4219673154832b294d74b810c98154b7a46464a893eb8f119439e358350 |

ezbr_sha256 is a deployment package digest, not a Git blob or commit SHA. No claim of Git-to-deployment byte parity is made.

## 4. Lifecycle comparison: Picker is a behavioral reference, not a file to copy wholesale

| Lifecycle step | Picker behavior | Operational Loader behavior | Finding |
|---|---|---|---|
| Authentication and role | Shared Auth / company context and active warehouse role validation | Shared Auth / company context and active loading role validation | Preserve separate role contracts. |
| Pending list | Company-scoped runsheets; distinguishes active from open work | Company-scoped Loading owned by current users.id plus Picked work | Broadly aligned; Completed still needs explicit company scope. |
| Search | Company-scoped search with error handling | Company-scoped search with error handling | Preserve. |
| Open runsheet | Company scope, ownership/state validation, detail rows and item relation | Company scope, Loading ownership by currentUser.id, joins items for description/image/name/unit | Aligned after recent Loader refactor. |
| Start | Authenticated HTTP start-picking | Preview → vehicle selection → start-loading with runsheet_code and vehicle_id | Vehicle selection now exists in operational Git. Keep it; do not weaken backend validation. |
| Edit quantities | IndexedDB draft persisted and restored for matching runsheet/session identity | qty_loaded and notes remain in memory only | Confirmed defect: missing draft persistence/resume. |
| Temporary pause and return | Reopening active runsheet restores matching local draft | No explicit pause action or equivalent draft restore | Add local draft pause/resume without changing server status or stock. |
| Complete | Sends operation_id / Idempotency-Key to its Edge contract | Sends every row including zero quantities; live Edge rejects any row with loaded_qty <= 0 | Confirmed contract mismatch: send only positive loaded quantities; block all-zero completion. |
| Quantity ceiling | Prevents quantity exceeding picked quantity | Input maximum uses qty_ordered and allows higher-than-picked after a note | Confirmed contract mismatch: Core rejects total loaded above picked capacity. |
| Reopen completed operation | Sends the expected reopen payload | Sends only runsheet_code | Confirmed API contract defect: live reopen-loading requires operation_id. |
| Cancel | Dedicated endpoint; clears local session | Calls cancel-loading; draft cleanup must be added if persistence is implemented | Cancel resets server state; pause must not. |
| Completion list | Company and canonical user scope | Omits company_id and allows id-or-email fallback | Add company scope and use canonical public.users.id. |

## 5. Root-cause findings confirmed from live contracts

### F1 — No durable in-progress Loader draft

editLoadedItem() updates only App.session.items; it does not persist to IndexedDB. openRunsheet() re-reads server rows, so unsent local quantities can disappear after reload or closing the tab. Picker's local-draft restore pattern is the correct reference, adapted to Loader loading_cycle_id and vehicle context.

Required behavior: persist a draft keyed by runsheet_code, carrying company_id, loader_id, runsheet_id, loading_cycle_id, loader_start, vehicle_id, and item quantities/notes. Restore only when all identity fields match the current Production runsheet and authenticated user. If cycle or owner changed, discard the stale draft and rebuild from server rows. Persist after every edit and before pausing. Clear only after successful completion or confirmed server cancellation.

### F2 — Complete-loading payload includes zero rows

The deployed complete-loading Edge source maps each submitted item and throws “بيانات التحميل غير صالحة” if any item's loaded_qty <= 0. The current UI builds its from every session item, including zero-loaded rows. Therefore a partial load with one unshipped item can be rejected even when other items have positive quantities.

Required behavior: build the summary from all items, but send only rows where qty_loaded > 0. If no positive rows remain, do not call Edge: explain that at least one positive loaded quantity is required under the current Core contract. Do not silently convert zero into a stock movement.

### F3 — UI quantity ceiling conflicts with Core

Production complete_runsheet_loading aggregates requested quantities by item_code, computes picked capacity from company-scoped order_details.qty_picked, and rejects requested quantity above picked capacity. Loader UI currently uses max=qty_ordered and permits a higher-than-picked quantity when a note is entered. That note does not override the Core invariant.

Required behavior: set input maximum and validation to qty_picked. If the business needs loading above picked quantity, that is a separate business/Core change and must not be simulated in the UI.

### F4 — Reopen Loading sends the wrong payload

Production reopen-loading requires runsheet_code and operation_id; it calls complete_runsheet_reopen_loading(p_company_id,p_runsheet_code,p_user_email,p_operation_id). Current operational Loader.reopenLoading() sends only runsheet_code. The button therefore does not satisfy the live endpoint contract.

Required behavior: generate a UUID once per user-confirmed reopen attempt; pass it as operation_id; reuse the same value if retrying that request. Add a company-scoped status read before confirmation. The Edge currently derives company context from app_settings.limit(1) rather than resolving the authenticated user's public.users record; this is an independently confirmed tenant-context risk that must be reconciled before claiming multi-company-safe reopen behavior.

### F5 — Completed-list scope is incomplete

renderCompletedTab() filters status=Loaded and loader_id, but omits company_id and uses currentUser.id || currentUser.email. Production runsheets.loader_id references public.users.id. Use canonical application user ID and explicit company scope.

### F6 — Pause must not mean cancel

cancel-loading calls cancel_runsheet_loading, which resets qty_loaded, clears loader/start/end/cycle identifiers, and changes status back to Picked. It is not a pause mechanism. The proposed pause action must only persist a local draft and return to the list; it must not call cancel-loading, clear loading_cycle_id, or alter stock.

## 6. Production Core, triggers, and security

### Central loading contract

complete_runsheet_loading(uuid,uuid,jsonb,text) is SECURITY DEFINER and enforces:

- runsheet belongs to the supplied company;
- status is Loading;
- vehicle_id, loader_start, and loading_cycle_id exist;
- submitted item quantities do not exceed picked capacity;
- physical movement is sent through post_stock_movement;
- an erp_operation_registry key is built from TASK-028|Loading|<loading_cycle_id>;
- a completed matching operation can return its stored result only when the canonical request payload matches.

The Edge authenticates JWT, resolves public.users via auth_id, derives company from that user, and calls Core. Keep this boundary; do not move physical stock writes into Loader HTML.

### Derived run_sheet_details data

Production has trg_sync_run_sheet_details on order_details INSERT/UPDATE/DELETE. The inspected sync_run_sheet_details() trigger recomputes run_sheet_details.qty_loaded from authoritative order_details.qty_loaded. Therefore the normal Core update path is designed to keep runsheet display/reopen quantities synchronized; no direct client write to run_sheet_details is warranted.

### Reopen tenant context

The live reopen-loading Edge source reads app_settings.company_id with limit(1) and passes it to RPC. Unlike start-loading and complete-loading, it does not resolve company through public.users.auth_id. Do not label this multi-tenant safe until the Edge identity path is aligned and verified. This is a dependency defect, not something the UI can securely repair by sending company_id from the browser.

## 7. Surgical owner patch plan — exact order

The governance source doc/Draft/Reprots/writing-block.md explicitly prohibits the assistant from directly editing operational erp-frontend/.../loader.html and assigns that application-source mutation to the owner. Therefore this cycle did not mutate operational HTML, Edge Functions, database, or Production data. Apply the following to latest operational Loader SHA f478a78b9e5999cf44f7f65e06341b3036bfdcc9; re-fetch first if SHA changes.

1. Add IndexedDB draft store near application initialization: Dexie database RW_Loader with a session store keyed by runsheet_code.
2. Extend _startSession(code, rs, items) to include company_id, loader_id, vehicle_id, loading_cycle_id, and loader_start in session. Read the saved draft; restore qty_loaded and notes only if company, runsheet, loader, cycle, and start timestamp all match. Otherwise delete stale draft. Save fresh/merged session and render after the IndexedDB promise settles.
3. Persist each edit in editLoadedItem() with the IndexedDB session store; surface persistence failure instead of pretending the draft was saved.
4. Add pauseLoading() and a clearly labeled “حفظ مؤقت والعودة للقائمة” button in renderActiveSession(). It saves the draft, stops the timer, clears only the in-memory session, and renders pending runsheets. It must not call a server endpoint or mutate runsheet status.
5. Fix completion payload: keep all rows for UI summary, but create request items only from rows with qty_loaded > 0; block the request if none remain; validate 0 <= qty_loaded <= qty_picked. Keep notes in the UI but do not claim the current Edge/Core contract persists them unless a supported field is proven.
6. Clear draft only after confirmed outcomes: after complete-loading returns success:true, delete that runsheet draft and clear session; after cancel-loading returns success:true, delete draft and clear session. Do not clear on timeout or unsuccessful response because the server outcome may be ambiguous.
7. Fix completed list: add company_id filter and canonical loader_id filter; check/report query errors rather than silently treating them as an empty list.
8. Fix reopenLoading(code): company-scope the status query; generate operation_id with crypto.randomUUID() only after confirmation; send runsheet_code and operation_id to reopen-loading; do not send client-supplied company_id. Clear old draft only after server confirms reopen, then reload active runsheet to construct a fresh draft for the new loading cycle.
9. Reconcile reopen-loading Edge identity: derive company from authenticated public.users row using auth_id, validate active status and company context, then call existing Core RPC. Do not rely on app_settings.limit(1) for tenant identity. This backend dependency must be tested before claiming multi-company safety.
10. Do not modify start-loading, vehicle-selection validation, complete_runsheet_loading, or central stock movement just to implement local pause/resume. Preserve the existing backend contract unless a new reproducible defect is proven.

## 8. E2E test matrix required after owner patch and deployment

No test below is marked PASS because the patch has not been applied to operational HTML and no authenticated browser/HTTP run was performed in this cycle.

| Test | Expected evidence |
|---|---|
| Normal start | Picked runsheet → choose same-company active mobile-stock vehicle → start-loading success → status Loading and loader_id, vehicle_id, loader_start, loading_cycle_id set. |
| No vehicle | No Edge request before selection; empty selection rejected in UI; direct backend request without vehicle rejected by current guard. |
| Cross-company vehicle | Vehicle absent from UI list; forged vehicle ID rejected by Edge/Core; no state change. |
| Resume same device | Edit two item quantities/notes → pause → reopen same active runsheet → same draft restored; no second start call and no stock movement. |
| Stale draft | Change cycle/loader/runsheet identity in controlled test → old draft is not restored. |
| Partial load | Only positive rows submitted; zero rows omitted; Core records central movement and sync trigger reflects results. |
| All-zero load | UI blocks before HTTP; no DB mutation. |
| Quantity above picked | UI rejects it; no complete-loading request. |
| Duplicate completion / timeout | Verify actual HTTP behavior and erp_operation_registry against Core; do not assume retry is safe after status changes. |
| Cancel | cancel-loading success restores Picked and clears server loading context; local draft deleted only after confirmed success; no loading movement remains. |
| Reopen completed | UUID operation_id sent; Edge resolves correct company; Core reverses prior loading through post_stock_movement, changes cycle, and UI reloads the new active cycle. |
| Completed-list isolation | Only current company and canonical loader users.id rows appear. |
| Runtime delivery | Confirm Cloudflare-served Loader is the committed artifact and record browser console/network evidence. |

### Retry/idempotency caveat

Current Core checks that the runsheet is Loading before consulting erp_operation_registry. A request retried after the first transaction committed and changed status to Loaded may fail the context check rather than return the stored duplicate result. The UI must not claim this retry case is verified. A separate Core change needs its own surgical review and tests; it is not silently included in the Loader patch.

## 9. Mutation and governance ledger

- No Production table or runsheet row was changed.
- No stock movement was created.
- No Edge Function was deployed or modified.
- No operational HTML was changed because the governing prompt explicitly reserves that mutation to the owner.
- No fixture or harness was created.
- This Report495 is the new artifact.
- Production live inspection was read-only.
- Cloudflare served artifact and authenticated HTTP E2E remain unverified.

## 10. FINAL SELF-AUDIT

### What I Proved

- Latest operational Loader source already contains vehicle selection; the old “no vehicle selector in current source” finding is stale.
- Live Production Edge versions/status/JWT settings/digests for four loading endpoints were read directly in this session.
- Loader's completion payload includes zero-quantity items while the live Edge rejects any submitted item with loaded_qty <= 0.
- Loader currently permits a quantity ceiling based on ordered quantity while Core enforces picked capacity.
- Loader's reopen button omits operation_id required by the live Edge endpoint.
- Loader has no durable IndexedDB draft/restore mechanism equivalent to Picker's.
- Live reopen-loading Edge uses app_settings.limit(1) to choose company context, which is not adequate evidence of authenticated-user tenant isolation.
- order_details sync trigger is intended to propagate qty_loaded into run_sheet_details.

### What I Did Not Prove

- That Cloudflare currently serves the latest Git commit.
- That any proposed owner patch has been applied.
- That an authenticated production HTTP E2E passed.
- That completion retry after an ambiguous timeout is safe.
- That current reopen-loading company selection is safe for multiple companies.

### What I Fixed

No operational code was changed in this cycle due the explicit governance prohibition. I produced a source-grounded, ordered repair plan and test matrix rather than falsely reporting a deployed fix.

### What I Initially Missed

- Vehicle-selection UI had already been added in commit 684a9fa4... after the earlier Report494 checkpoint; the checkpoint was stale.
- The remaining Loader/Picker gaps are draft persistence, zero-row payload filtering, picked-quantity ceiling, reopen operation identity, and reopen tenant context.

### What Could Still Be Wrong

- Other changes may have landed after the source SHA retrieved during this inspection.
- Cloudflare deployment may lag GitHub.
- Edge retry semantics may differ under an actual timed-out HTTP request.
- Existing RPC behavior requires runtime validation with a known isolated fixture before any closure claim.

**Final confidence:** High for identified static/API contract mismatches; moderate for complete lifecycle semantics; low for runtime closure because no deployed browser/HTTP E2E was executed.  
**Final closure status:** OPEN — OWNER HTML PATCH + REOPEN EDGE TENANT FIX + AUTHENTICATED E2E REQUIRED. No 100% CLOSED claim is made.
