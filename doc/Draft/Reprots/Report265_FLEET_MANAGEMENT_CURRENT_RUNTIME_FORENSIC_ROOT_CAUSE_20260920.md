# تقرير 265 — إغلاق جراحي لخطأ Runtime في إدارة الأسطول والحركة
## RAWAEA ERP — Current Production / Current Source / Forensic Closure

التاريخ: 2026-09-20
النطاق: تبويب إدارة الأسطول والحركة فقط
قاعدة التنفيذ: CURRENT GIT → CURRENT SOURCE → CURRENT PRODUCTION → CONTRACT → SURGICAL FIX → VERIFY → STATE UPDATE

---

## 1. الحالة المرجعية الحالية

تمت إعادة التحقيق من المصادر الحالية، ولم تُعامل التقارير السابقة كمصدر للحالة الحالية.

System repository: papamohammed77-glitch/rawaie-erp-New
Latest pre-report commit: fbbe6e64cb8a0a1a9714e7432f7d2746c7bfae42
Parent: 4f4ef5723f1bd4777c850eb9c6bfa69e542d8bb1

Mother repository: papamohammed77-glitch/erp-frontend
Current HEAD: ddcd9995240605dd9bcf31ab1abb1a774b887f84
Parent: 1823f9ab0e6f88c0118585c0b4f50a0b9b36bc38
Current main.html blob: 6074a4fc5f915701b23af5d7b6fca8a083c0a9dd

MASTER CTO GOVERNANCE تمت قراءته من المصدر الحالي. CURRENT_STATE تمت مراجعته، ثم تم تجاوز أي checkpoints قديمة بالحقيقة المثبتة من Git/Source/Production.

---

## 2. Production Reality

Supabase project: fiilmooggumokxanwiyx

السياق الحالي:
- companies = 1
- branches = 2
- items = 17
- main company = 00000000-0000-0000-0000-000000000001
- main branch = a38332b6-6cea-480a-ada1-6eb6ab0590db

Fleet data الحالية:
- vehicles = 0
- fleet_drivers = 0
- fleet_vehicle_assignments = 0
- vehicle_tracking = 0
- fleet_fuel_transactions = 0
- vehicle_maintenance = 0
- fleet_maintenance_plans = 0
- fleet_incidents = 0
- fleet_driver_performance_events = 0
- fleet_expenses = 0

Production RPCs الحالية verified:
- public.fleet_command_atomic
- public.fleet_query

كلتا الدالتين متاحتان لـ authenticated و service_role، وغير متاحتين لـ PUBLIC/anon.

تم استدعاء Fleet views التالية مباشرة من Production بسياق مستخدم مصادق عليه:
- dashboard
- vehicles
- drivers
- trips
- alerts
- costs
- performance

كلها أعادت success=true ولا يوجد Production backend failure مرتبط بخطأ فتح Fleet.

---

## 3. إعادة بناء التاريخ وعدم إعادة ما أُغلق

Report264 أثبت إغلاق Fleet Production Core، ولا توجد حاجة لإعادة إنشاء Vehicle Master أو Runsheet Engine أو Inventory Engine أو Edge Function جديدة.

تم التحقق أن current Mother تحتوي بالفعل على:
- Fleet navigation
- fleet-management route
- RW_FleetManagement module
- Fleet RPC consumer contract

إذن نقطة العمل الحالية ليست بناء Fleet من جديد؛ هي إغلاق آخر defect ظهر عند الاستدعاء الفعلي للـroute.

---

## 4. التحقيق الجنائي في Console Error

الخطأ المبلغ عنه:
RW_Navigation.navigate TypeError: Cannot read properties of undefined (reading 'render')

### Source Trace

في current main.html يوجد:
var RW_FleetManagement = (function() {

وفي router يوجد:
if (view === 'fleet-management') { RW_FleetManagement.render(); return; }

وفي نهاية Fleet IIFE كانت الصيغة:
window.RW_FleetManagement = { ... };
})();

### Root Cause

الدالة IIFE لا تعيد namespace object إلى التعبير:
var RW_FleetManagement = (function(){ ... })();

وبالتالي قيمة المتغير RW_FleetManagement تصبح undefined.

في الوقت نفسه، assignment إلى window.RW_FleetManagement ينشئ object آخر على window.

الـrouter يستخدم RW_FleetManagement.render() مباشرة، وليس window.RW_FleetManagement.render().

إذن الخطأ الناتج مطابق حرفيًا للعقد البرمجي الحالي:
Cannot read properties of undefined (reading 'render')

هذا Root Cause مثبت من current source، وليس استنتاجًا مبنيًا على التقرير القديم.

---

## 5. القرار الجراحي

لا يتم تعديل router.
لا يتم تعديل RPC.
لا يتم تعديل schema.
لا يتم إنشاء Edge Function.
لا يتم لمس main.html من CTO.

التصحيح هو استعادة عقد export الصحيح داخل Fleet IIFE نفسه:

1. إنشاء object محلي api.
2. إسناده إلى window.RW_FleetManagement.
3. إرجاع api من الـIIFE.

النتيجة المطلوبة بعد cutover:
RW_FleetManagement === window.RW_FleetManagement
و
typeof RW_FleetManagement.render === 'function'

---

## 6. التعديل الجراحي الجاهز للمالك

الملف:
erp-frontend/companies/company-1/main.html

ابحث عن نهاية Fleet module مباشرة قبل marker:
// RW_Views – نظام التوجيه النهائي

احذف فقط البلوك القديم الذي يبدأ بـ:
window.RW_FleetManagement={

وينتهي بـ:
})();

واستبدله كاملًا بالنص الموجود في:
Current/PWA/owner-patches/RW_FleetManagement.js

الـcanonical patch أصبح يحتوي tail المصحح.

التعديل الجراحي الفعلي هو:
var api = {
  render: render,
  switchTab: switchTab,
  setSearch: setSearch,
  openVehicleDetail: openVehicleDetail,
  openDriverDetail: openDriverDetail,
  openVehicleForm: openVehicleForm,
  openDriverForm: openDriverForm,
  openOdometerForm: openOdometerForm,
  openFuelForm: openFuelForm,
  openMaintenanceForm: openMaintenanceForm,
  openContractForm: openContractForm,
  openVehicleDocumentForm: openVehicleDocumentForm,
  openIncidentForm: openIncidentForm,
  openExpenseForm: openExpenseForm,
  openDriverDocumentForm: openDriverDocumentForm,
  openPerformanceForm: openPerformanceForm,
  navigateExisting: navigateExisting
};
window.RW_FleetManagement = api;
return api;
})();

لا توجد أي تغييرات أخرى مطلوبة في main.html لهذه المشكلة.

---

## 7. Production action for this exact defect

Production SQL changes = 0.
New Edge Functions = 0.
New RPCs = 0.
Fleet schema changes = 0.

سبب عدم تعديل Production: backend ثبتت سلامته، والخلل في JavaScript module return contract. أي تعديل Database هنا سيكون خارج السبب الجذري.

---

## 8. Competitive verification — Fleet only

المقارنة الحالية تؤكد أن الاتجاه المعماري الذي سبق بناؤه صحيح: Vehicle Master وحده غير كافٍ؛ Fleet المنافسين يربط المركبة بالسائق والخدمة/الصيانة والتكلفة والعداد والعقود والتنبيهات.

Odoo Fleet يضم Vehicle Master وDriver/Service/Cost analysis وOdometer analysis وتنبيه انتهاء العقود. المصادر الرسمية:
https://www.odoo.com/documentation/19.0/applications/hr/fleet/new_vehicle.html
https://www.odoo.com/documentation/19.0/applications/hr/fleet/service.html
https://www.odoo.com/documentation/19.0/applications/hr/fleet/odometers.html

Dynamics 365 Asset Management يعتمد على Maintenance Plans بنمط Time وCounter، ثم يكوّن Work Orders من maintenance schedules ويقيس downtime وavailability وMTBS. المصادر الرسمية:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/asset-management/preventive-and-reactive-maintenance/maintenance-plans
https://learn.microsoft.com/en-us/dynamics365/supply-chain/asset-management/preventive-and-reactive-maintenance/creating-work-orders
https://learn.microsoft.com/en-us/dynamics365/supply-chain/asset-management/work-orders/maintenance-downtime

SAP S/4HANA Maintenance يدعم time-based وperformance-based maintenance plans، ويربطها بقراءات counters/measuring points وبـmaintenance orders أو call objects. المصادر الرسمية:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/c9b5e9de6e674fb99fff88d72c352291/75d28f3290f146a6985d93d35964a1be.html
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e72f747389b340229f7fa343975bfa57/906cb65334e6b54ce10000000a174cb4.html
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/f7d969cde600466b96094e772632c3f3/bfa7ce5314894208e100000000a174cb4.html

Daftra يربط سياراته بالعقود والتكاليف والسائقين والأصول والإهلاك والتقارير، ويعرض maintenance orders/work files في تشغيل الصيانة. المصادر الرسمية:
https://www.daftra.com/en/car-rental/
https://docs.daftra.com/en/user_manual/rental-and-car-management/
https://www.daftra.com/en/maintenance
https://www.daftra.com/en/plans

Manager يتعامل مع المركبات كـFixed Assets مع التكلفة والعمر والإهلاك والتصرف في الأصل. المصادر الرسمية:
https://www2.manager.io/guides/9106
https://www2.manager.io/guides/9119
https://www2.manager.io/guides/9121

---

## 9. Business Contract gaps التي لا يجوز اختراعها

Production أثبتت وجود fixed_assets، لكنه حاليًا = 0 صف. وwork_orders/work_order_details موجودان لكن schema الحالي لا يحتوي company_id أو vehicle_id، لذلك لا يجوز استعمالهما كـFleet work-order engine بدون عقد جديد.

الفجوات التالية لذلك تبقى CONTRACT GAP وليست bugs:
- Vehicle ↔ Fixed Asset lifecycle.
- Maintenance Plan → scheduled Work Order lifecycle.
- Work Order → spare-part issue → post_stock_movement.
- Telematics/GPS event ingestion.
- Scheduled notification delivery.
- True On-Time Delivery KPI يحتاج Scheduled Delivery Date/Time contract.

هذا القرار مقصود لمنع إنشاء جزيرة Fleet أو كسر العمود الفقري التشغيلي للمخزون/الرانشيت.

---

## 10. E2E Verification status

Production backend E2E/read smoke = PASS.
Fleet query views = PASS.
Fleet command/query permissions = PASS.
Fleet data cleanliness after prior E2E = PASS؛ لا توجد بيانات اختبار Fleet باقية.

Browser E2E بعد إصلاح main.html = OPEN.

سبب بقاء Browser E2E مفتوحًا هو أن قاعدة المهمة تمنع CTO من تعديل main.html مباشرة، وليس وجود Backend defect.

---

## 11. Tailwind warning

التحذير الخاص بـ cdn.tailwindcss.com منفصل عن Fleet Root Cause.
لم يتم تعديله لأنه مشكلة build/deployment shell عامة وليست إصلاحًا جراحيًا لـFleet.

---

## 12. Canonical Git changes made by this closure

تم تحديث:
Current/PWA/owner-patches/RW_FleetManagement.js
من أجل إعادة return contract الصحيح.

تم تحديث:
Current/PWA/owner-patches/FLEET_MAIN_HTML_SURGICAL_PATCH.md
ليحتوي current Mother checkpoint وإصلاح الـIIFE exact tail.

تم إنشاء هذا التقرير:
doc/Draft/Reprots/Report265_FLEET_MANAGEMENT_CURRENT_RUNTIME_FORENSIC_ROOT_CAUSE_20260920.md

No main.html edit by CTO.

---

## 13. FINAL SELF-AUDIT

### What I Proved
- Current Mother HEAD and main.html blob were re-verified.
- Fleet module exists in current main.html.
- Fleet router calls the lexical RW_FleetManagement object.
- The Fleet IIFE previously returned undefined.
- Production Fleet RPCs and reads are healthy.
- Production Fleet dataset is clean/empty.
- The reported Console error is fully explained by the IIFE return contract defect.

### What I Fixed
- Corrected canonical Fleet module tail.
- Refreshed the exact Mother surgical patch.
- Recorded current Git/Production evidence in this report.

### What I Did Not Fix
- main.html itself, by explicit task ownership rule.
- Tailwind shell warning.
- Business contracts not supported by current Production evidence.

### Final Status
FLEET PRODUCTION CORE = CLOSED / CURRENTLY VERIFIED
FLEET ROOT CAUSE = PROVEN
FLEET CANONICAL OWNER PATCH = READY
FLEET BROWSER E2E = OPEN UNTIL OWNER CUTOVER
NEW EDGE FUNCTION = 0
PRODUCTION SQL CHANGE FOR ROOT CAUSE = 0

---

## 14. إرشادات المساعد التالي

ابدأ دائمًا بـ CURRENT Git/Source/Production وليس التقرير.
افحص آخر Mother HEAD والـparent ثم blob الحالي لـmain.html.
ابحث عن var RW_FleetManagement = (function() ثم تحقق من return api داخل نفس الـIIFE.
لا تعيد بناء Fleet RPCs.
لا تنشئ Edge Function جديدة.
بعد تطبيق الـowner patch نفذ Browser E2E فقط لـFleet ثم أعد snapshot Production.
بعد إغلاق Browser E2E انتقل إلى أول Business Contract يمكن إثباته من Production، ولا تستخدم competitor parity وحدها كبديل عن contract.