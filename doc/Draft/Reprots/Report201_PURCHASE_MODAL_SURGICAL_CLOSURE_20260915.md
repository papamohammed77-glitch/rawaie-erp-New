# Report201 — إغلاق جراحي لمودالات دورة المشتريات

**التاريخ:** 2026-09-15
**الحالة:** Production backend closed for this unit; Mother frontend surgical patch prepared for owner merge.

## 1) قاعدة الحقيقة

تمت مطابقة:
- CURRENT GIT
- CURRENT SOURCE
- CURRENT PRODUCTION
- CURRENT DATABASE
- CURRENT DEPLOYMENT

التقارير السابقة استُخدمت كمرجع فقط.

Mother Source of Truth:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

CURRENT HEAD:
`befa657277fc013c4fe4d3e326ed8fc5d1040b7b`

Parent:
`b6d35c5a1a362f381c9868bbc578de988b219c50`

Mother blob:
`bc268b9bb350991df64221e7f99b958264fb8d5f`

EOF المثبت تاريخيًا للمصدر الحالي:
```html
</script>
</body>
</html>
```

## 2) آخر commit/parent

HEAD يعدل timestamp فقط. الـparent أصلح syntax لزر `_openPO` في منطقة المشتريات قرب line 9577. لذلك لا يوجد سبب للرجوع إلى نسخة تاريخية بدل CURRENT Mother.

## 3) التحقيق الحالي — سبب سطحية المودالات

المشكلة ليست نقص جداول؛ Production تحتوي 22 كيانًا في دورة المشتريات ومحركات RPC حاكمة. السبب في Mother هو أن `RW_PurchaseGold` يستخدم SweetAlert بسيطًا جدًا مع textareas مفصولة بـ `|` بدل form workflow احترافي، مع وجود parser blockers في action strings وفواصل الأسطر.

الأجزاء الحالية المثبتة من CURRENT Mother:
- `createRequest()` يبدأ عند source line 9278.
- malformed separator داخل الدالة عند source lines 9292–9293.
- `createRFQ()` يبدأ عند source line 9373.
- `createQuotation()` يبدأ عند source line 9465 تقريبًا في نفس CURRENT sequence.
- `createInvoice()`, `createReturn()`, `createPayment()`, `reports()`, `settings()` تقع بعد ذلك داخل نفس RW_PurchaseGold block.

## 4) Production التي تم تنفيذها

### 4.1 Settings
تم إنشاء:
`purchase_set_settings_atomic(company_id, actor, settings)`

ويحفظ ويثبت:
- default_currency
- require_request_approval
- require_receiving_before_invoice
- require_invoice_before_payment
- require_inventory_on_invoice
- require_inventory_voucher_on_return
- default_branch_id
- request/rfq/quotation/invoice/return/payment prefixes

مع audit_log.

### 4.2 Reports
تم إنشاء:
`purchase_get_reports(company_id, as_of_date)`

ليعيد مصدرًا موحدًا لـ:
Requests / RFQs / Quotations / Orders / Invoices / Payments / Returns / Supplier Aging / Quotation Comparison.

### 4.3 Edge runtime
تم نشر `save-purchase-order` version 6 مع JWT، Company context من authenticated user، ودعم مباشر للعمليات الحاكمة:
CREATE_REQUEST / SUBMIT_REQUEST / APPROVE_REQUEST / REJECT_REQUEST / CREATE_RFQ / SEND_RFQ / CREATE_QUOTATION / ACCEPT_QUOTATION / CONVERT_QUOTATION_TO_PO / CREATE_INVOICE / POST_INVOICE / RECEIVE_PO / CREATE_RETURN / POST_RETURN / POST_PAYMENT / CANCEL_DOCUMENT / GET_SUMMARY / GET_REPORTS / SAVE_SETTINGS / GET_DATA.

## 5) ما لم يتم تغييره

لم يتم إنشاء جداول مشتريات مكررة.
لم يتم تغيير Inventory engine أو Order/Runsheet lifecycle أو Stock Voucher Supplier Return.
لم يتم تعديل Mother مباشرة.

## 6) Owner Surgical Patch — Mother

### أولًا: Parser blocker

في `requests(host)`:

**الموضع الحالي:** source line 9268–9270 تقريبًا داخل الشرط:
```javascript
(x.status === 'PendingApproval' || x.status === 'Draft'
  ? '<button type="button" onclick=...approveRequest...'
  : '') +
```

استخدم السطر المصحح التالي كاملًا:
```javascript
          ? '<button type="button" onclick="RW_PurchaseGold.approveRequest(\'' + esc(x.id) + '\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">اعتماد</button>'
```

ولا تُحذف نهاية:
```javascript
          : '') +
```

### ثانيًا: separator داخل createRequest

الدالة الحالية تبدأ عند line 9278.

احذف **السطرين الكاملين** عند source lines 9292–9293:
```javascript
        raw.split('\
').forEach(function (line) {
```

واستبدلهما بسطر واحد كامل:
```javascript
        raw.split('\n').forEach(function (line) {
```

### ثالثًا: escape blockers

داخل الدوال:
`sendRFQ`
`acceptQuotation`
`convertQuotation`
`postInvoice`
`postReturn`

أزل backslash الزائد داخل onclick strings، بحيث يكون الشكل النهائي:
```javascript
onclick="RW_PurchaseGold.<FUNCTION>(\'' + esc(x.id) + '\')"
```

## 7) Target UI replacement

المطلوب من owner ليس تغيير backend contract؛ المطلوب استبدال modal bodies الحالية في الدوال التالية، مع الاحتفاظ بأسماء الدوال وعمليات `api(...)` الحالية:

`createRequest`
`createRFQ`
`createQuotation`
`createInvoice`
`createReturn`
`createPayment`
`reports`
`settings`

المودالات الجديدة يجب أن تستخدم sections/card layout، labels واضحة، validation فوري داخل `preConfirm`, summaries، ورسائل عملية بعد الحفظ. يجب أن تبقى العملية في النهاية مستندة إلى RPC/Edge الحالي وليس insert/update مباشر من الواجهة.

## 8) Functional contracts التي يجب ألا يغيرها الـUI

Request:
`purchase_create_request_atomic`

RFQ:
`purchase_create_rfq_atomic`

Quotation:
`purchase_create_quotation_atomic`

Invoice:
`purchase_create_invoice_atomic`

Return:
`purchase_create_return_atomic`

Payment:
`purchase_post_payment_atomic`

Settings:
`purchase_set_settings_atomic`

Reports:
`purchase_get_reports`

## 9) Evidence / tests

نجح:
- Git HEAD/parent reconciliation.
- Mother blob identity verification.
- Production purchase schema verification.
- RPC inventory verification.
- Service-role execution permissions verification.
- Production deployment of `purchase_set_settings_atomic`.
- Production deployment of `purchase_get_reports`.
- Production deployment of `save-purchase-order` v6.

تم اختبار CREATE Request transactional باستخدام Company `da4e…` وGlobal Item identity، ونجح إنشاء voucher/request path بدون تغيير دائم بعد rollback.

لم يتم الادعاء بإغلاق Browser E2E لأن Mother لم تُعدل من طرف المساعد، ولا يوجد fresh browser/console/network evidence بعد merge.

## 10) Current closure status

```text
Production Purchase Backend foundation   = CLOSED
Production Settings source                = CLOSED
Production Reports source                 = CLOSED
save-purchase-order runtime               = CLOSED
Mother parser blocker                     = OWNER PATCH REQUIRED
Mother professional modal UI              = OWNER PATCH REQUIRED
Fresh Browser E2E                         = OPEN
Final Gold/Diamond Purchase closure       = OPEN until owner merge + fresh E2E
```

## 11) أهم تحذير

لا تستخدم أرقامًا من Report199/Report200 بدل CURRENT SOURCE. line numbers أعلاه مبنية على القراءة الحالية للـMother resource، والـHEAD الحالي هو `befa657…`.

## 12) تعليمات للمساعد القادم

ابدأ دائمًا بهذا التسلسل:

`CURRENT_STATE → CURRENT GIT HEAD → PARENT → CURRENT MOTHER BLOB → CURRENT PRODUCTION RPC/EDGE → CURRENT DATABASE → CURRENT BROWSER → CURRENT CONSOLE → CURRENT NETWORK`

بعد ذلك:

`ثبت الحقيقة → حدد closure واحدة → افتح المصدر التاريخي فقط لفهم العقد → قارن Production → أصلح سببًا واحدًا → انشر Production → اختبر → تحقق من Production من جديد → أعطِ owner patch دقيقًا إن كان الملف Frontend → اطلب/استخرج fresh Browser evidence → أغلق closure → انتقل للنقطة التالية.`

لا تعالج نقصًا مفترضًا في البنية إذا أثبتت Production أن المسؤولية موجودة.
لا تغيّر Inventory أو Order/Runsheet لمجرد أن Purchase UI سطحية.
لا تعتبر Backend foundation = Modal completion.
لا تعتبر static/source success = Browser pass.
لا تستخدم `LIMIT 1` لاستنتاج Company context إذا كانت الهوية مرتبطة بالمستخدم/الشركة.
لا تستخدم أي تقرير قديم باعتباره Current State.

## 13) القرار النهائي لهذه الجلسة

تم تنفيذ الجزء الذي يدخل ضمن صلاحية Production بالكامل، وتمت إزالة العائق الخلفي لإنضاج المودالات. الجزء الوحيد الذي بقي عمدًا خارج تنفيذ المساعد هو تعديل ملف Mother المنشور نفسه، لأن قاعدة المسؤوليات في المشروع تجعل هذا الدمج من اختصاص المالك.

الخطوة التالية بعد دمج الـOwner patch هي Fresh Browser E2E للمشتريات، ثم إغلاق كل modal كـClosure Unit مستقلة، وبعدها الانتقال لأول نقطة مفتوحة حقيقية فقط.
