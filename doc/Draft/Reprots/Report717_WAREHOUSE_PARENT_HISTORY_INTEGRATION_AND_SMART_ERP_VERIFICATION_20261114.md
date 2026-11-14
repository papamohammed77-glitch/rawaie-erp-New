# Report717 — تكامل سجل العمليات في النظام الأم مع المخزن الشامل والتحقق من SMART ERP
**التاريخ:** 2026-11-14 (Africa/Cairo)  
**Last Verified Event:** LVE-2026-11-14-717  
**الحكم:** READY WITH LIMITATIONS — إصلاحات المصدر وعقود القراءة وCI مثبتة؛ نشر أحدث المصدر على Cloudflare وProduction authenticated runtime لم يثبتا بعد.

## 1. نطاق المهمة والحوكمة
استئناف من LVE-2026-11-13-716 دون إعادة البدء. تمت قراءة CURRENT_STATE.md والدستور التشغيلي وملف writing-block-8888-10.md ومراجعة تقارير 712–716، ثم مطابقة الادعاءات مع المصدر الحي وSMART ERP.

- مستودع التشغيل: `papamohammed77-glitch/erp-frontend`، فرع `main`.
- مستودع الحالة والتقارير: `papamohammed77-glitch/rawaie-erp-New`، فرع `main`.
- Supabase الوحيد المستخدم: SMART ERP، project ref `fiilmooggumokxanwiyx`.
- لم يُنشأ مستودع أو فرع اختبار، ولم يُستخدم مشروع Supabase آخر.
- لم تُنفذ أي عملية استلام أو تحضير أو تحميل أو تفريغ أو مرتجع أو جرد أو إذن مخزني حقيقي في قاعدة الإنتاج.
- لم تُنشأ QA rows في جداول الأعمال. التغيير الوحيد في قاعدة البيانات كان تعديل دالتين/نسختين متتاليتين من RPC للقراءة وإظهار أسماء منفذي العمل؛ لا DML ولا حركات مخزون أو مالية.

## 2. نقطة المصدر الحية وسلسلة التغييرات
- Operational HEAD النهائي الذي اجتاز CI: `65596ceecaa30fcca99fb1c9c327507f075c2242`.
- Parent source: `companies/company-1/main.html`، blob `a499277ff6899d6bf759ade13db6d47926ae6817`.
- Warehouse Hub: `companies/company-1/warehouse/warehouse.html`، blob `a8ae55793beac95f1dd34f6fd8646d3995eb1b40`.
- أحدث تغييرات التكامل في Parent بدأت من `ac51d837c0a2bc8a0449f0edf0f809f05a7024e5`، ثم actor lookup وواجهة المرتجع، ثم سجل التحضير/التحميل، وأهلية التفريغ.
- لا تعديل على `core.js` أو `warehouse.html` في هذه الحزمة؛ واجهة المخزن الموحّد كانت تستخدم الحزم الأصلية Native Bundles بالفعل، بينما الإصلاحات الأمومية المطلوبة كانت في `main.html`.

## 3. الإصلاحات المنفذة في النظام الأم
كل الإضافات داخل التبويب الأمومي القائم؛ لم تُنشأ تبويبات جديدة:

### 3.1 التحضير — Picker
- أضيف سجل عمليات تحضير مكتملة داخل تبويب التحضير نفسه.
- مصدر السجل: `erp_operation_registry`، النوع `complete_runsheet_picking`، الحالة `completed`، مع قيد `company_id`.
- يعرض رقم الرانشيت ووقت الإتمام وبريد المنفذ وإجمالي `picked_qty` وعدد الأصناف.
- يحتفظ بسجل كل دورة إتمام، حتى إذا تغيرت حالة الرانشيت لاحقًا إلى Delivered أو Returned.
- تمت إضافة تحديث Realtime للسجل عند اكتمال حدث تحضير جديد، مع إعادة تطبيق مرشح رقم الرانشيت.

### 3.2 التحميل — Loader
- أضيف سجل عمليات تحميل مكتملة داخل تبويب التحميل نفسه.
- مصدر السجل: `erp_operation_registry`، النوع `complete_runsheet_loading`، الحالة `completed`، مع قيد الشركة.
- يعرض رقم الرانشيت ووقت الإتمام والمنفذ وإجمالي `loaded_total` وعدد الأصناف.
- لا يعتمد السجل التاريخي على بقاء `runsheets.status='Loaded'`؛ لذلك لا تختفي دورة التحميل بعد التفريغ أو التسليم أو الإرجاع.
- استبدل الاستعلام المباشر عن `users` في Parent باستدعاء RPC محكوم للصلاحيات لإظهار اسم مسؤول التحميل، بدل الاعتماد على سياسة قراءة جدول المستخدمين.

### 3.3 المرتجعات — Returns
- أضيف عنوان عمود واضح «مسؤول المرتجع» بما يطابق الخلية السادسة التي يعرضها الصف.
- أصبح إظهار اسم مسؤول المرتجع يعتمد على RPC الشركة/الصلاحية المشترك، لا على قراءة مباشرة لجدول `users` قد تمنعها RLS.
- سجل `complete_return` الحالي لا يحتوي في `request_payload` على runsheet_code أو هوية المنفذ؛ لذلك يظل Parent Returns معتمدًا على سجل الرانشيت و`return_handler_id`، ولا ندعي أن تاريخ كل دورة مرتجع منفصلًا أصبح كاملًا.

### 3.4 التفريغ — Unloader
- سجل التفريغ المكتمل داخل تبويب التفريغ الأمومي يقرأ `erp_operation_registry` من النوع `complete_runsheet_unloading`، بدل افتراض وجود سند `stock_vouchers`.
- يعرض الرانشيت ووقت الإتمام وبريد المنفذ وكمية التفريغ.
- أُضيف اشتراك Realtime مقيد بالشركة.
- طابور التفريغ الأمومي أصبح يطابق عقد RPC المركزي حرفيًا: `status='Loaded'` **و** `loading_cycle_id IS NOT NULL`. لا يظهر الرانشيت الذي لا يملك دورة تحميل صالحة.
- لا توجد حاليًا أحداث تفريغ مكتملة في SMART ERP؛ لذلك اختبار العرض لهذا النوع في CI اصطناعي وليس واقعة إنتاج حقيقية.

### 3.5 الأذونات والجرد والاستلام
- Parent Vouchers يعرض `created_by` ضمن سجل الأذونات.
- Parent Inventory Counts يعرض `created_by` في سجل جلسات الجرد.
- Parent Receiving يستمر في القراءة من `receiving` و`receiving_details`، ويعرض المسؤول/المستند/أوقات الاستلام وفق حقول المصدر.
- لم تُنشأ أي جداول موازية للمخزن الشامل. كل العمليات تستمر في استخدام جداولها وعقودها المركزية الحالية.

## 4. تعديل RPC لإظهار هوية منفذ العملية
تم تطبيق نسختين متتاليتين على SMART ERP وتوثيقهما في migrations:

1. `20261114130015_warehouse_return_handler_display_users_20261114`: توسيع علاقة المستخدمين المسموح بعرض بياناتهم لتشمل `return_handler_id` بجانب `picker_id`.
2. `20261114130048_warehouse_operation_actor_display_users_20261114`: إضافة `loader_id` إلى نفس العلاقة.

الدالة الحالية `public.get_picking_display_users(uuid[])` ما زالت تحافظ على:
- `SECURITY DEFINER` و`search_path TO ''`.
- شرط وجود `auth.uid()`.
- الحصول على الشركة من `app_private.current_user_company_id()`.
- السماح فقط عند وجود `warehouse` أو `runsheets` effective permission.
- حد أقصى 500 معرف.
- حصر المستخدم والرانشيت في الشركة نفسها.
- عدم منح `anon` صلاحية EXECUTE؛ `authenticated` يحتفظ بالصلاحية السابقة.

اختبار قراءة RPC نُفذ تحت role authenticated مع هوية مستخدم مخزن فعلية داخل معاملة `BEGIN/ROLLBACK`، وأعاد سجلات منفذي التحضير/التحميل/المرتجع. لا يغير هذا الاختبار بيانات الأعمال.

## 5. مطابقة المخزن الشامل مع التطبيقات الأصلية
المصدر الحي لـ`warehouse.html` يحتوي حزمًا Native للتطبيقات الأصلية: Receiver وPicker وLoader وReturns وUnloader وCounter وVouchers. لا يوجد iframe/srcdoc. ويستمر استخدام `../core.js` داخل Hub. التبويبات العليا ما زالت اليوم، العمليات، الأذونات، حسابي.

CI الحالي يؤكد ست مساحات تشغيل مخزنية كاملة، وسبعة إجراءات أذونات يدوية، وثلاثة أنماط للجرد، والاستلام من PO وQuick Market، وإيصال الفرع بمصدر فرع قابل للاختيار ووجهة ثابتة لفرع المستخدم. لا يوجد تبويب جديد خاص بالمخزن الشامل.

## 6. أدلة SMART ERP Production — قراءة فقط
لقطة ما بعد التعديلات:
| الجدول | عدد السجلات |
|---|---:|
| receiving | 4 |
| receiving_details | 7 |
| runsheets | 4 |
| run_sheet_details | 19 |
| stock_vouchers | 0 |
| stock_voucher_details | 0 |
| inventory_counts | 1 |
| inventory_count_details | 35 |
| inventory_log | 83 |
| erp_operation_registry | 98 |

- `complete_runsheet_picking`: أربعة أحداث مكتملة.
- `complete_runsheet_loading`: خمسة أحداث مكتملة.
- `complete_return`: أربعة أحداث مكتملة.
- `complete_runsheet_unloading`: صفر أحداث مكتملة.
- `runsheets.status='Loaded'`: صفر حاليًا.
- `runsheets.status='Picked'`: صفر حاليًا.
- جلسة الجرد ذات 35 تفصيلة بقيت كما هي ولم تُستخدم للاختبار.
- أعداد الجداول قبل تعديل RPC وبعده متطابقة في اللقطة المتاحة؛ لا يوجد دليل على DML أو حركة مخزون/خزينة/محاسبة نتيجة هذا العمل.

## 7. نتائج CI / E2E
<badge>SUCCESS</badge> Warehouse CI Run `43598314439` على HEAD `65596ce`:
- Unit tests وStatic source/module contract: SUCCESS.
- Browser E2E — ست مساحات تشغيل مخزنية وسبعة إجراءات أذونات: SUCCESS.
- Parent warehouse history Browser E2E: SUCCESS.
- اختبارات سجل التحضير والتحميل والتفريغ، فلاتر الشركة، Realtime، إسناد منفذ المرتجع، منشئ الأذونات والجرد، وعدم تنفيذ أي data writes: SUCCESS.
- اختبار طابور التفريغ يرفض الرانشيت الذي لا يملك `loading_cycle_id`: SUCCESS.
- اختبار الصور يستخدم Fixtures وصورًا اصطناعية وفشل صورة متعمدًا لاختبار fallback؛ لا يثبت HTTP status أو naturalWidth لروابط Production الحقيقية.
- Mother System Browser E2E Run `43598190657`: SUCCESS.
- Mother Inventory Forensic E2E Run `43598190590`: SUCCESS.
- Mother Assembly Guard Run `43598314398`: SUCCESS.

هذه اختبارات متصفح محلية بمصادر/Mocks اصطناعية. لا تُعد Production authenticated E2E، ولا تنفذ RPCs حركات مخزنية فعلية.

## 8. النشر وRuntime
- Cloudflare Pages project `rawaea-erp` مربوط بالنطاق `rawaea-erp.pages.dev`.
- أحدث deployment ظاهر في Cloudflare dashboard وقت الفحص هو commit `206b363ac3f7c82053b1979f626cabbb7ff6ebb3` مع Preview `https://71c4933f.rawaea-erp.pages.dev`.
- هذا النشر يتضمن تغييرات أقدم من الحزمة الحالية؛ لا يوجد deployment مثبت على HEAD `65596ce` أو على تغييرات Parent history الأخيرة. لا أصف أحدث كود بأنه منشور.
- فتح Preview عبر Web أعاد أن الرابط غير متاح عبر أداة الويب. المتصفح المتصل يعرض صفحة دخول وليس جلسة Production مصادقًا عليها.
- لذلك Cloudflare artifact parity، Production alias parity، وAuthenticated Parent/Hub runtime ما زالت UNVERIFIED.

## 9. فجوة معمارية لم تُخفَ
- `warehouse.html` يحمل `core.js` ويستخدم الحزم الأصلية.
- `main.html` ما زال ينشئ Supabase client وRW_Auth/Realtime محليًا ولا يحمل `core.js`.
- هذا اختلاف حقيقي بين هدف القلب المركزي والتنفيذ الأمومي الحالي. لم أحقن `core.js` في `main.html`؛ ذلك قد ينشئ عميلين أو يتعارض مع auth/session globals في ملف أمومي كبير، ويحتاج خريطة اعتماديات منفصلة قبل تغييره.
- `warehouse.html` ما زال يحمل Tailwind CDN؛ تحذير CDN لا يثبت عطلًا وظيفيًا، لكنه دين تقني إنتاجي يحتاج حزمة أصول منفصلة.

## 10. Benchmark معماري مختصر
- Odoo يعرّف أنواع عمليات منفصلة للاستلام والتحضير والتسليم والتحويل، مع تتبع الحركات المنظمة: https://www.odoo.com/documentation/20.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/operation_type.html
- Dynamics 365 يميز بين Warehouse transactions وInventory transactions، ويعرض معاملات العمل المخزني إلى جانب حركات المخزون: https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/warehouse-transactions
- SAP EWM يستخدم Warehouse Tasks لتوثيق التحضير والتخزين والتحويل والاستلام والصرف مع تفاصيل المستند والمنتج والكمية: https://help.sap.com/docs/SAP_SUPPLY_CHAIN_MANAGEMENT/ce32eae1b3db423fb4625f3d692cae6f/8fcccb53ad377114e10000000a174cb4.html
- ERPNext يحتفظ بـStock Ledger كسجل تفصيلي للحركات ويربطه بالمستند المصدر: https://docs.frappe.io/erpnext/stock-ledger

الاستنتاج التطبيقي: فصل سجل الحدث التاريخي عن الحالة الراهنة للرانشيت، مع إبقاء كل أثر مخزني في المحرك/دفتر الحركة المركزي، هو الاتجاه الصحيح. لا يجوز إنشاء سجل رصيد ثانٍ للمخزن الشامل.

## 11. ما بقي مفتوحًا
1. نشر HEAD `65596ce` على Cloudflare Pages والتحقق من الـProduction alias والـartifact الفعلي.
2. جلسة Browser مصادق عليها للتحقق بصريًا من ظهور Parent histories واسم المنفذ والصور الحقيقية.
3. قياس HTTP status و`naturalWidth` لصور Picker/Loader/Returns الحقيقية.
4. استكمال تصميم دمج Parent مع `core.js` دون ازدواج auth/client.
5. تحسين عقد `complete_return` مستقبلًا ليحمل runsheet_code وهوية المنفذ داخل event metadata؛ لا يمكن بناء سجل تاريخي متعدد الدورات بدقة من payload الحالي وحده.
6. إزالة Tailwind CDN من حزمة الأصول بعد قياس تأثيره وتغطية الواجهات.
7. لا يُختبر التفريغ أو التحميل أو الجرد أو الإتلاف أو التسوية عبر معاملات Production اصطناعية؛ جميعها قد تنشئ أثرًا فعليًا.

## 12. الملفات ومواقع التغيير
- Runtime Parent: `companies/company-1/main.html` — داخل مجلد الشركة المنشور.
- Hub: `companies/company-1/warehouse/warehouse.html` — لم يُعدل في هذه الحزمة.
- CI-only test helper: `scripts/warehouse-parent-unloading-history.e2e.mjs` — خارج مجلد الشركة، ليس جزءًا من التطبيق المنشور.
- DB migrations: `supabase/migrations/20261114130015_...` و`20261114130048_...` — خارج مجلد الشركة بحكم كونها سجل مصدر لعقود قاعدة البيانات، وليست ملفات واجهة منشورة.
- CI workflow: `.github/workflows/warehouse_hub_browser_e2e_20261110.yml` — تشغيل اختبارات فقط.
- `_forensic_current_main_extract.md` ملف مساعد آلي في جذر المستودع، ليس ملف Runtime؛ لم يُحذف لأنه ينتج من Workflow قائم.

**القرار النهائي:** Source + DB read contract + CI = CONFIRMED. Production business data unchanged = CONFIRMED. Latest Cloudflare deployment/runtime = UNVERIFIED. Overall READY WITH LIMITATIONS, وليس إغلاقًا نهائيًا قبل النشر وفحص جلسة Production مصادق عليها.
