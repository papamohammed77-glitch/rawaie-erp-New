# Report651 — Parent Finance Employee Custody Event Binding Collision
**Date:** 2026-11-08 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-08-651  
**Status:** `ROOT CAUSE CONFIRMED — OWNER-ONLY PARENT CHANGESET PREPARED — DEPLOYMENT / AUTHENTICATED E2E UNVERIFIED`

## 1. النتيجة التنفيذية

تم استلام المهمة من LVE650، وقراءة ملف `writing-block-8-10.md` كاملًا (SHA `39f18748a8a3cf633a04506216cc39fd98de523d`)، والدستور التشغيلي كاملًا (SHA `3a6b1e220af8509e314e94df76563bbc6f84910d`)، وCURRENT_STATE، والتقارير ذات الصلة Report545 وReports644–650، مع إعادة فحص المصدر الحالي وSupabase ولقطات Browser/Cloudflare المتاحة.

**السبب الجذري في مصدر Parent الحالي CONFIRMED:** يوجد تعريفان لـ`bind(root)` داخل النطاق نفسه في وحدة `RW_Finance_Custody`. التعريف الأول هو المعالج الجديد الشامل لأزرار السجل والبحث والتفاصيل والترقيم. التعريف الثاني، الموجود لاحقًا بعد `doc(path)`، هو المعالج القديم الذي يستمع فقط إلى زيادة العهدة والتسوية ومراجعة المصروف وفتح المستند. تعريف Function اللاحق يحجب التعريف الأول؛ لذلك يستدعي `render()` المعالج القديم ولا تتصل أحداث البحث/التفاصيل/الترقيم.

تم تجهيز إصلاح من تغيير اسم واحد في تعريف المعالج القديم، دون تعديل الدالة المالية أو استدعاءات RPC أو البيانات أو Edge Function. لم يُكتب إلى `main.html` ولم يُنشأ Commit تشغيلي، التزامًا بالبرومبت §10.1 والدستور §7.1 و§6.2: ملفات Parent يطبقها المالك بعد عرض ChangeSet محدد واعتماده.

## 2. LAST VERIFIED EVENT ونقطة الاستئناف

- **Current opening checkpoint:** LVE-2026-11-08-650.
- **Current state SHA at opening:** `8706ac15451790decfde17acd72b88f26682297c`.
- **Latest operational repository:** `papamohammed77-glitch/erp-frontend`, branch `main`.
- **Latest operational HEAD:** `855810884e9184122c5f149b6d052479a840cc6f`.
- **Parent file:** `companies/company-1/main.html`.
- **Current Parent blob:** `6b4d555d0da9efd3fb821aef4a9a2e832bb064e1`.
- **Last functional source commit:** `0389995ac3f4440113f5c83b41821366eba3fbeb`.
- Compare `0389995` → `8558108`: one descendant commit only, changing `_forensic_current_main_extract.md`; no intervening Parent source change.
- **Supabase SMART ERP:** `fiilmooggumokxanwiyx`, status `ACTIVE_HEALTHY`.
- **Existing Edge Function:** `save-purchase-order`, v33, ACTIVE, `verify_jwt=true`.

Report650 remains the latest completed operational checkpoint. Report649's client-side/first-200 proposal is superseded by Report650's server-paginated register; do not reapply Report649.

## 3. الحوكمة والمراجع المقروءة

- `writing-block-8-10.md` — full 34,511 characters; sections 1–19 reviewed, especially §§4, 8, 10, 11, 15–19.
- `الدستور التشغيلي الدائم.md` — full 19,916 characters; §§6.1–6.4, 7–14 reviewed.
- `CURRENT_STATE.md` — current opening LVE650; full file retained as history; latest checkpoint at top.
- Report545 — `Report545_GOVERNANCE_AUDIT_AND_DELIVERY_OWNER_PATCH_RESET_20261029.md`, SHA `e153396709ecfcc0552347db84e37c98ad8bcdd6`; full report read in chunks. It confirms the owner-only Parent ChangeSet method and the separation between source, deployment and E2E.
- Report644 — `Report644_EMPLOYEE_CUSTODY_UI_INTEGRATION_AND_RUNTIME_GAP_REVIEW_20261108.md`, SHA `87cf1c95e56000f268eedd967d66ac115bb670b8`.
- Report645 — `Report645_FINANCE_CUSTODY_STOP_LIFECYCLE_FIX_20261108.md`, SHA `ceac383e367b08b8793fe023f81f137d42b147dd`.
- Report646 — `Report646_PARENT_EMPLOYEE_CUSTODY_LEDGER_COMPLETION_20261108.md`, SHA `cfeafc59892232812d0ec02ba23934379e5f80cd`.
- Report647 — `Report647_PARENT_FINANCE_CUSTODY_RW_API_RUNTIME_FIX_20261108.md`, SHA `725363c509366b6628afbf2fd8b939e89ca5fe6f`.
- Report648 — `Report648_PARENT_FINANCE_EMPLOYEE_CUSTODY_ISSUE_ACTION_FIX_20261108.md`, SHA `be9b14ffa1131814722a614459e374b9566bed9c`.
- Report649 — `Report649_PARENT_FINANCE_CUSTODY_SEARCHABLE_REGISTER_20261108.md`, SHA `a8715050448d5c0596851a8fa52966ffa2bcaaf2`.
- Report650 — `Report650_PARENT_FINANCE_CUSTODY_SERVER_PAGINATED_REGISTER_20261108.md`, SHA `2a4430ddedb6ed9c7335bb476501a4df2f1ecd14`.

### الحاكمية الملزمة

- Parent `main.html` وCore والتطبيقات التشغيلية: Owner ChangeSet only; assistant does not directly edit.
- Supabase DDL/DML/RPC/RLS/ACL/Edge deployment and financial effects require specific change approval under §6.2 / prompt §10.2.
- Read-only investigation and precise change preparation are permitted.
- Do not create a branch, parallel application, staging workflow or new Edge Function. The project listing does contain a Supabase project named `rawaea-staging` (`hfzznsiprnwkpayskzhu`), but the owner's §6.4 directs this workstream to SMART ERP Production only; that project was not used. Its existence is not proof of an approved staging path.

## 4. فحص GitHub الحالي والسبب الجذري

The latest functional Parent commit `0389995ac3f4440113f5c83b41821366eba3fbeb` adds the server-paginated register and its new comprehensive event binder. Its patch contains **two declarations** of `function bind(root)` in the same IIFE.

### 4.1 المعالج الجديد — موجود لكنه محجوب

The earlier declaration includes selectors:
- `data-custody-apply`
- `data-custody-reset`
- `data-custody-page`
- `data-custody-open-detail`
- existing advance/settle/review/doc actions

It also installs a delegated `change` listener for `#custody-page-size`, stores `_boundChangeHandler`, and is cleaned up by the current `stop()`.

### 4.2 المعالج القديم — التعريف اللاحق الفعّال حاليًا

The later declaration appears immediately after `function doc(path){...}` in the diff hunk around new source line 23295. It only matches:
`[data-custody-advance],[data-custody-settle],[data-custody-review],[data-custody-doc]`.

It does not handle any of the four register actions above and has no page-size change listener. The active later `render()` calls `bind(target)`; due to the duplicate declaration, this resolves to the legacy handler.

### 4.3 لماذا الأعراض تطابق السبب

| User-visible symptom | Missing event in effective legacy binder |
|---|---|
| Apply search filters does nothing | `data-custody-apply` not selected |
| Reset filters does nothing | `data-custody-reset` not selected |
| Open Details does nothing | `data-custody-open-detail` not selected |
| Previous/Next does nothing | `data-custody-page` not selected |
| Page size selector does nothing | no `change` listener for `#custody-page-size` |

This is a direct source-level explanation, not an inference from the report. The duplicate-declaration precedence was also reproduced in an isolated JavaScript check: later duplicate declaration wins; renaming the legacy declaration leaves the comprehensive binder callable.

Report645 had already recorded the existence of duplicate `bind()` and `render()` declarations and the need to change the effective declaration, rather than add another shadowed implementation. The LVE650 patch inserted the comprehensive binder earlier but left the later legacy `bind()` in place. This is the immediate regression in the current register event wiring.

## 5. Owner ChangeSet — one-identifier surgical correction

**Repository:** `papamohammed77-glitch/erp-frontend`  
**Branch:** `main`  
**Commit/blob inspected:** HEAD `855810884e9184122c5f149b6d052479a840cc6f`; Parent blob `6b4d555d0da9efd3fb821aef4a9a2e832bb064e1`.  
**File:** `companies/company-1/main.html`  
**Module:** `RW_Finance_Custody`  
**Anchor:** the second `function bind(root)` declaration immediately after `function doc(path){...}`, around line 23295. Reconfirm this exact text and current blob SHA before applying.

### Original current line

```javascript
function bind(root){var h=root||byId('finance-content');if(!h)return;if(_boundElement&&_boundElement!==h&&_boundElement.onclick===_boundHandler)_boundElement.onclick=null;var handler=function(ev){var x=ev.target.closest&&ev.target.closest('[data-custody-advance],[data-custody-settle],[data-custody-review],[data-custody-doc]');if(!x)return;if(x.hasAttribute('data-custody-advance'))advance(x.getAttribute('data-custody-advance'));else if(x.hasAttribute('data-custody-settle'))settle(x.getAttribute('data-custody-settle'));else if(x.hasAttribute('data-custody-review'))review(x.getAttribute('data-custody-review'),x.getAttribute('data-custody-type'));else doc(x.getAttribute('data-custody-doc'));};h.onclick=handler;_boundElement=h;_boundHandler=handler;}
```

### Exact replacement

```javascript
function bindLegacy(root){var h=root||byId('finance-content');if(!h)return;if(_boundElement&&_boundElement!==h&&_boundElement.onclick===_boundHandler)_boundElement.onclick=null;var handler=function(ev){var x=ev.target.closest&&ev.target.closest('[data-custody-advance],[data-custody-settle],[data-custody-review],[data-custody-doc]');if(!x)return;if(x.hasAttribute('data-custody-advance'))advance(x.getAttribute('data-custody-advance'));else if(x.hasAttribute('data-custody-settle'))settle(x.getAttribute('data-custody-settle'));else if(x.hasAttribute('data-custody-review'))review(x.getAttribute('data-custody-review'),x.getAttribute('data-custody-type'));else doc(x.getAttribute('data-custody-doc'));};h.onclick=handler;_boundElement=h;_boundHandler=handler;}
```

Only the identifier `bind` → `bindLegacy` changes. Do not alter the earlier comprehensive `bind(root)`, the active `render()`, `stop()`, filters, API helper, or finance actions. The active render's `bind(target)` will then resolve to the earlier comprehensive binder. No exported interface changes: `bind` is private to the IIFE.

### Expected effects and non-effects

- Activates the already-authored delegated handlers for search, reset, page navigation, detail opening and page-size change.
- Preserves the existing advance, settle, review and document handlers in the comprehensive binder.
- Preserves the current `stop()` cleanup of the click and change listeners.
- No changes to employee identity, company/branch scope, Finance permission checks, API payloads, RPCs, Edge Function, accounting, treasury, custody business rows, inventory, suppliers or Buyer/Driver/Core.
- No database write, migration, new Edge Function, RLS/ACL change or financial posting.

## 6. Supabase SMART ERP read-only revalidation

- Project `fiilmooggumokxanwiyx`: `ACTIVE_HEALTHY`, PostgreSQL 17.6.1.121.
- `save-purchase-order`: version 33, ACTIVE, `verify_jwt=true`.
- Live Edge source includes the `GET_CUSTODY` register mode: requires Finance/Finance Manager for register mode, validates offset/page size/date range/employee UUID/search length, applies company scope, server-side search/filter, exact count and page range. Existing Buyer/employee mode remains backward-compatible and fetches authorized rows progressively.
- Existing custody RPC signatures are present; no RPC or schema mutation was performed.
- Read-only row counts:
  - `buyer_custodies`: 1
  - `buyer_custody_advances`: 1
  - `buyer_custody_expenses`: 0
  - `buyer_custody_payments`: 0
  - `buyer_custody_settlements`: 0
- Edge access logs around 2026-11-08 18:02Z contain authenticated v33 POST responses with HTTP 200. The access records do not expose the operation payload, so they do not prove that a specific `GET_CUSTODY` request or UI action succeeded.
- No DDL, DML, migration, RPC change, RLS/ACL change, Edge deployment, QA fixture, storage object, cash movement, treasury movement, journal entry, supplier/AP movement or stock/inventory movement was created.

## 7. Deployment and Browser evidence

- The connected Parent tab snapshot (last opened 2026-11-08 17:58 local) still contains the runtime text `RW_API is not defined`. It also shows the login form/shell; it is not a clean authenticated Finance test.
- The Cloudflare dashboard tab's last captured snapshot (last opened 16:35 local) displayed Production source `be4647ddc1caa3393229cfd73f80a31183457d27`. That snapshot is stale and is not a current deployment confirmation.
- Commit `4214cda5d180a003d79233a806ce7d6a2255b66b` fixed the Parent-local `RW_API` dependency, followed by fail-closed response parsing in `2a751e67405326d940af6eaf0f69ce42c7eca969`. Both are descendants of the last visible Cloudflare source snapshot. Compare `be4647d` → `8558108` is 10 commits ahead and includes `main.html` changes (+75/-12) plus a forensic extract update.
- The latest source has the API correction, but current Cloudflare deployment parity remains UNVERIFIED because the dashboard tab was not refreshed and the available Browser connector is read-only.
- No browser reload, click, navigation, login, authenticated DOM inspection or E2E action was performed.

### Deployment/runtime gates after owner application

1. Confirm a successful Cloudflare Production deployment containing the approved corrected Parent blob and the latest main source.
2. Open a fresh Parent session and confirm `RW_API is not defined` is absent.
3. Authenticate with an authorized Finance session and open Accounts & Finance → Employee Custody.
4. Verify date-from/date-to inclusive filtering, employee filter, text search, reset, previous/next, page-size change and correct detail drawer/target scroll.
5. Verify existing advance, settle, review and document actions still invoke the same established flow. Do not commit any financial action merely to prove the button opens.
6. Navigate away and back; verify no stale render or event listener remains.
7. Capture Console/Network/DOM evidence and compare served artifact to the approved commit/blob.

## 8. Status classification

**CONFIRMED**
- Current Git Parent blob and HEAD lineage.
- Two same-scope `bind(root)` declarations in the current functional commit.
- Later legacy declaration excludes search/reset/page/detail selectors and page-size change.
- New comprehensive binder contains the missing selectors and change listener.
- Current `GET_CUSTODY` backend contract supports server-side register filtering/pagination.
- SMART ERP and Edge v33 are healthy/active; current custody counts are 1/1/0/0/0.
- No production data or financial effects were changed.

**UNKNOWN**
- Whether the stale Parent tab's runtime error still occurs on a fresh load after the latest source is deployed.
- Current Cloudflare deployment status after the last visible dashboard snapshot.
- Exact operation represented by the v33 HTTP 200 access-log entries.

**CONFLICT**
- Supabase account listing contains a project named `rawaea-staging`, while the owner's governing §6.4 says this workstream must use SMART ERP Production only and no parallel staging/branch. No staging project was used; the existence and purpose of that named project are not inferred.

**UNVERIFIED**
- Authenticated Browser E2E.
- Served artifact parity.
- Actual click response after the owner applies the one-name patch and deployment completes.

## 9. Next action and closure

**Next action:** owner applies the one-identifier replacement in §5 to the current `main.html` blob after confirming the anchor and SHA, then publishes through the normal Cloudflare deployment path. The assistant can then re-fetch the resulting source, verify the changed blob, and continue read-only deployment/runtime checks available in the session.

**Closure state:** `ROOT CAUSE CONFIRMED — OWNER-ONLY PARENT CHANGESET PREPARED — DEPLOYMENT / AUTHENTICATED E2E UNVERIFIED`.

Do not label this issue FIXED, DEPLOYED or E2E VERIFIED until the owner patch exists in GitHub, Cloudflare serves that source, and the authenticated Finance controls are exercised successfully.
