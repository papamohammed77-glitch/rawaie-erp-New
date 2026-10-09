# Report397 — إصلاح سبب رفض تعديل أوردر بسبب هوية العميل
التاريخ: 2026-10-10
النطاق: Order Taker فقط — تحليل جنائي وجراحة مصدر مطلوبة من المالك
المستودع التشغيلي: `papamohammed77-glitch/erp-frontend`
المستودع التوثيقي: `papamohammed77-glitch/rawaie-erp-New`
Supabase Production: `fiilmooggumokxanwiyx`

## PRE-CHANGE SELF-AUDIT

- Business Understanding: 98/100 — تعديل أوردر Draft/Confirmed غير المرتبط برانشيت لا ينبغي أن يفقد هوية العميل أو يغير العميل عند التعديل.
- Architecture Understanding: 98/100 — مسار التعديل الحالي هو `order-taker.html → update-order (Edge v6) → update_order_atomic`; لا حاجة إلى Edge Function جديدة.
- Database Understanding: 99/100 — عقد RPC يبحث عن العميل داخل الشركة بواسطة `customers.customer_code`، ويحدّث `orders.customer_id` فقط بعد نجاح البحث.
- Historical Understanding: 97/100 — تمت مراجعة Report396 وCommit `f453f74c8e99dc7e2621850ee8087e33148fbfc0`؛ جراحة syncDown ومصدر الإنشاء موجودة الآن في المصدر الحالي، خلافًا للـcheckpoint الأقدم.
- Production Understanding: 98/100 — تمت قراءة Edge `update-order` الحية: v6 ACTIVE و`verify_jwt=true`، ثم قراءة تعريف RPC الحي.
- Current Understanding: 99/100 — تمت قراءة المصدر الحالي الكامل لـ`order-taker.html` وتتبع دالة `_editOrderFromDetail` ومسار `submitOrder`.
- Execution Confidence: 96/100 — السبب الجذري مثبت من الكود الحي وGit وDB. لم يتم تعديل التطبيق أو Production لأن تعليمات المالك تمنعني من لمس ملف التطبيق المستهدف، ويجب أن يطبق المالك الجراحة على ذلك الملف.

### المصادر التي فُحصت

- `CURRENT_STATE.md` الحالي في rawaie-erp-New؛ أحدث checkpoint فيه Report396، لكنه أصبح متقادمًا جزئيًا بالنسبة إلى ملف الواجهة.
- `doc/Draft/Reprots/Report396_ORDER_TAKER_INTEGRATION_PRODUCTION_SOURCE_ATTRIBUTION_20261010.md`.
- المصدر الحالي الكامل: `erp-frontend/companies/company-1/sales/order-taker.html`, Git blob `e1ab0f35218672cc7134cf18a7a35daaa807a757`.
- Commit تاريخي حديث يثبت إدخال Patch A/B/C إلى الملف: `f453f74c8e99dc7e2621850ee8087e33148fbfc0`.
- Production Edge `update-order`: v6 ACTIVE، `verify_jwt=true`، package SHA-256 `a1b06430b9d90777f7d9549286d9c64e7df009c5d15a19917ce6be096a00c8f3`.
- تعريف Production لـ`public.update_order_atomic(uuid,text,text,jsonb,jsonb,text,uuid)`.
- Production schema وبيانات الأوردر/العميل الحالية.
- تمت محاولة قراءة Unified Logs، لكن خدمة الاستعلام أعادت Backend error؛ لم تُستخدم نتيجة logs غير المتاحة كدليل.

## 1. ROOT CAUSE — مثبت

داخل `self._editOrderFromDetail`، يحمّل التطبيق الأوردر ويملأ `selCust` هكذا:

```javascript
selCust = {
    customer_code: order.customer_id || '',
    name: order.customer_name || 'عميل بدون اسم',
    area: order.area || '',
    phone: order.customer_phone || '',
    payment_type: order.payment_type || 'أجل',
    debt: 0,
    credit_limit: 0,
    location: '',
    visit_day: ''
};
```

ثم يبحث عن العميل محليًا بطريقة غير صحيحة:

```javascript
db.customers.where('customer_code').equals(order.customer_id).first()
```

لكن `orders.customer_id` هو UUID يشير إلى `customers.id`، وليس `customers.customer_code`. لذلك يفشل البحث غالبًا، ويبقى UUID في `selCust.customer_code`. وعند الحفظ، يرسل `submitOrder` ذلك UUID في `orderHeader.customer_code`.

في Production RPC، العقد صريح:

```sql
WHERE c.company_id = p_company_id
  AND c.customer_code = NULLIF(BTRIM(p_order_header->>'customer_code'), '')
```

وعندما لا يجد code مطابقًا، يرفع RPC الرسالة `العميل غير موجود ضمن الشركة`. هذه ليست مشكلة في وجود العميل بالشركة، بل خلط بين مفتاحي العميل: `customers.id` و`customers.customer_code`.

## 2. Production facts — إعادة قراءة مباشرة

- `update-order`: v6 ACTIVE؛ `verify_jwt=true`.
- `update_order_atomic` يقيّد البحث بالشركة ويستخدم `customer_code`، ولا يسمح لـanon/authenticated بتنفيذ RPC مباشرة حسب حالة ACL المسجلة في المشروع؛ المسار المقصود هو Edge المصادق عليه.
- فحص سلامة بيانات Production وقت المراجعة: عدد الأوردرات 1، العملاء 3، الأوردرات التي لا يطابق فيها customer_id عميلًا من الشركة نفسها = 0، والروابط العابرة للشركات = 0.
- الأوردر الظاهر حاليًا `ORD-1001` مرتبط بعميل حقيقي في الشركة نفسها، و`customers.customer_code=CUST-158938`. لم أعدّل أو أحذف هذه البيانات؛ لا يوجد إثبات كافٍ لاعتبارها بيانات اختبار آمنة للحذف.
- لم تُجرَ أي كتابة على Production في هذه الدورة.

## 3. التعديل الجراحي المطلوب من المالك

**لا تعدّل** `main.html` أو `core.js` أو Edge/RPC لهذه المشكلة. أصلح المصدر المعيب في ملف التطبيق فقط. لا تغيّر عقد RPC الصحيح ولا تجعله يقبل UUID داخل حقل اسمه customer_code؛ ذلك سيخفي خطأ المستهلك بدل إصلاحه.

### Patch D — استبدال كتلة حلّ هوية العميل في مسار التعديل

- الملف: `erp-frontend/companies/company-1/sales/order-taker.html`
- الدالة: `self._editOrderFromDetail = function(orderId)`
- محدد البحث الفريد:
  `// ✅ بناء selCust من بيانات الطلب مباشرة (حتى لو العميل غير موجود في Dexie)`
- احذف الكتلة كاملة من هذا التعليق حتى نهاية فرع `else { _commitEditCart(myGeneration); }` الذي يسبق تعريف `function _commitEditCart(myGen)`.
- استبدلها بالنص الكامل التالي:

```javascript
            // Resolve the order's customer by the canonical customers.id UUID.
            // Never place orders.customer_id into selCust.customer_code.
            function failCustomerResolution(error) {
                if (myGeneration !== _rwRenderGeneration) return;
                console.error('تعذر حل هوية عميل الأوردر:', error);
                cart = [];
                selCust = null;
                selBranch = null;
                editingOrderCode = null;
                RW_UI.hideLoader();
                RW_UI.toast('تعذر التحقق من العميل المرتبط بالأوردر؛ لم يتم فتح التعديل. حدّث بيانات العملاء ثم أعد المحاولة.', 'error');
                self.switchTab('my-orders');
            }

            function commitResolvedCustomer(customer) {
                if (myGeneration !== _rwRenderGeneration) return;
                if (!customer || !customer.customer_code ||
                    String(customer.company_id) !== String(order.company_id)) {
                    failCustomerResolution(new Error('Customer missing, code missing, or company mismatch'));
                    return;
                }
                selCust = customer;
                _commitEditCart(myGeneration);
            }

            if (!order.customer_id) {
                // Legacy order without customer_id: preserve legacy behavior without
                // inventing a customer code. The RPC will retain the existing customer.
                selCust = {
                    customer_code: '',
                    name: order.customer_name || 'عميل بدون اسم',
                    area: order.area || '',
                    phone: order.customer_phone || '',
                    payment_type: order.payment_type || 'أجل',
                    debt: 0,
                    credit_limit: 0,
                    location: '',
                    visit_day: '',
                    company_id: order.company_id
                };
                _commitEditCart(myGeneration);
            } else {
                db.customers.toArray().then(function(localCustomers) {
                    var match = null;
                    for (var i = 0; i < localCustomers.length; i++) {
                        var candidate = localCustomers[i];
                        if (String(candidate.id) === String(order.customer_id) &&
                            String(candidate.company_id) === String(order.company_id)) {
                            match = candidate;
                            break;
                        }
                    }
                    if (match && match.customer_code) {
                        commitResolvedCustomer(match);
                        return null;
                    }

                    // Cache miss/staleness: resolve by UUID from Production under
                    // the current user's RLS, and explicitly constrain company_id.
                    return supabase.from('customers')
                        .select('*')
                        .eq('id', order.customer_id)
                        .eq('company_id', order.company_id)
                        .maybeSingle()
                        .then(function(result) {
                            if (result.error) throw result.error;
                            if (!result.data) {
                                throw new Error('Customer UUID not visible in this company');
                            }
                            commitResolvedCustomer(result.data);
                        });
                }).catch(failCustomerResolution);
            }
```

**الأثر المتوقع:** عند فتح أوردر للتعديل، يحل التطبيق `orders.customer_id → customers.id → customers.customer_code`، ويتأكد من تطابق الشركة، ثم يرسل code القانوني إلى RPC. عند تعذر التحقق، يُجهض فتح التعديل بدل إرسال UUID خاطئ أو السماح بتغيير عميل غير مقصود.

### Patch E — نفس الخلط في «إعادة الطلب» (مسار مجاور مثبت)

- الملف نفسه.
- الدالة: `self.repeatOrder`.
- محدد البحث:
  `if (order.customer_id) db.customers.where('customer_code').equals(order.customer_id).first().then(function(c) { if (c) { selCust = c; self.selectCustomer(c.customer_code); } });`
- لا تستبدل الدالة الكاملة المختصرة؛ استبدل هذا التعبير وحده بالنص التالي:

```javascript
if (order.customer_id) {
    db.customers.toArray().then(function(localCustomers) {
        var customer = null;
        for (var j = 0; j < localCustomers.length; j++) {
            if (String(localCustomers[j].id) === String(order.customer_id) &&
                String(localCustomers[j].company_id) === String(order.company_id)) {
                customer = localCustomers[j];
                break;
            }
        }

        if (customer && customer.customer_code) {
            self.selectCustomer(customer.customer_code);
            return;
        }

        return supabase.from('customers')
            .select('*')
            .eq('id', order.customer_id)
            .eq('company_id', order.company_id)
            .maybeSingle()
            .then(function(result) {
                if (result.error) throw result.error;
                if (!result.data || !result.data.customer_code) {
                    throw new Error('تعذر التحقق من العميل داخل الشركة');
                }
                self.selectCustomer(result.data.customer_code);
            });
    }).catch(function(error) {
        console.error('تعذر حل عميل إعادة الطلب:', error);
        RW_UI.toast('تعذر التحقق من العميل؛ لم تتم إعادة الطلب', 'error');
    });
}
```

## 4. ما هو صحيح ويجب تمريره دون إعادة إصلاحه

- Patch A موجود في Current: `hdr.source = 'order-taker'` داخل فرع الإنشاء فقط.
- Patch B موجود في Current: `syncDown` يفحص `result.error` قبل مسح Dexie ويحدّث الجداول داخل transaction.
- Patch C موجود في Current: `enterApp` يعالج فشل syncDown ويحتفظ بالبيانات المحلية.
- Commit `f453f74c8e99dc7e2621850ee8087e33148fbfc0` يثبت هذه التغييرات؛ لذلك تقرير Report396/Checkpoint أقدم من المصدر الحالي في هذا الجزء.
- مسار edit يبقى `update-order → update_order_atomic`; لا يُعاد إنشاء الأوردر ولا يُربط بالرانشيت من Order Taker. لا تتغير حركة المخزون أو حالة الرانشيت ضمن هذا الإصلاح.

## 5. الاختبارات المطلوبة بعد تطبيق الجراحة والنشر

1. افتح `ORD-1001` أو أوردرًا آمنًا قابلًا للتعديل، وتأكد أن العميل المعروض هو نفس `customers.id` المرتبط بالأوردر.
2. راقب Payload لـ`update-order`: `orderHeader.customer_code` يجب أن يساوي `customers.customer_code` (مثل `CUST-158938`) وليس UUID.
3. عدّل ملاحظة أو كمية صنف مع الإبقاء على العميل؛ تأكد من نجاح التحديث وبقاء `orders.customer_id` كما هو.
4. تحقق من أن الأوردر المرتبط برانشيت أو بحالة غير مسموح بها يظل مرفوضًا حسب العقد الحالي.
5. تحقق من عزل الشركة: لا يقبل resolver عميلًا من company أخرى.
6. اختبر cache hit، وcache miss مع نجاح الاستعلام، وفشل الاستعلام؛ في الحالة الأخيرة يجب ألا يُرسل update-order.
7. اختبر «إعادة الطلب» وأثبت أن customer_code القانوني يُستخدم.
8. تحقق من عدم حدوث أي تغيير في `stock_branches` أو `inventory_log` أو روابط الرانشيت من هذا المسار.
9. بعد الاختبارات، احذف فقط fixture التي ثبت أنها تجريبية وبلا آثار تشغيلية، ثم أعد فحص baseline. لا تحذف `ORD-1001` الحالي تلقائيًا؛ يجب أولًا إثبات أنه fixture وأنه بلا آثار تابعة.

## 6. ما لم يتم تنفيذه أو إثباته

- لم ألمس ملف التطبيق التشغيلي؛ الجراحة أعلاه جاهزة ليطبقها المالك.
- لم أغيّر Production Edge أو RPC أو schema، لأن عقد قاعدة البيانات صحيح والمشكلة في قيمة المستهلك.
- تعذرت قراءة Unified Logs بسبب Backend error من أداة السجلات؛ لا أدعي وجود log محدد يثبت الطلب الفاشل.
- لم يُنفذ HTTP/Browser E2E بعد الجراحة، ولم يُثبت Cloudflare Pages/Service Worker parity.
- حالة `ORD-1001` الحالية لم تُحذف، ولم أعتبرها fixture دون دليل.

## SELF-AUDIT FINAL

**What I Proved**
- الخطأ سببه إرسال UUID الخاص بـ`orders.customer_id` داخل `orderHeader.customer_code` من `_editOrderFromDetail`.
- Production RPC يبحث باستخدام `customers.customer_code` ضمن `company_id`، ولذلك يرفض UUID إذا لم يطابق code.
- سجل Production الحالي لا يظهر orphan أو cross-company customer link في فحص التحقق.
- المصدر الحالي يحتوي بالفعل Patch A/B/C، خلافًا إلى checkpoint Report396 القديم.

**What I Did Not Prove**
- لم أقرأ log event محددًا للطلب الفاشل لأن خدمة Unified Logs أعادت خطأ backend.
- لم أثبت runtime بعد تطبيق Patch D/E أو تطابق Cloudflare artifact.

**What I Fixed**
- لا توجد كتابة في Production ولا تعديل في ملف التطبيق امتثالًا لتوجيه المالك. حُددت جراحة دقيقة وجاهزة للاستبدال في Patch D/E.

**What I Initially Missed**
- Checkpoint Report396 لم يعكس blob الواجهة الحالي؛ تمت إعادة قراءة Current Git والـcommit بدل اتباعه آليًا.
- علة الهوية تقع في `_editOrderFromDetail`، لا في وجود العميل داخل الشركة أو في Edge authentication.

**What Could Still Be Wrong**
- قد توجد مسارات أخرى تحول `customer_id` إلى `customer_code`؛ Patch E يغطي إعادة الطلب المباشر، ويجب إجراء consumer sweep قبل إعلان إغلاق تكامل Order Taker بالكامل.
- served artifact لم يُثبت.

**Final Confidence:** 98/100 في تحديد السبب الجذري؛ غير مغلق Runtime حتى تطبيق الجراحة واختبارها.

**Final Closure Status:** `ROOT CAUSE VERIFIED / OWNER SURGICAL PATCHES D AND E REQUIRED / PRODUCTION CONTRACT UNCHANGED / NOT CLOSED`.
