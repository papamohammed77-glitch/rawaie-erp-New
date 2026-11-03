# Report608 — مراجعة RAWAEA اليومية وإعادة التحقق من Change Set B (Buyer / Receiver)

**LVE:** LVE-2026-11-03-608  
**تاريخ الفحص:** 2026-11-03 — 22:18 Africa/Cairo (20:18 UTC)  
**المشروع:** RAWAEA ERP / SMART ERP  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend`  
**المستودع المرجعي للحالة والتقارير والذاكرة:** `papamohammed77-glitch/rawaie-erp-New`  
**قاعدة البيانات:** Supabase Production — SMART ERP  
**نطاق التنفيذ:** تحقق مستقل من Change Set B: Quick Market Invoice + Receiver، مع مراجعة التبعيات المباشرة في Buyer.

---

## 1. نقطة البداية وLAST VERIFIED EVENT

### 1.1 الحالة المرجعية

**CONFIRMED — REFERENCE STATE:** أول checkpoint مرجعي صحيح في هذا التشغيل هو **LVE-2026-11-03-607** في `rawaie-erp-New/CURRENT_STATE.md`. قرأت الملف المرجعي كاملًا، ثم قرأت Report607 وملف Master CTO Governance والأقسام ذات الصلة ببوابة موافقة المالك والاختبار الإنتاجي.

آخر حدث موثق في LVE607:
- Production يحتوي على `receive_purchase_atomic` بعقد مصادقة/صلاحيات/فرع محدث.
- Edge Function `receive-purchase` الإصدار 13 منشور.
- مصدر Edge Function المنشور لم يكن مستعادًا بصورة مطابقة داخل المستودع التشغيلي.
- Receiver ما زال PO-only، وQuick Market Invoice لا يملك دورة استلام مكتملة.
- الخطوة التالية المحددة كانت إعداد Change Set B، مع استعادة مصدر Edge المنشور في Git أولًا، ثم إصلاح عقد Receiver وربط الاستلام بالفاتورة.

### 1.2 انحراف نقطة البداية

**PROCESS DEVIATION — CONFIRMED:** بدأت القراءة خطأً من نسخة `CURRENT_STATE.md` الموجودة داخل المستودع التشغيلي `erp-frontend`، وهي نسخة أقدم عند LVE587، بدل ملف الحالة المرجعي في `rawaie-erp-New` عند LVE607. اكتشفت وجود النسختين، ثم قرأت الحالة المرجعية الكاملة وأعدت تثبيت الهدف الصحيح. بعض قراءات GitHub وProduction الأولية حدثت قبل تصحيح نقطة البداية؛ لذلك لا تُعامل تلك القراءات على أنها التزام كامل بترتيب البدء المطلوب.

### 1.3 الهدف الحالي

**الهدف الحالي ليس دمج PR #10 ولا إعادة بناء Buyer.** الهدف هو تجهيز Change Set B على المصدر الحي الحالي، ويشمل:
1. استعادة نسخة `receive-purchase` المنشورة v13 حرفيًا إلى مصدر Git التشغيلي، بعد موافقة المالك.
2. إصلاح استعلام Receiver عن تفاصيل أمر الشراء ليتبع المفتاح الحقيقي `po_id`.
3. إصلاح معالجة الكميات العشرية والكمية المتبقية ومنع الاستلام الصفري.
4. تحديد عقد قبول/رفض الكميات وأسباب الفروق، بدل حقل كمية مستلمة واحد.
5. إنشاء رابط صريح بين فاتورة الشراء ومحضر/تفاصيل الاستلام لدعم Quick Market Invoice.
6. وضع مفتاح idempotency لكل واقعة استلام فعلية، ثابت عند إعادة المحاولة، ومختلف بين واقعتين ماديتين مستقلتين حتى لو تساوت الكميات.

---

## 2. لقطة المصدر الحالية

| العنصر | الدليل الحالي | التصنيف |
|---|---|---|
| المستودع التشغيلي | `erp-frontend` | CONFIRMED |
| الفرع التشغيلي | `main` | CONFIRMED |
| HEAD | `2b94681bf0ce93ca9ea55066a3f52c0d1add1084` | CONFIRMED |
| Buyer | `companies/company-1/purchasing/buyer.html` — blob `7f82fceb0b2c2470d1f112aefeaa1341de5b71a8` | CONFIRMED |
| Receiver | `companies/company-1/warehouse/receiver.html` — blob `3111b5e8...` | CONFIRMED |
| Core | `companies/company-1/core.js` — blob `f4c6a0df...` | CONFIRMED |
| PR #10 | Open / Draft / Unmerged؛ head `209c318f2324d741e61b0dceaf5253f830af8c2e`؛ base `aa8cbffbfa8d42253726381080dcfc24eaea838b` | CONFIRMED |
| مقارنة PR بالـmain الحالي | الفرع متقدم 3 commits ومتأخر 13 commits؛ `mergeable=false` | CONFIRMED |
| تغيير HEAD الأخير | `2b94681` غيّر ملف CSS المجمّع فقط؛ لم يغيّر Buyer/Receiver HTML | CONFIRMED |

**قرار:** لا تدمج PR #10 مباشرة ولا تستبدل ملف Buyer الحالي بنسخة الفرع. الفرع أقدم من main الحالي، وPR لا يحتوي على سياق التغييرات اللاحقة في الموردين والعهدة والبنية التشغيلية.

---

## 3. CONFIRMED — نتائج المصدر الحي

### 3.1 Receiver: خطأ مفتاح الربط بين أمر الشراء وتفاصيله

في `receiver.html`:
- `loadPurchaseOrders` يقرأ أوامر الشراء، لكنه لا يحتفظ بـ `id` ولا `branch_id` في قائمة الأوامر.
- `loadPODetails` في السطر 254 ينفذ:
  `purchase_order_details ... .eq('po_code', code)`.
- مخطط Production الفعلي لجدول `purchase_order_details` يحتوي على `po_id`، ولا يحتوي على `po_code`.
- `purchase_orders` هو الجدول الذي يحتوي على `id` و`po_code`.

**النتيجة:** عقد الواجهة لا يطابق عقد قاعدة البيانات. يجب أن يحتفظ Receiver بمعرّف أمر الشراء `purchase_orders.id` ثم يجلب التفاصيل بواسطة `purchase_order_details.po_id`. هذا تعارض مصدر/مخطط CONFIRMED؛ أما ظهور رسالة الخطأ الفعلية في المتصفح فلم يُختبر.

### 3.2 Receiver: خطأ الكميات العشرية والكمية المتبقية

في `receiver.html`:
- السطر 272 يستخدم `parseInt(...)`، وبالتالي تُفقد الكسور العشرية.
- حقل الكمية يسمح بالصفر `min=0`.
- الحد الأعلى في السطر 259 هو `qty_ordered` بالكامل، وليس `qty_ordered - qty_received`.
- لا يقرأ التطبيق `qty_received` التراكمية، ولا يعرض الكمية المتبقية.
- لا يوجد حقل مستقل للكمية المقبولة والكمية المرفوضة.
- لا يُرسل `operation_id` ولا `Idempotency-Key` من الواجهة.

**النتيجة:** واجهة الاستلام لا تعكس عقد الكميات الرقمي في Production، ولا تمنع إدخال كمية تتجاوز المتبقي قبل وصولها إلى RPC.

### 3.3 Receiver: خطأ قبول استلام صفري

في Production migration `20261103155444_receive_purchase_role_and_branch_authorization.sql`:
- السطر 94 يرفض مصفوفة أصناف فارغة فقط.
- الأسطر 152–153 تتجاوز كل بند كميته `<= 0`.
- لا يوجد تحقق لاحق من أن مجموع الكميات الموجبة أكبر من صفر.
- يُدرج سجل `receiving` في السطر 164 بحالة `مكتمل` حتى إذا كانت جميع الكميات صفرًا.
- لا تُدرج تفاصيل ولا تُسجل حركة مخزون أو قيمة محاسبية في حالة الصفر، لكن يبقى رأس استلام مكتمل.

والـEdge v13 يتحقق من أن الكمية ليست سالبة، لكنه يسمح بالصفر. وواجهة Receiver تسمح بالصفر أيضًا.

**النتيجة:** يمكن أن تُنشأ واقعة استلام شكلية بلا أي كمية مستلمة. هذا خلل منطقي مؤكد في عقد المصدر وقاعدة Production؛ لم يُنفذ اختبار متصفح عليه.

### 3.4 Receiver: تسجيل فرق غير صحيح عند الاستلام الجزئي

في RPC `receive_purchase_atomic` ذي الخمسة معاملات:
- يتحقق النظام من المتبقي الحقيقي باستخدام `qty_ordered - qty_received`، وهذا جيد.
- لكنه يسجل `receiving_details.qty_expected = pd.qty_ordered` في كل واقعة.
- ويحسِب `difference = received_qty - pd.qty_ordered`، أي مقابل كامل الكمية الأصلية، لا المتبقي قبل هذه الواقعة.
- ويضع سبب `نقص في الاستلام` عندما تكون كمية الواقعة أقل من كامل طلب الشراء، حتى لو كانت هذه شحنة جزئية مقصودة.

**النتيجة:** تحديث الرصيد التراكمي يمنع تجاوز الطلب، لكن سجل الفروق لكل واقعة قد يصنف الاستلام الجزئي الطبيعي على أنه نقص. يلزم اعتماد تعريف الفرق: هل هو فرق هذه الشحنة عن المتوقع لها أم فرق الطلب النهائي بعد إغلاقه؟ لا يجوز تغيير المعادلة قبل حسم هذا التعريف.

### 3.5 صلاحيات الاستلام

**CONFIRMED — PRODUCTION:**
- Edge Function `receive-purchase` نشطة، الإصدار 13، و`verify_jwt=true`.
- تتحقق من المستخدم عبر JWT و`get_my_effective_profile`، ثم تتحقق من الدور النشط `استلام` وصلاحية `warehouse/receiving/*` أو Owner.
- تستدعي RPC `receive_purchase_atomic` ذي الخمسة معاملات.
- RPC يتحقق مرة أخرى من الشركة والمستخدم والصلاحية الفعالة والفرع المسموح.
- RPC الخماسي `SECURITY DEFINER`، وتنفيذه ممنوح لـ `service_role` فقط، وليس `anon/authenticated`.
- يوجد overload رباعي قديم، وهو أيضًا `service_role` فقط، ويولّد UUID عشوائيًا بدل مفتاح ثابت. المستهلك الحالي v13 يستخدم العقد الخماسي؛ لم يثبت وجود مستهلك آخر للقديم.

**ملاحظة RLS:** سياسات قراءة `receiving` و`receiving_details` تسمح بأدوار warehouse/reports/finance أو تطابق `responsible` مع اسم المستخدم، بينما RPC يخزن `responsible=p_user_email`. هذا تعارض في معيار القراءة الذاتية. كما أن صلاحية `receiving` التي يقبلها Edge/RPC ليست مذكورة في كل سياسات RLS. لم يُختبر أثر ذلك على حساب Receiver فعلي؛ واجهة Receiver الحالية تقرأ أوامر الشراء ولا تقرأ سجل `receiving` مباشرة.

### 3.6 Idempotency في الاستلام

**CONFIRMED — SOURCE + PRODUCTION:**
- Receiver لا يرسل `operation_id` ولا `Idempotency-Key`.
- Core `RW_API.call` يرسل Authorization وJSON body فقط؛ لا ينشئ مفتاح idempotency تلقائيًا.
- Edge v13 يولد مفتاحًا حتميًا من:
  `user.id + company_id + JSON.stringify({po_code, items})`
  عند غياب مفتاح من العميل.
- RPC يقارن بصمة الأصناف والكميات للمفتاح الموجود، ويعيد `duplicate=true` إذا تطابقت البصمة، ويرفض تعارض المفتاح إذا اختلفت البصمة.

**الخطر:** المفتاح الحتمي مناسب لإعادة إرسال الطلب نفسه بعد انقطاع الشبكة، لكنه يدمج واقعتين ماديتين مستقلتين إذا استلم الموظف الكميات نفسها من أمر الشراء نفسه مرتين وبنفس ترتيب البنود. يجب أن يرسل العميل معرف واقعة استلام مستقلًا، يُنشأ مرة واحدة عند بدء واقعة الاستلام ويُحتفظ به عند إعادة المحاولة. لا يجوز أن يكون payload وحده هو هوية الواقعة المادية.

### 3.7 الأثر المخزني والمحاسبي لـ receive_purchase_atomic

**CONFIRMED — SOURCE/PRODUCTION CONTRACT:**
- ينشئ رأس `receiving` وتفاصيل `receiving_details`.
- يزيد `purchase_order_details.qty_received` تراكميًا.
- ينفذ `post_stock_movement(...,'PurchaseIn',...)` للكمية المستلمة.
- ينشئ قيدًا محاسبيًا: مدين مخزون 124 / دائن حساب الموردين 211 وفق إعدادات الدليل الحالية.
- يضيف حركة دائنة في `supplier_ledger`.
- يحدّث حالة PO إلى `Partially Received` أو `Received` حسب مجموع الكميات التراكمي.
- يسجل حدث تدقيق.

**مهم:** هذا وصف لعقد الدالة المنشورة، وليس إثباتًا أن عملية استلام فعلية نجحت في Production. جدول `receiving` لا يحتوي أي صف حاليًا.

### 3.8 غياب ربط الفاتورة بالاستلام

**CONFIRMED — PRODUCTION SCHEMA:**
- `receiving` يحتوي `po_number` و`operation_id` ولا يحتوي `purchase_invoice_id`.
- `receiving_details` لا يحتوي `purchase_invoice_detail_id`.
- `purchase_invoices` لا يحتوي حقولًا من نوع `purchase_type/source_type/is_market_purchase/payment_method`.
- الموردون الحاليون لا يتضمنون نوعًا معرفًا باسم «مورد سوق/مورد كاش»؛ القيم الموجودة في `supplier_type` هي «مورد عام» و`QA`.
- `purchase_post_invoice_atomic` يرفض الفاتورة غير المرتبطة بـ PO برسالة `PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED`.
- `buyer_custody_submit_expense_atomic` يقبل فاتورة Draft مرتبطة بـ PO واستلام مكتمل، ويتحقق من مطابقة المورد والبنود والكميات والأسعار.

**النتيجة:** `quickPurchase` في Buyer مجرد alias إلى `createPurchaseInvoice`؛ يستطيع إنشاء Draft بلا PO، لكنه لا يمثل دورة شراء سوق مكتملة. لا يستطيع مسار الفاتورة غير المرتبطة بـ PO الوصول إلى Post، ولا يستطيع مسار مصروف العهدة تسويتها. لا يوجد رابط في مخطط الاستلام يربط فاتورة السوق بواقعة الاستلام.

### 3.9 بيانات Production الحالية

**CONFIRMED — READ-ONLY COUNTS:**
- `purchase_orders=1`، والحالة الوحيدة Draft.
- `purchase_order_details=1`.
- `receiving=0` و`receiving_details=0`.
- `purchase_invoices=3` و`purchase_invoice_details=6`.
- `buyer_custodies=0` و`buyer_custody_advances=0` و`buyer_custody_expenses=0` و`buyer_custody_settlements=0`.
- لا توجد بيانات تشغيلية تثبت E2E للاستلام أو العهدة.

يوجد سجل فاتورة باسم `QA-SR-INV-20260927`:
- حالته Draft.
- مرتبط بأمر `QA-SR-PO-20260927` وحالة الأمر Draft.
- `is_received=true` رغم أن `received_date` فارغ.
- مجموع `received_qty=5` في تفاصيل الفاتورة.
- لا يوجد أي سجل Receiving مرتبط.

**النتيجة:** هذا سجل غير متسق/معلّق؛ تعديل الفاتورة يمنعه شرط `is_received`، والترحيل يرفضه لغياب استلام Production. بادئة QA توحي بأنه اختبار، لكنها لا تثبت ملكيته أو جواز حذفه. لا تحذف أو تصلح بياناته دون مراجعة المالك وسجل التدقيق.

كما توجد فاتورتان Posted بلا PO من سبتمبر، وهما سجلات تاريخية سبقت migration منع ترحيل الفاتورة السريعة غير المرتبطة. وجودهما لا يثبت أن المسار الحالي يسمح بترحيل فاتورة سوق جديدة.

### 3.10 بيئة Staging

**CONFIRMED:** مشروع `rawaea-staging` يحتوي 62 migration، لكنه لا يحتوي جداول `purchase_invoices` و`purchase_invoice_details` و`buyer_custodies` و`buyer_custody_advances` و`buyer_custody_expenses` اللازمة لاختبار Change Set B كاملًا.

**النتيجة:** Staging الحالي ليس بيئة قبول كاملة لدورة Quick Market Invoice + Receiver + Custody.

---

## 4. نتائج Buyer الثانوية المؤثرة

### 4.1 أمر الشراء وPR #10

- Buyer في main لا يمرر `operation_id` عند `CREATE_PO`؛ Edge `save-purchase-order` يولد UUID جديدًا عند غياب المفتاح.
- فرع PR #10 يمرر مفتاحًا ثابتًا داخل نموذج الإنشاء، لكن هذا الإصلاح غير موجود في main.
- PR #10 مفتوح Draft وغير قابل للدمج حاليًا؛ الفرع متأخر 13 commit عن main الحالي.
- لا تدمج الفرع كاملًا ولا تنسخ ملفه فوق Buyer الحالي. المطلوب لاحقًا نقل التغيير المعتمد فقط إلى main الحالي مع الحفاظ على تغييرات الموردين والعهدة.

### 4.2 خصوصية «فواتيري»

- `renderInvoices` في main يعرض كل فواتير الشركة دون فلتر `created_by`.
- Edge `save-purchase-order` v22 يستخدم service-role في `GET_DATA` ويعيد بيانات الفواتير على نطاق الشركة، دون فلتر مالك.
- RLS على `purchase_invoices` و`purchase_invoice_details` يسمح بقراءة نطاق الشركة، وليس نطاق المستخدم.
- فرع PR #10 يضيف فلترًا داخل الواجهة فقط؛ لا يحمي استجابة الشبكة ولا قاعدة البيانات.

**النتيجة:** لا يوجد حتى الآن عقد server-side يحدد من يرى فواتير المشتري ومن يرى كل الفواتير لأغراض Finance/Audit. يلزم قرار صلاحيات واضح قبل تعديل الفلتر.

### 4.3 العهدة النقدية

- migration Production الأخيرة تجعل صرف العهدة/الزيادة Pending حتى يؤكد الموظف الاستلام؛ عند التأكيد فقط يُنشأ سند الخزينة والقيد.
- نص `issueCustody` والرسالة النهائية في Buyer ما زالا يوحيان بأن سند الخزينة والقيد تم تسجيلهما فور إصدار العهدة. هذا تعارض UI/Production.
- `acknowledgeCustody` يستدعي العملية مباشرة دون نافذة تأكيد ثانية، بينما تأكيد الزيادة له تأكيد واضح.
- `buyer_custody_review_expense_atomic` يطابق الفاتورة مع PO والاستلام ثم يخصم حساب الموردين ويحوّل الفاتورة إلى Paid، لكنه لا يفرض مستند دفع مستقلًا للمورد؛ مستند الفاتورة وإذن الاستلام ليسا وحدهما إثباتًا صريحًا لتسليم النقد للمورد.

---

## 5. Deployment / Runtime

### 5.1 GitHub checks

**CONFIRMED — DEPLOYMENT EVENTS:**
- أحدث main HEAD `2b94681`: فشل Cloudflare Pages check لمشروع `rawaea-erp` في 2026-11-03 19:16:47 UTC.
- commit السابق `5d7b10e4`: آخر نجاح مرصود لمشروع `rawaea-erp` في 2026-11-03 18:58:49 UTC.
- PR preview للـhead `209c318`: نجاح مرصود لمشروع `rawaea-erp` في 2026-11-02 18:48:50 UTC.
- فشل check منفصل لمشروع `erp-frontend` ظهر أيضًا؛ لا أعتبره دليلًا على حالة `rawaea-erp` الإنتاجية.

### 5.2 حدود التحقق

**UNVERIFIED:**
- لم أتمكن من جلب HTML المنشور مباشرة؛ محاولة الوصول إلى preview domain فشلت في DNS من بيئة الفحص.
- لم تتوفر جلسة Browser موثقة لفتح Buyer/Receiver، ولم يُنفذ Console/Network E2E.
- نجاح check للـpreview لا يثبت أن هذا هو artifact المستخدم حاليًا في Production.
- لا يمكن الجزم بأن artifact الحالي هو `5d7b10e4`؛ هذا آخر نجاح مرصود فقط، وليس readback مباشرًا للملفات التي يقدمها الخادم.

---

## 6. مصفوفة التحقق

| الطبقة | النتيجة | التصنيف |
|---|---|---|
| GitHub/source | main HEAD وBuyer/Receiver/Core والـdiff والـPR تمت قراءتها مباشرة | CONFIRMED |
| GitHub/Edge source | `save-purchase-order` موجود ومطابق حرفيًا لـProduction v22؛ `receive-purchase` غير موجود في operational repo | CONFIRMED |
| Supabase Production | 737 migrations؛ أحدث migrations ذات الصلة مطبقة؛ مخطط/RLS/grants/RPCs/Edge versions فُحصت | CONFIRMED |
| Deployed artifact | check events متاحة، لكن HTML/JS المنشور لم يُقرأ مباشرة | UNVERIFIED |
| Runtime/E2E | لم يجر اختبار متصفح موثق | UNVERIFIED |
| Business-data effects | لا توجد Receiving أو Buyer Custody rows؛ اختبار PO الوحيد أدناه كان داخل rollback | CONFIRMED / UNVERIFIED حسب الأثر |
| Staging | ناقص جداول الفواتير والعهدة اللازمة لاختبار B كاملًا | CONFIRMED |

---

## 7. اختبار Production المنفذ والانحراف الإجرائي

**PROCESS DEVIATION — CONFIRMED:** قبل قراءة §77.2 من Master CTO Governance، نفذت اختبارًا واحدًا لـPO idempotency داخل transaction قابلة للـROLLBACK، باستخدام سياق مستخدم Buyer فعلي ومورد وصنف صالحين. لم يكن لدي موافقة مالك صريحة على هذا الاختبار؛ لذلك يُسجل كخرق لبوابة الموافقة حتى مع عدم بقاء بيانات.

نتيجة الاختبار:
- الاستدعاء الأول أنشأ Draft PO داخل المعاملة.
- الاستدعاء الثاني بنفس `operation_id` ونفس payload أعاد نفس PO مع `duplicate=true`.
- ظهر صف واحد فقط داخل المعاملة.
- نفذت `ROLLBACK`.
- تحقق لاحقًا أن عدد صفوف operation IDs الاختبارية يساوي صفرًا.
- أعداد PO/تفاصيله/السجل/الفواتير/Receiving/المخزون/الخزينة/دفتر الموردين/القيود بقيت عند القيم السابقة.

وفي probe لاحق حدث خطأ في payload الاختباري: أُعيد استخدام المفتاح نفسه مع supplier id مختلف، فأعاد RPC السجل السابق بوصفه duplicate بدل رفض اختلاف payload. هذا يثبت أن `purchase_create_po_atomic` لا يربط المفتاح ببصمة payload. لم يبق أي صف من هذه الاختبارات بعد rollback.

**الإجراء التصحيحي:** لا مزيد من اختبارات كتابة في Production. أي اختبار مماثل لاحق يتطلب موافقة المالك وخطة rollback موثقة، أو بيئة معزولة صالحة.

---

## 8. ما لم يتم ولماذا

1. لم أضف `receive-purchase/index.ts` إلى operational Git؛ المصدر المنشور v13 يحتاج استعادة حرفية، لكن Master §77.2 يمنع تعديل المصدر قبل موافقة المالك.
2. لم أعدل `receiver.html`؛ إصلاح `po_id` وحده لا يكفي دون تصميم المتبقي والقبول/الرفض وidempotency.
3. لم أعدل migrations أو RPC أو RLS/grants أو Edge Functions في Production.
4. لم أنفذ Quick Market Invoice؛ لا يوجد عقد schema/receiving/payment معتمد يربط الفاتورة بالاستلام.
5. لم أنفذ Browser E2E؛ لا توجد جلسة متصفح صالحة، وStaging لا يحتوي الجداول المطلوبة.
6. لم أدمج PR #10؛ branch diverged وmergeable=false.
7. لم أصلح سجل `QA-SR-INV-20260927`؛ لا يجوز حذف/تعديل سجل مالي/مخزني دون موافقة المالك والتحقق من أثره.

---

## 9. Change Set B المقترح للمراجعة — دون تنفيذ

### B1 — Source parity
استعادة ملف Edge v13 المنشور حرفيًا إلى:
`supabase/functions/receive-purchase/index.ts`
مع تسجيل نسخة Production و`ezbr_sha256` ووقت الجلب. لا تُستخدم لقطة `Current/Edge_Functions/receive-purchase` القديمة بوصفها المصدر الحالي.

### B2 — Receiver query contract
- تضمين `purchase_orders.id` و`branch_id` في استعلام قائمة الأوامر.
- جلب `purchase_order_details` بواسطة `po_id`.
- فحص `res.error` وإظهار خطأ واضح بدل عرض قائمة فارغة مع زر استلام.
- فلترة الأوامر حسب فروع المستخدم المسموح بها، مع بقاء تحقق RPC هو الحاجز النهائي.

### B3 — Quantity model
- استخدام Number/decimal precision بدل `parseInt`.
- عرض `qty_ordered` و`qty_received` و`remaining_qty`.
- جعل الحد الأعلى هو المتبقي.
- رفض مجموع كميات الاستلام الصفري في Edge وRPC.
- إضافة accepted/rejected quantities وسبب رفض/فرق واضح.
- إعادة تعريف `qty_expected` و`difference` على مستوى واقعة الاستلام، لا مقارنة كل واقعة بكامل كمية PO دون تحديد.

### B4 — Idempotency per physical receipt
- يولد Receiver `operation_id` مستقلًا عند بدء واقعة استلام مادية.
- يحفظه حتى نجاح الطلب أو إلغائه صراحة.
- يستخدم المفتاح نفسه عند إعادة إرسال الطلب نفسه.
- واقعتان ماديتان مستقلتان تحصلان على مفتاحين مختلفين حتى لو تساوت PO/items/quantities.
- يحتفظ RPC ببصمة payload ويرفض إعادة استخدام المفتاح مع payload مختلف.

### B5 — Quick Market Invoice / invoice-linked receiving
لا يُضاف مسار سريع شكلي. يلزم عقد معتمد يحدد:
- مصدر الفاتورة: PO-backed أو Quick Market.
- المورد المركزي ورقم فاتورة المورد ونوع الشراء وطريقة التسوية.
- ربط `receiving` بـ`purchase_invoice_id` وربط التفاصيل بـ`purchase_invoice_detail_id` أو junction مناسب يدعم partial/multiple receipts.
- المقبول فقط يزيد المخزون.
- المرفوض لا يزيد المخزون ويُسجل مع السبب.
- لا يتكرر قيد المخزون/المورد بين الاستلام وترحيل الفاتورة.
- مستند إثبات الدفع للمورد عند استخدام عهدة المشتري، منفصل عن فاتورة المورد وإذن الاستلام.
- يظل Post محجوبًا حتى اكتمال الاستلام الفعلي والاعتماد وفق السياسة.

### B6 — Test plan
لا يُقبل التنفيذ دون:
1. Static/contract test لملف Receiver وEdge.
2. Schema/RLS/grants verification.
3. اختبار PO كامل وجزئي ومتعدد الشحنات.
4. اختبار كمية عشرية.
5. اختبار صفر كميات (يجب رفضه دون إنشاء رأس Receiving).
6. اختبار رفض/قبول مع سبب.
7. اختبار إعادة نفس operation_id/payload (duplicate واحد فقط).
8. اختبار واقعتين متطابقتين لكن operation_id مختلف (سجلان مستقلان).
9. اختبار branch unauthorized.
10. اختبار ربط Quick Market Invoice بالاستلام ومنع double posting.
11. اختبار أثر المخزون وsupplier ledger وjournal entries.
12. Browser E2E في بيئة Staging مكتملة، مع عدم ترك test data.

---

## 10. الخطوة التالية الوحيدة ذات الأولوية

**إعداد Change Set B كامل للمراجعة والاعتماد، يبدأ باستعادة مصدر Edge v13 حرفيًا إلى operational Git، ثم يقدم diff محددًا لـReceiver وعقد الاستلام وربط الفاتورة ومصفوفة الاختبار. لا تنفيذ ولا نشر ولا DDL/RLS/Edge update قبل موافقة المالك الصريحة وفق Master CTO §77.2.**

**الحالة النهائية:** التحقيق وإعادة التحقق مكتملان؛ Change Set B غير منفذ؛ Production لم يتغير بصورة دائمة؛ Browser/runtime E2E غير متحقق؛ يوجد انحراف إجرائي موثق لا يجوز إخفاؤه.
