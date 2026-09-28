# تقرير تنفيذي جنائي — إصلاح بحث مندوب المرتجع المباشر وتكامل النظام الأم
## RAWAEA ERP — Report 358
**التاريخ:** 2026-09-28  
**نطاق الإغلاق:** Warehouse Vouchers → DirectReturn → مندوب البيع المباشر  
**القاعدة الحاكمة:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE

---

## 1. نقطة البداية المعتمدة

تمت قراءة ملف **MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP** كاملًا، وجرى الالتزام بعقده الأساسي:

- التقارير تاريخية وإرشادية وليست مصدر الحقيقة الحالي.
- لا يبدأ التحقيق من الصفر.
- لا يعاد إصلاح ما ثبت إصلاحه.
- لا يجوز إعلان الإغلاق من وجود الكود أو نجاح RPC فقط.
- وحدة الإغلاق هي Capability كاملة، وليست شاشة منفردة.
- أي تعديل يجب أن يكون جراحيًا ويحافظ على Business Contract التاريخي.
- Production هو ما يعمل، وGit هو ما يجب أن يكون قابلًا لإعادة البناء.

تمت قراءة **CURRENT_STATE.md**، ثم أعيد بناء الحالة الفعلية لأن الحالة السابقة كانت تسجل Frontend HEAD أقدم من الـHEAD الحالي.

---

# 2. CURRENT GIT — الحقيقة الحالية

## النظام الأم

قبل هذه الجلسة:

- System HEAD: `c5d20c5c9cd82afaa587a155b2ebe031d03f43fc`
- Parent: `5a854bc731dd28e8272b5e93a757116e8a17424b`

`c5d20...` كان يسجل Report357 وحالة DirectSale Draft السابقة، ولا يخص عطل بحث DirectReturn الحالي.

## Frontend

الـHEAD الفعلي الحالي أحدث من CURRENT_STATE السابق:

- Frontend HEAD: `f28cbe21abe2dfc8d03d02fb0491cc984a273c13`
- Parent المثبت بالمقارنة: `8b6b32145aafdb49ae10af8f36aa888e4d25d412`
- أحدث commit: **Add draft voucher check for current user**
- `companies/company-1/warehouse/vouchers.html`
  - Current blob: `60f4b85ecf3dc32e45cc944bbbbd512ac37ea2a2`
  - 6,340 lines
  - 208,577 chars

تم التحقق أن آخر commit الخاص بـDraft عدّل فقط `actionFor()`، ولا يعالج DirectReturn.

### الملفات المحمية

- `main.html` — لم يلمس.
- `van-sales.html` — لم يلمس.
- `vouchers.html` — لم يكتب Git source في هذه الجلسة؛ تم إعداد تغييرات المالك الجراحية فقط.

---

# 3. التاريخ الوظيفي الذي يجب الحفاظ عليه

## DirectSale

العقد المثبت تاريخيًا:

**Branch → Direct Sales Rep → Vehicle Mobile Stock**

والعلاقة بين مندوب البيع المباشر والمركبة ليست مرادفة لهوية السائق.

## DirectReturn

العقد المثبت:

**Vehicle Mobile Stock → Branch**

وهو عملية مخزنية ميدانية مستقلة عن Order / Runsheet.

وهذا الجزء لا يجوز تحويله إلى Order Return أو Runsheet Return.

المركبة هي وعاء المخزون المتنقل، والمرتجع يتم إلى فرع تشغيلي محدد.

## النظام الأم

النظام الأم يملك المرجع المركزي للعلاقات التشغيلية، وعلى رأسها:

- الشركة.
- الفروع.
- المستخدمون.
- أدوار المستخدمين.
- المركبات.
- مخازن المركبات المتنقلة.
- علاقة مندوب البيع المباشر بالمركبة.
- الأذونات المخزنية.
- دورة الحركة المخزنية.

تطبيق `vouchers.html` ليس مصدر الحقيقة للعلاقة بين المندوب والمركبة؛ بل يستهلك العلاقة المركزية.

---

# 4. Production — الحقيقة الفعلية

تم فحص البنية الفعلية في Supabase.

## العلاقة الصحيحة للمندوب والمركبة

الجدول الفعلي هو:

`public.fleet_vehicle_sales_rep_assignments`

وليس جدولًا باسم `direct_sales_rep_assignments`.

الـProduction يحتوي حاليًا على علاقتين أساسيتين نشطتين:

| المركبة | المندوب | العلاقة |
|---|---|---|
| CHV-2025-01 | مندوب مبيعات بيع مباشر / vansales@rawaea.com | Primary Active |
| VHL-0422 | مندوب مبيعات بيع مباشر 2 / vansales2@rawaea.com | Primary Active |

والـProduction أثبت في الوقت نفسه أن:

- `vehicles.driver_id` للمركبات محل الاختبار = **NULL**.
- العلاقة التشغيلية الحديثة موجودة في `fleet_vehicle_sales_rep_assignments`.
- `fleet_query` يعيد العلاقة الصحيحة عند طلب `direct_sales_rep_assignments`.

هذه هي نقطة الحسم.

## النتيجة

استخدام:

`vehicle.driver_id`

كمصدر وحيد لهوية مندوب البيع المباشر أصبح غير صحيح بالنسبة للمركبات التي تستخدم Master Assignment.

ولهذا فإن اعتبار `driver_id` هو العلاقة الوحيدة يقطع التكامل بين النظام الأم وتطبيق الأذونات.

---

# 5. التحقيق الجنائي في سبب عدم استجابة حقل المندوب

تم تثبيت **ثلاثة عيوب مترابطة** داخل `vouchers.html`.

## العيب 1 — الحقل نفسه مقفول

### الملف
`companies/company-1/warehouse/vouchers.html`

### العنصر
`routeHtml:function()`

### الموضع الحالي
حوالي السطر **4268**

### النص المعيب المحدد

`p('wsRep','مندوب البيع المباشر',true)`

قيمة `true` تجعل الحقل `readonly`.

وبالتالي:

- `oninput="App.pickSearch(...)"` موجود.
- لكن المستخدم لا يستطيع الكتابة أصلًا.
- لذلك البحث الذكي لا يمكن تشغيله من لوحة المفاتيح.

---

## العيب 2 — مصفوفة نتائج المندوب تبحث عن الفرع في المكان الخطأ

### الملف
`vouchers.html`

### العنصر
`pickArr:function(key)`

### الموضع
حوالي السطر **3437**

### العيب

النظام يحسب:

`b`

من قيمة `wsFrom`.

لكن في DirectReturn:

- `wsFrom` = **Vehicle ID**
- وليس Branch ID.

لذلك:

`allBranches.find(...wsFrom...)`

لا يعثر على فرع.

وبعد ذلك:

`if(key==='wsRep')`

يجد:

`!b`

ويرجع:

`[]`

أي أن قائمة المندوبين تكون فارغة حتى بعد إزالة `readonly`.

وهذا يفسر بدقة لماذا المشكلة ليست UI-only.

---

## العيب 3 — العلاقة الحالية بعد اختيار السيارة تعتمد على driver_id القديم

### الملف
`vouchers.html`

### العنصر
داخل:

`pickSelect:function(key,id)`

### DirectReturn branch
حوالي السطر **4116**

الحالي:

`return rp.id===x.driver_id`

والحقل يصبح `readonly` عند إيجاد مندوب.

هذا يسبب مشكلتين:

1. السيارة ذات Master Assignment صحيح قد لا تحمل `driver_id`.
2. حقل المندوب لا يبقى قابلًا للبحث.

---

# 6. عيب التكامل المكتشف في طبقة الحفظ

### الملف
`vouchers.html`

### العنصر
كتلة:

`if(this.type==='DirectReturn')`

داخل:

`submit:function()`

حوالي السطر **5696**

الحالي يستخرج:

`rr`

من:

`vv.driver_id`

ولا يستخدم اختيار `wsRep` كمصدر أساسي.

إذًا حتى لو أصلحنا واجهة البحث وحدها، يمكن أن يظل المستخدم يختار مندوبًا بينما تقوم عملية Submit بتجاهل الاختيار وإعادة اشتقاق المندوب من `driver_id`.

هذا ليس إصلاحًا تجميليًا؛ هذه فجوة Business Contract فعلية.

---

# 7. Production Backend — الإصلاح الذي تم تنفيذه مباشرة

تم تعديل **الموجود بالفعل** فقط، ولم يتم إنشاء Edge Function جديد.

## 7.1 Create Contract

تم تحديث:

`create_manual_stock_voucher_atomic_core_12_20260828`

في DirectReturn ليصبح:

**Primary Active Master Assignment**

هو المصدر الأول للتحقق من:

`Vehicle ↔ Direct Sales Rep`

مع الإبقاء على:

`vehicles.driver_id`

كـ **legacy fallback** فقط.

أي:

`fleet_vehicle_sales_rep_assignments`

أو

`vehicles.driver_id`

ولا يوجد كسر للحالات التاريخية القديمة.

## 7.2 Update Contract

تم تحديث:

`update_manual_stock_voucher_atomic`

بنفس القاعدة.

وهذا يغلق التناقض الذي كان يجعل التعديل يعتمد على `driver_id` حتى عندما تكون العلاقة الحديثة في Master Assignment.

## 7.3 لم يتم تعديل

- `send_stock_voucher_atomic`
- `send_stock_voucher_atomic_core_20260828`
- `inventory_voucher_report`
- `inventory_control`
- دورة Transfer.
- دورة DirectReturn Receive.
- أي Edge Function جديدة.

والـstock writer المركزي ما زال كما هو.

---

# 8. الاختبارات التي تم تنفيذها في Production

## 8.1 اختفاء المشكلة قبل الإصلاح

تم إنشاء Fixture حقيقي عن طريق المسار الموجود في Production.

اختبار ما قبل الإصلاح أثبت أن Production كان يسمح بإنشاء DirectReturn بمندوب **غير مرتبط بالمركبة**:

- المركبة: CHV-2025-01
- المندوب المختبر: vansales2
- النتيجة قبل الإصلاح: **تم إنشاء IN-9**

وهذا إثبات مباشر لفجوة Backend، وليس استنتاجًا من الواجهة.

---

## 8.2 اختبار الرفض بعد الإصلاح

بعد الإصلاح تم تكرار نفس السيناريو بمندوب غير مرتبط.

النتيجة:

**رفض Production للعملية**

بالرسالة:

`المركبة المصدر لا تتبع مندوب البيع المباشر المحدد`

وهذا يثبت أن Master Assignment أصبح جزءًا من Business Contract وليس مجرد بيانات مساعدة للواجهة.

---

## 8.3 اختبار العلاقة الصحيحة

تم إنشاء DirectReturn صحيح بالمركبة:

`CHV-2025-01`

مع المندوب الأساسي:

`vansales@rawaea.com`

والنتيجة:

**Create = PASS**

ثم اختُبرت عملية Update داخل سياق مصادق عليه محاكى بـJWT claim.

النتيجة:

**Update = PASS**

مع:

- Status = Draft
- voucher identity صحيحة
- operation identity صحيحة.

---

## 8.4 اختبار النظام الأم

تم استدعاء:

`fleet_query('direct_sales_rep_assignments')`

داخل سياق مصادق عليه.

النتيجة:

**PASS**

والبيانات أعادت:

- المركبة.
- المندوب.
- assignment_id.
- Primary Active relation.

إذًا مصدر الحقيقة الموجود في النظام الأم قابل للاستهلاك من تطبيق الأذونات.

---

# 9. تنظيف بيانات الاختبار

تم تنظيف الـfixtures التي أنشأتها هذه الجلسة:

- IN-9 — محذوف.
- IN-10 — محذوف.
- لا توجد حاليًا Drafts اختبارية من هذه الجلسة.
- لا توجد DirectReturn تجريبية باقية من هذه الجلسة.

### ملاحظة رقابية

لم يتم حذف السجلات التاريخية القديمة المكتملة أو المرسلة التي تحمل آثار حركة مخزنية لمجرد أن وصفها يحتوي كلمة "تجريبي"، لأن حذفها قد يمحو حركات ومراجعات فعلية.

هذه ليست عملية حذف آمنة بالاعتماد على الاسم فقط.

---

# 10. التعديل الجراحي المطلوب من مالك المصدر

## PATCH 1 — فتح حقل البحث

### الملف
`companies/company-1/warehouse/vouchers.html`

### العنصر
`routeHtml:function()`

### ابحث تحديدًا عن السطر:

`if(t==='DirectReturn')return'<div class="grid grid-cols-1 sm:grid-cols-3 gap-2">'+p('wsFrom','المركبة المصدر')+p('wsRep','مندوب البيع المباشر',true)+p('wsTo','الفرع الوجهة')+'</div>';`

احذف هذا السطر واستبدله بالكامل بـ:

```
if(t==='DirectReturn')return'<div class="grid grid-cols-1 sm:grid-cols-3 gap-2">'+p('wsFrom','المركبة المصدر')+p('wsRep','مندوب البيع المباشر')+p('wsTo','الفرع الوجهة')+'</div>';
```

---

# 11. PATCH 2 — إصلاح مصدر قائمة المندوبين في DirectReturn

### الملف
`companies/company-1/warehouse/vouchers.html`

### الدالة
`pickArr:function(key)`

### الموضع
حوالي السطر **3601** في الـHEAD الحالي عند كتلة `if(key==='wsRep')`.

### ابحث عن هذه الكتلة كاملة فقط:

```
if(key==='wsRep'){
   return (
       (s.refs.reps||[])
       .filter(function(r){
           if(!b){
               return false;
           }

           if(
               s.type==='DirectSale' &&
               !s.refs.repVehicleMap[
                   String(r.id)
               ]
           ){
               return false;
           }

           return (
               s.allowedBranch(
                   s.user,
                   b
               ) &&
               s.allowedBranch(
                   r,
                   b
               )
           );
       })
   );
}
```

### احذفها بالكامل واستبدلها بـ:

```
if(key==='wsRep'){

    var returnBranchId=
        s.type==='DirectReturn'
            ?(
                (RW_UI.byId('wsTo')||{})
                    .value||
                ''
            )
            :'',

        returnBranch=
            returnBranchId
                ?allBranches.find(
                    function(x){
                        return String(x.id)===
                            String(returnBranchId);
                    }
                )||
                null
                :null;

    return (
        s.refs.reps||[]
    )
    .filter(function(r){

        if(!r){
            return false;
        }

        if(
            s.type==='DirectSale'
        ){
            return (
                !!s.refs.repVehicleMap[
                    String(r.id)
                ] &&
                !!b &&
                s.allowedBranch(
                    s.user,
                    b
                ) &&
                s.allowedBranch(
                    r,
                    b
                )
            );
        }

        if(
            s.type==='DirectReturn'
        ){

            var mappedVehicleId=
                s.refs.repVehicleMap[
                    String(r.id)
                ]||
                '';

            var mappedVehicle=
                (s.refs.vehicles||[])
                    .find(function(v){
                        return String(v.id)===
                            String(mappedVehicleId);
                    });

            var legacyVehicle=
                (s.refs.vehicles||[])
                    .find(function(v){
                        return (
                            String(v.driver_id||'')===
                            String(r.id) &&
                            v.status==='Active' &&
                            v.mobile_stock_enabled!==false &&
                            !!s.vehicleBranch(v)
                        );
                    });

            var hasReturnVehicle=
                !!(
                    (
                        mappedVehicle &&
                        mappedVehicle.status==='Active' &&
                        mappedVehicle.mobile_stock_enabled!==false &&
                        !!s.vehicleBranch(
                            mappedVehicle
                        )
                    )||
                    legacyVehicle
                );

            if(!hasReturnVehicle){
                return false;
            }

            if(returnBranch){

                return (
                    s.allowedBranch(
                        s.user,
                        returnBranch
                    ) &&
                    s.allowedBranch(
                        r,
                        returnBranch
                    )
                );
            }

            return true;
        }

        if(!b){
            return false;
        }

        return (
            s.allowedBranch(
                s.user,
                b
            ) &&
            s.allowedBranch(
                r,
                b
            )
        );
    });
}
```

### نتيجة هذا الإصلاح

البحث يصبح:

**مندوب → Master Assignment → Vehicle**

وليس:

**Vehicle ID → Branch ID → Rep**

كما كان.

---

# 12. PATCH 3 — جعل اختيار المركبة يقرأ Master Assignment

### الملف
`companies/company-1/warehouse/vouchers.html`

### الدالة
`pickSelect:function(key,id)`

### DirectReturn element

### ابحث عن الكتلة التي تبدأ حرفيًا:

```
if(key==='wsFrom'&&s.type==='DirectReturn'){
```

وفي داخلها ابحث تحديدًا عن هذا العنصر:

```
var r=
    s.refs.reps.find(function(rp){
        return rp.id===x.driver_id;
    });

RW_UI.byId('wsRep').value=r?r.id:'';
RW_UI.byId('wsRepSearch').value=
    r?(r.name||r.email):'';

if(r){
    RW_UI.byId('wsRepSearch').setAttribute(
        'readonly',
        'readonly'
    );
}else{
    RW_UI.byId('wsRepSearch').removeAttribute(
        'readonly'
    );
}
```

### احذف هذا العنصر فقط واستبدله بالكامل بـ:

```
var linkedRepId=
    s.refs.vehicleRepMap[
        String(x.id)
    ]||
    x.driver_id||
    '';

var r=
    (s.refs.reps||[])
        .find(function(rp){
            return String(rp.id)===
                String(linkedRepId);
        });

RW_UI.byId('wsRep').value=
    r?
        r.id:
        '';

RW_UI.byId('wsRepSearch').value=
    r?
        (r.name||r.email):
        '';

RW_UI.byId('wsRepSearch')
    .removeAttribute(
        'readonly'
    );
```

### النتيجة

اختيار المركبة يعرض مندوبها الحالي من Master Assignment.

لكن الحقل يظل قابلًا للبحث.

---

# 13. PATCH 4 — اختيار المندوب يجب أن يربط المركبة تلقائيًا

### الملف
`companies/company-1/warehouse/vouchers.html`

### الدالة
`pickSelect:function(key,id)`

### ابحث عن:

```
if(key==='wsRep'){

    RW_UI.byId(key+'Search').value=
        x.name||
        x.email||
        '';

    if(
        s.type==='DirectSale'
    ){
```

### احذف هذا العنصر `if(key==='wsRep')...` بالكامل حتى قبل:

```
}else if(
    key==='wsTo' &&
    s.type==='SupplierReturn'
)
```

### واستبدله بالكامل بـ:

```
if(key==='wsRep'){

    RW_UI.byId(key+'Search').value=
        x.name||
        x.email||
        '';

    if(
        s.type==='DirectReturn'
    ){

        var mappedVehicleId=
            s.refs.repVehicleMap[
                String(x.id)
            ]||
            '';

        var mappedVehicle=
            (s.refs.vehicles||[])
                .find(function(v){
                    return String(v.id)===
                        String(mappedVehicleId);
                });

        if(
            !mappedVehicle ||
            mappedVehicle.status!=='Active' ||
            mappedVehicle.mobile_stock_enabled===false ||
            !s.vehicleBranch(mappedVehicle)
        ){

            RW_UI.byId('wsRep').value='';
            RW_UI.byId('wsRepSearch').value='';

            RW_UI.toast(
                'لا توجد مركبة نشطة مرتبطة حاليًا بهذا المندوب',
                'error'
            );

            return;
        }

        var selectedReturnBranchId=
            (RW_UI.byId('wsTo')||{})
                .value||
            '';

        if(selectedReturnBranchId){

            var selectedReturnBranch=
                (s.refs.branches||[])
                    .find(function(branch){
                        return String(branch.id)===
                            String(selectedReturnBranchId);
                    });

            if(
                !selectedReturnBranch ||
                !s.allowedBranch(
                    s.user,
                    selectedReturnBranch
                ) ||
                !s.allowedBranch(
                    x,
                    selectedReturnBranch
                )
            ){

                RW_UI.byId('wsRep').value='';
                RW_UI.byId('wsRepSearch').value='';

                RW_UI.toast(
                    'المندوب خارج نطاق فرع استلام المرتجع المحدد',
                    'error'
                );

                return;
            }
        }

        RW_UI.byId('wsFrom').value=
            mappedVehicle.id;

        RW_UI.byId('wsFromSearch').value=
            mappedVehicle.vehicle_code||
            mappedVehicle.license_plate||
            mappedVehicle.model||
            '';

    }else if(
        s.type==='DirectSale'
    ){

        var synced=
            s.syncDirectSaleVehicleWithRep(
                x.id
            );

        if(!synced){
            RW_UI.byId('wsRep').value='';
            RW_UI.byId('wsRepSearch').value='';

            RW_UI.toast(
                'لا توجد مركبة نشطة معينة لهذا المندوب في إدارة الأسطول',
                'error'
            );

            return;
        }
    }

}else if(
    key==='wsTo' &&
    s.type==='SupplierReturn'
)
```

### الهدف

اختيار المندوب في DirectReturn يصبح Smart Bi-Directional Picker:

**Rep → Master Assignment → Vehicle**

والعكس:

**Vehicle → Master Assignment → Rep**

مع استمرار `wsTo` كفرع الاستلام.

---

# 14. PATCH 5 — منع Submit من إعادة اشتقاق المندوب من driver_id فقط

### الملف
`companies/company-1/warehouse/vouchers.html`

### الدالة
`submit:function()`

### الموضع
حوالي السطر **5700**

### ابحث تحديدًا عن:

```
var rr=vv&&(this.refs.reps||[]).find(function(x){
    return x.id===vv.driver_id;
});
```

### واستبدله بالكامل بـ:

```
var selectedRepId=
    String(
        rep||
        ''
    ).trim();

var linkedRepId=
    selectedRepId||
    String(
        s.refs.vehicleRepMap[
            String(fr)
        ]||
        vv.driver_id||
        ''
    );

var rr=
    vv&&
    (this.refs.reps||[])
        .find(function(x){
            return String(x.id)===
                String(linkedRepId);
        });

var assignedVehicleId=
    selectedRepId
        ?String(
            s.refs.repVehicleMap[
                selectedRepId
            ]||
            ''
        )
        :'';
```

ثم داخل نفس DirectReturn validation، **قبل**:

```
if(
    !vv||
```

أضف بعد هذا العنصر مباشرة:

```
if(
    selectedRepId &&
    assignedVehicleId &&
    String(assignedVehicleId)!==
    String(fr)
){
    RW_UI.toast(
        'مندوب البيع والمركبة لا ينتميان إلى نفس التعيين الحالي في إدارة الأسطول',
        'error'
    );
    return;
}
```

ولا تحذف بقية Validation الحالية.

---

# 15. لماذا هذه التعديلات الخمسة هي الحد الجراحي الصحيح

لا يوجد هنا إعادة بناء للتبويب.

لم يتم تغيير:

- دورة DirectReturn.
- نوع الحركة.
- Vehicle → Branch.
- stock writer.
- receive workflow.
- branch authorization.
- mobile branch.
- idempotency.
- accounting architecture.
- Main system.
- Van Sales operational app.

تم فقط إصلاح Consumer Layer بحيث يستهلك Master Assignment الذي يستخدمه النظام فعليًا.

---

# 16. لماذا لا نستخدم Edge Function جديدة

المشروع وصل بالفعل إلى حد عدد الـEdge Functions / Spend Cap.

وهذه المشكلة لا تحتاج Function جديدة.

المصدر موجود بالفعل:

`fleet_query`

والمسار الحالي:

`vouchers.html → fleet_query → fleet_vehicle_sales_rep_assignments`

كافٍ.

والـdatabase mutations تستخدم Functions موجودة وتم تطويرها in-place.

---

# 17. المنافسة — الفجوة التي عولجت

التحقق من وثائق الأنظمة المنافسة يوضح أن إدارة المخزون الاحترافية لا تكتفي بوجود حركة مخزنية؛ بل تعتمد على سياق واضح للمخزن/الموقع/العهدة والحركة والتفاصيل.

### Dynamics 365

يدعم Transfer Orders مع فصل واضح بين الشحن والاستلام وتتبع الكمية أثناء النقل، كما يدعم ربط مستودعات ومستويات إعادة التعبئة.  
المصدر:
https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-transfer-between-locations

https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/transfer-orders-warehouse

### Daftra

يوفر Stock Transfer بين المستودعات، ويعرض الكمية قبل وبعد الحركة، كما يدعم Inventory Detailed Transactions حسب Warehouse وType، بما فيها Stock Permission وSales Return وStock Transfer وManual Adjustment.  
المصادر:
https://docs.daftra.com/en/tutorial/transferring-stock/

https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/

https://docs.daftra.com/en/user_manual/how-to-assign-inventory-to-an-employee/

### RAWAEA

الميزة التي يجب الحفاظ عليها ليست تقليد هذه الشاشات.

RAWAEA لديه مسار ميداني مستقل:

**Van Sales → Mobile Stock → DirectReturn → Branch**

مع Master Assignment في النظام الأم، وهو ما يحافظ على التكامل بين التطبيقات التشغيلية المستقلة.

الفجوة التي ظهرت هنا كانت في Consumer UX وليس في فكرة الـworkflow.

---

# 18. E2E Status

## Production / Database

**PASS**

تم إثبات:

- Master assignment lookup.
- Valid DirectReturn Create.
- Invalid Rep/Vehicle combination rejection.
- Authenticated Update داخل transaction.
- Cleanup.

## Source logic

**PATCH READY**

العناصر الجراحية الخمسة أعلاه مطابقة للـHEAD الحالي.

## Browser E2E

**OPEN**

لم يتم تغيير `vouchers.html` مباشرة، ولم يتم نشر مصدر جديد من هذه الجلسة.

## Served Artifact

**OPEN**

لا يجوز اعتبار الـProduction UI مغلقًا قبل:

1. تطبيق owner patches.
2. قراءة `vouchers.html` كاملًا.
3. Parse كامل للـinline JavaScript.
4. نشر الـFrontend.
5. إثبات SHA/identity للـserved artifact.
6. فتح DirectReturn فعليًا.
7. الكتابة داخل حقل مندوب البيع.
8. ظهور نتائج البحث الذكي.
9. اختيار مندوب.
10. تحقق الربط التلقائي بالمركبة.
11. اختيار فرع الاستلام.
12. إنشاء Draft.
13. فتح Draft.
14. Submit.
15. Production re-check.

---

# 19. Deployment Boundary

لا يوجد ادعاء بأن Browser E2E أو Served Artifact أصبح PASS.

الحالة الصحيحة:

`Production DB = FIXED`

`Current Source = VERIFIED`

`Owner Source Patch = READY`

`Browser E2E = OPEN`

`Deployment Evidence = OPEN`

وهذا متوافق مع عقد MASTER CTO ولا يعتبر False Closure.

---

# 20. التغييرات الدائمة في Git

تم إنشاء مصدر Migration دائم:

`supabase/migrations/20260928221500_vouchers_directreturn_rep_assignment_contract_fix_20260928.sql`

وظيفته تسجيل نفس الإصلاح الجراحي الذي طُبق مباشرة في Production على الـFunctions الحالية.

لا ينشئ:

- Function جديدة.
- Table جديدة.
- Edge Function جديدة.

---

# 21. تعليمات المساعد القادم — نقطة الانطلاق

لا يبدأ من الصفر.

ابدأ بهذا التسلسل:

### A
افتح `CURRENT_STATE.md` الجديد.

### B
تحقق من:

- System HEAD.
- Parent.
- Frontend HEAD.
- vouchers blob.
- Production migration/function state.

### C
لا تعاود فحص Report349–357 إلا كمراجع تاريخية.

### D
لا تعيد إصلاح:

- Transfer.
- Receiver Binding.
- Partial/Full Receive.
- SupplierReturn.
- DirectSale Draft.
- DirectReturn backend authorization السابق.

هذه كلها ليست نقطة البداية الجديدة.

### E
طبّق فقط Owner patches في `vouchers.html` أعلاه.

### F
بعد الدمج:

**Read Full File → Parse → Deploy → Served SHA → Browser E2E → Production Verification → Update CURRENT_STATE**

### G
إذا بقي Search صحيحًا وانتقلت المهمة إلى نقطة أخرى، لا تعيد تصميم Smart Picker.

ابحث عن أول Business Contract حقيقي غير مغلق في CURRENT_STATE وانتقل إليه.

---

# 22. Self Audit

### هل بدأ التحقيق من التقارير فقط؟
لا.

### هل تم فحص Current Git؟
نعم.

### هل تمت مقارنة الـHEAD الجديد مع Parent؟
نعم.

### هل تم فحص Current Source؟
نعم.

### هل تم فحص Production؟
نعم.

### هل تم فحص Current Database؟
نعم.

### هل تم إثبات Master Assignment؟
نعم.

### هل تم إنشاء Edge Function جديدة؟
لا.

### هل تم لمس main.html؟
لا.

### هل تم لمس van-sales.html؟
لا.

### هل تم كتابة vouchers.html مباشرة؟
لا.

### هل تم تعديل Production Functions الحالية؟
نعم، في المكان الصحيح وبدون إنشاء Functions جديدة.

### هل تمت Cleanup لبيانات الاختبار الجديدة؟
نعم.

### هل Browser E2E مغلق؟
لا.

### هل Served Artifact مغلق؟
لا.

### هل تم تجنب False Closure؟
نعم.

---

# 23. الخلاصة التنفيذية

**السبب المباشر:** حقل مندوب DirectReturn كان `readonly`.

**السبب الوظيفي الثاني:** `pickArr('wsRep')` يبحث عن الفرع باستخدام Vehicle ID.

**السبب المعماري الثالث:** النظام الأم أصبح يستخدم `fleet_vehicle_sales_rep_assignments` كـMaster Assignment، بينما Consumer Layer كان لا يزال يعتمد على `vehicles.driver_id`.

**العلاج:** ربط DirectReturn بالـMaster Assignment مع fallback تاريخي، وإتاحة Smart Bidirectional Picker بين المندوب والمركبة، مع عدم تغيير دورة الحركة نفسها.

**Production:** تم إغلاق فجوة التحقق في Create/Update مباشرة.

**Source:** خمسة تعديلات جراحية جاهزة للمالك فقط.

**الحد المتبقي:** Owner merge + Deploy + Browser E2E + Served Artifact verification.

**قاعدة الجلسة التالية:** لا تعالج ما ثبت إغلاقه. ابدأ من هذه الحالة فقط.
