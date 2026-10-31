# Report569 — التدقيق الجنائي لتطبيق مسؤول المشتريات وربطه بعقود Production

**التاريخ:** 2026-10-31  
**وقت التحقق:** 23:28 Africa/Cairo  
**النوع:** CTO Forensic Audit + Business Contract Gap Analysis + Safe Execution Handoff  
**المستودع التشغيلي:** papamohammed77-glitch/erp-frontend — main  
**مستودع الحوكمة:** papamohammed77-glitch/rawaie-erp-New — main  
**Production:** Supabase SMART ERP — fiilmooggumokxanwiyx  
**الحالة:**  
BUYER SOURCE AND PURCHASE ENGINE RECONCILED / CRITICAL AUTHORIZATION AND CONTRACT DEFECTS CONFIRMED / NO PRODUCTION OR APP MUTATION / FULL UI COMPLETION NOT STARTED / DEPLOYMENT AND AUTHENTICATED E2E UNVERIFIED

---

## 1. نقطة الاستئناف واستعادة الحوكمة

بدأت من أحدث نقطة في CURRENT_STATE المرجعي، لا من الذاكرة القديمة:

- آخر نقطة سابقة: LVE-2026-10-31-568 — Parent Realtime Authorization Contract.
- ملف الحالة المرجعي قبل هذا التقرير: Blob SHA d57c60270d7e21a9a85a505506dbd44e4b4c4c4c.
- رأس مستودع التشغيل الحالي: 65799d282acc79359b17a1a13dcd68f62859e1fb.
- رأس مستودع الحوكمة الحالي: 4b8d8442d43ad60247996871c3cf8320e294b110.

تمت مراجعة Report545، وهو يسجل جرد 114 ملفًا من Reports 400–500، ويحدد التكرارات وغياب 490 و491، ويشرح منهج Owner Change Set، ويفصل APPLIED عن DEPLOYED وE2E VERIFIED. كما تمت مراجعة التقارير ذات الصلة بالرقابة المالية والخزينة، وبالأخص Reports 421 و425 و426 و431، وReport500 للخريطة الذهنية، إلى جانب Report567 وReport568 الأحدث.

**قواعد التنفيذ المعتمدة من Report545 والحوكمة:**
1. التقارير قرائن تاريخية وليست مصدر الحقيقة الحالية.
2. إعادة جلب SHA وقراءة المصدر الحي قبل أي تغيير.
3. عدم نقل كود من تطبيق أو تقرير دون إثبات توافق عقده.
4. Owner Change Set يجب أن يحدد الملف والدالة والمحدد الأصلي والاستبدال والاختبارات.
5. عدم الخلط بين Source وProduction وDeployment وRuntime.
6. عدم اعتبار نجاح SQL أو RPC إثباتًا لسلوك الواجهة.
7. عدم تعديل Parent أو التطبيقات التشغيلية على نحو واسع أو استبدال ملفات كاملة دون ضرورة مثبتة.
8. عدم إعلان الإغلاق قبل اختبار مصادق عليه والتحقق من الأثر التشغيلي.

**حد القراءة التاريخية:** Report545 هو ملخص التحقيق الذي وثق مراجعة نافذة 400–500. تمت مراجعة التقارير المرجعية التي تمس المشتريات والمالية والصلاحيات والتكامل؛ لا أدعي أنني فتحت النص الكامل لكل ملف من الملفات الـ114 منفردًا في هذه الدورة.

---

## 2. هوية المصدر الحي

| العنصر | القيمة الحالية |
|---|---|
| Operational HEAD | 65799d282acc79359b17a1a13dcd68f62859e1fb |
| buyer.html | companies/company-1/purchasing/buyer.html |
| Buyer Blob | 6ba510cff5250ba196528b14237ae400e544771a |
| Buyer الحجم | 15,051 حرفًا / 137 سطرًا |
| Operational core.js | Blob a95ee6b29ff54b4a240ce4b81f9a535aa87686db |
| Buyer Realtime wiring commit | ec9a81dc2a1157e38823827d8604bfdf5e1ed488 |
| Production Edge | save-purchase-order v7 ACTIVE |
| Edge verify_jwt | true |
| Edge SHA-256 | 8e8c419c94796d8b802976ff8f3bb9717c039a8701a1523736cb531b2cc6a6cd |

المصدر التشغيلي الحالي لملف Buyer يطابق Blob المسجل في Report567. لم يظهر تغيير أحدث في الملف حتى HEAD الحالي.

---

## 3. CONFIRMED — حالة واجهة Buyer الحالية

ملف Buyer الحالي يحتوي على ثلاثة تبويبات فقط:

1. أوامر الشراء.
2. أمر جديد.
3. الموردون.

والوظائف الموجودة فعليًا:

- تسجيل الدخول عبر RW_Auth.
- السماح بالدخول بناءً على isOwner أو صلاحية purchases.
- قائمة أوامر شراء مختصرة بحد أقصى 30 أمرًا.
- إنشاء أمر عبر cart بسيط.
- تحميل الموردين وعرض الاسم والهاتف والمنطقة والرصيد.
- البحث في الأصناف بالاسم أو item_code.
- Realtime subscription على purchase_orders مع company_id موثوق، وتحديث قائمة الأوامر عند كونها التبويب النشط، وإعادة المصالحة بعد reconnect/60 ثانية، وإيقاف القناة عند logout.

**النتيجة:** تكامل Realtime موجود في المصدر، لكنه لا يكمل دورة المشتريات ولا يثبت وصول أحداث Production إلى متصفح مصادق عليه.

### فجوات الواجهة المثبتة

- لا يوجد تبويب اليوم أو كروت التنبيه المطلوبة.
- لا يوجد PR list/details/timeline.
- لا توجد تفاصيل PO أو modal لإنشاء/إرسال/اعتماد PO.
- لا يوجد quick purchase invoice workflow.
- لا يوجد بحث بالباركود؛ الاستعلام الحالي يبحث بالاسم وitem_code فقط رغم وجود items.barcode.
- لا توجد إضافة مورد من Buyer، ولا ملف مورد كامل، ولا زيارة ميدانية أو تقييم.
- لا يوجد مودال مرفق فاتورة أو كاميرا أو OCR.
- لا يوجد تبويب عهدتي أو رصيد عهدة خاص بالمشتري.
- لا يوجد تبويب حسابي أو تقارير إنجاز وموافقات وتسويات.
- لا توجد مودالات أو قوائم تفصيلية للفاتورة أو تفاصيل بنود PO.
- لا يوجد حفظ ظاهر لتاريخ التسليم المتوقع أو شروط الدفع على مستوى PO.

---

## 4. CONFIRMED — محرك المشتريات الموجود في Production

قاعدة البيانات تحتوي بالفعل على منظومة مشتريات أوسع من واجهة Buyer الحالية:

- purchase_requests / purchase_request_details
- purchase_rfqs / purchase_rfq_details / purchase_rfq_suppliers
- purchase_quotations / purchase_quotation_details
- purchase_orders / purchase_order_details
- purchase_invoices / purchase_invoice_details
- purchase_returns / purchase_return_details
- purchase_payments / purchase_payment_allocations
- purchase_settings
- purchase_status_history
- purchase_attachments
- purchase_document_links
- Views تشمل purchase_invoice_aging وpurchase_quotation_comparison، كما أن Edge allow-list يتضمن purchase_supplier_balance.

ودالة save-purchase-order v7 تدعم العمليات التالية:

CREATE_REQUEST, SUBMIT_REQUEST, APPROVE_REQUEST, REJECT_REQUEST, CREATE_RFQ, SEND_RFQ, CREATE_QUOTATION, ACCEPT_QUOTATION, CONVERT_QUOTATION_TO_PO, CREATE_INVOICE, POST_INVOICE, RECEIVE_PO, CREATE_RETURN, POST_RETURN, POST_PAYMENT, CANCEL_DOCUMENT, GET_SUMMARY, GET_REPORTS, SAVE_SETTINGS, GET_DATA.

**مهم:** لا توجد عملية CREATE_PO أو SEND_PO أو APPROVE_PO في عقد Edge v7 الحالي. إنشاء PO المتاح يتم من خلال تحويل quotation مقبول إلى PO Draft. يجب الحفاظ على دورة PR → RFQ → Quotation → Acceptance → PO، وعدم تجاوزها بإنشاء PO مباشر قبل تحديد قرار الأعمال.

### دورة الشراء العاجل المباشر

ثبت من تعريفات Production أن:

- CREATE_INVOICE يقبل purchase_order_id اختياريًا؛ وبالتالي يمكن إنشاء فاتورة شراء مباشرة دون PO.
- إعداد Production الحالي: require_inventory_on_invoice = true.
- require_receiving_before_invoice = false.
- POST_INVOICE يمرر الأصناف إلى post_stock_movement بحركة PurchaseIn، ثم ينشئ القيد المحاسبي ويحدث supplier_ledger ويحول الفاتورة إلى Posted.

إذن يوجد مسار خلفي صالح من حيث المبدأ للشراء المباشر: إنشاء فاتورة Draft ثم POST_INVOICE، مع أثر مخزني ومحاسبي مركزي. لكنه ليس نفس مسار الاستلام التقليدي المرتبط بـPO في تطبيق Receiver؛ يجب أن تصمم الواجهة وتوضح للمخزن أي مسار استلام تم استخدامه، وألا تنفذ POST_INVOICE تلقائيًا قبل تأكيد الاستلام الفعلي المطلوب.

### حالة البيانات الحالية

| الكيان | العدد |
|---|---:|
| purchase_requests | 0 |
| purchase_orders | 1 — Draft |
| purchase_invoices | 3 |
| purchase_quotations | 0 |
| purchase_payments | 0 |
| purchase_returns | 0 |
| purchase_status_history | 5 |

هذه أعداد سجلات Production وقت الفحص، وليست إثباتًا لاكتمال الواجهة.

---

## 5. CONFLICT / P0 — عدم توافق Buyer مع Edge v7

**المصدر الحالي:** Buyer submitPO يرسل جسمًا بالشكل القديم:

~~~json
{ "orderHeader": { "supplierId": "...", "supplierName": "", "total": 0 }, "itemsList": [] }
~~~

بينما Edge v7 يبدأ بطلب body.operation ثم body.payload. وعند غياب operation يرفض الطلب برسالة «عملية المشتريات مطلوبة».

تمت مقارنة مصدر Git المرجعي في:
Current/Edge_Functions/save-purchase-order
مع المصدر النشط المسترجع مباشرة من Supabase Production v7:

- Git Blob: ade8ae3b34b55c00bb8c2e9986e2ec5b72013574.
- Production source length: 8,740 characters.
- Exact byte comparison: MATCH.

إذن لا توجد مشكلة في معرفة عقد Edge؛ لدينا عقد موثق ومطابق للنسخة المنشورة. المشكلة أن Buyer لم ينتقل إلى العقد الجديد.

**التصنيف:** CONFLICT — واجهة قديمة مقابل Backend contract v7.  
**الأثر المتوقع:** زر حفظ PO الحالي لا يرسل عملية مدعومة بصيغة Edge الحالية. لم أنفذ HTTP request تجاريًا في Production، لذلك لم أدّعِ اختبار الفشل الفعلي.

---

## 6. P0 — تفويض Edge Function لا يطابق صلاحيات التطبيق

المصدر المطابق لـProduction v7:

- يتحقق من Bearer token وAuth user.
- يربط Auth user بصف users ويستخرج company_id.
- يرفض غياب company_id أو حالة المستخدم غير النشطة.
- يستخدم service_role لتنفيذ RPCs والقراءة من الجداول.
- **لا يحتوي على أي فحص لصلاحية purchases أو suppliers أو finance أو أي role permission قبل تنفيذ العمليات.**
- فحص النص الكامل للمصدر لم يجد permission أو role_permissions أو get_my_effective_profile.

هذا يعني أن verify_jwt=true يثبت وجود جلسة صالحة فقط؛ ولا يثبت أن صاحب الجلسة مخول بتنفيذ عمليات المشتريات المالية أو اعتماد الطلبات أو تسجيل المدفوعات أو قراءة GET_DATA.

كما أن GET_DATA يقبل أسماء جداول من allow-list، ثم ينفذ قراءة باستخدام service_role مع company_id. هذا يحمي نطاق الشركة، لكنه لا يفرض صلاحية الوظيفة المطلوبة داخل الشركة.

**التصنيف:** CONFIRMED — فجوة تفويض خادمية.  
**الإجراء:** لا نضيف تبويبات أو أزرار تنفيذية جديدة قبل وضع permission matrix خادمية على Edge v8، تعتمد على الصلاحيات الفعالة الموثوقة، وتفرق بين purchases وsuppliers وfinance/treasury والاعتماد الإداري.

---

## 7. P0 — دالة Dashboard قابلة للتنفيذ من anon

Production function public.purchase_get_dashboard(uuid):

- SECURITY DEFINER.
- تفحص وجود الشركة فقط.
- لا تربط p_company_id بالشركة المستخرجة من auth.uid().
- ACL الحالي: PUBLIC وanon وauthenticated وservice_role لديهم EXECUTE.
- تعيد أعداد الطلبات والعروض والأوامر والفواتير والمدفوعات وقيمة المستحقات.

وبذلك لا يوجد في الدالة نفسها حاجز يربط طالب الاستعلام بشركته. وجودها خلف Edge لا يلغي إمكانية استدعائها مباشرة طالما ACL يسمح لـanon/authenticated.

**التصنيف:** CONFIRMED — سطح كشف بيانات مالي/تشغيلي بين الشركات محتمل عبر RPC مباشر.  
**المعالجة المطلوبة:** قصر EXECUTE على service_role إذا ثبت أن Edge هو المستهلك الوحيد، أو إعادة تصميم الدالة لتستخرج الشركة والصلاحية من Auth server-side. لا يتم تنفيذ REVOKE قبل إكمال caller census النهائي؛ لا نكسر مستهلكًا قائمًا غير مفحوص.

---

## 8. P1 — تعارض الصلاحيات الفعالة مع RLS

Production get_my_effective_profile() يجمع الصلاحيات من:

1. users.permissions
2. roles.permissions
3. role_permissions.permission_key

لكن app_private.current_user_has_permission(p_permission) يجمع المصدرين الأول والثاني فقط، ولا يقرأ role_permissions.

سياسات suppliers وitems تعتمد على current_user_has_permission:

- suppliers SELECT يتطلب suppliers أو استثناء دور مخزني محدد.
- items SELECT يتطلب items أو warehouse أو data-entry أو أدوار بيع محددة.
- Buyer يسمح بالدخول بناءً على purchases فقط.
- Buyer الحالي يقرأ suppliers وitems مباشرة من PostgREST.

إذن هناك تعارض مثبت: ملف المستخدم الموحد قد يمنح purchases، بينما RLS لا يمنح قراءة الموردين أو الأصناف لمجرد purchases؛ كما أن صلاحية موجودة في role_permissions قد تظهر في get_my_effective_profile ولا تُحتسب في helper المستخدم داخل RLS.

**التصنيف:** CONFLICT — effective-profile contract مقابل RLS permission helper وBuyer data reads.  
**المعالجة:** تحديد صلاحيات القراءة اللازمة للمشتري، ثم توحيد helper مع effective-profile أو تمرير قراءة موثقة عبر Edge بصلاحية واضحة. لا توسع RLS إلى كل مستخدم purchases دون تحديد الحد المطلوب.

---

## 9. P1 — عيوب مؤكدة داخل عقود PR

### 9.1 submit_request يكتب أعمدة غير موجودة

Production purchase_status_history يحتوي:

id, company_id, document_type, document_id, from_status, to_status, action, actor_email, note, created_at.

لكن purchase_submit_request_atomic ينفذ INSERT باستخدام:

changed_by, changed_at.

وهذان العمودان غير موجودين في الجدول.

كما يوجد بالفعل trigger على purchase_requests باسم trg_purchase_requests_status_history يستدعي purchase_company_status_history بعد INSERT أو تغيير status، ويكتب إلى الأعمدة الصحيحة: action وactor_email وcreated_at.

بالتالي INSERT اليدوي داخل purchase_submit_request_atomic غير صالح، وهو زائد أصلًا في وجود trigger؛ وعند تنفيذه يفترض أن يفشل ويرجع المعاملة كلها، بما فيها تحديث الحالة والـtrigger.

**التعديل الجراحي المقترح:** إزالة INSERT اليدوي غير الصحيح من purchase_submit_request_atomic، وترك trigger الحالي يسجل الحدث مرة واحدة. يجب اختبار ذلك في بيئة معزولة قبل Production.

### 9.2 إنشاء PR لا يقيد الصنف بالشركة

purchase_create_request_atomic يبحث عن item_code دون شرط company_id. الفهرس الحالي يجعل item_code فريدًا عالميًا، لكنه لا يثبت أن الصنف يتبع الشركة التي ينشئ لها الطلب.

**التعديل الجراحي المقترح:** إضافة company_id = p_company_id إلى lookup، ورفض أي صنف لا ينتمي للشركة نفسها. وينطبق الفحص نفسه على purchase_create_invoice_atomic حيث يظهر lookup مشابهًا.

### 9.3 بيانات PR لا تحمل كل حقول شاشة المستخدم المطلوبة

purchase_requests لا يحتوي department_id؛ وpurchase_request_details يحتوي qty_requested فقط، ولا يحتوي received_qty أو remaining_qty. الاستلام الفعلي يظهر في purchase_order_details.qty_received.

يمكن حساب المستلم والمتبقي للـPR عبر الروابط بين PR وRFQ وQuotation وPO وتفاصيل الاستلام، لكن هذا يتطلب تجميعًا صحيحًا على مستوى المستندات المرتبطة، وليس إضافة حقول واجهة وهمية.

---

## 10. فجوات Business Contract في الموردين والشراء والماليات

### الموردون

Production suppliers يحتوي: supplier_code, name, phone, location, area, address, supplier_type, payment_type, accounts_payable, contact_person, purchase_rep, notes, is_active.

لا يحتوي email أو rating أو تصنيف A/B/C صريح. ولم يظهر جدول مخصص supplier_visits أو supplier_ratings في الجرد الحالي.

### PO

purchase_orders لا يحتوي expected_delivery_date أو payment_terms أو approved_by أو sent_at. وEdge v7 لا يوفر SEND_PO أو APPROVE_PO. كما أن تحويل quotation إلى PO لا ينقل terms إلى سجل PO.

### الدفع

purchase_post_payment_atomic لا يستقبل payment_method. وعمود purchase_payments.payment_method له default = 'Cash'. لذلك لا يوجد في عقد RPC الحالي اختيار صريح بين Cash وBank Transfer رغم وجود العمود.

### العهدة

توجد treasury وcash_box وfinance_expenses وfinance_expense_lines، لكنها ليست بذاتها عقد عهدة موظف مشتريات له رصيد افتتاحي ووارد وصرف وتسوية ومرفقات واعتماد حسابات. لم يظهر جدول مخصص buyer_custody أو employee_advance في الجرد. كما أن purchase_payments يمثل سداد الموردين، لا عهدة المشتري.

تقرير POS Report425 يوضح مبدأ مهمًا يجب الحفاظ عليه: إغلاق صندوق أو تسجيل مصروف لا يثبت تسليم العهدة واستلامها من المحاسب. يجب أن يكون للعهدة مستلم ومسلّم وحالة تسوية وأثر تدقيقي واضح.

### الكاميرا وOCR

items.image_url موجود وpurchase_attachments موجود، لكن Buyer الحالي لا يوفر التقاط صورة أو رفع مرفق. لم يظهر في عقد Edge v7 أي OCR operation أو استخراج بيانات فاتورة. لا يجوز عرض OCR على أنه يعمل قبل توفير خدمة استخراج موثوقة، ومراجعة بشرية، وربط النتيجة بمسودة فاتورة غير مرحّلة.

### Dashboard / Account

purchase_get_dashboard موجود لكنه لا يغطي زيارات اليوم أو عهدة المشتري أو النواقص الحرجة أو PO overdue. لا يوجد expected_delivery_date في PO لتحديد التأخير وفق موعد توريد متفق عليه. كما لا توجد تبويبات اليوم أو حسابي في Buyer الحالي.

---

## 11. CONFIRMED / UNKNOWN / CONFLICT / UNVERIFIED

### CONFIRMED
- Buyer الحالي 137 سطرًا وثلاثة تبويبات فقط.
- Realtime purchase_orders مربوط بالمحرك المشترك في المصدر.
- Production save-purchase-order v7 مطابق byte-for-byte لمصدر Current/Edge_Functions/save-purchase-order في مستودع الحوكمة.
- Buyer يرسل عقدًا قديمًا لا يطابق v7.
- Edge v7 لا يطبق permission check.
- purchase_get_dashboard متاحة لـanon/authenticated وتفتقر إلى ربط الشركة بهوية Auth.
- RLS supplier/item يعتمد helper لا يقرأ role_permissions.
- submit_request يحتوي أسماء أعمدة لا توجد في purchase_status_history.
- purchase_create_request_atomic وpurchase_create_invoice_atomic لا يقيدان item lookup بـcompany_id.
- جداول الموردين وPO وPR لا تحتوي كل حقول المواصفات المذكورة في تكليف المالك.
- لا توجد تغييرات Production أو بيانات أعمال في هذه الدورة.

### CONFLICT
- واجهة Buyer مقابل Edge v7.
- صلاحيات get_my_effective_profile مقابل current_user_has_permission.
- مواصفات PR المعروضة مقابل حقول PR الفعلية وحالة الاستلام.
- المواصفات المطلوبة للموردين/PO/العهدة مقابل نموذج البيانات الحالي.

### UNKNOWN
- صلاحيات حساب المشتري الفعلي المحدد ونتيجة RLS معه.
- هل يوجد مستهلك مباشر آخر لـpurchase_get_dashboard خارج المصادر التي أمكن جردها.
- مسار Storage/OCR خارجي معتمد للمرفقات.
- كيف يريد المالك اعتماد PO وإرساله للمورد عمليًا، وهل الإرسال بريد/واتساب أو مجرد نشر داخلي.
- طريقة التسوية الحالية لعهدة موظف مشتريات في الحسابات، إن كانت موجودة خارج الجداول التي تم فحصها.

### UNVERIFIED
- Cloudflare served buyer artifact ونسخة HTML المنشورة.
- HTTP/Browser E2E بحساب مشتريات مصادق عليه.
- تسليم Realtime events في متصفح حقيقي.
- آثار المخزون والقيود بعد تنفيذ فاتورة شراء فعلية.
- رحلة PR → RFQ → quotation → PO → receiver → invoice → payment كاملة.
- مقارنة تنافسية موثقة مع SAP/Dynamics/Odoo في هذه الدورة؛ لم أجر بحثًا خارجيًا للمنافسين بعد.

---

## 12. خطة الإغلاق الجراحي — بالترتيب الإلزامي

1. **Security first:** استعادة مصدر Edge v7 إلى مستودع التشغيل أو ربطه بمصدر رسمي واحد، ثم إضافة permission matrix خادمية تشمل purchases/suppliers/finance/approval وتستند إلى الصلاحيات الفعالة. لا تنشر قبل اختبارات رفض/سماح.
2. **RPC exposure:** حسم كل مستهلك لـpurchase_get_dashboard ثم قصر EXECUTE على الخدمة الموثوقة أو إصلاح الدالة لتربط الشركة والمستخدم من Auth.
3. **PR contract repair:** إزالة INSERT history الخاطئ الذي يتعارض مع trigger، وإضافة company guard إلى item lookups، واختبار trigger يسجل مرة واحدة.
4. **Business contract decisions:** تحديد نموذج department، expected delivery، PO terms/approval/send، supplier category/email/rating/visits، buyer custody، payment method.
5. **Read models:** توفير استعلامات/Edge operations مجمعة وآمنة لـPR/PO details/timeline/received quantities/last supplier prices/overdue orders/dashboard.
6. **Buyer UI:** إضافة التبويبات الستة والمودالات على نفس الملف مع الحفاظ على RW_Auth وRW_Realtime؛ لا إعادة كتابة كاملة ولا استبدال core.
7. **Direct purchase:** ربط quick purchase بمسار CREATE_INVOICE ثم مراجعة الاستلام ثم POST_INVOICE وفق سياسة المخزون، مع payment method واضح وتسوية المورد عبر المسار المالي المعتمد.
8. **Supplier file:** إضافة إدارة الموردين والزيارات والتقييم والمرفقات فقط بعد اعتماد نموذج البيانات والصلاحيات.
9. **Verification:** static parse + unit/mock contracts + SQL rollback tests + authenticated browser E2E + cross-app Receiver/Parent/Finance verification + served artifact check.
10. **Closure:** تحديث CURRENT_STATE وProject Memory بعد كل مرحلة، ولا تستخدم CLOSED أو PRODUCTION READY قبل اكتمال الدليل.

### Owner Change Set policy

أي تعديل HTML سيُسلّم على هيئة رقع جراحية محددة للمالك، مع إعادة التحقق من SHA قبل التطبيق، وموضع البداية والنهاية الأصليين، والاستبدال الكامل للدالة فقط عندما تكون الدالة هي أصغر وحدة آمنة، ثم اختبارات قبول محددة. لا تُطبق رقعة قديمة على Blob مختلف.

---

## 13. سجل التغيير والتنفيذ

| الطبقة | ما حدث |
|---|---|
| Git operational | قراءة فقط |
| Git governance | إعداد هذا التقرير وتحديث الحالة والذاكرة |
| Supabase Production | استعلامات قراءة فقط للمخططط والـRLS والـACL والوظائف والبيانات والـEdge |
| Edge deployment | لم يتم |
| RLS / Grants / RPC / Migration | لم تتغير |
| Business data / Stock / Accounting | لم تتغير |
| Buyer HTML | لم يتغير |
| Cloudflare | لم يتم التحقق من artifact |
| Browser E2E | لم ينفذ |

## 14. NEXT SINGLE PRIORITY

**تأمين عقد المشتريات الخلفي قبل توسيع Buyer UI:** توحيد مصدر Edge v7 في مستودع التشغيل، وإغلاق فجوة permission enforcement وRPC exposure وPR submit/item-company guards، مع اختبارات معزولة لا تكتب بيانات أعمال حقيقية. بعد ذلك يصبح توصيل تبويبات Buyer الستة بالعقود القائمة آمنًا وقابلًا للتحقق.

**الحالة النهائية لهذه الدورة:** تشخيص موثق ومثبت؛ لا تعديل تشغيلي أو إنتاجي تم؛ مهمة Buyer ما زالت OPEN.
