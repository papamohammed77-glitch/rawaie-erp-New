# Report 344 — التحقيق الجنائي النهائي لملف الأذونات المخزنية / SupplierReturn + إصلاح Syntax Regression
## التاريخ: 2026-09-27
## النطاق: companies/company-1/warehouse/vouchers.html فقط من ناحية Source Patch؛ Production/Supabase مباشرة
## القيود: main.html غير ملامس — vouchers.html غير ملامس — van-sales.html غير ملامس — لا Edge Function جديدة

---

# 1. Executive Closure

تم استرجاع الحالة من المصادر الحالية وليس من التقارير وحدها.

النتيجة الحاسمة:

- Production Business Contract لمسار SupplierReturn موجود ومكتمل.
- Production RLS/ACL للموردين وContract RPC موجود ومطبق.
- قاعدة البيانات تحتوي جميع الحقول والعلاقات والـvaluation المطلوبة.
- الوظائف الحالية تكفي؛ لم تُنشأ Edge Function جديدة.
- مسار SupplierReturn الحالي ما زال مستقلًا عن Orders / Run Sheets كما هو مقصود معماريًا.
- العيب الحالي الذي يمنع تشغيل vouchers.html ليس عيبًا في الـBusiness Contract ولا في Supabase.
- **العيب الفعلي هو Regression نحوي في المصدر عند الموضع 2986.**
- Regression أُدخل في commit:
  `4a322fa793027f8584d9f0d55638ef5a14aebc03`
- الـsource الحالي عند HEAD:
  `2203768d8fd3f58a2fa0b378c45494b0741be9cd`
  وبصمة ملف vouchers.html الحالية:
  `306cb0ddf6e922951a8a164d9a7818728c6cb0da`
- بعد تطبيق التصحيح الجراحي المقترح في الذاكرة، تم تحليل JavaScript المضمّن مرة أخرى: **6/6 scripts PASS**.
- تم تنفيذ اختبارين إضافيين للـContract عبر RPC authenticated داخل معاملات مع rollback:
  1. PO + Purchase Invoice اختياريان.
  2. Purchase Invoice فقط بدون PO لمسار الشراء المباشر.
- تم إنشاء Fixture دائم جديد في Production لتجربة Browser E2E اللاحقة، ولم يتم حذفه.
- لم يتم تغيير أي جدول لأن Production الحالي يحتوي بالفعل على العقد الصحيح؛ إنشاء بنية جديدة كان سيصنع Duplicate Truth.
- لم يتم تعديل Edge Function؛ تم استخدام الـRPC القائم مباشرة.

الحالة الوحيدة المتبقية بعد هذه الجلسة:
**Owner Source Patch + Browser E2E + Published Artifact Verification.**

---

# 2. مصادر الحقيقة التي تم اعتمادها

ترتيب التحقيق:

CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT EVIDENCE

التقارير السابقة استُخدمت كـHistorical Evidence فقط.

## 2.1 System Repository

Repository:

`papamohammed77-glitch/rawaie-erp-New`

Latest commit الذي كان قائمًا قبل هذا التقرير:

`d89cbfaa475adaf9a05c3f3c9a5bec7e4f163d16`

والـparent الذي يشير إلى آخر تقرير/حالة تنفيذية مصححة:

`db654788af5f4e7639d816ebda97182356b47a72`

Current CURRENT_STATE السابق كان قد أشار إلى db654، بينما التحقيق الحالي أثبت أن d89 هو الرأس الحالي؛ لذلك تم اعتبار d89 هو CURRENT GIT الحقيقي.

## 2.2 Mother / Frontend Repository

Repository:

`papamohammed77-glitch/erp-frontend`

Current HEAD:

`2203768d8fd3f58a2fa0b378c45494b0741be9cd`

Parent:

`4a322fa793027f8584d9f0d55638ef5a14aebc03`

Current `vouchers.html` blob:

`306cb0ddf6e922951a8a164d9a7818728c6cb0da`

Current `van-sales.html` blob:

`8d61382a8e0025a0d079e71dd94f33d106d9088e`

Current `main.html` blob:

`810e4f5440f5975f55099a124deb42b086a49183`

Current `app.html` blob:

`ec75f89c11620f6e8b8ef5996cf1a3289dcf20b4`

ملاحظة جنائية مهمة:

رسالة commit `2203768...` تقول:

`Update print statement from 'Hello' to 'Goodbye'`

لكن diff الفعلي لا يمثل هذا الوصف وحده، بل يحتوي تعديلات SupplierReturn/Contract واسعة.

القاعدة المعتمدة هنا:
**commit message غير مصدر حقيقة؛ file content + blob + parent history هو المصدر.**

---

# 3. التحقيق التاريخي للـRegression

## 3.1 الحالة السليمة السابقة

تم فحص نسخ تاريخية من vouchers.html.

في:

`fce3dfaa0503957791113a5ebf57d402a4a82764`

كان embedded script رقم 6:

**PASS**

وفي:

`666f15bc84348b6fb44a5c565dcf2fb4fe1d0c98`

كان embedded script رقم 6:

**PASS**

أما في commit:

`4a322fa793027f8584d9f0d55638ef5a14aebc03`

فأصبح embedded script رقم 6:

**FAIL**

بنفس الخطأ:

`Function statements require a function name`

ثم استمر العيب في HEAD الحالي `2203768...`.

إذن causal chain المثبت:

Previous valid source
→ commit 4a322
→ deletion of pickArr closing segment
→ parser state corrupted
→ pickShow:function becomes illegal function statement
→ whole App object script fails
→ login page may appear but post-login application logic never initializes correctly
→ Supplier search / dropdown / workspace / contract buttons never become operational.

---

# 4. Root Cause النهائي — الموضع المحدد

## الملف

`companies/company-1/warehouse/vouchers.html`

## الدالة

`pickArr:function(key)`

## الموضع الحالي

حوالي:

**2970 → 2986**

## العنصر المعيب فعليًا

العنصر التالي موجود حاليًا:

```javascript
if(
    key==='wsTo' &&
    s.type==='SupplierReturn'
){

    return (
        s.refs.suppliers||[]
    )
    .filter(function(x){

        return (
            x &&
            x.is_active!==false
        );
    });
}
pickShow:function(key){this.pickSearch(key,(RW_UI.byId(key+'Search')||{}).value||'')},
```

### العيب ليس في

`pickShow:function(key)`

نفسها.

### العيب هو

**اختفاء إغلاق الدالة `pickArr` بعد نهاية SupplierReturn branch.**

كان يجب وجود:

```javascript
return [];
},
```

قبل `pickShow:function`.

الـcommit `4a322...` حذف هذا الجزء أثناء تعديل SupplierReturn.

وهذا هو سبب:

`vouchers:2986 Uncaught SyntaxError: Function statements require a function name`

---

# 5. التعديل الجراحي رقم 1 — جاهز للاستبدال

## الملف المطلوب تعديله

`companies/company-1/warehouse/vouchers.html`

## الدالة المتضمنة

`pickArr:function(key)`

## ابحث عن هذا العنصر كاملًا واحذفه بالكامل

```javascript
if(
    key==='wsTo' &&
    s.type==='SupplierReturn'
){

    return (
        s.refs.suppliers||[]
    )
    .filter(function(x){

        return (
            x &&
            x.is_active!==false
        );
    });
}
pickShow:function(key){this.pickSearch(key,(RW_UI.byId(key+'Search')||{}).value||'')},
```

## واستبدله بالكامل بهذا العنصر

```javascript
if(
    key==='wsTo' &&
    s.type==='SupplierReturn'
){

    return (
        s.refs.suppliers||[]
    )
    .filter(function(x){

        return (
            x &&
            x.is_active!==false
        );
    });
}

return [];
},
pickShow:function(key){this.pickSearch(key,(RW_UI.byId(key+'Search')||{}).value||'')},
```

### لماذا هذا هو التصحيح الصحيح

- يحافظ على SupplierReturn supplier filter الحالي.
- لا يعيد بناء pickArr.
- لا يعيد كتابة pickSearch.
- لا يغيّر Smart Search algorithm.
- لا يغيّر RLS.
- يعيد فقط delimiter/closure المفقود.
- يعيد الـfallback الأصلي `return []`.
- يعيد parser إلى داخل object literal الصحيح.
- يحافظ على جميع الوظائف الأخرى.

---

# 6. إثبات أن التعديل رقم 1 صحيح

تم تطبيق نفس replacement في نسخة داخل الذاكرة فقط.

النتيجة:

- script 1 = PASS
- script 2 = PASS
- script 3 = PASS
- script 4 = PASS
- script 5 = PASS
- script 6 = PASS

أي أن:

**Syntax Regression = CLOSED by surgical patch.**

لم يتم push لهذا التعديل إلى `erp-frontend` التزامًا بالـOwner-only source rule.

---

# 7. التعديل الجراحي رقم 2 — SR-08 Submit Preflight

هذا ليس Regression نحويًا؛ هو Business/UX gap ظل مفتوحًا رغم اكتمال Contract infrastructure.

## الملف

`companies/company-1/warehouse/vouchers.html`

## الدالة

`submit()`

## الموضع الدقيق الحالي

بعد SupplierReturn validation الحالي:

```javascript
if(this.type==='SupplierReturn'){
    var sb=(this.refs.branches||[]).find(function(x){
        return x.id===fr;
    });

    var sp=(this.refs.suppliers||[]).find(function(x){
        return x.id===to;
    });

    if(
        !sb||
        !sp||
        sp.is_active===false
    ){
        RW_UI.toast(
            'اختر فرعًا صالحًا وموردًا نشطًا من نفس الشركة',
            'error'
        );
        return;
    }
}
```

وقبل:

```javascript
if(this.mode==='edit'){
```

## لا تحذف SupplierReturn validation الحالي.

## أدخل هذا العنصر كاملًا قبل `if(this.mode==='edit')`

```javascript
if(this.type==='SupplierReturn'){

    var currentSupplierId=
        (RW_UI.byId('wsTo')||{})
            .value||'';

    var currentFingerprint=
        this.supplierReturnFingerprint();

    if(
        !this.supplierReturnDraft||
        String(
            this.supplierReturnDraft.supplier_id||''
        )!==
        String(currentSupplierId)||
        String(
            this.supplierReturnDraft.items_fingerprint||''
        )!==
        String(currentFingerprint)
    ){

        this.openSupplierReturnContract(
            function(){
                App.submit();
            }
        );

        return;
    }
}
```

---

# 8. لماذا SR-08 ضروري

بدون preflight:

UI يمكن أن ينشئ Draft SupplierReturn
→ ثم يبدأ Contract لاحقًا.

هذا يسمح بوجود Draft مجهز مخزنيًا لكن عقده التجاري غير مكتمل.

بعد SR-08:

Supplier selected
→ Contract missing/stale
→ Contract modal opens
→ user fills Return Reason / references / inspection / disposition / valuation
→ draft contract stored in memory
→ submit resumes
→ create/update voucher
→ save_supplier_return_contract
→ later send/complete.

هذا يمنع orphaned SupplierReturn drafts الناتجة عن تجاهل Contract UI.

والـcallback المقترح لا يكسر دورة التطبيق؛ هو يعيد submit بعد اكتمال الـContract.

---

# 9. إثبات أن SR-04 → SR-10 موجودة في المصدر الحالي

تم التحقق من وجود العناصر التالية في current `vouchers.html`:

- `supplierReturnDraft`
- `returnReasons`
- `taxCodes`
- تحميل `return_reasons`
- تحميل `finance_tax_codes`
- `openSupplierReturnContract()`
- `saveSupplierReturnContract()`
- `get_supplier_return_contract`
- `save_supplier_return_contract`
- optional Purchase Order
- optional Purchase Invoice
- Credit Note reference
- RMA reference
- Return-to Address
- Inspection Status
- Disposition
- line unit price
- line discount
- line tax
- fingerprint protection
- idempotency
- create callback SupplierReturn contract save
- edit callback SupplierReturn contract save
- reset of `supplierReturnDraft` in New/Edit/Back

إذن لا توجد حاجة لإعادة بناء هذه العناصر.

الجزء غير المنجز فعليًا في source كان SR-08 preflight، بالإضافة إلى regression النحوي الذي منع تشغيل التطبيق كله.

---

# 10. دور تطبيق الأذونات المخزنية في RAWAEA

## النوع

`warehouse/vouchers.html`

هو Execution Application مخصص للعمليات المخزنية اليدوية/غير المرتبطة تلقائيًا بأوردرات المبيعات والـRun Sheets.

## العمليات الحالية

- Transfer
- DirectSale
- DirectReturn
- SupplierReturn

ومسار SupplierReturn تحديدًا:

`Branch`
→ `Supplier`

بدون اشتراط:

- Sales Order
- Run Sheet
- Picking
- Loading
- Delivery

وهذا ليس نقصًا؛ بل Contract design مقصود.

## SupplierReturn

هو physical warehouse operation مستقلة:

Stock
→ Supplier

مع financial reference اختياري:

- Purchase Order
- Purchase Invoice

ومستندات تجارية:

- Supplier Credit Note
- RMA

وهذا هو الشكل الصحيح لتغطية:

1. Return linked to purchasing history.
2. Return independent of order history.
3. Direct purchase return.

---

# 11. دور النظام الأم

المبدأ المعماري الحالي:

### Control Plane

النظام الأم:

- الحوكمة
- الإدارة
- التبويبات
- المتابعة
- التحكم
- التقارير
- المراقبة

### Execution Plane

التطبيقات المنفصلة:

- vouchers.html
- van-sales.html
- picker
- loader
- receiver
- returns
- delivery
- purchasing
- finance

### System Transaction Plane

Supabase:

- PostgreSQL
- RPC
- transaction guards
- accounting
- stock
- audit
- idempotency
- RLS

هذه القسمة هي أحد الأسباب التي تسمح لـRAWAEA بأن يكون خفيفًا ميدانيًا مع backend مركزي.

---

# 12. التكامل مع app.html

المصدر الحالي لـ`app.html` يثبت routing مباشرًا حسب:

`activeWarehouseRole`

وعند:

```javascript
activeWarehouseRole === 'أذونات'
```

يتم التوجيه إلى:

`/companies/company-1/warehouse/vouchers.html`

وهذا يثبت أن التطبيق ليس جزيرة غير معروفة؛ بل هو أحد Execution Applications المنفصلة التي يوجه إليها نظام الدخول حسب الدور التشغيلي.

لم يتم تغيير هذا المسار.

---

# 13. التكامل مع van-sales.html

الملف:

`companies/company-1/sales/van-sales.html`

Current blob:

`8d61382a8e0025a0d079e71dd94f33d106d9088e`

التحقيق أثبت أن:

`loadVanBranch()`

يستخدم:

`setup-van-branch`

الموجودة بالفعل.

ويحفظ:

- branch_id
- branch_code
- vehicle_id
- vehicle_code
- driver_id

ثم يعمل على مخزن السيارة.

أما Core الخاص بـDirectSale فيستخدم:

`fleet_vehicle_sales_rep_assignments`

كمرجع Master Assignment، وليس `vehicle.driver_id` كمصدر تفويض لإنشاء DirectSale.

هذا يحافظ على الفصل الصحيح:

Van Sales
→ Mobile Stock
→ DirectSale

بينما:

Warehouse Vouchers
→ SupplierReturn

مساران مختلفان لكنهما يلتقيان في نفس Stock Core.

لم يتم تعديل van-sales.html.

---

# 14. إثبات أن SupplierReturn لا يعتمد على Driver / Van / Run Sheet

تم فحص `create_manual_stock_voucher_atomic_core_12_20260828`.

في SupplierReturn:

- source = Branch
- destination = Supplier
- supplier validation
- no PO requirement
- no Run Sheet
- no Sales Order
- no vehicle requirement
- no driver requirement

والتعليق الموجود في الـRPC يثبت صراحةً أن:

SupplierReturn is a standalone warehouse operation.

وهذا يجب الحفاظ عليه.

---

# 15. Supplier Smart Search / Dropdown

## ما كان يبدو كعيب UI

الاختبار الظاهري يعطي:

Supplier field
→ empty dropdown.

لكن التحقيق فصل بين:

### UI algorithm

`pickArr`
+
`pickShow`
+
`pickSearch`

و

### Data Access

RLS policy على:

`public.suppliers`

الـsmart search نفسه يعتمد على:

```javascript
x.name
x.supplier_code
x.phone
```

ويصفّي:

`x.is_active!==false`

هذا المنطق ليس سبب انعدام البيانات.

## Production

تم تنفيذ migration:

`20260927165000_harden_supplier_return_voucher_directory_and_rpc_acl_20260927.sql`

والموجود حاليًا في system repo:

`308ba5c1cd91f1f21dfca72e83973c5bbdf2479e`

التغيير يمنح SELECT داخل نفس الشركة للمستخدم الذي:

- يملك suppliers permission

أو:

- active_warehouse_role = `أذونات`

مع عدم توسيع INSERT/UPDATE/DELETE للموردين.

النتيجة المعمارية:

**مستخدم الأذونات يستطيع اختيار المورد دون أن يحصل على صلاحية إدارة الموردين.**

---

# 16. Production Contract — الحالة الحالية الفعلية

تم فحص Production مباشرة.

## stock_vouchers

يحوي:

- return_reason_id
- supplier_credit_note_ref
- supplier_rma_ref
- purchase_invoice_id
- purchase_order_id
- return_to_address
- inspection_status
- disposition
- return_currency
- return_subtotal
- return_discount_amount
- return_tax_amount
- return_total_amount

## stock_voucher_details

يحوي:

- unit_price
- gross_amount
- discount_percent
- discount_amount
- taxable_amount
- tax_code_id
- tax_rate
- tax_amount
- net_amount
- line_total

## Additional integration tables

موجودة فعليًا:

- return_reasons
- finance_tax_codes
- finance_tax_transactions
- purchase_document_links
- supplier_ledger
- suppliers.accounts_payable
- journal_entries
- journal_lines
- erp_operation_registry

لا يوجد نقص schema في هذه الطبقة.

---

# 17. Business Contract — Production RPC

تم فحص تعريف:

`save_supplier_return_contract(uuid,text,jsonb,text)`

وهو:

- authenticated only
- SECURITY DEFINER
- `search_path` محدد
- يتحقق من المستخدم داخل الشركة
- يتحقق من active user
- يتحقق من warehouse authorization
- يتحقق من المورد
- يتحقق من Return Reason
- يتحقق من address
- يتحقق من inspection
- يتحقق من disposition
- يتحقق من optional invoice
- يتحقق من optional PO
- يتحقق من invoice/PO supplier consistency
- يتحقق من invoice/PO relationship
- يحسب line gross
- يحسب discount
- يحسب taxable
- يحسب tax
- يحسب net
- يكتب voucher header
- يكتب voucher detail valuation
- ينشئ purchase_document_links
- يسجل idempotency
- يسجل audit log

هذا هو قلب العقد المالي/التجاري.

---

# 18. Assertion Contract

تم فحص:

`assert_supplier_return_contract(uuid,uuid)`

وهو يمنع الإرسال إذا:

- supplier missing
- invalid reason
- empty return address
- inspection = pending
- inspection = failed
- disposition = rejected
- line valuation صفر/ناقصة
- total صفر
- invalid invoice reference
- invalid PO reference
- invoice لا تتبع PO المحدد

وهذا يمنع انتقال Draft غير صالح إلى Send/Complete.

---

# 19. Accounting / Stock Core

تم فحص:

`create_manual_stock_voucher_atomic_core_12_20260828`

وهو موجود بالفعل.

SupplierReturn لا يحتاج Edge Function جديدة.

الدورة:

Browser
→ existing create-stock-voucher wrapper
→ canonical stock core
→ Draft
→ Contract RPC
→ Send
→ Complete
→ inventory
→ supplier ledger
→ GL
→ tax
→ audit.

وهذا يحقق مطلب:

**Central Unified Transaction Engine**

بدون إنشاء وظيفة جديدة.

---

# 20. QA Permanent Data — الموجود سابقًا

البيانات الدائمة الأصلية لم تُحذف.

## Supplier

`QA-SR-CLOSURE-20260927`

## Item

`QA-SR-ITEM-20260927`

## Completed Voucher

`QA-SR-UI-CONTRACT-20260927-01`

Status:

`Completed`

### Values

- Gross = 75.00
- Discount = 7.50
- Taxable = 67.50
- VAT = 10.13
- Total = 77.63

### Stock

5.00 → 4.00

### Supplier Ledger

Debit = 77.63

### GL

Supplier payable debit = 77.63
Inventory credit = 67.50
Input VAT credit = 10.13

### Tax Transaction

Taxable = 67.50
Tax = 10.13

هذه البيانات بقيت كما هي.

---

# 21. QA Permanent Data — الجديد الذي تم إنشاؤه مباشرة في Production

لإكمال شرط Browser E2E دون تعديل source أو حذف البيانات:

تم إنشاء Fixture دائم:

## Reference

`QA-SR-BROWSER-E2E-20260927-01`

## Voucher ID

`e029730a-2925-4c42-8472-57c6b0264c27`

## Voucher Code الحالي

`IN-7`

## Status

`Draft`

## Type

`SupplierReturn`

## Supplier

`QA-SR-CLOSURE-20260927`

## Item

`QA-SR-ITEM-20260927`

## Contract

- Return Reason = SR001
- Credit Note = QA-BROWSER-CN-20260927-01
- RMA = QA-BROWSER-RMA-20260927-01
- PO = QA-SR-PO-20260927
- Purchase Invoice = QA-SR-INV-20260927
- Inspection = passed
- Disposition = credit_requested
- Unit Price = 75
- Discount = 10%
- VAT = VAT15-PURCHASE
- Total = 77.63

## الحالة المالية المقصودة حاليًا

Draft only.

لذلك:

- inventory movement = 0
- supplier ledger entry = 0
- journal entry = 0
- tax transaction = 0

وهذا مقصود حتى يكون Fixture مناسبًا لاختبار Browser Send/Complete لاحقًا دون تغيير أرصدة الشركة قبل الاختبار اليدوي النهائي.

**هذه البيانات دائمة ولا يجب حذفها.**

---

# 22. E2E Test — PO + Invoice

تم تشغيل transactional test عبر RPC authenticated مع:

- SupplierReturn
- valid supplier
- Return Reason
- Credit Note
- RMA
- optional PO
- optional Purchase Invoice
- Inspection passed
- Disposition credit_requested
- line discount
- VAT

النتيجة:

- Draft created
- Contract Save PASS
- Assert PASS
- 2 document links created
- movement count = 0 while draft

المعاملة كانت test transaction ثم rollback للـtemporary voucher فقط.

لم يتم حذف أي QA master data.

---

# 23. E2E Test — Direct Purchase / Invoice Only

تم أيضًا اختبار المسار الثاني الخاص بالشراء المباشر.

الاختبار استخدم:

Purchase Invoice:

`PINV-1001`

وكان:

- status = Posted
- purchase_order_id = NULL
- supplier = SUPP-1001

تم إنشاء SupplierReturn مؤقتًا بنفس المورد ثم:

- Contract Save PASS
- Purchase Invoice link = 1
- PO = NULL
- Assert PASS
- movement = 0 while draft

ثم rollback للـtemporary voucher فقط.

هذا يثبت أن:

**الشراء المباشر بالفاتورة بدون PO مدعوم في Contract الحالي.**

---

# 24. مساران شراء رسميان في RAWAEA

## المسار الأول

Supplier
→ Purchase Order
→ Receive Purchase
→ Stock
→ Purchase Invoice
→ Supplier Return

في هذا المسار:

- PO optional reference
- Purchase Invoice optional reference
- invoice/PO consistency enforced.

## المسار الثاني

Buyer / Purchase Representative
→ Direct Purchase
→ Purchase Invoice
→ Stock
→ Supplier Return

في هذا المسار:

- Purchase Invoice may exist
- Purchase Order may be NULL
- SupplierReturn accepts invoice-only reference.

هذه ليست حالتين اصطناعيتين؛ الـContract الحالي يسمح بهما صراحة.

---

# 25. مقارنة وظيفية مع الأنظمة المنافسة

المقارنة هنا ليست Ranking.

## Odoo 19

Official documentation يثبت أن Vendor Returns تقلل المخزون وقيمة المخزون وفق costing method، وتتعامل مع vendor bills والـinventory valuation.

https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html

أهم ما يجب الاحتفاظ به في RAWAEA:

- physical return
- stock valuation
- accounting counterpart
- purchasing references.

## Microsoft Dynamics 365

Purchase Return Order يربط الإرجاع مع الشراء والـcredit note وعمليات shipment/receipt.

https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/tasks/create-purchase-return-order

RAWAEA حاليًا يملك Contract reference layer وvaluation وaccounting integration، مع إبقاء physical return كـWarehouse execution.

## SAP S/4HANA

Return-to-Supplier يمكن أن يكون Return Purchase Order / Return Delivery / Warehouse execution، ومع بعض المسارات inspection.

https://help.sap.com/docs/SAP_S4HANA_CLOUD/87f9b54f9c4f4e75aff0061860a6589a/48fa152d678a4fe2858d014d7e8790f9.html

RAWAEA يحقق separation مشابهًا:

Contract
+
Warehouse execution
+
Accounting.

## Daftra

Daftra يوثق Purchase Debit Notes وPurchase Refund وربطها بالفواتير.

https://docs.daftra.com/en/user_manual/issuing-credit-notes-and-refund-receipts-for-purchase-invoices/

أهمية ذلك لـRAWAEA:

- supplier financial adjustment
- reference traceability
- automatic journal impact.

## Manager.io

Supplier Debit Notes تغطي return of goods، supplier balance، inventory/expense/tax correction.

https://www2.manager.io/guides/7426

هذه النقاط موجودة فعليًا في SupplierReturn Contract الحالي.

---

# 26. فجوات RAWAEA التي أُغلقت

العناصر المطلوبة كانت:

- Return Reason
- Supplier Credit Note / RMA
- Optional Purchase Invoice reference
- Optional PO reference
- Return-to Address
- Inspection / disposition
- Tax/discount line valuation

الـBusiness Contract + DB + Accounting لهذه العناصر أصبح **CLOSED**.

لا حاجة إلى:

- table جديدة
- Edge Function جديدة
- duplicate contract.

---

# 27. فجوة واجهة المستخدم التي بقيت

لم تكن فجوة schema.

كانت:

## A

Syntax regression يمنع التطبيق من parsing.

## B

SR-08 preflight غير موجود في source الحالي.

لهذا وصلت البنية إلى الحالة:

Production Backend = Ready
+
Source UI = Partially wired
+
Parser = Broken

بعد patch 1:

Parser = Ready

وبعد patch 2:

Contract preflight = Ready

ثم يبقى:

Browser E2E
+
Deployment proof.

---

# 28. Security / ACL

تم التحقق من أن:

`save_supplier_return_contract`

- anon execute = false
- authenticated execute = true

و:

`get_supplier_return_contract`

- anon execute = false
- authenticated execute = true

أما:

`assert_supplier_return_contract`

فتم تقييد Execute عليه وعدم تعريضه كـpublic capability.

Supplier SELECT policy أصبحت تدعم:

- suppliers permission

أو:

- active warehouse role = أذونات.

لكن write permissions للموردين لم يتم توسيعها لهذا الدور.

---

# 29. Supabase Advisors

تم تشغيل security/performance advisors بعد التحقق.

ظهرت findings عامة على مستوى المشروع لا تخص SupplierReturn الجديد مباشرة، ومنها:

- security-definer views
- mutable function search paths
- security-definer functions executable by anonymous/authenticated roles
- RLS enabled tables without policies

هذه findings ليست جزءًا من Closure الحالي ولم يتم تعديلها حتى لا تتوسع الجلسة خارج نطاقها وتتم إعادة بناء Security Architecture دون تحقق مستقل.

قاعدة الجلسة:

**لا نعالج findings عامة unrelated ونخاطر بكسر modules مستقرة أثناء إغلاق vouchers.**

---

# 30. Edge Functions

تم فحص القائمة الحالية.

المسار المطلوب موجود:

- create-stock-voucher
- send-stock-voucher
- complete-stock-voucher

ولا توجد حاجة لإنشاء:

- create-supplier-return
- save-supplier-return
- complete-supplier-return

جديدة.

القرار:

**NO NEW EDGE FUNCTION**

واستخدام RPC هو الحل الآمن ضمن Spend/Gateway boundary الحالي.

---

# 31. Deployment Evidence

README الخاص بالـfrontend يثبت:

- Hosting = Cloudflare Pages
- Repository = GitHub
- Backend = Supabase
- PWA = Service Worker + Manifest

لكن لم يتم الادعاء بأن الـpublished artifact يحمل patch Owner ما دام `vouchers.html` نفسه لم يُدفع بعد إلى frontend repository.

لذلك:

Published Artifact SHA = **OPEN**

وهذا ليس فشلًا في Production؛ بل نتيجة متعمدة لقاعدة:

**Owner Source Apply first.**

---

# 32. لماذا لا يجب إعادة بناء vouchers.html

لأن:

- contract موجود
- create موجود
- edit موجود
- references موجودة
- tax موجود
- discount موجود
- inspection موجود
- disposition موجود
- idempotency موجود
- audit موجود
- RLS موجود
- smart search موجود
- source routing موجود
- separate applications موجودة

إعادة البناء ستعيد مخاطر regression التي أوقفناها الآن.

الـClosure الصحيح هو:

**Patch only.**

---

# 33. Closure Matrix

| العنصر | الحالة الحالية |
|---|---|
| Current Git | VERIFIED |
| Parent commit | VERIFIED |
| Current vouchers source | VERIFIED |
| Syntax root cause | IDENTIFIED |
| Surgical syntax patch | READY |
| Supplier Smart Search logic | PRESENT |
| Supplier RLS | CLOSED |
| Return Contract schema | CLOSED |
| Return Contract RPC | CLOSED |
| PO optional | CLOSED |
| Invoice optional | CLOSED |
| Invoice-only direct purchase | RPC E2E PASS |
| Credit Note | CLOSED |
| RMA | CLOSED |
| Return-to Address | CLOSED |
| Inspection | CLOSED |
| Disposition | CLOSED |
| Tax line | CLOSED |
| Discount line | CLOSED |
| Supplier Ledger | CLOSED |
| GL | CLOSED |
| Tax Transaction | CLOSED |
| Stock movement | CLOSED |
| Idempotency | CLOSED |
| Audit | CLOSED |
| Existing permanent QA | RETAINED |
| New browser E2E fixture | CREATED + RETAINED |
| Edge Function count | NOT INCREASED |
| main.html | UNTOUCHED |
| vouchers.html | UNTOUCHED BY ASSISTANT |
| van-sales.html | UNTOUCHED |
| SR-08 submit preflight | READY |
| Browser E2E | OPEN |
| Published artifact | OPEN |

---

# 34. ما لم يتم فعله عمدًا

لم يتم:

- تعديل main.html
- تعديل vouchers.html في GitHub
- تعديل van-sales.html
- إنشاء Edge Function
- إنشاء جدول جديد
- تغيير SupplierReturn Core
- تغيير post_stock_movement
- تغيير DirectSale
- تغيير DirectReturn
- تغيير fleet assignment
- حذف QA data
- حذف production records
- rollback لـProduction Contract.

---

# 35. Direct Production Actions Executed This Session

تم التنفيذ المباشر في Production:

1. التحقق من schema الحالي.
2. التحقق من Contract RPCs الحالية.
3. التحقق من ACL/RLS.
4. authenticated RPC E2E لـPO + Invoice.
5. authenticated RPC E2E لـInvoice-only.
6. إنشاء Fixture دائم:
   `QA-SR-BROWSER-E2E-20260927-01`
7. حفظ Contract للـFixture.
8. Assert ناجح.
9. التحقق من عدم وجود inventory/ledger/GL/tax movement للـDraft Fixture.

لم يتم إدخال أي تغييرات schema غير لازمة.

---

# 36. تعليمات Owner — التنفيذ الجراحي فقط

## Patch 1

في:

`companies/company-1/warehouse/vouchers.html`

ابحث عن:

`if(key==='wsTo' && s.type==='SupplierReturn')`

داخل:

`pickArr:function(key)`

واحذف العنصر الكامل الذي ينتهي مباشرة بـ:

`}`
ثم يأتي:

`pickShow:function(key)`

واستبدله بالعنصر الموجود في Section 5 حرفيًا.

## Patch 2

في نفس الملف، داخل:

`submit()`

ابحث عن:

```javascript
if(this.mode==='edit'){
```

الموجود مباشرة بعد SupplierReturn validation.

أدخل قبله العنصر الموجود في Section 7 حرفيًا.

---

# 37. بعد Owner Apply

التسلسل المطلوب:

Source Apply
→ Git commit
→ parse embedded JavaScript
→ verify no SyntaxError
→ publish
→ verify served artifact SHA
→ authenticated browser login
→ Supplier Search
→ Supplier Dropdown
→ SupplierReturn Contract
→ Return Reason
→ Credit Note
→ RMA
→ PO optional
→ Invoice optional
→ Return-to Address
→ Inspection
→ Disposition
→ line valuation
→ Save
→ Send
→ Complete
→ verify Stock
→ verify inventory_log
→ verify Supplier Ledger
→ verify AP
→ verify GL
→ verify Tax
→ verify Audit
→ retain QA fixture.

لا يتم اعتبار:

DB PASS

أو:

RPC PASS

بأنه:

Browser PASS.

---

# 38. تعليمات المساعد التالي

لا يبدأ من Report 344 فقط.

ابدأ:

1. CURRENT GIT
2. CURRENT SOURCE
3. CURRENT PRODUCTION
4. CURRENT DATABASE
5. CURRENT DEPLOYMENT

ثم تحقق من:

- System HEAD
- Mother HEAD
- vouchers blob
- report 344
- CURRENT_STATE
- permanent QA `QA-SR-UI-CONTRACT-20260927-01`
- permanent browser fixture `QA-SR-BROWSER-E2E-20260927-01`

ولا تعيد:

- Production SupplierReturn schema
- Supplier RLS
- DirectSale
- DirectReturn
- Fleet assignment
- Contract RPC construction
- QA data construction

ولا تلمس:

- main.html
- van-sales.html

ولا تنشئ:

- Edge Function جديدة

وفي vouchers.html لا تبدأ من الصفر.

ابدأ من:

**Patch 1 → Patch 2 → Parse → Browser → Deployment → E2E closure.**

---

# 39. SELF AUDIT

## هل تم الوثوق بالتقرير فقط؟

لا.

تم فحص:

- current git
- parent
- current source
- historical parent versions
- production schema
- production RPC definitions
- RLS
- grants
- QA records
- stock
- supplier ledger
- GL
- tax
- purchase invoice/PO references
- current van-sales source
- current app routing.

## هل تم تحديد سبب SyntaxError؟

نعم.

الموضع:

`vouchers.html:2986`

والسبب:

**missing `return [];
},` closing segment of pickArr.**

## هل تم إصلاح vouchers.html مباشرة؟

لا.

وذلك متعمد.

## هل تم لمس main.html؟

لا.

## هل تم لمس van-sales.html؟

لا.

## هل تم إنشاء Edge Function؟

لا.

## هل تم تغيير schema؟

لا؛ لأن schema الحالي مكتمل.

## هل تم إنشاء بيانات اختبار دائمة؟

نعم.

## هل تم حذف بيانات اختبار؟

لا.

## هل تم اختبار Direct Purchase invoice-only؟

نعم.

## هل تم اختبار PO + Invoice؟

نعم.

## هل تم اختبار Browser؟

ليس بعد؛ لأن Owner source patch لم يُدفع.

---

# 40. FINAL CTO DECISION

هذه الجلسة لا تحتاج إعادة تصميم.

القرار:

**Surgical Source Closure + Existing Production Contract Reuse**

وليس:

**Rewrite / Rebuild / New API / New Edge Function / New Table**

الـBusiness Contract الحالي في Production صالح ويغطي مساري الشراء.

الـRegression الحقيقي هو parser closure داخل `pickArr`.

والفجوة الوظيفية المتبقية في المصدر هي SR-08 preflight.

بعد تطبيق التعديلين حرفيًا:

Supplier Directory
→ SupplierReturn Contract
→ Draft
→ Send
→ Complete
→ Stock
→ Supplier Ledger
→ GL
→ Tax
→ Audit

تعود كسلسلة واحدة متكاملة دون تحويل التطبيق إلى جزيرة جديدة.

---

# 41. END STATE

**Production:** CLOSED  
**Database:** CLOSED  
**RPC:** CLOSED  
**Security ACL/RLS:** CLOSED  
**Business Contract:** CLOSED  
**QA:** PASS + RETAINED  
**Syntax Root Cause:** IDENTIFIED  
**Surgical Patch 1:** READY  
**Surgical Patch 2:** READY  
**main.html:** PROTECTED  
**vouchers.html source:** OWNER APPLY REQUIRED  
**Browser E2E:** OPEN  
**Published Artifact:** OPEN

---
## END — Report 344
