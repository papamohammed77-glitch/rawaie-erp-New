# تقييد فواتير المشتريات على الخادم — Buyer

## المشكلة المثبتة

مدخل `save-purchase-order` الحالي يتيح عملية `GET_DATA` للمستخدم الذي يحمل صلاحية المشتريات، ثم ينفذ قراءة عامة للشركة على `purchase_invoices`. كما أن مسار `detailScope` يجلب معرفات كل فواتير الشركة قبل قراءة `purchase_invoice_details`.

هذا يعني أن إخفاء سجلات الآخرين في واجهة `renderInvoices` وحده لا يوفر عزلًا حقيقيًا؛ فالبيانات نفسها تصل إلى متصفح المشتري. المطلوب قيد الخادم.

## قاعدة الرؤية

- مستخدم المشتريات غير المالي: لا يستلم إلا الفواتير التي أنشأها بريده الموثق في `auth.getUser`.
- المالية/مدير المالية/المالك: يمكنه القراءة الشاملة وفق صلاحياته الحالية.
- تفاصيل الفاتورة تتبع بالضرورة مجموعة الفواتير المسموح بها.
- يظل `created_by` هو معيار التوافق للفواتير التاريخية التي لم تُصنف بعد.
- بعد نشر تصنيف المصدر الجديد، تبقى `purchaser_user_id` مفيدة للتقارير والتدقيق، لكن لا تستخدم قيمة من المتصفح لتقرير نطاق المستخدم.

## التعديل الجراحي في مدخل Edge

داخل فرع `GET_DATA` الموجود، بعد `rowLimit`، أضف:

```typescript
const financeInvoiceView =
  hasPermission("finance") || hasPermission("finance_manager");
```

ثم في فرع `detailScope[table]` الحالي، استبدل إنشاء قائمة الآباء بالكتلة التالية:

```typescript
      } else if (detailScope[table]) {
        const scope = detailScope[table];
        let parentQuery = sb.from(scope.parent).select("id")
          .eq("company_id", companyId);

        if (scope.parent === "purchase_invoices" && !financeInvoiceView) {
          parentQuery = parentQuery.eq("created_by", user.email);
        }

        const parents = await parentQuery.limit(500);
        if (parents.error) throw parents.error;
        const parentIds = (parents.data || []).map((row: any) => row.id).filter(Boolean);
        if (!parentIds.length) {
          data = { success: true, items: [], table };
        } else {
          r = await sb.from(table).select("*").in(scope.foreignKey, parentIds).limit(rowLimit);
          if (r.error) throw r.error;
          data = { success: true, items: r.data || [], table };
        }
```

ثم أضف فرعًا خاصًا قبل الفرع العام الأخير:

```typescript
      } else if (table === "purchase_invoices" && !financeInvoiceView) {
        r = await sb.from("purchase_invoices").select("*")
          .eq("company_id", companyId)
          .eq("created_by", user.email)
          .order("created_at", { ascending: false })
          .limit(rowLimit);
        if (r.error) throw r.error;
        data = { success: true, items: r.data || [], table };
```

ويظل فرع المالية يسلك القراءة العامة للشركة من خلال الفرع الأخير الحالي.

## أثر هذا التعديل

| الاستدعاء | مستخدم مشتريات | المالية |
|---|---|---|
| `GET_DATA(purchase_invoices)` | فواتير البريد الموثق فقط | كل فواتير الشركة |
| `GET_DATA(purchase_invoice_details)` | تفاصيل فواتيره فقط | تفاصيل كل الفواتير |
| `GET_CUSTODY` | عهدته النقدية فقط | جميع العهد النقدية وفق الصلاحية |
| `GET_GOODS_CUSTODY` | دفتر حيازته فقط | العرض الشامل للمالية المخولة |

لا تعتمد هذه الحماية على `purchaser_user_id` الجديدة وحدها؛ فهي تعمل كذلك مع الفواتير التاريخية عبر `created_by`. كما أنها لا تغير صلاحيات أي جدول آخر أو أي تطبيق آخر.

## اختبارات إلزامية

1. مستخدم مشتريات A لا يحصل عبر Edge على فاتورة أنشأها B.
2. محاولة طلب تفاصيل فاتورة B بمعرفة UUID لا تعيد صفوفًا؛ لأن قائمة الآباء نفسها مفلترة.
3. تغيير payload أو تمرير `created_by` مختلف لا يغير النطاق؛ البريد يؤخذ من جلسة المصادقة.
4. المالية المخولة ترى الفواتير والتفاصيل كاملة.
5. اختبر حد 500 سجل بوضوح؛ لا تدّع أن القائمة كاملة إذا تجاوزت حجم الصفحة.
6. لا تسمح بإضافة استثناءات لمستخدم المشتريات العادي بحجة إنشاء PO نيابة عن زميل؛ يجب أن تكون وظيفة تفويض مستقلة معتمدة ومسجلة إذا ظهرت حاجة تشغيلية لذلك.

**لا يغير هذا التعديل ملف النظام الأم أو قاعدة البيانات أو وظائف Edge الأخرى.**
