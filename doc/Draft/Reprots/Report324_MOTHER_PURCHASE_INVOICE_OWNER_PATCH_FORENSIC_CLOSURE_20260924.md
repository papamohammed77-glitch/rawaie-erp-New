# RAWAEA ERP — تقرير التحقيق الجنائي والإغلاق الجراحي
## Mother Main → فواتير الشراء → Smart Search / Invoice Metadata
## 2026-09-24

### 1. نطاق المهمة

Closure Unit:
Mother ERP → دورة المشتريات → فواتير الشراء → `RW_PurchaseGold.createInvoice()`

قاعدة الحقيقة:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

التقارير السابقة استُخدمت كقرائن فقط ثم أُعيد التحقق من المصدر الحالي وProduction الحالية.

لا تعديل مباشر للمصدر المملوك للمالك داخل `main.html`.

---

## 2. آخر حالة Git المثبتة

### System Repository
Current pre-report HEAD:
`89058fcdb80e311694607a8a24e653b2fc5570ca`

Parent:
`1b4744eb345c652dec9745b141e704be69c0d04e`

آخر تقرير شراء سابق:
`Report323_MOTHER_PURCHASE_INVOICE_SMART_SEARCH_FORENSIC_SURGICAL_CLOSURE_20260923.md`

### Mother Frontend
Repository:
`papamohammed77-glitch/erp-frontend`

Current HEAD:
`ae6049f9672031da7113b2b1296e7f3fee14eeee`

Parent:
`1799a7107460410840efbd76a1145e624f0b2a34`

Current `companies/company-1/main.html` blob:
`e1766d81a59a5e18d654f0366846701c36922edf`

Commit message:
`Update main.html`

مهم:
هذا هو Owner Commit الذي طبّق Patch-323 فعليًا بعد Report323.

---

## 3. Current Source Forensics

### 3.1 ما تم تطبيقه فعليًا من Report323

Verified in current Mother source:

- Supplier smart-search UI exists.
- Supplier hidden identity field exists.
- Supplier dropdown exists.
- Item smart-search UI exists.
- Item dropdown exists.
- `purchaseSupplierSearch()` exists.
- `purchaseItemSearch()` exists.
- PO → supplier synchronization patch exists.
- `pg-i-add` selected-item logic exists.
- supplier invoice number field exists.
- invoice notes field exists.
- `supplier_invoice_no` is no longer deleted before API call.

### 3.2 ما لم يُطبق بشكل صحيح

#### Defect A — orphaned legacy handler tail

Current source lines 13543–13550 contain:

```javascript
            byId('pg-i-code').value = '';
            byId('pg-i-add-qty').value = '';
            byId('pg-i-add-price').value = '';
            renderLines();
          } catch (e) {
            Swal.showValidationMessage(e.message);
          }
        });
```

هذا الجزء هو بقايا من الـhandler السابق.

الـhandler الجديد مكتمل بالفعل عند:

```javascript
        });
```

في السطر 13542.

إبقاء الجزء القديم بعده ينتج:

`SyntaxError: Unexpected token 'catch'`

### 3.3 Proof

تم استخراج آخر Mother blob وتحويل الـinline script الحالي إلى compilation test.

Current source:
`FAIL — SyntaxError Unexpected token 'catch'`

بعد حذف الجزء المحدد أعلاه:
`PASS`

---

## 4. Defect B — Invoice Notes لم تدخل Payload

Current `preConfirm` عند الأسطر 13573–13589 يحتوي:

```javascript
supplier_invoice_no: byId('pg-i-supplier-no').value.trim(),
currency: 'SAR',
```

لكن لا يحتوي:

```javascript
notes: byId('pg-i-notes').value.trim(),
```

وبالتالي:
UI field موجود،
Production RPC يدعم `notes`،
Production Edge يدعم `notes`،
لكن Mother UI لا ترسل القيمة.

هذا هو سبب عدم اكتمال Patch-323-07.

---

# 5. Production Current Truth

## Edge

`save-purchase-order`

Version:
7

Status:
ACTIVE

JWT:
true

Current deployed source matches canonical Current source.

CREATE_INVOICE يمر عبر:

```
purchase_create_invoice_atomic_v2
```

ولا توجد حاجة إلى Edge Function جديدة.

---

## 6. Production RPC Contract

### CREATE

`purchase_create_invoice_atomic_v2`

Signature:

```
p_company_id uuid
p_supplier_id uuid
p_purchase_order_id uuid
p_branch_id uuid
p_due_date date
p_currency text
p_created_by text
p_supplier_invoice_no text
p_notes text
p_items jsonb
p_operation_id text
```

الـRPC:

1. يتحقق من `operation_id`.
2. يمنع إعادة CREATE لنفس operation.
3. يتحقق من supplier/company.
4. يتحقق من branch/company.
5. يحافظ على Purchase Core الأصلي.
6. يحفظ `supplier_invoice_no`.
7. يحفظ `notes`.

### POST

`purchase_post_invoice_atomic`

يقوم بـ:

```
Purchase Invoice
    ↓
post_stock_movement
    ↓
stock_branches
+
inventory_log
    ↓
Journal
    ↓
Supplier Ledger
```

---

# 7. Fresh Production E2E

تم تنفيذ اختبار جديد داخل Transaction حقيقية ثم `ROLLBACK`، بدون أي QA residue.

### السيناريو

Supplier مؤقت
→ Invoice CREATE
→ CREATE Replay
→ POST
→ POST Replay
→ Stock
→ Inventory Log
→ Supplier Ledger
→ Journal
→ Invoice Detail
→ Rollback

### النتائج المثبتة

#### CREATE

```
success = true
status = Draft
invoice_code = PINV-1000
total_amount = 110
supplier_invoice_no = SUP-INV-E2E-20260924-02
notes = Notes-OK
```

#### CREATE Replay

```
success = true
duplicate = true
same invoice id
```

#### POST

```
success = true
status = Posted
journal.status = Posted
journal.line_count = 2
journal.total_debit = 110
journal.total_credit = 110
```

#### POST Replay

```
success = true
duplicate = true
```

#### Stock

```
before = 3
after  = 5
delta  = +2
```

#### Inventory Log

```
invoice movements = 1
```

#### Supplier Ledger

```
rows   = 1
credit = 110
```

#### Invoice Detail

```
qty          = 2
received_qty = 2
tax_amount   = 10
line_total   = 110
```

#### Persisted Invoice

```
status              = Posted
is_received         = true
supplier_invoice_no = SUP-INV-E2E-20260924-02
notes               = Notes-OK
paid_amount         = 0
```

### Rollback

تم عمل `ROLLBACK`.

لا توجد فاتورة دائمة.
لا يوجد Supplier اختبار دائم.
لا توجد حركة مخزنية اختبارية دائمة.
لا يوجد Journal اختبار دائم.
لا يوجد Supplier Ledger اختبار دائم.

---

# 8. Production Purchase Core Classification

| Capability | Current Truth |
|---|---|
| Supplier company scope | PASS |
| Item identity | PASS |
| CREATE invoice | PASS |
| CREATE idempotency | PASS |
| Supplier invoice reference | PASS |
| Notes persistence | PASS |
| POST invoice | PASS |
| POST idempotency | PASS |
| Physical stock | PASS |
| inventory_log | PASS |
| Supplier Ledger | PASS |
| Journal | PASS |
| Debit/Credit balance | PASS |
| Invoice received_qty | PASS |
| Rollback safety | PASS |
| New Edge Function required | NO |
| Production backend change required now | NO |

---

# 9. Mother Main Surgical Correction

## PATCH-324-01 — remove corrupted legacy handler tail

File:

`companies/company-1/main.html`

Function:

`RW_PurchaseGold.createInvoice()`

Current lines:

`13543–13550`

### ابحث عن هذا النص بالضبط

```javascript
            byId('pg-i-code').value = '';
            byId('pg-i-add-qty').value = '';
            byId('pg-i-add-price').value = '';
            renderLines();
          } catch (e) {
            Swal.showValidationMessage(e.message);
          }
        });
```

### احذفه بالكامل

لا تحذف `});` السابق في السطر 13542.

لا تستبدل هذا الجزء بدالة جديدة.

بعد الحذف مباشرة يجب أن ينتقل الكود من:

```javascript
        });
      },
      preConfirm: function () {
```

---

# 10. Mother Main Surgical Correction

## PATCH-324-02 — send invoice notes

File:

`companies/company-1/main.html`

Function:

`RW_PurchaseGold.createInvoice()`

Section:

`preConfirm`

Current location:
حوالي السطر 13578.

### ابحث عن هذا السطر بالضبط

```javascript
supplier_invoice_no: byId('pg-i-supplier-no').value.trim(),
```

### أضف بعده مباشرة

```javascript
notes: byId('pg-i-notes').value.trim(),
```

ليصبح الجزء:

```javascript
supplier_invoice_no: byId('pg-i-supplier-no').value.trim(),
notes: byId('pg-i-notes').value.trim(),
currency: 'SAR',
```

لا تعدل أي سطر آخر في هذا الجزء.

---

# 11. لماذا هذه التعديلات فقط

لا توجد Current Evidence تبرر تعديل:

- `purchaseItemLookup`
- `purchaseSupplierSearch`
- `purchaseItemSearch`
- `post_stock_movement`
- `purchase_create_invoice_atomic`
- `purchase_create_invoice_atomic_v2`
- `purchase_post_invoice_atomic`
- `stock_branches`
- `inventory_log`
- Supplier Ledger
- Journal engine
- Purchase Edge Function
- Purchase database schema

كل هذه النقاط تم إثباتها من Current Source/Production ولم يظهر تناقض جديد.

---

# 12. Competitive Contract Check

الدراسة الحالية تؤكد أن نموذج Purchase Invoice الناضج يتضمن:

- Supplier
- Supplier Invoice Reference
- Invoice/Issue date
- Due date / payment terms
- Purchase Order relationship
- Item lines
- Quantity
- Unit price
- Tax
- Discount
- Posting/accounting impact
- Accounts payable / supplier balance
- Inventory relationship
- Invoice verification/matching في الأنظمة الأكثر تقدمًا

Manager يوثق Supplier + Reference + Due Date + Order Number + Description + Item/Qty/Unit Price + Tax + Discount، مع أثر على Accounts Payable والمخزون والحسابات.  
SAP يوثق Supplier Invoice Reference، PO reference، quantity/amount/tax، والتحقق مقابل PO/GR قبل الـPost.  

Official references:

- Manager:
https://www2.manager.io/guides/7189
- SAP:
https://help.sap.com/docs/SAP_S4HANA_CLOUD/031c345485b84c8c94265be9ef61d3a8/4e246b54f94c8f4ce10000000a4450e5.html
- SAP Supplier Invoice with PO/GR:
https://help.sap.com/docs/s4hana-cloud-best-practices/service-and-material-procurement-project-based-services-j13-de/create-supplier-invoice-with-po-gr-relation-9c2c6d2584e94f41a847c4838417ab3e

### RAWAEA current gap

لا توجد Current Evidence تستوجب إعادة بناء Purchase Core.

الـbackend الحالي لديه:
PO relationship
+
Supplier Invoice Reference
+
Notes
+
Item lines
+
Tax/Discount
+
Inventory posting
+
AP ledger
+
Journal
+
Idempotency.

الفجوة الحالية المؤكدة في هذه closure هي Mother frontend execution فقط.

أما 3-way matching / tolerance / workflow / approval routing فهي Business Contracts مستقلة، ولا تُضاف داخل هذا patch دون فتح Closure Unit جديدة.

---

# 13. Full Main Static Verification Status

Current Mother blob:
`e1766d81a59a5e18d654f0366846701c36922edf`

Current source:
`Syntax FAIL`

Failure:
`Unexpected token 'catch'`

After PATCH-324-01 + PATCH-324-02:
`Inline Script Syntax PASS`

تم إثبات ذلك بالـcompilation test داخل نفس Current Source.

---

# 14. Browser E2E Classification

Browser E2E الحقيقي لم يتم الإعلان عنه PASS لعدم وجود جلسة Browser مصادق عليها يمكنها:

- فتح Mother ERP فعليًا.
- تنفيذ Supplier typing/click.
- تنفيذ Item typing/click.
- الضغط على Save.
- التقاط Network.
- التقاط Console.
- التحقق من served artifact.

لذلك:

```
Production DB/RPC E2E = PASS

Browser E2E = OPEN
```

لا يجوز تحويل أحدهما إلى الآخر.

---

# 15. Closure Status

## Production Purchase Core
CLOSED / VERIFIED

## Purchase Invoice Reference
CLOSED / VERIFIED

## Purchase Invoice Notes Backend
CLOSED / VERIFIED

## Supplier Smart Search Backend
CLOSED / VERIFIED

## Item Smart Search Backend
CLOSED / VERIFIED

## Mother Main Source
FOUND DEFECT / OWNER PATCH READY

## Mother Main Full Syntax
OPEN until PATCH-324-01

## Mother Notes Payload
OPEN until PATCH-324-02

## Authenticated Browser E2E
OPEN

---

# 16. Exact Next Resumption Point

1. Verify Mother HEAD:
   `ae6049f9672031da7113b2b1296e7f3fee14eeee`

2. Verify main blob:
   `e1766d81a59a5e18d654f0366846701c36922edf`

3. In `RW_PurchaseGold.createInvoice()`:
   delete PATCH-324-01 exact block only.

4. Add PATCH-324-02 exact line only.

5. Parse the full inline script.

6. If parse PASS:
   commit Owner frontend.

7. Publish Mother frontend.

8. Verify served artifact identity.

9. Fresh authenticated session.

10. Purchase Cycle → Purchase Invoices.

11. Supplier smart search:
   name / code / phone.

12. Item smart search:
   code / name / barcode.

13. Select supplier.

14. Select item.

15. Create Draft invoice.

16. Verify:
   supplier_invoice_no
   notes
   supplier_id
   branch_id
   items.

17. POST invoice.

18. Verify:
   purchase_invoices
   purchase_invoice_details
   stock_branches
   inventory_log
   supplier_ledger
   journal_entries
   journal_lines.

19. Replay same CREATE operation.

20. Replay same POST operation.

21. Verify no duplicate stock/accounting.

22. Verify Realtime refresh.

23. Capture fresh Production snapshot.

24. Update CURRENT_STATE.

25. Only after this closure open the next real Business Contract gap.

---

# 17. Anti-Regression Rule

لا تعيد تطبيق Report323.

الـcurrent Owner Commit يحتوي بالفعل على معظم Patch323.

التعديل الجراحي الجديد يقتصر على:

```
PATCH-324-01
PATCH-324-02
```

ولا يجوز استبدال `createInvoice()` كاملة.

---

# 18. Final Self-Audit

### What I Proved

- Current Mother HEAD and parent.
- Current main.html blob.
- Owner applied Report323 changes.
- Current Mother source has one concrete syntax defect.
- Current Mother source omitted one concrete payload field.
- Production Edge Version 7 is current.
- Production RPC contract is current.
- CREATE / Replay tested.
- POST / Replay tested.
- Physical stock delta tested.
- Inventory Log tested.
- Supplier Ledger tested.
- Journal tested.
- Invoice reference tested.
- Notes persistence tested.
- Rollback tested.
- No permanent QA residue.
- No new Edge Function required.
- Backend Purchase Core does not need another rewrite.

### What I Did Not Prove

- Live authenticated Browser E2E.
- Served artifact after Owner commit.
- Actual browser Network/Console evidence.

### What Was Found

- Previous owner patch was incomplete.
- Exact syntax corruption: obsolete handler tail.
- Exact data omission: missing notes payload field.

### What Was Not Changed

- No closed backend contract reopened.
- No new Edge Function.
- No production purchase-core rewrite.
- No modification to operational field PWAs.
- No direct write to owner-owned Mother source.

### Final State

```
PURCHASE BACKEND CORE = CLOSED / VERIFIED

MOTHER MAIN SURGICAL PATCH = READY

FULL MOTHER SYNTAX = OPEN UNTIL OWNER PATCH

BROWSER E2E = OPEN

PURCHASE GOLD CLOSURE = NOT YET 100%
```

---

# 19. Instructions to Next CTO / Assistant

REPORT = clue

CURRENT GIT = source identity

CURRENT SOURCE = actual implementation

CURRENT PRODUCTION = deployed contract

CURRENT DATABASE = persisted truth

CURRENT DEPLOYMENT = runtime deployment identity

CURRENT BROWSER = UI truth

ابدأ من Current Mother HEAD، وليس من Report323.

تحقق من blob SHA قبل أي patch.

لا تعيد Patch323.

ابحث فقط عن PATCH-324-01 وPATCH-324-02.

بعد Owner patch:
parse → commit → publish → served artifact → fresh browser → E2E → Production snapshot → CURRENT_STATE.

أي نتيجة جديدة يجب ربطها أولًا بـ:
SHA + deployment version + exact source + Production row + timestamp.

إذا لم تتطابق هذه الخمس، لا تُعلن defect جديدًا.
