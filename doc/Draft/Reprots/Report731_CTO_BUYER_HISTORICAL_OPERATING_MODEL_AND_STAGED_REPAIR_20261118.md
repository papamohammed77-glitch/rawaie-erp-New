# Report731 — مراجعة CTO التاريخية والتشغيلية لتطبيق Buyer وخطة الإغلاق المرحلي

**التاريخ:** 2026-11-18 (Africa/Cairo)
**نقطة الاستئناف السابقة:** LVE-2026-11-17-730
**نقطة التحقق الحالية:** LVE-2026-11-18-731
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` / `main`
**HEAD التشغيلي:** `ebb2a01d07c8dc1460bd4f577962a7b8c26be920`
**ملف Buyer:** `companies/company-1/purchasing/buyer.html` — Blob `db1d311966a676dd2c7210895afefef5b5d2a954`
**مستودع السجلات:** `papamohammed77-glitch/rawaie-erp-New`
**Supabase Production:** SMART ERP — `fiilmooggumokxanwiyx`
**الدستور:** `doc/Draft/Reprots/الدستور التشغيلي الدائم.md` — تمت قراءة مواده الحاكمة كاملة في هذه المهمة.
**الحكم:** `READY WITH LIMITATIONS` — التاريخ والعقود الحالية وآثار Production المقروءة موثقة؛ الإصلاحات المؤثرة متوقفة عند بوابة ChangeSet وموافقة المالك.

---

## 1. النتيجة التنفيذية

هذه المهمة بدأت بإعادة بناء فهم وظيفة Buyer تاريخيًا قبل اتخاذ قرار إزالة أو دمج أي تبويب. النتيجة: **لا يوجد تبويب تشغيل أساسي أو دفتر عهدة أو مسار شراء أثبتت المراجعة الحالية أنه يجب حذفه.** التبويبات تخدم مسؤوليات مختلفة، وبعضها تطور من Placeholder إلى دفتر حيازة حقيقي. العلاج المطلوب هو إكمال روابطها ومسؤولياتها وتوحيد قوالب العرض، لا إلغاء الوظائف.

تم تأكيد تعارض P0 فعلي في Production: استلام PO يسجل حركة مخزون، لكنه يسجل أيضًا قيدًا مرحّلًا على حساب المورد ودفتره الفرعي قبل وجود فاتورة مورد مرتبطة بالـPO. عُثر على حالة تشغيلية واحدة موثقة: `PO-20260928` استُلم بالكامل، وتوجد له قيد `JE-RCV-...` بقيمة 700 جنيه وحركة دائنة في دفتر المورد بقيمة 700 جنيه، بينما عدد فواتير الشراء المرتبطة بأمر الشراء يساوي صفرًا. لم يُعكس القيد ولم تُعدّل الأرصدة.

كما تأكد أن مسار الشراء السريع يسمح بإنشاء فاتورة بمصدر تسوية `SUPPLIER_CREDIT`، لكن قائمة Receiver ودالة الاستلام تقبلان حاليًا `EMPLOYEE_CUSTODY` فقط، بينما ترحيل فاتورة Buyer يرفض `QUICK_MARKET` عمومًا. إذن خيار الائتمان يستطيع إنشاء مسودة لا تجد مسارًا مكتملًا للاستلام والمطابقة والترحيل.

**لا يوجد تغيير تشغيلي أو DDL/DML أو نشر في هذه الجولة.** نُفذت استعلامات قراءة فقط، وفحصت ملفات المصدر ودوال Production المنشورة وتاريخ Git. السبب ليس عجزًا عن تحديد المسارات؛ بل أن الدستور يمنع تحويل تفويض عام إلى تغيير مؤثر غير معروض. كل تغيير يمس دورة المستندات أو قيود المخزون/المورد أو الصلاحيات يتطلب عرض SQL/patch الكامل وأثره وخطة الاختبار والتنظيف والتراجع ثم موافقة المالك الصريحة.

## 2. استعادة رؤية المالك والتاريخ الفني

### 2.1 التسلسل الفعلي لبناء Buyer

| التاريخ / المرجع | ما الذي يثبته سجل التطوير؟ | الدلالة على التصميم الحالي |
|---|---|---|
| 2026-11-01 — `a0ff4e25d349b84015f48337d0d978a4509d690b` | دمج PWA للمشتري مع محرك مشتريات مؤمّن وسير عمل أولي من ستة تبويبات. | التطبيق بدأ كمساحة عمل للمشتري، لا كنسخة من Parent. |
| 2026-11-01 — `8bc997c8f3d3db80acca08c1e8c523d2a28b5e85` | إضافة دفتر عهدة موظف منفصل ودورة تسوية. | عهدة النقد وظيفة مالية مستقلة لها دورة إثبات ومراجعة وتسوية. |
| 2026-11-02 — `02b5f00cc126bc33775d53fbd1886ae08e30f6a2` | إضافة الفواتير وعروض الموردين ورؤية حيازة المركبة؛ كان تبويب الحيازة ما زال Placeholder بعنوان «رصيد السيارة». | وجود التبويب كان مطلبًا وظيفيًا مبكرًا، لكن تنفيذه الأول لم يكن دفترًا حقيقيًا. |
| 2026-11-04 — `2c421a95985fcdd5f59166046cf70db1e63127ae` | استبدال رصيد السيارة الوهمي بدفتر حيازة بضاعة حي مشتق من أحداث مركزية، وتغيير الاسم إلى «عهدة بضاعتي». | التبويب تطور عمدًا من vehicle balance إلى physical custody ledger؛ لا يجوز إرجاعه إلى رصيد مركبة أو حذفه. |
| 2026-11-04 — `30be4201d31f78db0310f0b25468e540dfe4a333` و`ad9c003614ac9cfec729ab173aa488cb23029a3a` | فصل إدخال فاتورة PO عن فاتورة Quick Market المستقلة، وإضافة حجز عهدة نقدية للشراء السريع. | فصل المسارين يعكس فرقًا في مصدر التوريد والتمويل والاستلام، وليس ازدواجًا يجب دمجه. |
| 2026-11-04/05 — `8059ac691d...` و`bf27232142...` و`8f40e65f66...` | إضافة متابعة حيازة مشتريات السوق السريع وحجز النقد والمصروفات التشغيلية. | الحيازة النقدية والحيازة المادية تحتاجان دفترين منفصلين. |
| 2026-11-09 — `c7e85001edd24ab8ac153de2c9c0a6cedebd9a17` و`6a35dbf91ca283499b9da8ac5f709a92cc4f3664` | تفعيل استلام Quick Market في Receiver وفصل عهدة النقد عن حيازة البضاعة. | Receiver أصبح نقطة دخول الكمية المقبولة للمخزون؛ لا يستبدل Buyer ولا يقوم بالترحيل المالي. |
| 2026-11-09 — `36431ef45a175c989315d6fa7322dd4a85e64f4f` و`85a1773430a6d76799cd31e85b1a03f79f132369` | إصلاح دفتر حيازة Quick Market وإضافة إجراء مرتجع المورد للبضاعة المملوكة للمورد والتي لا تزال في عهدة المشتري. | هذا المسار مختلف عن مرتجع المورد الصادر من مخزون الشركة عبر StockVoucher. |
| 2026-11-09 — `Report669` إلى `Report678` | فصل الملكية والحيازة، حجز النقد، إثبات الاستلام، مرتجع مشتريات السوق، تفويض مستلم مرتجع المورد، وإعادة تنظيم UX. | يجب الحفاظ على الإصلاحات اللاحقة وعدم إعادة فتح فجوات سبق إغلاقها. |

### 2.2 سبب شكل المودالات وتعددها

التاريخ لا يثبت أن المودالات أُنشئت اعتباطًا. Buyer اكتسب وظائفه على مراحل: موردون، PR، RFQ/عروض، PO، فواتير، شراء سريع، عهدة نقد، حيازة بضاعة، مراجعات مالية، ومرفقات وإثباتات. سجل `99c721f6ed8b6f3c13aa93930018a51fe60eab03` يذكر صراحة مواءمة العملة واستنساخ أنماط مودالات المورد والفاتورة وPO من Parent. أي أن المودالات المخصصة هي نتيجة تسليم تدريجي ونسخ أنماط النظام الأم، وليست دليلًا وحده على تكرار منطق أعمال.

الملف الحالي يحتوي 32 موضعًا لاستدعاء `Swal.fire()`. هذا العدد **لا يساوي 32 مودالًا مكررًا**؛ منه نماذج إنشاء/تعديل، وعرض تفاصيل، وتأكيدات، ورفض، ومراجعات مالية، واستلام عهدة. ما يمكن توحيده دون خسارة وظيفة هو طبقة العرض المشتركة: رأس المستند، تخطيط البنود، اختيار المورد والصنف، التحقق، المرفقات، سجل الحالة، وشريط الإجراءات. أما فروق PO وQuick Market وتمويل العهدة فتظل فروقًا تشغيلية ظاهرة ومفصولة.

التصميم الحالي داخل ملف Buyer monolithic واحد يزيد احتمال تكرار HTML/JS؛ لكنه لا يبرر حذف الإجراء. يجب نقل التكرار إلى helpers/views مشتركة أو مساحات عمل مستندية تدريجية مع الإبقاء على جميع الحقول والقيود والسلوكيات الخاصة بكل مسار. أي تعديل على Buyer نفسه يجهز كـpatch للمالك ولا يُدفع مباشرة من المساعد وفق §7 من الدستور.

### 2.3 التمييز عن تاريخ Parent

Report200 وReport201 من سبتمبر 2026 يتناولان مودالات النظام الأم `RW_PurchaseGold` وسير Source-to-Pay في Parent. لا يصح استخدامهما كدليل على أن كل مودال في Buyer مكرر أو معيب. Report595 يذكر تعايش مسارات شراء Parent قديمة وحديثة؛ مثل `RW_PurchaseGold` و`purchase-pos`/`RW_Purchases.renderPOS`. يجب تدقيق مسار Parent الفعلي قبل تعديل أي واحد منهما. لم أتمكن في هذه الجولة من جلب ملف `main.html` الحالي كاملًا بسبب حجمه/استجابة GitHub؛ لذلك تفاصيل Parent الحالية مصنفة `UNVERIFIED` وتحتاج قراءة مجزأة في المرحلة التالية.

## 3. الوظيفة التي يجب الحفاظ عليها في كل تبويب

| التبويب الحالي | لماذا أُنشئ؟ | ما الذي يجب استكماله؟ | قرار الحفظ |
|---|---|---|---|
| اليوم | مركز متابعة للمشتري ومؤشرات أوامر متأخرة وعهدة واحتياجات. | إظهار المطلوب اتخاذ إجراء بشأنه فقط، مع أرقام مصدرها بيانات كاملة لا عينة 500 سجل. | يُحفظ. |
| الموردون | دليل الموردين وبيانات التعامل. | ربط سجل الأداء والتوريد المتأخر والرفض والشروط والفروع، مع مراعاة صلاحيات النظام الأم. | يُحفظ. |
| طلبات PR | صندوق وارد لاحتياجات الإدارات المعتمدة، وليس أداة إنشاء احتياج للمشتري. | هوية الإدارة والفرع ومقدم الطلب والميزانية/مركز التكلفة، بنود وتغطية جزئية، حالة اعتماد مستقلة عن التوريد. لا تجعل المشتري معتمد الميزانية لمجرد امتلاكه `purchases`. | يُحفظ؛ والاعتماد يفصل عن Buyer. |
| عروض الأسعار | RFQ وعروض الموردين واختيار العرض. | مقارنة عروض منظمة على البنود والأسعار والضرائب وشروط الدفع والمدة والجودة، وتوثيق سبب الترسية والاستثناء. | يُحفظ. |
| أوامر PO | التزام توريد يصدره المشتري للمورد. | مرجع PR وبنوده في الحالة العادية، دعم جزئي ومتعدد PO لطلب واحد، تأكيد المورد، إرسال/استجابة المورد، والمتبقي. يبقى Direct PO استثناءً مضبوطًا لا يُحذف. | يُحفظ. |
| فواتيري | فواتير المورد المرتبطة بـPO وفواتير Quick Market المباشرة. | فصل مصادر الفاتورة والتمويل والاستلام؛ دعم فواتير/دفعات توريد جزئية؛ مطابقة PO/GRN/Invoice؛ حل مسار `SUPPLIER_CREDIT` في Quick Market. | يُحفظ. |
| عهدتي | النقد المسلم للمشتري/الموظف، حجوزات مشتريات السوق السريع، المصروفات والمرفقات والمراجعة ورد النقد. | إبقاء دفتر النقد منفصلًا، عدم خصم الحجز والمصروف مرتين، وربط كل حركة قبض/صرف بمستند حقيقي. | يُحفظ مستقلًا. |
| عهدة بضاعتي (المعرف الداخلي `vehicle`) | جرد ما هو في الحيازة الفعلية للمشتري: بضاعة مورد اشتراها سريعًا، أو بضاعة شركة خرجت في مرتجع مورد بتفويض المشتري. المركبة مجرد وعاء اختياري للنقل/التخزين. | استكمال تسليم المورد وقبوله، وإرجاع الجزء المرفوض للمخزن، وإضافة جرد فعلي ومقارنة الرصيد الدفتري بالموجود الفعلي، واعتماد فروق الجرد عبر أحداث تصحيحية غير قابلة للمحو. يدعم الحيازة دون سيارة. | يُحفظ ولا يُدمج مع عهدة النقد أو Van Sales. |
| حسابي | هوية المستخدم وإعداداته. | إبقاؤه مرتبطًا بهوية وصلاحيات Parent لا يخلق ملف مستخدم موازٍ. | يُحفظ. |

لا توجد توصية بحذف تبويب. كما أن دفتر `عهدتي` الحالي منفصل بالفعل عن `عهدة بضاعتي`؛ لم أجد في `renderCustody()` الحالي إعادة عرض لدفتر الحيازة المادي. هذا التكرار الذي وصفه Report669 كان تاريخيًا، ثم أزالته معالجة Report670. لا يعاد إدخاله.

## 4. عهدة بضاعتي / المركبة — العقد الصحيح

### 4.1 دفتر الحيازة ليس رصيد السيارة

التبويب الحالي «عهدة بضاعتي» يستند إلى `GET_BUYER_GOODS_CUSTODY_BALANCES` ودفتر أحداث `buyer_goods_custody_events`. أنواع الملكية الحالية مفصولة: `SUPPLIER_OWNED` و`COMPANY_OWNED_SUPPLIER_RETURN` و`UNCLASSIFIED`. يقرأ كل رصيد بحسب الحائز/الفرع/الصنف/المورد/المستند المصدر. عمود `vehicle_id` اختياري؛ ولا توجد حاجة إلى سيارة حتى تظهر البضاعة كحيازة للمشتري.

هذه حدود سليمة يجب الحفاظ عليها: لا تُعرض هذه الكميات كأنها مخزون الفرع، ولا تُخلط مع `Van Sales` أو مخزون سيارة المندوب، ولا يُسمح بإدخال رصيد قابل للتحرير يدويًا. أي جرد فعلي يجب أن يقارن لقطة الرصيد الدفتري المستنتج من الأحداث بما عُد فعليًا، ولا يستبدل دفتر الأحداث.

### 4.2 مرتجع المورد من مخزون الشركة — المسار موجود

الفحص التاريخي والحالي أثبت وجود دعم قائم في النظام الأم/المخزن:
- واجهة `warehouse/vouchers.html` تعرض اختيارًا اختياريًا باسم «المشتري المفوض لحيازة بضاعة المرتجع» داخل SupplierReturn.
- تستدعي الواجهة `get_buyer_custody_recipients_atomic` وتخزن `receiver_user_id` على مستند SupplierReturn.
- `assign_supplier_return_receiver_atomic` يسمح لمستخدم مخزن مؤهل بتعيين مستلم Buyer نشط في الشركة ويحمل صلاحية `purchases`، والمسودة فقط قابلة للتعيين.
- Trigger `enforce_supplier_return_receiver` يفرض نفس الشركة والأهلية ويمنع تغيير الهوية بعد الإرسال.
- Trigger `sync_supplier_return_buyer_custody_event` ينشئ حدث `WAREHOUSE_TO_BUYER_SUPPLIER_RETURN` عند `Draft → Sent`، ثم حدث `BUYER_TO_SUPPLIER_ACCEPTED` عند `Sent → Completed`.

إذًا لا يصح القول إن نقل مرتجع المورد من المخزن إلى المشتري غير موجود. العقد الحالي يسمح بحيازة فعلية كاملة مع سيارة اختيارية، لكن الإكمال يقبل الكمية الكاملة فقط؛ عند وجود قبول جزئي يرفع `SUPPLIER_RETURN_PARTIAL_ACCEPTANCE_NOT_SUPPORTED_BY_CURRENT_FINANCE_CONTRACT`. كما أن المشتري نفسه لا يملك الآن إجراءً في دفتره لتسجيل تسليم/قبول جزئي وإرفاق الإثبات؛ صلاحية الإكمال النهائية بقيت لدى أدوار المخزن المميزة.

### 4.3 العقد المطلوب لمرتجع المورد الجزئي

لكل بند في إذن SupplierReturn يجب أن يتحقق:

`issued_qty = supplier_accepted_qty + warehouse_returned_qty + buyer_custody_open_qty`

- الكمية المقبولة من المورد فقط هي التي تُنقص حيازة المشتري وتُنشئ استحقاق دائن/تسوية مورد وضريبة/قيدًا وفق الكمية المقبولة.
- الكمية المرفوضة لا تُعد مرتجعًا مقبولًا لدى المورد، ولا تُنقص الحيازة حتى تُعاد فعليًا للمخزن بمستند مستقل وتُقبل في المخزن؛ عندها تُعاد للمخزون مرة واحدة.
- لا يغلق SupplierReturn الأصلي طالما `buyer_custody_open_qty > 0`.
- المشتري يستطيع تسجيل «قدمت للمورد» وإرفاق إثبات وكمية مقترحة، لكن لا ينفذ بنفسه ترحيل المورد أو حركة المخزون؛ تخضع النتيجة لمراجعة الدور المخول.
- تحفظ الأحداث Append-only وبـoperation_id/fingerprint، وأي تصحيح لاحق يكون حدثًا عكسيًا مرتبطًا بالأصل.

### 4.4 الجرد الفعلي المطلوب

لم يظهر في بحث أسماء جداول `public` كيان مخصص لجلسة جرد حيازة Buyer. هذه النتيجة لا تثبت عدم وجود كيان بدلالة اسم أخرى، لذلك تظل مراجعة كل المخططات والمستهلكين مفتوحة. التصميم المطلوب قبل إضافة جدول جديد:
1. جلسة جرد مرتبطة بالمشتري والفرع ووقت القطع والمستخدم القائم بالجرد، مع خيار موقع/مركبة اختياري.
2. لقطة متوقعة لكل مصدر/سطر/صنف/وحدة وملكية ومورد من دفتر الأحداث في وقت القطع.
3. إدخال الكمية المعدودة الفعلية لكل سطر، مع سبب الفرق والمرفق/الصورة عند الحاجة.
4. إظهار الفرق وعدم تعديل الرصيد أثناء العد.
5. مراجعة/اعتماد الفروق حسب الملكية: Supplier-owned لا يُعدّل كأنه مخزون الشركة؛ Company-owned SupplierReturn يحتاج مسار قبول مورد أو استلام مخزن؛ Unknown يوقف الإغلاق.
6. بعد الاعتماد فقط، تنشأ أحداث تصحيح/عكس Append-only مرتبطة بجلسة الجرد والمصدر؛ لا DML مباشر على دفتر الأحداث ولا على `stock_branches`.

## 5. التحقق الحي من Production — أثر الاستلام والتسويات

### 5.1 حالة PO مثبتة فعليًا

تمت قراءة دوال Production وبيانات المستندات قراءة فقط. `receive_purchase_atomic` (النسخة ذات خمسة معاملات) تنفذ، عند قبول كمية PO:
- `post_stock_movement(..., 'PurchaseIn', ...)` للكمية المقبولة.
- زيادة `purchase_order_details.qty_received` وتحديث حالة PO.
- إنشاء `journal_entries` نوع `PurchaseReceiving` بحالة `Posted`، مدين `124` مخزون ودائن `211` موردين.
- إضافة Credit إلى `supplier_ledger` مباشرة.

الحالة الحية:

| البيان | القيمة الحالية المقروءة |
|---|---:|
| PO | `PO-20260928` |
| حالة PO | `Received` |
| قيمة PO | 700.00 EGP |
| المستند الفعلي للاستلام | `مكتمل` بتاريخ 2026-11-09 |
| مجموع الكمية المقبولة | 15.0000 (سطران) |
| عدد فواتير الشراء المرتبطة بهذا PO | 0 |
| القيد | `JE-RCV-aaa9a71bd0b9412ea4831157cd8c46cf` / `Posted` |
| إجمالي القيد | Dr 124 = 700.00 / Cr 211 = 700.00 EGP |
| دفتر المورد | Credit 700.00 EGP، مرجع `PO-20260928` |

هذا دليل مباشر على أن Receiver/استلام PO يستطيع اليوم إنشاء ذمة مورد وقيود قبل أن تُنشأ أو تُراجع فاتورة المورد. لا أُجري أي قيد عكسي ولا أصحح السجل القائم آليًا. يجب مراجعة هذا القيد تحديدًا من المحاسب ومطابقته مع المستندات قبل أي تسوية تاريخية.

### 5.2 تعارض بين الاستلام والترحيل

`purchase_post_invoice_atomic` لمسار PO يتحقق من وجود استلام وكميات وأسعار، ثم يحول الفاتورة إلى `Posted` ويعيد `supplier_liability_posted_by_invoice=false` دون إنشاء AP؛ لأن المنطق الحالي يفترض أن ذمة المورد نُشئت مسبقًا من الاستلام. هذا يثبت أن نقل القيد من Receiver إلى الحسابات لا يمكن أن يتم بحذف أسطر القيد من دالة الاستلام فقط؛ يجب إصلاح طرفي المعاملة معًا:
- Receiver/GRN: المخزون والكميات وحالة الاستلام وسجل الاستلام فقط، بلا Supplier AP/Subledger/GL.
- Accounts: بعد مطابقة PO + GRN + Supplier Invoice وصلاحية الاعتماد، يرحل الالتزام المستحق على المورد حسب الكمية المفوترة والمقبولة، دون تكرار حركة المخزون.
- Payment: يبقى منفصلًا عبر `purchase_post_payment_atomic` ومسار الخزينة، عند دفع النقد فعليًا، جزئيًا أو كليًا.

لا يُنشأ حساب GR/IR أو قيد استحقاق استلام وسيط تلقائيًا في هذا التغيير؛ ذلك خيار سياسة محاسبية منفصل يجب أن يعتمده المالك، ولا يجوز أن يتحول إلى دائن للمورد في دفتره الفرعي قبل المطابقة.

### 5.3 Quick Market / Supplier Credit — مسار غير مكتمل

دالة `purchase_create_quick_market_invoice_atomic` تقبل `EMPLOYEE_CUSTODY` أو `SUPPLIER_CREDIT`. لكن:
- `get_quick_market_receiving_queue_atomic` تجلب `settlement_source='EMPLOYEE_CUSTODY'` فقط.
- `receive_quick_market_purchase_atomic` تشترط `settlement_source='EMPLOYEE_CUSTODY'` ووجود `cash_custody_id`.
- `purchase_post_buyer_invoice_atomic` ترفض `purchase_source='QUICK_MARKET'` عمومًا.

لذلك فاتورة Quick Market على `SUPPLIER_CREDIT` يمكن إنشاؤها كمسودة، لكن لا تصل إلى مسار Receiver ولا إلى مسار ترحيل مالي مكتمل. هذا تناقض بين الخيارات التي تعرضها الواجهة وما تسمح به المرحلة التالية. الإصلاح يجب أن يبقي تمويل العهدة والائتمان منفصلين:

| المصدر | Receiver | بعد الاستلام | الترحيل المالي |
|---|---|---|---|
| `EMPLOYEE_CUSTODY` | يقبل الكمية الفعلية ويزيد المخزون فقط | يحفظ GRN ويخصم المقبول من عهدة البضاعة | مراجعة Finance لتسوية العهدة؛ مسار QMP الحالي Dr 124 / Cr 127، بلا AP أو دفعة خزينة ثانية |
| `SUPPLIER_CREDIT` | يجب أن يقبلها بنفس ضوابط الفرع والكمية/idempotency، ويزيد المخزون المقبول فقط | يحفظ GRN ويخصم المقبول من حيازة المشتري | Finance يطابق الفاتورة مع GRN ثم Dr 124 / Cr 211 وSupplier Ledger، بلا حركة خزينة حتى الدفع الفعلي |

لا يجب أن يؤدي اختيار مصدر التمويل إلى تغيير ضوابط الاستلام الفعلي أو أن يخلق أثرًا ماليًا أثناء حفظ المسودة.

### 5.4 أرقام الإنتاج وقيود القراءة

لقطة القراءة في هذه الجولة أظهرت: PR=1، RFQ=0، Quotations=1، PO=4، Purchase Invoice=7، Receiving=7، `purchase_status_history`=22، `purchase_document_links`=5. هذه عدادات حالية لشركة التشغيل الظاهرة في SMART ERP وليست حصرًا تاريخيًا لكل الشركات.

كما ظهرت حالات QMP مسجلة `Draft` مع `receipt_status='RECEIVED'` و`settlement_status='UNSETTLED'`؛ أي إن اكتمال الاستلام لا يعني اكتمال المراجعة/التسوية، وهذا فصل صحيح من حيث المبدأ لكنه يحتاج مسار Finance قابلًا للتنفيذ لكل مصدر تمويل.

### 5.5 بيانات هوية PR

مخطط Production الحالي لـ`purchase_requests` لا يحوي `department_id` أو `branch_id` أو `requested_by_user_id`؛ الحقول المعروفة تشمل `requested_by` كنص. توجد جداول HR (`hr_departments`, `hr_employee_assignments`, `employee_profiles`) لكن عدد الصفوف في كل منها صفر في لقطة القراءة الحالية. توجد ثلاثة Cost Centers، ولا يكفي ذلك لاستنتاج إدارة كل مقدم طلب. لذلك لا يجوز ربط PR بإدارة مفترضة أو تحويل نص `requested_by` إلى هوية موثوقة دون استكمال مصدر HR/التعيينات.

## 6. عيوب دورة PR / RFQ / Quote / PO

1. Buyer يعرض PR الواردة ولا يملك حاليًا `createRequest`؛ هذا مناسب إذا كانت جهة إنشاء PR هي الإدارات/Parent وليس المشتري.
2. تفاصيل PR الحالية تعرض `requested_by` على أنه الإدارة/مقدم الطلب، وتقر في الواجهة أن الإدارة/القسم غير محفوظ كحقل مستقل.
3. `purchase_approve_request_atomic` تسمح بحالات Draft/PendingApproval/Submitted، ولا تتحقق داخل الدالة من سلطة اعتماد متميزة أو منع مقدم الطلب من اعتماد طلبه.
4. Edge `APPROVE_REQUEST` في `save-purchase-order` يقع حاليًا تحت بوابة `purchases` العامة، وليس permission اعتماد PR مستقلة؛ وتعرض Buyer أزرار اعتماد/رفض PR. هذا يخلط دور المشتري مع اعتماد احتياج الإدارة/الميزانية.
5. `purchase_create_rfq_atomic` تقبل Draft أو Approved، وتحدث PR إلى `Converted` عند إنشاء RFQ؛ إصدار طلب أسعار لا يعني أن التوريد تم. حالة PR يجب أن تحتفظ بحالة الاعتماد والتنفيذ المفتوح والتغطية الجزئية.
6. `purchase_create_po_atomic` لا يستقبل مرجع PR أو بنوده؛ لذلك PO اليدوي لا يثبت مصدر الاحتياج. لا يحذف مسار PO اليدوي؛ يُصنف Direct/Exception مع سبب وموافقة عند اللزوم، بينما المسار العادي يربط كل PO line ببند PR.
7. Buyer `poEligible()` يمنع بدء فاتورة جديدة إذا بدأ استلام أي بند PO، رغم أن نمط المورد يمكن أن يفوتر دفعات متتابعة. يجب أن يكون الأهلية وفق كمية مستلمة غير مفوترة لكل بند، لا شرط انعدام الاستلام بالكامل.
8. قواعد 3-Way Match الحالية ترفض أي خصم أو ضريبة غير صفرية وتطلب تطابق سعر صارم؛ المطلوب مصفوفة فروق وسماح واعتماد استثناءات، لا تمرير غير مشروط ولا رفض موحد لكل فرق.

## 7. الصلاحيات والأمان — المتبقي من LVE730

Report730 أكد في 2026-11-17 أن 12 جدول مشتريات/سجل حالة/روابط/إعدادات/مدفوعات كانت تملك صلاحيات كتابة مباشرة لـ`anon` و`authenticated` مع سياسات company-scope، وأن `purchase_status_history` يفتقر إلى append-only guard، وأن `purchase_document_links` يفتقر إلى FK على `source_id/target_id`. لا يوجد migration أحدث من `20261116144311` في لقطة Production الحالية، لكن لم أعد في هذه الجولة تنفيذ census ACL كامل؛ لذلك يسجل هذا كـ`CONFIRMED AT LVE730 — CURRENT ACL RECHECK OPEN` وليس كإصلاح منجز.

كذلك فحصت ACL لعدد من الدوال: `purchase_approve_request_atomic` و`purchase_create_request_atomic` و`purchase_create_rfq_atomic` و`receive_purchase_atomic` خدمة `service_role` فقط مباشرة من Postgres، بينما Edge هو بوابة الاستدعاء. يجب ألا تُضعف هذه الحدود عند إضافة صلاحيات جديدة، ويجب أن تتحقق الدوال/Edge من هوية الطالب وسلطته والشركة والفرع وعدم self-approval.

## 8. خطة الإغلاق المرحلي

### المرحلة 1 — اكتملت: التاريخ والمالك والعقود الحية

- قراءة الدستور كاملًا، واستعادة `CURRENT_STATE` من LVE730.
- مقارنة Buyer الحالي مع commits التي تفسر أصل التبويبات وتطور دفتر الحيازة.
- قراءة تقارير 595/599/669/670/672/673/674/675/676/678/728/729/730 ذات الصلة.
- قراءة Buyer/Receiver/warehouse vouchers، ودوال Supabase المنشورة، ومخطط الجداول والحقول الأساسية.
- قراءة فقط لسجلات PO/GRN/Invoice/Journal/Supplier Ledger وإثبات الأثر الواقعي أعلاه.
- لا كتابة تشغيلية أو تغيير بيانات.

**نتيجة المرحلة:** `CONFIRMED — ROOT CAUSE MAPPED WITH LIVE EVIDENCE`.

### المرحلة 2 — P0: إعادة ضبط حد الاستلام والترحيل المالي

**العقود التي يلزم إعداد replacement SQL لها بعد اكتمال dependency scan:**
- كل overloads لـ`receive_purchase_atomic` المستخدمة حاليًا من Edge/Receiver/warehouse.
- `purchase_post_invoice_atomic` و`purchase_post_buyer_invoice_atomic`.
- أي Trigger/Wrapper/RPC يكتب PurchaseReceiving journal أو Supplier Ledger من مسار الاستلام.

**السلوك المطلوب:** Receiver ينشئ GRN ويحدث المخزون فقط بالكمية المقبولة. Finance يطابق المستندات ثم ينشئ ذمة المورد والقيود مرة واحدة على الفاتورة المقبولة. يجب الحفاظ على idempotency، partial receipt، source/line refs، audit log، والlegacy guards. لا يعاد ترحيل أو عكس `PO-20260928` قبل تسوية محاسبية مستقلة.

**بوابة القبول:** PO Draft/Approved لا يغير المخزون أو GL/AP؛ Receiver يزيد `stock_branches` بالكمية المقبولة فقط ولا يزيد Supplier Ledger/211؛ فاتورة PO بعد GRN ومراجعة Finance تنشئ قيدًا متوازنًا وSupplier Ledger مرة واحدة؛ Payment وحده يغير الخزينة ويخفض ذمة المورد. اختبار `BEGIN/ROLLBACK` أو fixture QA فريد قابل للإزالة، ثم مقارنة baseline كاملة.

### المرحلة 3 — P1: استكمال Quick Market بكلا مصدري التمويل

توسيع `get_quick_market_receiving_queue_atomic` و`receive_quick_market_purchase_atomic` لقبول `SUPPLIER_CREDIT` بشروط صريحة، مع الحفاظ على مسار `EMPLOYEE_CUSTODY`. ثم إضافة branch ترحيل مالي داخل بوابة `purchase_post_buyer_invoice_atomic` لمصدر Quick Market الائتماني: يجب أن يثبت الاستلام المقبول، ويحسب غير المفوتر، وينشئ AP 211 فقط للكمية/القيمة المقبولة؛ لا يعيد حركة المخزون ولا حركة خزينة. لا يُغير QMP cash custody settlement الحالي إلا بعد مطابقة عقده واختباره.

### المرحلة 4 — P1: اكتمال PR ومرجعية PO

- اعتماد مصدر HR للإدارة/القسم ومقدم الطلب والفرع؛ لا تستخدم أسماء مكتوبة فقط ولا تنشئ master جديدًا إن كان Parent/HR يملك مصدرًا صالحًا.
- إضافة identity FK/metadata إلى PR بعد تأكيد المصدر المرجعي، وربط PR lines بتخصيصات PO/RFQ متعددة مع تغطية جزئية.
- فصل صلاحية تقديم PR واعتماده عن `purchases`; منع self-approval وإضافة مسار إرجاع/رفض بسبب واضح.
- عدم تحويل PR إلى `Converted` عند إنشاء RFQ؛ إدارة حالة التوريد منفصلة عن حالة الاعتماد.
- الإبقاء على Direct PO كاستثناء محكوم ومسبب، وربطه بالطلب إن وجد.
- إعادة تأهيل فواتير PO حسب الكمية المستلمة غير المفوترة؛ دعم فاتورة المورد الجزئية المتكررة.

### المرحلة 5 — P1: إكمال حيازة مرتجع المورد

- الحفاظ على `receiver_user_id`، وتعيين المشتري، وحدث `WAREHOUSE_TO_BUYER_SUPPLIER_RETURN` عند إرسال الإذن.
- إنشاء مستند/عملية قبول جزئي append-only لكل دفعة قبول من المورد مع الكمية والدليل والفاعل وoperation_id؛ المشتري يقدم الإثبات ولا ينفذ ترحيل المورد.
- دعم مستند مستقل لإرجاع الجزء المرفوض للمخزن؛ لا يضاف للمخزون حتى يقبله المخزن فعليًا.
- تحديث `sync_supplier_return_buyer_custody_event` و`complete_manual_stock_voucher_atomic` وfinancial core في ChangeSet ذري واحد بعد مراجعة كل consumers؛ لا تغير Trigger وحده.
- تطبيق معادلة issued = supplier accepted + warehouse returned + open custody، ومنع إغلاق الإذن مع رصيد موجب.

### المرحلة 6 — P1/P2: جرد عهدة بضاعتي وتوحيد UX

- فحص كل المخططات/الجداول لمعرفة إن كانت هناك آلية count session قائمة باسم آخر قبل إنشاء أي كيان جديد.
- إضافة جلسة جرد Snapshot/Actual/Variance ومراجعة/اعتماد؛ الأحداث التصحيحية فقط بعد الاعتماد.
- إعادة استخدام common document shell وline editor وsupplier/item picker وattachment panel وtimeline داخل Buyer؛ إبقاء فروق PO/QMP والمال/البضاعة مستقلة.
- عدم حذف أي تبويب، وعدم دمج النقد مع البضاعة، وعدم اشتراط vehicle_id.
- إزالة التكرار البصري فقط بعد تحديده بالمقارنة؛ الاحتفاظ بكل Actions/fields/validations.
- استبدال حدود 500/100 بـpagination أو server-side filters مع count metadata.

### المرحلة 7 — اختبارات E2E والإغلاق

1. Department PR submit → manager approval → Buyer queue.
2. PR → عدة RFQ/Quotes → selection/award rationale → عدة PO جزئية.
3. PO approved/sent → partial and full GRN → invoice matching → AP posting → partial/full supplier payment.
4. Quick Market EMPLOYEE_CUSTODY → Buyer physical custody → Receiver partial acceptance → Finance custody review → no extra Treasury/AP.
5. Quick Market SUPPLIER_CREDIT → Buyer custody → Receiver partial acceptance → Finance AP invoice posting → later payment.
6. Warehouse SupplierReturn → assigned Buyer custody → Buyer delivery evidence → supplier partial acceptance → warehouse return of rejected remainder → no double stock/ledger posting.
7. Buyer goods physical count → reviewed variance → append-only correction; test without vehicle and with vehicle.
8. No-effect assertions for Draft/Approve/PO/RFQ; idempotent retries and payload conflicts; unauthorized/other-company/other-branch attempts; Realtime refresh and page reload.
9. Baseline and cleanup verification for every committed QA fixture; no fixture residue, journal, cash, supplier ledger or stock movement remains.

## 9. التغييرات المنفذة في هذه الجولة

| العنصر | الحالة |
|---|---|
| Historical/source audit | مكتمل قراءة وتحليل |
| Production function and schema audit | مكتمل للنطاق المذكور، read-only |
| Actual PO/AP discrepancy identification | Confirmed, not adjusted |
| Buyer tab deletion/reorganization | لم يُحذف أو يُعدّل أي تبويب |
| Buyer/Receiver/Parent/vouchers operational source | لم يتغير |
| Supabase DDL/DML/RPC/Edge deployment | لم يتغير |
| QA fixture / E2E / Cloudflare runtime | لم ينفذ في هذه الجولة |
| Governance report | سيُسجل بهذا التقرير |
| CURRENT_STATE | سيُحدّث بنقطة LVE731 |

## 10. بوابة المالك قبل المرحلة التشغيلية

لا يُعتبر هذا التقرير موافقة تنفيذية على التغيير. قبل أي كتابة مؤثرة يجب عرض ChangeSet منفصل لكل حزمة يتضمن: جميع النصوص البديلة الكاملة للدوال/Triggers، أسماء كل المستهلكين، الفروق قبل/بعد، أثر المخزون والخزينة وAP/GL/Supplier Ledger والعهد، صلاحيات التنفيذ، اختبار rollback/fixture وخطوات cleanup، وخطة rollback. لا تمس الملفات التشغيلية مباشرة؛ تُجهز patches ليطبقها المالك. أما Production SQL فتنتظر الموافقة المحددة على كل حزمة.

## 11. Last Verified Event / Resume

- **LVE:** `LVE-2026-11-18-731`.
- **Readiness:** `READY WITH LIMITATIONS`.
- **Completed:** historical rationale, tab-purpose recovery, Production root-cause mapping and actual PO/AP effect confirmation.
- **Open:** complete Parent segmented source review; exact replacement SQL and consumer census; owner approval; P0 implementation; Quick Market credit branch; PR/PO identity and state model; partial SupplierReturn acceptance; Buyer goods count workflow; authenticated browser/Cloudflare E2E.
- **Next step:** prepare the exact P0 financial ChangeSet (both Receiver and invoice-posting sides together), showing the full live function definitions and all callers. Present it to the owner before applying any SQL. Do not reopen or delete the goods custody tab; it is a core custody ledger.

---

## References

- [Operational Buyer current source](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/purchasing/buyer.html)
- [Operational Receiver current source](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/warehouse/receiver.html)
- [Operational warehouse vouchers current source](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/warehouse/vouchers.html)
- [Buyer initial six-tab workflow — commit a0ff4e2](https://github.com/papamohammed77-glitch/erp-frontend/commit/a0ff4e25d349b84015f48337d0d978a4509d690b)
- [Buyer invoice/quotation/vehicle custody tabs — commit 02b5f00](https://github.com/papamohammed77-glitch/erp-frontend/commit/02b5f00cc126bc33775d53fbd1886ae08e30f6a2)
- [Live goods custody ledger replacing vehicle placeholder — commit 2c421a9](https://github.com/papamohammed77-glitch/erp-frontend/commit/2c421a95985fcdd5f59166046cf70db1e63127ae)
- [PO and Quick Market split — commit 30be420](https://github.com/papamohammed77-glitch/erp-frontend/commit/30be4201d31f78db0310f0b25468e540dfe4a333)
- [Buyer QMP custody and return — commit 36431ef](https://github.com/papamohammed77-glitch/erp-frontend/commit/36431ef45a175c989315d6fa7322dd4a85e64f4f)
- [Previous custody integration review Report669](./Report669_BUYER_CASH_AND_GOODS_CUSTODY_INTEGRATION_FORENSIC_20261109.md)
- [Previous custody hardening Report670](./Report670_BUYER_CASH_AND_GOODS_CUSTODY_HARDENING_20261109.md)
- [SupplierReturn partial acceptance analysis Report672](./Report672_BUYER_SUPPLIER_RETURN_PARTIAL_ACCEPTANCE_ACCOUNTING_FORENSIC_20261109.md)
- [PR/PO lifecycle review Report728](./Report728_DAILY_CTO_REVIEW_PR_PO_LIFECYCLE_20261116.md)
- [Procurement server guard review Report729](./Report729_DAILY_CTO_REVIEW_PROCUREMENT_SERVER_GUARDS_AND_RLS_EXPANSION_20261116.md)
- [Latest prior state Report730](./Report730_DAILY_CTO_REVIEW_DIRECT_DML_CENSUS_AND_PO_GUARDS_20261117.md)