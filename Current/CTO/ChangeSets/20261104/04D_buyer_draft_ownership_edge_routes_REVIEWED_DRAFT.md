# Buyer — توصيل حراسة ملكية المسودات بمدخل Edge الحالي

هذا الملف يكمل SQL `03J_buyer_draft_ownership_guards_REVIEWED_DRAFT.sql`. لا يغير العمليات العامة التي قد تستخدمها تطبيقات/مستهلكات مشتريات أخرى؛ يضيف عمليتين واضحتين مخصصتين لمدخل Buyer.

## 1. أسماء العمليات الجديدة

| عملية Buyer | الوظيفة المركزية | الغرض |
|---|---|---|
| `UPDATE_BUYER_LEGACY_DRAFT` | `purchase_update_buyer_legacy_draft_atomic` | تعديل مسودة قديمة غير مصنفة يملكها المستخدم الحالي |
| `DELETE_BUYER_DRAFT_INVOICE` | `purchase_delete_buyer_draft_invoice_atomic` | حذف مسودة PO أو Legacy يملكها المستخدم الحالي أو المالك |

تظل العمليات العامة الحالية `UPDATE_DRAFT_INVOICE` و`DELETE_DRAFT_INVOICE` دون تغيير في Edge حتى لا تتغير عقود مستهلكين آخرين. واجهة Buyer وحدها تنتقل إلى العمليات الجديدة.

## 2. حراسة الصلاحية في مدخل Edge

أضف `UPDATE_BUYER_LEGACY_DRAFT` و`DELETE_BUYER_DRAFT_INVOICE` إلى قائمة عمليات المشتريات ذات `requireAny(["purchases"])`، ولا تضفهما إلى `POST_INVOICE` أو قائمة الصلاحيات المالية.

## 3. توجيه العمليات

داخل سلسلة العمليات الحالية:

```typescript
} else if (op === "UPDATE_BUYER_LEGACY_DRAFT") {
  ({ data, error } = await profileClient.rpc("purchase_update_buyer_legacy_draft_atomic", {
    p_company_id: companyId,
    p_invoice_id: p.id,
    p_supplier_id: p.supplier_id,
    p_purchase_order_id: p.purchase_order_id || null,
    p_branch_id: p.branch_id || null,
    p_due_date: p.due_date || null,
    p_currency: await getSystemCurrency(),
    p_actor: user.email,
    p_supplier_invoice_no: p.supplier_invoice_no || null,
    p_notes: p.notes || null,
    p_items: p.items || [],
    p_operation_id: operationId
  }));
} else if (op === "DELETE_BUYER_DRAFT_INVOICE") {
  ({ data, error } = await profileClient.rpc("purchase_delete_buyer_draft_invoice_atomic", {
    p_company_id: companyId,
    p_invoice_id: p.id,
    p_actor: user.email,
    p_reason: p.reason || null,
    p_operation_id: operationId
  }));
```

تستخدم هذه العمليات `profileClient` لأن الوظائف تفحص `auth.uid()`. لا تستدعها بعميل Service Role.

## 4. توجيه واجهة Buyer

- إذا كانت الفاتورة `LEGACY_UNCLASSIFIED`، تعديلها يستدعي `UPDATE_BUYER_LEGACY_DRAFT`.
- يمرر هذا المسار مرجع PO التاريخي نفسه إن وجد؛ لا يجوز تغييره أو تحويل المستند القديم إلى PO أو Quick Market. وظيفة SQL ترفض تغيير `purchase_order_id` في المسار التاريخي.
- إذا كانت `PURCHASE_ORDER`، تعديلها يستدعي `UPDATE_PO_INVOICE`.
- إذا كانت `QUICK_MARKET`، تعديلها يستدعي `UPDATE_QUICK_MARKET_INVOICE`.
- حذف `LEGACY_UNCLASSIFIED` أو `PURCHASE_ORDER` يستدعي `DELETE_BUYER_DRAFT_INVOICE`.
- حذف `QUICK_MARKET` يستدعي `DELETE_QUICK_MARKET_DRAFT`.
- لا تسمح للواجهة بإرسال نوع المستند أو صاحبه بوصفه مصدرًا موثوقًا؛ الوظيفة تقرأ الفاتورة من قاعدة البيانات وتتحقق من مصدرها/مالكها.

## 5. سبب الفصل

وظائف `purchase_update_draft_invoice_atomic` و`purchase_delete_draft_invoice_atomic` المركزية القديمة تتحقق من أن البريد يخص مستخدمًا نشطًا داخل الشركة، لكنها لا تثبت أن المستخدم هو منشئ المسودة أو مالكها. غلاف Buyer يضيف فحص الملكية قبل استدعاء الوظيفة الأصلية. هذا يمنع كشف UUID فاتورة من تمكين مشتري آخر من تعديل أو حذف مسودة ليست له، دون تغيير الوظائف المركزية العامة المستخدمة خارج Buyer.

## 6. اختبار قبول

1. مستخدم مشتريات A يعدل/يحذف مسودته Legacy أو PO غير مستلمة: يسمح.
2. مستخدم مشتريات A يحاول تعديل/حذف مسودة B بإرسال UUID معروف: يرفض.
3. المالك الذي يحمل wildcard يستطيع تنفيذ الاستثناء الإداري.
4. مسودة Quick Market لا تدخل هذه الوظائف؛ تستخدم أغلفتها المخصصة.
5. فاتورة مرحّلة أو مستلمة أو لها مراجع downstream: الوظيفة المركزية الأساسية ترفض الحذف/التعديل كما هي.
