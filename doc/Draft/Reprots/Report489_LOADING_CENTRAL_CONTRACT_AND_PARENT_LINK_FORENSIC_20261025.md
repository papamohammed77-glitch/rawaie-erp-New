
# Report489 — تحقيق تكامل النظام الأم والتطبيقات التشغيلية: Loader / Central Loading Contract
**التاريخ:** 2026-10-25  
**الحدث:** LVE-2026-10-25-490  
**الحالة:** SOURCE DEFECTS CONFIRMED / PRODUCTION CONTRACT VERIFIED / NO SOURCE OR DB MUTATION / NOT CLOSED

## 1. SELF-AUDIT قبل الفحص

- **Business understanding:** مؤكد في نطاق تدفق Loading من التطبيق إلى Edge ثم RPC ثم سجلات الطلب والمخزون.
- **Architecture understanding:** مؤكد جزئيًا؛ التطبيق التشغيلي companies/company-1/warehouse/loader.html يستدعي complete-loading عبر RW_API.call، والكتابة المخزنية تمر عبر complete_runsheet_loading ثم post_stock_movement.
- **Database understanding:** تم التحقق مباشرة من Production schema وتعريف RPC وACL.
- **Historical understanding:** تم فتح Report488 بوصفه مؤشرًا تاريخيًا، ولم يُستخدم كبديل عن فحص المصدر والإنتاج الحاليين.
- **Production understanding:** تم جلب مصدر Edge المنشور مباشرةً من Supabase وفحص تعريف RPC ووقت قاعدة البيانات في الجلسة نفسها.
- **Current understanding:** أعيد جلب Loader وPicker وapp.html وcore.js من فرع main في المستودع التشغيلي.
- **Execution confidence:** مرتفع في عيوب المصدر/العقد المحددة أدناه؛ غير كافٍ لإعلان إغلاق تشغيلي لعدم تنفيذ Browser E2E أو نشر إصلاح.

### الحالة عند الفحص
- **Operational repository:** papamohammed77-glitch/erp-frontend, branch main.
- **Loader SHA:** 97b83d68a683df77c1e0557838c24a1b4fb65169.
- **Picker SHA:** d483bd15b36585b975b63c2ef641481a01d5d084.
- **app.html SHA:** ec75f89c11620f6e8b8ef5996cf1a3289dcf20b4.
- **core.js SHA:** ff2f581d9900543c16f7cb026e13446520c0329d.
- **Parent-system entry check:** companies/company-1/main.html exists in erp-frontend/main as a zero-byte file, blob SHA bb10422217fc57a9a42c2bf65a55e9470a19537c. No non-empty main.html was found at the checked repository-root paths.
- **Production project:** fiilmooggumokxanwiyx (SMART ERP).
- **Fresh database capture:** 2026-10-25 12:59:11.58881+00.
- **Production Edge:** complete-loading v11, ACTIVE, verify_jwt=true, ezbr_sha256=c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286.
- **Production RPC:** public.complete_runsheet_loading(uuid,uuid,jsonb,text), SECURITY DEFINER; observed ACL: postgres and service_role EXECUTE. No anon/authenticated EXECUTE grant appeared in the returned ACL.
- **Central movement dependency:** Production exposes the 10-argument post_stock_movement(..., p_idempotency_key text) to service_role; a 9-argument overload also exists but is postgres-only. Neither overload was modified.

## 2. CONFIRMED DEFECT 1 — application silently attempts a forbidden direct write

**File:** https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/warehouse/loader.html  
**Blob SHA:** 97b83d68a683df77c1e0557838c24a1b4fb65169  
**Location:** line 289, inside editLoadedItem.

### العنصر المعيب — النص الأصلي الفعلي فقط
~~~js
supabase.from('run_sheet_details').update({qty_loaded:nq}).eq('runsheet_id',s.session.runsheet_id).eq('item_code',it.item_code).then(function(){});
~~~

### السبب المثبت
- Production grants authenticated SELECT but not UPDATE on run_sheet_details; no authenticated UPDATE policy was present in the inspected state.
- The Promise callback ignores both error and affected-row count. The UI can therefore behave as if the draft quantity was saved when the direct write failed.
- The central completion RPC writes order_details.qty_loaded and synchronizes the detail projection; direct update to run_sheet_details is not an authorized source-of-truth path.

### الإجراء الجراحي المقترح
احذف هذا السطر فقط. لا تستبدله بكتابة مباشرة أخرى إلى run_sheet_details. تبقى القيم محليًا في جلسة Loader حتى الإرسال المركزي. هذا الإجراء وحده لا يحل عيب حفظ الملاحظات أو الأصناف ذات الكمية صفرًا، وهما موثقان أدناه.

**الأثر المتوقع:** إزالة محاولة كتابة غير مصرح بها ورسالة نجاح ضمنية كاذبة، دون منح صلاحيات جدول إضافية أو إنشاء مسار كتابة موازٍ.

## 3. CONFIRMED DEFECT 2 — Loader payload contract is incompatible with Production Edge/RPC for zero-loaded items and notes

### 3.1 Loader: النص الأصلي الفعلي
**File/SHA:** loader.html / 97b83d68a683df77c1e0557838c24a1b4fb65169, lines 298–304.

~~~js
its.push({itemCode:it.item_code,loadedQty:it.qty_loaded,notes:it.notes});
...
RW_UI.showLoader(); RW_API.call('complete-loading',{runsheet_code:s.session.runsheet_code,items:its},function(json) { RW_UI.hideLoader();
~~~

### 3.2 Production Edge: النص المنشور الفعلي
**Function:** complete-loading v11 / ACTIVE / verify_jwt=true.

~~~ts
const items = rawItems.map((x: any) => ({
  item_code: x?.item_code ?? x?.itemCode,
  loaded_qty: Number(x?.loaded_qty ?? x?.loadedQty ?? 0)
}))
if (items.some((x: any) => !x.item_code || x.loaded_qty <= 0)) throw new Error("بيانات التحميل غير صالحة")
~~~

### 3.3 Production SQL: الشرط الفعلي
**RPC:** public.complete_runsheet_loading(p_company_id uuid, p_runsheet_id uuid, p_items jsonb, p_user_email text).

~~~sql
IF iid IS NULL OR req<=0 THEN RAISE EXCEPTION 'invalid item request'; END IF;
...
PERFORM public.post_stock_movement(p_company_id,'Loading',m,van,iid,req,r.runsheet_code,keybase||'|'||iid::text,p_user_email,keybase||'|'||iid::text);
~~~

### السبب المثبت
- Loader sends every line, including loadedQty=0, and includes notes.
- Production Edge rejects any line with loaded_qty <= 0; the RPC independently rejects req <= 0. Thus a valid partial-loading case where an item was not loaded at all cannot be represented in the current completion request without failing the transaction.
- Production Edge maps only item_code and loaded_qty; it drops notes before calling the RPC. The RPC does not parse notes and does not persist the reason.
- The schema confirms order_details.reason_loading exists, alongside order_details.notes; run_sheet_details has no notes column. Therefore a direct write to the projection table is not a valid repair.

### الإصلاح الصحيح المطلوب
لا تعالج ذلك بتصفية الأصناف ذات الكمية صفرًا من الواجهة فقط؛ فهذا قد يمنع RPC من تصفير كميات محمّلة سابقًا في سطور الطلب المقابلة. يجب إصلاح العقد المركزي كحزمة واحدة:
1. تطبيع notes / سبب النقص في Edge payload.
2. تعديل RPC للسماح بـ loaded_qty=0 كحالة fulfillment/backorder صحيحة، مع تحديث order_details.qty_loaded وreason_loading على السطور المعنية.
3. استدعاء post_stock_movement فقط عندما تكون الكمية موجبة؛ الصفر ليس حركة مخزون.
4. الحفاظ على loading_cycle_id وerp_operation_registry ورفض إعادة استخدام مفتاح idempotency مع payload مختلف.
5. استمرار معالجة backorders وتغيير حالة الرانشيت ضمن المعاملة نفسها.
6. إضافة migration canonical واختبارات rollback/retry/duplicate/concurrency قبل نشر أي تغيير.

**لم تُطبق هذه التغييرات في هذا التنفيذ:** لا توجد بيئة Staging نشطة مثبتة ولا تم إجراء E2E معزول في هذه الدورة. لم تُجرَ أي كتابة SQL أو نشر Edge أو تعديل مصدر.

## 4. CONFIRMED SOURCE WIRING DEFECT 3 — parent-system link targets a zero-byte file

**File:** https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/app.html  
**Blob SHA:** ec75f89c11620f6e8b8ef5996cf1a3289dcf20b4, line 64.

### العنصر المعيب — النص الأصلي الفعلي فقط
~~~html
<a href="main.html" class="text-gray-400 text-xs hover:text-blue-600">الدخول إلى النظام الأم</a>
~~~

### الدليل
الرابط نسبي من companies/company-1/app.html ويشير إلى companies/company-1/main.html. هذا الهدف موجود في المستودع التشغيلي لكنه صفر بايت (blob SHA bb10422217fc57a9a42c2bf65a55e9470a19537c). كما لم يُعثر على ملف نظام أم غير فارغ في مسارات الجذر التي جرى فحصها داخل المستودعين.

### حدود الاستنتاج والإجراء
الخلل في المصدر مؤكد: رابط الدخول إلى النظام الأم لا يصل إلى ملف HTML يحتوي تطبيقًا. لكن عنوان النظام الأم المنشور الصحيح لم يُثبت من Cloudflare/Deployment في هذه الجلسة؛ لذلك لا أختلق URL بديلًا ولا أغير الرابط إلى مسار تخميني. يجب ربطه بالمسار المنشور الفعلي بعد إثباته من إعداد النشر/الـrouter. فحص artifact المنشور للواجهة ما زال UNVERIFIED.

## 5. Consumer / core trace

~~~text
Loader UI (loader.html)
  ├─ local draft: qty_loaded + notes
  ├─ [defect] unauthorized best-effort UPDATE → run_sheet_details
  └─ RW_API.call('complete-loading', { runsheet_code, items[] })
       → Production Edge complete-loading v11
          ├─ auth.getUser(token)
          ├─ public.users lookup by auth_id = auth.users.id
          ├─ resolve company_id from authenticated profile
          ├─ select runsheets constrained by company_id + runsheet_code
          └─ RPC complete_runsheet_loading(company_id, runsheet_id, items, user_email)
               ├─ idempotency: erp_operation_registry + loading_cycle_id
               ├─ updates order_details.qty_loaded
               ├─ fulfillment_backorders
               ├─ central post_stock_movement for positive quantities
               └─ marks runsheet/orders Loaded
~~~

## 6. Security and isolation observations

- Production Edge verifies the bearer token with auth.getUser(token) and resolves the company through public.users.auth_id = auth.users.id.
- The runsheet lookup is explicitly scoped by company_id.
- The RPC is SECURITY DEFINER and its observed ACL allows service_role, not anon/authenticated; the Edge service-role call is the authorized boundary in the inspected path.
- No direct Production write was performed. This report does not claim a full system-wide ACL sweep; only the relevant loading path was inspected.

## 7. Tests and production changes

| Check | Result | Evidence / limit |
|---|---|---|
| Fresh Production Edge source | PASS | Direct Supabase fetch: v11, ACTIVE, JWT verification ON |
| Fresh RPC definition/ACL | PASS | Direct read-only SQL at 2026-10-25 12:59:11.58881+00 |
| Current Loader source | PASS | Fresh GitHub fetch, SHA recorded above |
| Parent link target | FAIL (source-level) | Relative target exists as zero-byte HTML |
| Direct projection-table write | FAIL (contract) | authenticated lacks UPDATE; Promise suppresses error |
| Zero-quantity loading contract | FAIL (contract) | Edge and RPC both reject zero-loaded line |
| Notes persistence | FAIL (contract) | Edge drops notes; RPC does not persist them |
| Browser/HTTP E2E | NOT RUN | No authenticated browser run or isolated fixture executed |
| Staging | UNVERIFIED | No active staging verification in this cycle |
| Production deploy | NOT PERFORMED | No source or database mutation performed |
| Baseline/data restoration | N/A | No fixture/data writes performed |

## 8. Mutation ledger

- Source files changed: NONE.
- Production Edge deployments: NONE.
- Database DDL/DML: NONE.
- Test fixture creation/deletion: NONE.
- Report written: this file only, after the investigation.
- CURRENT_STATE update: to be appended after this report commit is confirmed.

## 9. Remaining closure work

1. Owner/source change: remove the unauthorized best-effort run_sheet_details update line.
2. Establish the real deployed URL/path for the parent system, then correct the link to the verified target and fill/restore the canonical parent entry artifact through the authorized source workflow.
3. Design and apply one canonical migration for zero-quantity Loading and reason persistence; update the deployed Edge artifact and Current source together.
4. Verify the migration against the cumulative Production state before deployment; inspect grants, RLS, triggers, constraints and dependent functions.
5. Run isolated Staging tests: all-positive, partial with zero line, retry, duplicate, payload conflict, company isolation, failure rollback, and concurrent completion.
6. Deploy only after source and migration are reconciled; verify fresh Production Edge version/source and execute authenticated HTTP E2E.
7. Verify database baseline and confirm no duplicate movement, no incorrect reservation delta, and no orphaned test artifacts.
8. Confirm the Cloudflare-served parent entry route and browser navigation.

## 10. SELF-AUDIT FINAL

- **What I proved:** current Loader source fingerprint; current Production complete-loading v11/JWT state; live RPC definition and ACL; schema fields relevant to loading reasons; the ignored unauthorized direct write; zero-quantity and notes contract mismatch; the parent link’s zero-byte target.
- **What I did not prove:** deployed Cloudflare artifact identity; actual user-visible reproduction; successful patched runtime; full global consumer/writer/ACL sweep; Staging or Production E2E; end-to-end baseline restoration.
- **What I fixed:** no code/DB fix was applied. The defects are precisely localized and recorded; source changes remain under the owner’s source-application workflow.
- **What I initially missed:** the parent entry target is a zero-byte file, and the Loader direct-write path is not merely redundant—it suppresses an unauthorized write failure.
- **What could still be wrong:** Cloudflare routing may rewrite the parent path, and the exact intended route is not yet proven; the proposed reason mapping must be validated against existing business semantics before implementation.
- **Final confidence:** high for source/DB contract findings; low for deployed UI runtime because it was not exercised.
- **Final closure status:** **PARTIAL — NOT CLOSED**. No 100% CLOSED claim is made.
