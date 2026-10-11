# Report406 — POS: إصلاح عقد المرتجع النقدي ومزامنة المصدر
**التاريخ:** 2026-10-11  
**Production:** Supabase project \`fiilmooggumokxanwiyx\`  
**Frontend:** \`papamohammed77-glitch/erp-frontend\`  
**Governance repo:** \`papamohammed77-glitch/rawaie-erp-New\`

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** مرتجع POS يجب أن يعيد الكمية المؤهلة عبر محرك المخزون المركزي، ويمنع تجاوز الكمية المباعة/المتبقية، وينشئ إشعارًا دائنًا، ويعيد المبلغ النقدي فعليًا إلى مصدر التحصيل الأصلي مرة واحدة.
- **Architecture Understanding:** \`pos.html → complete-return (Edge) → complete_sales_return_credit_note_atomic → complete_return_atomic → post_stock_movement\`. رد النقد يتم عبر Core المالي الحالي \`post_cash_payment_atomic\`، ولا توجد Edge Function جديدة.
- **Database Understanding:** \`orders.payment_type\` و\`orders.source\` و\`orders.original_total_amount\` و\`orders.discount_amount\` موجودة. إيصال POS النقدي يسجل في \`cash_box\` مع \`source_type='POS'\` و\`source_id=orders.id\` و\`reference=order_code\`، ويرتبط بالخزينة المستخدمة في البيع.
- **Historical Understanding:** تمت مراجعة CURRENT_STATE الحالي، وReport404/405، ومصدر POS الحالي، وتعريفات Production الفعلية. بعض أسماء migrations التاريخية الموجودة في سجل قاعدة البيانات لم يمكن استرداد ملفاتها من مسارات Git المتوقعة؛ لم أتعامل مع ذلك كدليل على غيابها من كل الفروع.
- **Production Understanding:** \`complete-return\` ما زالت v26 مع \`verify_jwt=true\`. تم تعديل Core SQL فقط عبر migrations مسجلة في Production؛ ACL بقي service_role-only.
- **Current Understanding:** \`pos.html\` لم يُعدّل. Blob الحالي \`967d486147cf3ca9911c4dbd3ba89042c373577e\`، والـcommit المسجل \`950abb6b78680d37c8d29f1beba78c8c1d6a51a4\`.
- **Execution Confidence:** عالٍ في إثبات سبب فشل مرتجع النقدي وفي مزامنة Core المنشور؛ متوسط في سلوك الواجهة لأن اختبار المتصفح الفعلي غير متاح، واختبار DML المعزول رُفض بواسطة طبقة أمان الأدوات قبل التنفيذ.

### الأدلة الحالية

- Production \`get_pos_invoice_data(text,text)\` موجودة، وتتحقق من صلاحية POS ونطاق الشركة والفروع.
- محاكاة claims للمستخدم \`cashier@rawaea.com\` أعادت الفرع \`BR-01\`، وأعادت \`ORD-1004\` مع 3 تفاصيل و\`ORD-1005\` مع تفصيلين. هذا **DB claim simulation** وليس HTTP/browser E2E.
- \`ORD-1004\`: فاتورة POS نقدية بمبلغ 275.00، و\`customer_id=NULL\`، وإيصال قبض فعلي مرتبط بالخزينة الرئيسية.
- \`ORD-1005\`: فاتورة POS نقدية بمبلغ 185.00، و\`customer_id=NULL\`، وإيصال قبض فعلي مرتبط بالخزينة الرئيسية.
- لم أغيّر الفاتورتين أو أي بيانات مالية تخصهما.
- رصيد الخزينة الرئيسية بقي \`10645.00\` في قراءة التحقق، وعدد صفوف QA للمرتجع النقدي = 0.

## 1. السبب الجذري

### أ. رسالة «الفاتورة غير موجودة في فروع POS المصرح بها»

هذه الرسالة تظهر من \`self._searchReturnInvoice\` فقط عندما يعيد RPC استجابة ناجحة لكن \`payload.order\` فارغًا. المصدر الحالي يستعمل بالفعل:

\`\`\`js
self._getPosInvoiceData('return_lookup', code)
\`\`\`

والمحاكاة المباشرة على Production أثبتت أن الفاتورتين المعروفتيْن \`ORD-1004\` و\`ORD-1005\` تُسترجعان للمستخدم المصرح به. لذلك لا يوجد دليل يبرر إعادة كتابة \`_searchReturnInvoice\` أو توسيع صلاحيات الفروع. **كود الفاتورة الذي فشل فعليًا في المتصفح غير موجود في السجلات المتاحة**؛ يلزم التقاطه من Network إن استمرت الرسالة على فاتورة أخرى.

### ب. عيب مرتجع النقدي الفعلي

كان \`complete_return_atomic\` يرفض كل مرتجع ذي قيمة إيجابية عندما يكون \`v_order.customer_id IS NULL\` بالخطأ:

\`\`\`
RETURN_CUSTOMER_REQUIRED_FOR_FINANCIAL_POSTING
\`\`\`

وهذا يتعارض مع نموذج POS النقدي الفعلي: العميل النقدي قد لا يملك سجل عميل، بينما يوجد إيصال قبض وخزينة أصلية. حذف شرط العميل وحده لم يكن حلًا؛ لأنه لا يرد المال.

## 2. ما نُفذ في Production

تم تعديل الدالة القائمة \`public.complete_return_atomic(uuid,text,text,boolean,text,jsonb)\`، دون إنشاء Edge Function جديدة، لتضيف ما يلي:

1. عند مرتجع POS نقدي، تحديد إيصال البيع الأصلي من \`cash_box\` باستخدام الشركة والفاتورة ونوع الإيصال ومصدره.
2. رفض العملية إذا لم يوجد إيصال أصلي وحيد مطابق أو لم يتطابق مبلغ الإيصال مع قيمة الفاتورة الأصلية.
3. احتساب قيمة المرتجع بعد توزيع خصم الفاتورة على قيمة الأصناف بالتناسب؛ لا يعيد عقد مرتجع البضاعة رسوم التوصيل.
4. فحص مجموع المبالغ التي سبق ردها على الفاتورة، ومنع رد يتجاوز قيمة التحصيل النقدي غير المرتجعة.
5. تنفيذ الصرف عبر \`post_cash_payment_atomic\`؛ أي تسجيل سند صرف وقيد يومية متوازن وتخفيض رصيد **الخزينة نفسها المرتبطة بإيصال البيع**.
6. استخدام \`operation_id\` ثابت مشتق من مفتاح العملية لمنع تكرار الصرف عند إعادة المحاولة.
7. إرجاع \`refund_posted\` و\`refund_amount\` و\`refund_reference\` و\`refund_cash_box_id\` و\`refund_operation_id\` و\`refund_treasury_id\` للواجهة.
8. رفض قيمة المرتجع الصفرية برسالة \`POS_RETURN_NO_RETURNABLE_VALUE\` بدل إنشاء نجاح/إشعار دائن فارغ.
9. إبقاء الصلاحيات محصورة في \`service_role\`: \`anon=false\` و\`authenticated=false\` و\`service_role=true\`.

### migrations المسجلة

- \`supabase/migrations/20261011_pos_cash_return_refund_atomic.sql\`
- \`supabase/migrations/20261011_pos_return_zero_value_guard.sql\`

روابط:
- [POS cash return core migration](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/supabase/migrations/20261011_pos_cash_return_refund_atomic.sql)
- [POS zero-value return guard](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/supabase/migrations/20261011_pos_return_zero_value_guard.sql)

لم يتم نشر نسخة Edge جديدة؛ \`complete-return\` الحالية v26 تستدعي Wrapper الحالي، وهو يستدعي Core المعدل.

## 3. القرار الجراحي الخاص بالواجهة — لم يتم تطبيقه على الملف

**ممنوع تعديل \`main.html\` أو \`companies/company-1/sales/pos.html\` من جانبي.** لا يوجد مبرر لإعادة إصلاح دوال البحث أو التنقل الموجودة أصلًا. المطلوب في الواجهة هو تعديل دالة الإنهاء فقط لتعرض نتيجة الصرف التي يؤكدها الخادم بدل الرسالة الحالية التي تقول إن رد النقد لم يتم.

- **الملف:** \`erp-frontend/companies/company-1/sales/pos.html\`
- **الدالة:** \`self._finalizeReturn\`
- **محدد البحث:** ابحث عن النص الحرفي \`self._finalizeReturn = function() {\`
- **العنصر المعيب:** كتلة النجاح التي تعرض \`تم تسجيل المرتجع وفق عقد الإشعار الدائن. لم يتم تنفيذ رد نقدي أو رد للبطاقة من هذه الشاشة.\`
- **الإجراء:** استبدل دالة \`self._finalizeReturn\` كاملة بالنص التالي. لا تستبدل أي دالة أخرى.

~~~javascript
self._finalizeReturn = function() {
    var orderCode = returnOriginalInvoice ? returnOriginalInvoice.order_code : null;
    var items = [];

    if (!orderCode) {
        RW_UI.showError('لم يتم تحديد الفاتورة الأصلية؛ لم يُرسل المرتجع');
        return;
    }

    for (var i = 0; i < returnCart.length; i++) {
        var it = returnCart[i];
        if (Number(it.returnQty) > 0) {
            items.push({
                item_code: it.code,
                item_name: it.name,
                unit_price: Number(it.price) || 0,
                returnedQty: Number(it.returnQty),
                return_condition: 'good',
                reason: 'مرتجع نقطة بيع'
            });
        }
    }

    if (!items.length) {
        RW_UI.toast('لا توجد أصناف في سلة المرتجع', 'warning');
        return;
    }

    RW_UI.showLoader('جاري تسجيل المرتجع ورد المبلغ النقدي...');
    RW_API.call('complete-return', {
        runsheet_code: null,
        order_code: orderCode,
        items: items,
        is_pos_return: true,
        reason: 'مرتجع نقطة بيع'
    }, function(json, err) {
        RW_UI.hideLoader();

        if (err || !json || json.success !== true) {
            RW_UI.byId('returnPaymentModal').classList.remove('hidden');
            RW_UI.showError((json && (json.msg || json.error)) ||
                (err && String(err)) ||
                'فشل تسجيل المرتجع؛ لم يتم تفريغ السلة');
            return;
        }

        if (json.refund_posted !== true) {
            RW_UI.byId('returnPaymentModal').classList.remove('hidden');
            RW_UI.showError('لم يؤكد الخادم رد المبلغ؛ احتفظنا بالسلة ولم نعلن نجاح الصرف');
            return;
        }

        var newStatus = json.new_order_status || 'Returned';
        var isPartial = newStatus === 'Partially Returned';
        var refundAmount = Number(json.refund_amount) || 0;
        var refundReference = self._escapePosText(json.refund_reference || orderCode);
        var creditNoteCode = self._escapePosText(json.creditNoteCode || '—');
        var cashBoxId = self._escapePosText(json.refund_cash_box_id || '—');

        returnCart = [];
        returnOriginalInvoice = null;
        _returnTotal = 0;
        self.closeReturnPaymentModal();

        Swal.fire({
            icon: isPartial ? 'warning' : 'success',
            title: isPartial ? 'تم المرتجع الجزئي ورد المبلغ' : 'تم المرتجع ورد المبلغ',
            html: '<div class="text-right text-white text-sm">' +
                '<p>عدد الأصناف المرتجعة: <strong>' + items.length + '</strong></p>' +
                '<p>المبلغ النقدي المصروف فعليًا: <strong class="text-emerald-300">' +
                    fmtNum(refundAmount) + ' ' + self._escapePosText(currency) + '</strong></p>' +
                '<p>مرجع الفاتورة: <strong>' + refundReference + '</strong></p>' +
                '<p>الإشعار الدائن: <strong>' + creditNoteCode + '</strong></p>' +
                '<p>سند الصرف: <strong>' + cashBoxId + '</strong></p>' +
                '<p>حالة الفاتورة: <strong>' + self._escapePosText(newStatus) + '</strong></p>' +
                '<p class="text-amber-300 mt-3">تم رد النقد إلى الخزينة المرتبطة بإيصال البيع الأصلي.</p>' +
                '</div>',
            confirmButtonText: 'حسنًا',
            customClass: {
                popup: '!bg-slate-900 !rounded-3xl !border !border-slate-700',
                confirmButton: isPartial ? '!bg-amber-600 !rounded-xl' : '!bg-emerald-600 !rounded-xl'
            }
        });

        self.switchView('invoices');
    });
};
~~~

**التأثير المتوقع:** لن تعرض الواجهة نجاح المرتجع إلا إذا أعاد الخادم \`refund_posted=true\`، وستعرض المبلغ المصروف ومرجع الفاتورة والإشعار الدائن وسند الصرف.  
**الاختبار بعد تطبيق الرقعة:** مرتجع نقدي جزئي، ثم باقي الأصناف، ثم إعادة إرسال نفس الطلب، ثم فاتورة غير نقدية يجب أن تُرفض برسالة واضحة دون حركة مخزون أو قيد مالي.

## 4. الاختبارات ونتائجها

| الاختبار | النتيجة |
|---|---|
| Production function signature/security | PASS — الدالة موجودة و\`SECURITY DEFINER\`؛ EXECUTE لـservice_role فقط |
| Current Edge identity | VERIFIED — \`complete-return\` v26، \`verify_jwt=true\` |
| POS read RPC / branch scope | PASS في محاكاة claims لفرع BR-01 |
| \`ORD-1004\` و\`ORD-1005\` lookup | PASS في محاكاة DB؛ لا يمثل اختبار HTTP/browser |
| Production data safety | PASS — الفاتورتان لم تُعدّلا |
| QA residue | PASS — \`qa_orders=0\` و\`qa_refunds=0\` |
| Treasury baseline | PASS — الرصيد المقروء \`10645.00\` |
| Refund transactional E2E | **UNVERIFIED** — طبقة أمان الأدوات رفضت تنفيذ SQL الذي ينشئ Fixture داخل معاملة اختبارية؛ لم يُنشأ Fixture |
| Browser/HTTP E2E | **OPEN** — لا توجد جلسة متصفح/Network متاحة هنا |
| Hosted asset parity | **OPEN** — لم يثبت تطابق الملف الذي يخدمه Cloudflare مع Blob الحالي |

## 5. حدود العقد الحالي التي لا يجوز إخفاؤها

- Production لا يحتوي كيانًا مثبتًا لوردية/درج نقدي مستقل لكل كاشير. عقد البيع الحالي يفرض خزينة نشطة واحدة ويودع إيصال POS فيها؛ لذلك الإصلاح يرد المال إلى **الخزينة المسجلة في الإيصال الأصلي**، ولا يدّعي أنه خصم من درج كاشير مستقل.
- رد البطاقة/المختلط غير مدعوم بعقد موثق أو معالج دفع في Production. يرفض Core هذه الحالات بدل إنشاء إشعار دائن يوهم بأن رد البطاقة قد تم.
- لم أغيّر \`pos.html\` أو \`main.html\`. تطبيق الرقعة أعلاه ونشرها واختبار المتصفح ما زال مطلوبًا من مالك الملف.
- لم أستخدم \`ORD-1004\` أو \`ORD-1005\` كبيانات اختبار ولم أعدّلها.

## SELF-AUDIT FINAL

- **What I Proved:** سبب فشل العميل النقدي ذي \`customer_id=NULL\`؛ أن قراءة الفاتورتين المعروفتين تعمل ضمن نطاق BR-01؛ أن Core المعدل منشور في Production مع حدود التنفيذ الصحيحة؛ وأن رصيد الخزينة وبيانات الفواتير لم يتغيرا خلال التحقق.
- **What I Did Not Prove:** تنفيذ HTTP/browser لمرتجع حقيقي، تطابق ملف Cloudflare المنشور مع Git، أو وجود درج مستقل لكل كاشير.
- **What I Fixed:** عقد Production النقدي أصبح يستخرج إيصال البيع الأصلي، ويمنع التكرار/تجاوز مبلغ التحصيل، ويستخدم \`post_cash_payment_atomic\` للصرف الفعلي، ويرجع تفاصيل الصرف؛ أضيف منع نجاح المرتجع الصفري.
- **What I Initially Missed:** رسالة «الفاتورة غير موجودة» ليست دليلًا كافيًا على عطل RPC؛ كما أن إشعارًا دائنًا وحده ليس ردًا نقديًا.
- **What Could Still Be Wrong:** سلوك الواجهة المنشورة قد يختلف عن Git؛ ويظل نموذج درج الكاشير ورد البطاقة خارج العقد الحالي.
- **Final Confidence:** عالٍ في مزامنة Core/ACL وقراءة الفاتورتين؛ متوسط في تنفيذ المرتجع الكامل لغياب E2E.
- **Final Closure Status:** \`CORE CASH REFUND REPAIR DEPLOYED / POS SOURCE PATCH PENDING OWNER / HTTP-BROWSER E2E OPEN / CASHIER-SHIFT AND CARD REFUND CONTRACT OPEN / POS NOT 100% CLOSED\`.

## تعليمات الاستئناف

1. ابدأ بقراءة Production function الحالية وACL في نفس الجلسة، لا تعتمد على هذا التقرير وحده.
2. راجع آخر commit وBlob لـ\`pos.html\`؛ لا تعِد كتابة \`_searchReturnInvoice\` أو \`switchView\` ما لم يظهر دليل جديد.
3. طبّق استبدال \`_finalizeReturn\` كاملًا فقط، ثم انشر عبر المسار المعتمد.
4. نفّذ HTTP/browser E2E باستخدام فاتورة QA معزولة، ثم تحقق من \`cash_box\` و\`treasury\` و\`journal_entries\` و\`credit_notes\` ومخزون الفرع، وأعد baseline إلى ما كان عليه.
5. لا تعلن إغلاق POS حتى يُثبت درج الكاشير/الوردية أو يُعتمد صراحةً أن الخزينة المشتركة هي العقد المقصود، ويُحسم عقد رد البطاقة.
