# تقرير 122 — المراجعة الجنائية وإعادة فحص Main3
## RAWAEA ERP — Main3 Forensic Recheck / Gold-Diamond Functional Gate

> **الهدف الحاكم — إعادة التأكيد:** هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يجوز التعامل معه كإضافات شكلية.
>
> وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا → إعادة بناء العقد التاريخي → تتبع السلوك الحالي → تتبع البيانات والصلاحيات والتدفق → تحديد الفجوة الفعلية → التعديل الجراحي → الاختبار → التحقق من Production → التوثيق.

---

## 1. نطاق الجلسة

تم إيقاف مسار المهمة السابق والتركيز على `Current/PWA/main2/main3.md` مع فحص Production للقدرات التي يعتمد عليها Main3.

لم يتم تعديل:
- `Current/PWA/main2/main3.md` بواسطة المساعد.
- `Current/PWA/main2/main1.md ... main11.md` كمصدر Owner باستثناء أداة التحقق المساعدة.
- `Current/PWA/New-main`.
- `Original/PWA/main`.
- أي Assembly نهائي.

Main3 remains Owner-editable; Production Edge Functions remain assistant-managed.

---

## 2. المصادر الفعلية التي تم التحقق منها

تم الرجوع مباشرة إلى:

1. `doc/Draft/Reprots/Report121_Main2_Forensic_Recheck_20260911.md`.
2. `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`.
3. `CURRENT_STATE.md`.
4. `Current/PWA/main2/main3.md` من البداية حتى EOF.
5. `Original/PWA/main/main3.md` كمرجع تاريخي فقط.
6. Production Supabase: schema, constraints, policies, triggers, Edge Functions.
7. Git history والـcurrent tree.

التقارير السابقة لم تُعامل كمصدر حقيقة؛ استخدمت فقط لتحديد ما يجب إعادة إثباته.

---

## 3. Main3 — البنية التي تم إثباتها

Main3 يحتوي على الوحدات التالية:

- `RW_Customers` — العملاء.
- `RW_Suppliers` — الموردون.
- `RW_Branches` — الفروع والمخازن.
- `RW_Settings` — إعدادات النظام والفوترة.
- `RW_Users` — المستخدمون والصلاحيات وتعيين العملاء.

الملف يصل حتى نهاية `RW_Users` ولا توجد فيه عبارة `(قيد التطوير)` مثبتة في القراءة الحالية، لكن الفحص أظهر أن عدة أجزاء ما زالت CRUD/basic master-data وليست Gold/Diamond functional depth.

---

## 4. Production Truth — ما تم إثباته

### Customer / Supplier / Branch / Employee capabilities

الـEdge Functions الحالية في Production أصبحت بعد هذه الجلسة:

- `save-customer` — version 4.
- `delete-customer` — version 3.
- `save-supplier` — version 4.
- `delete-supplier` — version 3.
- `save-branch` — version 4.
- `delete-branch` — version 3.
- `save-employee` — version 8.
- `delete-employee` — version 3.
- `save-settings` — version 13.

### ما تم إصلاحه فعليًا

#### 4.1 Customer
تم إغلاق:
- غياب permission gate عن الحفظ.
- غياب company context الصحيح.
- التعامل مع المستخدم Inactive.
- حذف Master Data التاريخية بلا حماية.

الحذف أصبح soft-deactivation عندما توجد history في orders / customer ledger / credit records، مع hard delete فقط عند عدم وجود history.

#### 4.2 Supplier
تم إغلاق:
- permission/company scoping.
- حماية التاريخ المالي.
- الحذف أصبح deactivation عند وجود purchase/ledger history.

#### 4.3 Branch
تم إغلاق:
- permission/company scoping.
- hard delete غير الآمن.
- تعطيل الفرع الرئيسي مباشرة من الشاشة.

#### 4.4 Employee
تم إغلاق:
- غياب permission gate عن `save-employee`.
- حفظ `allowed_branch_ids` الآن يقبل JSON array مع الحفاظ على wildcard `['*']`، مع التوافق مع القيمة النصية التاريخية.
- تعديل حساب المالك من شاشة المستخدمين ممنوع.
- `delete-employee` أصبح deactivation وليس حذفًا مباشرًا، company-scoped، مع حماية self/owner.

---

## 5. Schema Truth الذي حَكَم القرارات

### 5.1 Item identity
`items.item_code` لديه constraint رسمي `UNIQUE` عالميًا. لذلك لا يجوز اعتبار `company_id + item_code` مفتاح الهوية الأساسي للصنف ما لم يثبت Contract مختلف.

### 5.2 Customer assignments
`customer_assignments` لا يحتوي `company_id` مستقلًا، لكن Production RLS يفرض ارتباط customer بالشركة الحالية ويشترط permission `customers` للإدارة. لذلك لم تتم إضافة company_id مصطنع إلى الجدول.

### 5.3 Users branches
`users.allowed_branch_ids` نوعه `jsonb`، بينما Main3 كان يرسله كـCSV:
`selectedBranches.join(',')`
وهذا تم إثباته كـschema mismatch فعلي.

### 5.4 Historical deletion safety
Branches/customers/suppliers/users لها references تشغيلية ومالية متعددة؛ لذلك deactivation هو السلوك الآمن عند وجود history، وليس hard delete.

---

## 6. Owner Source Surgeries — Main3

> **مهم:** هذه التعديلات لم ينفذها المساعد داخل `Current/PWA/main2/main3.md` طبقًا لحدود Owner. المطلوب من المالك تنفيذها يدويًا.

### MAIN3-N1 — allowed_branch_ids JSON contract

**الموضع:** السطر `870` في `Current/PWA/main2/main3.md`.

ابحث عن السطر كاملًا:

`allowed_branch_ids: selectedBranches.join(','),`

احذف هذا السطر كاملًا واستبدله بالسطر:

```javascript
                        allowed_branch_ids: selectedBranches,
```

هذا التغيير ضروري لأن Production/schema يعامل الحقل كـJSONB array، والـ`save-employee` الحالي أصبح يحفظه بصيغة قانونية.

---

### MAIN3-N2 — branch deletion label must match actual Production behavior

**الموضع:** السطر `336` تقريبًا داخل `RW_Branches.openModal`.

ابحث عن المقطع الكامل الذي يحتوي:

```javascript
${isEdit ? '<button type="button" id="btn-delete-branch" class="px-5 py-2.5 bg-red-600 text-white rounded-xl font-bold mr-auto"><i class="fas fa-trash-alt ml-1"></i> حذف</button>' : ''}
```

احذف السطر كاملًا واستبدله بـ:

```javascript
${isEdit ? '<button type="button" id="btn-delete-branch" class="px-5 py-2.5 bg-red-600 text-white rounded-xl font-bold mr-auto"><i class="fas fa-ban ml-1"></i> تعطيل الفرع</button>' : ''}
```

السبب: Production `delete-branch` لا يحذف الفرع؛ هو deactivation ويحافظ على التاريخ.

---

### MAIN3-N3 — customer financial balance must not look like an ordinary master-data edit

**الموضع:** السطر `64` داخل `RW_Customers.openModal`.

ابحث عن السطر كاملًا:

```html
<div class="flex flex-col"><label>الرصيد الحالي (EGP)</label><input id="cust-debt" type="number" value="${c?.debt||0}" class="p-2.5 bg-gray-50 border rounded-lg"></div>
```

احذفه كاملًا واستبدله بـ:

```html
<div class="flex flex-col"><label>الرصيد الحالي (EGP)</label><input id="cust-debt" type="number" value="${c?.debt||0}" readonly disabled class="p-2.5 bg-gray-100 border rounded-lg text-gray-600 cursor-not-allowed"><p class="text-xs text-gray-500 mt-1">الرصيد المالي يُعرض للقراءة فقط ولا يتم تعديله من بيانات العميل الأساسية.</p></div>
```

لا يتم حذف الحقل من payload في هذه المرحلة حتى لا ينكسر Consumer قديم؛ لكن الواجهة لا تعرضه كحقل إدخال قابل للتعديل.

---

### MAIN3-N4 — supplier payable balance must not look like an ordinary master-data edit

**الموضع:** السطر `209` داخل `RW_Suppliers.openModal`.

ابحث عن السطر كاملًا:

```html
<div class="flex flex-col"><label>الرصيد الدائن (EGP)</label><input id="supp-balance" type="number" value="${s?.accounts_payable||0}" class="p-2.5 bg-gray-50 border rounded-lg"></div>
```

احذفه كاملًا واستبدله بـ:

```html
<div class="flex flex-col"><label>الرصيد الدائن (EGP)</label><input id="supp-balance" type="number" value="${s?.accounts_payable||0}" readonly disabled class="p-2.5 bg-gray-100 border rounded-lg text-gray-600 cursor-not-allowed"><p class="text-xs text-gray-500 mt-1">الرصيد المالي يُعرض للقراءة فقط ولا يتم تعديله من بيانات المورد الأساسية.</p></div>
```

كما في العميل، لا يتم تغيير الـpayload في هذه المرحلة حفاظًا على compatibility؛ المنع هنا UI safety gate إلى أن يُغلق مسار opening balance المالي بعقد مستقل مثبت.

---

## 7. ما لم أغيّره عمدًا

### Settings
لم تتم إضافة إعدادات جديدة غير مثبتة في schema أو historical contract. الموجود حاليًا يغطي delivery fee / minimum invoice / tax / currency / company identity / VAT-ZATCA fields، ولذلك لم يتم اختراع حقول أو workflow مالي جديد داخل Main3.

### Customer assignments
لم تتم إعادة تصميمها؛ Production RLS الحالي يثبت company isolation وpermission enforcement، والمسار الحالي يمكن الاستمرار به.

### Historical owner semantics
لم يتم تغيير wildcard `['*']` أو Owner semantics.

### Inventory / Order / Runsheet
لم يتم العبث بأي lifecycle مخزني أو order/runsheet writer في هذه الجلسة، لأن Main3 لا يملك Contract حركة مخزنية حاكمًا لها.

---

## 8. Main3 Gold/Diamond functional gate

النقص الحالي المثبت ليس في Syntax بل في depth الوظيفي.

النسخة الحالية توفر CRUD أساسيًا، لكنها تحتاج في مرحلة استكمال Main3 إلى وظائف أعمال مرتبطة مباشرة بالمصادر الحالية، وليس placeholders:

### Customers
- كشف حساب فعلي من `customer_ledger`.
- تاريخ الطلبات والمرتجعات.
- حالة الائتمان وسلوك السداد.
- إبراز العملاء غير النشطين/المتعثرين.
- ربط التعيينات والزيارة مع التطبيق الميداني.

### Suppliers
- كشف حساب فعلي من `supplier_ledger`.
- تاريخ أوامر الشراء والاستلامات.
- aging/payables analysis مبني على البيانات الفعلية.

### Branches
- snapshot تشغيلي للفروع.
- إجمالي stock quantities لكل فرع.
- ربط الفرع بالتطبيقات/السيارات عند ثبوت contract المناسب من الأجزاء الأخرى.

### Users
- الإبقاء على permission matrix الحالية.
- company-scoped branches.
- JSONB `allowed_branch_ids`.
- customer assignments.
- Owner protection.

هذه العناصر ليست placeholders مقترحة نظريًا؛ عند استكمالها يجب أن تستخدم الجداول والـRPC/Edge contracts الموجودة فعليًا، ولا تُبنى على بيانات وهمية.

---

## 9. Syntax / validation

تمت مراجعة `main3.md` من البداية إلى EOF. لم يظهر في النص الحالي نقص واضح في الأقواس/إغلاق IIFE أو عبارة `(قيد التطوير)`.

لكن الـworkflow القديم كان لا يفحص Main1–Main11 كاملًا. لذلك تم إصلاح:

`.github/workflows/validate-main2-fragments.yml`

بحيث يقوم صراحة بـ:

- `node --check` لـMain1 حتى Main11.
- التحقق من وجود الملفات الـ11 جميعًا.

### CI limitation
لم يظهر في GitHub connector Run قابل للاعتماد يثبت تنفيذ هذا الـworkflow بعد commit `b1148d6...`؛ لذلك لا أعتبر CI PASS حقيقة مثبتة. هذا يمنع ادعاء syntax CI-verified كامل من هذه الجلسة.

---

## 10. Assembly Source Truth

كان `forensic_main_assembly.yml` غير مثبت الوجود في root، لذلك تم إنشاؤه في root بالمصدر الصحيح:

`Current/PWA/main2`

مع fragments:

`main1.md ... main11.md`

وتم تسجيل:
- `Original/PWA/main` = historical reference.
- `Current/PWA/main` = forbidden source.
- `Current/PWA/New-main` = forbidden historical stage.
- Assembly remains deferred.

---

## 11. التجارب والنتائج

### Production
- تحقق versions للقدرات الرئيسية عبر `list_edge_functions`.
- تحققت schema/constraints/RLS قبل تعديل السلوك.
- Customer/Supplier/Branch/Employee edge capabilities تم نشرها بنجاح.

### Negative/compatibility reasoning
- حماية owner confirmed قبل employee mutation.
- branch deactivation يمنع تعطيل main branch.
- history-bearing customers/suppliers deactivate rather than delete.
- allowed branches normalized to JSONB-compatible representation.

### Tests not claimed as full E2E
لم تُنفذ جلسة browser E2E كاملة لـMain3 لأن التعديل على Main3 نفسه Owner-boundary ولم يتم دمجه في ملف النشر النهائي. لذلك لا يوجد ادعاء بأن الـUI بعد Owner surgery أصبح Production E2E verified.

---

## 12. ما تم اكتشافه أثناء العمل ولم يُخفَ

1. الـworkflow القديم لم يكن يغطي Main1–Main11.
2. `allowed_branch_ids` كان يُرسل CSV رغم أن schema JSONB.
3. Employee save كان بلا permission gate في Production.
4. Employee delete كان hard-delete وغير company-scoped بصورة كافية.
5. Branch/customer/supplier delete semantics في الواجهة كانت توحي بـhard delete بينما Production الآمن يجب أن يحافظ على history.
6. Customer/Supplier balance fields كانت تظهر كمدخلات عادية دون عقد opening balance مستقل مثبت.
7. Main3 نفسه ما زال CRUD-heavy؛ إغلاق الشكل لا يساوي Gold/Diamond completion.

---

## 13. Self-Audit

### What I Proved
- Main3 الحالي هو `Current/PWA/main2/main3.md` والـblob الحالي `479060e3...`.
- Production capabilities المقابلة active ومراجعة.
- `allowed_branch_ids` JSONB.
- customer_assignments محكومة بـRLS company/permission.
- branch/customer/supplier deletion يجب أن يحافظ على history.
- owner wildcard semantics يجب عدم المساس بها.

### What I Did Not Prove
- Browser E2E كامل بعد تطبيق Owner changes.
- CI `node --check` ناجح على Main1–Main11 بعد آخر workflow update؛ لا يوجد Run موثوق ظاهر عبر connector.
- Gold/Diamond completeness لكل functions المستقبلية للـfinance/HR/CRM/reports، لأن تلك الأجزاء ليست داخل Main3 وحده.

### What I Fixed
- Production save/delete customer.
- Production save/delete supplier.
- Production save/delete branch.
- Production save/delete employee.
- Main2 validation workflow coverage.
- Main assembly source-of-truth file.

### Final Closure Status
`MAIN3 FORENSIC RECHECK = COMPLETED`

`MAIN3 OWNER SURGERY = REQUIRED`

`MAIN3 GOLD/DIAMOND FUNCTIONAL COMPLETION = NOT YET CLOSED`

`FINAL ASSEMBLY = DEFERRED`

هذا ليس فشلًا في المهمة؛ بل منع متعمد من إعلان اكتمال غير مثبت قبل دمج Owner changes ثم إعادة الاختبار.

---

## 14. Session handoff

الجلسة التالية تبدأ من:

`Current/PWA/main2/main3.md`

وتنفذ بالضبط:

`MAIN3-N1 → MAIN3-N2 → MAIN3-N3 → MAIN3-N4`

ثم يُعاد فحص Main3 كاملًا بعد تطبيق التغييرات، وبعدها ينتقل العمل إلى الوظائف Gold/Diamond التي لها contracts مثبتة، دون إعادة فتح الأجزاء التي ثبتت صحتها.
