# Report328 — MOTHER PURCHASE INVOICE SUPABASE_URL FORENSIC CLOSURE
## 2026-09-24

## 1. نطاق الإغلاق

Closure Unit:

Mother ERP → دورة المشتريات → فواتير الشراء → `RW_PurchaseGold.createInvoice()`

القاعدة الحاكمة:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

التقارير التاريخية استُخدمت لاسترجاع النية والسياق فقط. Current Truth أُعيد إثباته من Git وProduction مباشرة.

لا يوجد أي تعديل مباشر من المساعد على:

`companies/company-1/main.html`

الـOwner يبقى منفذ تعديل Mother.

---

## 2. Current Git / Current Source

Repository:

`papamohammed77-glitch/erp-frontend`

Current HEAD:

`0010f719a33bfcda3f2922eca66c6be55d5582a9`

Current HEAD message:

`forensic: persist current Mother HR extract`

Parent:

`b5043e626bf9eddea87644c36d024291cccff55f`

والـparent هو commit:

`Update timestamp and improve supplier representative input`

Current Mother file:

`companies/company-1/main.html`

Current source blob:

`4eb18a27285550e81a6b1564fdb9df4708363cfa`

Current file:

- 32,075 lines
- 1,741,278 bytes (blob content loaded directly)
- لا يوجد تعريف لـ `SUPABASE_URL`
- يوجد تعريف/مصدر المشروع باسم `RW_SUPABASE_URL`

الـCurrent source تم فحصه مباشرة، ولم تُستخدم نسخة Report324 القديمة كمصدر patch.

---

## 3. Historical Reconciliation

### Report323

أثبت أن Purchase Invoice modal كان في حاجة إلى استكمال تكامل البحث الذكي وربط البيانات بالـpayload.

### Report324

أضاف/أثبت:

- Supplier smart search
- Item smart search
- Supplier invoice number
- Notes payload
- Full inline syntax verification

هذه البنود موجودة بالفعل في Current Source الحالي.

لذلك لم تتم إعادة تنفيذها.

### Current source after later commits

الـmodal الحالي يحتوي فعليًا على:

- Supplier
- Branch
- Purchase Order
- Due Date
- Supplier Invoice Number
- Notes
- Item smart search
- Quantity
- Unit Price
- Discount %
- Tax %
- Pre-confirm validation
- `CREATE_INVOICE` dispatch

إذن العناصر المغلقة تاريخيًا لم تُفتح من جديد.

---

## 4. Root Cause — Current Evidence

### Defective element

Function:

`RW_PurchaseGold.api(operation, payload, operationId)`

Current line:

`12040`

Current statement:

```js
      SUPABASE_URL + '/functions/v1/save-purchase-order',
```

### السبب المثبت

Current `main.html` لا يعرّف identifier باسم:

`SUPABASE_URL`

بينما يوفّر:

`RW_SUPABASE_URL`

وبالتالي عند تنفيذ:

`createInvoice()`

ثم:

`api('CREATE_INVOICE', r.value)`

يصل التنفيذ إلى expression:

`SUPABASE_URL + ...`

فتحدث:

`ReferenceError: SUPABASE_URL is not defined`

ولا يتم إرسال HTTP request أصلًا.

---

## 5. لماذا لا يظهر الخطأ في Console؟

Current source يحتوي على:

```js
try {
  var result = await api('CREATE_INVOICE', r.value);
  ...
} catch (e) {
  hideLoader();
  Swal.fire('تعذر إنشاء الفاتورة', e.message, 'error');
}
```

لذلك `ReferenceError` يتم التقاطه داخل `catch` ويُعرض للمستخدم في SweetAlert بدون `console.error()`.

إذن:

- عدم وجود Console error في هذا المسار مفهوم من Current Source.
- الخطأ الحقيقي هو runtime ReferenceError وليس Supabase network failure.

---

## 6. Spinner / Loading Analysis

Current global loader:

```js
const showLoader = (title = 'جاري التحميل...') => {
  try {
    Swal.fire({
      title,
      allowOutsideClick: false,
      didOpen: () => Swal.showLoading()
    });
  } catch(e) { console.error(e); }
};

const hideLoader = () => {
  try { Swal.close(); } catch(e) {}
};
```

و`createInvoice()` يستدعي `hideLoader()` داخل `catch`.

إذن Current Source لا يثبت أن `SUPABASE_URL` نفسه يترك loader يدور بلا نهاية.

التصنيف الصحيح:

- ReferenceError: PROVEN
- Browser spinner stuck on the exact served artifact: NOT YET PROVEN
- Current source catch contains loader close: PROVEN

ولا يجوز تحويل وصف المستخدم لسلوك browser إلى defect مستقل في loader قبل اختبار النسخة المنشورة نفسها.

---

## 7. Current Production Deployment

Supabase project:

`fiilmooggumokxanwiyx`

Existing Edge Function:

`save-purchase-order`

Current Production version:

`7`

`verify_jwt = true`

لا يوجد إنشاء Edge Function جديد.

Current `save-purchase-order` dispatches:

`CREATE_INVOICE` → `purchase_create_invoice_atomic_v2`

و:

`POST_INVOICE` → `purchase_post_invoice_atomic`

إذن البنية المطلوبة موجودة بالفعل.

---

## 8. Current Production CREATE Contract

`purchase_create_invoice_atomic_v2`

Current contract:

```
p_company_id
p_supplier_id
p_purchase_order_id
p_branch_id
p_due_date
p_currency
p_created_by
p_supplier_invoice_no
p_notes
p_items
p_operation_id
```

ويعتمد على:

`purchase_create_invoice_atomic`

والـbase RPC:

- يطلب `operation_id`
- يمنع duplicate باستخدام `company_id + operation_id`
- يتحقق من Supplier Company scope
- يتحقق من Branch Company scope
- يتحقق من PO/Supplier relationship
- يتحقق من Item identity
- يحفظ تفاصيل الفاتورة
- يحسب subtotal / discount / tax / total
- يترك الفاتورة `Draft`

ثم v2 يضيف:

- `supplier_invoice_no`
- `notes`

ولا توجد حاجة لإعادة بناء هذا الجزء.

---

## 9. Current Production POST Contract

`purchase_post_invoice_atomic`

Current workflow:

```
Draft Invoice
      ↓
resolve branch
      ↓
validate branch/company
      ↓
validate inventory account 124
      ↓
validate supplier liability account 211
      ↓
post_stock_movement(PurchaseIn)
      ↓
post_journal_entry
      ↓
supplier_ledger
      ↓
Invoice = Posted
```

Physical stock لا يُكتب مباشرة من purchase invoice.

الـPhysical Stock contract يبقى:

```
purchase invoice
      ↓
purchase_post_invoice_atomic
      ↓
post_stock_movement
      ↓
stock_branches + inventory_log
```

وهذا متوافق مع الـcentral inventory architecture.

---

## 10. Current Production Database Baseline

تم أخذ snapshot مستقل من Production في نفس جلسة التحقيق.

Current:

- companies = 1
- suppliers = 2
- purchase_orders = 0
- purchase_order_details = 0
- purchase_invoices = 0
- purchase_invoice_details = 0
- purchase_returns = 0
- purchase_payments = 0
- inventory_log = 6
- stock_branches = 48
- supplier_ledger = 0
- journal_entries = 8
- journal_lines = 12

Main Branch:

`a38332b6-6cea-480a-ada1-6eb6ab0590db`

Test item:

`1001`

Supplier used for transactional E2E:

`SUPP-1001`

No existing purchase invoice data existed that required preservation during the test.

---

## 11. Production Schema Evidence

`purchase_invoices` currently contains:

- `supplier_invoice_no`
- `supplier_id`
- `purchase_order_id`
- `quotation_id`
- `branch_id`
- `invoice_date`
- `due_date`
- `currency`
- `status`
- `is_received`
- `received_date`
- `subtotal`
- `discount_amount`
- `tax_amount`
- `total_amount`
- `paid_amount`
- `notes`
- `operation_id`

والـSchema يفرض:

`UNIQUE(company_id, operation_id)`

وهذا هو idempotency contract المعتمد.

---

## 12. E2E Production Transaction Test

تم إنشاء اختبار كامل داخل PostgreSQL نفسه باستخدام بيانات Production حقيقية، لكن داخل anonymous transaction يتم إلغاؤها بالكامل في النهاية.

### Create

Input:

- supplier = SUPP-1001
- branch = BR-01
- item = 1001
- qty = 1
- unit price = 10
- discount = 0
- tax = 0
- currency = EGP
- operation_id = unique QA operation

Result:

```
success = true
status = Draft
total_amount = 10
invoice_code = PINV-1000
```

### CREATE replay

تم إرسال نفس `operation_id`.

Result:

```
success = true
duplicate = true
same invoice id
same invoice code
```

وبالتالي Create idempotency PASS.

### POST

تم ترحيل نفس الفاتورة.

Result:

```
success = true
status = Posted
```

### Physical Stock

Before:

`qty = 2`

After:

`qty = 3`

Delta:

`+1`

Allocated:

`0 → 0`

### Inventory Log

Delta:

`+1 row`

أي حركة PurchaseIn واحدة فقط.

### Accounting

Journal Entry delta:

`+1`

Journal Lines delta:

`+2`

Debit:

`10.00`

Credit:

`10.00`

القيد متوازن.

### Supplier Ledger

Delta:

`+1 row`

Supplier credit:

`10.00`

### POST replay

تم تكرار `purchase_post_invoice_atomic`.

Result:

```
success = true
duplicate = true
status = Posted
```

ولم تحدث حركة إضافية.

---

## 13. QA Residue Verification

بعد الاختبار تم التحقق من Production:

- purchase_invoices = 0
- purchase_invoice_details = 0
- inventory_log = 6
- journal_entries = 8
- journal_lines = 12
- supplier_ledger = 0
- QA invoice residue = 0
- QA inventory-log residue = 0
- QA journal residue = 0
- QA supplier-ledger residue = 0

إذن الاختبار لم يلوث Production.

---

## 14. Production Decision

لا توجد Production migration جديدة مطلوبة لعلاج العطل الحالي.

السبب:

- Edge Function الحالية صحيحة.
- RPC CREATE موجودة وصحيحة.
- RPC POST موجودة وصحيحة.
- idempotency موجودة رسميًا.
- branch/company validation موجود.
- stock centralization موجود.
- accounting posting موجود.
- supplier ledger موجود.

أي تعديل إضافي في Production لعلاج `SUPABASE_URL` سيكون إصلاحًا في الطبقة الخطأ.

### Production Change Count لهذه الأزمة

`0`

---

## 15. Exact Mother Surgical Patch

### لا تستبدل الدالة كاملة.

### الملف

`companies/company-1/main.html`

### Current Blob

`4eb18a27285550e81a6b1564fdb9df4708363cfa`

### الدالة

`RW_PurchaseGold.api(operation, payload, operationId)`

### السطر

`12040`

### ابحث عن هذا النص بالضبط

```js
      SUPABASE_URL + '/functions/v1/save-purchase-order',
```

### احذف السطر أعلاه فقط.

### واستبدله بهذا السطر فقط

```js
      RW_SUPABASE_URL + '/functions/v1/save-purchase-order',
```

لا تعدّل:

- `createInvoice()`
- `preConfirm`
- `showLoader/hideLoader`
- `purchase_create_invoice_atomic_v2`
- `purchase_post_invoice_atomic`
- أي جزء من Inventory
- أي جزء من العمليات الميدانية

---

## 16. Why This Is the Correct Surgical Boundary

المشكلة ليست:

- Modal DOM
- Supplier search
- Item search
- Payload structure
- Supabase RPC
- Database schema
- Accounting
- Inventory
- Edge Function

المشكلة هي فقط:

`Wrong runtime identifier for the existing Supabase base URL`

Therefore:

```
Current:
SUPABASE_URL

Target:
RW_SUPABASE_URL
```

هذا أقل تغيير آمن ويحافظ على كل ما تم بناؤه سابقًا.

---

## 17. Static Verification of the Owner Patch

Current source before patch:

- full inline script compilation = PASS
- Current code itself parses
- runtime failure remains because unresolved identifier is executed only when the function runs

In-memory surgical correction:

`SUPABASE_URL + '/functions/v1/save-purchase-order'`

→

`RW_SUPABASE_URL + '/functions/v1/save-purchase-order'`

After replacement:

- full inline script compilation = PASS
- PurchaseGold API URL expression becomes valid
- no createInvoice rewrite required

---

## 18. Same-root-cause latent references discovered

Current Mother also contains other bare `SUPABASE_URL` references.

Within the legacy `RW_Purchases` purchase module there are additional references at:

- line 11923 — `openReceive()`
- line 11995 — `savePO()`

These were **not included in the mandatory invoice patch**, because the present Closure Unit is the current `RW_PurchaseGold.createInvoice()` path.

They are recorded here to prevent a future CTO from mistakenly treating the next occurrence as an unexplained new architecture problem.

They must only be patched later if that legacy surface is proven to remain reachable in the current navigation.

---

## 19. Competitor Reconciliation

The current RAWAEA modal is not structurally deficient at the basic document level. It already contains supplier, branch, PO linkage, due date, supplier invoice number, notes, item, quantity, price, discount and tax.

However, current external product documentation shows several mature purchase controls worth recording as future Business Contract candidates, not as emergency patches.

### Odoo

Odoo supports vendor bills either from ordered quantities or received quantities, plus 3-way matching between vendor bills, purchase orders and receipts; it also supports bill reference, payment registration and purchase matching.  
Source: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/purchase/manage_deals/manage.html

### Microsoft Dynamics 365 Business Central

Business Central supports direct purchase invoices as well as purchase-order-driven receiving, and posting updates inventory/resource ledgers and financial records.  
Source: https://learn.microsoft.com/en-us/dynamics365/business-central/quick-start-procurement

### SAP

SAP documents goods-receipt-based invoice verification as an explicit procurement workflow.  
Source: https://help.sap.com/docs/business-network-for-trading-partners/supplier-business-network-supply-chain/workflow-for-goods-receipt-based-invoice-verification-881bb9ac02e54453b9c413e76bf39dae?version=2511

### Daftra

Daftra documents purchase invoice fields/features including invoice number, payment terms, line taxes, already-paid state, payment method, received state, preview, additional custom fields, supplier linking, reports and purchase/return management.  
Sources:
https://docs.daftra.com/en/tutorial/creating-a-purchase-invoice/
https://docs.daftra.com/en/user_manual/adding-purchase-invoice/
https://docs.daftra.com/en/user_manual/purchase-invoicing-settings/

### RAWAEA Gap Candidates

These are recorded for later contract work, not implemented during this emergency:

1. Explicit payment terms on invoice creation.
2. Explicit matching status between PO / receipt / invoice.
3. Goods-received versus ordered billing policy at the document level.
4. Attachment / source document.
5. Preview before save.
6. Multi-payment / already-paid workflow at invoice level.
7. Freight / landed-cost treatment.
8. Proper tax-account mapping if non-zero tax is enabled.
9. Strong invoice/PO/quotation traceability.
10. Advanced reporting and filtering around supplier, branch, currency, status and payment state.

### Important unresolved contract conflict

Current modal sends:

`currency = 'SAR'`

while surrounding older purchase UI renders monetary values as EGP.

Current Production has no purchase invoices from which the expected currency can be inferred.

Therefore currency was **not changed by assumption**.

It is an explicit Business Contract Gap requiring evidence before implementation.

---

## 20. Accounting / Tax Integrity Finding

Current chart of accounts contains:

- 124 = المخزون السلعي
- 211 = الموردون (ذمم دائنة)

No explicit VAT/input-tax account was found by current Production query.

The current invoice detail schema stores tax values, but `purchase_post_invoice_atomic` currently posts the full invoice total to inventory account 124 and supplier account 211.

This is not changed in this Closure because creating or choosing a tax account without an established RAWAEA accounting contract would violate the governing no-assumption rule.

It is a real future accounting-contract candidate whenever non-zero purchase taxes become a production requirement.

---

## 21. Browser E2E Classification

### Completed

- Current Git identity
- Current source forensic read
- Current Production RPC verification
- Current database snapshot
- Full inline-script syntax test
- Production transactional E2E Create
- CREATE retry/idempotency
- POST
- Physical stock delta
- Inventory log
- Journal entry
- Journal lines
- Supplier ledger
- POST retry/idempotency
- QA residue verification

### Still OPEN

Authenticated Browser E2E on the **served published Mother artifact after Owner applies the one-line patch**.

This is intentionally not marked PASS because the current tool path does not provide a live authenticated browser session against the owner's published Mother.

Required final Browser proof:

```
open Purchase
→ invoices
→ New Purchase Invoice
→ select supplier
→ select branch
→ add item
→ enter qty/price
→ save
→ HTTP 200
→ RPC CREATE_INVOICE
→ Draft invoice visible
→ no ReferenceError
→ loader closes
→ Console clean
→ Network clean
→ refresh
→ same invoice visible
```

Then:

```
post invoice
→ stock +qty
→ inventory_log +1 movement
→ journal +1
→ supplier ledger +1
→ replay post
→ duplicate=true / no second movement
```

---

## 22. Final Self-Audit

### What I Proved

- The failing Mother path contains a real undefined identifier.
- The current identifier is `RW_SUPABASE_URL`.
- The PurchaseGold API incorrectly references `SUPABASE_URL`.
- Production CREATE/POST infrastructure exists and works.
- Idempotency exists and works.
- Stock posting is centralized.
- Accounting posting is active and balanced.
- Supplier ledger posting is active.
- The full transactional E2E passed and was rolled back.
- Production returned to its exact pre-test counts.

### What I Did Not Prove

- Authenticated Browser E2E on the final served artifact after Owner patch.
- The exact external published artifact currently served to the browser.
- The intended business currency of RAWAEA purchase invoices.
- The approved accounting treatment for non-zero purchase VAT.

### What I Fixed

Production:

- No additional Production mutation was required.

Mother:

- Owner surgical patch prepared; no direct source mutation by assistant.

### What I Initially Missed in This Session

The same bare `SUPABASE_URL` identifier exists in other legacy purchase paths. They are documented, but intentionally not mixed into this Closure Unit.

### Final Closure

```
PURCHASE INVOICE BACKEND = VERIFIED

PRODUCTION DATA = CLEAN

ACCOUNTING E2E = PASS

STOCK E2E = PASS

IDEMPOTENCY = PASS

CURRENT SOURCE ROOT CAUSE = PROVEN

MOTHER SURGICAL PATCH = READY

BROWSER E2E AFTER OWNER PATCH = OPEN

PURCHASE INVOICE CLOSURE = PENDING ONE-LINE OWNER PATCH
```

---

## 23. Instructions to Next CTO / Assistant

Do not restart Purchase.

Start from:

```
CURRENT HEAD
0010f719a33bfcda3f2922eca66c6be55d5582a9

PARENT
b5043e626bf9eddea87644c36d024291cccff55f

CURRENT MAIN BLOB
4eb18a27285550e81a6b1564fdb9df4708363cfa
```

Then:

1. Verify that Owner applied only the exact Report328 line replacement.
2. Fetch the new main blob.
3. Parse the entire inline script.
4. Verify `RW_PurchaseGold.api()` now uses `RW_SUPABASE_URL`.
5. Verify no change to `createInvoice()`.
6. Verify the current published artifact identity.
7. Run authenticated Browser E2E.
8. Capture Console + Network + HTTP.
9. Re-check Production immediately after the browser test.
10. Only then mark this Closure Unit 100% CLOSED.
11. Do not reopen Reports 323/324 unless Current evidence contradicts them.
12. Do not change tax/currency contracts without explicit current evidence.
13. If the legacy purchase `RW_Purchases` surface is proven reachable, address its two remaining bare URL references as a separate Closure Unit.

## END REPORT328
