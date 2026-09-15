# Report202 — التحقيق الجنائي الحالي واختبار E2E لمشتريات النظام الأم

**التاريخ:** 2026-09-15

## 0. نقطة البداية الحاكمة

هذه الجلسة لا تعتبر أي تقرير قديم حالة حالية. تم استخدام التقارير فقط لفهم التاريخ، بينما قرار التنفيذ بُني على:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ولإغلاق Browser E2E يلزم إضافة:

`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

والهدف الذي يجب قراءته بعناية: **إغلاق مشكلة مودالات المشتريات في النظام الأم وظيفيًا، وليس الاكتفاء بوجود جداول أو RPCs أو شاشات شكلية.**

## 1. استرجاع آخر حالة من Git الحالي

### Current Mother

المستودع المعتمد للنظام الأم:

`papamohammed77-glitch/erp-frontend`

الملف:

`companies/company-1/main.html`

Current HEAD:

`befa657277fc013c4fe4d3e326ed8fc5d1040b7b`

رسالة HEAD:

`Update HTML comment timestamp`

Direct parent:

`b6d35c5a1a362f381c9868bbc578de988b219c50`

رسالة parent:

`Fix button onclick syntax in main.html`

Current Mother blob:

`bc268b9bb350991df64221e7f99b958264fb8d5f`

HEAD يغير timestamp فقط من `17:00 UTC` إلى `20:00 UTC`. والـparent عدّل بالفعل زر `_openPO` قرب السطر 9577. لا يوجد دليل أن جسم Purchase الحالي تغيّر بعد هذا الـparent.

## 2. Source of Truth / forensic assembly

تم فحص:

`forensic_main_assembly.yml`

وحالته الحالية صحيحة، ومضمونها:

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

إذن لا يوجد تصحيح لمسار الـSource of Truth مطلوب في هذه اللحظة.

الأجزاء القديمة:

`Current/PWA/main2/*`

تظل Historical Reference فقط.

## 3. التحقيق الجنائي في Mother الحالية

داخل `RW_PurchaseGold` ثبت وجود دوال:

`requests`
`createRequest`
`approveRequest`
`createRFQ`
`sendRFQ`
`createQuotation`
`acceptQuotation`
`convertQuotation`
`createInvoice`
`postInvoice`
`createReturn`
`postReturn`
`createPayment`
`reports`
`settings`

### Parser blocker المثبت

Current Purchase source ما زال يحتوي escaping مكسورًا في زر `approveRequest`، وهو سبب Console الذي تم ربطه سابقًا بـ:

`main:9263:65 — Uncaught SyntaxError: Unexpected string`

النسخة الحالية المعيبة هي من نمط:

```javascript
(x.status === 'PendingApproval' || x.status === 'Draft'
  ? '<button onclick="RW_PurchaseGold.approveRequest(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">اعتماد</button>'
  : '') +
```

التصحيح الجراحي المطلوب من **المالك فقط**:

```javascript
(x.status === 'PendingApproval' || x.status === 'Draft'
  ? '<button type="button" onclick="RW_PurchaseGold.approveRequest(\'' + esc(x.id) + '\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">اعتماد</button>'
  : '') +
```

الموضع المؤكد: **السطر 9263** داخل `requests(host)`.

لا تحذف:

```javascript
'</td></tr>';
```

### createRequest separator defect

`createRequest()` يبدأ عند **السطر 9278** في الـCURRENT Mother.

السطران **9292–9293** ما زالا بالصيغة المعيبة:

```javascript
        raw.split('\
').forEach(function (line) {
```

التبديل الكامل:

```javascript
        raw.split('\n').forEach(function (line) {
```

وهذا عيب مستقل عن سبب Console 9263.

### بقية action-string defects

تم إثبات نفس escaping المكسور في:

`sendRFQ`
`acceptQuotation`
`convertQuotation`
`postInvoice`
`postReturn`

النمط النهائي الصحيح:

```javascript
onclick="RW_PurchaseGold.<FUNCTION>(\'' + esc(x.id) + '\')"
```

ولا يوجد مبرر لتغيير منطق العمليات المحيط بهذه الأزرار.

## 4. سبب سطحية المودالات — الحقيقة الحالية

التحقيق لا يثبت نقصًا في الـPurchase backend. Production تحتوي بالفعل على دورة شراء كاملة من حيث البنية:

- Requests
- RFQ
- Supplier quotations
- Quotation comparison
- Purchase Orders
- Purchase invoices
- Purchase returns
- Supplier payments
- Status history
- Document links
- Attachments
- Aging
- Supplier balance
- Settings

كما توجد RPCs حاكمة لكل مراحل دورة الشراء.

إذن السبب الحالي لسطحية المودالات **Frontend UX / input composition / validation / presentation**, وليس غياب البنية الخلفية.

## 5. Current Production database evidence

وقت snapshot الأخير في Production:

`2026-09-15 18:08:05.849107+00`

وكانت counts:

```text
purchase_requests  = 0
purchase_rfqs      = 0
purchase_quotations= 0
purchase_orders    = 0
purchase_invoices  = 0
purchase_payments  = 0
purchase_returns   = 0
```

لذلك لا توجد بيانات تشغيل مشتريات حقيقية يمكن التظاهر بأنها E2E fixture جاهز. أي اختبار كامل يتطلب إما بيانات تشغيل فعلية أو fixture داخل Transaction/rollback أو اختبارًا على بيئة اختبار مخصصة.

## 6. Current purchase backend contracts

Production يحتوي على:

```text
purchase_create_request_atomic
purchase_submit_request_atomic
purchase_approve_request_atomic
purchase_reject_request_atomic
purchase_create_rfq_atomic
purchase_send_rfq_atomic
purchase_create_quotation_atomic
purchase_accept_quotation_atomic
purchase_convert_quotation_to_po_atomic
purchase_create_invoice_atomic
purchase_post_invoice_atomic
purchase_create_return_atomic
purchase_post_return_atomic
purchase_post_payment_atomic
purchase_cancel_document_atomic
purchase_get_dashboard
purchase_get_reports
purchase_set_settings_atomic
purchase_next_code
receive_purchase_atomic
save_purchase_order_atomic
```

والمودالات الصحيحة يجب أن تنتهي دائمًا إلى هذه العقود، لا إلى direct table mutation من Mother.

## 7. العلاقات والـinfrastructure الموجودة بالفعل

العلاقات الحالية المثبتة تشمل:

`purchase_request_details.request_id → purchase_requests.id`

`purchase_rfq_details.rfq_id → purchase_rfqs.id`

`purchase_rfq_suppliers.rfq_id → purchase_rfqs.id`

`purchase_quotations.rfq_id → purchase_rfqs.id`

`purchase_quotation_details.quotation_id → purchase_quotations.id`

`purchase_orders.branch_id → branches.id`

`purchase_order_details.po_id → purchase_orders.id`

`purchase_invoices.purchase_order_id → purchase_orders.id`

`purchase_invoice_details.invoice_id → purchase_invoices.id`

`purchase_returns.purchase_invoice_id → purchase_invoices.id`

`purchase_return_details.return_id → purchase_returns.id`

`purchase_payments.treasury_id → treasury.id`

`purchase_payment_allocations.payment_id → purchase_payments.id`

`purchase_payment_allocations.invoice_id → purchase_invoices.id`

`purchase_settings.default_branch_id → branches.id`

إذن لا يجوز إنشاء بدائل لهذه العلاقات بسبب ضعف الـmodal فقط.

## 8. Realtime evidence

Production `supabase_realtime` publication تحتوي حاليًا على:

`purchase_requests`
`purchase_rfqs`
`purchase_quotations`
`purchase_invoices`
`purchase_payments`
`purchase_returns`

وهذا يعني أن قاعدة البيانات مجهزة أصلًا لنتائج Realtime لهذه الكيانات الرئيسية. الإغلاق النهائي ما زال يتطلب إثبات أن Mother نفسها تشترك/تنعش البيانات بالطريقة المطلوبة.

## 9. Production security hardening executed now

تم تنفيذ migration:

`purchase_harden_public_rpc_execution_20260915`

وتم سحب EXECUTE العام/المصادق منه من:

`purchase_submit_request_atomic`
`purchase_reject_request_atomic`
`purchase_cancel_document_atomic`
`purchase_company_status_history`

وأصبح المسار المسموح لتلك الوظائف هو `service_role`، بما يتوافق مع كون الـMother runtime يستخدم Edge capability layer ولا ينبغي أن يستطيع العميل استدعاء SECURITY DEFINER workflow controls مباشرة لتجاوز طبقة authorization.

بعد التنفيذ أعيد فحص privileges، وكانت النتائج:

- `service_role` = موجود.
- `anon` = غير موجود.
- `authenticated` = غير موجود.

## 10. ما لم أغيره عمدًا

لم يتم تعديل:

`erp-frontend/companies/company-1/main.html`

لأن هذا الملف ملك المالك في بروتوكول المشروع.

ولم يتم تعديل:

Inventory engine
Order/Runsheet lifecycle
Stock Voucher Supplier Return
Accounting posting engine

لعدم وجود defect حالي مثبت في هذه الأجزاء مرتبط بمشكلة Surface UI للمشتريات.

ولم يتم إنشاء جداول مشتريات جديدة، لأن Production تثبت أن البنية المطلوبة موجودة بالفعل.

ولم يتم إنشاء Edge Function جديد؛ لأن `save-purchase-order` موجود أصلًا كـcapability layer للدورة.

## 11. التجارب التي أجريت

### نجح

- Git HEAD / parent reconciliation.
- Current Mother blob identity verification.
- Current `forensic_main_assembly.yml` verification.
- Current Production Purchase schema verification.
- Current Production Purchase RPC inventory verification.
- Current Realtime publication verification.
- Production privilege hardening migration.
- التحقق أن database purchase transactional family خالية من بيانات تشغيل حقيقية حاليًا.

### فشل أو بقي مفتوحًا بسبب دليل غير متاح

- Fresh browser login/network/console E2E لا يمكن اعتباره منجزًا من دون تشغيل Browser فعلي بعد إصلاح المالك للـMother.
- البيئة الحالية لا توفر line-map كاملًا للـMother البالغ حجمها 1.2MB عبر connector range calls، لذلك لم يتم اختلاق أرقام أسطر غير مثبتة.
- تنزيل raw file مباشرة من داخل container فشل بسبب DNS، ولذلك لم يتم بناء line numbers بالتخمين من ملف قديم.

## 12. Owner Surgical Patch — ما يجب تنفيذه في Mother

**هذه هي العناصر التي ثبتت من CURRENT Mother، وليست من fragment قديم.**

### A. `requests(host)` — line 9263

ابحث عن البلوك الذي يحتوي على:

```javascript
(x.status === 'PendingApproval' || x.status === 'Draft'
```

واحذف **الثلاثة أسطر الكاملة** التي تنتهي بـ:

```javascript
          : '') +
```

واستبدلها بالبلوك الصحيح الموجود في Section 3.

### B. `createRequest()` — lines 9292–9293

احذف السطرين الكاملين اللذين يبدأان بـ:

```javascript
        raw.split('\\
```

وينتهيان بـ:

```javascript
').forEach(function (line) {
```

واكتب:

```javascript
        raw.split('\n').forEach(function (line) {
```

### C. Remaining current action lines

داخل الدوال:

`sendRFQ`
`acceptQuotation`
`convertQuotation`
`postInvoice`
`postReturn`

استبدل فقط escape الخاص بالـonclick بالنمط الصحيح، كما هو موثق في Report199/Report200، ولا تلمس business logic الأخرى.

### D. `createRequest()` complete safe replacement

لمنع قطع السطور، النسخة الكاملة الجاهزة للدالة هي النسخة الموجودة في Report199 Section 9، بعد مطابقة اسم الدالة والـCURRENT anchor. لا تستخدم أي نسخة fragment أخرى.

## 13. القرار الوظيفي للمودالات Gold/Diamond

بعد إزالة parser blocker، المطلوب من الـMother ليس إضافة CRUD آخر؛ بل تحويل المودالات إلى:

`Structured Form → Validation → Multi-line Item Entry → Live Totals → Authoritative API → Status History/Audit → Refresh/Realtime`

### Request

`title + required_by + requested_by + notes + multi item lines`

### RFQ

`request + due_date + multi suppliers + inherited lines + notes/attachments`

### Quotation

`supplier + rfq + validity + currency + terms + line pricing + discount + tax + totals`

### Invoice

`supplier + PO + branch + due_date + currency + lines + discount + tax + totals + post`

### Supplier Payment

`supplier + treasury + date + amount + reference + invoice allocations + remaining balances`

### Return

يجب أن ترتبط بالمستند الشرائي وتستخدم عقد `purchase_post_return_atomic`، بينما Physical stock يبقى تحت Inventory/Stock Voucher contract، وليس محركًا ثانيًا من واجهة الشراء.

### Reports

يجب أن تعتمد على `purchase_get_reports` وتعرض:

open requests / RFQs / quotations / POs / unbilled receipts / invoices / supplier aging / payments / returns / quotation comparison.

### Settings

يجب أن تتحكم فعليًا في `purchase_settings` بدل hard-coded policy داخل JavaScript.

## 14. شرط عدم ترك نصف حل

وجود:

`Tables + RPCs + Edge`

لا يساوي:

`Gold/Diamond Purchase`

ووجود:

`Beautiful Modal`

لا يساوي:

`Functional Purchase`

والإغلاق الصحيح يجب أن يثبت:

`UI → Edge → RPC → DB → Status/Audit → Realtime/Refresh → Browser Console clean → Network clean`

## 15. FINAL SELF-AUDIT

### What I Proved

- Current HEAD = `befa657…`
- Direct parent = `b6d35c5…`
- Mother blob = `bc268b9…`
- `forensic_main_assembly.yml` points to the correct Source of Truth.
- Current Mother contains the PurchaseGold modal block and parser defects described above.
- Production already contains the Purchase relational model.
- Production already contains the relevant Purchase RPC layer.
- Realtime publication includes the principal Purchase master transactional tables.
- Public execution of key purchase control RPCs has now been hardened to service-role access.

### What I Did Not Prove

- Fresh browser login.
- Fresh browser parser-clean state after owner edit.
- Fresh authenticated Purchase navigation.
- Opening and submitting every requested modal in a browser.
- Current Network waterfall after the owner merge.
- Full E2E lifecycle on real Purchase production data.

### What I Fixed

- Production privilege boundary for purchase workflow-control RPCs.
- No backend duplicate tables were introduced.
- No duplicate inventory engine introduced.

### What I Initially Did Not Know / What Investigation Corrected

The initial instinct could have been to create more Purchase infrastructure for the shallow modal. Current Production proves this would have been wrong: the full table and RPC family already exists.

The true open defect is the Mother parser/UI closure, not missing database tables.

### Remaining Risk

The principal remaining risk is attempting to continue building functionality into an unparsed Mother file. That must be eliminated first.

## 16. الحالة النهائية لهذه الجلسة

```text
CURRENT SOURCE IDENTITY              = VERIFIED
CURRENT GIT + PARENT                 = VERIFIED
FORENSIC ASSEMBLY PATH               = VERIFIED
PURCHASE PRODUCTION SCHEMA           = VERIFIED
PURCHASE RPC FOUNDATION              = VERIFIED
PURCHASE REALTIME TABLES             = VERIFIED
PURCHASE RPC PUBLIC HARDENING        = CLOSED
MOTHER PARSER                        = OPEN / OWNER PATCH REQUIRED
PROFESSIONAL MODAL UI                = OPEN / OWNER PATCH REQUIRED
FRESH BROWSER E2E                    = OPEN
FINAL PURCHASE GOLD/DIAMOND          = OPEN
```

لا يوجد إعلان 100% غير صادق في هذه الجلسة: الـProduction الجزء الذي يقع داخل صلاحية المساعد تم تنفيذه، أما Mother فباقية عند نقطة المالك التي يحددها بروتوكول المشروع.

## 17. إرشادات تشغيلية للمساعد التالي — ابدأ من آخر حقيقة فقط

اقرأ هذا القسم بعناية قبل أي إجراء لاحق:

```text
1) ابدأ من CURRENT_STATE وليس من تقرير قديم.
2) ثبّت CURRENT Git HEAD.
3) افتح DIRECT PARENT واحصل على diff الفعلي.
4) ثبّت CURRENT MOTHER blob SHA.
5) افتح CURRENT source للموضع المطلوب كاملًا، وليس fragment قديمًا.
6) افتح CURRENT Production database مباشرة.
7) افتح CURRENT Edge deployment مباشرة.
8) لا تعتبر وجود Table/RPC/Edge دليلًا على اكتمال الوظيفة.
9) حدد Closure واحدة فقط.
10) أعد بناء العقد التاريخي لفهم لماذا بُنيت المسؤولية بهذه الطريقة.
11) افصل بين frontend owner work وProduction assistant work.
12) إذا كان defect في Production: أصلحه في Production، ثم أعد الاختبار والقراءة من Production.
13) إذا كان defect في Mother: أعطِ owner surgical block كاملًا، مع start anchor وend anchor وline number مثبت.
14) بعد owner merge: أعد فحص Git HEAD/blob مرة أخرى.
15) شغّل Browser E2E على النسخة المنشورة الحالية، وليس tab قديمًا أو cache قديمًا.
16) اجمع Console + Page Error + Network + HTTP result.
17) اربط كل UI action بنتيجة RPC/DB/Status/Audit.
18) أعد snapshot للـProduction في نفس لحظة التقرير.
19) إذا كانت النتيجة في التقرير مختلفة عن Production، Production هي الحقيقة.
20) لا تعيد إصلاح أي نقطة ثبت إغلاقها، وابدأ مباشرة من أول Closure مفتوح حقيقي.
```

### الترتيب الإلزامي التالي

```text
PARSER CLEAN
→ REQUEST MODAL
→ REQUEST APPROVAL
→ RFQ MODAL
→ SUPPLIER SELECTION
→ QUOTATION MODAL
→ QUOTATION COMPARISON
→ PO CONVERSION
→ PURCHASE INVOICE
→ POST / MATCHING
→ SUPPLIER PAYMENT
→ ALLOCATION
→ RETURN LINKAGE
→ REPORTS
→ SETTINGS
→ FINAL E2E
```

## 18. الخلاصة التنفيذية

التحقيق الحالي لا يبرر إنشاء أي بنية Purchase جديدة. البنية موجودة بالفعل ومترابطة، وProduction أصبحت أكثر حماية بعد سحب direct execution من workflow-control RPCs.

النقطة الفاصلة الآن هي **Current Mother parser clean**. بعد ذلك يبدأ اختبار E2E الحقيقي للمودالات واحدًا واحدًا، ولا تُعلن أي نسبة نجاح أو إغلاق نهائي قبل مطابقة Production وBrowser وConsole وNetwork في نفس لحظة التقرير.
