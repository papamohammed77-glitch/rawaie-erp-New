# Report394 — إعادة مزامنة Production ومراجعة جراحة تكامل التلي سيلز
**التاريخ:** 2026-10-10  
**النطاق:** استعادة آخر حالة مثبتة، مطابقة Production الحالي، والتحقق من التعديل الجراحي المطلوب لتكامل التلي سيلز مع صلاحيات النظام الأم والقلب المركزي.  
**الحدود:** لم يُعدّل `main.html` أو `telesales.html` أو `core.js`؛ هذه ملفات واجهة يطبق المالك التعديل الجراحي عليها. لم تُنشأ Edge Functions جديدة ولم تُنفذ تغييرات DB غير لازمة.

## PRE-CHANGE SELF-AUDIT

| المجال | الحالة المثبتة الآن | الدليل |
|---|---|---|
| فهم Business Flow | إنشاء الأوردر عبر `save-sales-invoice`، والتعديل عبر `update-order`، وربط الرانشيت لاحقًا بدورة الرانشيت الحالية | Production Edge source + Report392/393 + مصدر التلي سيلز الحالي |
| Architecture | يجب أن تمر تعديلات الأوردر من RPC الذري لا كتابة الجداول مباشرة من PWA | `update-order` الحالي يستدعي `update_order_atomic` |
| Production Synchronization | أُعيدت القراءة في هذه الجلسة قبل تقرير الحالة | Supabase project `fiilmooggumokxanwiyx` |
| Provenance | المصدر الحالي للنواة والتلي سيلز لم يتغير منذ checkpoint السابق | Git blob SHA أدناه |
| Runtime Verification | فحص Production/ACL/عدادات الجداول أُعيد؛ لا يوجد HTTP/Browser E2E من هذه الجلسة | نتائج SQL وEdge retrieval أدناه |
| Execution Confidence | عالٍ بشأن backend الموجود؛ غير كافٍ لإغلاق تكامل الواجهة قبل تطبيق الجراحة ونشرها | لم تتغير ملفات الواجهة |

### Confirmed Production facts — re-read this session

- `save-sales-invoice`: **v17 ACTIVE**, `verify_jwt=true`, package SHA-256 `fee635a235a3f8e42db8f72e792bbf2a828fb6a444f082c59bc8e95c4fa9ddb1`.
- `update-order`: **v6 ACTIVE**, `verify_jwt=true`, package SHA-256 `a1b06430b9d90777f7d9549286d9c64e7df009c5d15a19917ce6be096a00c8f3`.
- `public.get_my_effective_profile()` موجودة في Production، وتُرجع JSONB مبنيًا على `auth.uid()` فقط، وتجمع `users.permissions` و`roles.permissions` و`role_permissions.permission_key`. ACL الحالي: `anon EXECUTE=false`, `authenticated EXECUTE=true`. الدالة `SECURITY DEFINER` و`search_path='' `.
- Baseline عند الفحص: `orders=0`, `order_details=0`, `runsheets=0`, `run_sheet_details=0`.
- لم يُنشأ Edge Function جديد ولم يتغير Production أثناء هذه المراجعة.

### Git artifacts read

- `erp-frontend/companies/company-1/main.html`: blob `4f94f9c6ebdde1b59632384628c72767d3bb950d`. أداة GitHub تعيد محتوى فارغًا لهذا الملف؛ لم يُلمس ولم تُستنتج تفاصيل داخلية غير مقروءة.
- `erp-frontend/companies/company-1/sales/telesales.html`: blob `d839ff043631d365be8eb2832ee98aa4fabcb43c`.
- `erp-frontend/companies/company-1/core.js`: blob `e853c49375ccc8b94757b594057dcd853b4a2fdb`.
- راجعت Report392 وReport393 كأدلة تاريخية مساعدة، ولم أعاملهما بديلًا عن إعادة قراءة Production الحالية.

## Root cause confirmed

1. النواة الحالية `RW_Auth` تقرأ `users` بالـemail وتستمد owner/permissions من `user_metadata`؛ هذا لا يضمن صلاحيات الدور الفعلية الموجودة في قاعدة البيانات، وقد يفشل إذا لم تتطابق metadata مع الملف المرجعي.
2. مسار تعديل الأوردر في PWA كان منفصلًا عن العقد الذري المركزي؛ التعديل يجب أن يمر عبر `update-order`، لا تحديث `orders` وحذف/إعادة إدخال `order_details` مباشرة.
3. مسار تحرير عميل قديم يضع UUID في قيمة `customer_code`; يجب تحويل UUID إلى `customers.customer_code` القانوني قبل استدعاء RPC.
4. لا يجوز اعتبار إصلاح backend إغلاقًا لتكامل الواجهة؛ ملفات الواجهة لم تُنشر بالجراحة المقترحة، ولا يوجد HTTP/Browser E2E مثبت بعد.

## التعديل الجراحي المطلوب من المالك — فقط

### 1. النواة المشتركة

- **الملف:** `erp-frontend/companies/company-1/core.js`
- **SHA الحالي:** `e853c49375ccc8b94757b594057dcd853b4a2fdb`
- **محدد البحث:** `var RW_Auth = (function() {`
- **حد الحذف:** الوحدة كاملة حتى `})();` الذي يسبق مباشرة `// الوحدة ٢: RW_DB`.
- **الإجراء:** استبدل وحدة `RW_Auth` كاملة بالنص الكامل الموجود في [Report393، القسم 3](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report393_TELESALES_ROLE_PERMISSION_PARITY_20261010.md).
- **ممنوع:** تعديل `RW_DB` أو `RW_API` أو `main.html`.
- **سبب الإصلاح:** تحميل ملف المستخدم والصلاحيات الفعلية عبر RPC المصادق عليه، مع دمج الصلاحيات المباشرة وصلاحيات الدور، وعدم اعتبار metadata وحدها مصدر تفويض.

### 2. تطبيق التلي سيلز

- **الملف:** `erp-frontend/companies/company-1/sales/telesales.html`
- **SHA الحالي:** `d839ff043631d365be8eb2832ee98aa4fabcb43c`
- **محدد البحث:** `// ==================== حفظ الأوردر ====================` ثم `self.submitOrder = function() {`
- **حد الحذف:** نهاية الدالة `};` التي تسبق مباشرة `self._editOrderFromDetail = function(orderId)`.
- **الإجراء:** استبدل الدالة كاملة بالنص الكامل في [Report392، القسم 3](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report392_TELESALES_INTEGRATION_HARDENING_20261009.md).
- **سبب الإصلاح:** الإنشاء يبقى عبر `save-sales-invoice`، والتعديل ينتقل إلى `update-order` الذري، مع حل UUID العميل إلى `customer_code` قبل الإرسال.
- **ممنوع:** تعديل أي دالة أخرى في `telesales.html` أو تعديل `main.html`.

## Verification matrix

| الاختبار | النتيجة الحالية |
|---|---|
| Production Edge version / JWT | VERIFIED: v17 وv6، وكلاهما JWT مطلوب |
| Effective-profile RPC definition / ACL | VERIFIED: auth.uid(), SECURITY DEFINER, search_path فارغ، authenticated فقط |
| Production business-table baseline | VERIFIED: الجداول الأربعة صفر عند الاستعلام |
| Frontend patch applied | NOT YET — لم يُعدّل المالك الملفات بعد |
| Published frontend parity | UNVERIFIED |
| Authenticated HTTP/Browser E2E | NOT RUN |
| Create/edit/idempotent retry/runsheet linkage/no stock side effect/company isolation | OPEN حتى تطبيق الجراحة واختبارها |
| Production residue after frontend E2E | OPEN — لا توجد تجربة واجهة جديدة في هذه الجلسة |

## SELF-AUDIT FINAL

- **What I Proved:** Production الحالي للدوال وRPC وACL وعدادات الجداول؛ hashes الحالية لملفات الواجهة؛ سبب فجوة الصلاحيات ومسار التعديل.
- **What I Did Not Prove:** نشر الواجهة بعد الجراحة، HTTP/Browser E2E، ربط أوردر فعلي برانشيت من المتصفح، واختبار العزل عبر HTTP.
- **What I Fixed:** لا تغيير جديد مطلوب في Production ضمن هذا الفحص؛ الـbackend الموجود بالفعل متوافق مع الخطة المثبتة.
- **What I Initially Missed:** لا يجوز مساواة وجود RPC/Edge صحيح بإغلاق التكامل؛ النواة والـPWA ما زالتا بحاجة إلى الجراحة اليدوية والنشر.
- **What Could Still Be Wrong:** أي اعتماد آخر داخل مستهلكي `RW_Auth` على حقول metadata القديمة؛ يجب اختبار تطبيقات PWA المشتركة بعد الاستبدال قبل تعميم النشر.
- **Final Confidence:** مرتفع في حقائق Production التي أُعيد فحصها؛ متوسط في أثر التعديل على بقية التطبيقات حتى إجراء regression.
- **Final Closure Status:** `BACKEND VERIFIED / FRONTEND SURGERY PENDING / NOT CLOSED`.

## تعليمات بدء الدورة التالية

1. أعد قراءة Production أولًا وسجّل الإصدارات والـACL وعدادات baseline في نفس الجلسة.
2. طبّق الجراحة المحددة فقط على `core.js` و`telesales.html`؛ لا تلمس `main.html`.
3. راجع جميع مستهلكي `RW_Auth` قبل النشر المشترك؛ اختبر login/session/logout و`checkPermission` و`hasWarehouseRole`.
4. انشر الواجهة ثم نفّذ HTTP/Browser E2E بمستخدم مباشر الصلاحية وآخر يرثها من الدور.
5. أثبت الإنشاء والتعديل وidempotency وربط الرانشيت وعدم تحريك المخزون وعزل الشركة، ثم أعد قياس baseline وسجّل النتيجة. لا تعلن الإغلاق قبل إثبات ذلك.
