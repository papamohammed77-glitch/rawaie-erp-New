# Report609 — مراجعة RAWAEA اليومية: Buyer / Receiver / Production Reconciliation

**LVE:** LVE-2026-11-03-609  
**وقت الفحص:** 2026-11-03 — 23:30 Africa/Cairo (21:30 UTC)  
**المستودع التشغيلي:** papamohammed77-glitch/erp-frontend / main  
**مستودع الحالة والتقارير والذاكرة:** papamohammed77-glitch/rawaie-erp-New / main  
**Production:** Supabase SMART ERP — fiilmooggumokxanwiyx  
**نطاق اليوم:** إعادة التحقق من Change Set B، Receiver/Quick Market Invoice، عقد الاستلام، بيانات Production، الصلاحيات، النشر، وسلامة استمرارية الحالة.  
**نوع التنفيذ:** قراءة وفحص فقط في المستودع التشغيلي وProduction. التغيير الوحيد في هذا التشغيل هو هذا التقرير وتحديثات الحالة/الذاكرة في مستودع التوثيق.

---

## الملخص التنفيذي

**النتيجة: Buyer/Receiver ما زالا غير جاهزين للإنتاج التشغيلي الكامل.** لا توجد مشكلة تستدعي إعادة بناء Buyer أو إعادة تنفيذ ضوابط P0 التي سبق تطبيقها. لكن دورة الاستلام نفسها غير مكتملة، وواجهة Receiver لا تطابق مخطط Production، كما أن عقد الاستلام يسمح بإنشاء رأس استلام صفري بلا حركة مخزون.

أهم النتائج الجديدة/المعاد إثباتها:

1. مصدر Receiver يستخدم po_code على جدول تفاصيل لا يحتوي إلا po_id؛ كما لا يفحص أخطاء Supabase داخل نتيجة الاستعلام، ولذلك قد يعرض «لا توجد أصناف» بدل خطأ العقد.
2. Receiver يستخدم parseInt، ولا يقرأ qty_received التراكمية، ويحدد الحد الأعلى بكمية PO الأصلية، ويسمح بالصفر، ولا يرسل operation_id.
3. Edge v13 يولد operation_id حتميًا من المستخدم والشركة وPO والـpayload عند غياب المفتاح. هذا يمنع تكرار إعادة المحاولة، لكنه يدمج واقعتين ماديتين مستقلتين إذا تطابقت الكميات والبيانات.
4. RPC الخماسي يقبل مصفوفة غير فارغة حتى لو كانت كل الكميات صفرًا؛ يتجاوز البنود الصفرية ثم ينشئ رأس receiving مكتملًا ويحوّل PO إلى Partially Received دون تفاصيل أو مخزون أو قيد أو مورد.
5. لا يوجد ربط مباشر بين receiving وpurchase_invoice_id أو بين receiving_details وpurchase_invoice_detail_id؛ لذلك لا يمكن إتمام Quick Market Invoice عبر Receiver الحالي.
6. ظهرت بيانات تاريخية في Production تحتاج مصالحة، لا حذفًا: فاتورتان Posted بلا PO وبعملة SAR مع آثار مخزون ودفتر موردين وقيود؛ وسجل QA غير متسق؛ وأربعة روابط مستندية تشير إلى stock vouchers غير موجودة حاليًا.
7. ضوابط كتابة فواتير الشراء أصبحت SELECT-only للمستخدمين العاديين، وRPC الاستلام محمي بصلاحيات/فرع ويعمل عبر service_role. لكن صلاحيات قراءة PO/Invoices حاليًا على مستوى الشركة فقط، لا على مستوى الفرع أو الإذن الوظيفي.
8. Cloudflare Pages check على HEAD الحالي 2b94681 فشل؛ آخر نجاح مرصود لمشروع rawaea-erp على الأب 5d7b10e. هذا لا يثبت ما يقدمه الخادم حاليًا، والـartifact/runtime لا يزالان UNVERIFIED.
9. Report608 وثّق اختبار كتابة داخل Production transaction مع ROLLBACK. سجلات Production تؤكد تنفيذ معاملتين من هذا النوع ثم ROLLBACK، ولا توجد صفوف متبقية لهما. عدم وجود موافقة صريحة موثق في Report608، لكن لا توجد هنا وسيلة مستقلة لإثبات غياب أي موافقة خارج سجل الحالة؛ يجب التعامل مع الواقعة كحادث انضباط تنفيذي وعدم تكراره.

**لم يُجرَ في هذا التشغيل أي DDL أو DML أو تعديل RLS/GRANT/RPC/Edge أو نشر أو تغيير في Buyer/Receiver أو main.html.**

---

## 1. نقطة البداية — CURRENT_STATE وLAST VERIFIED EVENT

### 1.1 نقطة البداية الملزمة

أول مصدر تمت قراءته هو CURRENT_STATE.md في المستودع المرجعي rawaie-erp-New، وليس أحدث تقرير.

- **LAST VERIFIED EVENT المسجل عند بدء الفحص:** LVE-2026-11-03-607 — Buyer Safe Source Execution / Supplier Master & Goods Custody Naming.
- **آخر حالة مسجلة:** Workstream A source-level complete؛ تبويب «رصيدي» أصبح صحيح التسمية والدلالة لكنه لا يحتوي دفتر عهدة بضاعة؛ B–E مفتوحة؛ Buyer غير جاهز للإنتاج الكامل.
- **الهدف الحالي:** إعداد Change Set B، ويشمل استعادة مصدر receive-purchase v13 حرفيًا في Git التشغيلي، وإصلاح Receiver، وربط Quick Market Invoice بمحضر الاستلام، مع عدم إنشاء Edge جديد.
- **القيود:** عدم تعديل companies/company-1/main.html؛ عدم إنشاء Edge Function جديدة؛ عدم إعادة تنفيذ migrations 20261103155029 و20261103155444 و20261103160902؛ عدم إجراء أي تغيير مؤثر قبل موافقة المالك المحددة وفق Master CTO §77.2.

### 1.2 مصالحة الحالة مع Report608

وجدت Report608 بالفعل في المستودع المرجعي، بتاريخ 22:18 Cairo، بينما ظل CURRENT_STATE عند LVE607. قرأت Report608 باعتباره سجل تحقيق سابقًا، ثم أعدت التحقق من الادعاءات المهمة مباشرة من GitHub وProduction. لم أتعامل مع تقرير 608 أو أي تقرير أقدم على أنه إثبات للحالة الحالية.

هذا التقرير LVE609 يحدّث نقطة الاستئناف ويثبت النتائج الجديدة، مع الاحتفاظ بـ Report608 كما هو دون إعادة كتابة التاريخ.

---

## 2. GitHub / SOURCE CODE — الحالة الحية

### 2.1 المستودع التشغيلي

**CONFIRMED:**
- Repository: papamohammed77-glitch/erp-frontend.
- Branch: main.
- HEAD: 2b94681bf0ce93ca9ea55066a3f52c0d1add1084.
- Parent: 5d7b10e4fd0fdf1bb2299c87805f9c86d381cc35.
- Commit message: build: compile Buyer Tailwind CSS.
- Buyer blob: 7f82fceb0b2c2470d1f112aefeaa1341de5b71a8.
- Receiver blob: 3111b5e801d1bc021cf18fd66d633fbdc54ac0d6.
- Core blob: f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1.

### 2.2 Buyer — ما بقي صحيحًا وما لم يكتمل

**CONFIRMED:**
- Buyer في main لم يعد ينشئ أو يعدل الموردين؛ لا يوجد استدعاء SAVE_SUPPLIER في مسار التطبيق الحالي.
- اختيار الموردين في تدفقات المشتريات أصبح active-only؛ لا يجوز تفسير is_active على أنه موافقة مورد رسمية، لأن schema لا يحتوي approval_status.
- التبويب أصبح «رصيدي» ولا يقرأ Fleet/Delivery vehicle assignment.
- «رصيدي» لا يدّعي وجود رصيد بضاعة؛ دفتر عهدة البضاعة غير موجود.
- quickPurchase ما زال alias إلى createPurchaseInvoice؛ إنشاء فاتورة Draft ليس دورة شراء سوق مكتملة.
- Parent main.html لم يتغير.

**CONFIRMED — عقد الفاتورة:**
- purchase_create_invoice_atomic وpurchase_create_invoice_atomic_v2 يقبلان purchase_order_id اختياريًا، وينشئان Draft، ولا ينفذان حركة مخزون أو قيدًا أو موردًا أو خزينة.
- كلا RPCs ممنوحان لـservice_role فقط.
- purchase_post_invoice_atomic يرفض الفاتورة بلا PO برسالة PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED.
- لذلك إنشاء فاتورة سوق Draft ممكن، لكن استلامها وترحيلها غير ممكنين عبر عقد Receiver الحالي.

### 2.3 Receiver — أخطاء المصدر المؤكدة

**CONFIRMED — مصدر/مخطط:**
- loadPurchaseOrders يقرأ po_code وpo_date وsupplier_name وstatus وtotal_amount فقط؛ لا يحتفظ بـpurchase_orders.id أو branch_id.
- القائمة لا تفلتر حسب فروع المستخدم.
- القائمة تعرض الحالات Sent وPartially Received فقط.
- loadPODetails ينفذ فلترًا على purchase_order_details.po_code.
- Production purchase_order_details لا يحتوي po_code؛ المفتاح الصحيح هو po_id.
- لا يوجد فحص صريح لـres.error في loadPODetails؛ عند إرجاع Supabase نتيجة خطأ مع data فارغة قد يعرض التطبيق «لا توجد أصناف» ويُظهر زر اعتماد الاستلام.
- loadPurchaseOrders أيضًا يعتمد على res.data دون معالجة صريحة لـres.error.
- submitReceiving يستخدم parseInt؛ الكميات العشرية تُختزل إلى أعداد صحيحة.
- الحد الأعلى في الحقل هو qty_ordered الأصلية، وليس المتبقي بعد الاستلامات السابقة.
- التطبيق لا يقرأ qty_received، ولا يحسب remaining_qty.
- الحقل يقبل الصفر، ولا يوجد نموذج مستقل للكمية المقبولة والمرفوضة.
- الواجهة لا ترسل operation_id أو Idempotency-Key.

**النتيجة:** تعارض po_code/po_id مثبت من المصدر والمخطط. أثره في المتصفح متوقع من مسار التنفيذ، لكنه لم يُختبر عبر Browser/Network؛ لذلك runtime behavior يظل UNVERIFIED.

### 2.4 Idempotency — العقد الحالي غير كافٍ لوقائع الاستلام المستقلة

**CONFIRMED:**
- RW_API.call في Core يرسل Authorization وJSON body ولا ينشئ Idempotency-Key أو operation_id تلقائيًا.
- Receiver لا يرسل operation_id.
- Edge receive-purchase v13 يولد UUID حتميًا من user.id + company_id + JSON.stringify({po_code, items}) عند غياب مفتاح العميل.
- RPC يقارن بصمة item_code وreceived_qty فقط.

**الأثر المنطقي:**
- إعادة إرسال نفس الواقعة بعد انقطاع الشبكة تحصل على المفتاح نفسه، وهذا مفيد.
- لكن استلام شحنة ثانية مستقلة بنفس PO ونفس البنود والكميات وبنفس المستخدم يحصل على المفتاح نفسه أيضًا، فيُعامل كـduplicate بدل واقعة جديدة.
- اختلاف reason أو item_name أو unit مع ثبات item_code/received_qty لا يدخل في بصمة RPC الحالية، وبالتالي لا يكتشفه تعارض المفتاح.

لا يوجد اختبار Production أو Browser لهذا السلوك في هذا التشغيل.

### 2.5 كميات الاستلام الجزئي وفروق الاستلام

**CONFIRMED — RPC source:**
- RPC يتحقق من المتبقي الفعلي باستخدام qty_ordered - qty_received، ويمنع تجاوز المتبقي.
- لكنه يسجل receiving_details.qty_expected = qty_ordered في كل واقعة.
- ويحسب difference = received_qty - qty_ordered، أي مقابل الكمية الأصلية كاملة، لا المتبقي قبل هذه الشحنة.
- لذلك قد تظهر الشحنة الجزئية المقصودة كأنها نقص عن كامل أمر الشراء في سجل الواقعة.

هذا ليس مجرد تعديل واجهة؛ يلزم تعريف محاسبي/تشغيلي للفرق: فرق الشحنة عن الكمية المتوقع تسليمها في هذه الشحنة، أم فرق الطلب النهائي بعد إغلاق PO؟ لا تُغيّر المعادلة قبل اعتماد التعريف.

---

## 3. Supabase Production — العقد والمخطط والصلاحيات

### 3.1 صحة المشروع والمهاجرات

**CONFIRMED:**
- Project: SMART ERP / fiilmooggumokxanwiyx.
- Status: ACTIVE_HEALTHY.
- PostgreSQL: 17.6.1.121.
- Currency في app_settings: EGP.
- Migration registry: 737 migrations.
- أحدث migrations: 20261103155029، 20261103155444، 20261103160902.

### 3.2 Edge Functions المنشورة

**CONFIRMED:**
- save-purchase-order: ACTIVE v22، verify_jwt=true، deployed SHA-256 a0885a8a636b0d57ef9ab54b476001be8e3dd1f4227b921f511b002f58642ffb.
- المصدر المنشور لـsave-purchase-order بطول 23,077 حرفًا مطابق حرفيًا لملف Git الحالي blob bc038be8c60a3d593f604c7b2ae445e807bacf57.
- receive-purchase: ACTIVE v13، verify_jwt=true، deployed SHA-256 50ab45ae026a0bb4d1de7837c872c4cc42da47b6a603f340e48d023d839310cc، بطول 4,140 حرفًا.
- لا يوجد ملف supabase/functions/receive-purchase/index.ts في المستودع التشغيلي.
- لقطة Current/Edge_Functions/receive-purchase في مستودع التوثيق blob 76b21329702a884b31ece74e3c535fa27e756b10 بطول 2,792 حرفًا، وليست مطابقة للمصدر المنشور؛ لا تحتوي على نفس فحوص get_my_effective_profile والدور والصلاحية الموجودة في v13 الحالية.
- لا يجوز نشر لقطة Current القديمة أو اعتبارها مصدرًا حاليًا. يجب استعادة v13 المنشورة حرفيًا إلى Git قبل أي توسيع، وبعد موافقة المالك.

### 3.3 RPC الاستلام

**CONFIRMED — Production + migration source:**
- receive_purchase_atomic الخماسي: (p_company_id uuid, p_po_code text, p_user_email text, p_items jsonb, p_operation_id uuid).
- SECURITY DEFINER، وEXECUTE ممنوح لـservice_role فقط؛ anon/authenticated لا يملكان EXECUTE.
- overload الرباعي القديم أيضًا service_role-only.
- الدالة تتحقق من الشركة، المستخدم النشط، الدور النشط «استلام» أو Owner، الصلاحيات الفعالة، والفرع المسموح.
- Edge v13 يتحقق من JWT وget_my_effective_profile ثم يستدعي RPC الخماسي.
- جسم الدالة في Production يطابق حرفيًا جسم migration 20261103155444 في Git.

### 3.4 خلل الاستلام الصفري

**CONFIRMED — Source contract:**
- Edge v13 يحوّل القيمة المفقودة/غير الصالحة إلى صفر، ويرفض الكمية السالبة فقط؛ الصفر يمر.
- RPC يرفض مصفوفة فارغة فقط.
- داخل حلقة التحقق والتسجيل يتجاوز كل بند received_qty <= 0.
- بعد ذلك ينشئ رأس receiving بحالة «مكتمل» حتى لو لم يتبق أي بند موجب.
- إذا كانت كل البنود صفرًا، لا تُنشأ تفاصيل ولا حركة PurchaseIn ولا قيد ولا supplier_ledger.
- مع ذلك تُحدّث حالة PO إلى Partially Received ما لم يكن مستلمًا بالكامل من قبل.

هذا خلل منطقي مؤكد في العقد الحالي. لم يُنفذ اختبار كتابة له في Production أو Staging.

### 3.5 الأثر المخزني والمحاسبي لاستلام PO

**CONFIRMED — عقد الدالة، لا إثبات عملية تشغيل:**
- رأس receiving وتفاصيله تُنشأ.
- purchase_order_details.qty_received يزيد تراكميًا.
- post_stock_movement ينفذ PurchaseIn للكمية المستلمة.
- ينشأ قيد مدين مخزون 124 / دائن موردين 211.
- يُضاف credit إلى supplier_ledger.
- PO تصبح Partially Received أو Received حسب الكمية التراكمية.
- يسجل audit_log حدث الاستلام.

هذه الآثار لا يجوز إعادة تنفيذها من مسار ترحيل الفاتورة؛ purchase_post_invoice_atomic للفاتورة المرتبطة بـPO يعيد status Posted بعد تحقق الاستلام والكميات والأسعار، ويصرح بأن المخزون والالتزام المالي تم تسجيلهما بواسطة PurchaseReceiving لتجنب التكرار.

### 3.6 غياب ربط فاتورة السوق بمحضر الاستلام

**CONFIRMED — Production schema:**
- receiving يحتوي po_number ولا يحتوي purchase_invoice_id أو source_type.
- receiving_details لا يحتوي purchase_invoice_detail_id.
- purchase_invoices لا يحتوي invoice_type أو source_type أو payment_method.
- purchase_invoice_details يحتوي received_qty، لكنه لا يرتبط بسجل receiving_details أو واقعة استلام بعينها.
- purchase_attachments يحتوي document_id وdocument_type وstorage_path، لكنه لا يحتوي document_line_id؛ والجدول حاليًا فارغ.
- لذلك لا توجد علاقة صريحة تثبت أن الكمية المقبولة في محضر معين تخص سطر فاتورة سوق بعينه.

### 3.7 RLS / GRANTS

**CONFIRMED — إصلاحات قائمة:**
- purchase_invoices وpurchase_invoice_details وpurchase_attachments: RLS ON؛ anon بلا SELECT/INSERT/UPDATE/DELETE؛ authenticated لديه SELECT فقط ولا يملك DML.
- هذا يثبت تطبيق central-writer boundary؛ لا تكرر migration 20261103155029.

**CONFIRMED — فجوات قراءة/صلاحيات:**
- purchase_orders وpurchase_order_details وpurchase_invoices وpurchase_invoice_details تستخدم سياسات SELECT على مستوى الشركة، لا على مستوى الفرع أو الإذن الوظيفي.
- Receiver لا يفلتر PO حسب الفرع، لذلك يستطيع مستخدم authenticated ضمن الشركة قراءة أوامر الشركة وفق سياسة RLS الحالية؛ RPC يمنع الاستلام خارج الفرع، لكنه لا يمنع ظهور السجل في القائمة.
- receiving وreceiving_details لديهما GRANTS DML لـanon وauthenticated، مع RLS ON وسياسات SELECT فقط دون سياسات DML. هذا لا يثبت أن الكتابة المباشرة ممكنة؛ RLS يفترض أن يمنعها، لكن GRANTS أوسع من اللازم ويستحق hardening منفصلًا.
- سياسة قراءة receiving تقارن responsible مع users.name، بينما receive_purchase_atomic يكتب responsible=p_user_email.
- سياسة RLS تستعمل current_user_has_permission التي تفحص users.permissions وroles.permissions، ولا تجمع role_permissions؛ بينما RPC الاستلام يجمع role_permissions أيضًا ويقبل receiving.
- لذلك قد ينجح Receiver في الاستلام عبر Edge/RPC ثم لا يستطيع قراءة سجله بنفسه إذا كان اعتماده على receiving فقط أو إذا لم تتطابق قيمة البريد مع الاسم. لا توجد receiving rows حاليًا؛ أثر القراءة الفعلي غير مختبر.

---

## 4. Migration Lineage — CONFLICT

**CONFIRMED:**
- Production migration registry يسجل 20261102150516 باسم buyer_invoice_draft_edit_delete_atomic_20261102.
- Production migration registry يسجل 20261102151137 باسم quick_invoice_post_requires_receipt_contract_20261102.
- operational Git filenames هما 20261102160000_buyer_invoice_draft_edit_delete_atomic.sql و20261102162000_quick_invoice_post_requires_receipt_contract.sql.
- أجسام purchase_update_draft_invoice_atomic وpurchase_delete_draft_invoice_atomic في Production تطابق حرفيًا ملف Git ذي prefix 20261102160000.
- جسم purchase_post_invoice_atomic في Production يطابق حرفيًا ملف Git ذي prefix 20261102162000.
- migrations 20261103155029 و20261103155444 و20261103160902 لها أسماء/إصدارات متوافقة بين registry وملفات Git الحالية.

**التصنيف:** CONFLICT في lineage/version naming، وليس اختلافًا مثبتًا في أجسام الدوال. لا تنفذ db push ولا تعِد ترقيم/إعادة تطبيق أي migration قبل مصالحة التاريخ.

---

## 5. Production Business Data — لقطة القراءة فقط

### 5.1 الأعداد الحالية

| الجدول | الصفوف |
|---|---:|
| purchase_orders | 1 |
| purchase_order_details | 1 |
| purchase_invoices | 3 |
| purchase_invoice_details | 6 |
| receiving / receiving_details | 0 / 0 |
| purchase_attachments | 0 |
| purchase_payments | 0 |
| buyer_custodies / advances / expenses / settlements / payments | 0 |
| stock_vouchers | 0 |
| purchase_document_links | 4 |
| inventory_log | 76 |
| supplier_ledger | 2 |
| journal_entries | 19 |

**لا يوجد PO بحالة Sent أو Partially Received في اللقطة الحالية؛ أمر الشراء الوحيد Draft، لذلك Receiver الحالي لا يملك PO تشغيلية ظاهرة وفق فلتره.**

### 5.2 فاتورتان تاريخيتان Posted بلا PO

**CONFIRMED — Production rows and linked effects:**

| الفاتورة | الحالة | العملة | PO | الفرع | الإجمالي | المدفوع |
|---|---|---|---|---|---:|---:|
| PINV-1000 | Posted | SAR | NULL | NULL | 2,640 | 0 |
| PINV-1001 | Posted | SAR | NULL | NULL | 1,330 | 0 |

- تاريخ الإنشاء والترحيل: 2026-09-24.
- كلتاهما is_received=true وreceived_date=2026-09-24.
- لا توجد لهما سجلات receiving أو purchase_attachments.
- PINV-1000 لها 3 حركات PurchaseIn بإجمالي 30 وحدة.
- PINV-1001 لها حركتا PurchaseIn بإجمالي 20 وحدة.
- supplier_ledger يحتوي credit بقيمة 2,640 و1,330؛ الرصيد الناتج 3,970.
- journal_entries يحتوي قيدين Posted متوازنين بقيمتي 2,640 و1,330.
- purchase_payments=0، وpaid_amount=0.

هذه سجلات تاريخية سبقت guard منع ترحيل الفاتورة غير المرتبطة بـPO. وجودها لا يثبت أن المسار الحالي يسمح بترحيل فاتورة سوق جديدة. لكنها آثار مخزنية ومحاسبية فعلية تحتاج مصالحة مع المالك/المحاسب؛ لا تُلغَ أو تُعكس تلقائيًا.

### 5.3 سجل QA غير متسق

**CONFIRMED — Production rows:**
- PO: QA-SR-PO-20260927، status=Draft، currency=EGP، total=375.
- PO detail: qty_ordered=5 وqty_received=5، unit_price=75.
- Invoice: QA-SR-INV-20260927، status=Draft، currency=SAR، purchase_order_id مرتبط بالـPO، total=375.
- الفاتورة is_received=true، لكن received_date=NULL.
- invoice detail received_qty=5.
- لا يوجد أي receiving أو receiving_details.
- لا توجد stock_vouchers حاليًا.
- توجد أربعة purchase_document_links من النوع stock_voucher إلى هذه الفاتورة والـPO، لكنها تشير إلى معرفي stock_voucher لا يوجد لهما صف في stock_vouchers حاليًا.
- جدول purchase_document_links لا يملك FK يضمن وجود source row في stock_vouchers.
- migration تاريخية في مستودع التوثيق تذكر أن cleanup تجريبيًا لـSupplierReturn نُفذ في Production، لكنها لا تربط هذين المعرفين صراحةً بعملية الحذف؛ سبب بقاء الروابط ومقصوديتها UNKNOWN.
- صنف QA-SR-ITEM-20260927 ما زال active ومخفيًا من المتجر؛ يظهر له رصيد 4 في فرع واحد ولا توجد له inventory_log rows في اللقطة المستعلم عنها. منشأ هذا الرصيد UNKNOWN.

هذه بيانات مرشحة لأن تكون QA، لكن بادئة QA ليست تفويضًا للحذف. لا تعدّل PO أو invoice أو روابطها أو رصيد الصنف دون مراجعة المالك ومصالحة السجل.

---

## 6. Staging — صلاحية الاختبار

**CONFIRMED — live project inspection:**
- rawaea-staging / hfzznsiprnwkpayskzhu: ACTIVE_HEALTHY.
- Migration count: 62.
- Public base tables: 70.
- من مجموعة الجداول الثمانية اللازمة لهذا المسار، الموجودان فقط receiving وreceiving_details.
- purchase_invoices وpurchase_invoice_details وجداول Buyer custody غير موجودة.

**النتيجة:** Staging الحالي غير صالح لاختبار Quick Market Invoice + Receiving + Custody كاملًا. لا تنشئ بيانات Production بديلًا عن بيئة الاختبار.

---

## 7. Deployment / Runtime

### 7.1 GitHub Cloudflare check runs

**CONFIRMED — GitHub check-run metadata:**
- HEAD 2b94681: Cloudflare Pages: rawaea-erp = failure، بدأ وانتهى 2026-11-03 19:16:47 UTC.
- Parent 5d7b10e: Cloudflare Pages: rawaea-erp = success، انتهى 2026-11-03 18:58:49 UTC.
- فشل منفصل ظهر أيضًا لمشاريع erp-frontend وrawaea-store وwarehouse-supervisor على HEAD الحالي.

هذه check-run statuses فقط؛ لا تثبت أي commit يقدمه Production حاليًا ولا سبب الفشل. تفاصيل Cloudflare dashboard لم تكن متاحة في جلسة الفحص.

### 7.2 Served artifact وRuntime

**UNVERIFIED:**
- لم تتوفر جلسة Browser صالحة لقراءة Buyer/Receiver أو Console/Network.
- محاولة جلب مسار Pages مباشرة لم توفر HTML المنشور.
- لم تتم قراءة response headers أو cache أو build artifact.
- لم يُنفذ Browser E2E أو HTTP authenticated E2E.
- لا يمكن إعلان أن HEAD الحالي منشور، ولا أن commit الأب هو artifact الحالي.

**قرار:** لا تُعامل GitHub commit أو نجاح check سابق على أنه إثبات نشر. يلزم فحص Cloudflare authorized session وقراءة artifact فعليًا.

---

## 8. Process Incident — مراجعة اختبار Production الوارد في Report608

**CONFIRMED — LOG EVIDENCE:**
- Supabase Postgres logs تعرض معاملتين في 2026-11-03 عند 20:22:38.942 UTC و20:27:59.930 UTC.
- كل معاملة تبدأ BEGIN، وتنشئ temporary table، وتستخدم SET LOCAL ROLE authenticated مع JWT claims، وتستدعي purchase_create_po_atomic بمفاتيح اختبار تبدأ buyer-daily-audit-20261103-2218-001 وbuyer-daily-audit-20261103-2218-005، ثم تنفذ ROLLBACK.
- لا توجد حاليًا purchase_orders بهذه operation_ids.
- لا توجد audit_log أو purchase_status_history rows لهذين المفتاحين.

**التفسير المنضبط:**
- تنفيذ استدعاءات كتابة داخل Production transaction ثم rollback مثبت من السجلات.
- عدم بقاء صفوف اختبارية مثبت بالاستعلامات الحالية.
- Report608 يصف الاختبار بأنه نُفذ دون موافقة مالك؛ لم أعثر في CURRENT_STATE على موافقة محددة له. لا أستطيع إثبات عدم وجود موافقة خارج سجل الحالة، لذلك أسجل عدم الموافقة كـreported/approval evidence not found، لا كحقيقة مستقلة مطلقة.
- ادعاء Report608 اللاحق بوجود probe أعاد المفتاح نفسه مع supplier مختلف لم أجد له سندًا في السجلين اللذين ظهرا؛ لا أعتمده كـCONFIRMED.

**الإجراء:** لم أنفذ أي كتابة أو rollback test في هذا التشغيل. جميع استعلامات Production التي نفذتها كانت SELECT/قراءة سجلات فقط. لا تكرر اختبارات الكتابة في Production.

---

## 9. مصفوفة التحقق

| الطبقة | النتيجة | التصنيف |
|---|---|---|
| GitHub/source | HEAD وBuyer/Receiver/Core والـmigrations ذات الصلة أعيد جلبها | CONFIRMED |
| Production schema/RPC/RLS/GRANTS | 737 migrations، عقود الفواتير والاستلام والصلاحيات والبيانات فُحصت | CONFIRMED |
| Edge deployment | save-purchase-order v22 byte-identical؛ receive-purchase v13 active لكن مصدره غير موجود في operational Git | CONFIRMED |
| Deployed HTML/JS artifact | لا يوجد readback مباشر أو headers/cache | UNVERIFIED |
| Runtime / Browser E2E | لم يُنفذ؛ لا توجد جلسة Browser صالحة | UNVERIFIED |
| Business-data effects | أثر الفاتورتين التاريخيتين مثبت؛ لا Receiving أو Custody rows حالية | CONFIRMED |
| QA data provenance | بعض الروابط والرصيد لا يمكن تفسير منشئها من الأدلة الحالية | UNKNOWN |
| Staging parity | غير كافٍ لاختبار B | CONFIRMED |
| Migration lineage | أجسام الدوال متطابقة، prefixes لا تطابق Production registry | CONFLICT |

---

## 10. ما تم فعليًا وما لم يتم

### ما تم فعليًا
1. قراءة CURRENT_STATE المرجعي وتثبيت LVE607 والهدف B قبل استخدام التقارير.
2. قراءة Master CTO Governance §§77.1–77.4.
3. إعادة جلب operational main وBuyer/Receiver/Core.
4. إعادة جلب Edge v22 وv13 من Production ومقارنة save-purchase-order حرفيًا مع Git.
5. مقارنة أجسام RPCs في Production مع migration files ذات الصلة.
6. فحص schema، RLS، GRANTS، policies، migrations، business data، inventory log، supplier ledger، journal entries، وPostgres logs.
7. إعادة التحقق من Staging وGitHub Cloudflare check runs.
8. إعداد هذا التقرير وتحديث نقطة الاستئناف والذاكرة في مستودع التوثيق فقط.

### ما لم يتم ولماذا
- لم أعدل Buyer أو Receiver أو Core أو Parent main.html: التغيير مؤثر ويحتاج Change Set محددًا وموافقة §77.2.
- لم أضف receive-purchase v13 إلى operational Git: يلزم عرض الإضافة الدقيقة وموافقة المالك، خصوصًا مع فشل Cloudflare check الحالي.
- لم أغير RPC أو schema أو RLS/GRANTS أو triggers أو migrations: Production read-only.
- لم أختبر الاستلام أو الفاتورة السريعة ببيانات حقيقية: لا توجد بيئة Staging مطابقة، وProduction ليس بيئة اختبار.
- لم أنفذ Browser/Network E2E: لا توجد جلسة متصفح صالحة.
- لم أصلح بيانات QA أو الفواتير التاريخية أو الروابط المستندية: تحتاج مصالحة واعتمادًا ولا يجوز افتراض أنها بيانات يمكن حذفها.

---

## 11. Change Set B — المطلوب عرضه قبل التنفيذ

### B1 — Source parity
- استعادة receive-purchase v13 المنشور حرفيًا إلى operational Git في المسار supabase/functions/receive-purchase/index.ts.
- تسجيل version=13 وverify_jwt=true وSHA-256 الحالي.
- عدم استخدام لقطة Current/Edge_Functions القديمة.
- عدم النشر بمجرد استعادة الملف.

### B2 — Receiver query and branch scope
- الاحتفاظ بـpurchase_orders.id وbranch_id في قائمة الأوامر.
- جلب التفاصيل بواسطة po_id.
- جلب qty_ordered وqty_received وحساب remaining_qty.
- فلترة القائمة حسب فروع المستخدم المسموح بها، مع بقاء RPC هو حاجز التفويض النهائي.
- معالجة res.error في list/details وإظهار خطأ حقيقي وتعطيل زر الاستلام عند فشل جلب التفاصيل.

### B3 — Quantity and receipt model
- Number/decimal بدل parseInt.
- قبول كمية موجبة فقط في واقعة الاستلام؛ رفض all-zero في Edge وRPC قبل إنشاء رأس receiving.
- عدم السماح بتجاوز remaining_qty.
- فصل accepted_qty عن rejected_qty، مع سبب الرفض/الفرق.
- اعتماد معنى qty_expected وdifference لكل شحنة قبل تعديل حساب الفرق.
- بصمة idempotency تشمل كل الحقول المادية ذات الأثر، لا item_code والكمية فقط.

### B4 — Idempotency per physical event
- إنشاء operation_id مستقل لكل واقعة استلام مادية.
- الاحتفاظ بالمفتاح نفسه عند إعادة محاولة نفس الواقعة.
- إنشاء مفتاح مختلف لواقعة جديدة حتى لو تطابقت الكميات.
- رفض إعادة استخدام المفتاح مع payload مختلف.
- لا تستخدم deterministic payload-only key كهوية دائمة للواقعة.

### B5 — Quick Market Invoice linkage
- إضافة علاقة صريحة من receiving إلى purchase_invoice، ومن receiving_details إلى purchase_invoice_detail، أو junction يدعم multiple/partial receipts.
- الحفاظ على PO receipt الحالي دون double posting.
- لا يُسمح بترحيل Quick Market Invoice قبل استلام فعلي معتمد.
- لا تُنشأ حركة مخزون إلا للكمية المقبولة.
- يجب فصل المعالجة المالية للمشتريات النقدية المدفوعة من عهدة المشتري عن المورد الآجل؛ لا تستخدم مسار Supplier AP/Payment الحالي تلقائيًا.
- تحديد إثبات دفع المورد، ومصدر النقد، وطريقة التسوية، والقيود المعتمدة قبل أي posting مالي.
- لا تخترع COA mapping أو GRNI/GRIR دون اعتماد Finance/Owner.

### B6 — Authorization and read policies
- الحفاظ على JWT/effective-profile/active-role/branch checks في Edge/RPC.
- حسم سياسة قراءة PO/Invoices: company-wide أم branch/permission scoped.
- تصحيح receiving responsible comparison أو توحيد التخزين/القراءة (email vs user.name).
- توحيد permission resolver مع role_permissions.
- مراجعة GRANTS الزائدة على receiving/receiving_details؛ لا تُجرِ revoke في Production قبل exact diff ومراجعة المستهلكين والrollback.

### B7 — Migration lineage
- مصالحة Production versions 20261102150516/20261102151137 مع Git filenames 20261102160000/20261102162000.
- أجسام الدوال متطابقة حاليًا؛ المطلوب توثيق أصل إعادة التسمية/الترقيم قبل أي migration push.
- لا global db push.

### B8 — Acceptance tests
لا يُقبل التنفيذ دون بيئة معزولة مكتملة واختبارات:
1. PO كامل وجزئي ومتعدد الشحنات.
2. كمية عشرية تحفظ دقتها.
3. all-zero مرفوض بلا receiving header أو status/stock/GL/AP delta.
4. over-receipt مرفوض.
5. accepted/rejected مع سبب ودليل.
6. same operation_id + same payload = duplicate واحد.
7. same operation_id + different payload = conflict.
8. two physical receipts identical quantities but different operation_id = two distinct receipts.
9. unauthorized role/branch/company denied.
10. invoice-linked quick receipt and partial receipt.
11. stock, supplier_ledger, journal, treasury, custody snapshots prove no duplicate or premature effect.
12. read-policy tests for Receiver/Finance/Audit and direct DML denial.
13. Parent/Buyer/Receiver regression and authenticated Browser E2E.
14. cleanup of all isolated fixtures with before/after snapshots.

---

## 12. الخطوة التالية الوحيدة ذات الأولوية

**إعداد Change Set B كاملًا للمراجعة والاعتماد، مع تضمين أخطاء Receiver الصفرية/idempotency/الفرع، وربط الفاتورة، وفجوات RLS/قراءة الاستلام، ومصالحة migration lineage، وتشخيص فشل Cloudflare check. لا تُجرِ أي تعديل في operational Git أو Production أو نشر قبل موافقة صريحة على هذا التغيير المحدد وفق Master CTO §77.2.**

**الحالة النهائية:** Buyer Workstream A محفوظ؛ Change Set B غير منفذ؛ Production لم يتغير في هذا التشغيل؛ سجل rollback السابق موثق؛ البيانات التاريخية لا تُلمس؛ artifact/runtime غير متحققين؛ النظام غير Production Ready.
