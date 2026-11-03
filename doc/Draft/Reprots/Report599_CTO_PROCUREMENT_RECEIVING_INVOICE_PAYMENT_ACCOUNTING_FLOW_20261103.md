# RAWAEA ERP — دورة المشتريات والاستلام والفاتورة والسداد والمرتجع

**Checkpoint:** LVE-2026-11-03-599  
**التاريخ:** 2026-11-03  
**الحالة:** PROCUREMENT ACCOUNTING FLOW MAPPED / RECEIVING AUTHORIZATION GAP CARRIED FORWARD / POLICY QUESTIONS OPEN  
**نقطة البداية:** LVE-598.

---

## 1. النطاق

تم تتبع تعريفات Production التالية:
- receive_purchase_atomic overloads.
- purchase_create_invoice_atomic_v2.
- purchase_post_invoice_atomic.
- purchase_post_payment_atomic.
- purchase_post_return_atomic.
- purchase_update_draft_invoice_atomic.

الهدف هو إثبات أين يحدث المخزون والالتزام المالي فعليًا، ومنع تكرار أثر الاستلام عند ترحيل الفاتورة.

---

## 2. إنشاء فاتورة Draft

purchase_create_invoice_atomic_v2:
- SECURITY DEFINER، EXECUTE محصور في service_role.
- يشترط operation_id.
- يفوض إنشاء الفاتورة إلى purchase_create_invoice_atomic.
- يحدث supplier_invoice_no وnotes على الفاتورة الجديدة.
- لا يرحل المخزون أو AP بمجرد إنشاء Draft.

إذًا إنشاء الفاتورة ليس استلامًا ولا ترحيلًا ماليًا.

---

## 3. الاستلام الفعلي — Receiving

receive_purchase_atomic (5 args):
- SECURITY DEFINER، EXECUTE محصور في service_role.
- يتحقق من الشركة النشطة، المستخدم النشط داخل الشركة، ووجود PO.
- يشترط operation_id.
- يبني operation key خاصًا بـPO/company/operation_id.
- يحسب payload fingerprint من item_code وreceived_qty.
- يرفض إعادة استخدام المفتاح مع كميات مختلفة.
- يقفل PO وتفاصيله.
- يتحقق من أن الصنف موجود في PO وأن الكمية لا تتجاوز المتبقي غير المستلم.
- يحدد receiving branch من PO branch أو main branch.
- ينشئ receiving + receiving_details.
- يستدعي post_stock_movement(PurchaseIn) لزيادة stock_branches وتسجيل inventory_log.
- يزيد purchase_order_details.qty_received.
- يغير حالة PO إلى Received أو Partially Received.
- ينشئ journal entry من Inventory account 124 إلى Supplier account 211.
- ينشئ supplier_ledger credit بقيمة البضاعة المستلمة.
- يسجل audit event.

**أثر الاستلام CONFIRMED:** المخزون والالتزام المالي يُسجلان عند الاستلام، وليس عند مجرد إنشاء PO أو Draft invoice.

### تفويض الاستلام

receive-purchase Edge v12 لا يفرض effective receiving/warehouse permission. وRPC يتحقق من المستخدم النشط والشركة لكنه لا يفرض warehouse permission أو receiver assignment. هذه فجوة تفويض carried forward من LVE-590؛ لا يوجد استلام اختباري في هذه الجولة.

---

## 4. ترحيل فاتورة مرتبطة بـPO

purchase_post_invoice_atomic:
- SECURITY DEFINER، EXECUTE محصور في service_role.
- يقفل الفاتورة ويتحقق من الشركة والحالة.
- يتحقق من عملة النظام وعملة PO.
- يشترط وجود receiving للـPO قبل الترحيل.
- يتحقق أن كل صنف بالفاتورة موجود في PO.
- يتحقق أن invoice qty لا تتجاوز qty_received بعد خصم الكميات المفوترة سابقًا.
- يتحقق من unit price وtax مقابل PO.
- يتحقق من إجمالي الفاتورة مقابل PO total.
- يحدث invoice status إلى Posted.
- يعيد صراحة:
  - stock_posted_by_invoice=false
  - supplier_liability_posted_by_invoice=false

**النتيجة:** الفاتورة المرتبطة بـPO لا تكرر حركة المخزون أو الالتزام الذي سجله Receiving. الاستلام هو مصدر PurchaseIn/AP في المسار الحالي.

### الفاتورة السريعة غير المرتبطة بـPO

- إذا كان purchase_order_id NULL، يرفع RPC خطأ PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED.
- لذلك لا يمكن ترحيل quick invoice مستقلة دون ربطها بـPO واستلام فعلي.
- يوجد بعد هذا الشرط كود لحركة PurchaseIn وقيد AP؛ لكنه غير قابل للوصول عندما يكون purchase_order_id NULL بسبب RAISE EXCEPTION السابق.

**قرار مطلوب من المالك:** هل يجب أن تمر مشتريات السوق السريعة أيضًا عبر PO/Receiving؟ إذا نعم، فالمنع مقصود. إذا كان المطلوب مسار شراء سوقي مباشر بعهدة وفاتورة واستلام، فالعقد الحالي لا يحقق ذلك ويحتاج مسارًا واضحًا دون مضاعفة المخزون/AP.

---

## 5. سداد المورد

purchase_post_payment_atomic:
- يشترط operation_id ومبلغًا موجبًا.
- يتحقق من المورد والخزينة داخل الشركة.
- يحترم purchase_settings.require_invoice_before_payment.
- يمنع تخصيص مبالغ تتجاوز قيمة السداد.
- يستدعي post_cash_payment_atomic لتسجيل حركة الخزينة/النقدية.
- ينشئ purchase_payment وpurchase_payment_allocations.
- يزيد paid_amount ويحول الفاتورة إلى PartiallyPaid أو Paid.
- يسجل supplier_ledger debit بقيمة السداد.

**الأثر:** السداد يخفض الالتزام على المورد ويخفض الخزينة عبر cash payment atomic، ولا يغير المخزون.

---

## 6. مرتجع المورد

purchase_post_return_atomic:
- يقفل سجل المرتجع ويتحقق من Draft/Posted.
- يتحقق من الفرع والحسابات.
- لكل صنف يستدعي post_stock_movement(SupplierReturn) من branch إلى NULL.
- ينشئ journal entry: debit Supplier account 211 / credit Inventory account 124.
- ينشئ supplier_ledger debit.
- يغير حالة المرتجع إلى Posted.

**الأثر:** المرتجع يخفض مخزون الفرع ويخفض التزام المورد وفق الحسابات المحددة.

---

## 7. تحرير Draft invoice

purchase_update_draft_invoice_atomic:
- يشترط operation_id.
- يثبت المستخدم النشط والشركة.
- لا يسمح إلا بفاتورة Draft غير مستلمة وغير مرحلة وغير مدفوعة.
- يرفض إذا received_qty > 0.
- يرفض إذا وجدت buyer custody expense أو payment allocation أو purchase return أو stock voucher مرتبطة بالفاتورة.
- يتحقق من المورد والفرع وPO والعملات وسياسة receiving.
- يعيد إنشاء التفاصيل ويحدث Draft history.

هذا يمنع تعديل مستند له آثار مخزنية/مالية لاحقة.

---

## 8. المعالجة المحاسبية — نقطة تحتاج قرارًا

المسار الحالي يسجل عند الاستلام:
- Dr Inventory (124).
- Cr Supplier account (211).
- supplier_ledger credit.

ثم ترحيل فاتورة PO لا يضيف AP أو مخزونًا مرة أخرى.

هذا تصميم مبسط يعترف بالتزام المورد عند الاستلام. في أنظمة ERP مثل SAP/Dynamics يوجد غالبًا فصل بين Goods Receipt/GRNI وInvoice Receipt/AP عبر حساب وسيط (GR/IR أو GRNI)، ثم تسوية الفرق عند الفاتورة.

لا يعني ذلك أن التصميم الحالي خطأ تلقائيًا؛ يجب حسم السياسة:
- هل التزام المورد ينشأ عند الاستلام حتى لو لم تصل فاتورة المورد؟
- هل account 211 يمثل AP مباشرًا أم حسابًا وسيطًا؟
- كيف يعالج فرق سعر/ضريبة/كمية بين PO والفاتورة؟
- هل المطلوب three-way match بين PO وGRN وSupplier Invoice؟

لا تغيّر الحسابات أو القيود قبل قرار محاسب/مالك النظام.

---

## 9. مصفوفة الأثر

| الحدث | Stock | Supplier Ledger | Journal | Treasury |
|---|---|---|---|---|
| Create Draft Invoice | لا | لا | لا | لا |
| Receive PO | PurchaseIn + | Credit + | Dr Inventory / Cr Supplier | لا |
| Post PO Invoice | لا | لا | لا (تأكيد المستند فقط) | لا |
| Post Payment | لا | Debit - | عبر cash payment atomic | خروج نقدية |
| Post Supplier Return | SupplierReturn - | Debit - | Dr Supplier / Cr Inventory | لا |

---

## 10. ما تم وما لم يتم

**تم:**
- قراءة تعريفات RPC المذكورة.
- تتبع كل stock/ledger/journal/cash effect في المصدر.
- مطابقة عدم تكرار المخزون/الالتزام عند Post Invoice المرتبط بـPO.
- تحديد شرط quick invoice المرتبطة بـPO/Receiving.

**لم يتم:**
- لم يتم إنشاء PO أو استلام أو فاتورة أو سداد أو مرتجع.
- لم يتم اختبار partial receiving أو retry.
- لم يتم تغيير حسابات أو بيانات أو RPC أو Edge.
- لم يتم اختبار واجهة Buyer/Receiver E2E.

---

## 11. الأولوية

1. حسم سياسة quick market purchase: هل PO/Receiving إلزامي؟
2. حسم سياسة الاعتراف بالمورد عند GRN: AP مباشر أم GRNI وسيط.
3. إصلاح تفويض receive-purchase على الخادم مع warehouse/receiver assignment.
4. اختبار PO → partial receive → invoice → payment → supplier return على fixture معزول، ومقارنة stock_branches وinventory_log وsupplier_ledger وjournal_entries وtreasury قبل/بعد.
5. الحفاظ على منع تكرار stock/AP عند ترحيل فاتورة PO.

**الحالة:** PROCUREMENT FLOW SOURCE/DB CONFIRMED / ACCOUNTING POLICY UNKNOWN / RECEIVING AUTHORIZATION GAP CONFIRMED / RUNTIME UNVERIFIED / NOT CLOSED.
