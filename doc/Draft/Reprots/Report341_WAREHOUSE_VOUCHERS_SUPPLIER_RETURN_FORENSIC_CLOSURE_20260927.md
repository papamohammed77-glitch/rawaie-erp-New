# تقرير 341 — إغلاق جنائي لمسار «مرتجع مورد» في تطبيق الأذونات المخزنية
## تاريخ التنفيذ: 2026-09-27

**نطاق التقرير:** SupplierReturn فقط داخل companies/company-1/warehouse/vouchers.html، مع تحقق من Mother main.html وvan-sales.html وProduction Supabase.

**قاعدة التنفيذ:** لم يتم تعديل main.html، ولم يتم تعديل vouchers.html، ولم يتم إنشاء Edge Function جديدة. أي إصلاح مصدر في vouchers.html مقدم هنا كـ OWNER SURGICAL CHANGESET للتطبيق اليدوي.

---

## 1. الحالة المثبتة

### System Git
- Repository: papamohammed77-glitch/rawaie-erp-New
- HEAD: 27dd52a82bccfc65726ed3e46776ede28ac1281b
- Parent: 6ebea2c7aacad14a1702fe86032870fb14d87db1
- Parent السابق: 0d5a57d7b263cbb10e5235db56175fc4b7825ed3

### Mother Git
- Repository: papamohammed77-glitch/erp-frontend
- HEAD: fce3dfaa0503957791113a5ebf57d402a4a82764
- Parent: 666f15bc84348b6fb44a5c565dcf2fb4fe1d0c98
- main.html SHA: 810e4f5440f5975f55099a124deb42b086a49183
- vouchers.html SHA: 6c3822060c0e261c73879b94a5147d807a0bc6c2
- van-sales.html SHA: 8d61382a8e0025a0d079e71dd94f33d106d9088e

آخر Commit لـVouchers أزال بقايا vehicleRep غير المعرّفة فقط. لم تتم إعادة هذا الإصلاح.

---

## 2. ما أثبته التاريخ مقابل الحالة الحالية

التقارير التاريخية، خصوصًا Report302، بنت SupplierReturn على supplierBranchMap مشتق من purchase_orders.

الحالة الحالية المثبتة من المصدر والـProduction تعكس عقدًا مختلفًا:

SupplierReturn = عملية مخزنية مستقلة عن PO.

Mother main.html:
- يضع SupplierReturn تحت الأذونات المخزنية.
- يحمّل جميع الموردين النشطين للشركة.
- لا يفرض PO.
- المسار Branch → Supplier.

Production create_manual_stock_voucher_atomic_core_12_20260828:
- يثبت SupplierReturn كعملية مستقلة.
- يتحقق من Supplier نشط داخل الشركة.
- لا يشترط PO أو Purchase Invoice.

لذلك القاعدة التاريخية الخاصة بـPO أصبحت Consumer Drift داخل Vouchers Standalone.

---

## 3. دورة الشراء الصحيحة

### المسار الأول
Purchase Order → Receiving → Stock → Supplier Ledger → Accounting → Audit

### المسار الثاني
شراء مباشر/فاتورة شراء صغيرة → Stock/Accounting وفق مسار الشراء المباشر.

ولا يترتب على وجود المسارين أن SupplierReturn يجب أن يكون PO-bound.

العقد الصحيح:

SupplierReturn → Supplier Master + Source Branch + Items + Qty + Valuation → Physical Stock Movement → Supplier Ledger → GL → Audit

يمكن لاحقًا أن يكون هناك Purchase Invoice أو PO مرجعًا اختياريًا، لا شرط إنشاء.

---

## 4. سبب مشكلة البحث الذكي والقائمة المنسدلة

العنصر المعيب في vouchers.html هو Candidate Source داخل pickArr(key)، وليس محرك البحث نفسه.

الموقع الحالي: الأسطر 2937–2964 تقريبًا.

ابحث بالضبط عن:

~~~javascript
if(
    key==='wsTo' &&
    s.type==='SupplierReturn'
)
~~~

واحذف هذه الكتلة كاملة:

~~~javascript
if(
    key==='wsTo' &&
    s.type==='SupplierReturn'
){

    var m=
        (
            s.refs
                .supplierBranchMap||
            {}
        )[bid];

    if(
        m &&
        Object.keys(m).length
    ){

        return (
            s.refs.suppliers||[]
        )
        .filter(function(x){

            return !!m[x.id];
        });
    }

    return [];
}
~~~

واستبدلها بالكامل بـ:

~~~javascript
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
~~~

### أثر الإصلاح
بعدها سيعمل pickSearch على الموردين الموجودين فعلًا بدل Array فارغة.

---

## 5. التحقق في submit

الموقع الحالي: الأسطر 4085–4106 تقريبًا.

ابحث بالضبط عن:

~~~javascript
if(this.type==='SupplierReturn'){
~~~

واحذف الكتلة الحالية كاملة:

~~~javascript
if(this.type==='SupplierReturn'){
    var sb=(this.refs.branches||[]).find(function(x){
        return x.id===fr;
    });
    var sp=(this.refs.suppliers||[]).find(function(x){
        return x.id===to;
    });
    var map=(s.refs.supplierBranchMap||{})[fr];

    if(
        !sb||
        !sp||
        !map||
        !map[sp.id]
    ){
        RW_UI.toast(
            'لا يوجد ربط موثق بين المورد والفرع',
            'error'
        );
        return;
    }
}
~~~

واستبدلها بالكامل بـ:

~~~javascript
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
~~~

الحارس النهائي يبقى Production Core الذي يثبت company/supplier ownership.

---

## 6. تغيير نص واحد فقط في واجهة المسار

في routeHtml() داخل فرع SupplierReturn:

ابحث فقط عن النص:

مورد مرتبط بالفرع

واستبدله بـ:

المورد

لا تغيّر بقية routeHtml().

---

## 7. pickSearch لا يحتاج إلى تعديل في هذه Closure

بعد إصلاح Candidate Source:
- البحث بالاسم يعمل.
- البحث بكود المورد يعمل.
- البحث بالهاتف يعمل.
- الترتيب الحالي يعمل.
- pickSelect يعمل.

لذلك تعديل pickSearch الآن سيكون إعادة بناء غير لازمة.

---

## 8. إثبات Production الحقيقي

تم العثور على Fixture دائمة موجودة بالفعل ولم يتم حذفها:

### Supplier
- QA-SR-20260927
- QA مرتجع مورد — لا يوجد PO
- ID: 37207061-6153-4c57-8449-90e381bccf5f
- Active = true
- لا يوجد PO مرتبط.

### Item
- QA-SR-ITEM-20260927
- QA صنف مرتجع مورد — اختبار دائم
- ID: 8a84e363-4c27-4b52-959f-311138df9972
- Cost = 75
- Unit = حبة

### Voucher
- IN-3
- Type = SupplierReturn
- Status = Completed
- Reference = QA-SR-RETURN-20260927-01
- Qty = 2
- Unit Price = 75
- Total = 150
- Source = BR-01
- Supplier = QA-SR-20260927

هذه البيانات أبقيت كما هي، ولم يتم إنشاء Fixture ثانية لأنها تؤدي الغرض المطلوب.

---

## 9. إثبات الأثر المخزني

بعد SupplierReturn:
- BR-01 للصنف QA أصبح qty = 8
- allocated_qty = 0
- available_qty = 8

Inventory Log:
- movement_type = SupplierReturn
- qty = 2
- source_branch_id = BR-01
- target_branch_id = NULL
- voucher_id = IN-3
- idempotency key موجود.

العقد المركزي:

SupplierReturn → post_stock_movement → stock_branches + inventory_log

ولم يتم تعديل post_stock_movement.

---

## 10. إثبات الأثر المحاسبي

قيمة العملية = 2 × 75 = 150.

Supplier Ledger:
- Debit = 150
- Credit = 0
- Balance = -150

Journal:
- JE-SVR-IN-3
- Status = Posted
- Supplier Payable: Debit 150
- Inventory: Credit 150
- Total Debit = 150
- Total Credit = 150

القيد متوازن.

---

## 11. إثبات Retry / Idempotency

تم تنفيذ RPC القائم:

complete_manual_stock_voucher_atomic(
  company,
  IN-3,
  owner@alrawae.com
)

على الإذن المكتمل نفسه.

النتيجة:
- success = true
- duplicate = true
- status = Completed
- نفس journal entry
- نفس supplier ledger result
- لا قيد مالي ثانٍ.

لا يوجد احتياج إلى Edge Function جديدة.

---

## 12. نقطة محاسبية مكتشفة ولا تُرقع داخل هذه المهمة

يوجد فرق بين:
- supplier_ledger.balance
- suppliers.accounts_payable

في Production:
- QA supplier: accounts_payable = 0
- ledger_balance = -150
- SUPP-1001: accounts_payable = 0
- ledger_balance = 3970

هذا يعني أن عقد الرصيد المالي في Master Suppliers يحتاج Closure مستقلة لتحديد الحقل المرجعي. لم يتم تعديل accounts_payable بالتخمين حتى لا يتغير عقد مالي قائم.

---

## 13. Van Sales والتكامل

van-sales.html:
- يعتمد على setup-van-branch.
- يعمل على mobile branch.
- يسجل مبيعات السيارة عبر save-sales-invoice.
- لديه مسار جرد السيارة.
- لا ينشئ SupplierReturn.

تكامل SupplierReturn مع Van Sales يتم عبر نفس stock_branches وinventory_log، لذلك لا يوجد إصلاح في van-sales لهذه Closure.

إصلاحات DirectSale Master Assignment السابقة لم تُكرر.

---

## 14. المنافسون — الفجوة الحقيقية

Odoo:
- Vendor Bill يمكن إنشاؤه مباشرة دون PO.
- Credit/Debit Note متاحة.
- يمكن الربط بـPO اختياريًا.

Dynamics 365:
- Purchase Return Order يدعم المرتجع الجزئي والبضائع غير المخططة، مع إمكانية النسخ من Vendor Invoice وربط الحركة الأصلية.

SAP:
- Supplier Returns تشمل return document وinspection وfollow-up وshipment وgoods issue والمعالجة المالية.

Daftra:
- Purchase Debit Note يمكن أن يكون مستقلًا أو مرتبطًا بفاتورة.
- Purchase Refund يعتمد على فاتورة شراء.
- توجد تقارير للمشتريات والمرتجعات.

Manager.io:
- Debit Note يتطلب Supplier، وPurchase Invoice مرجع اختياري.
- يعدل Inventory وAccounts Payable.

مصادر رسمية:
https://www.odoo.com/documentation/19.0/applications/finance/accounting/vendor_bills.html
https://www.odoo.com/documentation/17.0/applications/finance/accounting/customer_invoices/credit_notes.html
https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/tasks/create-purchase-return-order
https://help.sap.com/docs/SAP_S4HANA_ON-PREMI-SE/af9ef57f504840d2b81be8667206d485/666259fa030b4b959991a99b45e85e00.html
https://docs.daftra.com/en/user_manual/issuing-credit-notes-and-refund-receipts-for-purchase-invoices/
https://docs.daftra.com/en/tutorial/inventory-consumption-for-purchase-invoices-and-returns/
https://www2.manager.io/guides/7426

### ما ينقص RAWAEA مستقبلًا
هذه ليست ترقيعات هذه Closure:
- Return Reason.
- Supplier Credit Note / RMA.
- Optional Purchase Invoice reference.
- Optional PO reference.
- Return-to Address.
- Inspection / disposition.
- Tax/discount line valuation.

هذه تحتاج Business Contract + DB + Accounting closure مستقلة.

---

## 15. Edge / RPC

Production الموجود حاليًا:
- create-stock-voucher v12
- send-stock-voucher v20
- receive-stock-voucher v22
- complete-stock-voucher v4

كما توجد RPCs المركزية:
- create_manual_stock_voucher_atomic
- post_stock_movement
- post_supplier_ledger_entry
- post_journal_entry
- complete_manual_stock_voucher_atomic

لا يوجد Backend defect يستوجب Function جديدة.

---

## 16. مصفوفة الإغلاق

| البند | الحالة |
|---|---|
| SupplierReturn Production Contract | PASS |
| No-PO SupplierReturn | PASS |
| Persistent QA | PASS |
| Stock movement | PASS |
| Inventory Log | PASS |
| Supplier Ledger | PASS |
| Journal | PASS |
| Retry idempotency | PASS |
| Root cause | PROVED |
| Candidate source before patch | FAIL |
| Owner surgical patch | READY |
| main.html touched | NO |
| vouchers.html touched by assistant | NO |
| van-sales touched | NO |
| New Edge Function | NO |
| Browser E2E after owner patch | OPEN |

---

## 17. سبب الخطأ النهائي

الخطأ الجذري:

SupplierReturn صحيح كعملية مستقلة.

لكن vouchers.html كان يطبق:

SupplierReturn
→ supplierBranchMap
→ purchase_orders
→ لا يوجد PO
→ الموردون = []
→ البحث الذكي بلا نتائج
→ المستخدم يظن أن Dropdown/Search معطل.

ثم كان submit() يفرض نفس الشرط مرة ثانية.

إذن:

**Search Engine ليس سبب العطل.**

**Candidate Source هو سبب العطل.**

والعقد الصحيح هو:

**SupplierReturn = Standalone Branch → Supplier operation**

مع إمكانية إضافة مرجع PO/Invoice مستقبلاً بشكل اختياري.

---

## 18. ما تم تنفيذه في Production

لا يوجد تعديل Business Logic Production مطلوب.

تم تنفيذ/التحقق من:
- Production reads.
- RPC definitions.
- Edge versions.
- Stock.
- Inventory Log.
- Supplier Ledger.
- Journal.
- Retry عبر RPC.
- QA persistence.

ولا يوجد إنشاء Edge Function جديدة.

---

## 19. تعليمات الجلسة التالية

لا تبدأ من أي تقرير قديم.

ابدأ من:
- CURRENT_STATE.md
- System HEAD + parent
- Mother HEAD + parent
- vouchers SHA
- main SHA
- van-sales SHA
- Production QA IN-3

ثم تحقق فقط من:
1. تطبيق SR-01.
2. تطبيق SR-02.
3. تطبيق SR-03.
4. Full parse.
5. Published artifact.
6. Authenticated Browser E2E.

بعد ذلك:
- إغلاق SupplierReturn UI إذا نجح Browser E2E.
- عدم إعادة DirectSale/DirectReturn/fleet fixes.
- عدم إنشاء Edge Function جديدة.
- عدم لمس main.html.

---

## 20. Self Audit

### What was proved
- Production SupplierReturn مستقل عن PO.
- Mother SupplierReturn مستقل عن PO.
- Vouchers Standalone هو المكان الذي أُدخل فيه PO gate.
- هذا هو سبب فراغ Supplier picker.
- Backend stock/accounting/idempotency صحيح.

### What was intentionally not changed
- main.html
- vouchers.html
- van-sales.html
- post_stock_movement
- create-stock-voucher
- send-stock-voucher
- complete-stock-voucher
- supplier ledger engine
- journal engine

### Last Verified Checkpoint
Production Core + DB + accounting + idempotency verified.

### Next Exact Step
Owner applies SR-01/SR-02/SR-03 in:
companies/company-1/warehouse/vouchers.html

ثم Browser E2E authenticated verification.

## END — Report 341
