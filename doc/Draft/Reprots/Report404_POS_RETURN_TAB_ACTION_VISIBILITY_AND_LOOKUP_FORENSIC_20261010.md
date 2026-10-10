# Report404 — POS Return Tab UI State and Invoice Lookup Forensic Review

**التاريخ:** 2026-10-10  
**النطاق:** تطبيق الكاشير فقط — تبويب «مرتجع»، البحث عن فاتورة POS، حالة أزرار الجانب، وتكاملها مع Production.  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend`  
**Production:** Supabase project `fiilmooggumokxanwiyx`

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** الكاشير يجب أن ينتقل بين البيع والمعلقة وفواتير اليوم والمرتجع دون بقاء أزرار عملية مختلفة عن الشاشة النشطة. البحث عن فاتورة مرتجع يجب أن يقرأ فاتورة POS ضمن الشركة والفروع المصرح بها فقط.
- **Architecture Understanding:** POS frontend → authenticated RPC `get_pos_invoice_data` لقراءة الفواتير؛ تسجيل المرتجع يمر عبر `complete-return` ثم `complete_sales_return_credit_note_atomic` و`complete_return_atomic`.
- **Database Understanding:** تم فحص تعريف RPC الحي، ACL، نطاق الفروع، وفواتير Production الموجودة. لم يتم تعديل جداول أو بيانات.
- **Historical Understanding:** راجعت `CURRENT_STATE.md` وReport402 وReport403 وcommit `3b27e45adbdfcea4a08f414b2dc5a9082f1be422`. هذا الـcommit سبق أن استبدل القراءة المباشرة من `orders/order_details` بالـRPC؛ لا تكرر ذلك الإصلاح.
- **Production Understanding:** Production هو المرجع لهذه الدورة. بيانات الكاشير الحية تعيد فرع `BR-01 / الفرع الرئيسي` فقط، وRPC قراءة الفواتير منشورة ومسموح بها لـauthenticated، ومرفوضة لـanon.
- **Current Understanding:** POS blob الحالي `21c6a0b318b9eb629f8f1917f9b3a4bbf21decfa`. دوال البحث والقراءة عبر RPC موجودة. لم يتم تعديل `main.html` أو `pos.html`.
- **Execution Confidence:** مرتفع في RPC/ACL وقراءة الفواتير المعروفة؛ مرتفع في وجود خلل في مزامنة أزرار الواجهة داخل `switchView`؛ غير كافٍ لإثبات أن سبب كل رسالة «الفاتورة غير موجودة» هو خلل backend، لأن سجل PostgREST لا يحتفظ بنص رقم الفاتورة المرسل.

### مصادر Production التي تمت مطابقتها

- `public.get_pos_invoice_data(text,text)`: `SECURITY DEFINER`, `search_path=''`.
- ACL الفعلي: `anon EXECUTE=false`, `authenticated EXECUTE=true`, `service_role EXECUTE=true`.
- `get_pos_branches()` تحت claims الخاصة بحساب `cashier@rawaea.com` يعيد `BR-01 / الفرع الرئيسي` ضمن الشركة `00000000-0000-0000-0000-000000000001`.
- `ORD-1004`: POS، `BR-01`، Invoiced، إجمالي 275.00، 3 تفاصيل.
- `ORD-1005`: POS، `BR-01`، Invoiced، إجمالي 185.00، تفصيلان.
- محاكاة claims لقراءة `today` أعادت الفاتورتين. و`return_lookup` أعادت تفاصيل `ORD-1004` و`ORD-1005`.
- سجل PostgREST يحتوي طلبات حقيقية من جلسة مصادق عليها إلى `/rest/v1/rpc/get_pos_invoice_data` مع HTTP 200، أحدثها في `2026-10-10 17:25:41Z`. السجلات لا تعرض payload، ولذلك لا تثبت أي رقم فاتورة كُتب عند كل محاولة.

## 1. Root cause المثبت في الواجهة

الملف:
`companies/company-1/sales/pos.html`

الدالة:
`self.switchView = function(view)`

السلوك الحالي يغيّر حالة أزرار الجانب فقط داخل فرع `if (view === 'pos')`. عند الانتقال إلى `returns` أو `invoices` أو `suspended` لا يتم إخفاء أزرار البيع ولا إظهار `cartActionsReturn` و`btnPayReturn` بحسب الشاشة النشطة. نتيجة ذلك أن الواجهة قد تبقى تعرض أزرار دفع/سلة لا تخص التبويب الحالي؛ وهذا خلل تكامل UI مثبت من المصدر، حتى وإن كانت دالة التنقل نفسها تستدعي `renderReturnsView()`.

## 2. التعديل الجراحي المطلوب — يطبقه مالك الملف التشغيلي

**لا تعدّل `main.html`. لا تعدّل `pos.html) من جانب المساعد.** الملف التشغيلي محمي لتطبيق التعديل من المالك.

### محدد البحث الدقيق

ابحث في `companies/company-1/sales/pos.html` عن النص الكامل التالي:

```javascript
    self.switchView = function(view) {
        currentView = view;
        var views = ['pos', 'suspended', 'invoices', 'returns'];
        for (var i = 0; i < views.length; i++) { var b = RW_UI.byId('nav-' + views[i]); if (b) b.classList.remove('active'); }
        var a = RW_UI.byId('nav-' + view); if (a) a.classList.add('active');
        if (view === 'pos') { 
            self.renderProducts(); 
            self.updateCartUI(); 
            RW_UI.byId('cartActionsNormal').classList.remove('hidden');
            RW_UI.byId('btnPayNormal').classList.remove('hidden');
            RW_UI.byId('cartActionsReturn').classList.add('hidden');
            RW_UI.byId('btnPayReturn').classList.add('hidden');
        }
        else if (view === 'suspended') self.renderSuspendedView();
        else if (view === 'invoices') self.renderInvoicesView();
        else if (view === 'returns') self.renderReturnsView();
    };
```

**احذف الدالة كاملة واستبدلها بالنص الكامل التالي:**

```javascript
    self.switchView = function(view) {
        var allowedViews = ['pos', 'suspended', 'invoices', 'returns'];
        if (allowedViews.indexOf(view) === -1) {
            console.error('Unsupported POS view:', view);
            return;
        }

        currentView = view;

        for (var i = 0; i < allowedViews.length; i++) {
            var navButton = RW_UI.byId('nav-' + allowedViews[i]);
            if (navButton) navButton.classList.remove('active');
        }

        var activeButton = RW_UI.byId('nav-' + view);
        if (activeButton) activeButton.classList.add('active');

        var isSaleView = view === 'pos';
        var isReturnView = view === 'returns';

        var normalActions = RW_UI.byId('cartActionsNormal');
        var returnActions = RW_UI.byId('cartActionsReturn');
        var normalPayButton = RW_UI.byId('btnPayNormal');
        var returnPayButton = RW_UI.byId('btnPayReturn');

        if (normalActions) {
            if (isSaleView) normalActions.classList.remove('hidden');
            else normalActions.classList.add('hidden');
        }

        if (returnActions) {
            if (isReturnView) returnActions.classList.remove('hidden');
            else returnActions.classList.add('hidden');
        }

        if (normalPayButton) {
            if (isSaleView) normalPayButton.classList.remove('hidden');
            else normalPayButton.classList.add('hidden');
        }

        if (returnPayButton) {
            if (isReturnView) returnPayButton.classList.remove('hidden');
            else returnPayButton.classList.add('hidden');
        }

        if (isSaleView) {
            self.renderProducts();
            self.updateCartUI();
        } else if (view === 'suspended') {
            self.renderSuspendedView();
        } else if (view === 'invoices') {
            self.renderInvoicesView();
        } else if (isReturnView) {
            self.renderReturnsView();
        }
    };
```

### التأثير المتوقع

- «البيع»: تظهر أزرار البيع والدفع العادية فقط.
- «مرتجع»: تظهر أزرار المرتجع فقط ولا يبقى زر دفع فاتورة بيع ظاهرًا.
- «فواتير اليوم» و«معلقة»: لا تبقى أزرار دفع/مرتجع غير مرتبطة بالشاشة.
- يحافظ التعديل على أسماء الدوال وواجهات RPC وEdge Functions، ولا ينشئ Edge Function أو يغير قاعدة البيانات.

## 3. تشخيص «الفاتورة غير موجودة في فروع POS المصرح بها»

الـRPC الحالي يبحث باستخدام شروط الشركة، والفرع المصرح به، و`source='pos'`. هذا السلوك مقصود أمنيًا. ثبت أن `ORD-1004` و`ORD-1005` موجودتان ويمكن استرجاعهما ضمن `BR-01` باستخدام claims المصادق عليها؛ لذلك لا يوجد دليل يبرر توسيع RLS أو إزالة شرط الفرع أو تغيير هوية الفاتورة.

**ما لم يُثبت بعد:** لا تعرض سجلات PostgREST رقم الفاتورة المرسل في المحاولات التي سجلت HTTP 200. لذلك لا يمكن الجزم أن المستخدم كتب `ORD-1004` أو `ORD-1005` في المحاولة الفاشلة. بعد تطبيق الجراحة، اختبر هذين الرقمين حرفيًا. إذا نجحا بينما الرقم الأصلي لا ينجح، فالمطلوب تحديد هل الرقم الأصلي فاتورة POS فعلًا وهل يقع في الشركة/الفروع المصرح بها؛ لا يجوز تجاوز العزل لمعالجة رسالة عامة.

## 4. الاختبارات

### اختبارات قاعدة البيانات المنفذة في هذه الدورة

| الاختبار | النتيجة |
|---|---|
| حساب الكاشير يستخرج الفرع المصرح به | PASS — BR-01 فقط |
| `today` تحت claims المصادق عليها | PASS — ORD-1004 وORD-1005 |
| `return_lookup(ORD-1004)` | PASS — 3 تفاصيل، الإجمالي 275.00 |
| `return_lookup(ORD-1005)` | PASS — تفصيلان، الإجمالي 185.00 |
| ACL: منع anon والسماح authenticated | PASS |
| كتابة بيانات أعمال تجريبية أو تغيير المخزون | لم تتم؛ اختُبرت مسارات القراءة باستخدام البيانات الموجودة |

### اختبارات المتصفح المطلوبة بعد تطبيق الجراحة ونشر الملف

1. افتح POS مع `cashier@rawaea.com` ثم اضغط «مرتجع»: يجب أن تظهر شاشة البحث وأزرار المرتجع فقط.
2. اضغط «فواتير اليوم» ثم «معلقة» ثم «البيع»؛ تحقق من تبدل الأزرار وعدم بقاء زر الدفع في تبويب آخر.
3. ابحث حرفيًا عن `ORD-1004`: يجب أن تظهر ثلاثة أسطر وإجمالي 275.00.
4. ابحث حرفيًا عن `ORD-1005`: يجب أن يظهر سطران وإجمالي 185.00.
5. جرّب رقمًا غير موجود؛ يجب أن تظهر رسالة عدم العثور دون تغيير المخزون أو إنشاء مرتجع.
6. جرّب فاتورة من فرع/شركة غير مصرح بها بهوية اختبار مناسبة؛ يجب أن تكون غير مرئية.
7. جرّب فاتورة ملغاة وكمية سبق إرجاعها؛ يجب رفض المرتجع أو عرض الكمية المتبقية فقط.
8. تحقق من أن الضغط على زر الدفع في تبويب «مرتجع» لا يفتح نافذة بيع عادية.
9. تحقق من نسخة Cloudflare Pages وService Worker بعد النشر؛ لا تعتبر Git وحده إثباتًا للنسخة المعروضة.

## 5. حدود الإغلاق

- **Production RPC / ACL / known invoice lookup:** VERIFIED.
- **Frontend defect in action visibility:** ROOT CAUSE FOUND; exact replacement supplied; owner application and deployment pending.
- **Actual browser-visible E2E and served artifact parity:** UNVERIFIED in this session.
- **Cash/card refund from an individual cashier drawer:** OPEN; current path creates a credit note and explicitly does not prove cash/card disbursement. لا تربط الرد بالخزينة العامة `CASH-01` بالتخمين.
- **No Production schema or business-data mutation** was performed in this cycle.
- **POS integration is not closed** until the surgical patch is applied, deployed, and browser E2E passes.

## SELF-AUDIT FINAL

- **What I Proved:** الفرع المصرح به، ACL، وقراءة الفواتير المعروفة من Production تحت claims المصادق عليها؛ كما أثبت المصدر أن `switchView` لا يزامن أزرار الجانب لجميع التبويبات.
- **What I Did Not Prove:** رقم الفاتورة الذي أدخله المستخدم في المحاولة الفاشلة، تطابق النسخة المقدمة من Pages مع Git blob، واختبار متصفح فعلي بعد النشر.
- **What I Fixed:** لا تعديل مباشر لملف الواجهة المحمي؛ أعددت بديلًا كاملًا محددًا لدالة `switchView` لمعالجة الخلل المثبت.
- **What I Initially Missed:** نجاح دالة التنقل وحده لا يكفي؛ يجب أن تتزامن أزرار الجانب مع التبويب النشط.
- **What Could Still Be Wrong:** نسخة Service Worker قديمة أو أن الرقم المدخل ليس فاتورة POS في النطاق المصرح؛ لا توجد أدلة كافية لحسم أي منهما بعد.
- **Final Confidence:** مرتفع في Production RPC والخلل المصدرّي؛ متوسط في التشخيص الكامل لتجربة المستخدم؛ غير كافٍ لإغلاق Browser E2E.
- **Final Closure Status:** `SOURCE PATCH REQUIRED / PRODUCTION READ CONTRACT VERIFIED / BROWSER E2E OPEN / CASH REFUND CONTRACT OPEN / POS NOT CLOSED`.
