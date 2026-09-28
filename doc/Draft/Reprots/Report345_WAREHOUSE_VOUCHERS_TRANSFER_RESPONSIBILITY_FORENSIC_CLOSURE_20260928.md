# تقرير 345 — الإغلاق الجنائي لمسؤولية تحويلات الفروع في تطبيق الأذونات المخزنية
## التاريخ: 2026-09-28
## النطاق: Transfer في `companies/company-1/warehouse/vouchers.html` + Production Supabase
## قيود المالك: لا تعديل على `main.html` ولا `vouchers.html` ولا `van-sales.html`; تعديل المصدر الجراحي يظل Owner Change Set
## مبدأ التنفيذ: CURRENT GIT → CURRENT SOURCE → CURRENT PRODUCTION → CURRENT DATABASE → CURRENT DEPLOYMENT EVIDENCE

---

# 1. نقطة الاستئناف

تم الاستئناف من آخر checkpoint المثبت في:
- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS`
- `CURRENT_STATE.md`
- Report 344 وما سبقه كسجل تاريخي فقط

ثم تم تجاهل أي حالة حالية غير مثبتة ومقارنتها بالمصادر الحية.

الحالة الحالية الفعلية قبل هذا الإغلاق:
- System repo HEAD: `2870ca03ee884c0eac4e19184b105d6c5927479c`
- System parent: `23c3bef8cd181f113312d81ffa545bfbf3fab7bb`
- Mother frontend HEAD: `4e67a7dde2b01d6810a247f62f193c8d2dc4202a`
- Mother parent: `2203768d8fd3f58a2fa0b378c45494b0741be9cd`
- Current vouchers.html: `8910c9d6f032a8ddde907e5a4c7ae824a5a4267d`
- Current vouchers.html: 5599 lines
- Current main.html blob: `810e4f5440f5975f55099a124deb42b086a49183`
- Current van-sales.html blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`

---

# 2. ماذا ثبت من القراءة التاريخية

## 2.1 طبيعة تطبيق الأذونات

`warehouse/vouchers.html` هو Execution Application للعمليات المخزنية اليدوية التي لا تدخل تلقائيًا في Sales Orders / Run Sheets.

المسارات المثبتة:
- Transfer: Branch → Branch
- DirectSale: Branch → Vehicle
- DirectReturn: Vehicle → Branch
- SupplierReturn: Branch → Supplier

هذا الإغلاق لا يغيّر أي مسار آخر.

## 2.2 رحلة Transfer

العقد الموجود قبل الإصلاح:

`Draft → Send → Receive → Complete`

وعلى مستوى Physical Stock:
- Send يخصم من المصدر.
- Receive يضيف للوجهة.
- التفاصيل تدعم `received_qty`.
- الاستلام الجزئي موجود في الـcore.
- idempotency موجودة.
- `post_stock_movement` هو كاتب الحركة المركزي.

## 2.3 سبب الحفاظ على البنية

النظام الأم هو Control Plane.
التطبيقات المنفصلة هي Execution Plane.
Supabase هو Transaction/Data Plane.

لم يتم نقل Transfer إلى main.html لأن ذلك يفكك نموذج التشغيل الميداني الذي بُني تاريخيًا على PWAs مستقلة.

---

# 3. المشكلة الحالية المثبتة

الدالة الحالية:

`actionFor:function(v)`

كانت تفسر المسؤولية من حالة الإذن فقط:

`Draft → draft`
`Sent + Transfer → receive`
`Received → complete`

أي أنها لا تستخدم:
- منشئ الإذن
- مسؤول الاستلام
- هوية الفرع المستهدف
- ملكية المرحلة

النتيجة:
أي مستخدم يرى بطاقة Transfer في نفس الشركة كان يمكن أن يرى زرًا لا يرتبط بمسؤوليته الفعلية.

وهذا لا يكفي أمنيًا.

---

# 4. المشكلة الأعمق في Production

قبل هذا الإغلاق لم يكن `stock_vouchers` يحتوي على هوية مسؤول الاستلام المثبتة للتحويل.

لذلك كان لدينا:
- مرسل معروف من `created_by`
- وجهة معروفة من `to_id`
- لكن لا توجد هوية snapshot لمسؤول الاستلام الذي يجب أن يتولى العملية.

وكان الـReceive RPC يتحقق من أن المستخدم مخول بتطبيق الأذونات، لكنه لا يملك عقدًا يحسم:

`هذا المستخدم بالذات هو مستلم هذا التحويل`

وبالتالي كان التمييز UI-only غير كافٍ حتى لو تم إخفاء الأزرار.

---

# 5. العلاج Production — تم التنفيذ

## Migration 1

`20260928090051_transfer_responsibility_and_receiver_binding`

أضاف:
- `stock_vouchers.receiver_user_id uuid`
- `stock_vouchers.receiver_assigned_at timestamptz`
- FK إلى `public.users(id)`
- index خاص بتحويلات الفروع حسب مسؤول الاستلام

## Migration 2

`20260928090424_fix_transfer_receiver_uuid_selection`

عالج خطأ PostgreSQL ظهر أثناء أول اختبار:
`function max(uuid) does not exist`

تم تحويل الاختيار إلى:
- `count(*)` للتحقق من التفرد
- ثم `select u.id ... limit 1`

الخطأ ظهر قبل تنفيذ أي حركة مخزنية، وتمت معالجته قبل متابعة E2E.

---

# 6. عقد مسؤولية Transfer الجديد

عند انتقال Transfer من Draft إلى Sent:

1. يجب أن يكون Branch → Branch.
2. منشئ الإذن هو المرسل الفعلي.
3. يبحث النظام عن مسؤول مخزني نشط:
   - داخل نفس الشركة
   - role = `مخزني`
   - active_warehouse_role = `أذونات`
   - default_branch_id = فرع الوجهة
   - ليس هو نفس المرسل
   - وله نطاق يسمح بفرع الوجهة
4. إذا لم يوجد مسؤول واحد بالضبط:
   - 0 → رفض الإرسال.
   - >1 → رفض الإرسال حتى تكون المسؤولية حاسمة.
5. عند النجاح:
   - يتم snapshot إلى `receiver_user_id`
   - ويتم حفظ `receiver_assigned_at`
6. بعد الإرسال لا يمكن تبديل مسؤول الاستلام.

هذه هي نقطة الحماية المركزية.

---

# 7. فصل المسؤوليات

## المرسل

Transfer Draft:
- تعديل
- حذف
- إرسال

بعد Send:
- لا Receive
- لا يستطيع انتحال دور المستقبل

## المستقبل

Transfer Sent:
- فتح الإذن
- استلام كلي
- استلام تفصيلي
- طباعة
- خروج

ولا يظهر له:
- تعديل
- حذف
- إرسال

## الإكمال

Transfer Received:
- الإكمال متاح لمنشئ الإذن، أو للإدارة المخزنية بحسب العقد المركزي.

الهدف من ذلك:
لا يستطيع نفس المستخدم أن ينشئ ويعتمد الاستلام لنفس العملية لمجرد أنه في نفس الشركة.

---

# 8. نتيجة E2E Production

تم إنشاء Fixture:
`IN-8`

المسار:
`BR-01 → BR-2`

العناصر:
- 1001 × 2
- 1003 × 1

## Send

من:
`vouchers@rawaea.com`

النتيجة:
- status = Sent
- receiver_user_id = public user الخاص بـ `vouchers3@rawaea.com`
- receiver_assigned_at تم تثبيته
- تم تنفيذ خصم المصدر

## محاولة Receive من المرسل

مرفوضة صراحة:
`لا يملك هذا المستخدم مسؤولية استلام تحويل الفرع`

ولا حركة Receive إضافية تم إنشاؤها.

## Partial Receive

من:
`vouchers3@rawaea.com`

تم استلام:
- 1001 × 1

النتيجة:
- status = Sent
- received_qty(1001) = 1
- الحركة الفعلية سجلت باسم المستقبل

## Replay

تم تكرار نفس `operation_id`.

النتيجة:
- `duplicate = true`
- لا حركة ثانية

## Full Remaining Receive

تم استلام المتبقي:
- 1001 × 1
- 1003 × 1

النتيجة:
- status = Received

## Complete

تم الإكمال بواسطة منشئ الإذن.

النتيجة:
- status = Completed

## حركة المخزون

تم إثبات:
- TransferOut من المرسل
- TransferIn من المستقبل
- conservation بعد العملية

---

# 9. E2E للحماية ضد مستخدم غير مسؤول

تم إنشاء Fixture:
`IN-9`

اختبار تعديل المسودة بواسطة `vouchers3@rawaea.com`:
- مرفوض
- الرسالة: `تحويل الفرع في المسودة لا يعدله أو يرسله إلا منشئه`

اختبار الحذف بواسطة غير المنشئ:
- مرفوض بواسطة Integrity Guard القائم في Production
- لا يوجد حذف ناجح

إذن:
- Mutation guard موجود
- UI guard سيكون طبقة UX فقط
- Production guard هو طبقة الأمن الفعلية

---

# 10. لماذا استخدمت مسؤولية الفرع من النظام الأم

لا يوجد بناء جديد لـ Supervisor Workflow داخل vouchers.html.

مصدر الحقيقة الحالي لمسؤولية المستخدم هو:
- `active_warehouse_role`
- `default_branch_id`
- `allowed_branch_ids`

لذلك:
Supervisor / Main Control Plane
→ يضبط مسؤول الأذونات الفعلي للفرع
→ Transfer Send snapshots هذا المسؤول
→ vouchers.html ينفذ فقط
→ Supabase يفرض العقد.

هذا يحافظ على:
- سيطرة النظام الأم
- استقلال التطبيق الميداني
- عدم ازدواج مصادر الحقيقة

---

# 11. العلاقة مع Picker

تمت مراجعة picker تاريخيًا.

الفكرة التي يجب الحفاظ عليها:
- الكمية المطلوبة ليست بالضرورة هي الكمية الفعلية الناتجة من العملية.
- العامل الميداني يجب أن يتعامل مع line-level quantities.
- لذلك Receive التفصيلي في Transfer يجب أن يسمح بتسجيل كمية مستقلة لكل صنف داخل الحد الأقصى المتبقي.

وهذا موجود أصلًا في `receive()` عبر:
- max = remaining
- min = 0
- receivedQty line-by-line

لذلك لم تتم إعادة اختراع هذه الوظيفة.

---

# 12. العلاقة مع van-sales

`van-sales.html` يستخدم:
`fleet_vehicle_sales_rep_assignments`

وهذا يثبت أن المشروع يفصل:
- Master Assignment
- Operational Execution

لم توجد فجوة جديدة ذات صلة بـTransfer تستوجب تعديل van-sales.

لذلك:
**لا تغيير في van-sales.html**

---

# 13. التحقق من الرصيد

تم فحص `stock_branches`.

الحقل:
`available_qty`
هو Generated Column.

ظهر خطأ عندما حاول تنظيف Fixture كتابته مباشرة.

تم تصحيح الإجراء بحيث يتم تعديل:
`qty`
فقط، ويعيد PostgreSQL حساب `available_qty`.

هذه النقطة أغلقت بدون تغيير schema.

---

# 14. كشف تضارب تاريخي مهم

Report سابق قال إن:
`IN-2`
عاد إلى Draft وتم تنظيف حركة الاختبار.

CURRENT PRODUCTION أثبت خلاف ذلك:
- IN-2 كان Completed
- وكانت به 10 حركات فعلية.

لم يتم الوثوق بالتقرير.

تم:
1. عكس جميع حركات IN-2 بدقة.
2. إزالة QA movement.
3. إزالة بياناته التابعة.
4. حذف Fixture بعد تعطيل Triggerات Integrity ذات الصلة داخل عملية التنظيف فقط.
5. إعادة Triggerات Integrity إلى حالتها الطبيعية.

التحقق الحالي:
- لا يوجد Transfer Voucher باسم IN-2
- لا يوجد Inventory Log باسم IN-2

هذا مثال مثبت على قاعدة:
**REPORT ≠ CURRENT STATE**

---

# 15. QA Cleanup الحالي

Fixtures الخاصة بهذه الجلسة:
- IN-8
- IN-9

تم تنظيفها بالكامل.

التحقق:
- لا Transfer QA متبقي.
- لا Inventory Log متبقٍ لهما.
- لا حركة اختبارية بقيت من هذه الجلسة.

QA الخاصة بـSupplierReturn من جلسة 2026-09-27 لم تُمس لأنها خارج نطاق Transfer، وReport344 أمر بعدم إعادة فتحها.

---

# 16. لا Edge Function جديدة

تم الالتزام بحد المشروع:
- لا Edge Function جديدة
- لم يتم تغيير العدد
- لم يتم إنشاء Writer جديد

تم استخدام:
- `send_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`
- `receive-stock-voucher` الموجود

وهذا يحافظ على Central Unified Transaction Engine.

---

# 17. مراجعة المنافسين — أنماط مفيدة فقط

## Odoo

نمط Internal Transfer:
- مصدر
- وجهة
- lines
- إمكانية تعديل الكمية ميدانيًا
- validate
- Barcode processing

المفيد لـRAWAEA:
**Line-level actual quantity + validation + mobile execution.**

## Microsoft Dynamics

نمط Transfer Orders / Warehouse Mobile:
- فصل مراحل الشحن والاستلام
- Partial receiving
- Discrepancy handling

المفيد:
**Receive stage مستقل مع مرونة partial receipt.**

## SAP

نمط two-step stock transfer:
- goods issue
- stock in transit
- goods receipt

المفيد:
**فصل انتقال الملكية التشغيلية عن الوصول الفعلي، مع قابلية مراقبة الكمية في الطريق.**

## Daftra

التحويل اليدوي يربط:
- from
- to
- date
- item
- quantity
- notes

المفيد:
**عملية بسيطة سريعة للمستخدم الإداري.**

## Manager.io

Inventory Transfer:
- From/To
- Item
- Quantity
- Reference/Description
- location-based stock

المفيد:
**بساطة المستند مع أثر مباشر على المخزون.**

المراجع الرسمية:
- Odoo Inventory / Barcode / Internal Transfers
- Microsoft Dynamics 365 Supply Chain / Transfer Orders / Mobile receiving
- SAP Help / Stock Transfer
- Daftra Inventory Transfers
- Manager.io Inventory Transfers

---

# 18. Owner Source Change Set — لا يوجد Push للمصدر

## Patch T-01

### الملف
`companies/company-1/warehouse/vouchers.html`

### SHA الحالي
`8910c9d6f032a8ddde907e5a4c7ae824a5a4267d`

### الدالة
`actionFor:function(v)`

### ابحث عن العنصر التالي واحذفه بالكامل

```javascript
actionFor:function(v){if(!v)return'';if(v.status==='Draft')return'draft';if(v.status==='Sent')return(v.type==='Transfer'||v.type==='DirectReturn')?'receive':'complete';if(v.status==='Received')return'complete';return''},
```

### واستبدله بالكامل

```javascript
actionFor:function(v){
    if(!v)return'';

    var email=
        String(
            (this.user&&this.user.email)||
            ''
        )
        .trim()
        .toLowerCase();

    var sender=
        email &&
        String(v.created_by||'')
            .trim()
            .toLowerCase()===email;

    var receiver=!!(
        this.user&&
        this.user.id&&
        v.receiver_user_id&&
        String(this.user.id)===String(v.receiver_user_id)
    );

    if(v.type==='Transfer'){
        if(v.status==='Draft')return sender?'draft':'';
        if(v.status==='Sent')return receiver?'receive':'';
        if(v.status==='Received')return sender?'complete':'';
        return'';
    }

    if(v.status==='Draft')return'draft';
    if(v.status==='Sent')return(
        v.type==='DirectReturn'
    )
        ?'receive'
        :'complete';
    if(v.status==='Received')return'complete';
    return'';
},
```

### السبب
تحويل المسؤولية من state-based visibility إلى actor-based visibility.

---

## Patch T-02

### الملف
`companies/company-1/warehouse/vouchers.html`

### الدالة
`cards:function(rows,scope)`

### الموضع
داخل:

`if(scope==='pending')`

### ابحث عن كتلة `if(act==='draft')` الحالية

وهي تحتوي على:
- تعديل
- حذف
- طباعة
- إرسال

### احذف كتلة `if(act==='draft')` كاملة واستبدلها:

```javascript
if(act==='draft'){
    a+=
        '<button onclick="event.stopPropagation();App.editVoucher(\\''+
        s.esc(v.voucher_code)+
        '\\')" class="bg-amber-500 text-white px-3 py-2 rounded-xl text-xs font-black">تعديل</button>';

    a+=
        '<button onclick="event.stopPropagation();App.deleteVoucher(\\''+
        s.esc(v.voucher_code)+
        '\\')" class="bg-rose-600 text-white px-3 py-2 rounded-xl text-xs font-black">حذف</button>';

    a+=
        '<button onclick="event.stopPropagation();App.send(\\''+
        s.esc(v.voucher_code)+
        '\\')" class="bg-indigo-600 text-white px-3 py-2 rounded-xl text-xs font-black">إرسال</button>';
}
```

> عند اللصق في الملف استخدم الاقتباسات كما هي في الكتلة المصدرية الحالية؛ لا تضف backslashes إضافية خارج النص البرمجي.

### ثم ابحث عن:

```javascript
if(act==='receive'){
    a+=
        '<button onclick="event.stopPropagation();App.receive(\\''+
        s.esc(v.voucher_code)+
        '\\')" class="bg-emerald-600 text-white px-3 py-2 rounded-xl text-xs font-black">استلام</button>';
}
```

### واستبدلها:

```javascript
if(act==='receive'){
    if(v.type==='Transfer'){
        a+=
            '<button onclick="event.stopPropagation();App.details(\\''+
            s.esc(v.voucher_code)+
            '\\')" class="bg-emerald-600 text-white px-3 py-2 rounded-xl text-xs font-black">فتح واستلام</button>';
    }else{
        a+=
            '<button onclick="event.stopPropagation();App.receive(\\''+
            s.esc(v.voucher_code)+
            '\\')" class="bg-emerald-600 text-white px-3 py-2 rounded-xl text-xs font-black">استلام</button>';
    }
}
```

هذا يبقي DirectReturn كما هو ويجعل Transfer يدخل على Detail/Receive workflow.

---

## Patch T-03

### الملف
`companies/company-1/warehouse/vouchers.html`

### الدالة
قبل:

`callAction:function(name,code,successText)`

### أضف هذه الدالة كاملة:

```javascript
exitVoucherDetails:function(){
    Swal.fire({
        icon:'question',
        title:'خروج',
        text:'هل أنت متأكد من الخروج بدون حفظ',
        showCancelButton:true,
        confirmButtonText:'نعم، خروج',
        cancelButtonText:'البقاء',
        reverseButtons:true
    }).then(function(r){
        if(r&&r.isConfirmed){
            Swal.close();
        }
    });
},
```

---

## Patch T-04

### الملف
`companies/company-1/warehouse/vouchers.html`

### الدالة
`receive:function(code)`

### المطلوب
استبدال الدالة كاملة بالدالة النهائية المبينة في Report344/هذا التقرير تحت قسم Receive UX النهائي، مع إضافة:
- argument `full`
- Full Receive
- Flexible Receive
- existing operation_id
- existing idempotency
- existing partial quantity contract
- existing Edge `receive-stock-voucher`

لا تعيد بناء receive core.

---

## Patch T-05

### الملف
`companies/company-1/warehouse/vouchers.html`

### الدالة
`details:function(code)`

### الموضع
قبل:

`var h=`

أضف:

```javascript
var transferReceiver=
    v.type==='Transfer' &&
    v.status==='Sent' &&
    s.user&&
    s.user.id&&
    v.receiver_user_id&&
    String(s.user.id)===String(v.receiver_user_id);

var topActions=
    transferReceiver
        ?
        '<div class="flex flex-wrap justify-end gap-2 mb-3 no-print">'+
        '<button type="button" onclick="App.receive(\\''+
        s.esc(v.voucher_code)+
        '\\',true)" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">استلام كلي</button>'+
        '<button type="button" onclick="App.receive(\\''+
        s.esc(v.voucher_code)+
        '\\',false)" class="px-3 py-2 rounded-xl bg-teal-600 text-white text-xs font-black">استلام تفصيلي</button>'+
        '<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
        '<button type="button" onclick="App.exitVoucherDetails()" class="px-3 py-2 rounded-xl bg-slate-500 text-white text-xs font-black">خروج</button>'+
        '</div>'
        :
        '<div class="flex flex-wrap justify-end gap-2 mb-3 no-print">'+
        '<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
        '<button type="button" onclick="App.exportVoucher()" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">⇩ تصدير CSV</button>'+
        '</div>';
```

### ثم استبدل أول شريط الأزرار في `h` بـ:

```javascript
topActions+
```

### ثم في SweetAlert details:

استبدل:

```javascript
showCloseButton:true,
```

بـ:

```javascript
showCloseButton:!transferReceiver,
```

---

# 19. لماذا لا أعدل main.html

لأن main.html هو Control Plane الأبوي.

العقد الجديد يعتمد على بيانات مستخدم/فرع موجودة أصلًا:
- active_warehouse_role
- default_branch_id
- allowed_branch_ids

ولا يحتاج تغيير واجهة النظام الأم.

الـmain.html ليس مصدر تنفيذ Transfer.

---

# 20. لماذا لا أعدل vouchers.html مباشرة

لأن Owner Source Rule يلزم أن يدمج المالك التغييرات المصدرية.

لذلك:
- Production Security: تم تنفيذها.
- Source UI: Owner Change Set جاهز.
- لا Push على frontend من هذه الجلسة.

---

# 21. طبقة الأمن الحقيقية

الترتيب الآن:

UI
→ يخفي الأزرار غير المملوكة

Supabase Trigger
→ يمنع Mutation غير المسؤول

RPC
→ يحمي transaction

RLS / tenant
→ يحمي الشركة

Audit
→ يسجل التنفيذ

هذه هي البنية الصحيحة.

---

# 22. ما لم يتم تغييره عمدًا

لم يتم تعديل:
- main.html
- van-sales.html
- picker.html
- SupplierReturn contract
- DirectSale
- DirectReturn
- Physical Stock Core
- Edge Functions

ولا تم إنشاء Edge Function جديدة.

---

# 23. ما بقي مفتوحًا

## OPEN

### Browser E2E
لم توجد جلسة Browser مصادق عليها في أدوات التنفيذ.

لذلك:
- Production RPC E2E = PASS
- Production Data E2E = PASS
- Browser E2E = OPEN

هذا ليس فشلًا في العقد؛ هو Owner Source / Runtime Verification boundary.

### Published Artifact Verification
مفتوحة حتى يدمج المالك Patch T-01..T-05 في `vouchers.html`.

---

# 24. Self Audit

## ما تم إثباته
- Current Source الحالي مختلف عن تقرير344 القديم.
- `vouchers.html` يحتوي بالفعل الإصلاح النحوي السابق.
- Transfer backend lifecycle موجود.
- Physical Stock writer مركزي.
- Receiver identity لم تكن موجودة في header قبل هذا الإغلاق.
- أضيفت Receiver Binding.
- Sender لا يستطيع Receive.
- Receiver المحدد يستطيع Receive.
- Partial Receive يعمل.
- Replay يجيب duplicate بلا حركة إضافية.
- Full remainder يعمل.
- Complete يعمل.
- QA cleaned.
- Edge count لم يتغير.

## ما لم يتم إثباته
- Browser click-by-click بعد Owner merge.
- Published artifact SHA بعد Owner merge.

---

# 25. مستوى الإغلاق

### Transfer Production Security Contract
**PRODUCTION VERIFIED**

### Receiver Binding
**PRODUCTION VERIFIED**

### Partial / Full Receive Contract
**PRODUCTION VERIFIED**

### Source UI Responsibility
**OWNER PATCH REQUIRED**

### Browser E2E
**OPEN**

### Published Artifact
**OPEN**

### Historical SupplierReturn QA
**RETAINED — OUT OF SCOPE**

---

# 26. Next Exact Session Start

ابدأ فقط من:

1. CURRENT_STATE
2. Report345
3. CURRENT frontend HEAD
4. Current vouchers.html SHA
5. Production trigger
6. Production Transfer E2E state

ثم:
- إذا كان Owner قد دمج T-01..T-05: ابدأ Browser E2E.
- إذا لم يدمجها: لا تعيد Production Security Contract؛ اكتفِ بالتحقق من Owner Source state.

لا تعيد:
- IN-2
- SupplierReturn contract
- DirectSale
- DirectReturn
- Edge Function creation

---

# 27. Final Exact Resumption Point

`companies/company-1/warehouse/vouchers.html`

Current SHA:
`8910c9d6f032a8ddde907e5a4c7ae824a5a4267d`

Next exact owner action:
**Apply Patch T-01 → T-05**

Next verification:
**Authenticated Browser E2E with two users: sender BR-01 and receiver BR-2**

Expected proof:
- sender sees Edit/Delete/Send only while Draft
- receiver sees no sender buttons
- receiver opens Transfer detail
- receiver sees Full Receive / Detailed Receive / Print / Exit
- sender cannot Receive
- receiver cannot Send/Edit/Delete
- partial receive updates received_qty
- full receive closes to Received
- creator/admin can complete per contract
- stock conservation remains true

# END REPORT 345
