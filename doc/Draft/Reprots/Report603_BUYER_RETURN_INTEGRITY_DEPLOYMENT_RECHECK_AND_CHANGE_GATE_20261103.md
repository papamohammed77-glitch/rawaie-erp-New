# Report 603 — التحقيق الجنائي لسلامة مرتجعات المشتريات، حدود الصلاحيات، وإعادة مطابقة النشر — Buyer

**التاريخ:** 2026-11-03 — Africa/Cairo  
**الحالة:** OPEN / NOT PRODUCTION-READY  
**نقطة الاستكمال:** LVE-2026-11-03-602  
**النطاق:** Buyer + عقد مرتجعات المشتريات + بوابة الاستلام + عهدة المشتري + أدلة Supabase Production وCloudflare  
**المستودع التشغيلي:** papamohammed77-glitch/erp-frontend — main  
**مستودع التقارير والحالة:** papamohammed77-glitch/rawaie-erp-New — main

---

## الملخص التنفيذي

استُكمل التحقيق من آخر Checkpoint موثق، وأعيد فحص المصدر التشغيلي وقاعدة SMART ERP Production والـRPCs والمنح والسياسات والمحفزات ذات الصلة. لم يُعَد تنفيذ الضوابط التي ثبت أنها طُبقت بالفعل.

**أهم اكتشاف جديد:** دالة إنشاء مرتجع الشراء لا تحتسب كميات المرتجعات السابقة عند التحقق من الكمية المسموح بإرجاعها. وهي تسمح لكل عملية جديدة ذات Operation ID مختلف بإنشاء مرتجع يصل إلى كامل الكمية المستلمة الأصلية، حتى لو سبق إرجاع جزء منها أو كلها. ودالة الترحيل تنفذ حركة SupplierReturn وتخفض حساب المورد والمخزون لكل مرتجع منشأ. لا يوجد في جداول المرتجعات الحالية حقل accepted_qty أو قيد/Trigger يضمن الحد التراكمي أو حدث قبول المورد. هذا خلل عقدي مؤكد في المصدر وقاعدة الإنتاج، لكنه **لم يُستغل في بيانات Production وقت الفحص**؛ عدد المرتجعات حاليًا صفر.

**اكتشاف أمني مؤكد:** جدولَا purchase_returns وpurchase_return_details ما زالا يمنحان المستخدم المصادق عليه صلاحيات INSERT/UPDATE/DELETE مباشرة مع RLS من نوع ALL تتحقق من نطاق الشركة فقط، بينما بوابة save-purchase-order هي التي تفحص صلاحيات المشتريات والمالية. يستطيع مستخدم داخل الشركة، من حيث صلاحيات قاعدة البيانات، تجاوز فحص الصلاحية في البوابة والكتابة مباشرة على جداول المرتجعات. هذه الفجوة قائمة رغم أن عمليات إنشاء وترحيل المرتجع المركزية نفسها مقيدة إلى service_role.

**ما لم يتغير:** لم تُنفذ كتابة أو Migration أو تعديل RLS/ACL/RPC أو بيانات أو Edge أو نشر. لم تُنشأ بيانات اختبار في Production. سبب التوقف ليس عائقًا تقنيًا؛ بل قاعدة §77.2 الأحدث التي تمنع أي تغيير مؤثر قبل عرض نص التغيير الكامل وانتظار موافقة صريحة عليه. طلب تنفيذ المهمة لا يلغي هذه البوابة.

**الحكم:** لا يصح إغلاق Buyer ولا إعلان جاهزيته للإنتاج. تم إنجاز التحقيق والتوثيق وتجهيز Change Set P0-D؛ وما زالت حماية المرتجعات، منع تجاوز الكميات، قبول المورد الفعلي، عهدة بضاعة سيارة المشتريات، الشراء السوقي المستقل، واستكمال اختبارات E2E والنشر نقاطًا مفتوحة.

---

## 1. نقطة البداية وآخر حالة مثبتة

بدأت من أعلى CURRENT_STATE.md، وليس من تقرير تاريخي أو الذاكرة. كان أعلى checkpoint هو LVE-2026-11-03-602.

- CURRENT_STATE.md قبل هذا التقرير: blob SHA 18964899b45250a3bf92bec32d730b6457c1e199.
- Report602: doc/Draft/Reprots/Report602_BUYER_CURRENT_SOURCE_PRODUCTION_FORENSIC_AND_CHANGESET_20261103.md، blob SHA af43e480f35c72fbc5093a6607c36b4ea16747eb.
- Report589 يثبت مبدأ الفصل بين الحالة التشغيلية والمستندية والواقعة المالية والواقعة المخزنية.
- الدستور الدائم: doc/Draft/Reprots/الدستور التشغيلي الدائم.md.
- Master CTO: doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md، blob SHA 1a0c81c2984103b5a7f3b40db41607d74051b310.

**LAST VERIFIED EVENT السابق:** إعادة جلب HEAD وParent ومصادر Buyer/Core/Receiver، والتحقق من Edge والإصدارات والـRPCs والمنح وRLS والمخطط والبيانات. كانت ضوابط كتابة فواتير الشراء، اعتماد استلام PO، وإقرار الموظف قبل صرف العهدة مثبتة. بقيت صلاحيات DML على جدولي المرتجعات، كما بقيت فجوات دورة الحيازة والقبول والشراء السوقي.

## 2. مصادر الإثبات الحالية

### 2.1 GitHub — المستودع التشغيلي

| العنصر | القيمة المثبتة |
|---|---|
| Repository / Branch | papamohammed77-glitch/erp-frontend / main |
| HEAD | 743c9b170bf2314a9e4d64fd4d8104f2cc1aee8c |
| Parent | 2ce93c6d80ec4c38353bdf88880d06ae9e0abdde |
| Buyer | companies/company-1/purchasing/buyer.html — blob aee14e6a4edbccd5fb95dff24f21daf1c6d21fcc |
| Core | companies/company-1/core.js — blob f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1 |
| Receiver | companies/company-1/warehouse/receiver.html — blob 3111b5e801d1bc021cf18fd66d633fbdc54ac0d6 |

تاريخ HEAD وParent يؤكد أن آخر حركة Git كانت مواءمة اسم Migration العهدة مع اسم الإصدار المسجل في Production ثم إزالة اسم Migration غير المطابق؛ لا يوجد في هذه الحركة إصلاح لدورة قبول المورد أو منع تجاوز كميات المرتجعات.

روابط الإثبات:
- [Buyer الحالي](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/purchasing/buyer.html)
- [Commit HEAD](https://github.com/papamohammed77-glitch/erp-frontend/commit/743c9b170bf2314a9e4d64fd4d8104f2cc1aee8c)
- [Commit Parent](https://github.com/papamohammed77-glitch/erp-frontend/commit/2ce93c6d80ec4c38353bdf88880d06ae9e0abdde)

### 2.2 Supabase Production

- المشروع: SMART ERP — fiilmooggumokxanwiyx.
- قاعدة Production وحالة المشروع: ACTIVE_HEALTHY، PostgreSQL 17.6.1.121.
- عدد الـMigrations المسجلة وقت الفحص: 737.
- العملة المقروءة من إعدادات الشركة: EGP.
- لا يوجد Supabase Development Branch معزول متاح للاختبار في Snapshot الفحص.

آخر Migrations ذات صلة:
- 20261103155029 — buyer_invoice_tables_central_writer_only_20261103.
- 20261103155444 — receive_purchase_role_and_branch_authorization_20261103.
- 20261103160902 — buyer_custody_cash_disbursement_requires_employee_ack_20261103.

Edge Functions الحالية:
- save-purchase-order — v22، ACTIVE، verify_jwt=true.
- receive-purchase — v13، ACTIVE، verify_jwt=true.
- لم تُنشأ Edge Function جديدة.

### 2.3 Cloudflare / Deployment

لقطة لوحة Cloudflare المتاحة في المتصفح أظهرت Production على rawaea-erp.pages.dev مع Automatic Deployments مفعلة، وكان الإصدار الظاهر وقت اللقطة مربوطًا بـCommit 7a14d51b4d4c225240b215879abf6b77b99888d3 (LVE-587). هذه اللقطة أقدم من HEAD الحالي 743c9b...؛ لذلك لا يجوز استخدامها لإثبات أن النشر الحالي ما زال على ذلك الإصدار أو أنه انتقل إلى HEAD الأحدث.

لم تتوفر في وضع القراءة الحالي وسيلة لتحديث لوحة Cloudflare أو فتح تفاصيل نشر حديثة أو فحص الـArtifact الفعلي والـheaders. وعليه:
- آخر لقطة Production المعروضة: CONFIRMED بتاريخ/وقت فتح التبويب 2026-11-03 نحو 15:45 بتوقيت القاهرة.
- نشر HEAD الحالي: UNKNOWN.
- تطابق Buyer المنشور مع blob الحالي: UNVERIFIED.
- لا يُستنتج من ظهور Production في لوحة Cloudflare أن سلوك Buyer داخل التطبيق سليم.

### 2.4 Runtime

التبويب المفتوح للتطبيق يعرض صفحة النظام الأم ونموذج تسجيل الدخول. لم تتوفر جلسة Buyer مصادق عليها أو أدوات تفاعل/تنقل Browser في وضع القراءة الحالي؛ لذلك لم ينفذ اختبار Buyer E2E أو اختبار Console/Network. لا يصح الادعاء بأن دورة فعلية تمت بنجاح.

---

## 3. CONFIRMED — النتائج المثبتة

### 3.1 حماية فواتير الشراء السابقة سليمة ولا تعاد

أثبتت قاعدة Production أن purchase_invoices وpurchase_invoice_details لهما RLS مفعّل، وقراءة authenticated، ولا توجد لهما صلاحيات INSERT/UPDATE/DELETE مباشرة من authenticated أو anon. الكتابة تمر عبر العقد المركزي، وهو ما يتوافق مع Migration 20261103155029.

**القرار:** لا تكرر هذا الإصلاح ولا تعدّل تلك الجداول دون دليل جديد.

### 3.2 صلاحية استقبال PO سبق إغلاقها

Edge receive-purchase v13 نشطة، ومسارها الحالي مرتبط بالتحقق من المستخدم والدور والفرع. سجل المستودع يحتوي Migration 20261103155444 الخاصة بتقييد الاستلام. Receiver الحالي يستدعي عملية receive-purchase عبر RW_API.

**القرار:** لا تنشئ Edge جديدة ولا تعد ضبط هذا القفل. هذا لا يعني أن E2E للاستلام في الجلسة الحالية قد اختُبر.

### 3.3 صرف العهدة النقدية ينتظر إقرار صاحب العهدة

الدالة المركزية الحالية لا تعتبر إصدار طلب العهدة تسليمًا نقديًا نهائيًا. القيد النقدي والمحاسبي يقع بعد ACKNOWLEDGE_CUSTODY من المستخدم المصادق عليه الذي يطابق الموظف صاحب العهدة. وتوجد حماية من إقرار مستخدم آخر، كما يدعم المسار منع ازدواج الحركة.

لكن نص Buyer في السطرين 870 و880 لا يزال يوحي بأن الخزينة والقيد تم تحديثهما عند إصدار العهدة؛ وهذه مخالفة وصفية للعقد الحقيقي، وليست خطأ في RPC نفسه.

### 3.4 صلاحيات جدولي المرتجعات أوسع من الكاتب المركزي

الاستعلام المباشر على صلاحيات Production أظهر:

| الجدول | RLS | anon | authenticated |
|---|---|---|---|
| purchase_returns | ON / not FORCE | SELECT/INSERT | SELECT/INSERT/UPDATE/DELETE |
| purchase_return_details | ON / not FORCE | SELECT/INSERT | SELECT/INSERT/UPDATE/DELETE |

وسياسات الجدولين الحالية من نوع ALL إلى PUBLIC، وتتحقق من current_user_company_id ونطاق الشركة، لكنها لا تتحقق من صلاحيات المشتريات أو المالية.

في المقابل:
- purchase_create_return_atomic وpurchase_post_return_atomic لا تسمحان بتنفيذ مباشر من authenticated أو anon؛ منفذ RPC المتاح هو service_role.
- Edge save-purchase-order يفحص الملف الفعال وصلاحيات المستخدم قبل التوجيه إلى RPC.
- POST_RETURN في Edge يتطلب purchases + finance.
- CREATE_RETURN يتطلب purchases.

**النتيجة:** المستخدم المصادق عليه داخل الشركة يستطيع من ناحية DB privileges إجراء DML مباشر على جدولي المرتجعات خارج فحص صلاحية Edge. فحص RLS الحالي يحد نطاق الشركة ولا يقوم مقام RBAC. لم أثبت أن anon يستطيع عبور شرط الشركة عمليًا؛ صلاحيات المنح موجودة لكن الاستغلال المجهول نفسه UNVERIFIED.

### 3.5 خلل تراكمي في حد كمية المرتجع — مؤكد من عقد Production

التوقيع الحالي:

purchase_create_return_atomic(p_company_id uuid, p_invoice_id uuid, p_created_by text, p_reason text, p_items jsonb, p_operation_id text)

المنطق الفعلي:
1. يتحقق من وجود operation_id ويعيد النتيجة عند تكرار نفس operation_id.
2. يقفل فاتورة الشراء ويقفل سطر الفاتورة.
3. يرفض إذا كانت كمية السطر المطلوبة غير موجبة أو أكبر من purchase_invoice_details.received_qty.
4. ينشئ سطور المرتجع ويحسب الإجمالي.

**النقص:** لا يحسب الكمية التي سبق إدراجها في purchase_return_details على الفاتورة/سطر الصنف، ولا يطرح المرتجعات السابقة Draft/Posted من received_qty قبل السماح بإنشاء مرتجع جديد. Idempotency يمنع إعادة العملية نفسها بالمفتاح نفسه، لكنه لا يمنع إنشاء عملية جديدة بمفتاح مختلف للكمية نفسها.

دالة purchase_post_return_atomic(p_company_id uuid,p_return_id uuid,p_actor text):
- تقبل المستند Draft.
- تنفذ post_stock_movement بالحركة SupplierReturn لكل سطر.
- تنشئ قيدًا يخصم من Supplier AP account 211 ويقابل Inventory account 124.
- تسجل debit في supplier_ledger وتضع المستند Posted.
- لا تحتوي على حدث قبول فعلي من المورد أو كميات مقبولة جزئيًا لكل سطر.

**الأثر الممكن:** إنشاء مرتجعين بمفتاحي تشغيل مختلفين، كل منهما لا يتجاوز received_qty وحده، قد يؤدي إلى ترحيل مجموع كميات أكبر من المستلم فعليًا؛ وبالتالي حركة مخزون خارجة زائدة وتخفيض زائد في مستحق المورد. كما أن مجرد ترحيل المستند الحالي لا يثبت تسليم البضاعة للمورد وقبوله لها.

**فحص القيود والمحفزات:** لا توجد أعمدة returned_qty/accepted_qty في مصدر الحقيقة الحالي. قيود purchase_return_details تقتصر على PK/FK وqty > 0 وunit_price >= 0. ومحفزات purchase_returns الحالية هي سجل تاريخ الحالة وتحديث updated_at فقط؛ لا يوجد Trigger تراكمي على تفاصيل المرتجع أو قيد يحدد مجموع المرتجع مقابل received_qty.

**Business impact:** صفر بيانات مرتجعات فعلية في Snapshot Production؛ الخلل في العقد وليس هناك دليل على وقوع خسارة/تجاوز تاريخي. الاختبار العملي له في Production ممنوع، ولم يتم.

### 3.6 لا يوجد عقد لقبول المورد أو التسليم الجزئي للمرتجع

مخطط purchase_returns لا يحتوي على supplier_accepted_at أو supplier_accepted_by أو حالة قبول/رفض أو رقم إثبات التسليم. تفاصيل المرتجع لا تحتوي accepted_qty أو rejected_qty أو حالة جزئية. دالة POST_RETURN تنفذ حركة المخزون والتخفيض المحاسبي عند الترحيل مباشرة.

هذا لا يحقق سياسة المالك التي تفصل خروج المرتجع من المخزن إلى عهدة المشتري/السيارة عن قبول المورد لها، ولا تسمح بخصم حساب المورد إلا عند قبول الكمية فعليًا، أو قبول جزء ورفض جزء.

### 3.7 Buyer Quick Purchase ليس عملية شراء سوقية مستقلة

في Buyer:
- quickPurchase عند السطر 762 مجرد alias إلى createPurchaseInvoice.
- توجد إمكانية إنشاء مسودة فاتورة دون PO، لكن إنشاء المسودة لا يثبت استلامًا ولا يسمح وحده بترحيل فاتورة بلا دليل الاستلام المعتمد.
- Receiver الحالي PO-only: يعرض أوامر Sent / Partially Received ويستدعي receive-purchase برقم PO؛ لا يظهر مسار استلام سوقي مستقل بلا PO.

إذن اسم Quick Purchase لا يعني أن دورة الشراء النقدي/السوقي مكتملة.

### 3.8 عهدة بضاعة سيارة المشتريات ليست مبنية

Buyer renderVehicleBalance عند السطور 617–628:
- يقرأ fleet_vehicle_assignments وvehicles ويحدد المركبة عبر driver_user_id.
- يعرض صراحة أن دفتر عهدة بضاعة المشتريات غير مفعّل.
- لا يوجد في Production المخطط المفحوص كيان يربط تسليم المورد للمشتري ثم تسليم المشتري للمخزن، أو صرف المخزن للمرتجع ثم تسليمه للمورد.
- تعيين Fleet للمركبة لا يثبت تحميل صنف أو استلامه ماديًا.

لا يجوز استخدام مخزون سيارات التوصيل أو Fleet Assignment كبديل عن دفتر عهدة مشتريات.

### 3.9 عهدة النقد الحالية خاصة بمشتريات الموردين وليست دفتر مصروفات عام

submitCustodyExpense في Buyer يفرض فاتورة شراء Draft مرتبطة بأمر PO ومورد، وإذن استلام مخزني مكتمل، وملفي إثبات. دالة submit_expense في Production تحقق نفس العقد. دالة review_expense عند الموافقة تسجل settlement لمورد بعينه وتحدث purchase invoice إلى Paid وتعدل supplier_ledger، مع القيود المناسبة.

لكن مخطط buyer_custody_expenses لا يحتوي expense_type أو expense_category أو cost_account أو payee_kind. لذلك الوقود والنقل والمصروفات المتنوعة غير مغطاة كأنواع مستقلة، ولا يصح إدخالها في مسار Supplier AP لمجرد أنها خرجت من عهدة المشتري.

كما أن buyer_custody_settlements يحتوي مبلغ النقد المرتجع ومرجعًا وملاحظات وروابط خزينة/قيد، لكنه لا يملك حقول مستندات إثبات مستقلّة مخصصة لإيصال استلام النقد المرتجع. هذا Gap تصميمي يحتاج تحديد دليل مقبول قبل تعديله.

### 3.10 بيانات Production وقت الفحص

| المصدر | عدد السجلات |
|---|---:|
| purchase_invoices | 3 |
| purchase_returns | 0 |
| purchase_return_details | 0 |
| buyer_custodies | 0 |
| buyer_custody_advances | 0 |
| buyer_custody_expenses | 0 |
| buyer_custody_payments | 0 |
| buyer_custody_settlements | 0 |
| receiving | 0 |
| fleet_vehicle_assignments | 0 |
| vehicles | 2 |
| stock_vouchers | 0 |
| inventory_log | 76 |
| supplier_ledger | 2 |
| journal_entries | 19 |
| cash_box | 8 |

لم تُدرج أي سجلات تجريبية في Production، ولم تتغير هذه الأرصدة نتيجة هذه المهمة.

---

## 4. UNKNOWN

1. المستهلكون الخارجيون لجدولي المرتجعات خارج شجرة company-1، بما في ذلك أي تكاملات أو مستودعات/تطبيقات أخرى، لم يثبت استنفادها جميعًا. تقرير602 سجل فحص 34 ملفًا من HTML/JS داخل شجرة الشركة وعدم وجود DML مباشر في الملفات المفحوصة، لكن هذا لا يغطي جميع المستودعات أو التكاملات.
2. ما إذا كان Cloudflare قد نشر HEAD 743c9b... بعد لقطة لوحة التحكم القديمة غير معلوم.
3. لا توجد أدلة تشغيلية في هذه الجلسة على تسليم مرتجع إلى مورد أو قبول مورد له أو تسوية سيارة مشتريات.
4. لا يمكن الجزم بكيفية تعامل جميع السيناريوهات المحاسبية لمرتجعات فاتورة مدفوعة أو مرتجع غير متعلق بفاتورة دون مراجعة سياسة Credit Note/Refund المعتمدة ومصادر الحسابات والضرائب كاملة.
5. لا يمكن تحديد تصنيف مصروفات المشتريات وتعيين حساباتها دون اعتماد الإدارة المالية لجدول الحسابات وسياسة المصروفات.

## 5. CONFLICT

- هناك تعارض بين واجهة Buyer التي تفيد بأن صرف العهدة أثر بالفعل في الخزينة والقيود بمجرد الإصدار، وبين عقد Production الحالي الذي يؤجل الأثر إلى ACKNOWLEDGE_CUSTODY. الحقيقة التنفيذية المثبتة هي عقد Production؛ النص الموجود في الواجهة قديم ويحتاج تصحيحًا من المالك.
- لقطة Cloudflare القديمة تظهر Commit 7a14d51...، بينما مصدر Git الحالي عند 743c9b... أحدث. لا يوجد دليل مباشر أحدث لحسم Artifact الحالي؛ لذا لا تُصنّف الحالة كتعارض حالي محسوم، بل Deployment Head = UNKNOWN لحين إعادة فحص حديثة.

## 6. UNVERIFIED

- صلاحية anon الفعلية لاجتياز RLS عمليًا.
- قابلية تنفيذ تجاوز الكمية تفاعليًا عبر جلسة Buyer؛ الخلل مثبت من تعريف الدالة/المخطط، لكن لم ينفذ E2E.
- تطابق Artifact المنشور حاليًا مع Buyer blob الحالي.
- Buyer Browser authenticated E2E، وConsole/Network.
- أثر أي عملية استلام/مرتجع على stock_branches وinventory_log وsupplier_ledger وjournal_entries وcash_box؛ لم يتم إجراء معاملات اختبار.
- سلسلة قبول المورد المادي غير مطبقة أو مجربة.
- اختبارات regression مع Parent وReceiver وWarehouse vouchers وSales/Delivery/Finance لم تنفذ.

---

## 7. مصفوفة التحقق الإلزامية

| الطبقة | الحالة | الدليل / الحد |
|---|---|---|
| GitHub / source | CONFIRMED | HEAD/Parent وBuyer/Core/Receiver والوظائف ذات الصلة أعيد جلبها مباشرة |
| Supabase Production | CONFIRMED | migration ledger، Edge versions، جدول الأعمدة والقيود والمحفزات والمنح والسياسات وتعريفات RPC والـcounts |
| Deployed artifact | UNKNOWN / UNVERIFIED | آخر لقطة Cloudflare أقدم من HEAD؛ لم تثبت نسخة الـArtifact الحالية |
| Runtime / E2E | UNVERIFIED | لا جلسة Buyer مصادق عليها أو browser interaction لإتمام اختبار الدورة |
| Business-data effects | Baseline CONFIRMED / test effects UNVERIFIED | لا سجلات مرتجعات أو عهدة، ولم يحدث أي تحديث لأرصدة Production |

لا يُستخدم نجاح استعلام SQL أو وجود كود في Git كبديل لاختبار مسار الأعمال الفعلي.

---

## 8. Change Set P0-D — تضييق صلاحيات الكتابة على جداول المرتجعات

**الهدف:** جعل إنشاء/تعديل/ترحيل/إلغاء Purchase Return يمر عبر البوابة المركزية التي تتحقق من الدور والصلاحية، مع إبقاء القراءة للمستخدم المصادق عليه ضمن الشركة، والحفاظ على Service Role الحالي.

**الأدلة:** المنح الحالية تمنح anon وauthenticated DML على الجدولين، وسياسة ALL لا تتحقق إلا من نطاق الشركة. والـRPC المركزي service_role-only.

### 8.1 SQL المقترح للمراجعة — لم يُنفذ

```
BEGIN;

REVOKE ALL PRIVILEGES
ON TABLE public.purchase_returns, public.purchase_return_details
FROM PUBLIC, anon, authenticated;

GRANT SELECT
ON TABLE public.purchase_returns, public.purchase_return_details
TO authenticated;

DROP POLICY IF EXISTS purchase_returns_company
ON public.purchase_returns;

CREATE POLICY purchase_returns_company
ON public.purchase_returns
FOR SELECT
TO authenticated
USING (company_id = app_private.current_user_company_id());

DROP POLICY IF EXISTS purchase_return_details_company
ON public.purchase_return_details;

CREATE POLICY purchase_return_details_company
ON public.purchase_return_details
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.purchase_returns r
    WHERE r.id = purchase_return_details.return_id
      AND r.company_id = app_private.current_user_company_id()
  )
);

COMMIT;
```

### 8.2 Preflight قبل التنفيذ

1. إعادة تصوير grants وpolicies الفعلية، بما في ذلك PUBLIC وanon وauthenticated وservice_role.
2. إثبات أن كل مستهلك يحتاج الكتابة يستخدم save-purchase-order v22 ولا يكتب مباشرة.
3. فحص أي تطبيق أو تقرير أو تكامل خارج شجرة company-1.
4. Snapshot لتعريف السياسات والمنح الحالية.
5. إثبات أن Parent/Buyer/Receiver/warehouse/vouchers يمكنها القراءة بعد التغيير.
6. التأكد من أن الكاتب service_role لم تتغير صلاحياته.

### 8.3 Rollback المقترح — لا يستخدم قبل مقارنة Snapshot

```
BEGIN;

DROP POLICY IF EXISTS purchase_returns_company
ON public.purchase_returns;

CREATE POLICY purchase_returns_company
ON public.purchase_returns
FOR ALL
TO public
USING (company_id = app_private.current_user_company_id())
WITH CHECK (company_id = app_private.current_user_company_id());

DROP POLICY IF EXISTS purchase_return_details_company
ON public.purchase_return_details;

CREATE POLICY purchase_return_details_company
ON public.purchase_return_details
FOR ALL
TO public
USING (
  EXISTS (
    SELECT 1
    FROM public.purchase_returns r
    WHERE r.id = purchase_return_details.return_id
      AND r.company_id = app_private.current_user_company_id()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.purchase_returns r
    WHERE r.id = purchase_return_details.return_id
      AND r.company_id = app_private.current_user_company_id()
  )
);

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, UPDATE
ON TABLE public.purchase_returns, public.purchase_return_details
TO anon, authenticated;

COMMIT;
```

هذا Rollback يعكس المنح والسياسات المعروفة في Snapshot السابق، ولا ينفذ حرفيًا إذا أثبت Preflight اختلافًا في المنح أو السياسات. عندئذ يُعاد بناء Rollback من Snapshot الفعلي.

### 8.4 Acceptance بعد الموافقة والتنفيذ

- anon: لا قراءة ولا DML.
- authenticated: SELECT ضمن الشركة الحالية فقط.
- authenticated: INSERT/UPDATE/DELETE/TRIGGER/REFERENCES مرفوضة مباشرة.
- service_role: يحتفظ بمنح الكتابة التي يحتاجها.
- CREATE_RETURN وPOST_RETURN وCANCEL_DOCUMENT تستمر عبر البوابة المركزية مع إعادة المحاولة بنفس operation_id.
- أي فشل لا يغير stock_branches أو inventory_log أو supplier_ledger أو journal_entries أو cash_box.
- اختبار مستخدم بلا صلاحية، شركة أخرى، فرع آخر، وقراءات Parent/Buyer/Receiver.

**STATUS:** READY FOR OWNER REVIEW — NOT APPLIED. يلزم اعتماد صريح لهذا SQL بعينه وفق Master CTO §77.2.

---

## 9. Change Set مستقل P0-R — منع تجاوز الكمية التراكمية وقبول المورد

لا يكفي تضييق ACL وحده لإغلاق خطر الكمية؛ فحتى لو أُجبر الجميع على استخدام Edge، ستظل دالة إنشاء المرتجع الحالية تسمح بتجاوز إجمالي الكمية عبر operation_id مختلفة.

**العقد المطلوب قبل صياغة Migration:**

1. ربط كل سطر مرتجع بسطر فاتورة الشراء الأصلي، وليس item_code وحده عند وجود احتمال تكرار SKU أو أكثر من دفعة/سعر.
2. حساب الكمية القابلة للإرجاع من الكمية التي استلمها المخزن فعليًا، مطروحًا منها كل الكميات المرتجعة ذات الحالة المؤهلة حسب السياسة.
3. قفل سطر الفاتورة الأصلي أو مفتاح تجميعي مناسب بما يضمن serialization تحت التزامن. يجب احتساب Draft المفتوحة وPosted والملغاة والمرفوضة وفق قواعد حالة معلنة، وألا تتحول حالة مسودة إلى حجز دائم دون سياسة انتهاء/إلغاء.
4. الفصل بين:
   - إنشاء طلب المرتجع.
   - صرفه ماديًا من المخزن إلى عهدة المشتري/مركبة المشتريات.
   - التسليم الفعلي للمورد.
   - الكمية المقبولة لدى المورد.
   - الكمية المرفوضة وإعادتها للمخزن.
   - أثر المورد والمخزون والقيد المالي بعد قبول المورد فقط.
5. تسجيل accepted_qty وrejected_qty ومصدر/وقت/منفذ إثبات القبول، مرجع المورد، والمرفقات، وoperation_id لكل انتقال.
6. السماح بالقبول الجزئي؛ لا يخصم حساب المورد ولا ينفذ SupplierReturn stock movement إلا للكمية التي ثبت قبول المورد لها، وبطريقة لا تسبب ازدواج ترحيل.
7. ربط الدائن/الإشعار المحاسبي بفاتورة المورد الأصلية والضرائب والخصم وتكلفة المخزون وطريقة التقييم. يجب تحديد معالجة المرتجع بعد سداد الفاتورة، وهل الاسترداد النقدي حدث مستقل عن خصم AP.
8. جعل إلغاء/عكس الحركة المنشورة عكسيًا ومدققًا، لا حذفًا مباشرًا أو تعديل كمية حركة قديمة.
9. اختبارات تزامن لعمليتين تحملان operation_id مختلفين على السطر نفسه، واختبارات retry للمفتاح نفسه، وقبول جزئي/رفض وإعادة للمخزن.

**ملاحظة محاسبية:** دالة الترحيل الحالية تربط Supplier AP بالحساب 211 وInventory بالحساب 124. لا يجوز تغيير الحسابات أو إنشاء قيد بديل قبل فحص سياسات الضريبة والتكلفة وحالة فاتورة المورد والدفتر العام. كما يجب منع أي حركة مخزنية مزدوجة بين استلام المخزن وقبول المورد.

**STATUS:** CONFIRMED GAP / DESIGN AND SQL NOT YET APPROVED. لا توجد Migration جاهزة للتطبيق في هذا التقرير؛ لأن علاجها يتطلب إقرار دورة قبول المورد وسياسة قيود المرتجع الجزئي، وليس إضافة عمود دون عقد متكامل.

---

## 10. Owner Change Set — تصحيحات Buyer الجراحية

التعديل التالي يخص وصف الواجهة ورسالة نجاحها وإضافة تأكيد صريح عند إقرار استلام النقد. لا أعدل Buyer HTML مباشرة؛ الدستور يجعل تعديلات التطبيقات المنشورة مسؤولية المالك.

**FILE:** companies/company-1/purchasing/buyer.html  
**CURRENT SHA:** aee14e6a4edbccd5fb95dff24f21daf1c6d21fcc

### 10.1 تصحيح نص إصدار العهدة — السطر 870

**ابحث داخل الدالة issueCustody عن النص الكامل التالي واحذفه:**

```
'<p class="text-xs text-amber-700">يجب أن تكون النقدية قد سُلّمت فعليًا. سيُسجل النظام سند صرف من الخزينة إلى حساب عهد الموظفين ويُحدّث رصيد الخزينة والقيد العام.</p></div>';
```

**واستبدله كاملًا بالنص التالي:**

```
'<p class="text-xs text-amber-700">سيُسجل الآن طلب تسليم العهدة فقط. لن تتغير الخزينة أو القيود المحاسبية إلا بعد أن يؤكد الموظف صاحب العهدة استلام النقدية فعليًا من حسابه المصادق عليه.</p></div>';
```

### 10.2 تصحيح رسالة النجاح — السطر 880

**ابحث عن السطر التالي داخل الدالة issueCustody واحذفه:**

```
if(result.isConfirmed){this.invalidate();await this.renderCustody();RW_UI.toast('تم تسجيل تسليم العهدة وربطه بالخزينة والحسابات','success');}
```

**واستبدله بالسطر التالي كاملًا:**

```
if(result.isConfirmed){this.invalidate();await this.renderCustody();RW_UI.toast('تم تسجيل طلب تسليم العهدة وبانتظار إقرار الموظف بالاستلام الفعلي','success');}
```

### 10.3 استبدال acknowledgeCustody كاملًا — الأسطر 907–910

**ابحث عن العنصر الكامل التالي داخل كائن App واحذفه:**

```
acknowledgeCustody:async function(id){
    try{await this.api('ACKNOWLEDGE_CUSTODY',{custody_id:id});this.invalidate();await this.renderCustody();RW_UI.toast('تم تأكيد استلام العهدة','success');}
    catch(e){this.notifyError(e);}
},
```

**واستبدله بالعنصر الكامل التالي:**

```
acknowledgeCustody:async function(id){
    var ok=await Swal.fire({
        title:'تأكيد استلام العهدة النقدية',
        text:'هل استلمت مبلغ العهدة المذكور فعليًا يدًا بيد؟ لن تُثبت حركة الخزينة والقيد العام إلا بعد هذا الإقرار.',
        icon:'question',
        showCancelButton:true,
        confirmButtonText:'نعم، استلمت المبلغ فعليًا',
        cancelButtonText:'إلغاء'
    });
    if(!ok.isConfirmed)return;
    try{
        await this.api('ACKNOWLEDGE_CUSTODY',{custody_id:id});
        this.invalidate();
        await this.renderCustody();
        RW_UI.toast('تم تأكيد استلام العهدة وتسجيل أثرها النقدي والمحاسبي','success');
    }catch(e){
        this.notifyError(e);
    }
},
```

**لماذا؟** لأن RPC الحالي ينتظر إقرار الموظف الصحيح قبل تسجيل الحركة النقدية والمحاسبية؛ والنص الحالي يوحي بأن الصرف تم عند إصدار الطلب. كما أن الزر الحالي ينفذ الإقرار دون نافذة تحقق من الواقعة المادية.

**Dependencies:** Swal موجودة مستخدمة في Buyer؛ API operation ACKNOWLEDGE_CUSTODY موجود بالفعل؛ لا تغيير في اسم RPC أو تواقيعه أو SQL.

**Expected result:** إصدار العهدة يظل Pending بلا أثر نقدي، والإقرار يطلب تأكيدًا واضحًا ثم ينفذ العقد المركزي الحالي. لا يُسمح لمستخدم غير صاحب العهدة بإتمام الإقرار لأن قاعدة Production هي التي تتحقق من ذلك.

**Verification بعد تطبيق المالك:** موظف العهدة نفسه مع إقرار فعلي؛ مستخدم آخر؛ إلغاء التأكيد؛ retry؛ مطابقة custody/advance/cash_box/journal_entries. هذه التصحيحات لم تُطبق ولم تُختبر في Runtime بعد.

---

## 11. التصميم الوظيفي المقترح لإغلاق الفجوات التالية

هذا تصميم عمل للمراجعة، وليس تصريحًا بتغيير المخطط.

### 11.1 Quick Market Purchase — شراء مباشر من السوق بلا PO

ينبغي الفصل بين:
- فاتورة المورد التقليدية.
- شراء مباشر من بائع سوق/Payee قد لا يكون موردًا مسجلًا.
- إثبات استلام المستودع للكمية المادية.
- الدفع الفعلي من العهدة أو الخزينة.
- تسوية المصروف أو فاتورة المورد لاحقًا.

الحقول المرشحة: نوع الطرف Supplier/MarketSeller، اسم/هوية Payee، مرجع فاتورة أو إيصال السوق، التاريخ، الفرع والمخزن، الصنف والوحدة والكمية والسعر والخصم والضريبة، حالة الفحص، المقبول/المرفوض/التالف، طريقة الدفع، مرجع الدفع الفعلي، صور الفاتورة ومحضر الاستلام، المشتري والمركبة، operation_id.

لا تنشئ PO وهميًا لإجبار المشتريات السوقية على المرور بعقد المورد. ولا ترفع المخزون بمجرد إدخال الفاتورة أو طلب المصروف؛ المخزون يزداد عند حدث استلام فعلي مقبول واحد فقط. يجب تحديد معالجة GRNI/الالتزام المستحق وسياسة ضريبة المشتريات مع المحاسب قبل تنفيذ القيود.

### 11.2 عهدة بضاعة المشتريات على السيارة

يحتاج دفترًا مستقلاً عن Fleet/Delivery Van Stock:
- المورد → المشتري/المركبة: إثبات تسليم المورد الفعلي للمشتري.
- المشتري/المركبة → المخزن: استلام أمين المخزن وفحص وقبول أو رفض.
- المخزن → المشتري/المركبة: صرف المرتجع فعليًا.
- المشتري/المركبة → المورد: قبول المورد وتوقيعه أو إثباته.

كل انتقال له actor/time ومصدر ووجهة ومستند ومرفقات وصنف/وحدة/كمية/حالة وoperation_id. لا ترفع الكمية إلى stock_branches عند حيازة المشتري لها؛ لا تزيد مخزون الفرع إلا عند قبول المخزن. ولا تخصم AP عند صرف المرتجع من المخزن؛ بل بعد قبول المورد.

### 11.3 أنواع مصروفات العهدة

تصنيف مقترح:
- PURCHASE: شراء بضاعة؛ يتطلب بائعًا ومستندًا وإثبات استلام، ويعالج موردًا/مخزونًا وفق الحالة.
- FUEL: وقود؛ مرتبط بمركبة أو معدة وعداد/كمية وقود ومستند، ويقيد على حساب مصروف الوقود.
- TRANSPORT: نقل/شحن؛ مرجع خدمة ومورد/Payee ومسار أو شحنة، ويُحمّل على مصروف النقل أو تكلفة المخزون إذا اعتمدت سياسة Landed Cost ذلك.
- OTHER: مصروف متنوع؛ يتطلب سببًا ومرفقًا ومركز تكلفة وحسابًا معتمدًا وحدود موافقة.

يجب ألا تمر FUEL/TRANSPORT/OTHER على supplier_ledger باعتبارها شراء بضاعة. ويلزم جدول حسابات/مراكز تكلفة معتمد وحدود صرف وموافقة منفصلة.

### 11.4 تسليم وتسوية النقد

الإصدار → إقرار الموظف باستلام النقد → شراء أو مصروف موثق → مراجعة مالية → رد النقد غير المصروف فعليًا إلى خزينة محددة → تسوية. يجب تسجيل إيصال رد النقد أو سند قبض وإرفاق إثباته. لا تعتبر خانة notes أو finance_reference بديلًا عن دليل استلام نقدي مستقل.

---

## 12. المقارنة مع الأنظمة المرجعية — استخلاص عملي

هذه المقارنة مستندة إلى وثائق الموردين الرسمية، وهي نماذج للمقارنة وليست دليلًا على وجود وظيفة بعينها في RAWAEA:

- **Microsoft Dynamics 365:** يتيح تسجيل مخزون المورد الموجود ماديًا لدى الشركة مع بقاء ملكيته للمورد دون إنشاء قيود GL عند الاستلام. ثم ينقل الملكية من المورد إلى الشركة عبر Inventory Ownership Change Journal. ويدعم متابعة المورد للكميات الموجودة والمستهلكة. الدرس للروائع: افصل الحيازة عن الملكية وعن الاعتراف المالي. [Microsoft Learn — Consignment](https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/consignment) و[Ownership change](https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/change-ownership-consignment).
- **Odoo 19:** يدعم Receipts يدويًا لمخزون الأمانة دون PO، مع اختيار المورد في Receive From وAssign Owner؛ ويحتفظ بمالك الصنف ويظهره في تقارير الحركة، لكنه لا يدخل في تقييم مخزون الشركة قبل انتقال الملكية. الدرس: لا تخلط الحيازة الفعلية مع المخزون المملوك. [Odoo — Consignment](https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/shipping_receiving/daily_operations/owned_stock.html) و[Stock movement valuation](https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html).
- **SAP Business One:** يفصل Goods Return عن A/P Credit Memo، ويربط المستند اللاحق بالمستند الأصلي، بما يسمح بتصحيح الكمية والقيمة جزئيًا. الدرس: إثبات عودة البضاعة ليس هو نفسه إثبات استحقاق إشعار المورد الدائن أو استرداد النقد. [SAP — Purchasing process](https://help.sap.com/docs/SAP_BUSINESS_ONE/68a2e87fb29941b5bf959a184d9c6727/450a572b37ca1f2ce10000000a1553f6.html) و[Credit Memo based on Goods Return](https://help.sap.com/docs/SAP_BUSINESS_ONE/6b5ba20510a244d0a005150566f01415/96ff5fbb8e144cde98c52ba1793c7ca0.html).
- **Daftra:** يوثق دورة شراء تبدأ من طلب الشراء أو مباشرة من فاتورة، وتدعم الاستلام الجزئي ومراحل الاستلام والسداد والمرتجع، مع فصل أثر الخدمة عن المنتج وتوثيق الفروق بين Purchase Return وDebit/Credit Note. الدرس: Quick Market لا ينبغي أن يُختزل في alias لفاتورة، وتصنيف الخدمة/المصروف مهم. [Daftra — Complete Purchase Cycle](https://docs.daftra.com/en/tutorial/the-complete-purchase-cycle/) و[Purchase Cycle](https://docs.daftra.com/en/user_manual/purchase-cycles-guide/).
- **Manager.io:** Purchase Order لا يؤثر ماليًا أو مخزنيًا وحده؛ Purchase Invoice تؤثر في AP، والدفع معاملة ثانية؛ Goods Receipt يفصل الكمية عن العملية المالية بحسب إعداد الصنف؛ كما يتيح تسجيل Payee لمشتريات نقدية دون ضرورة إنشاء Supplier. الدرس: فصل الأمر عن الفاتورة وعن الاستلام وعن الدفع، مع إمكان مسار للمشتريات النقدية. [Purchase Orders](https://www2.manager.io/guides/7210) و[Purchase Invoices](https://www2.manager.io/guides/7189) و[Goods Receipts](https://www2.manager.io/guides/36498) و[Suppliers/Payee](https://www2.manager.io/guides/7020).

**الاستنتاج المناسب لـ RAWAEA:** تبنّي فصل أربعة أبعاد مستقلة لكل حركة: حالة التشغيل، حالة المستند، واقعة الملكية/الحيازة المخزنية، والواقعة المالية. التفوق المطلوب لا يأتي من كثرة التبويبات بل من صحة التسلسل والمطابقة وعدم التكرار وإثبات كل انتقال.

---

## 13. مصفوفة E2E المطلوبة للإغلاق

| # | سيناريو الاختبار | الإثبات الواجب جمعه |
|---|---|---|
| 1 | Draft / PO / RFQ / Quotation | لا مخزون أو نقدية أو AP أو Journal بسبب الإنشاء/الموافقة وحدها |
| 2 | استلام PO جزئي ثم كامل | accepted qty، stock_branches، inventory_log، حالة PO، idempotency |
| 3 | شراء سوقي بلا PO | Payee، فاتورة/إيصال، استقبال فعلي، المقبول فقط للمخزون، عدم إنشاء PO وهمي |
| 4 | إقرار العهدة | لا أثر عند الإصدار؛ أثر واحد بعد ACK؛ رفض غير صاحب العهدة |
| 5 | مصروفات PURCHASE/FUEL/TRANSPORT/OTHER | مرفق وموافقة وحساب صحيح؛ لا AP غير مستحق |
| 6 | عهدة بضاعة المركبة | المورد→السيارة→المخزن مع قبول/رفض جزئي؛ لا زيادة فرع قبل قبول المخزن |
| 7 | مرتجع مورد جزئي | صرف من المخزن إلى عهدة مشتري؛ لا خصم AP قبل قبول المورد |
| 8 | قبول المورد | accepted_qty فقط يرحل مرة واحدة إلى SupplierReturn وSupplier Ledger وGL |
| 9 | تجاوز الكمية | مرتجع أول ثم ثانٍ بمفتاح مختلف؛ رفض إذا تخطى التراكمي received_qty |
| 10 | التزامن | عمليتان متزامنتان على نفس سطر الفاتورة لا تتجاوزان حد الكمية |
| 11 | عكس/إلغاء | قيد عكسي/حركة عكسية مدققة؛ لا حذف مباشر للمرحل |
| 12 | الصلاحيات | مستخدم بلا purchases/finance، مستخدم شركة أخرى، branch scope، direct DML رفض |
| 13 | التكامل | Parent، Buyer، Receiver، stock vouchers، driver/van sales، supplier ledger، finance reports، Realtime |
| 14 | النشر | Artifact وcommit lineage وheaders/cache وConsole/Network، ثم authenticated browser |
| 15 | عدم الأثر الجانبي | مقارنة snapshots قبل/بعد لكل من المخزون والدفاتر والخزينة وسجل التدقيق |

لا يمكن تشغيل هذه المصفوفة على Production ببيانات معاملات حقيقية أو مصطنعة. يجب توفير بيئة معزولة أو اختبار قابل للتراجع بعد اعتماد صريح وخطة تنظيف وحفظ الأدلة.

---

## 14. المشاكل التي ظهرت وكيف تم التعامل معها

1. تعذر إتمام مراجعة مجلد التقارير 400–500 بالكامل عبر أدوات GitHub المتاحة؛ لم أختلق أسماء ملفات أو أدّعِ قراءة هذه السلسلة. تم استخدام CURRENT_STATE وReport602 وReport589 والدستور وMaster CTO كمراجع موجهة، ثم أُعيد فحص المصدر الحي وقاعدة Production.
2. لقطة Cloudflare الموجودة قديمة بالنسبة إلى HEAD الحالي؛ لم أعتبرها دليلاً على النشر الحالي ولم أستنتج من ذلك أن النشر فشل.
3. لا توجد Development Branch في Supabase، ولا جلسة Buyer مصادق عليها مع إمكانية browser interaction في وضع الجلسة الحالي؛ لذلك لم أستخدم Production لإنشاء بيانات اختبار ولم أصف static inspection بأنه E2E.
4. ظهرت قاعدة §77.2 الأحدث التي تحسم التعارض مع التعليمات الأقدم التي كانت تطلب تنفيذ تعديلات Production مباشرة. تم الالتزام بالقاعدة الأعلى: تشخيص وقراءة وتجهيز حزمة تغيير، ثم انتظار اعتماد المالك الصريح قبل أي كتابة مؤثرة.

---

## 15. ما تم فعليًا وما لم يتم

### تم فعليًا

- قراءة CURRENT_STATE كبداية.
- إعادة جلب Git HEAD وParent ومصادر Buyer/Core/Receiver.
- فحص Production migrations، Edge versions، أعمدة وجداول وقيود ومحفزات وسياسات ومنح وعقود RPC ذات الصلة.
- إثبات فجوة DML على جداول المرتجعات.
- إثبات غياب الحد التراكمي للمرتجعات في دالة الإنشاء ومخطط البيانات الحالي.
- إثبات أن ترحيل المرتجع يحرك المخزون ويخفض AP دون حدث قبول المورد داخل RPC.
- تحديد عدم اكتمال الشراء السوقي وعهدة بضاعة السيارة وتصنيف مصروفات العهدة.
- تجهيز SQL مراجعة P0-D وRollback ومعايير القبول.
- تجهيز تصحيحات Buyer النصية والجراحية.
- إجراء مقارنة تنافسية بمراجع رسمية.
- إنشاء هذا التقرير وتحديث الحالة وسجل التنفيذ وذاكرة المشروع.

### لم يتم

- لم تُنفذ أي Migration أو DDL أو REVOKE/GRANT أو تعديل Policy/RPC/Trigger.
- لم تُعدل أي بيانات أو أرصدة Production.
- لم تُنشأ Edge Function ولم يُنشر كود Edge.
- لم يُعدل Buyer أو Receiver أو Parent HTML في المستودع التشغيلي.
- لم يُنشر Cloudflare.
- لم تُنشأ بيانات تجريبية في Production.
- لم يكتمل Browser E2E أو اختبار Console/Network.
- لم يُعلن إغلاق دورة المشتريات أو جاهزية Buyer للإنتاج.

---

## 16. إرشادات CTO القادم — التسلسل الإلزامي للوصول إلى الحقيقة

1. افتح CURRENT_STATE.md من أعلى الملف؛ استخرج LAST VERIFIED EVENT والـblockers، ثم اقرأ الدستور الدائم وMaster CTO بما فيه §§29 و32 و58–60 و77.2–77.4.
2. اقرأ Report603 كاملًا، ثم Report602 وReport589 §19؛ استخدمهما كخيوط تحقيق لا كإثبات للحالة الحالية.
3. أعد جلب Git HEAD وParent وBuyer/Core/Receiver والـdiffs. لا تفترض أن blob أو deployment لم يتغير.
4. اتصل بـSMART ERP Production قراءة فقط، وأعد فحص grants/policies/migrations/RPC/trigger/schema/counts قبل أي Migration.
5. افحص المستهلكين خارج company-1، وحدد هل أي تكامل يكتب مباشرة في purchase_returns أو purchase_return_details.
6. اعرض P0-D SQL الوارد في هذا التقرير على المالك، وانتظر موافقة صريحة على النص المحدد. لا تعتبر أي موافقة عامة على المشروع موافقة على هذا التغيير.
7. صمم واعرض P0-R كاملًا: منع تجاوز الكمية تحت التزامن + قبول المورد الجزئي + صرف مخزن → عهدة مركبة → قبول المورد + قيد المخزون/AP. اعرض SQL كاملًا وتأثيراته واختباراته وRollback، ثم انتظر اعتمادًا مستقلًا.
8. اطلب من المالك تطبيق Owner Change Set في Buyer (السطور 870/880 وacknowledgeCustody)، ثم أعد جلب SHA وأثبت تطبيق التعديل.
9. بعد اعتماد بيئة اختبار معزولة، نفذ E2E ومقارنة snapshots قبل/بعد، ثم افحص Artifact المنشور وRuntime. لا تقل FIXED/CLOSED/READY قبل إثبات الطبقة المعنية.
10. لا تلمس companies/company-1/main.html. لا تنشئ Edge Function جديدة. لا تعِد تنفيذ P0 controls المغلقة. لا تستبدل عهدة سيارة المشتريات بمخزون سيارات التوصيل أو Fleet assignment.

---

## 17. الخطوة التالية الواحدة ذات الأولوية

**اعتماد المالك الصريح لنص SQL الخاص بـP0-D بعد استكمال مراجعة المستهلكين الخارجيين.** بعد هذا الاعتماد فقط يمكن تطبيق عزل DML والتحقق من أن مسار الكاتب المركزي لم يتأثر. ويظل P0-R (منع تجاوز الكميات وقبول المورد) Change Set مستقلًا يجب تصميمه واعتماده قبل أي تنفيذ.

## 18. مستوى الإغلاق

| المجال | الحالة |
|---|---|
| Invoice central writer | CONFIRMED / CLOSED سابقًا |
| PO receiving authorization | CONFIRMED / CLOSED سابقًا |
| Custody cash acknowledgement gate | CONFIRMED / CLOSED سابقًا |
| Purchase return direct-DML boundary | CONFIRMED GAP / awaiting owner approval |
| Cumulative returned-quantity control | CONFIRMED GAP / design and owner approval required |
| Supplier physical acceptance & partial return | OPEN |
| Quick Market Purchase | OPEN |
| Purchasing vehicle goods custody ledger | OPEN |
| Custody expense categories and account mapping | OPEN |
| Buyer custody UI wording/confirmation | OWNER PATCH PREPARED / not applied |
| Cloudflare current artifact parity | UNKNOWN / UNVERIFIED |
| Authenticated Buyer E2E and business-data effects | UNVERIFIED |
| Overall Buyer | **OPEN / NOT PRODUCTION-READY** |

**قاعدة الإغلاق:** لا يعتبر وجود واجهة أو دالة أو جدول إنجازًا. الإغلاق يثبت فقط عندما يكون العقد متماسكًا، والحدث الفعلي موثقًا، والمخزون والحسابات والخزينة تتحرك مرة واحدة بالقيمة الصحيحة، وتنجح اختبارات الرفض والتزامن وعدم التكرار والتكامل والنشر.
