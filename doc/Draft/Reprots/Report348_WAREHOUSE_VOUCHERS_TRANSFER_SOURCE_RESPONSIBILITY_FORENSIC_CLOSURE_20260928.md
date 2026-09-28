# تقرير 348 — التحقيق الجنائي الحالي لدورة تحويل الإذن المخزني بين الفروع وإغلاق فجوة مسؤولية المصدر
## التاريخ
2026-09-28

## 1. الغرض ونقطة الاستئناف

هذه الجلسة ليست إعادة بناء للمهمة.

تم الاستئناف من آخر حالة موثقة في:
- CURRENT_STATE.md
- Report347
- Report346
- Report345
ثم تم إسقاط أي ادعاء سابق أمام الأدلة الحالية.

القاعدة التنفيذية:
CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT EVIDENCE
→ BUSINESS CONTRACT
→ SURGICAL REPAIR
→ PRODUCTION VERIFY
→ SOURCE PATCH DOCUMENTATION
→ E2E
→ CURRENT_STATE

التقارير السابقة استُخدمت لفهم التاريخ والقصد فقط، ولم تُعامل كحالة تشغيلية حالية.

---

## 2. مصادر الحقيقة الحالية

### System Git
Current HEAD عند بداية هذه الإضافة:
515c508d6b6d4a15bc627d0720b92079b1153dbc

Parent:
f55b15ee2dffabc5d98bcde02c6245fbbb59481e

Commit:
state: checkpoint Report347 transfer current forensic closure

المستودع النظامي لم يغيّر Mother أو Transfer source في هذا الـcommit؛ التغيير كان في الحالة والتوثيق.

### Frontend Git
Repository:
papamohammed77-glitch/erp-frontend

Current HEAD:
f07bdcc4abbbe899af569f8bfaccde04df279416

Parent:
cc35f3a9da6ababf4c8cd87b05ab93539cdae087

Latest commit:
Update vouchers.html

Current vouchers.html blob:
9e3a9cbd0124639934cdf98abc9ec579f4b19f61

Current main.html blob:
810e4f5440f5975f55099a124deb42b086a49183

Current picker.html blob:
c7ad267d852d415b680aed7716833eea9bcffdf6

Current van-sales.html blob:
8d61382a8e0025a0d079e71dd94f33d106d9088e

### Current frontend diff
الـparent commit cc35f3a9... والـcurrent f07bdcc... غيّرا فقط vouchers.html:
- استبدال toolbar القديم داخل details() بـ topActions+
- إغلاق زر X أثناء حالة receiver

لم يحدث أي تعديل في:
- main.html
- picker.html
- van-sales.html

---

## 3. مراجعة Report347 وتصحيح ما لم يعد صحيحًا

Report347 سجّل أن السماح لمخزني الأذونات بالتعامل مع تحويلات فروع الشركة كان مقصودًا تاريخيًا، ثم بنى على ذلك عدم تقييد مصدر التحويل.

هذه النقطة لم تعد تصف العقد الحالي بشكل كامل بعد فحص المصدر الحالي وقاعدة البيانات.

الفحص الحالي أثبت:

### في vouchers.html
الدالة:
allowedBranch:function(u,b)

كانت تحتوي:

if(
    this.type==='Transfer' &&
    u.role==='مخزني' &&
    u.activeWarehouseRole==='أذونات' &&
    String(b.company_id||'')===String(this.company||'')
){
    return true;
}

هذه العبارة تجعل مخزني الأذونات يرى كل فروع الشركة على أنها فروع مسموحة له أثناء التحويل.

والـpickArr:function(key) كان يعيد allBranches عند:
key === 'wsFrom'
و
type === 'Transfer'.

كما أن pickSelect() كان يعامل wsTo في Transfer كفرع يجب أن يمر في allowedBranch() مثل المصدر.

هذه البنية لا تفرّق بين:
- مسؤولية المرسل على المصدر
- مجرد اختيار الوجهة التي ستستلم

### في Production
تم فحص enforce_transfer_responsibility_contract().

العقد الحالي قبل التصحيح كان يثبت:
- هوية منشئ الإذن
- receiver_user_id
- استبعاد المرسل من مسؤول الاستلام
- receiver immutability
- receiver-only receive

لكنه لم يكن يتحقق من أن actor المنفذ للانتقال Draft → Sent مخول فعليًا على فرع المصدر.

النتيجة:
مخزني فرع BR-2 كان يستطيع تقنيًا إنشاء مسودة Transfer من BR-01 ثم محاولة إرسالها بصفته نفسه، بينما UI كان أصلًا يسمح له باختيار BR-01 كمصدر.

حتى لو لم تنجح الحركة في وجود شروط أخرى، فهذا خرق فعلي لعقد مسؤولية المصدر ويجب إغلاقه عند نقطة الترحيل.

---

## 4. لماذا هذه الفجوة أمنية وليست تجميلية

الـUI ليس حدًا أمنيًا.

وجود أو إخفاء زر:
- لا يحمي المخزون.
- لا يثبت مسؤولية الموظف.
- لا يمنع استدعاء المسار التنفيذي مباشرة.

الحماية يجب أن تنتهي عند نقطة:
Draft → Sent

لأن هذه هي اللحظة التي:
- يحدث فيها الخصم من المصدر
- تنتقل فيها الملكية التشغيلية من sender إلى receiver
- يبدأ فيها مسار الاستلام

لذلك تم إصلاح العقد في Trigger الموجود نفسه، بدون إنشاء Edge Function جديدة.

---

## 5. Production Fix المنفذ

تم تعديل الدالة الموجودة:

public.enforce_transfer_responsibility_contract()

بدون تغيير اسمها أو إنشاء Function بديلة.

أضيفت حراسة مصدر التحويل قبل تثبيت receiver:

### القاعدة الجديدة

لغير الإداري:

- يجب أن يكون from_id موجودًا.
- يجب أن يكون actor مخولًا على فرع المصدر.
- يؤخذ نطاق الفروع من:
  - default_branch_id
  - أو allowed_branch_ids
- يدعم الشكلين الحاليين للـallowed_branch_ids:
  - JSON array
  - JSON string
- يدعم wildcard الموجود في العقد.
- لا يتم تقييد destination بنفس نطاق sender، لأن destination ليست مسؤولية sender بل وجهة استلام.
- يظل admin_override كما هو:
  - مدير النظام
  - مدير عام
  - permissions = ["*"]

رسالة الرفض الجديدة:

مرسل التحويل غير مخول للعمل على فرع المصدر

### ما لم يتغير
- receiver binding
- receiver uniqueness
- receiver immutability
- sender/receiver separation
- Partial Receive
- Full Receive
- idempotency
- stock movement core
- Complete
- existing Edge Functions

لم يتم إنشاء Edge Function جديدة.

---

## 6. لماذا لم نعدل create RPC في Production

create_manual_stock_voucher_atomic() غير متاح لـauthenticated مباشرة.

ACL الحالي:
- postgres EXECUTE
- service_role EXECUTE

والـEdge:
create-stock-voucher
يتحقق من Authorization ويستخدم هوية المستخدم الفعلية قبل استدعاء الـRPC.

لذلك نقطة الأمان الحاسمة هي Send/Posting، وليس مجرد إنشاء Draft.

إغلاق source responsibility في trigger يضمن أن حتى محاولة تجاوز UI وإنشاء مسودة خاطئة لا تستطيع تحويلها إلى حركة مخزنية.

تم عدم تعديل create RPC لتقليل مساحة التغيير وعدم تكرار منطق الحماية دون ضرورة.

---

## 7. ACL الحالي للدالة الحساسة

public.enforce_transfer_responsibility_contract()

الحالة الحالية:
- postgres EXECUTE = true
- service_role EXECUTE = true
- authenticated EXECUTE = false
- anon EXECUTE = false
- PUBLIC EXECUTE = false

وهذا يتوافق مع hardening السابق ولا توجد حاجة لإعادته.

---

## 8. الحسابات المستخدمة في الاختبار الحالي

### Sender
الدور:
مخزني

active warehouse role:
أذونات

default branch:
BR-01

allowed branches:
BR-01

### Receiver
الدور:
مخزني

active warehouse role:
أذونات

default branch:
BR-2

allowed branches:
BR-2

الهدف الأمني:
- Sender يستطيع تنفيذ BR-01 → BR-2
- Receiver يستطيع استلام BR-2 فقط عندما يثبته Production كـreceiver
- Sender لا يستطيع Receive
- لا يمكن للشخص نفسه أن يكون sender وreceiver

---

## 9. E2E بعد Production source guard

تم تنفيذ اختبار Transactional كامل داخل Transaction ثم ROLLBACK.

### السيناريو الأول — محاولة مصدر غير مخول

المستخدم المرتبط بـBR-2 حاول:

إنشاء Transfer:
BR-01 → BR-2

ثم Send من حسابه.

النتيجة:

PASS

تم رفض التنفيذ بالرسالة:

مرسل التحويل غير مخول للعمل على فرع المصدر

إذًا:
- لا يوجد خصم مخزون
- لا يوجد انتقال فعلي
- لا يستطيع مخزني فرع آخر أن يرسل بضاعة نيابة عن BR-01

### السيناريو الثاني — التحويل الصحيح

BR-01 → BR-2

1001:
qty 1

1003:
qty 1

النتائج:

CREATE = PASS
SEND = PASS
RECEIVER BIND = PASS
Receiver = مخزني BR-2
SELF RECEIVE BLOCK = PASS
PARTIAL RECEIVE = PASS
IDEMPOTENT REPLAY = PASS
REMAINDER RECEIVE = PASS
COMPLETE = PASS
FINAL STATUS = Completed
DETAIL RECEIPTS = PASS

### أثر المخزون

1001:
BR-01:
8 → 7

BR-2:
3 → 4

1003:
BR-01:
8 → 7

BR-2:
2 → 3

كل هذه التأثيرات حدثت داخل الاختبار ثم أُعيدت بالكامل بواسطة ROLLBACK.

---

## 10. اختبار الاستلام الجزئي

تم اختبار:
1001 = 1 من أصل 1

وفي اختبار سابق تم اختبار partial 1 من 2 ثم remainder.

العقد الحالي:
received_qty
يحمل الفعلي فقط.

الاستلام لا يعيد إرسال كل الإذن.

الكمية المرسلة:
تبقى qty الأصلية.

الكمية المستلمة:
تُجمع في received_qty.

المتبقي:
qty - received_qty.

الحالة:
Sent
حتى يكتمل المتبقي.

ثم:
Received.

هذا السلوك يطابق الحاجة التشغيلية لحالات:
- نقص كمية
- اختلاف فعلي
- استلام جزء من الشحنة
- إكمال المتبقي لاحقًا.

---

## 11. Idempotency

تم تشغيل نفس operation_id بعد نجاح partial receive.

النتيجة:
duplicate = true

ولم تتكرر الحركة.

إعادة الاستدعاء لا تضيف كمية مرتين.

هذه نقطة حاسمة في:
- ضعف الاتصال
- إعادة الضغط
- Retry
- Mobile network
- فقد الاستجابة بعد التنفيذ

---

## 12. اختبار self-receive

تمت محاولة:

Sender:
استلام نفس التحويل

والنتيجة:

PASS — تم الرفض

الرسالة:
لا يملك هذا المستخدم مسؤولية استلام تحويل الفرع

إذًا المسؤولية ليست مبنية على:
- role فقط
- branch فقط
- permission فقط

بل على snapshot فعلي:
receiver_user_id.

---

## 13. اختبار receiver binding

عند Send:

Production يبحث عن receiver واحد فقط:

- نفس الشركة
- Active
- role = مخزني
- active_warehouse_role = أذونات
- default_branch_id = destination
- ليس actor
- branch scope يشمل destination

ثم يثبت:
receiver_user_id
receiver_assigned_at

بعد ذلك لا يمكن تبديل receiver.

هذا يضمن أن المسؤول الذي يصبح صاحب مسؤولية الاستلام هو الشخص الذي حدده النظام لحظة الإرسال، وليس شخصًا يتم تبديله لاحقًا.

---

## 14. Cleanup

الاختبارات المؤقتة الخاصة بتحويل Transfer في هذه الجلسة أعيدت بالكامل إلى الحالة السابقة بـROLLBACK.

التحقق الحالي:
- لا يوجد voucher ثابت للاختبار الحالي.
- لا يوجد inventory_log للاختبار الحالي.
- لا يوجد أثر مخزني من الاختبارات الحالية.

### ملاحظة
يوجد في Production ستة QA vouchers من مسار SupplierReturn السابق، مرتبطة باختبارات قديمة في Report343/344، ويوجد سجل حركة QA واحد لها.

هذه البيانات ليست Transfer، وبعضها Completed وله أثر مخزني وتوثيق محاسبي.

لذلك لم يتم حذفها أثناء جلسة Transfer حتى لا يتم عكس أثر محاسبي/مخزني خارج نطاق المهمة بدون forensic reversal مستقل.

---

## 15. Current vouchers.html

المصدر الحالي فحصه مباشرة.

### Transfer responsibility UI
العنصر المعيب الأول:

الدالة:

allowedBranch:function(u,b)

الكتلة المعيبة:

if(
    this.type==='Transfer' &&
    u.role==='مخزني' &&
    u.activeWarehouseRole==='أذونات' &&
    String(b.company_id||'')===String(this.company||'')
){
    return true;
}

### الإصلاح الجراحي المطلوب

الملف:
companies/company-1/warehouse/vouchers.html

ابحث عن:
allowedBranch:function(u,b){

واحذف الدالة كاملة واستبدلها بالدالة التالية كاملة:

```javascript
allowedBranch:function(u,b){
    if(!u||!b)return false;

    if(String(u.default_branch_id||'')===String(b.id)){
        return true;
    }

    var a=u.allowed_branch_ids;

    if(a===null||typeof a==='undefined'){
        return true;
    }

    if(Array.isArray(a)){
        a=a.map(String);
    }else if(typeof a==='string'&&a.trim()){
        var raw=a.trim(),
            parsed=null;

        try{
            parsed=JSON.parse(raw);
        }catch(e){
            parsed=null;
        }

        if(Array.isArray(parsed)){
            a=parsed.map(String);
        }else if(typeof parsed==='string'){
            a=[parsed.trim()];
        }else{
            a=raw
                .split(/[,|]/)
                .map(function(x){
                    return x
                        .trim()
                        .replace(/^"|"$/g,'');
                })
                .filter(Boolean);
        }
    }else{
        return false;
    }

    a=a.map(function(x){
        return String(x)
            .trim()
            .replace(/^"|"$/g,'');
    });

    if(a.indexOf('*')>=0){
        return true;
    }

    return (
        a.indexOf(String(b.id))>=0 ||
        a.indexOf(String(b.branch_code||''))>=0
    );
},
```

لا تضف أي Special Case لـTransfer داخل allowedBranch.

هذا يحافظ على:
- default branch
- allowed branches
- wildcard
ويزيل فقط المنح التلقائي لكل فروع الشركة.

---

## 16. الإصلاح الجراحي الثاني — مصدر Transfer

الملف:
companies/company-1/warehouse/vouchers.html

الدالة:
pickArr:function(key)

ابحث داخل فرع:

if(key==='wsFrom'){

عن:

```javascript
if(
    s.type==='Transfer'
){
    return allBranches;
}
```

احذف هذا العنصر بالكامل واستبدله بـ:

```javascript
if(
    s.type==='Transfer'
){
    return userBranches;
}
```

السبب:
- wsFrom = مسؤولية sender.
- لذلك يجب أن يظهر فقط ضمن نطاق المستخدم.
- wsTo = destination ولا يجب أن يرث نطاق sender.

---

## 17. الإصلاح الجراحي الثالث — وجهة Transfer

الدالة:
pickSelect:function(key,id)

ابحث عن العنصر الكامل:

```javascript
var branchSelection=
    (key==='wsFrom'&&s.type!=='DirectReturn') ||
    (key==='wsTo'&&(
        s.type==='Transfer' ||
        s.type==='DirectReturn'
    ));
```

احذفه بالكامل واستبدله بـ:

```javascript
var branchSelection=
    (key==='wsFrom'&&s.type!=='DirectReturn') ||
    (key==='wsTo'&&s.type==='DirectReturn');
```

النتيجة:
- wsFrom Transfer = يتحقق من نطاق sender
- wsTo Transfer = يسمح باختيار أي فرع نشط من نفس الشركة
- wsTo DirectReturn = يبقى تحت existing branch validation
- SupplierReturn لا يتأثر

لا تغيّر بقية pickSelect.

---

## 18. لماذا هذه التعديلات الثلاثة مرتبطة ببعضها

بدون التعديل الأول:
كل Transfer branches تظهر للمخزني.

بدون التعديل الثاني:
حتى لو صححت allowedBranch، فإن pickArr لفرع المصدر سيعيد allBranches مباشرة.

بدون التعديل الثالث:
حتى بعد تصحيح المصدر، ستظهر الوجهة لكنها ستُرفض لأن pickSelect سيطبق allowedBranch على destination.

إذًا الثلاثة تشكل contract واحدًا:

SOURCE:
authorized sender scope

DESTINATION:
any active company branch

RECEIVER:
server-selected destination custodian

هذه ليست ثلاثة تحسينات منفصلة.

---

## 19. T-06 / T-07 / T-08

Report347 سبق أن وثق:

T-06:
زر Print في Draft card.

T-07:
خروج مسؤول الاستلام = خروج بدون حفظ.

T-08:
تنفيذ الاستلام التفصيلي = حفظ الكميات المستلمة.

هذه العناصر لم أكرر نصها هنا حتى لا يُعاد تنفيذ عمل سبق توثيقه.

لا تعيد T-01..T-05.

---

## 20. الطباعة

فحص printVoucher() الحالي أثبت:

- يستخدم modal الحالية كمصدر الوثيقة.
- يفتح نافذة طباعة.
- ينسخ المحتوى.
- يضيف print CSS.
- يستدعي print بعد تحميل النافذة.

لا يوجد خلل Print backend مثبت.

لا حاجة لتغيير printVoucher() في هذه المرحلة.

---

## 21. Exit Without Save

exitVoucherDetails() الحالي:

- يعرض تأكيدًا.
- لا يغيّر voucher.
- لا يغير quantities.
- لا يلمس stock.
- يغلق modal فقط.

المشكلة الحالية شكل/تسمية وليست transaction defect.

---

## 22. العلاقة مع picker.html

Picker الحالي يثبت نمطًا تشغيليًا متسقًا:
- لكل line كمية مطلوبة
- ولكل line كمية فعلية
- progress لا يعني أن كل الكمية مساوية للمطلوب
- operator يتعامل line-by-line

Transfer Receive الحالي يطبق نفس المبدأ على:
received_qty.

وبذلك:
Picker:
qty_ordered → qty_picked

Transfer:
qty → received_qty

وهذا أفضل من تحويل الاستلام إلى boolean:
Received / Not Received.

---

## 23. العلاقة مع van-sales.html

فحص van-sales الحالي لم يثبت أي Transfer contract مفقود.

Van Sales يعتمد على:
setup-van-branch

والتطبيق يستخدم مخزن السيارة المعتمد.

Transfer فرع → فرع مستقل عن runsheet/order lifecycle.

لا يتم خلط:
- Transfer
- DirectSale
- DirectReturn
- Runsheet

وهذا يجب الحفاظ عليه.

لا تغيير في van-sales.html.

---

## 24. العلاقة مع Mother

Mother main.html هو authority layer.

مسؤولياته:
- users
- roles
- permissions
- default_branch_id
- allowed_branch_ids
- warehouse responsibility
- master data

Standalone vouchers:
- execution layer
- لا تنشئ authority مستقلة.

Production:
- يطبق business contract.
- يثبت المسؤولية.
- يكتب المخزون.
- يسجل audit.

التكامل المقصود:

Mother
→ user / branch responsibility
→ vouchers app
→ RPC / Edge
→ DB contract
→ stock movement
→ audit
→ Mother visibility/reporting

لا توجد حاجة لتعديل main.html.

---

## 25. مراجعة المنافسين

### Odoo
Internal Transfers تدعم Source/Destination، Detailed Operations، وتسمح بتحديد Done Quantity في العمليات التفصيلية، كما تدعم barcode scanning لنقل واستلام الأصناف. Moves History تسجل التاريخ والمرجع والصنف والموقع المصدر والوجهة وسبب الحركة.

المصادر:
https://www.odoo.com/documentation/18.0/applications/inventory_and_mrp/barcode/operations/transfers_scratch.html
https://www.odoo.com/documentation/18.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/moves_history.html

### Dynamics 365
Transfer Orders تفصل الشحن والاستلام، وتدعم رؤية الكميات shipped/received ومسارات goods-in-transit والاستلام بدرجة تحكم مختلفة.

المصادر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-transfer-order-receiving-process
https://learn.microsoft.com/en-us/dynamics365/supply-chain/landed-cost/in-transit-processing

### SAP
Stock Transport Order يفصل Goods Issue عن Goods Receipt، ويمكن أن تمر الكمية عبر Stock in Transit قبل وصولها للمخزون المتاح في الوجهة.

المصادر:
https://help.sap.com/docs/SAP_ERP/96bf9ad642cf4b26a29595e3d573fb8c/1e62bd534f22b44ce10000000a174cb4.html
https://help.sap.com/docs/s4hana-cloud-best-practices/stock-transfer-without-delivery-bmh-ie/post-goods-receipt-for-stock-transport-order

### Daftra
نقل المخزون يحدد:
- التاريخ
- المصدر
- الوجهة
- الملاحظات
- البنود
- الكمية
- رصيد قبل
- رصيد بعد

المصدر:
https://docs.daftra.com/tutorial/نقل-المخزون/

### Manager.io
Inventory Transfers تنقل المخزون بين المواقع بدون Sale/Purchase، وتُحفظ كحركة موقعية تغير كميات المواقع.

المصدر:
https://www2.manager.io/guides/10707

---

## 26. فجوات تنافسية حقيقية لاحقة

ليست جزءًا من هذا الإصلاح ولم تُنفذ لتجنب scope creep:

1. In-Transit Stock
2. ETA / Expected Receipt
3. Transfer aging / SLA
4. discrepancy reason codes
5. approval workflow عند فروق الكميات
6. attachment / photo proof
7. barcode receiving
8. lot / serial traceability
9. custody acknowledgement
10. transfer control dashboard
11. reconciliation report
12. overdue transfers report

هذه فجوات Product/Business إضافية وليست أعطالًا في contract الحالي.

---

## 27. Browser E2E

GitHub workflow:

RAWAEA — Warehouse Vouchers Browser E2E

آخر run:
36407039250

HEAD:
f07bdcc4abbbe899af569f8bfaccde04df279416

الحالة:
failure

سبب الفشل المثبت في log ليس Transfer business failure.

الـworkflow نفسه يطبق gate على مصدر HTML:

```javascript
const a=s.indexOf('<script>',s.indexOf('<body>'));
const b=s.lastIndexOf('</script>');
if(a<0||b<=a) throw new Error('INLINE_SCRIPT_NOT_FOUND');
```

ثم ظهر:
INLINE_SCRIPT_NOT_FOUND

بينما Current Source الفعلي يحتوي inline script بعد body في نفس blob الذي نفذ عليه الـrunner.

لذلك:

BROWSER E2E = OPEN

ولا يجوز تحويل:
- DB PASS
- RPC PASS
- Source PASS

إلى Browser PASS.

لا يتم تعديل vouchers.html لإرضاء هذا harness الخطأ.

الإصلاح الصحيح لاحقًا هو تصحيح اختبار الـworkflow نفسه، وليس تشويه صفحة التشغيل.

---

## 28. Deployment Evidence

Current Git = PROVEN

Current DB = PROVEN

Current RPC/Trigger = PROVEN

Current Edge functions = PROVEN

Current Browser workflow = FAILING TEST HARNESS

Published browser artifact = UNVERIFIED

لا يوجد في الأدوات الحالية authenticated browser session يثبت آخر متر على Cloudflare/Production للمستخدمين الفعليين.

---

## 29. مستوى الإغلاق

### مغلق
- receiver binding
- sender/receiver separation
- self-receive prevention
- receiver immutability
- partial receive
- full receive
- idempotency
- physical stock transfer
- complete lifecycle
- source responsibility at database posting
- trigger ACL hardening

### Owner source patches
- T-06
- T-07
- T-08
- T-09 = allowedBranch correction
- T-10 = Transfer source list restriction
- T-11 = Transfer destination selection correction

### مفتوح
- authenticated browser E2E
- published artifact verification
- CI test-harness correction

---

## 30. لا تعيد هذه الأعمال

لا تعيد:
- Transfer receiver migrations
- receiver UUID correction
- receiver trigger architecture
- partial/full receive backend
- self-receive hardening
- existing Edge Functions
- main.html
- picker.html
- van-sales.html
- post_stock_movement
- DirectSale
- DirectReturn
- SupplierReturn
- Runsheet
- historical QA SupplierReturn cleanup

العيب الجديد الذي تم إغلاقه هنا هو:
SOURCE RESPONSIBILITY GAP

---

## 31. SELF AUDIT

تم:
- قراءة الحالة الحالية.
- فحص current system HEAD + parent.
- فحص current frontend HEAD + parent.
- فحص current vouchers blob.
- فحص main blob.
- فحص picker.
- فحص van-sales.
- فحص Production users/branches.
- فحص current RPC signatures.
- فحص current Edge Functions.
- فحص current Trigger.
- فحص current Trigger ACL.
- فحص current stock.
- تنفيذ negative source-authorization test.
- تنفيذ valid transfer E2E.
- تنفيذ partial receive.
- تنفيذ replay.
- تنفيذ remainder.
- تنفيذ complete.
- التحقق من أثر stock.
- التحقق من rollback.
- إبقاء QA SupplierReturn السابقة دون عبث خارج scope.
- عدم تعديل main.html.
- عدم تعديل vouchers.html.
- عدم إنشاء Edge Function جديدة.

---

## 32. تعليمات البداية للمساعد التالي للوصول إلى الحقيقة

لا تبدأ من التقرير.

ابدأ:

1. CURRENT_STATE.md
2. System HEAD + parent
3. Frontend HEAD + parent
4. vouchers.html blob
5. main.html blob
6. Production DB
7. Trigger current definition
8. Edge function current versions
9. Current browser workflow result

ثم افصل دائمًا:

SOURCE OF AUTHORITY
عن
SOURCE OF EXECUTION

ثم افصل:

SENDER RESPONSIBILITY
عن
DESTINATION SELECTION
عن
RECEIVER RESPONSIBILITY

ولا تعتبر:
- hidden button = security
- existing function = closed contract
- RPC pass = browser pass
- report statement = current state

القاعدة:
كل انتقال للمخزون يجب أن يكون له actor واضح، source واضح، destination واضح، receiver واضح، أثر مخزني واضح، وأثر audit واضح.

---

## 33. نقطة الاستكمال الدقيقة

بعد أن يطبق Owner T-09/T-10/T-11 وT-06/T-07/T-08:

1. اقرأ vouchers.html كاملًا.
2. تحقق أن allowedBranch لا يحتوي Transfer all-company bypass.
3. تحقق أن wsFrom Transfer يعيد userBranches.
4. تحقق أن wsTo Transfer لا يرفض destination بسبب sender scope.
5. Parse كامل JavaScript.
6. تحقق عدم وجود duplicate action blocks.
7. Execute authenticated Browser E2E:
   - Sender BR-01
   - Receiver BR-2
   - Draft
   - Edit
   - Delete
   - Send
   - Receiver open
   - Partial receive
   - Full receive
   - Print
   - Exit without save
   - Complete
8. تحقق من stock before/after.
9. تحقق inventory_log.
10. تحقق receiver_user_id.
11. تحقق audit.
12. لا تغلق Browser إلا بعد دليل UI منشور فعلي.
13. بعدها انتقل إلى أول Business Contract Gap حقيقية.

# END REPORT 348
