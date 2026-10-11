# CURRENT FORENSIC CHECKPOINT — 2026-10-11 — Report417 Live Parent Orders Forensic Patch

## Current scope
Only the parent system's sales-orders table: `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`, module `RW_Orders`. Owner applies parent UI changes. Assistant must not edit `main.html` or the operational app. Production/Supabase changes are assistant-owned only when fresh evidence proves a defect.

## Latest execution record
- Latest report: [Report417_PARENT_ORDERS_LIVE_SOURCE_FORENSIC_AND_OWNER_PATCH_20261011.md](doc/Draft/Reprots/Report417_PARENT_ORDERS_LIVE_SOURCE_FORENSIC_AND_OWNER_PATCH_20261011.md).
- Prior checkpoint: [Report416_PARENT_ORDERS_CURRENT_SOURCE_AND_PRODUCTION_RECHECK_20261011.md](doc/Draft/Reprots/Report416_PARENT_ORDERS_CURRENT_SOURCE_AND_PRODUCTION_RECHECK_20261011.md).
- Report commit: `726ffd2c3bc2ae01e70e20badb0b44f0a664a8dc` (file blob SHA; use report link for content).
- Previous evidence: [Report415](doc/Draft/Reprots/Report415_PARENT_ORDERS_FRESH_PRODUCTION_AND_SURGICAL_PATCH_20261011.md), [Report414](doc/Draft/Reprots/Report414_PARENT_ORDERS_LIVE_RESYNC_AND_RLS_AUDIT_20261011.md), [Report413](doc/Draft/Reprots/Report413_PARENT_ORDERS_RETURN_RUNSHEET_SOURCE_INTEGRATION_20261011.md), [Report408](doc/Draft/Reprots/Report408_POS_RETURN_STATE_DETAILS_AND_OWNER_CHANGESET_20261011.md).
- Master governance: [MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS](doc/Draft/Reprots/MASTER%20CTO%20GOVERNANCE%20%26%20CONTINUOUS%20EXECUTION%20OS%20%E2%80%94%20RAWAEA%20ERP.md).

## Fresh Production facts — 2026-10-11 16:34 UTC
- `ORD-1006`: source=`pos`, created_by=`cashier@rawaea.com`, created_at=`2026-10-11 07:31:00.768458+00`, status=`Partially Returned`, current/original totals=`135.00/185.00`, `runsheet_id=NULL`.
- Two detail rows: item `1001` qty 1 / returned 1 / reason `مرتجع نقطة بيع`; item `1003` qty 1 / returned 0. Remaining quantity=1 and remaining detail-line count=1. No business rows changed.
- Production RPCs `create_runsheet_atomic` and `append_orders_to_runsheet_atomic` reject sources outside normalized `telesales/tele-sales/order-taker/online-store`; `pos` and blank/unknown sources are rejected. ACL: anon=false, authenticated=false, service_role=true. No new Production SQL/Edge change justified.
- RLS `users_select_company` permits cross-user lookup only to users with `users` permission (plus self row). UI must fall back to `created_by`; do not broaden RLS to display names.
- Supabase has no development branches. No Production fixture created and no production data mutated.

## Current source/provenance constraint
- `fetch_file` يعيد محتوى فارغًا للملف الأم، لكن `fetch_blob` للـSHA نفسه أعاد المصدر الكامل: 1,756,169 حرفًا / 32,363 سطرًا. تمت قراءة مقاطع `RW_Orders` الحية وتثبيت أرقام الأسطر في Report417.
- مصدر الملف الحي الحالي: `erp-frontend/companies/company-1/main.html`, blob `4f94f9c6ebdde1b59632384628c72767d3bb950d`.
- Snapshot `rawaie-erp-New/Current/PWA/main.html` (blob `27b777528665dcc985809648f006452c861ae36e`) تاريخي فقط. لا تستخدم أرقام snapshot القديمة بدل أرقام المصدر الحي المثبتة في Report417.

## Owner surgical patch
اتبع Report417، لأنه يستند إلى blob الحي الحالي ويعطي مواضع الأسطر الدقيقة:
1. 10255: استثناء checkboxes المعطلة من `check-all`.
2. 10257–10264: عرض وقت الإنشاء والمصدر والمنشئ؛ العدد يصبح 11 عمودًا.
3. 10290–10305: عدّ التفاصيل التي لها كمية متبقية فقط.
4. 10444–10491: استبدال `_renderTable(data)` كاملة؛ تعطيل POS/المصدر غير المؤهل للرانشيت.
5. 10631–10636: استبدال إعادة العد بعد التأكيد بإعادة تحميل مشتقات الأوردر.
6. 10661–10767: استبدال `_showDetails(code)` كاملة لعرض الأصلي/المرتجع/المتبقي والأصل/النهائي.
7. 10800–10844: استبدال `_buildPrintWindow(order,items,settings)` كاملة مع الحفاظ على الإجمالي النهائي من `orders.total_amount`.
8. 10969–10994: استبدال `_refreshData()` كاملة كي لا يعود عدّ السطور المرتجعة بعد Realtime.
- لا يوجد `loadData()` أو `refreshRealtimeChannel()` منفصل داخل `RW_Orders` الحية؛ لا تطبق تواقيع snapshot القديمة.
- الحارس المركزي Production صحيح بالفعل؛ لا تعدّل RPC/ACL أو تنشئ Edge جديدة دون Defect جديد مثبت.

## Closure status
`PRODUCTION CORE VERIFIED / LIVE SOURCE AND LINE MAP VERIFIED / OWNER PATCH PREPARED / OWNER MERGE + FRONTEND DEPLOYMENT + AUTHENTICATED BROWSER E2E + PRINT OPEN / NOT CLOSED`.

## Next exact resumption point
المالك يطبق عناصر A–H من Report417 على `erp-frontend/companies/company-1/main.html` الحالي بعد مطابقة SHA `4f94f9c6ebdde1b59632384628c72767d3bb950d`، ثم ينشر ويثبت SHA الملف المخدوم، ويختبر الجدول/التفاصيل/الطباعة/Realtime واختيار المصادر المؤهلة وغير المؤهلة. لا تغيير Production مطلوب حاليًا؛ لا تنشئ fixture في Production. أبقِ التقارير السابقة في التاريخ ولا تعد تنفيذ ما تم إصلاحه.
