# Report203 — التحقيق الجنائي الحالي في Modals دورة المشتريات — 2026-09-15

## 1. قاعدة الحقيقة الحاكمة

هذه الجلسة لا تعتمد على التقارير السابقة كحالة حالية.
مصدر الحقيقة هو:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ولإثبات E2E الكامل يلزم:

`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

Source of Truth للنظام الأم:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

الملفات التاريخية `Current/PWA/main2/*` و`Original/PWA/main/*` للاسترشاد فقط.

---

## 2. Git الحالي

Repository:
`papamohammed77-glitch/erp-frontend`

Branch:
`main`

Current HEAD:
`befa657277fc013c4fe4d3e326ed8fc5d1040b7b`

HEAD message:
`Update HTML comment timestamp`

Direct parent:
`b6d35c5a1a362f381c9868bbc578de988b219c50`

Parent message:
`Fix button onclick syntax in main.html`

HEAD diff في `companies/company-1/main.html` يغيّر timestamp فقط.
Parent أصلح `_openPO` onclick قرب السطر 9577.

وبالتالي لا يجوز الرجوع إلى تاريخ أقدم لمجرد أن تقريرًا سابقًا يصف عيبًا تم إصلاحه لاحقًا.

---

## 3. Current Mother source — النتيجة الفعلية

تم استخراج المصدر الحالي مباشرة من commit الـHEAD وفحص نطاق دورة المشتريات كاملًا.

المصدر الحالي يحتوي:

- `RW_PurchaseGold` يعمل.
- `api(operation,payload,operationId)` يرسل العملية إلى `save-purchase-order` مع `Idempotency-Key`.
- `getData()` يقيّد الجداول التي تحمل `company_id` على شركة الجلسة.
- parser/action-string defects السابقة في PurchaseGold أصبحت مصححة في الـsource الحالي.
- مشكلة session parser القديمة ليست هي المشكلة الحالية.

المشكلة الحالية المثبتة هي **UI depth / functional modal quality** وليست parser syntax.

---

## 4. مواضع المودالات الحالية

`createRequest()` : lines **9271–9323**

`createRFQ()` : lines **9365–9414**

`createQuotation()` : lines **9461–9531**

`createInvoice()` : lines **9616–9686**

`createReturn()` : lines **9730–9787**

`createPayment()` : lines **9828–9906**

`reports()` : lines **9908–9949**

`settings()` : lines **9951–9977**

`saveSettings()` : lines **9979–10001**

---

## 5. التحقيق الجنائي في سبب ضحالة المودالات

### createRequest

الحالة الحالية كانت تعتمد على:

- input title
- date
- textarea بصيغة `item_code|qty`
- notes

هذا يثبت أن المودال مجرد input collector وليس document-entry UX.

العيوب المثبتة:

- لا يوجد item picker/verification داخل المودال.
- لا يوجد item name/unit بعد اختيار الصنف.
- لا يوجد جدول بنود حقيقي.
- لا يوجد حذف/تعديل بند مباشر.
- لا توجد مراجعة بصرية قبل الحفظ.
- لا توجد validation عملية قبل الإرسال باستثناء parsing أساسي.

### createRFQ

الحالة الحالية:

- request select
- multi-supplier select
- date

العيوب:

- لا توجد معاينة لبنود الطلب الموروثة.
- لا تظهر كمية/صنف الطلب قبل الإنشاء.
- لا توجد UX واضحة لدعوة الموردين.
- لا توجد نتيجة مرئية تربط RFQ بالطلب الأصلي.

### createQuotation

الحالة الحالية تستخدم textarea:

`item_code|qty|price|discount|tax`

العيوب:

- لا يوجد RFQ-driven line entry.
- لا توجد صفوف قابلة للتحرير.
- لا توجد totals حيّة.
- لا تظهر unit/item name.
- الخصم والضريبة مدخلات نصية غير احترافية.

### createInvoice

الحالة الحالية تستخدم:

- supplier select
- branch select
- free text `purchase_order_id`
- date
- textarea lines

العيوب:

- `purchase_order_id` يجب ألا يكون UUID حرًا للمستخدم.
- لا يوجد PO selector/preview.
- لا يتم توريث بنود PO داخل الواجهة.
- لا توجد مراجعة بندية حقيقية.

### createReturn

الحالة الحالية:

- invoice select
- textarea `item_code|qty|reason`

العيب الجوهري:

الـUI لا يشرح أو يعرض `received_qty`، رغم أن Production `purchase_create_return_atomic` يعتبر `received_qty` حد الاستحقاق. لذلك يجب أن يعرض الـUI الحد المسموح بدل مطالبة المستخدم بالتذكر اليدوي.

### createPayment

الحالة الحالية:

- supplier
- treasury
- amount
- reference
- فاتورة واحدة فقط

العيوب:

- لا يوجد multi-invoice allocation UX.
- لا يظهر remaining بشكل عملي.
- لا توجد validation بصرية قبل الترحيل.

### reports

المشكلة الحالية ليست نقص infrastructure.
المودال/الشاشة الحالية تقرأ views مباشرة وتعرض قسمين فقط.

Production لديه بالفعل `purchase_get_reports`، وهو مصدر التقرير الموحد الذي يجب أن تعتمد عليه الشاشة.

### settings

الشاشة الحالية تعرض جزءًا من settings فقط.

لكن schema وRPC يدعمان:

- default currency
- request/rfq/quotation/invoice prefixes
- return/payment prefixes
- request approval
- receiving before invoice
- invoice before payment
- inventory on invoice
- inventory voucher on return
- default branch

إذًا النقص الحالي UI completeness وليس قاعدة بيانات مفقودة.

---

## 6. Current Production evidence

Current capability layer:

`save-purchase-order` version **6** — ACTIVE — `verify_jwt=true`.

الـEdge function يستخلص Company context من authenticated user عبر `users.auth_id` ثم يوجّه عمليات المشتريات إلى RPCs المناسبة.

Production relational model موجود بالفعل. لا توجد حاجة لإنشاء جداول شراء مكررة.

Current purchase tables مثبتة في Production، بما فيها:

`purchase_requests`
`purchase_request_details`
`purchase_rfqs`
`purchase_rfq_details`
`purchase_rfq_suppliers`
`purchase_quotations`
`purchase_quotation_details`
`purchase_orders`
`purchase_order_details`
`purchase_invoices`
`purchase_invoice_details`
`purchase_returns`
`purchase_return_details`
`purchase_payments`
`purchase_payment_allocations`
`purchase_settings`

Current live company transactional counts عند القراءة الحالية:

```text
purchase_requests    = 0
purchase_rfqs        = 0
purchase_quotations  = 0
purchase_orders      = 0
purchase_invoices    = 0
purchase_returns     = 0
purchase_payments    = 0
```

لم يتم إدخال fixtures دائمة إلى Production لاختبار UI.

---

## 7. Production change executed in this session

Migration applied directly to Production:

`purchase_reports_settings_tenant_hardening_20260915`

وأضيفت canonical Git migration:

`supabase/migrations/20260915_purchase_reports_settings_tenant_hardening.sql`

التعديلان المنفذان:

### purchase_get_reports

تم إصلاح `unbilled_receipts` ليُحسب من `purchase_order_details` المرتبط بـ`purchase_orders` مع Company scope.

قبل الإصلاح كان subquery غير مقيّد بـCompany.

### purchase_set_settings_atomic

تم إضافة التحقق من:

`default_branch_id`

بحيث يجب أن يكون فرعًا موجودًا ونشطًا ويتبع نفس الشركة.

وتم توسيع التحديث ليشمل:

`return_prefix`
`payment_prefix`
`require_inventory_on_invoice`
`require_inventory_voucher_on_return`

التنفيذ Production تم التحقق من تعريفات الدوال بعد الـmigration.

---

## 8. Production Realtime evidence

Publication `supabase_realtime` تحتوي حاليًا على:

`purchase_requests`
`purchase_rfqs`
`purchase_quotations`
`purchase_invoices`
`purchase_payments`
`purchase_returns`

إذن بنية Realtime موجودة في Production.

المتبقي في Mother هو الاشتراك والـrefresh behavior، وقد أُعد له owner patch منفصل.

---

## 9. Industry comparison used for design direction

تمت مراجعة Odoo وDynamics 365 وSAP كمرجع تصميمي فقط.
النمط المشترك المثبت:

- document header واضح.
- line-item grid وليس textarea.
- quantity/price/discount/tax قابلة للمراجعة بنديًا.
- inherited source document visible عند وجوده.
- supplier selection مرتبطة بسياق RFQ/quotation.
- report dashboard متعدد المؤشرات وليس جدولين مبعثرين.

Odoo وDynamics يعرضان RFQ كوثيقة عملية ذات Vendors + Items، وSAP يوضح header/items/bidders كأجزاء أساسية من RFQ.
المبدأ المنقول إلى RAWAEA هو النمط الوظيفي، وليس نسخ الواجهة.

المراجع:

- Odoo RFQ documentation: https://www.odoo.com/documentation/18.0/applications/inventory_and_mrp/purchase/manage_deals/rfq.html
- Dynamics 365 RFQ overview: https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/request-quotations
- SAP Request for Quotation: https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/25a41481f62e469ba0e61015a0d39d20/11215f54380c033de10000000a441470.html

---

## 10. ماذا تم تنفيذه فعليًا؟

### Production

تم تنفيذ hardening المطلوب في `purchase_get_reports` و`purchase_set_settings_atomic`.

لا توجد جداول Purchase ناقصة تستوجب إنشاءًا جديدًا في هذه النقطة.

### Mother

لم يتم تعديل `erp-frontend/main.html` بواسطة المساعد، وفق توزيع المسؤولية الصريح.

تم إعداد **Owner Surgical Patch Package** كامل، يتضمن:

- helper block للـitem verification.
- realtime subscription.
- professional Request modal.
- professional RFQ modal.
- professional Quotation modal.
- professional Purchase Invoice modal.
- professional Purchase Return modal.
- professional Supplier Payment multi-allocation modal.
- authoritative Reports screen via `GET_REPORTS`.
- complete Purchase Settings UI.

ملف patch الكامل:

`RAWAEA_Purchase_Modal_Owner_Patch_20260915.md`

---

## 11. لماذا لم يتم إنشاء Edge Functions أو جداول جديدة؟

لأن Production أثبتت أن:

- capability wrapper موجود.
- RPC lifecycle موجود.
- schema relational موجود.
- idempotency موجود في Request/Quotation/Invoice/Return/Payment.
- Realtime publication موجودة.

إضافة طبقة جديدة هنا كانت ستخلق duplicate path بدل إغلاق الفجوة الحالية.

---

## 12. القيود التي ما زالت تمنع 100% E2E

لا يمكن إثبات أن مودالات Mother أصبحت Gold/Diamond من Production وحدها، لأن التعديل النهائي على `erp-frontend/main.html` owner-owned ولم يتم تطبيقه في هذه الجلسة.

وحتى بعد تطبيقه، يجب إجراء Fresh Browser E2E وجمع:

- Console
- PageError
- Network
- HTTP result
- RPC result
- DB state
- Audit state
- Realtime refresh

لا يجوز اعتبار code review أو Production SQL PASS بديلًا عن Browser PASS.

---

## 13. Closure status

```text
Historical understanding          = DONE
Current Git HEAD                  = VERIFIED
Direct parent                     = VERIFIED
Current Mother source             = VERIFIED
Current Production schema         = VERIFIED
Current purchase RPC layer       = VERIFIED
Current Edge deployment           = VERIFIED
Current Realtime publication     = VERIFIED
Production report hardening      = DEPLOYED + VERIFIED
Production settings hardening    = DEPLOYED + VERIFIED
Mother parser issue              = NOT CURRENT BLOCKER
Professional Purchase Modals     = OWNER PATCH READY
Fresh Browser E2E                 = OPEN
Gold/Diamond Purchase Closure    = OPEN UNTIL OWNER MERGE + E2E
```

---

## 14. FINAL SELF-AUDIT

### What I proved

- الحالة الحالية ليست هي الحالة التي وصفتها التقارير القديمة.
- HEAD الحالي وParent الحالي تم فحصهما.
- Mother الحالية هي المصدر المنشور المقصود.
- Purchase backend infrastructure موجود بالفعل.
- سبب ضحالة المودالات موجود في Mother frontend، وليس في نقص الجداول.
- Reports وSettings لديهما backend capabilities كافية لتطوير UI كامل.
- Production report tenant bug تم إصلاحه.
- Production settings validation bug تم إصلاحه.
- Realtime publication موجودة.

### What I did not prove

- Browser execution بعد التعديلات الجديدة.
- Console clean بعد owner merge.
- Network 2xx لكل modal operation.
- Full purchase lifecycle transaction over live Production data.
- Gold/Diamond closure نهائي.

---

# 15. إرشادات البداية للمساعد القادم — لا يعيد الخطأ

ابدأ من الحقيقة وليس من التقرير:

1. افتح `CURRENT_STATE.md`.
2. ثبّت `erp-frontend/main.html` الحالي وHEAD وParent.
3. لا تثق في أي line number قديم قبل إعادة فتح المصدر الحالي.
4. افصل تاريخ التصميم عن الحالة الحالية.
5. افتح Production مباشرة وحدد RPC/Edge/schema الحالي.
6. حدّد المشكلة كـClosure واحدة.
7. لا تعيد إصلاح parser defect تم إثبات إغلاقه.
8. لا تنشئ جداول أو Edge Functions إذا كان الـbackend الحالي قادرًا على العقد المطلوب.
9. عند مشكلة UI، ابحث أولًا عن Professional Pattern موجود في Mother نفسها ثم قلّده في نفس الطبقة.
10. عند تعديل Mother، لا تعدّل الملف بنفسك؛ أعطِ Owner block كاملًا مع start/end anchors ورقم السطر الحالي.
11. عند تعديل Production، نفّذ migration canonical ثم تحقق من الدالة المنشورة بعد التنفيذ.
12. لا تعتبر Realtime publication مساوية لاشتراك الواجهة.
13. لا تعتبر modal ظاهرًا في DOM مساويًا لوظيفة مكتملة.
14. لا تنتقل إلى Closure جديدة قبل أن تثبت Browser + Network + DB + Realtime.
15. في كل تقرير جديد: snapshot Production أولًا، ثم النتيجة، ثم ما تم تغييره، ثم ما لم يُثبت.
16. أي تعارض بين التقرير وProduction يُحسم لصالح Production.
17. لا تكرر إصلاحًا ثبت إغلاقه.
18. الهدف النهائي ليس ملء الشاشة؛ الهدف إغلاق العقدة الوظيفية بدون Debt جديد.
