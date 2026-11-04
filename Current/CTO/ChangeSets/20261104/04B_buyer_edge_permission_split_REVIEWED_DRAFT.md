# تصحيح فصل صلاحيات Buyer في مدخل المشتريات المركزي

هذه المذكرة تتقدم على كتلة الصلاحيات المجمعة في المسودات السابقة.

## الكتلة الصحيحة

```typescript
} else if ([
  "CREATE_INVOICE",
  "CREATE_PO_INVOICE",
  "UPDATE_PO_INVOICE",
  "CREATE_QUICK_MARKET_INVOICE",
  "UPDATE_QUICK_MARKET_INVOICE",
  "REGISTER_GOODS_HANDOVER",
  "DELETE_QUICK_MARKET_DRAFT"
].includes(op)) {
  requireAny(["purchases"]);
} else if (op === "POST_INVOICE") {
  requireAll(["purchases", "finance"]);
} else if ([
  "GET_GOODS_CUSTODY",
  "GET_QUICK_MARKET_HANDOVER_PROGRESS"
].includes(op)) {
  requireAny(["purchases", "finance", "finance_manager"]);
}
```

## القاعدة

- إنشاء أو تعديل مسودة PO/Quick Market وإثبات حيازة المورد إلى Buyer: صلاحية المشتريات.
- ترحيل فاتورة PO: المشتريات + المالية، إلا المالك المصرح به في محرك الصلاحيات.
- قراءة رصيد الحيازة: المشتري يرى سجله، والمالية المخولة ترى سجلات الشركة وفق وظيفة القراءة.
- الاستلام المخزني ليس من صلاحيات Buyer؛ يظل في Receiver لاحقًا.
- لا تضف `warehouse` أو `receiving` إلى صلاحيات Buyer لمجرد عرض رصيد حيازة بضاعته.

يجب تطبيق الكتلة داخل سلسلة `if / else if` الحالية دون إزالة الفروع الأخرى أو تغيير الصلاحيات غير المرتبطة بالمشتريات.
