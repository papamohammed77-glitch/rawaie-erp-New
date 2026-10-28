# Report526 — تحقيق فجوة ظهور تكليفات مشرف التوصيل في Runtime النظام الأم

**التاريخ:** 2026-10-28  
**النطاق:** تطبيق مشرف التوصيل → إدارة التوصيل والشحن → مناديب التوصيل في النظام الأم فقط.  
**الحالة:** `SOURCE + LIVE PRODUCTION RPC/DATA VERIFIED / DEPLOYED AUTHENTICATED UI E2E NOT PROVEN / ROOT CAUSE OF RUNTIME GAP STILL OPEN`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding — CONFIRMED:** إسناد مندوب التوصيل إلى الرانشيت هو `runsheets.deliverer_id`. وهو منفصل عن سجل `delivery_agents)، وعن هوية السائق `driver_id)، وعن المركبة `vehicle_id`.
- **Architecture Understanding — CONFIRMED:** تطبيق المشرف يحفظ الإسناد عبر `delivery_supervisor_assign_deliverer_atomic`; النظام الأم يقرأ بيانات مركز اللوجستيات عبر `delivery_logistics_query`. لا ينبغي تحويل تكليف الرانشيت تلقائيًا إلى سجل مندوب لوجستي أو خطة مسار.
- **Database Understanding — CONFIRMED:** استعلام Production المباشر يعيد تكليفين محفوظين، كما أن RPC يعيدهما داخل `runsheet_assignments`.
- **Historical Understanding — CONFIRMED:** تمت مراجعة CURRENT_STATE.md وآخر التقارير 523–525 والمرجع الحاكم المتاح. استُخدمت التقارير لتحديد مواضع الفحص، لا كبديل عن Git وProduction.
- **Production Understanding — CONFIRMED:** أُعيد فحص تعريف RPC الحي وصلاحيات EXECUTE وبيانات الرانشيت والنتيجة الفعلية للاستدعاء.
- **Current Understanding — CONFIRMED:** blob النظام الأم في Git هو `0c1745081e8d17480433ed527d77cac9f5292021`، وblob تطبيق المشرف هو `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
- **Execution Confidence:** مرتفع لعقد المصدر وبيانات/RPC Production؛ غير كافٍ لإعلان نجاح E2E مصادق عليه أو تحديد سبب Runtime النهائي.

### فحوص المصادر والسجلات

- **Current State:** تمت قراءته؛ أحدث نقطة سابقة كانت LVE-525.
- **Historical reports:** Report523 وReport524 وReport525؛ كما تم فحص سياق الإصلاح الوظيفي في commit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc`.
- **Operational repository:** `papamohammed77-glitch/erp-frontend`, branch `main`.
- **Parent artifact:** `companies/company-1/main.html`, blob `0c1745081e8d17480433ed527d77cac9f5292021`.
- **Supervisor artifact:** `companies/company-1/delivery/supervisor.html`, blob `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
- **Production RPC:** `public.delivery_logistics_query(uuid,text,jsonb,uuid,text)`.
- **Production SQL timestamp returned by database:** `2026-10-28 13:03:03+00`.

## 2. Production evidence — read-only

The fresh SQL result returned:

- Active owner actor in company `00000000-0000-0000-0000-000000000001`, with `permissions=["*"]`.
- Runsheets in company: `2`; assigned runsheets: `2`.
- `RS-1`: status `Loaded`, deliverer «مندوب توصيل».
- `RS-2`: status `Loaded`, deliverer «مندوب توصيل 3».
- RPC `delivery_logistics_query(..., 'agents', ...)`: `success=true`, `rows=[]`, and `runsheet_assignments` containing both RS-1 and RS-2.
- `delivery_logistics_query` is `SECURITY DEFINER`, with `search_path=public`; `authenticated` can execute it and `anon` cannot.

**Interpretation:** `rows=[]` is the empty master registry `delivery_agents`; it is not evidence that the supervisor assignments are missing. The assignment rows are present in the separate `runsheet_assignments` property.

No production data, schema, RPC, ACL/RLS, inventory, accounting, or operational record was changed. RS-1 and RS-2 were read-only evidence and were not used as test fixtures.

## 3. Source and consumer contract

The current source and earlier reviewed commit establish the intended split:

1. The supervisor UI queries runsheets and invokes `delivery_supervisor_assign_deliverer_atomic`.
2. The assignment belongs to `runsheets.deliverer_id`.
3. The Parent `q(view,payload)` returns the RPC response object, not only `rows`.
4. Parent `agents()` must render two separate concepts: the master `delivery_agents` registry from `d.rows`, and the supervisor assignments from `d.runsheet_assignments`.

The source-level assignment-table patch was already included in commit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc`; current-state evidence identifies it as present in the current Parent blob. The supervisor file blob is unchanged from the last review. Therefore, repeating that same source patch or changing the RPC would duplicate already-present responsibility without new evidence.

## 4. Published Runtime observation and limitation

The connected browser's existing tab for `https://rawaea-erp.pages.dev/companies/company-1/main` exposed a page snapshot whose visible Parent section showed the master delivery-agent table and the empty-state message «لا يوجد مناديب مسجلون», but did **not** show the separate «تعيينات الرانشيت من مشرف التوصيل» table.

However, the same snapshot showed the login form with `owner@alrawae.com` prefilled and an empty password field. It therefore does **not** prove a successfully authenticated Parent session. The snapshot's tab metadata was last opened at `2026-10-28T12:29:34Z`, before the fresh SQL check. No authenticated Network response, browser console trace, or served-artifact source hash was available in this read-only browser context.

This is a concrete **runtime/source discrepancy to investigate**, not proof that Cloudflare is stale. The remaining alternatives include an older served artifact, unauthenticated/stale DOM, or a client-side runtime/rendering failure. The evidence does not yet distinguish them.

## 5. Surgical decision

**No new operational code or Production mutation was justified in this run.** The current Parent and supervisor HTML files are owner-maintained and must not be edited by this assistant under the task's change boundary. The existing SQL contract already returns the correct assignment rows; changing it or adding test records would not address the unproven browser/rendering cause.

No exact new code replacement is issued because no new defective source fragment has been isolated. Do not repeat the already-implemented Parent assignment-table patch.

## 6. Exact next diagnostic action

On the published Parent page, after the owner signs in normally:

1. Open **إدارة التوصيل والشحن → مناديب التوصيل**.
2. Inspect the request to `delivery_logistics_query` for view `agents`.
3. If the response contains `runsheet_assignments` with RS-1 and RS-2 but the table is absent, capture the Console exception and compare the served HTML/JS with Parent blob `0c1745081e8d17480433ed527d77cac9f5292021`.
4. If the response itself lacks `runsheet_assignments`, capture the exact request/response and compare the invoked RPC signature/deployed database function with the live definition recorded above.
5. If served code is older than the current blob, repair the Pages deployment/redeployment path; do not patch the same source again.
6. After isolating the cause, run authenticated Parent E2E and verify RS-1/RS-2 render without creating or mutating production fixtures.

## 7. Change ledger

- Operational HTML: **unchanged**.
- Supabase schema/data/RPC/ACL/RLS: **unchanged**.
- Production business data and test fixtures: **unchanged**.
- Inventory/accounting: **unchanged**.
- This report and CURRENT_STATE continuity entry: documentation-only.

## 8. SELF-AUDIT FINAL

- **What I Proved:** Current Git artifact identifiers; supervisor call path; live RPC definition and ACL; two actual Production assignments; RPC returns both assignment rows; current browser snapshot lacks the assignment table while displaying a login form.
- **What I Did Not Prove:** authenticated Parent UI rendering, current Cloudflare served-artifact parity, a fresh HTTP/browser E2E, or which runtime branch causes the missing table.
- **What I Fixed:** No operational defect was changed because the source/database defect is not currently isolated. This report records the fresh evidence and the precise next diagnostic.
- **What I Initially Missed:** An empty `delivery_agents` master registry must not be confused with missing `runsheets.deliverer_id` assignments; also, a logged-out page snapshot cannot serve as authenticated E2E evidence.
- **What Could Still Be Wrong:** Served build drift or a client-side rendering/runtime error remains plausible but unconfirmed.
- **Final Confidence:** High for the live SQL/data contract; limited for published UI behavior.
- **Final Closure Status:** `PRODUCTION DATA/RPC VERIFIED / SOURCE PATCH ALREADY PRESENT / AUTHENTICATED DEPLOYED UI E2E OPEN / NOT 100% CLOSED`.
