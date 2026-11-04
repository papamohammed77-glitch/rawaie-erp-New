# Buyer Phase 1 — الفروق الدقيقة للمتاح من العهدة النقدية ولوحة اليوم

هذا الملف يستكمل `04A` و`04` ويقدم منطقًا مطابقًا لكود Buyer الحالي. لا يغير دورة صرف العهدة المركزية.

## 1. قاعدة الحجز الوحيدة

المعادلة الصحيحة للعهدة النقدية:

```
المتاح =
  النقد المؤكد استلامه
  - المصروفات المقدمة أو المعتمدة
  - صافي حجوزات فواتير Quick Market المرتبطة بالعهدة
```

صافي حجز كل فاتورة:
```
max(0, total_amount - paid_amount - المصروفات Submitted/Approved المرتبطة بنفس الفاتورة)
```

السبب: بمجرد تقديم فاتورة Quick Market إلى المالية في مرحلة Receiver، تصبح قيمتها ضمن المصروفات Submitted/Approved. لا يجوز أن تخصم القيمة نفسها مرة ثانية كاملة من حجز المسودة. ويجب أيضًا ألا تُخصم فاتورة ائتمان مورد من عهدة نقدية.

## 2. helper داخل كائن App

أضف مرة واحدة داخل كائن `App`:

```javascript
quickMarketCashReservation:function(invoices,expenses,custodyId,excludeInvoiceId){
    var rows=Array.isArray(invoices)?invoices:[];
    var expenseRows=Array.isArray(expenses)?expenses:[];
    return rows.filter(function(i){
        return i.id!==excludeInvoiceId &&
            i.cash_custody_id===custodyId &&
            i.purchase_source==='QUICK_MARKET' &&
            i.settlement_source==='EMPLOYEE_CUSTODY' &&
            ['Draft','Posted','PartiallyPaid'].indexOf(i.status)!==-1 &&
            ['UNSETTLED','PENDING_FINANCE','AP_OPEN','PARTIALLY_SETTLED'].indexOf(i.settlement_status)!==-1;
    }).reduce(function(total,i){
        var linked=expenseRows.filter(function(e){
            return e.purchase_invoice_id===i.id &&
                e.custody_id===custodyId &&
                ['Submitted','Approved'].indexOf(e.status)!==-1;
        }).reduce(function(n,e){return n+Number(e.amount||0);},0);
        var remaining=Math.max(0,Number(i.total_amount||0)-Number(i.paid_amount||0)-linked);
        return total+remaining;
    },0);
},
```

هذا helper للعرض الأمامي والتنبيه فقط؛ التحقق الحاسم من حد العهدة يبقى داخل SQL في وظائف إنشاء/تعديل Quick Market.

## 3. تعديل `quickPurchase`

في نموذج الشراء السريع الحالي في 04، استبدل كتلة حساب `reserved` داخل `custodies.forEach`:

```javascript
var reserved=this.quickMarketCashReservation(invoices,expenses,c.id,current&&current.id);
availableByCustody[c.id]=Math.max(0,acknowledged-committed-reserved);
```

لا تستخدم `invoice.total_amount` كاملًا إذا كان هناك مصروف مقدم/معتمد مرتبط بنفس الفاتورة. ولا تخصم فاتورة مرتبطة بـ `SUPPLIER_CREDIT`.

## 4. تعديل `renderToday` في Buyer الحالي

في `renderToday` الحالية (تبدأ قرب السطر 370 من blob الحالي):
- احتفظ بتحميل `GET_CUSTODY` كما هو.
- استخرج `expenses` من `custodyData.expenses`.
- بعد حساب `committedCustody` مباشرة أضف:

```javascript
var qmpReserved=0;
myCustodies.forEach(function(c){
    qmpReserved+=this.quickMarketCashReservation(invoices,custodyData.expenses||[],c.id,null);
},this);
var custodyAvailable=Math.max(0,acknowledgedCustody-committedCustody-qmpReserved);
```

استبدل الحساب الحالي:
```javascript
var custodyAvailable=Math.max(0,acknowledgedCustody-committedCustody);
```

وغيّر النص التوضيحي لبطاقة الرصيد إلى:
«النقد المؤكد ناقص المصروفات والحجوزات الحالية لفواتير السوق السريع».

### 4.1 أزرار اليوم

استبدل زر المسودة العام الحالي بزرين منفصلين:
```html
<button type="button" onclick="App.createPurchaseInvoice()" ...>إنشاء فاتورة PO</button>
<button type="button" onclick="App.quickPurchase()" ...>شراء سوق سريع</button>
```
الزر الأول ينشئ فاتورة PO مرتبطة بأمر شراء. الزر الثاني فقط ينشئ فاتورة بلا PO.

## 5. تعديل `renderCustody` الحالي

الطريقة الحالية تقرأ `GET_CUSTODY` فقط. اجعلها تقرأ فواتير Buyer أيضًا:

```javascript
var loaded=await Promise.all([
    this.api('GET_CUSTODY',{}),
    this.data('purchase_invoices')
]);
var data=loaded[0]||{};
var invoices=loaded[1]||[];
```

بعد تعريف `expenses` و`advances`، وفي داخل `custodies.forEach(function(c){...})` حيث تُحسب `committedTotal` حاليًا، أضف:

```javascript
var reservedTotal=this.quickMarketCashReservation(invoices,expenses,c.id,null);
var availableTotal=Math.max(0,acknowledgedTotal-committedTotal-reservedTotal);
```

واستبدل:
```javascript
buyerMoney(Math.max(0,acknowledgedTotal-committedTotal),c.currency)
```
بـ:
```javascript
buyerMoney(availableTotal,c.currency)
```

غيّر عنوان العمود من «الرصيد المتاح للمستندات» إلى «الرصيد المتاح بعد الحجوزات».

### 5.1 عرض الفواتير المحجوزة

داخل بطاقة العهدة يمكن إضافة قائمة صغيرة توضح فواتير السوق السريع التي تحجز جزءًا من العهدة:
- رقم الفاتورة.
- رقم فاتورة المورد.
- القيمة الكلية.
- المصروفات المقدمة/المعتمدة المرتبطة بها.
- صافي الحجز.
- حالة الفاتورة/الاستلام/التسوية.

هذه القائمة للشفافية فقط. لا تتيح تعديل الحجز يدويًا.

## 6. تعديل SQL لحد العهدة

في `purchase_create_quick_market_invoice_atomic` و`purchase_update_quick_market_invoice_atomic`:
- `v_committed` يجمع المصروفات Submitted/Approved للعهدة.
- `v_reserved` يجمع المتبقي من فواتير السوق السريع المرتبطة بالعهدة بعد طرح المصروفات المرتبطة بنفس الفاتورة والرصيد المدفوع.
- في update، استبعد الفاتورة الجاري تعديلها من الحجوزات السابقة ثم أدخل `v_total` الجديد.
- الحالات التي تظل محجوزة: Draft / Posted / PartiallyPaid مع حالة تسوية غير نهائية (UNSETTLED / PENDING_FINANCE / AP_OPEN / PARTIALLY_SETTLED).
- لا تحسب فواتير المورد الآجلة أو الفواتير التاريخية غير المصنفة.
- لا تجمع مبالغ بعملات مختلفة.

هذا التعديل تم إدخاله في أحدث نسخ ملفات SQL:
- `03B_buyer_phase1_atomic_contracts_FINAL_REVIEW_DRAFT.sql`
- `03D_buyer_source_idempotency_and_permission_hardening_REVIEWED_DRAFT.sql`

## 7. اختبارات هذه المعادلة

1. نقد مؤكد 1,000، مصروفات PO معتمدة 200، Quick Market Draft 300: المتاح 500.
2. تقديم 100 من نفس فاتورة السوق: المصروفات تزيد 100 والحجز ينخفض 100؛ المتاح يظل 500 ولا يصبح 400.
3. رفض مصروف 100: يعود الحجز 100 وتعود المصروفات إلى الصفر؛ المتاح يظل 500.
4. فاتورة سوق بمصدر Supplier Credit: لا تحجز من العهدة النقدية.
5. مسودتان على نفس العهدة بمجموع يتجاوز النقد المؤكد: SQL يرفض الثانية.
6. عمليتان متزامنتان على العهدة نفسها: قفل سجل العهدة يمنع تجاوز الإجمالي.
7. currency mismatch: الرفض من SQL؛ الواجهة لا تجمع مبالغ العملات المختلفة.

