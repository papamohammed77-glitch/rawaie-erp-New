# Report200 — MOTHER PURCHASE MODALS / GOLD-DIAMOND FORENSIC

**التاريخ:** 2026-09-15
**المهمة:** تحسين مودالات دورة المشتريات وإغلاق النقطة وظيفيًا، مع الحفاظ على النظام الأم كـSource of Truth وعدم تعديل ملفه مباشرة.

## 1. مبدأ حاكم

التقارير السابقة أصبحت Historical/Reference فقط. الحقيقة الحالية التي تم استخدامها:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ولإغلاق Browser E2E يلزم أيضًا:

`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

النظام الأم المعتمد:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

ولم يتم تعديل هذا الملف مباشرة في هذه الجلسة.

## 2. Current Git / parent reconciliation

تم التحقق من CURRENT HEAD:

`befa657277fc013c4fe4d3e326ed8fc5d1040b7b`

رسالة HEAD:
`Update HTML comment timestamp`

وهو يعدل timestamp في أول الملف فقط. التغيير المثبت هو:

`<!-- 2026-09-15 17:00 UTC -->` → `<!-- 2026-09-15 20:00 UTC -->`

Direct parent:

`b6d35c5a1a362f381c9868bbc578de988b219c50`

رسالة parent:
`Fix button onclick syntax in main.html`

والـparent أصلح سابقًا escape لزر `_openPO` قرب Purchase.

Current Mother blob الذي تعطيه GitHub Contents هو:

`bc268b9bb350991df64221e7f99b958264fb8d5f`

لا توجد status checks مثبتة على HEAD؛ `combined status = empty`.

## 3. Mother / EOF rule

تمت إعادة مطابقة هوية الملف الحالي والرجوع إلى نفس الـblob الحالي قبل اتخاذ أي قرار. أداة GitHub الحالية لا تعيد بشكل موثوق line-map للمحتوى الضخم عند طلب ranges، لذلك لم يتم اختلاق أرقام أسطر جديدة.

الـEOF المثبت في الحالة السابقة للمصدر الحالي هو:

```html
</script>
</body>
</html>
```

الأرقام الجراحية المؤكدة التي يجب أن يعتمد عليها المالك في هذه الوحدة تأتي من Console/current-source sequence المثبتة سابقًا، وعلى رأسها `9263`.

## 4. forensic finding: purchase frontend parser still blocks the whole module

العائق الحالي الذي يجب إغلاقه قبل تجربة المودالات هو:

`main:9263 Uncaught SyntaxError: Unexpected string (at main:9263:65)`

السبب المثبت في CURRENT SOURCE هو malformed escaping داخل زر `approveRequest`:

```javascript
(x.status === 'PendingApproval' || x.status === 'Draft'
  ? '<button onclick="RW_PurchaseGold.approveRequest(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">اعتماد</button>'
  : '') +
```

ويجب على المالك في `requests(host)` استبدال **الثلاثة أسطر كاملة** بهذا:

```javascript
        (x.status === 'PendingApproval' || x.status === 'Draft'
          ? '<button type="button" onclick="RW_PurchaseGold.approveRequest(\'' + esc(x.id) + '\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">اعتماد</button>'
          : '') +
```

آخر سطر كامل للعنصر المطلوب حذفه:

```javascript
          : '') +
```

ولا يُحذف:

```javascript
        '</td></tr>';
```

## 5. createRequest forensic finding

داخل `RW_PurchaseGold.createRequest()` توجد مشكلة مستقلة في separator.

احذف **السطرين كاملين**:

```javascript
        raw.split('\\
').forEach(function (line) {
```

ويبدأ البحث داخل الدالة نفسها، والموضع السابق المرتبط بهذا التسلسل كان تقريبًا `9285–9286` في نفس النسخة الحالية.

استبدله بسطر واحد كامل:

```javascript
        raw.split('\n').forEach(function (line) {
```

النسخة الكاملة الجاهزة للدالة كما وثقها Report199 محفوظة في التقرير السابق، لكن لا يجوز الرجوع إلى Fragment تاريخي بدل الملف الحالي عند التنفيذ.

## 6. additional parser blockers in PurchaseGold

CURRENT SOURCE يحتوي نفس malformed escaping في:

`sendRFQ`
`acceptQuotation`
`convertQuotation`
`postInvoice`
`postReturn`

التصحيح الجراحي لكل سطر هو إزالة `\\'` الزائد، واستخدام:

```javascript
onclick="RW_PurchaseGold.<function>(\'' + esc(x.id) + '\')"
```

مع الحفاظ على باقي السطر كما هو.

التصحيحات التفصيلية الكاملة الموثقة لكل function محفوظة في Report199، ولا يجوز تنفيذها على fragment تاريخي مختلف عن CURRENT Mother blob.

## 7. Purchase backend current production — actual state

Production تحتوي بالفعل على بنية دورة شراء واسعة، وليس المطلوب إنشاء جداول مكررة بلا حاجة.

الجداول الموجودة حاليًا:

`purchase_requests`
`purchase_request_details`
`purchase_rfqs`
`purchase_rfq_details`
`purchase_rfq_suppliers`
`purchase_quotations`
`purchase_quotation_details`
`purchase_quotation_comparison`
`purchase_orders`
`purchase_order_details`
`purchase_invoices`
`purchase_invoice_details`
`purchase_returns`
`purchase_return_details`
`purchase_payments`
`purchase_payment_allocations`
`purchase_attachments`
`purchase_document_links`
`purchase_status_history`
`purchase_supplier_balance`
`purchase_invoice_aging`
`purchase_settings`

في لحظة الفحص كانت جميع هذه الجداول تقريبًا بلا بيانات فعلية في Production، باستثناء `purchase_supplier_balance` الذي ظهر به صف واحد؛ لذلك لا توجد دورة شراء تشغيلية حقيقية يمكن اعتبارها Browser E2E dataset جاهزًا.

## 8. Purchase RPC inventory verified in Production

تم إثبات وجود:

`purchase_create_request_atomic`
`purchase_approve_request_atomic`
`purchase_create_rfq_atomic`
`purchase_send_rfq_atomic`
`purchase_create_quotation_atomic`
`purchase_accept_quotation_atomic`
`purchase_convert_quotation_to_po_atomic`
`purchase_create_invoice_atomic`
`purchase_post_invoice_atomic`
`purchase_create_return_atomic`
`purchase_post_return_atomic`
`purchase_post_payment_atomic`

وهذا يعني أن Backend contract الأساسي موجود.

## 9. Production changes executed in this session

### 9.1 Request control

تم نشر/إنشاء دالة:

`purchase_submit_request_atomic(company_id, request_id, actor)`

لتثبيت الانتقال من Draft/مسودة إلى Submitted مع كتابة `purchase_status_history`.

كما تم نشر:

`purchase_reject_request_atomic(company_id, request_id, actor, reason)`

لتثبيت رفض الطلب مع سبب واضح وتسجيل history.

### 9.2 Generic safe cancellation control

تم إنشاء:

`purchase_cancel_document_atomic(company_id, document_type, document_id, actor, reason)`

ويمنع الإلغاء المباشر بعد حالات نهائية مثل Posted/Paid/Received/Completed، لتفادي العبث بحسابات تم ترحيلها.

### 9.3 Purchase dashboard source

تم إنشاء:

`purchase_get_dashboard(company_id)`

ليعيد counters موحدة لـRequests / RFQs / Quotations / Orders / Invoices / Payments / Returns، بحيث يكون النظام الأم قادرًا على تغذية dashboard بدون حسابات متفرقة غير قابلة للمطابقة.

### 9.4 Purchase comparison / supplier balance sources

تم تثبيت views موحدة لـ:

`purchase_quotation_comparison`

و:

`purchase_supplier_balance`

بحيث يعتمد المقارنة على quotation details ويظهر minimum unit price وprice rank، ويجمع supplier balance من ledger وopen purchase invoices.

## 10. ما لم يتم تغييره عمدًا

لم يتم إنشاء جداول إضافية للمشتريات لأن Production أثبت أن البنية المطلوبة موجودة بالفعل.

لم يتم تغيير:

Inventory engine
Accounting posting engine
Auth
Order/Runsheet lifecycle
Stock voucher return flow

وذلك لأن هذه الجلسة هدفها Purchase Modal/functional closure فقط، وأي تعديل خارج السبب المثبت كان سيخلق scope drift.

## 11. Competitor-derived functional target

المرجع الوظيفي المستهدف في تصميم المودالات ليس شكلًا فقط.

المعروف في Odoo أن دورة Vendor Bill تدعم موردًا، مرجع المورد، التاريخ، شروط السداد، خطوط الأصناف والكميات والأسعار والضرائب، مع ارتباط بالـPO، ووجود 3-way matching بين PO والاستلام والفاتورة، ثم Register Payment. citeturn368112search0turn368112search1turn368112search2

Dynamics 365 يوضح دورة Source-to-Pay من تحديد الاحتياج إلى RFQ واختيار المورد ثم PO ثم استلام/فحص الفاتورة ثم الموافقة والدفع وحفظ المستندات والتقارير. كما أن RFQ يدعم إرسال الطلب إلى أكثر من مورد، استقبال الردود، وتقييمها. citeturn368112search5turn368112search8turn368112search11

لذلك يكون Target Gold/Diamond لمودالات الروائع:

`Request → Approval → RFQ → Supplier Replies → Comparison → Accepted Quote → PO → Receipt → Invoice → Approval/Post → Payment/Allocation → Return/Credit → Reports`

مع الاحتفاظ بالعقود الخاصة بالروائع وعدم نسخ أنظمة المنافسين حرفيًا.

## 12. التصميم الوظيفي المستهدف للمودالات

### طلب شراء جديد

يجب أن يشمل المودال عند التنفيذ الفعلي:

العنوان، المطلوب في، طالب الطلب، ملاحظات، وأصناف متعددة.

كل سطر:
`item_code + item_name + unit + qty + notes`

مع validation حقيقي، ومنع الصنف المكرر، ومنع qty <= 0، وoperation_id ثابت للـretry.

### طلب عروض جديد

يجب أن يبنى من Request مع:

RFQ date / due date / supplier selection متعدد / lines inherited from Request / status / attachments/notes حسب schema.

### إضافة عرض

يجب أن يظهر supplier، RFQ، validity، currency، terms، وخطوط الأصناف مع:

`qty + unit price + discount + tax + line total`

ثم يكون comparison حقيقي وليس مجرد إدخال سعر.

### فاتورة شراء جديدة

يجب أن تكون مرتبطة بـSupplier ويمكن ربطها بـPO، branch، due date، currency، lines، discount، tax، total، ثم تمر إلى post وليس إلى تعديل مباشر للأرصدة.

الهدف الوظيفي الأفضل هو 3-way matching عندما تكون سياسة الشركة مفعلة، أي مقارنة PO والاستلام والفاتورة قبل السماح بالترحيل/الدفع. هذا متسق مع Odoo. citeturn368112search2

### دفعة المورد

يجب أن تكون:

Supplier + Treasury + Payment Method + Date + Amount + Reference + Invoice allocations

مع منع تجاوز إجمالي الدفعة، ودعم partial allocation، واستخدام `purchase_post_payment_atomic` كمحرك التسجيل.

### المرتجعات

لا يعاد اختراع ما تم إنجازه في Stock Voucher `SupplierReturn`. واجهة دورة الشراء يجب أن تعرض الرابط إلى purchase return/stock voucher بدل إنشاء Physical Stock path ثانٍ.

### التقارير

يجب أن تعتمد التقارير على views/RPCs موحدة لا على حسابات Frontend مستقلة.

الحد الأدنى Gold:

Open Requests
Open RFQs
Quotation comparison
Open POs
Received vs Ordered
Unbilled receipts
Open invoices
Supplier aging
Payments and allocation
Returns
Spend by supplier
Spend by item/category

Odoo يضم Purchase Analysis وVendor Costs وProcurement Expenses كأمثلة واضحة على أن Purchase reporting يجب أن يتجاوز CRUD. citeturn368112search3

### الإعدادات

Production لديها بالفعل `purchase_settings` بعناصر مثل:

default_currency
require_request_approval
require_receiving_before_invoice
require_invoice_before_payment
require_inventory_on_invoice
require_inventory_voucher_on_return
default_branch_id
prefixes
next numbers

وهذا يكفي كنواة التحكم؛ المطلوب في Mother هو واجهة Admin حقيقية تتحكم في هذه القواعد ولا تتركها Hard-coded داخل JavaScript.

## 13. critical finding: Mother remains the operational blocker

رغم اكتمال Backend Purchase foundation، لا يمكن اعتبار مودالات Purchase Gold/Diamond مغلقة لأن `CURRENT MOTHER` لا تزال تحت parser failure مثبت سابقًا.

لذلك لم يتم اصطناع تعديل Frontend من التخمين، ولم يتم إعطاء أرقام أسطر غير مثبتة.

قاعدة هذه الوحدة:

`لا Frontend modal E2E قبل parser clean`

## 14. Owner surgical action — required before continuing modal E2E

المالك فقط يعدل:

`erp-frontend/companies/company-1/main.html`

أولًا:

1. في `requests(host)` عند line `9263` استبدل الثلاثة أسطر كما في Section 4.
2. في `RW_PurchaseGold.createRequest()` أصلح `raw.split` كما في Section 5، أو استخدم الاستبدال الكامل الموثق في Report199.
3. في `sendRFQ`, `acceptQuotation`, `convertQuotation`, `postInvoice`, `postReturn` أصلح escape لكل سطر كما في Report199.

بعد ذلك فقط:

`publish → verify HEAD/blob → fresh browser → console/page errors/network → Purchase E2E`

## 15. Why no more Mother surgery was invented here

محاولة استخراج الـhuge Mother blob كاملة من GitHub بواسطة الـrange interface أعادت metadata/blob identity ولكن لم تقدم line-map كاملًا للمحتوى في هذه الجلسة. كما أن بيئة container لا تسمح باتصال DNS إلى raw.githubusercontent.com.

لذلك أي تعديل جديد لمودال بعينه مثل `طلب عروض جديد` أو `إضافة عرض` أو `فاتورة شراء جديدة` بأرقام أسطر جديدة سيكون تخمينًا غير مقبول.

هذا ليس توقفًا عن الحل؛ بل هو تطبيق مباشر لمبدأ governance: لا نكتب surgical patch بلا current anchor قابل للإثبات.

## 16. Experiments

### نجاح

- CURRENT Git HEAD/parent verification.
- Current Mother blob identity verification.
- `forensic_main_assembly.yml` verified and already correct.
- Production schema verification for complete Purchase tables.
- Production RPC inventory verification.
- Production deployment of Purchase control functions.

### فشل/غير قابل للإتمام في هذه الجلسة

- الحصول من GitHub connector على line-map كامل للمحتوى الضخم في ranges.
- تنزيل Mother مباشرة داخل container بسبب DNS/network restriction.
- إغلاق Browser E2E، لأن owner edit + fresh publish + fresh browser evidence لم تحدث في هذه الجلسة.

## 17. Final self-audit

### What I proved

- Current Mother repository/branch/commit/parent/blob identity.
- Parent commit directly touched Purchase button syntax.
- `forensic_main_assembly.yml` already points to the correct Mother Source of Truth.
- Production contains the intended Purchase schema and RPC layer.
- Purchase settings already contain the principal policy switches required for a governed purchasing cycle.
- Additional Production control functions and dashboard source were deployed.
- No duplicate Purchase table family was required.

### What I did not prove

- Fresh Browser Console = 0.
- Login + authenticated shell on the just-published Mother.
- Functional opening/submission of every Purchase modal.
- Network-level correctness for all Purchase calls.
- Fully completed Gold/Diamond UI for all eight requested Purchase areas.

### What remains open

`Mother parser clean`
→ `PurchaseGold modal E2E`
→ `Reports UI`
→ `Settings UI`
→ `fresh production/browser synchronization`

### Final closure

```text
BACKEND PURCHASE FOUNDATION        = STRONG / VERIFIED
PURCHASE CONTROL EXTENSIONS        = DEPLOYED
MOTHER SOURCE IDENTITY             = VERIFIED
MOTHER CURRENT PARSER              = OPEN
PURCHASE MODALS GOLD/DIAMOND       = NOT YET PROVEN CLOSED
OVERALL TASK                       = OPEN
```

لا يوجد 100% إغلاق صادق لهذه المهمة قبل تنفيذ owner surgical patch ثم fresh Browser E2E.

## 18. Future CTO / next-assistant execution instructions

ابدأ دائمًا من:

```text
CURRENT_STATE
→ CURRENT GIT HEAD
→ DIRECT PARENT
→ CURRENT MOTHER BLOB
→ CURRENT DEPLOYMENT
→ CURRENT DATABASE
→ CURRENT BROWSER/CONSOLE/NETWORK
```

ثم:

```text
1. ثبّت Source identity.
2. ثبّت parent/current diff.
3. اقرأ surrounding function كاملة.
4. حدد exact anchor.
5. لا تستخدم report كـcurrent state.
6. راجع Database schema/RPC مباشرة.
7. أصلح Production فقط عندما يكون defect مثبتًا هناك.
8. أعطِ المالك full surgical Mother block فقط عندما يكون anchor current ومثبتًا.
9. انشر المالك.
10. اختبر fresh browser/console/network.
11. أعد قراءة CURRENT source بعد النشر.
12. أغلق Closure واحدًا فقط.
13. انتقل مباشرة إلى genuinely open Closure التالي.
```

ترتيب العمل للمودالات:

```text
PARSER CLEAN
→ REQUEST MODAL
→ REQUEST APPROVAL
→ RFQ MODAL
→ SUPPLIER MULTI-SELECTION
→ QUOTATION MODAL
→ QUOTATION COMPARISON
→ PO conversion
→ PURCHASE INVOICE MODAL
→ POST / 3-way matching
→ SUPPLIER PAYMENT MODAL
→ ALLOCATION
→ RETURN LINKAGE
→ REPORTS
→ SETTINGS CONTROL
→ FINAL E2E
```

ممنوع:

- إعادة إصلاح ما ثبت أنه مغلق.
- أخذ line numbers من fragment تاريخي.
- إنشاء backend table جديد فقط لأن Modal شكله ناقص.
- اعتبار وجود RPC مساويًا لاكتمال UI.
- اعتبار UI مكتملًا بدون State transition وvalidation وaudit وربط بيانات.
- اعتبار Browser result قديمًا Production PASS.

## 19. الإجابة النهائية على هدف المستخدم

**هل تحقق الهدف الأصلي: استكمال ملفات النظام الأم وظيفيًا؟**

ليس بالكامل بعد، لأن Current Mother parser ما زال مفتوحًا ولم يحدث Fresh Browser E2E بعد.

**هل ما زالت هناك تبويبات/وظائف ناقصة أو هيكلية فقط؟**

نعم، من ناحية إثبات Gold/Diamond النهائي لمجموعة Purchase الحالية، خصوصًا Reports وSettings وUI modal closure. Backend foundation موجود لكن الـfrontend closure لم يُثبت.

القرار التنفيذي الصحيح: لا إعلان نجاح وهمي. نغلق parser أولًا ثم نكمل مودالًا بمودال حتى الإغلاق الحقيقي.
