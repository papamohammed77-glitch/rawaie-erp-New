# Report415 — تحقق إنتاجي حديث وخطة التعديل الجراحي لجدول أوردرات المبيعات
**التاريخ:** 2026-10-11  
**النطاق الوحيد:** تكامل جدول «أوردرات المبيعات» في النظام الأم `erp-frontend/companies/company-1/main.html` مع بيانات المرتجعات وقيود الرانشيت.  
**Production:** Supabase project `fiilmooggumokxanwiyx`.  
**سياسة الملفات:** لم يُعدّل `main.html` أو أي تطبيق تشغيلي. لم يُنفذ تغيير DB/Edge جديد لأن الفحص الحديث لم يثبت حاجة إلى تغيير إضافي في Production Core.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** الجدول الأم يجب أن يعرض الحقيقة النهائية للأوردر، ويحتفظ بالكمية الأصلية والمرتجعة لأغراض التدقيق، ويمنع اختيار POS/المصدر المجهول للرانشيت.
- **Architecture Understanding:** ضمان مصدر الرانشيت موجود في RPCs الحالية ويجب أن تبقى الواجهة طبقة تجربة مستخدم لا حاجز الأمان الوحيد. المالك وحده يطبق تعديل الملف الأم والتطبيقات.
- **Database Understanding:** Production يحتوي `orders.source/created_by/created_at/total_amount/original_total_amount` و`order_details.qty/qty_returned/reason_return/line_amount`. RLS مفعّل على `orders` و`order_details` و`users`.
- **Historical Understanding:** راجعت `CURRENT_STATE.md`، ومرجع الحوكمة، وReport413 وReport414، وأعدت فحص نص التغيير الجراحي السابق. التقارير ليست بديلًا عن القراءة الحية.
- **Production Understanding:** قراءة مباشرة في 2026-10-11 16:15:23+00 للأوردر `ORD-1006)، وقراءة تفاصيله في 16:15:41+00، وإعادة قراءة تعريفات RPC وACL في هذه الدورة.
- **Current Understanding:** snapshot `rawaie-erp-New/Current/PWA/main.html` له blob `27b777528665dcc985809648f006452c861ae36e`، لكن ذلك ليس إثباتًا على الملف الأم الحي. الموصل أعاد للملف الحي `erp-frontend/companies/company-1/main.html` SHA `4f94f9c6ebdde1b59632384628c72767d3bb950d` ومحتوى فارغًا حتى مع طلب نطاق أسطر.
- **Execution Confidence:** مرتفع في بيانات Production وعقد RPC/ACL؛ متوسط في تشخيص snapshot؛ غير مثبت في مطابقة patch مع النص الحي، نشر الواجهة، أو Browser E2E.

## 1. Fresh Production snapshot

وقت القراءة: **2026-10-11 16:15:23.260096+00**.

| الحقل | القيمة |
|---|---|
| order_code | `ORD-1006` |
| company_id | `00000000-0000-0000-0000-000000000001` |
| source | `pos` |
| created_by | `cashier@rawaea.com` |
| created_at | `2026-10-11 07:31:00.768458+00` |
| order_status | `Partially Returned` |
| total_amount / original_total_amount | `135.00 / 185.00` |
| runsheet_id | `NULL` |

تفاصيل Production التي قرئت عند **2026-10-11 16:15:41.66604+00**:

| item_code | qty | qty_returned | reason_return | line_amount |
|---|---:|---:|---|---:|
| 1001 | 1 | 1 | مرتجع نقطة بيع | 50.00 |
| 1003 | 1 | 0 | NULL | 135.00 |

النتيجة الحسابية من السطور: كميتان أصليتان، كمية مرتجعة واحدة، كمية متبقية واحدة؛ سطر واحد فقط له كمية متبقية. رأس الأوردر هو مرجع الإجمالي النهائي (135.00)، و`original_total_amount=185.00` مرجع الإجمالي الأصلي. لم تتغير بيانات أعمال أو مخزون أو حسابات في هذه الدورة.

## 2. Production Core — فحص حديث

تمت إعادة قراءة التعريف الحي لكل من:

- `public.create_runsheet_atomic(uuid,text[],text)`
- `public.append_orders_to_runsheet_atomic(uuid,text[],text,text)`

كلاهما يرفض أي مصدر لا ينتمي إلى `telesales`, `tele-sales`, `order-taker`, `online-store` بعد التطبيع؛ وبالتالي يرفض `pos` والمصدر الفارغ/المجهول. ACL التي أعادها فحص Production: `anon=false`, `authenticated=false`, `service_role=true`. هذا يتفق مع سلسلة Edge الحالية → service_role → RPC مركزية. لا يوجد Defect مثبت يبرر إعادة تعديل RPC أو ACL الآن.

فحص سياسات RLS أظهر أن قراءة جميع مستخدمي الشركة من `public.users` تتطلب صلاحية `users`، مع السماح للمستخدم بقراءة سجله. لذلك لا يجوز الاعتماد على اسم المنشئ العربي ليكون متاحًا لكل دور. يجب أن يعرض الجدول `created_by` كقيمة fallback دائمًا، وألا يؤدي تعذر قراءة جدول users إلى فشل تحميل الجدول.

محاولة قراءة سجلات Supabase الموحدة في هذه الدورة أعادت خطأ backend من أداة السجلات؛ لم أستخدم ذلك كدليل على غياب أحداث أو أخطاء.

## 3. ما هو العيب وما الذي لا يحتاج إلى تعديل؟

### عيوب مثبتة في snapshot المتاح
داخل `RW_Orders` في snapshot `Current/PWA/main.html`:
1. عدّ الأصناف لا يستبعد السطور التي أصبحت `qty - qty_returned = 0`.
2. Realtime يحدّث رأس الأوردر المخزن في الذاكرة ولا يعيد بناء مشتقات التفاصيل.
3. المصدر والمنشئ ووقت الإنشاء لا تظهر جميعها في الجدول.
4. الاختيار لا يعطّل مصادر غير مؤهلة للرانشيت.
5. عرض التفاصيل يعيد بناء الإجمالي من سطور البيع الأصلية بدل اعتماد `orders.total_amount` النهائي.
6. الطباعة غير مثبتة على عرض الأصلي/المرتجع/المتبقي.

### ما لا ينبغي تغييره
- لا تعدّل Production RPCs مرة أخرى؛ الحارس المركزي موجود الآن.
- لا توسّع RLS لجدول `users` لمجرد عرض الاسم.
- لا تغيّر بيانات `ORD-1006` ولا تنشئ fixture عليها.
- لا تضف Edge Function جديدة.
- لا تستبدل الملف الأم كاملًا ولا تنقل snapshot تاريخيًا إليه.

## 4. Owner Surgical Changeset — التعديل المطلوب في الملف الأم

**الملف:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`  
**الوحدة:** `RW_Orders`  
**التوقيع المرجعي:** `var ordersData = [];`, `async function loadData()`, `async function refreshRealtimeChannel()`, `function _renderTable(rows)`, `function _validateSelected(selected)`, `async function _showDetails(code)`, و`_printOrder/_buildPrintWindow`.

**تنبيه تحديد السطر:** لم أستطع استخراج نص الملف الأم الحي عبر موصل GitHub؛ أعاد SHA `4f94f9c6ebdde1b59632384628c72767d3bb950d` مع محتوى فارغ، حتى للقراءات المحددة. لذلك لا أختلق أرقام أسطر ولا أدّعي أن تواقيع snapshot تطابق الملف الحي. ابحث داخل الوحدة المحددة بالتواقيع التالية، وطابق جسم العنصر قبل الاستبدال.

### A — Helpers
ابحث داخل `RW_Orders` عن:
```javascript
var ordersData = [];
```
أضف مرة واحدة بعده helpers `_normalizeOrderSource`, `_runsheetSourceEligible`, `_canAddOrderToRunsheet) بالنص الكامل الوارد في Report413، القسم 3-A. لا تضف نسخة ثانية إن كانت موجودة بالفعل.

### B — `loadData()`
استبدل الدالة كاملة فقط إذا طابق توقيعها النص الحي. استخدم البديل الكامل في Report413، القسم 3-B. يجب أن:
- تقرأ `qty` و`qty_returned` وتعد السطر فقط عندما تكون الكمية المتبقية أكبر من صفر.
- تقرأ المنشئ بالاسم إن سمحت RLS، وتستخدم `created_by` كـfallback.
- لا تفشل عملية تحميل الأوردرات إذا لم يكن جدول `users` قابلًا للقراءة من الدور الحالي.

### C — `refreshRealtimeChannel()`
استبدل الدالة المطابقة فقط ببديل Report413، القسم 3-C، بحيث يؤدي تغيير رأس الأوردر داخل الشركة الحالية إلى إعادة تحميل البيانات والمشتقات عبر `_refreshData()`، مع إزالة الاشتراك القديم وتقييد القناة على `company_id`.

### D — رأس الجدول و«تحديد الكل»
- غيّر عمود التاريخ ليعرض `created_at` ووقت الإنشاء.
- أضف عمودي المصدر والمنشئ بعد عمود العميل/المنطقة.
- اجعل «تحديد الكل» يستخدم `.order-checkbox:not(:disabled)` داخل معالج `id="check-all"` فقط.
- حدّث `colspan` الخاص بجدول الأوردرات من 9 إلى 11 في حالات التحميل/الخطأ/الفراغ ذات الصلة فقط.
- لا تنفّذ أي استبدال عام على مستوى الملف؛ هذه السلاسل قد تتكرر في جداول أخرى.

### E — `_renderTable(rows)`
استخدم البديل الكامل الموجود في Report413، القسم 3-E، بعد التأكد من تطابق التوقيع. يجب أن يعرض المصدر والمنشئ ووقت الإنشاء، ويعرض `itemsCount` بعد استبعاد السطور المرتجعة بالكامل، ويعطّل checkbox إذا كان المصدر أو الحالة أو ارتباط الرانشيت غير مؤهل.

### F — `_validateSelected(selected)`
استخدم البديل الكامل في Report413، القسم 3-F. تحقق من الشركة، والمصدر المسموح، والحالة `Confirmed/Pending`، وعدم وجود `runsheet_id`. هذا تحقق لتحسين UX؛ تبقى RPC في Production حاجز الأمان المركزي.

### G — تفاصيل المرتجع والطباعة
داخل `RW_Orders`، طابق `async function _showDetails(code)` ثم أصلح المقطع فقط إذا كان مطابقًا للعنصر الفعلي. يجب أن يعرض لكل سطر:
- الكمية الأصلية.
- الكمية المرتجعة.
- الكمية المتبقية `max(qty - qty_returned, 0)`.
- سبب المرتجع.
- قيمة المتبقي دون تعديل سطر البيع الأصلي.
- الإجمالي النهائي من `orders.total_amount` والإجمالي الأصلي من `original_total_amount` لأغراض التدقيق.

ثم افحص `_printOrder` و`_buildPrintWindow` كلًا على حدة؛ لا تفترض أن إصلاح المودال أصلح الطباعة. لم أستبدل هذه الدوال لأن نص الملف الحي لم يكن قابلًا للقراءة، ولأن استبدالها من snapshot قديم يخالف شرط عدم التخمين. لا يوجد في الأدلة الحالية نص كامل موثوق للبديل الخاص بالطباعة يمكن نسبته إلى الملف الحي.

**الأثر المتوقع:** عرض الحالة النهائية دون محو التاريخ، عدم تضليل عدد الأصناف بعد المرتجع، وضوح مصدر/منشئ/وقت الأوردر، منع اختيار POS للرانشيت من الواجهة، وبقاء الحماية المركزية في Production.

## 5. الاختبارات المطلوبة بعد دمج المالك

1. قراءة فقط لـ`ORD-1006`: الحالة `Partially Returned`، المصدر POS/كاشير، المنشئ `cashier@rawaea.com` على الأقل، وقت الإنشاء ظاهر، `itemsCount=1`، الإجمالي النهائي 135.00، الأصلي 185.00.
2. مع مستخدم لا يملك `users`: الجدول لا يفشل؛ يظهر البريد بدل الاسم.
3. لا يمكن اختيار أوردر POS أو مصدر فارغ/مجهول للرانشيت. يجب أن يبقى `order-taker` المؤهل في حالة `Confirmed/Pending` وغير المرتبط قابلًا للاختيار.
4. «تحديد الكل» لا يحدد checkboxes المعطلة.
5. على fixture معزول فقط: اختبار Realtime بعد تغير `qty_returned`، ثم تنظيف fixture وإثبات عدم بقاء أثر.
6. اختبار تفاصيل المرتجع والطباعة والفرز والفلاتر والتأكيد والحذف والإنشاء/الضم وعزل الشركة.
7. بعد النشر: إثبات SHA للملف المخدوم، وConsole/Network/Service Worker، وإعادة قراءة Production للتأكد من عدم وجود أثر اختبار.

## 6. ما تم / لم يتم

**تم:** قراءة Production حديثًا؛ التحقق من حالة `ORD-1006` وحقول الرأس؛ قراءة سطري التفاصيل؛ إعادة فحص RPC definitions وACL؛ إعادة فحص سياسات RLS؛ تثبيت أن حماية مصدر الرانشيت موجودة بالفعل.

**لم يتم:** أي تغيير في Production أو بيانات الأعمال أو Edge Functions؛ أي تعديل في `main.html` أو POS؛ نشر واجهة؛ اختبار Browser E2E؛ إثبات مطابقة الملف الأم الحي مع snapshot. فشل أداة السجلات لم يُفسر كدليل على غياب أحداث.

## SELF-AUDIT FINAL

- **What I Proved:** Production row الحالي وحقول المرتجع؛ أن سطرًا واحدًا فقط له كمية متبقية؛ أن الإجمالي الحالي 135.00 والأصلي 185.00؛ أن RPCs المركزية تمنع مصادر الرانشيت غير المسموحة؛ ACL الحالي؛ حدود RLS على أسماء المستخدمين.
- **What I Did Not Prove:** محتوى `main.html` الحي، أرقام أسطره، انطباق كل patch عليه، النشر، Browser E2E، أو اتساق الطباعة.
- **What I Fixed:** لم أجرِ تغييرًا غير مبرر؛ أبقيت Production دون تغيير لأن عقد الحماية المطلوب موجود، وحددت عناصر الواجهة التي تحتاج دمج المالك.
- **What I Initially Missed:** يجب ألا يفترض أي patch أن مستخدم `orders` يستطيع قراءة دليل `users`; البريد المخزن هو fallback الموثوق.
- **What Could Still Be Wrong:** اختلاف الملف الأم الحي عن snapshot، وجود اختلاف في دوال الطباعة، أو عدم نشر أي تغييرات واجهة سابقة.
- **Final Confidence:** مرتفع في بيانات Production وعقد RPC/RLS؛ متوسط في تشخيص snapshot؛ غير مثبت في الواجهة الحية والنشر وE2E.
- **Final Closure Status:** `PRODUCTION SOURCE GUARD VERIFIED / OWNER UI SURGICAL PATCH SPECIFIED / LIVE MAIN SOURCE TEXT UNREADABLE THROUGH CONNECTOR / FRONTEND DEPLOYMENT + BROWSER E2E + PRINT OPEN / NOT CLOSED`.

## نقطة الاستكمال الدقيقة
المالك يفتح `erp-frontend/companies/company-1/main.html` من محرر GitHub، يطابق توقيعات `RW_Orders` أعلاه، ويطبق فقط الأجزاء المطابقة من Report413. لا تُعلن الإغلاق قبل نشر الواجهة وإثبات SHA المخدوم واختبارات المتصفح والطباعة.
