# Report475 — التقرير التشغيلي الموحد لإصلاح معاينة Picker

مسودة تقرير موحد قيد الاستكمال. هذا الملف لا يعلن إغلاق المهمة.

## 1. الحالة التنفيذية

فُحص المصدر التشغيلي الحالي في مستودع `erp-frontend` والـProduction بقراءة فقط. لا يُعلن إغلاق المهمة قبل تطبيق التغييرات واختبارها والنشر.

## 2. هدف العمل وحدوده

RAWAEA ERP منظومة متكاملة وليست مجموعة شاشات منفصلة. مسار المخازن محل هذه المهمة هو: `Confirmed Orders → Runsheet → Picking/Allocation → Loading → Delivery/Return/Unloading → Stock/Ledger/Audit`. Picker مسؤول عن معاينة الرانشيت، تسجيل الكميات المحضّرة والملاحظات، حفظ مسودة Dexie، ثم استدعاء Edge Functions القائمة لإتمام التحضير. المعاينة نفسها لا يجوز أن تغيّر المخزون أو `allocated_qty` أو القيود المالية.

لماذا نعدل كتلة صغيرة فقط؟ تاريخ Picker يثبت وجود نطاق شركة، تحقق ملكية الجلسة، استعادة Dexie، تحقق الكميات، `operation_id`/Idempotency-Key ومعالجة خطأ نقص المخزون. إعادة كتابة `App.openRunsheet` كاملة قد تفسد هذه الضمانات؛ لذلك تبقى الجلسة النشطة وتدفق العمل كما هما.

## 3. مصادر الحقيقة وبصمات المصدر

المستودع التشغيلي: `papamohammed77-glitch/erp-frontend` على `main`. مستودع `rawaie-erp-New` للحوكمة والتقارير لا يثبت ما يعمل على Cloudflare. تمت قراءة وثيقة الحوكمة كاملة (2606 سطرًا) و`CURRENT_STATE.md` وذاكرة المشروع، والمصدر الكامل الحالي لكل من Loader وPicker، مع مقارنة تاريخية مع PWA القديمة.

| المصدر | البصمة الحالية |
|---|---|
| `companies/company-1/warehouse/loader.html` | `97b83d68a683df77c1e0557838c24a1b4fb65169`, 332 سطرًا |
| `companies/company-1/warehouse/picker.html` | `d483bd15b36585b975b63c2ef641481a01d5d084`, 1058 سطرًا |
| أحدث refactor لمعاينة Loader | commit `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010` |
| Core المشترك | `companies/company-1/core.js`, SHA `ff2f581d9900543c16f7cb026e13446520c0329d` |
| Picker التاريخي | `rawaie-erp-review/PWA/warehouse/picker.html`, SHA `7626ba320021a607854bf219f4bacd81fc3d1d92`, 623 سطرًا |
| Loader التاريخي | `rawaie-erp-review/PWA/warehouse/loader.html`, SHA `7e61b04d0d9a480d43763e8b7b21f9cbed78409a`, 266 سطرًا |

Loader يستورد `core.js` ويستخدم `RW_Auth/RW_UI/RW_API`. Picker لا يستورد النواة حاليًا؛ ينشئ Supabase client مستقلًا، ويتحقق من المستخدم والشركة محليًا، ويستخدم Dexie باسم `RW_Picker`. هذا اختلاف معماري قائم ويجب عدم دمج إصلاحه داخل رقعة العرض.

## 4. عقد Production التي تم التحقق منها

استعلام مباشر بوضع القراءة فقط في Supabase Production `SMART ERP` (`fiilmooggumokxanwiyx`) عند **2026-10-23 12:24:37 UTC**، PostgreSQL 17.6:

- `items` يحتوي `id/company_id/item_code/name/unit/description/image_url`.
- `run_sheet_details` يحتوي `item_id/runsheet_id/item_code/item_name/unit/unit_price/qty_ordered/qty_picked`، ولا يحتوي `description`.
- FK `run_sheet_details_item_id_fkey`: `item_id → items.id`؛ وFK `run_sheet_details_runsheet_id_fkey`: `runsheet_id → runsheets.id`.
- `runsheets.company_id → companies.id`.
- 18 صنفًا، و12 سجل تفاصيل رانشيت؛ حالات الرانشيت التي رجعها استعلام الحالة: `Picked: 2` فقط، ولا توجد `Open/Confirmed` في العينة الحالية.

إذًا وصف الصنف الصحيح يأتي من relation `items!run_sheet_details_item_id_fkey(description)`، وليس من `run_sheet_details.description`. لا تُنشأ حالات اختبار في Production؛ يلزم Staging معتمد لتجربة بدء التحضير.

الوظائف الحالية ذات الصلة كما رجعت من قائمة Production، ACTIVE وJWT verification مفعّل:
- `start-picking` v35، SHA `fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a`.
- `complete-picking` v18، SHA `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`.
- `start-loading` v5، SHA `afcfe32707382c57a15ebb744dec61e95a4079abb9ee8d32f479f322091230c7`.
- `complete-loading` v11، SHA `c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286`.

لم يتم تغيير Schema أو RLS/RPC أو Edge Functions أو بيانات Production.
