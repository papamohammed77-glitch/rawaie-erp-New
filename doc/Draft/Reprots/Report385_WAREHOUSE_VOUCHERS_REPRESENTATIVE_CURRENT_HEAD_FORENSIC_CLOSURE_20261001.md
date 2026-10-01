# Report385 — WAREHOUSE VOUCHERS / REPRESENTATIVE COLUMN — CURRENT HEAD FORENSIC CLOSURE 2026-10-01

## 1. نطاق الجلسة

الملف الحاكم المطلوب من المالك:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

المطلوب الوظيفي:

- إظهار عمود **المندوب** في جدول **الأذونات المخزنية**.
- إظهار المندوب في **DirectSale** و **DirectReturn**.
- عدم تغيير workflow أو المخزون أو العهدة أو المحاسبة.
- عدم إنشاء Edge Function/RPC/Table جديد.
- عدم تعديل `main.html` بواسطة المساعد؛ المالك هو من يطبق المصدر عند الحاجة.

الحالة الحالية في هذه الجلسة حُسمت من:

**CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE**

والتقارير السابقة استُخدمت للاستدلال التاريخي فقط.

---

# 2. MASTER CTO GOVERNANCE / قاعدة التحقيق

تمت قراءة:

`doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`

حتى نهايته.

القواعد الحاكمة التي تم تطبيقها:

1. لا ثقة عمياء في التقارير القديمة.
2. Current Source هو مرجع الكود الفعلي.
3. Current Git يحدد النسخة.
4. Current Database يثبت العقد التشغيلي.
5. Commit ليس Deployment.
6. Deployment ليس Runtime Proof.
7. لا Closure وظيفي بلا Runtime/E2E evidence.
8. لا إعادة إصلاح لما ثبت إغلاقه.
9. الإصلاح الجراحي يجب أن يكون في العنصر المحدد، وليس إعادة كتابة الدوال كاملة.

---

# 3. CURRENT GIT — الحقيقة الحالية

Repository:

`papamohammed77-glitch/erp-frontend`

Branch:

`main`

## Current HEAD

`d5b8319b81c2236da66c25dcfc32a8f18182f249`

Message:

`forensic: persist current Mother HR extract`

Parent:

`5edf6d448203b8b431086ae762df1b35699366bf`

## Parent الذي عدّل main.html

Commit:

`5edf6d448203b8b431086ae762df1b35699366bf`

Message:

`Update voucher table to include custodian column`

Parent:

`503fb79da0878f97af46c8adad5bdedb0b3c283f`

هذا هو الـcommit الذي أدخل عمود المندوب بالفعل.

## Current main.html Blob

`4fc2adb99861031cc69decb215daac6f74d58c66`

Current source:

- 32,347 lines
- 1,755,708 characters

والـbranch `main` نفسه مثبت حاليًا على `d5b8319...`.

**النتيجة:**

الإصلاح المطلوب موجود بالفعل في Current Source.

---

# 4. التاريخ الكامل للعيب

قبل commit `5edf6d...` كان جدول الأذونات يعرض:

- رقم الإذن
- النوع
- التاريخ
- الحالة
- المرجع
- من
- إلى
- الإجراءات

وكانت `loadVouchers()` تنتهي فعليًا بـ:

`stock_vouchers → window._vouchersData → _applyVouchers()`

بدون إسقاط:

`custodian_user_id → users.id → representative name`

هذا كان **Mother UI Read-Model Projection Gap**.

Commit `5edf6d...` أصلح هذه الفجوة.

---

# 5. CURRENT SOURCE — المواضع المثبتة حاليًا

## loadVouchers()

يبدأ عند:

**السطر 14858 تقريبًا**

## Table

السطر:

**14874**

الجدول الحالي يحتوي بالفعل:

`<th class="p-3">المندوب</th>`

ويستخدم:

`colspan="9"`

## _applyVouchers()

تبدأ عند:

**14915**

والـEmpty State الحالي:

**14933**

ويستخدم:

`colspan="9"`

## Row projection

السطر:

**14941**

ويحتوي بالفعل:

`esc(v._custodian_name||'-')`

## Representative lookup

المصدر الحالي يحتوي بالفعل:

`custodian_user_id`

في:

- 14886
- 14887
- 14890
- 14907
- 14908

ويحتوي:

`_vouchersRepMap`

في:

- 14894
- 14902
- 14908

---

# 6. CURRENT SOURCE — Static Syntax Gate

تم جلب **Current main.html** من الـblob الحالي مباشرة.

تم استخراج كامل الـinline JavaScript.

النتيجة:

- Inline script count = 1
- Script size ≈ 1,736,013 chars
- Full JavaScript compilation with `new Function(...)` = **PASS**
- No syntax error in Current main.html

**STATIC SOURCE SYNTAX = PASS**

---

# 7. Semantic Projection Gate

تم تشغيل fixture منطقي مطابق للعقد الحالي:

### Fixture A

`type = DirectSale`

`custodian_user_id = 111b0730-a977-4d11-bcd0-2427b178a9e5`

النتيجة:

`مندوب مبيعات بيع مباشر`

**PASS**

### Fixture B

`type = DirectReturn`

`custodian_user_id = 1fc1a0f7-e8bf-44f4-93fb-002e8cb9cbf9`

النتيجة:

`van-sales2`

**PASS**

### Fixture C

`type = Transfer`

`custodian_user_id = null`

النتيجة:

`-`

**PASS**

### Fixture D

`type = SupplierReturn`

`custodian_user_id = null`

النتيجة:

`-`

**PASS**

كما تم التحقق من deduplication لـ `custodianIds`.

**SEMANTIC REPRESENTATIVE PROJECTION = PASS**

---

# 8. CURRENT DATABASE — Production

Supabase:

`SMART ERP`

Project ref:

`fiilmooggumokxanwiyx`

## Current voucher reality

الاستعلام الحالي أعطى:

- DirectSale = 0
- DirectReturn = 0
- Total stock_vouchers = 0

أي أن Production الحالية نظيفة من هذه السجلات.

## Current direct-sales representatives

Production الحالية تحتوي على ثلاثة مندوبي بيع مباشر Active:

1. `1fc1a0f7-e8bf-44f4-93fb-002e8cb9cbf9`
   - `van-sales2`
   - `van-sales2@rawaea.com`

2. `111b0730-a977-4d11-bcd0-2427b178a9e5`
   - `مندوب مبيعات بيع مباشر`
   - `vansales@rawaea.com`

3. `cb086d71-ba61-4392-8d3d-c4bec02ec913`
   - `مندوب مبيعات بيع مباشر 2`
   - `vansales2@rawaea.com`

وكلهم:

`permissions = ["van-sales"]`

## Owner integrity

المالك الحالي:

`owner@alrawae.com`

وهو ما زال على العقد التاريخي الصحيح:

`permissions = ["*"]`

`status = Active`

`role = مدير النظام`

ولا علاقة للجراحة الحالية بهذه الصلاحيات.

---

# 9. Database Contract

العقد التشغيلي المثبت تاريخيًا والحالي هو:

`stock_vouchers.custodian_user_id`

والمرجع:

`custodian_user_id → public.users.id`

وليس:

`vehicles.driver_id`

كما أن التطبيق التشغيلي المنفصل `warehouse/vouchers.html` يستخدم أصلًا:

`s.refs.reps`

و:

`custodian_user_id`

لربط الإذن بالمندوب.

هذا يثبت أن Mother يجب أن يستهلك نفس الحقيقة، وليس إنشاء علاقة بديلة مع السيارة.

---

# 10. Operational Application Integration

Current:

`companies/company-1/warehouse/vouchers.html`

الحالة الحالية:

- `loadList(scope)` يعتمد RPC الحالي `inventory_voucher_report`.
- `s.refs.reps) موجودة.
- `custodian_user_id) مستخدم في DirectSale/DirectReturn.
- المسؤولية التشغيلية تبقى في vouchers.html.
- النظام الأم مسؤول عن consolidated visibility.

المسار الصحيح:

**Operational Voucher**

→ `custodian_user_id`

→ `users.id`

→ Representative

→ Mother Visibility

ولا يجوز نقل مسؤولية CRUD أو stock mutation إلى Mother بسبب هذا العيب.

---

# 11. Production Mutation Decision

لا حاجة لأي تعديل Production.

سبب ذلك:

هذه الجراحة:

- SELECT فقط
- Read Projection فقط
- لا INSERT
- لا UPDATE
- لا DELETE
- لا stock mutation
- لا custody mutation
- لا accounting posting
- لا treasury posting
- لا workflow transition

إذن:

**Schema Change = NONE**

**Edge Function Change = NONE**

**RPC Change = NONE**

**Table Change = NONE**

**RLS Change = NONE**

---

# 12. DB-level Fixture بدون تلويث Production

تم تنفيذ fixture على مستوى SQL باستخدام `VALUES` مع الربط الحقيقي على `public.users`، دون كتابة سجل دائم.

نتائج الربط:

| Type | Fixture representative |
|---|---|
| DirectSale | مندوب مبيعات بيع مباشر |
| DirectReturn | van-sales2 |
| Transfer | - |
| SupplierReturn | - |

Current Production بعد الاختبار:

- DirectSale = 0
- DirectReturn = 0
- Total stock_vouchers = 0

لا توجد QA residues.

**PERMANENT TEST DATA = 0**

**CLEANUP REQUIRED = 0**

السبب: الـfixture كان ephemeral/read-only ولم ينشئ سجلات دائمة.

---

# 13. سبب عدم إعادة اختبار Transactional E2E

التعليمات التاريخية تمنع إعادة تشغيل اختبار تم إغلاقه بالفعل دون سبب.

العقد التشغيلي DirectSale / DirectReturn / Receive تم إثباته في Report382، وتأكدت التقارير اللاحقة من عدم إعادة فتحه.

كما أن الجراحة الحالية لا تغير:

- start
- send
- receive
- stock movement
- custody
- audit
- accounting

لذلك إعادة تشغيل transactional mutation E2E بسبب عمود UI فقط ليست إصلاحًا ولا تحققًا ذا قيمة.

هذا يتماشى مع قاعدة:

**Never re-fix what is proven closed.**

---

# 14. CURRENT GitHub Actions Evidence

Commit `5edf6d...` شغّل:

**RAWAEA — Mother System Browser E2E**

Run:

`36907835220`

على:

`5edf6d448203b8b431086ae762df1b35699366bf`

النتيجة:

**FAIL**

لكن الفشل لم يكن في عمود المندوب.

الخطوات:

- Mother shell infrastructure syntax = PASS
- Known route JSON syntax = PASS
- RW_HR payroll syntax assertion = FAIL
- Install Playwright = SKIPPED
- Browser E2E = SKIPPED

الـfailure exact:

`AssertionError: Canonical RW_HR payroll syntax not present`

إذن الاختبار **لم يصل أصلًا إلى Playwright**.

هذا العيب في HR غير مرتبط بوحدة vouchers، ولم يتم لمسه عمدًا حتى لا يتحول إصلاح جراحي إلى تغيير خارج النطاق.

### Current HEAD `d5...`

الـcommit الحالي بعد ذلك غيّر فقط:

`_forensic_current_main_extract.md`

ولم يغير `main.html`.

ولا توجد في نتائج endpoint الخاص بـPR-triggered workflow run دلائل منفصلة على Browser E2E ناجح لـ`d5...`.

**BROWSER E2E FOR THIS UNIT = OPEN**

---

# 15. Deployment Evidence

لا يوجد في الأدلة الحالية proof كافٍ على أن served artifact الخاص بالـproduction يحمل blob:

`4fc2adb99861031cc69decb215daac6f74d58c66`

لذلك لا يجوز إغلاق Runtime Production UI.

التسلسل الصحيح:

`Current Git`

→ `Build/Deploy`

→ `Served Artifact`

→ `Browser Runtime`

وهذا لم يُثبت بعد.

إذا كان المستخدم يرى أن عمود المندوب غير موجود في Production مع أن Git الحالي يحتويه، فإن السبب المتبقي يصبح خارج source correction، وأقربه:

- deployed artifact drift
- stale publish
- cache/service-worker
- served HTML ليس من Current HEAD

ولا يجب إعادة تعديل المصدر قبل إثبات served artifact.

---

# 16. العنصر المعيب الذي كان يجب حذفه

## مهم

**Current HEAD لم يعد يحتوي العنصر المعيب.**

العنصر المعيب كان موجودًا في parent:

`503fb79da0878f97af46c8adad5bdedb0b3c283f`

وتم حذفه بالفعل في:

`5edf6d448203b8b431086ae762df1b35699366bf`

لذلك:

**إذا كان ملفك المحلي مطابقًا لـCurrent HEAD `4fc2adb...` فلا تحذف أي شيء ولا تطبق الجراحة مرة أخرى.**

إذا كان ملفك المحلي قديمًا ومطابقًا للـparent، فطبّق العناصر الأربعة التالية فقط.

---

# 17. OWNER SURGICAL PATCH — PATCH 1

## الملف

`companies/company-1/main.html`

## الدالة

`async function loadVouchers()`

## الموضع

حوالي السطر **14879**

## ابحث حرفيًا عن هذا العنصر

```js
var res = await supabase.from('stock_vouchers').select('*').eq('company_id', companyId).order('voucher_date', { ascending: false });
window._vouchersData = res.data || [];
_applyVouchers();
```

## احذفه كاملًا.

## واستبدله كاملًا بهذا

```js
var res = await supabase.from('stock_vouchers').select('*').eq('company_id', companyId).order('voucher_date', { ascending: false });
        if (res.error) throw res.error;
        var voucherRows = res.data || [];
        var custodianIds = [];
        var custodianSeen = Object.create(null);
        for (var vi = 0; vi < voucherRows.length; vi++) {
            var voucher = voucherRows[vi];
            if ((voucher.type === 'DirectSale' || voucher.type === 'DirectReturn') && voucher.custodian_user_id) {
                var custodianKey = String(voucher.custodian_user_id);
                if (!custodianSeen[custodianKey]) {
                    custodianSeen[custodianKey] = true;
                    custodianIds.push(voucher.custodian_user_id);
                }
            }
        }
        window._vouchersRepMap = Object.create(null);
        if (custodianIds.length) {
            var repsRes = await supabase.from('users')
                .select('id,name,email')
                .eq('company_id', companyId)
                .in('id', custodianIds);
            if (repsRes.error) throw repsRes.error;
            (repsRes.data || []).forEach(function(rep) {
                window._vouchersRepMap[String(rep.id)] = rep.name || rep.email || '';
            });
        }
        window._vouchersData = voucherRows.map(function(v) {
            var isDirectVehicleVoucher = v.type === 'DirectSale' || v.type === 'DirectReturn';
            v._custodian_name = isDirectVehicleVoucher && v.custodian_user_id
                ? (window._vouchersRepMap[String(v.custodian_user_id)] || '-')
                : '-';
            return v;
        });
        _applyVouchers();
```

---

# 18. OWNER SURGICAL PATCH — PATCH 2

## الدالة

`loadVouchers()`

## الموضع

حوالي السطر **14874**

## ابحث حرفيًا عن الجزء

```html
<th class="p-3">إلى</th><th class="p-3 text-center">إجراءات</th></tr></thead><tbody id="vouchers-tbody"><tr><td colspan="8" class="text-center py-8">جاري التحميل...</td></tr>
```

## احذفه.

## واستبدله بهذا

```html
<th class="p-3">إلى</th><th class="p-3">المندوب</th><th class="p-3 text-center">إجراءات</th></tr></thead><tbody id="vouchers-tbody"><tr><td colspan="9" class="text-center py-8">جاري التحميل...</td></tr>
```

---

# 19. OWNER SURGICAL PATCH — PATCH 3

## الدالة

`function _applyVouchers()`

## الموضع

حوالي السطر **14933**

## ابحث حرفيًا عن

```js
if (!d.length) { safeHTML(tb, '<tr><td colspan="8" class="text-center py-8">لا توجد أذونات</td></tr>'); return; }
```

## احذفه.

## واستبدله بهذا

```js
if (!d.length) { safeHTML(tb, '<tr><td colspan="9" class="text-center py-8">لا توجد أذونات</td></tr>'); return; }
```

---

# 20. OWNER SURGICAL PATCH — PATCH 4

## الدالة

`function _applyVouchers()`

## الموضع

حوالي السطر **14941**

## ابحث حرفيًا عن السطر

```js
return '<tr class="hover:bg-gray-50"><td class="p-3 font-bold text-indigo-700">' + (v.voucher_code||'') + sourceIndicator + '</td><td class="p-3">' + (v.type||'') + '</td><td class="p-3">' + (v.voucher_date||'') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs ' + statusBadge + '">' + (v.status||'') + '</span></td><td class="p-3">' + (v.reference||'-') + '</td><td class="p-3">' + (v.from_id||'-') + '</td><td class="p-3">' + (v.to_id||'-') + '</td><td class="p-3 text-center">' + actions + '</td></tr>';
```

## احذفه كاملًا.

## واستبدله بهذا

```js
return '<tr class="hover:bg-gray-50"><td class="p-3 font-bold text-indigo-700">' + (v.voucher_code||'') + sourceIndicator + '</td><td class="p-3">' + (v.type||'') + '</td><td class="p-3">' + (v.voucher_date||'') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs ' + statusBadge + '">' + (v.status||'') + '</span></td><td class="p-3">' + (v.reference||'-') + '</td><td class="p-3">' + (v.from_id||'-') + '</td><td class="p-3">' + (v.to_id||'-') + '</td><td class="p-3">' + esc(v._custodian_name||'-') + '</td><td class="p-3 text-center">' + actions + '</td></tr>';
```

---

# 21. لا تستبدل أي Function كاملة

ممنوع في هذه الجراحة:

- استبدال `loadVouchers()` كاملة.
- استبدال `_applyVouchers()` كاملة.
- تعديل `_viewVoucherDetails()`.
- تعديل `_sendVoucher()`.
- تعديل `_receiveVoucher()`.
- تعديل `_openNewVoucherModal()`.
- تعديل `warehouse/vouchers.html`.
- تعديل `van-sales.html`.
- تعديل backend.

المطلوب فقط:

**4 substitutions جراحية.**

والأهم:

**Current HEAD already contains them.**

---

# 22. Workflow / Stock / Custody / Accounting Impact

الـUI projection الجديدة تقرأ:

`stock_vouchers`

وتقرأ:

`users`

ولا تكتب شيئًا.

الأثر المتوقع بعد تطبيقها:

| المجال | الأثر |
|---|---:|
| Branch stock | 0 |
| Vehicle stock | 0 |
| Allocated stock | 0 |
| Custody balance | 0 |
| Inventory log | 0 |
| Driver ledger | 0 |
| General journal | 0 |
| Customer ledger | 0 |
| Supplier ledger | 0 |
| Treasury | 0 |
| Voucher status | 0 |
| Workflow | 0 |

هذا ليس مجرد توقع تصميمي؛ السبب أن الكود الجديد هو read projection فقط.

---

# 23. Full operational E2E contract protected

العقد الذي ثبت تاريخيًا ولم يتغير:

## DirectSale

Branch

→ DirectSale Voucher

→ Mobile/Vehicle custody

## DirectReturn

Vehicle/Mobile

→ DirectReturn

→ Branch

والـReceive يعيد الكمية للفرع وفق العقد المثبت.

هذه الجراحة لا تتدخل في:

- movement posting
- custody debit/credit
- journal creation
- settlement
- vehicle assignment
- Master Assignment

ولا تعيد فتح إصلاحات Report359 / Report360 / Report382.

---

# 24. Competitive benchmark

## Odoo

Odoo 19 يجعل سجل حركة المخزون قابلًا للتحقيق ويربط الحركة بالتاريخ والمرجع والمنتج والدفعة/السيريال ومن/إلى والحالة، كما يعرض نقل المسؤولية حسب الموظف في لوحات المتابعة.

Official:

https://www.odoo.com/documentation/19.0/ar/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/moves_history.html

https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/dashboards.html

https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html

## Microsoft Dynamics 365

يوثق النقل باعتباره حركة لها From/To dimensions وتنتج عنها inventory transactions قابلة للمراجعة.

Official:

https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/warehouse-transactions

## SAP

Goods issue / movement workflow يفصل الحركة الفعلية عن سجل المستند ويجعل أثر المخزون جزءًا من العملية التشغيلية.

## Daftra / Manager.io

توجد لديهما نماذج تربط المستودع/الموظف وحركة المخزون بالتقرير والمسؤولية التشغيلية.

### نتيجة المقارنة

إضافة المندوب إلى سجل الأذونات ليست تجميلًا.

إنها **Audit Dimension** مهمة، خصوصًا في RAWAEA لأن السيارة ليست وحدها كيان العهدة؛ المسؤول الفعلي في DirectSale / DirectReturn هو المندوب المرتبط بـ`custodian_user_id`.

لكن لا يتم هنا توسيع النطاق إلى:

- Lot/Serial
- Expiry
- Stock Before/After
- Attachments
- Approval SLA
- Exception queue
- Timeline

فهذه Business Capabilities مستقلة.

---

# 25. Security / Tenant Integrity

الـlookup الحالي محصور على:

`company_id = companyId`

والمندوب يتم جلبه بواسطة:

`users.id IN (custodianIds)`

وهذا أفضل من:

- تحميل جميع المستخدمين.
- استخدام `vehicles.driver_id`.
- خلط الشركة الحالية بشركة أخرى.
- إعادة بناء users map كامل.

ولا توجد حاجة لتعديل RLS في هذه الوحدة.

---

# 26. مشكلة الوصول التي تسببت في الفشل السابق

التقرير السابق كان يحوي Anchors تخص مصدرًا آخر.

الخطأ التاريخي كان:

`Current/PWA/main.html`

بينما الملف الذي طلبه المالك هو:

`erp-frontend/companies/company-1/main.html`

لذلك:

- Anchor قديم ≠ Current Target
- Report384 كان يحتوي بالفعل التصحيح المنطقي
- لكن Current Git بعد ذلك أصبح يحتوي التصحيح فعلًا

**هذه الجلسة لا تعيد إنتاج خطأ البحث في مسار غير صحيح.**

---

# 27. Final forensic decision

## Root Cause — CLOSED

Mother UI projection gap كان هو السبب الأصلي.

## Current Source — CLOSED

Current main.html يحتوي الإصلاح بالفعل.

## Database Contract — CLOSED

`custodian_user_id → users.id` صحيح.

## Production Data — CLEAN

DirectSale = 0

DirectReturn = 0

Total vouchers = 0

## Static Syntax — PASS

Current main.html full inline JavaScript = PASS.

## Semantic Projection — PASS

DirectSale = Representative

DirectReturn = Representative

Other voucher types = -

## Production Mutation

غير مطلوبة.

## Main.html modification by assistant

**لم تُنفذ.**

## Browser E2E

**OPEN**

لأن GitHub Actions توقفت في فحص HR قبل Playwright.

## Served Artifact

**OPEN**

لا يوجد إثبات حالي بأن Production serving الـblob `4fc2adb...`.

---

# 28. EXACT NEXT ACTION — للمالك

### الحالة A — ملفك المحلي يطابق Current HEAD

Current blob:

`4fc2adb99861031cc69decb215daac6f74d58c66`

**لا تعدل main.html.**

انتقل مباشرة إلى:

**Publish / Deploy → Served Artifact Verification → Browser E2E**

### الحالة B — ملفك المحلي قديم

ابحث عن العناصر الأربعة أعلاه.

نفّذ:

**احذف → استبدل**

فقط.

ثم:

1. Full inline JS syntax gate.
2. Commit.
3. Publish.
4. Verify served artifact.
5. Browser E2E.
6. Verify DirectSale representative.
7. Verify DirectReturn representative.
8. Verify Transfer = -
9. Verify SupplierReturn = -
10. Close only after runtime evidence.

---

# 29. Instructions to the next assistant

لا تبدأ من الصفر.

ابدأ بهذا الترتيب:

1. Read `CURRENT_STATE.md` حتى آخر Append.
2. Verify frontend HEAD.
3. Verify main.html blob.
4. Verify that `5edf6d...` already introduced representative column.
5. Do not reapply the four patches if Current Source matches blob `4fc2adb...`.
6. If a local copy is older, apply only PATCH 1→4 above.
7. Do not modify backend.
8. Do not create Edge Function/RPC/Table.
9. Do not reopen DirectReturn Receive.
10. Do not reopen Master Assignment.
11. Do not reopen owner wildcard.
12. Do not repair unrelated HR syntax as part of this unit.
13. Verify deployment.
14. Run browser E2E only after served artifact is proven.
15. Only then close the unit.

---

# 30. SELF AUDIT

### Proven

- correct repository
- correct branch
- current HEAD
- parent commit
- parent-of-parent
- current main.html blob
- exact existing representative column
- exact existing lookup
- full inline JS syntax
- semantic mapping
- production representative records
- production voucher count
- owner wildcard integrity
- operational vouchers integration
- no required schema change
- no required Edge Function
- no required RPC
- no required RLS change

### Not Proven

- current served Production artifact
- Browser-rendered Production UI after publish
- Browser E2E against the final served artifact

### Not Changed

- main.html by assistant
- vouchers.html
- van-sales.html
- Edge Functions
- RPCs
- tables
- RLS
- stock workflow
- accounting workflow
- custody workflow

---

# 31. END STATE

**The source defect is already corrected in Current Git.**

The remaining problem, if the user still cannot see the representative column, is no longer a missing code patch in `main.html`.

The next evidence to obtain is:

**CURRENT SERVED ARTIFACT → BROWSER RUNTIME**

and not another source rewrite.

# END OF REPORT 385
