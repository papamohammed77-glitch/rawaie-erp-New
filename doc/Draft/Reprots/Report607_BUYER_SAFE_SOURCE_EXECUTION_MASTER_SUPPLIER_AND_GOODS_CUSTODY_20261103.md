# Report607 — تنفيذ Buyer الآمن: سلطة المورد المركزي وتهيئة «رصيدي»

**التاريخ:** 2026-11-03 — Africa/Cairo  
**نقطة البداية:** LVE-2026-11-03-606 / Report606.  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` / `main`.  
**مستودع الحالة والتقارير:** `papamohammed77-glitch/rawaie-erp-New` / `main`.  
**Production:** SMART ERP — `fiilmooggumokxanwiyx`.  
**الحالة:** PARTIAL SOURCE EXECUTION / NO PRODUCTION WRITE / NOT E2E-VERIFIED / OVERALL OPEN.

## 1. Last Verified Event

تمت إعادة قراءة LVE-606 وReports603–606 وBuyer/Receiver/Core الحاليين، وإعادة الاستعلام من مخطط SMART ERP Production وإصدارات Edge/RPC المتاحة. نُفذت تعديلات محددة وآمنة في Buyer فقط. لم يُلمس `companies/company-1/main.html`، ولم تُنشأ Edge Function، ولم يحدث أي تغيير على قاعدة البيانات أو بياناتها أو نشر Cloudflare.

## 2. Current Git Evidence

- Operational HEAD بعد التعديل: `5d7b10e4fd0fdf1bb2299c87805f9c86d381cc35`.
- Parent: `df7ad3aaa38b10dfaef6a3beb47780be4f5cfc9d`.
- Buyer: `companies/company-1/purchasing/buyer.html`.
- Buyer blob الحالي: `7f82fceb0b2c2470d1f112aefeaa1341de5b71a8`.
- Parent `main.html`: لم يُعدل.
- Receiver `companies/company-1/warehouse/receiver.html`: لم يُعدل.
- Core `companies/company-1/core.js`: لم يُعدل.
- Existing Edge: `save-purchase-order` v22 ACTIVE/JWT، و`receive-purchase` v13 ACTIVE/JWT. لم يتم إنشاء Function جديدة ولم يتم استبدال أي Edge.

## 3. التغييرات المنفذة في Buyer

### A — Master Supplier Authority (تم على مستوى المصدر)

1. أزيل زر «مورد جديد» من تبويب الموردين.
2. أُزيل مسار إنشاء/تعديل المورد من واجهة Buyer؛ بقيت `supplierForm()` كحاجز رفض صريح، ولا يوجد استدعاء `SAVE_SUPPLIER` في الملف.
3. أزيل زر «تعديل» من نافذة تفاصيل المورد؛ أصبحت القراءة فقط.
4. تحولت تسمية التبويب إلى «دليل الموردين المركزي»، مع توضيح أن الإنشاء والإدارة من النظام الأم.
5. أصبحت قائمة الموردين واختيارات عروض الأسعار وأوامر الشراء والفواتير تقبل فقط `is_active === true`، بدل قبول أي سجل لا يحمل `false`.
6. يظهر للمستخدم أن المورد نشط في الدليل المركزي مع شروط الدفع المسجلة.

**حد الإثبات:** Production لا يحتوي `approval_status` مستقلًا، ولم يثبت أن `is_active` يساوي اعتمادًا رسميًا من Master Data. لذلك لم تسمِّ الواجهة المورد «معتمدًا»؛ التعديل يمنع اختيار غير النشط فقط، ولا يخترع عملية اعتماد غير موجودة.

### C — تهيئة «رصيدي» (تصحيح دلالي للواجهة فقط)

1. تغير اسم «رصيد السيارة» إلى «رصيدي».
2. أزيل اعتماد هذا التبويب على `fleet_vehicle_assignments` و`vehicles`؛ لا يمكن استخدام تكليف سائق/مركبة توصيل لإثبات حيازة مشتريات.
3. تعرض الشاشة صراحة أن دفتر عهدة بضاعة المشتريات المركزي غير موجود في مخطط Production، ولا تعرض رصيدًا وهميًا.
4. وثقت الشاشة مراحل الحيازة المطلوبة: المورد→المشتري، المشتري→المخزن، المخزن→المشتري عند صرف المرتجع، ثم المشتري→المورد مع إثبات قبول المورد. المركبة اختيارية والتسليم اليدوي مسموح.
5. لم تُنشأ حركات أو جداول شكلية، ولم يُسمح بتسجيل حركة لا تملك كاتبًا مركزيًا ذريًا.

## 4. ما لم يتغير — لا تعتبره مغلقًا

### B — Quick Market Invoice + Receiver

- Buyer الحالي يملك إنشاء فاتورة بلا PO كمسودة فقط عبر `purchase_create_invoice_atomic_v2`.
- RPC `purchase_post_invoice_atomic` يرفض الترحيل بلا PO حاليًا.
- `receiving` لا يحمل `purchase_invoice_id`، و`receiving_details` لا يحمل `purchase_invoice_detail_id`.
- Receiver الحالي PO-only، و`receive_purchase_atomic` الحالي يقبل `po_code` وليس invoice ID.
- Receiver ما زال يستخدم `purchase_order_details.po_code` بينما المخطط الحالي يربط التفاصيل عبر `po_id`.
- Edge `receive-purchase` v13 تعمل في Production، لكن مصدرها التشغيلي غير موجود في `erp-frontend/main`، والنسخة الموجودة في مستودع الحوكمة ليست مطابقة لبصمة المصدر الحي.
- لم يتم توسيع المسار، ولم تُضف شاشة/زر يوحي بأن استلام السوق يعمل.

### C — دفتر الحيازة المركزي

لم يُنشأ بعد. يتطلب دفترًا Append-only بحركات ذات operation_id فريد، ورصيد مشتق، وقبول/رفض كميات، وربطًا بإذن الاستلام والمرتجع. لا يجوز بناؤه كرصيد قابل للتحرير أو باستخدام مخزون Delivery/Fleet.

### D — Supplier Return Single Writer

ما زالت فجوة المسارين قائمة بين `purchase_returns` و`stock_vouchers.SupplierReturn`. منع تكرار المخزون وAP/GL، وقيد الكمية التراكمي تحت التزامن، وإثبات قبول المورد الجزئي، وربط إيصال المورد، لم تُنفذ. تغيير ACL P0-D وChange Set P0-R ما زالا منفصلين وتحت بوابات الموافقة الموثقة في Reports603/604.

### E — Cash Custody Expense Types

جداول العهدة النقدية الحالية لا تحتوي `expense_category` أو `expense_account_id` أو `payee_kind`. RPC المراجعة الحالي مخصص لمسار فاتورة مورد/PO/استلام/سداد مورد، ولا يمثل FUEL/TRANSPORT/OTHER. لا توجد خريطة حسابات تشغيلية معتمدة لهذه الفئات في COA المفحوص. لم يُغير هذا المسار حتى لا ينشأ AP أو Payment مزدوج أو قيد بمقابل غير معتمد.

### Quick Purchase semantics

`quickPurchase()` لا يزال alias إلى `createPurchaseInvoice()`. لم يُدّع أنه أصبح مسار شراء سوق مكتملًا، ولم تُضف حقول source/settlement غير موجودة في schema/RPC.

## 5. Production / Data Safety

الاستعلام المباشر أعاد تأكيد وجود الجداول الحالية وحقولها. من أهم حدود المخطط:

- `purchase_invoices`: لا يوجد حقل source_type أو settlement_source.
- `receiving`: لا يوجد purchase_invoice_id.
- `receiving_details`: لا يوجد purchase_invoice_detail_id.
- `buyer_custody_expenses`: لا يوجد expense_category أو expense_account_id أو payee_kind.
- `buyer_custodies`: دفتر نقدي، وليس دفتر عهدة أصناف.
- لا يوجد جدول مستقل مثبت لحركات عهدة بضاعة المشتريات.

لم تُنفذ DDL/Migration أو RPC changes أو ACL/RLS changes أو Edge deployment أو تعديل بيانات أو أرصدة Production. لم تُنشأ بيانات تجريبية في Production.

## 6. الاختبارات والتحقق

| الاختبار | النتيجة |
|---|---|
| إعادة جلب Buyer من operational main بعد كل commit | PASS |
| إزالة استدعاء SAVE_SUPPLIER من Buyer | PASS |
| منع إنشاء/تعديل المورد من واجهة Buyer | PASS على مستوى المصدر |
| active-only supplier selection في list/quotation/PO/invoice | PASS على مستوى المصدر |
| تبويب «رصيدي» لا يقرأ Fleet/vehicles | PASS على مستوى الدالة |
| عدم تعديل main.html / Receiver / core.js | CONFIRMED من نطاق commits هذه الدورة |
| SQL/DB regression | NOT RUN — لم تتغير قاعدة البيانات |
| Fixtures / E2E | NOT RUN — لا بيئة Buyer Staging مطابقة |
| Authenticated Browser E2E | UNVERIFIED — لا جلسة Buyer مصادق عليها في هذه الدورة |
| Cloudflare artifact parity / deployment | UNVERIFIED |
| stock/AP/GL/Treasury before-after reconciliation | NOT RUN — لا معاملات اختبار ولا تغييرات Production |

### سبب عدم إنشاء بيانات تجريبية

مشروع `rawaea-staging` لا يملك جداول Buyer الأساسية `purchase_invoices` و`purchase_invoice_details` وجداول عهدة Buyer، ومخططه 62 migration فقط مقابل 737 في Production. لذلك لا يمثل بيئة E2E صالحة. Production ليس بيئة Fixtures. لم أضع بيانات اختبار في حسابات المؤسسة أو مخزون الفروع أو خزائنها بغرض الاختبار.

## 7. القرارات التي تمنع التنفيذ غير الآمن

- لا Edge Function جديدة؛ استهلاك Gateway/Functions cap يمنع ذلك.
- لا تمديد لـ`receive-purchase` v13 قبل استعادة مصدر مطابق ومراجعة عقده الحي.
- لا RPC جديد ولا Migration على Production دون Change Set محدد، SQL كامل، Authorization/RLS، idempotency، concurrency، أثر محاسبي/مخزني، acceptance وrollback وموافقة المالك الصريحة على التغيير المحدد وفق Master CTO §77.2.
- الطلب العام الحالي لا يثبت موافقة على SQL محدد لتغيير دفتر المرتجعات أو دفتر الحيازة أو ترحيل الاستلام؛ لذلك اقتصر التنفيذ الفعلي على تعديلات Buyer المصدرية الآمنة.
- لا لمس لـ`main.html` مطلقًا.

## 8. Next Execution — ترتيب العمل

1. إعداد Change Set B كاملًا: استعادة مصدر Edge v13 المطابق إلى Git، تصميم توسيع Receive RPC الحالي ليدعم PO وQuick Invoice، إضافة علاقات invoice/line إلى receiving، وتصحيح Receiver من po_code إلى po_id، مع الحفاظ على عقد PO.
2. إعداد Change Set C: دفتر حيازة أصناف Append-only، اختياري vehicle_id، استلام مخزن/رفض جزئي، صرف مرتجع إلى عهدة المشتري، قبول المورد/رفضه وإيصالاته، مع writer واحد وربط idempotent.
3. إعداد Change Set D: توحيد purchase_returns وstock_vouchers SupplierReturn، قفل سطر الفاتورة والتحقق التراكمي المتزامن، ومنع AP/GL/stock double-posting.
4. إعداد Change Set E: تصنيف PURCHASE/FUEL/TRANSPORT/OTHER، account mapping معتمد، ومنع Supplier AP/Payment عند تسوية المصروف من العهدة.
5. بعد استكمال Staging schema parity أو توفير اختبار معزول معتمد: fixtures غير إنتاجية، E2E مصادق عليه، اختبارات صلاحيات الشركة/الفرع/الدور، retry/idempotency/concurrency، ومقارنة snapshots للمخزون وAP/GL والخزينة والعهدة.
6. التحقق من Cloudflare artifact والـruntime بعد النشر المعتمد.

**الحكم:** Workstream A نُفذ في Buyer source؛ تبويب «رصيدي» أصبح صادقًا دلاليًا لكنه ليس دفترًا تشغيليًا بعد. Workstreams B–E لم تُنفذ لأن عقودها المركزية غير موجودة/غير مكتملة وبيئة E2E غير صالحة. **OVERALL BUYER: OPEN / NOT PRODUCTION-READY.**
