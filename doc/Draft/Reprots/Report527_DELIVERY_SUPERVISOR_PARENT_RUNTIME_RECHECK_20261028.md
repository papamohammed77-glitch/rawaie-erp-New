# Report527 — إعادة فحص Runtime المنشور لتكليفات مشرف التوصيل
**التاريخ:** 2026-10-28  
**النطاق:** تطبيق مشرف التوصيل → النظام الأم → إدارة التوصيل والشحن → مناديب التوصيل فقط.  
**الحالة:** `SOURCE + PRODUCTION DATA/RPC VERIFIED / LIVE PAGE STILL DOES NOT EXPOSE ASSIGNMENT TABLE IN SNAPSHOT / DEPLOYMENT-OR-CLIENT-RUNTIME ROOT CAUSE UNRESOLVED`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding — CONFIRMED:** إسناد مندوب التوصيل إلى الرانشيت محفوظ في `runsheets.deliverer_id`، وهو مستقل عن `driver_id` و`vehicle_id` وعن السجل الإداري/التعاقدي `delivery_agents`.
- **Architecture Understanding — CONFIRMED:** تطبيق المشرف يستخدم `delivery_supervisor_assign_deliverer_atomic`; النظام الأم يقرأ `delivery_logistics_query`. يجب عرض تكليفات الرانشيت منفصلة عن سجل مناديب اللوجستيات.
- **Database Understanding — CONFIRMED:** فحص Production مباشر في `2026-10-28 13:21:07.478162+00` أعاد رانشيتين، وكلاهما مسند، ولا توجد سجلات `delivery_agents` نشطة للشركة.
- **Historical Understanding — CONFIRMED:** تمت مراجعة نقاط الحالة LVE-524 وLVE-525 وLVE-526 والتقارير 524–526، مع الرجوع إلى commit الإصلاح الوظيفي؛ لم تُعامل التقارير كبديل عن Git/Production.
- **Production Understanding — CONFIRMED:** RPC الحي يعيد تكليفات الرانشيت في `runsheet_assignments`. `authenticated EXECUTE=true` و`anon EXECUTE=false`.
- **Current Understanding — CONFIRMED:** Parent blob `0c1745081e8d17480433ed527d77cac9f5292021`; Supervisor blob `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
- **Execution Confidence:** مرتفع لعقد المصدر وبيانات/RPC Production؛ غير كافٍ لإعلان نجاح واجهة منشورة مصادق عليها.

## 2. مصادر الحقيقة التي فُحصت

- **Operational repository:** `papamohammed77-glitch/erp-frontend`, branch `main`.
- **Parent:** `companies/company-1/main.html`, blob `0c1745081e8d17480433ed527d77cac9f5292021`.
- **Supervisor:** `companies/company-1/delivery/supervisor.html`, blob `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
- **Existing source repair:** commit [cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc](https://github.com/papamohammed77-glitch/erp-frontend/commit/cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc), which adds a distinct assignment table in `RW_DeliveryLogistics.agents()`.
- **Production migration source:** [20261027_delivery_supervisor_parent_runsheet_assignments.sql](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/supabase/migrations/20261027_delivery_supervisor_parent_runsheet_assignments.sql).
- **Prior execution reports:** [Report524](Report524_DELIVERY_SUPERVISOR_ASSIGNMENT_PARENT_SYNC_20261028.md), [Report525](Report525_DELIVERY_SUPERVISOR_PARENT_VISIBILITY_FORENSIC_RECHECK_20261028.md), [Report526](Report526_DELIVERY_SUPERVISOR_PARENT_VISIBILITY_DEPLOYED_RUNTIME_GAP_20261028.md).

## 3. Fresh Production check — read-only

Timestamp returned by Production database: `2026-10-28 13:21:07.478162+00`.

| Check | Live result |
|---|---:|
| Runsheets in company | 2 |
| Assigned runsheets | 2 |
| Active `delivery_agents` rows | 0 |
| `delivery_logistics_query` EXECUTE for `authenticated` | true |
| `delivery_logistics_query` EXECUTE for `anon` | false |

Actual assignments returned by the live database:

- `RS-1` — «مندوب توصيل» — `Loaded`.
- `RS-2` — «مندوب توصيل 3» — `Loaded`.

No Production row, schema, RPC, ACL/RLS, inventory, accounting, or operational data was modified.

## 4. Source contract and prior repair

The current Parent source already contains the distinct `runsheet_assignments` table and continues to render the `delivery_agents` master registry separately. The Supervisor source already invokes the central assignment RPC. Therefore, repeating the same patch in either operational HTML file would duplicate an existing change; no new defective source fragment has been isolated.

The historical defect is confirmed: the old Parent read model showed only `delivery_agents` records, while Supervisor assignments live on `runsheets.deliverer_id`. The source and Production RPC contract have already been corrected for that distinction.

## 5. Published runtime evidence — fresh inspection

The connected browser tab for [the published Parent page](https://rawaea-erp.pages.dev/companies/company-1/main) currently exposes the old-style «مناديب التوصيل» table and the empty message «لا يوجد مناديب مسجلون», without the separate «تعيينات الرانشيت من مشرف التوصيل» table that exists in current Git source.

The same snapshot also contains the login form with `owner@alrawae.com` prefilled and a blank password field. This means the snapshot is **not sufficient proof of an authenticated E2E**, and it does not identify the exact runtime failure by itself.

Supabase request logs for the live site show authenticated `POST` requests to `delivery_logistics_query` returning HTTP 200 at `2026-10-28T12:29:51.804Z` and `2026-10-28T12:29:57.914Z`. Those log records prove requests succeeded at HTTP level, but do not expose the JSON response body or prove the assignment table rendered.

**Confirmed:** current source contains the table; Production RPC/data contains both assignments; the inspected live page snapshot does not show the table.  
**Unresolved:** whether the discrepancy is caused by an older served artifact, a logged-out/stale DOM, or a client-side render/runtime issue. Do not label it “Cloudflare deployment drift” as confirmed until served-artifact provenance or authenticated browser evidence distinguishes these causes.

## 6. Change decision

- `main.html`: unchanged by this execution.
- `supervisor.html`: unchanged by this execution.
- Supabase schema/data/RPC/ACL/RLS: unchanged by this execution.
- Business/test data: no fixtures created, no existing runsheet changed.
- Inventory/accounting: unchanged.
- This report and the continuity record are documentation-only.

No additional Edge Function or RPC is justified: the existing production contract already returns the assignments. No source replacement block is issued because the intended source repair is already present and no new defective block has been isolated.

## 7. Exact next action to close the remaining runtime gap

Using a normally authenticated session on the published Parent page:

1. Open **إدارة التوصيل والشحن → مناديب التوصيل**.
2. Inspect the Network response for `delivery_logistics_query` with view `agents`; verify whether `runsheet_assignments` contains `RS-1` and `RS-2`.
3. If the response contains both rows but the table is absent, capture the Console exception and compare the served Parent artifact with blob `0c1745081e8d17480433ed527d77cac9f5292021`; repair only the proven client/runtime or deployment defect.
4. If the response omits `runsheet_assignments`, capture the exact request/response and reconcile the invoked RPC signature with the live Production definition.
5. If the served artifact is older, repair/redeploy the Pages deployment from the intended `main` source, then reload and verify the served artifact. The current tool set did not expose a Cloudflare deployment action, so no deployment was claimed or triggered here.
6. Re-run authenticated Parent E2E and verify both assignments render; do not create or modify test records.

## 8. SELF-AUDIT FINAL

- **What I Proved:** the live database contains RS-1 and RS-2 assignments; the Production RPC contract and ACL are correct for this read path; current Git source includes the assignment table; the current browser snapshot lacks that table; live HTTP logs contain successful authenticated RPC requests.
- **What I Did Not Prove:** the exact served artifact SHA, successful authenticated visual rendering, the response body of the live logged requests, or whether deployment drift versus a client/runtime issue is the cause.
- **What I Fixed:** no new operational change; the known source/RPC fix was already present. I added this execution record to prevent repeating the same patch.
- **What I Initially Missed:** HTTP 200 and a correct SQL result do not prove the published UI rendered the result.
- **What Could Still Be Wrong:** stale served artifact, stale/logged-out page state, or a client-side rendering exception.
- **Final Confidence:** high for source and Production data/RPC; low-to-moderate for published runtime.
- **Final Closure Status:** `NOT 100% CLOSED — AUTHENTICATED PUBLISHED UI E2E + RUNTIME ROOT CAUSE OPEN`.
