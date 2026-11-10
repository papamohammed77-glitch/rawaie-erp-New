# تقرير 700 — إصلاح عودة Receiver إلى قائمة الاستلام واستكمال تغطية E2E للمخزن الشامل

**التاريخ:** 2026-11-10 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-10-700  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` / `main`  
**مستودع الحوكمة:** `papamohammed77-glitch/rawaie-erp-New` / `main`  
**Production DB:** SMART ERP — Supabase project `fiilmooggumokxanwiyx`

## 1. النتيجة التنفيذية

تم تنفيذ إصلاح جراحي في مسار نجاح الاستلام داخل التطبيق المستقل `receiver.html` والنسخة الأصلية المضمّنة منه في `warehouse.html`، مع توسيع اختبار Playwright في GitHub Actions لتغطية PO وQuick Market والرفض الكامل وسجل العمليات المكتملة.

**السبب الجذري المثبت:** بعد حفظ عملية رفض شحنة بالكامل (sent > 0, accepted = 0)، لا يتغير رصيد المخزون أو كمية PO/QMP المستلمة أو حالة المستند. لذلك يمكن أن تبقى بصمة قائمة الانتظار كما هي. كان معالج النجاح في Receiver يفرّغ مؤشر المستند ثم يستدعي `loadPurchaseOrders()` فقط؛ وهذه الدالة تعيد بناء الواجهة إذا تغيرت بصمة البيانات فقط. عندما لا تتغير البصمة، يظل DOM يعرض مساحة المستند بدل قائمة الانتظار، رغم نجاح تسجيل عملية الرفض.

**الإصلاح:** بعد نجاح أي عملية استلام، يعرض Receiver قائمة الانتظار فورًا من البيانات المحفوظة، ثم يجري تحديثًا هادئًا من المصدر:
- `self.renderList();`
- `self.loadPurchaseOrders({silent:true});`

تم تطبيق نفس التغيير في المصدر المستقل والنسخة المضمّنة، لمنع اختلاف سلوك التطبيقين.

**الحالة:** `FIX APPLIED — STATIC / SOURCE VERIFICATION PASS — PLAYWRIGHT CI RESULT NOT VERIFIED — CLOUDflare DEPLOYMENT NOT VERIFIED`.

## 2. نقطة البداية والمصادر المثبتة

- رأس `main` قبل التغيير: `76a80dfa1437f5a51a8f076f963c9328d8b1aa29`.
- التطبيق الموحد: `companies/company-1/warehouse/warehouse.html`، blob قبل التعديل `31c4f1ae903b389269a4b90afdf310784f77f194`.
- Receiver المستقل: `companies/company-1/warehouse/receiver.html`، blob قبل التعديل `7766f6d9b3959de1b6a22bb7bcd2aee05c053bde`.
- عقد الاختبار: `.github/workflows/warehouse_hub_browser_e2e_20261110.yml`.
- مرجع تشغيل Receiver السابق وتقارير 682–694 تمت مراجعتها مع المصدر الحي وProduction، ولم تُعامل باعتبارها بديلًا عن الفحص المباشر.
- تمت قراءة `writing-block-8888-10.md` كاملًا على دفعات إلى EOF، وكذلك `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md` (2,665 سطرًا) والدستور التشغيلي الدائم.

## 3. مطابقة Receiver المستقل مع Receiver المضمّن

التطبيق الشامل يضم سبع وحدات أصلية: Receiver وPicker وLoader وReturns وUnloader وCounter وVouchers. لا يستخدم `iframe` ولا يفتح ملفات التطبيقات الفرعية لتشغيلها؛ تُحمّل الوحدات في مساحة عمل داخلية، مع Core وSupabase client مشتركين.

تمت مقارنة 19 وظيفة محورية في مسار Receiver بعد تطبيع مراجع DOM المعزولة (`moduleUI` / `RW_UI` و`moduleDocument` / `document`). الوظائف المطابقة شملت:
- إرسال الاستلام `submitReceiving`.
- تحميل قائمة الانتظار وبياناتها وبصمتها.
- فتح مستند PO/QMP وتفاصيله.
- جدولة Realtime وحماية المستند المفتوح أثناء التحديث.
- سجل الاستلام المكتمل وفتح تفاصيل العملية.
- تهيئة الوحدة والجلسة وتسجيل الخروج وتبديل التبويبات.

النتيجة: **19/19 وظيفة محورية متطابقة بعد تطبيع نطاق الواجهة**. الفروق المتبقية في Login/Account هي تعديلات Scope مقصودة داخل الحاوية وليست استبدالًا لعقد الاستلام.

تم فحص JavaScript للحاوية والملف المستقل بعد التغيير؛ كلاهما يمر باختبار التحليل النحوي.

## 4. التعديل الجراحي

**الملفات الثلاثة المتغيرة في التزام واحد:**

| الملف | Blob بعد التغيير |
|---|---|
| `companies/company-1/warehouse/receiver.html` | `f2bd1e427b902924a50531f886ba22bb61912b91` |
| `companies/company-1/warehouse/warehouse.html` | `b617dc7a040df60f20f5d84321500d3dd8c11e31` |
| `.github/workflows/warehouse_hub_browser_e2e_20261110.yml` | `85e8287863f077e5c721c3d66753251f15ff7c50` |

**Commit:** `a68a206184b2d588e10793a8146229eb35baddc9`  
**الرسالة:** `fix(warehouse): return receiver to queue after rejected shipment`  
**Compare:** من `76a80dfa1437f5a51a8f076f963c9328d8b1aa29` إلى `a68a206184b2d588e10793a8146229eb35baddc9`؛ ثلاثة ملفات فقط، دون تغيير `main.html` أو `core.js`.

لم تتغير أي دالة RPC أو Edge Function أو Migration أو RLS/ACL أو جدول في Supabase.

## 5. تغطية Playwright E2E المضافة

أُضيفت Fixtures اصطناعية إلى mock المحلي داخل Workflow، مع اعتراض `RW_API.call('receive-purchase')`. الاختبار لا يتصل بكتّاب Supabase الفعليين ولا يرسل معاملة إنتاج.

التغطية المضافة:
1. تحميل PO وQuick Market في قائمة موحدة، والتحقق من مرشحات المصدر.
2. فتح PO في مساحة العمل المستقلة.
3. منع المقبول إذا تجاوز المرسل.
4. فرض سبب الاختلاف عند اختلاف الكمية المرسلة والمقبولة.
5. التحقق من payload أمر الشراء، والكمّيتين، وUUID للعملية.
6. فتح Quick Market وتسجيل شحنة مرسلة مع صفر مقبول وسبب رفض إلزامي.
7. التحقق من استخدام `invoice_id` بدل `po_code`، وأن UUID للعملية الجديدة مختلف.
8. التحقق من العودة إلى قائمة الانتظار بعد PO وبعد الرفض الكامل، حتى عندما لا تتغير بصمة المستند.
9. فتح سجل العمليات المكتملة، وعرض عملية PO وQMP وتفاصيل العملية وسبب الرفض.

كما أُضيف فحص ثابت يمنع فقدان `renderList()` أو العودة إلى الاعتماد على تغيّر Queue Signature وحده.

**النتيجة الحالية للاختبارات:**
- JavaScript parsing للحاوية: **PASS**.
- JavaScript parsing للملف Receiver: **PASS**.
- تطابق كتلة إصلاح عودة القائمة بين المصدر المستقل والمضمّن: **PASS**.
- وجود اختبارات PO / QMP / History / unchanged-queue في Workflow: **PASS**.
- GitHub commit status أعاد قائمة Checks فارغة؛ لذلك **نتيجة تنفيذ GitHub Actions الفعلية غير مثبتة في هذه الجلسة**. لا يُسجل Playwright على أنه PASS حتى تظهر نتيجة تشغيله.

## 6. SMART ERP — التحقق من أثر المخزون والحسابات

تم فحص التعريف الحي لـ `receive-purchase`، الإصدار 18، ACTIVE، `verify_jwt=true`. بصمة المصدر المنشور المسجلة `e2e35f338861f6b5e96320509ab7c8bd8dfd1854766b68ecdd8cc5bce7c19bb8` مطابقة لبصمة المصدر التي سبق التحقق منها في GitHub. لم تُعدّل أو تُنشر Edge Function.

مسارا الاستلام مختلفان ويجب الحفاظ عليهما:
- **PO:** الكمية المقبولة فقط تُسجل `PurchaseIn`، وتحدث `qty_received` وحالة PO، ويُنشأ التزام مورد وقيد محاسبي متوازن.
- **Quick Market / Employee Custody:** المقبول فقط ينتقل من حيازة المشتري إلى مخزون الفرع، مع تخفيض حيازة المشتري بالمقدار المقبول. هذا المسار لا ينشئ Supplier AP أو Supplier Ledger أو Journal/GL أو Treasury/Cash. الرفض الكامل يسجل واقعة الاستلام والفرق والسبب دون زيادة مخزون أو تخفيض عهدة.

**عملية Production موجودة مسبقًا وليست Fixture لهذا الاختبار:** PO `PO-20260928` بتاريخ 2026-11-09، بسجل استلام واحد وسطرين، مجموع المرسل 15 والمقبول 15 والفرق صفر. تحقق الربط الفعلي:
- حركتا `PurchaseIn` بإجمالي 15 وحدة.
- قيد يومية واحد متوازن: Debit 700 / Credit 700.
- قيد مورد واحد بصافي دائن 700.
- سجل تدقيق واحد لعملية الاستلام.

هذه العملية لم تُنشأ أو تُعدل بواسطة هذا التنفيذ.

**عدادات Production بعد التغيير البرمجي:** receiving=1، receiving_details=2، inventory_log=78، stock_branches=58، stock_vouchers=0، stock_voucher_details=0، supplier_ledger=3، journal_entries=21، buyer_goods_custody_events=0. وهي مطابقة للفحص السابق أثناء هذه الجلسة؛ لم يحدث أي ترحيل أو إضافة سجل أعمال بسبب تعديل الملفات أو الاختبار.

## 7. النظام الأم والتكامل

مدخل «المخزن الشامل» موجود في قائمة النظام الأم ضمن العمليات المخزنية، ويفتح `warehouse/warehouse.html` بصلاحية `warehouse`. لذلك لم تكن هناك حاجة لتعديل `main.html` أو إضافة مدخل مكرر.

سجل الاستلام و`receiving_details` هما المصدر المشترك الذي يقرأه النظام الأم؛ كما أن PO receipt يحدّث PO و`inventory_log` وSupplier Ledger وJournal وAudit وفق العقد الحي.

## 8. ما لم يُثبت بعد — بوابات الإغلاق

1. **GitHub Actions / Playwright:** وجود Workflow والاختبارات محفوظ في Git، لكن حالة التشغيل الفعلية ونتيجة Playwright لم تظهر عبر واجهة Checks المتاحة. الحالة `UNVERIFIED`.
2. **Cloudflare Pages:** لا يوجد تحقق بعد التزام `a68a206` من أن Production يخدم blobs الجديدة للملفين. الحالة `UNVERIFIED`.
3. **Authenticated browser E2E:** لم تُنفذ جلسة Receiver حقيقية موثقة بعد. صفحة ERP المتاحة لم تُستخدم لإجراء معاملة حقيقية.
4. **Live transaction E2E:** لم يتم تنفيذ استلام حي من PO أو QMP بغرض الاختبار؛ لا يوجد مستند QA مخصص ذو مسار عكس وتنظيف مثبت ضمن هذه الدورة. لم تُستخدم الفواتير والأوامر التشغيلية الحقيقية كـFixtures.
5. **Gold/Diamond certification:** غير ممنوحة؛ يلزم إنهاء بوابات CI والنشر والتشغيل المصادق عليه.

هذه القيود لا تلغي الإصلاح المطبق، لكنها تمنع وصفه بأنه منشور ومقبول E2E في Production.

## 9. سجل السلامة

- لا كتابة إلى SMART ERP أو تغيير بيانات.
- لا إنشاء/تحديث/حذف PO أو فاتورة أو Receiving حقيقية.
- لا حركة مخزون أو عهدة مشتري أو Supplier Ledger أو Journal أو Cash/Treasury.
- لا Migration أو RPC أو RLS/ACL أو Edge deployment.
- لا تعديل للنظام الأم `main.html` أو Core.
- لا Supabase branch أو بيئة مدفوعة جديدة.

## 10. نقطة الاستئناف الدقيقة

**Last verified operational HEAD:** `a68a206184b2d588e10793a8146229eb35baddc9`.

الخطوات التالية:
1. احصل على نتيجة تشغيل Workflow على الالتزام `a68a206`، وافحص سجل Playwright الفعلي؛ أصلح أي فشل يظهر بدل الاكتفاء بوجود assertions.
2. تحقق من Cloudflare Production SHA وقارن الملفات المنشورة مع blobs: Receiver `f2bd1e427b902924a50531f886ba22bb61912b91` وWarehouse `b617dc7a040df60f20f5d84321500d3dd8c11e31`.
3. في جلسة Receiver مصادق عليها، اختبر العرض والبحث والمرشحات وفتح المستند وإدخال الكميات ورفض البيانات غير الصالحة والعودة إلى القائمة، دون إرسال معاملة حقيقية.
4. لا تنفذ Live stock/accounting E2E إلا بعد وجود Fixture اصطناعي محدد ومؤقت ومسار تنظيف/عكس شامل مثبت، ثم تحقق من baseline بعد التنظيف.
5. أعد تدقيق بقية وحدات Warehouse والتكامل مع Parent بعد إغلاق Receiver، مع الحفاظ على حدود المخزون والحسابات.

**التقييم النهائي:** `FIX APPLIED — SOURCE PARITY PASS — RECEIVER STATIC/E2E COVERAGE ADDED — PRODUCTION DATA UNCHANGED — PLAYWRIGHT CI / CLOUDFLARE / AUTHENTICATED E2E NOT VERIFIED — NOT CLOSED`.
