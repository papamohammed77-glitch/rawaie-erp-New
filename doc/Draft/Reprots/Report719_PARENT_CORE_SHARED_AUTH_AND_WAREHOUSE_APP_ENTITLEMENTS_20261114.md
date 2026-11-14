# Report719 — توحيد صلاحيات تطبيقات المخازن وربط Parent بـCore.js
**التاريخ:** 2026-11-14 (Africa/Cairo)  
**Last Verified Event:** LVE-2026-11-14-719  
**Operational HEAD:** `d7caf2eafd37ecc7777ccd6aa37856c7918b02dd`  
**Deployment:** Cloudflare Pages Production / `main` / `d7caf2e`  
**الحكم:** SOURCE + CI + CLOUDFLARE DEPLOYMENT = CONFIRMED؛ authenticated live account acceptance = UNVERIFIED؛ READY WITH LIMITATIONS.

## 1. الهدف ونقطة الاستئناف

استكمال LVE-718 دون إعادة البدء. نطاق هذه الدورة أربع فجوات مترابطة:

1. فصل إذن دخول المخزن الشامل إلى `warehouse.html` عن أذونات التطبيقات المخزنية المستقلة.
2. إدخال Picker المستقل في جلسة وعميل وRealtime القلب المشترك Core.js، دون عميل Supabase أو جلسة مستقلة.
3. إعادة مطابقة استلام Receiver والمخزن الشامل مع جداول SMART ERP وسجل Parent.
4. ربط Parent `main.html` بالقلب المشترك بأقل نقطة تغيير، دون إعادة كتابة مسارات المصادقة أو استبدال قنوات Realtime الأخرى.

المصدر التشغيلي الوحيد: `papamohammed77-glitch/erp-frontend`، فرع `main`.  
قاعدة البيانات الوحيدة: SMART ERP، project ref `fiilmooggumokxanwiyx`.  
مستودع التقارير: `papamohammed77-glitch/rawaie-erp-New`، فرع `main`.

## 2. التصحيح المعماري الحاكم للصلاحيات

كان الخطأ في قراءة سابقة هو اعتبار active warehouse role = `مخزن شامل` سببًا كافيًا لدخول كل التطبيقات الأصلية. هذا غير صحيح.

**العقد الذي تم تثبيته في المصدر:**

- `warehouse.html` وحده هو التطبيق الموحد الذي يقبل دور `مخزن شامل` بعد التحقق من هوية المستخدم وملف الشركة ونطاق الفروع عبر `get_warehouse_hub_snapshot`.
- التطبيقات المستقلة لا تعتبر `مخزن شامل` وحده إذنًا عامًا. لكل تطبيق دوره التشغيلي المخصص أو مفتاح الإذن المحدد الممنوح من النظام الأم.
- المالك الموثق يظل مستثنى وفق قواعد Core الحالية.
- مشرف المخازن/مدير المخازن لا يحصل على أي دخول لمجرد اسم الدور. يسمح له التطبيق فقط عندما يحمل ملفه الفعّال المفتاح الخاص بذلك التطبيق.
- لا يُعد تعديل حساب أو أذونات المستخدم ضمن هذه الدورة؛ لم تتغير بيانات users أو roles أو role_permissions.

| التطبيق المستقل | الدور التشغيلي المقبول | مفتاح Parent الفعّال البديل |
|---|---|---|
| Picker / التحضير | تحضير | `picking` |
| Receiver / الاستلام | استلام | `receiving` |
| Loader / التحميل | تحميل | `loading` |
| Returns / المرتجعات | مرتجعات | `return` |
| Unloader / التفريغ | تفريغ | `unloading` |
| Counter / الجرد | جرد | أحد `vehicle-count` أو `branch-count` أو `general-count` |
| Vouchers / الأذونات | أذونات | `vouchers` |

### مطابقة الأذونات الفعلية في SMART ERP

الاستعلامات كانت SELECT فقط، وقرأت `public.users.permissions` و`roles` و`role_permissions`:

- `storekeeper@rawaea.com`: الدور الوظيفي أمين مخزن، الدور النشط مخزن شامل، والصلاحيات الحالية `[warehouse]`. لذلك حقه هو تطبيق المخزن الشامل؛ لا يملك مفاتيح دخول مستقلة لبقية التطبيقات.
- `picker@rawaea.com`: الدور النشط تحضير؛ يظل صالحًا لتطبيق Picker.
- `receiver@rawaea.com`: الدور النشط استلام؛ يظل صالحًا لتطبيق Receiver.
- `loader@rawaea.com`: الدور النشط تحميل؛ يظل صالحًا لتطبيق Loader.
- `returns@rawaea.com`: الدور النشط مرتجعات؛ يظل صالحًا لتطبيق Returns.
- `warehouse.supervisor@rawaea.com`: ملفه يتضمن مفاتيح العمليات المستقلة، ومنها `picking`, `receiving`, `loading`, `return`, `unloading`, `vouchers` ومفاتيح الجرد الثلاثة. دخوله ينتج عن هذه المفاتيح الصريحة، لا عن لقب «مشرف مخازن».
- `warehouse.manager@rawaea.com`: ملفه يتضمن أيضًا مفاتيح تطبيقات مستقلة صريحة.

**الحالة:** CONFIRMED من المصدر وقيم SMART ERP الحالية. لم يحدث أي توسيع صلاحيات في قاعدة البيانات.

## 3. إصلاح Picker المستقل وربطه بـCore.js

الملف: `companies/company-1/warehouse/picker.html`  
Blob: `d1baa1ea7caebf515d4e750b1b4be78a698949f6`

التغييرات الجراحية:

- تحميل `../core.js` قبل التطبيق.
- حذف إنشاء Supabase client المحلي من Picker؛ واستخدام `window.RW_SHARED_SUPABASE` الذي يقدمه Core.
- تمرير تسجيل الدخول واستعادة الجلسة والخروج عبر `RW_Auth.doLogin` و`RW_Auth.init` و`RW_Auth.doLogout`.
- بوابة Picker تتحقق من الدور النشط «تحضير» أو `RW_Auth.checkPermission('picking')` أو المالك الموثق. لا تمنح «مخزن شامل» وحدها الدخول إلى Picker المستقل.
- تشغيل `RW_Realtime.start` بمعرف `warehouse-picker` وجداول `runsheets` و`run_sheet_details` و`erp_operation_registry` و`items`، مع نطاق الشركة.
- أحداث الأصناف تعيد بناء Cache الصور. أحداث الرانشيت والسجل تحدث التبويب الحالي. إذا كان هناك Picking Session مفتوح، يتم تعليم الحالة أنها تحتاج Refresh بعد اكتمال الجلسة، ولا يُعاد رسم شاشة العمل أو إسقاط حالة العامل وسط التنفيذ.
- إيقاف قناة Picker عند الخروج لمنع تسرب الاشتراكات.

لم تُعد كتابة محرك التحضير أو قواعد الكميات أو الصور أو إجراءات بدء/إكمال التحضير.

## 4. بوابات الدخول للتطبيقات الأصلية المستقلة

تم تعديل أضيق شرط دخول داخل كل ملف، مع الحفاظ على بقية دورة العمل:

| الملف | التعديل |
|---|---|
| `warehouse/picker.html` | Core Auth + `picking` |
| `warehouse/receiver.html` | الدور «استلام» أو `receiving` في مساري الدخول/استعادة الجلسة |
| `warehouse/loader.html` | الدور «تحميل» أو `loading` |
| `warehouse/returns.html` | الدور «مرتجعات» أو `return` |
| `warehouse/unloader.html` | الدور «تفريغ» أو `unloading` |
| `warehouse/counter.html` | الدور «جرد» أو أحد مفاتيح أنواع الجرد الثلاثة |
| `warehouse/vouchers.html` | الدور «أذونات» أو `vouchers` |

لم تتغير حزم التطبيقات الأصلية المضمنة داخل `warehouse.html`، ولم يتغير Hub snapshot أو نطاق الفروع أو آليات تسجيل العمليات. تبقى قاعدة `مخزن شامل` في Hub وحده، بينما التطبيقات المستقلة تخضع لإذنها المحدد.

## 5. ربط النظام الأم بـCore.js دون إنشاء عميل أو جلسة ثانية

الملفات:

- `companies/company-1/main.html` — blob `e6d7a835f4e43b810e8c93c818d45880f5396c1e`.
- `companies/company-1/core.js` — blob `2b2211a3f95049042e27a7b2ecbab3640a584942`.

التنفيذ:

1. أضيف bootstrap صغير بعد تحميل Supabase SDK وقبل `core.js`. ينشئ عميلًا واحدًا بإعدادات الجلسة الأصلية للنظام الأم ويضعه في `window.RW_SUPABASE_CLIENT` و`window.RW_SHARED_SUPABASE`.
2. أضيف إلى Core شرط إعادة استخدام `window.RW_SUPABASE_CLIENT` إذا كان موجودًا وصالحًا؛ في هذه الحالة لا ينشئ Core عميلًا ثانيًا.
3. مصنع العميل داخل Parent يعيد استخدام العميل نفسه، ويوقف التهيئة بأمان إذا لم يكن bootstrap موجودًا، بدل إنشاء عميل احتياطي ثانٍ.
4. تمت إضافة `_ensureParentCoreRealtime(companyId)` وقناة واحدة من Core باسم `parent-warehouse-history` على `erp_operation_registry` مع فلتر الشركة.
5. تستخدم القناة تحديثات السجل الحالي فقط في تبويبات Parent: Picking وLoading وUnloading. يتم استدعاء Render/Refresh القائم فقط عندما يكون تبويب العملية ظاهرًا، مع الحفاظ على الفلاتر وحالة التبويب. يمنع مدير القناة التكرار ويوقفها عند تغير الشركة.
6. تم تجاوز الاشتراك المحلي السابق فقط في مستمعي Parent الخاصين بسجل Picking/Loading ومستمع Unloading. بقية اشتراكات Parent لم تتغير.

**حدود الدمج:** Parent يحمل الآن Core ويشاركه عميل Supabase واحد، كما أن سجل العمليات الثلاثة يمر عبر RW_Realtime. لم أستبدل كل طبقة مصادقة Parent المحلية بـ`RW_Auth` ولم أغيّر دورة boot/login/permissions العامة؛ ما زالت واجهة Parent المحلية مسؤولة عن عرض الحالة والتوجيه، ويستخدم Core التحقق المستقل من الملف الفعّال عند تأسيس قناته. هذا قرار مقصود لتجنب استبدال نظام المصادقة بالكامل في ملف Parent ضخم وحساس في خطوة واحدة. لا يوجد عميل ثانٍ أو مخزن جلسة Supabase منفصل، لكن توحيد واجهة المصادقة على مستوى كل Parent لا يزال Closure Unit مستقلة بعد فحص اعتمادياتها.

**الاشتراكات التي لم تُنقل:** كل قنوات Parent الأخرى ظلت كما هي. لا إعادة كتابة لكل قنوات Realtime دفعة واحدة.

## 6. حالة الاستلام Receiver والنظام الأم

تمت إعادة قراءة المصدر والاستعلام عن SMART ERP بعد تعديلات المصدر:

- `public.receiving` = 4 رؤوس.
- `public.receiving_details` = 7 تفاصيل.
- أحدث سجل: 12 نوفمبر 2026، `PINV-1002`، المسؤول `receiver@rawaea.com`، الحالة مكتمل.
- سجل آخر: 11 نوفمبر 2026، `PINV-1003`، المسؤول `storekeeper@rawaea.com`، الحالة مكتمل.
- يوجد أيضًا سجل 11 نوفمبر `PINV-1002` للمستخدم `receiver@rawaea.com` وسجل 9 نوفمبر `PO-20260928`.

Parent `loadReceiving()` يقرأ رؤوس `receiving` وتفاصيل `receiving_details` بحسب `operation_id`، ويعرض `responsible` في عمود المسؤول. اختبارات Browser بالمحاكاة تؤكد ظهور المستند والتفاصيل واسم المنشئ في تبويب الاستلام القائم، وعدم إنشاء صفوف جديدة أثناء الاختبار.

**حد Realtime:** جدولا `receiving` و`receiving_details` غير موجودين في `supabase_realtime` publication في لقطة الإنتاج. لذلك ظهور البيانات عند فتح/إعادة تحميل تبويب الاستلام مؤكد من المصدر والبيانات والاختبار، لكن وصول حدث Postgres Changes فوري من الجدولين غير متاح حاليًا. لم أضفهما إلى publication أو أغيّر replica identity/RLS أو إعدادات قاعدة البيانات؛ هذه خطوة تتطلب ChangeSet ومراجعة أمنية مستقلة.

## 7. اختبارات القبول

### Warehouse E2E
- Run `43605817668`: **SUCCESS** على مصدر `b212c3759b095573d2c4ccb93bafdedb623048b8`.
- `WAREHOUSE_SEVEN_STANDALONE_PARENT_APP_ENTITLEMENTS=PASS`.
- `STANDALONE_PICKER_CORE_REALTIME_AND_PARENT_PERMISSION_BOUNDARY=PASS`.
- `PARENT_RECEIVING_DOCUMENT_ACTOR_AND_DETAILS=PASS`.
- `PARENT_ALL_ADDED_PARENT_TAB_TESTS_NO_DATA_WRITES=PASS`.
- اجتازت الاختبارات المتبقية: حساب الهوية المشتركة، الوحدات الأصلية السبعة، مساحات العمل، الأذونات السبعة، الصور، preflight الكميات، سجلات العمليات وتفريغ Parent.

### Parent Core bridge Browser E2E
- Run `43605778406`: **SUCCESS** على المصدر الذي تضمن Parent/Core bridge.
- المخرجات: `clientCount=1`, `sameClient=true`, `coreAuth=true`, `coreRealtime=true`, `verifiedCompany=qa-parent-company`, `authError=null`.
- تم العثور على قناة Core واحدة باسم `rw-core-parent-core-bridge-e2e-qa-parent-company-1` وفلتر `company_id=eq.qa-parent-company`. وجود قناة HR قديمة مستقلة لم يُحسب خطأ؛ لم تُدمج أو تُعدّل.
- HTTP 200 و`BROWSER_E2E_ANONYMOUS_SMOKE=PASS`.

### Mother Inventory anonymous smoke
- Run `43605908068`: **SUCCESS** بعد تثبيت Supabase stub محلي في smoke المجهول؛ لا يحتاج هذا الاختبار اتصالًا خارجيًا بـRealtime حتى يتحقق من إقلاع هيكل Parent.
- Assembly Guard Run `43605908054`: **SUCCESS**.
- Forensic current Mother extract Run `43605908018`: **SUCCESS**.
- CTO Helper Files Run `43605908129`: **SUCCESS**.
- Parent forensic gate Run `43605651042`: **SUCCESS** بعد إضافة تحقق Core script/عميل واحد/جسر سجل العمليات.

محاولات smoke أقدم فشلت بسبب محاولة WebSocket حقيقية من بيئة CI برسالة HTTP Authentication failed؛ عولجت في الاختبارات بعزل Supabase/Reatime الخارجي عن اختبارات الإقلاع. لا تعتبر هذه الأخطاء دليلًا على فشل Core Auth أو منطق المصدر.

## 8. تحقق النشر

- Cloudflare Pages dashboard للمشروع `rawaea-erp` يظهر Production / branch `main` / Automatic deployments enabled.
- أحدث deployment ظاهر: commit `d7caf2e`، مع رابط النشر `https://d0306a63.rawaea-erp.pages.dev/`.
- Operational HEAD في GitHub هو `d7caf2eafd37ecc7777ccd6aa37856c7918b02dd`؛ يضم التغييرات التشغيلية السابقة في سلسلة commits.
- **Deployment = CONFIRMED** وفق لوحة Cloudflare. لا أخلط ذلك مع اختبار مستخدم Production مصادق عليه.

## 9. SMART ERP — السلامة وعدم تغيير البيانات

كل الاستعلامات في هذه الدورة كانت SELECT أو فحص كتالوج. لقطة الأعداد بعد الاختبار:

| الجدول | العدد |
|---|---:|
| receiving | 4 |
| receiving_details | 7 |
| inventory_counts | 1 |
| inventory_count_details | 35 |
| inventory_log | 83 |
| stock_vouchers | 0 |
| stock_voucher_details | 0 |
| erp_operation_registry | 98 |

لا DML ولا DDL ولا Migration ولا Trigger/RPC/RLS/Publication تغيير ولا تعديل role/user permission ولا إنشاء QA row ولا عملية استلام/تحضير/تحميل/تفريغ/مرتجع/جرد/إذن في SMART ERP. لم تُلمس جلسة الجرد الحالية ذات 35 تفصيلة. لا حركات مخزون أو خزينة أو قيود محاسبية أو أرصدة أطراف أُنشئت.

## 10. ملفات المصدر وCommits

- Picker Core/Auth/Realtime: commit `b85aa209225dd35f6c354bbbef9fd7cd8d0ee8e`.
- Core reuses Parent's client: `e64f17833432d1f1a53821521fb3a0dc44ab903c`.
- Parent bootstrap/Core script: `518e71c0145e6aa5c3767f9c6595f127ad578abc`.
- Parent client factory reuses shared client + Parent history Core channel: `c1444851ee0324726e403393e096786284a3ba82`.
- Parent browser bridge test: `105e70a64e45bc30ce6357999a574f143ff23883`, then assertion isolation `ba3d952a931fbe26175766996fb9a2535c72fee8`.
- Receiver gates: `374ea6c`, ثم `1572765`.
- Loader: `38b005f`; Returns: `c0feb10`; Unloader: `d36bc96`; Counter: `8315491`; Vouchers: `93a6517`.
- Standalone entitlement test contract: `a8ad2f0`; Hub role snapshot test correction: `b212c37`.
- Mother anonymous smoke isolation: `d7caf2e`.

ملفات التطبيقات الحالية وblobs:
- `main.html`: `e6d7a835f4e43b810e8c93c818d45880f5396c1e`.
- `core.js`: `2b2211a3f95049042e27a7b2ecbab3640a584942`.
- `picker.html`: `d1baa1ea7caebf515d4e750b1b4be78a698949f6`.
- `receiver.html`: `04ba0ee213d638f088776f2ad1799f4a822dc800`.
- `loader.html`: `e9fc96958563d7aa4a7f44d867ed2887aed0ea3e`.
- `returns.html`: `d38b3a48d7bf88453523ac30b7e4d3e0e0429c11`.
- `unloader.html`: `0573f1ba41b395894c8fe6775eb978629ffb28a8`.
- `counter.html`: `f82bcb5ecd535732daac0bfa30a943c6d9e8946f`.
- `vouchers.html`: `f251b6d894a5983cb2344b9c13c584dd9c05142c`.
- `warehouse.html`: `e1cf531deec5c092e007320e67a35e312528ed09` (لم يتغير في هذه الدورة).

## 11. ما بقي مفتوحًا

1. **UNVERIFIED:** تسجيل دخول حي فعلي بحساب `storekeeper@rawaea.com` والتأكد بصريًا أنه يرى Hub فقط ولا يدخل التطبيقات المستقلة.
2. **UNVERIFIED:** تسجيل دخول حي فعلي بحساب مشرف المخازن، ثم التحقق أن كل تطبيق يسمح به فقط عندما يكون مفتاح الإذن موجودًا، وليس بسبب اسم الدور.
3. **UNVERIFIED:** مشاهدة تبويب Parent Receiving داخل جلسة مصادق عليها ومقارنة السجلات الأربعة مع الواجهة بعد النشر.
4. **OPEN:** نشر `receiving` و`receiving_details` في Realtime publication أو اعتماد آلية تحديث بديلة؛ لا تنفيذ قبل ChangeSet ومراجعة RLS/replica identity/الفلاتر والتأثير.
5. **OPEN:** توحيد طبقة Auth في Parent بالكامل على RW_Auth بعد رسم اعتماديات login/boot/permissions/session/role switching واختبارات رجوع. هذه الدورة وحّدت عميل Supabase والجسر المطلوب، ولم تستبدل كل auth adapter المحلي.
6. **OPEN:** قياس runtime الحقيقي لقنوات Realtime للـParent بعد تسجيل دخول فعلي؛ CI أكد العقد باستخدام mock موثوق لكنه لا يثبت اتصال Supabase Production.
7. **OPEN:** تأكيد تطابق alias الإنتاج مع كل صفحة تشغيلية محددة من جلسة Production مصادق عليها؛ لوحة Cloudflare تؤكد deployment source، وليس قبول جميع الواجهات التشغيلية.

## 12. نقطة الاستكمال التالية

ابدأ من Operational HEAD `d7caf2eafd37ecc7777ccd6aa37856c7918b02dd` وReport719، لا تعِد إصلاح بوابات الدخول أو Picker Core أو Parent client bridge دون سبب جديد مثبت.

المرحلة التالية غير الكتابية:
- إجراء مرور دخول/منع بصري في Production بالحسابات المعتمدة، من دون تشغيل أي إجراء مخزني.
- مقارنة قائمة التطبيقات المتاحة في Parent مع بوابة كل تطبيق مستقل، وإرفاق اسم الحساب والمفتاح الذي سمح/منع الدخول.
- فتح تبويب الاستلام فقط ومطابقة سجل 12 نوفمبر و11 نوفمبر والمسؤول/التفاصيل.
- قياس Realtime Production دون إنشاء حركة مخزنية.

أي تغيير جديد في جداول أو سياسات أو Publication أو عقود محرك أو مسارات مالية/مخزنية يظل خاضعًا لمراجعة ChangeSet وموافقة المالك طبقًا للدستور التشغيلي.

**القرار:** الصلاحيات المحددة في مصدر التطبيقات، Picker Core/Auth/Realtime، وجسر Parent/Core بعميل واحد، واختبارات CI والنشر Cloudflare مثبتة. القبول النهائي لصلاحيات دخول حسابات Production الفعلية وواجهة Parent Receiving تحت جلسة مصادق عليها ما زال UNVERIFIED.  
**Readiness: READY WITH LIMITATIONS.**
