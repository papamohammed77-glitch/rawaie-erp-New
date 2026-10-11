# Report404 — POS Return: Current Forensic Decision & Exact Surgical Scope
**التاريخ:** 2026-10-11  
**Production:** Supabase project `fiilmooggumokxanwiyx`  
**Frontend:** `papamohammed77-glitch/erp-frontend`  
**Documentation:** `papamohammed77-glitch/rawaie-erp-New`

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** مرتجع POS يجب أن يعيد الصنف للمخزون وفق `post_stock_movement`، ويعكس أثر البيع ماليًا، ويعيد المبلغ فعلًا من وسيلة/خزنة التحصيل، مع دعم المرتجع الجزئي والكامل ومنع التكرار.
- **Architecture Understanding:** `pos.html → get_pos_invoice_data → complete-return (Edge) → complete_sales_return_credit_note_atomic → complete_return_atomic → post_stock_movement`.
- **Database Understanding:** فواتير POS النقدية قد تحمل `customer_id=NULL`. `cash_box` يسجل إيصال البيع ويشير إلى `treasury_id`، لكن لم يظهر كيان موثّق لوردية/درج منفصل لكل كاشير.
- **Historical Understanding:** تمت قراءة Report403، وCURRENT_STATE الحالي، وmigration الخاصة بـ`get_pos_invoice_data`، ومصدر POS الحالي، وتعريفات Core المنشورة.
- **Production Understanding:** تم فحص Edge `complete-return` الحية: v26، `verify_jwt=true`، وقراءة تعريفات Core وACL الحية.
- **Current Understanding:** `pos.html` الحالي blob `967d486147cf3ca9911c4dbd3ba89042c373577e`; آخر commit مسجل في مصدر الواجهة `950abb6b78680d37c8d29f1beba78c8c1d6a51a4`. لم يتم تعديل `main.html` أو `pos.html`.
- **Execution Confidence:** عالٍ في تحديد عيب Core؛ غير كافٍ لإعلان أن رد الأموال أو اختبار HTTP/Browser قد اكتمل.

## 1. أدلة Production الحالية

### Edge
- `complete-return`: **v26**, active, JWT verification enabled.
- يستدعي `complete_sales_return_credit_note_atomic(uuid,text,text,boolean,text,jsonb,text)`.

### Core / ACL
- `complete_return_atomic(uuid,text,text,boolean,text,jsonb)`: `SECURITY DEFINER`; التنفيذ محصور في `service_role` (anon=false, authenticated=false, service_role=true).
- `complete_sales_return_credit_note_atomic(...,text)`: `SECURITY DEFINER`; التنفيذ محصور في `service_role`.
- `get_pos_invoice_data(text,text)`: `SECURITY DEFINER`; anon=false, authenticated=true, service_role=true.

### Invoice fixture already in Production (read-only evidence)
- `ORD-1004`: company `00000000-0000-0000-0000-000000000001`, branch `a38332b6-6cea-480a-ada1-6eb6ab0590db`, source `pos`, status `Invoiced`, total `275.00`, payment `نقدي`, `customer_id=NULL`.
- Receipt `cash_box` amount `275.00`, source_type `POS`, reference `ORD-1004`, treasury = `0a9d9357-b5f3-4dfa-886f-7c73de4f274e` (الخزينة الرئيسية).
- No business data was inserted, updated, or deleted in this investigation.

## 2. Root cause — two distinct issues

### A. Invoice lookup error
The current source already calls `get_pos_invoice_data('return_lookup', code)`; it does not directly query `orders/order_details` for return lookup. The live RPC is present and ACL is verified. Previous DB claim simulation returned `ORD-1004` and its details. Therefore the old claim that the live database categorically cannot find the invoice is **not supported by current evidence**. A real browser/HTTP request and served-artifact check are still needed to determine whether the deployed page/Service Worker or request context differs.

**Surgical decision:** do not replace `self._searchReturnInvoice` or `self.switchView` with an old report patch. The current Git file already contains those changes. No new frontend patch is justified solely by the old message without a fresh browser trace.

### B. Actual return-finance defect
`complete_return_atomic` performs inventory movement through `post_stock_movement`, creates a journal entry for inventory/COGS, and then executes:
`IF v_order.customer_id IS NULL THEN RAISE EXCEPTION 'RETURN_CUSTOMER_REQUIRED_FOR_FINANCIAL_POSTING'; END IF;`
before customer-ledger posting. This breaks cash POS invoices whose customer is the generic cash customer (`customer_id=NULL`).

Removing this check alone is **not** a valid repair: it would merely skip the customer ledger while still not paying cash/card back to the customer. The current UI's success message explicitly says no cash/card refund is performed. The historical POS flow also did not send a refund method, refund amount, or cashier-drawer identity to the server.

## 3. Surgical modification — exact scope

### Do not change
- `erp-frontend/companies/company-1/main.html` — owner-only; untouched.
- `erp-frontend/companies/company-1/sales/pos.html` — untouched in this cycle; current lookup/navigation fixes are already present.
- Do not delete `ORD-1004` or `ORD-1005`; linked cash-box/journal records mean they are not disposable QA rows.

### The defective element
- **Production function:** `public.complete_return_atomic(uuid,text,text,boolean,text,jsonb)`
- **Defective branch:** the POS/order financial-posting block that rejects `v_order.customer_id IS NULL` with `RETURN_CUSTOMER_REQUIRED_FOR_FINANCIAL_POSTING`.
- **Why not simply remove it:** that check is currently protecting an incomplete financial contract. Deleting it would permit inventory/credit-note changes without a real cash/card refund and would not debit the correct cashier's drawer.

### Required permanent replacement contract
The safe repair must be one atomic, authenticated server-side contract that:
1. locks and validates the original POS order and its receipt;
2. verifies the cashier/company/branch and the actual cashier shift/drawer that collected the payment;
3. caps each returned quantity against the sold quantity less prior returns;
4. posts the physical return only through `post_stock_movement`;
5. records an idempotent refund linked to the original invoice and return operation;
6. refunds only through the original/authorized tender (cash/card/split), rejects insufficient drawer balance, and updates `cash_box`/treasury using the existing accounting contract;
7. posts balanced accounting entries, without inventing a customer ledger entry for a generic cash customer;
8. writes audit evidence and returns the refund receipt/reference;
9. supports partial return, retry, duplicate, concurrent request, and rollback tests.

### Why no Production mutation was applied
Live schema evidence confirms `treasury` and `cash_box`, but does **not** confirm a cashier shift/drawer entity or a binding from the cashier's authenticated identity to the actual till used at checkout. The current receipt for `ORD-1004` points to the main treasury, not an individually proven cashier drawer. No safe mapping can be inferred from the cashier email or branch. A Production SQL change that guesses this mapping could refund from the wrong treasury or create an unbalanced ledger. Accordingly, no Core condition was removed and no financial data was mutated. This is a deliberate prevention of a false/unsafe fix, not a declaration of completion.

## 4. Required owner-side change after the backend contract is implemented
The owner must then make a single surgical change in `companies/company-1/sales/pos.html`:
- **Function:** `self._finalizeReturn`
- **Current behavior:** sends `order_code/items/is_pos_return/reason` to `complete-return` and correctly describes the result as a credit note, not a cash/card refund.
- **Required replacement:** send the backend-issued `refund_method` / tender allocation and `cashier_shift_id` (or equivalent server-issued drawer session identifier), and display the server-confirmed refund reference/amount. The exact full replacement block must be generated against the newly deployed RPC/API signature; adding guessed fields now would be ignored or rejected by the existing Edge contract.
- **Do not change the lookup function** unless a fresh browser trace proves a defect in the current source.

## 5. Test matrix required before closure

| Test | Required proof |
|---|---|
| Authorized invoice lookup | real authenticated HTTP/browser request returns invoice and details |
| Unauthorized branch/company | no invoice disclosure |
| Cash partial return | stock movement + cash refund + balanced journal + audit, all once |
| Full return | invoice state and remaining quantities correct |
| Card/split return | correct original tender and refund reference |
| Duplicate retry / concurrency | one return/refund only |
| Insufficient drawer | full rollback; no stock/ledger/cash changes |
| Damaged item | no saleable stock increase unless the established condition contract permits it |
| Baseline restoration | fixture removed or restored; no residue |
| Served frontend | deployed artifact verified against current Git; Service Worker cache checked |

## 6. Status
- Current POS source read path: **PRESENT**
- Production read RPC and ACL: **VERIFIED**
- Core customer-null failure: **CONFIRMED**
- Cashier drawer/shift mapping: **NOT VERIFIED / NOT PRESENT IN THE VERIFIED SCHEMA**
- Actual cash/card refund: **NOT IMPLEMENTED BY CURRENT CONTRACT**
- Live HTTP/browser E2E and served-artifact parity: **UNVERIFIED**
- `main.html` changed: **NO**
- `pos.html` changed: **NO**
- Production business data changed: **NO**
- Closure: **OPEN — no false 100% claim**

## SELF-AUDIT FINAL
- **What I Proved:** live Edge v26 and its Core chain; ACLs; the exact customer-null rejection; a real POS invoice with null customer and a receipt tied to the main treasury; current Git already contains the invoice read RPC and navigation fix.
- **What I Did Not Prove:** live browser HTTP behavior, served asset parity, individual cashier till identity, or an actual cash/card refund.
- **What I Fixed:** no code/data mutation; identified the precise unsafe branch and prevented an incomplete bypass.
- **What I Initially Missed:** lookup success and financial return completion are separate capabilities; credit-note creation is not a cash refund.
- **What Could Still Be Wrong:** the production host may serve a stale frontend; additional payment/treasury conventions may exist outside the inspected tables, and must be found before implementing the refund contract.
- **Final Confidence:** high for root cause; insufficient for production closure.
- **Final Closure Status:** `OPEN — CORE FINANCIAL CONTRACT REQUIRES A VERIFIED CASHIER-TILL BINDING BEFORE SAFE DEPLOYMENT`.
