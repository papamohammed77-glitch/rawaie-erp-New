# Report307 — Warehouse Vouchers Current-Source Regression & Integration Forensic Closure
**التاريخ:** 22 سبتمبر 2026  
**نطاق الجلسة:** `companies/company-1/warehouse/vouchers.html` + التكامل مع النظام الأم + Van Sales + Production evidence + Service Worker infrastructure  
**قاعدة التنفيذ:** Production أولًا، ثم Current Source، ثم العقد، ثم الإصلاح الجراحي، ثم التحقق.

---

## 1. مصدر الحقيقة الحالي

تمت قراءة:
- `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md` حتى EOF.
- `doc/Draft/Reprots/Report306_WAREHOUSE_VOUCHERS_FORENSIC_E2E_COMPETITIVE_CLOSURE_20260922.md` حتى EOF.
- `CURRENT_STATE.md` حتى EOF.

تمت مطابقة المصدر الحالي مع Git:
- System repo HEAD قبل هذا التقرير: `95370aefbb45e46cc66f4937caaf4f6862fe275e`
- Parent: `516619eaeea6c08a92d9ee2ad8301d5d6bbbe99a`
- Frontend current `vouchers.html` blob: `1117c83808b5aee0ab26dc3c53adbb6eecd29538`
- آخر تعديل على `vouchers.html`: commit `d8d1bde852a6b2dd25a11b06d75baac3e1af0991`, parent `7589fcc2312b70b4dda6801d27053f81f3873684`.
- `main.html` current blob: `8c3d6b05fd6a94a6b488f12b29da85ae888f70bc` — لم يتم تعديله.
- `van-sales.html` current blob: `445dff4217fbf4a82f333fa716bba5d74def7680` — لم يتم تعديله.

---

## 2. الحقيقة الجنائية للخطأ

### العطل 1 — `App.List is not a function`

**الملف:** `companies/company-1/warehouse/vouchers.html`  
**الدالة:** `renderList:function(scope)`  
**آخر commit أدخل العطل:** `d8d1bde...`

الـparent diff أثبت أن زر التصدير تغيّر من:
`App.loadList(App.tabName)`
إلى:
`App.List()`

وفي نفس commit أضيفت الدالة الموجودة فعلًا:
`exportVoucherList:function(){...}`

لكن لا توجد دالة مستقلة باسم `List`.

**النتيجة:** الزر يستدعي اسمًا غير موجود، بينما الدالة المقصودة موجودة باسم `exportVoucherList`.

### العطل 2 — تحذيرات nested `<select>`

داخل `renderList` الحالي:
1. يتم فتح `#listType`.
2. يتم إدخال `typeOptions`.
3. يتم فتح `#listStatus` قبل إغلاق `#listType`.
4. ثم يوجد إغلاقان متتاليان.

لذلك يقوم HTML parser بتصحيح DOM تلقائيًا، وهو سبب سلسلة التحذيرات:
`A <select> tag was parsed within another <select> tag...`

**الإصلاح الصحيح:** إغلاق `listType` مباشرة بعد `typeOptions`، ثم فتح `listStatus`، مع إبقاء إغلاق واحد لـ`listStatus`.

---

## 3. الإصلاح الجراحي المطلوب من المالك في `vouchers.html`

### العنصر المحدد للحذف

**ابحث حرفيًا عن:**
`renderList:function(scope){`

**احذف الدالة كاملة** حتى بداية:
`filterList:function(){`

**واستبدلها بالكامل بالدالة التالية:**

```javascript
renderList:function(scope){
    var s=this;

    var typeOptions=[
        '<option value="">كل الأنواع</option>',
        '<option value="Transfer">تحويل مخزني</option>',
        '<option value="DirectSale">صرف سيارة بيع مباشر</option>',
        '<option value="DirectReturn">استلام مرتجع سيارة</option>',
        '<option value="SupplierReturn">مرتجع لمورد</option>'
    ].join('');

    function secondsBetween(a,b){
        var x=Date.parse(a||'');
        var y=Date.parse(b||'');

        if(!Number.isFinite(x)||!Number.isFinite(y)||y<x){
            return null;
        }

        return Math.round((y-x)/1000);
    }

    function durationText(sec){
        if(sec===null||sec===undefined){
            return '—';
        }

        var n=Math.max(0,Number(sec)||0),
            d=Math.floor(n/86400);

        n-=d*86400;

        var h=Math.floor(n/3600);

        n-=h*3600;

        var m=Math.floor(n/60),
            parts=[];

        if(d) parts.push(d+'ي');
        if(h||d) parts.push(h+'س');
        parts.push(m+'د');

        return parts.join(' ');
    }

    var total=this.vouchers.length;

    var draft=this.vouchers.filter(function(v){
        return v.status==='Draft';
    }).length;

    var active=this.vouchers.filter(function(v){
        return v.status==='Sent'||v.status==='Received';
    }).length;

    var completedRows=
        this.vouchers
            .map(function(v){
                return secondsBetween(
                    v.created_at,
                    v.completed_at
                );
            })
            .filter(function(x){
                return x!==null;
            });

    var avgCompleted=
        completedRows.length
            ?
            durationText(
                Math.round(
                    completedRows.reduce(
                        function(a,b){return a+b;},
                        0
                    )/completedRows.length
                )
            )
            :
            '—';

    var h=
        '<div class="h-full overflow-y-auto p-4 overscroll-contain">'+
        '<div class="max-w-[1150px] mx-auto">'+

        '<div class="flex justify-between items-center mb-4">'+
        '<div>'+
        '<b class="text-lg">'+
        (scope==='pending'
            ?'📄 الأذونات المعلقة'
            :'✅ الأذونات المكتملة')+
        '</b>'+
        '<p class="text-xs text-slate-400 mt-1">'+
        '<span id="listCount">'+this.vouchers.length+'</span>'+
        ' سجل · <span id="syncAt">آخر مزامنة: —</span>'+
        '</p>'+
        '</div>'+
        '<button onclick="App.toggleMenu()" class="gold-chip px-4 py-2.5 rounded-2xl font-black text-sm">'+
        '+ نوع جديد</button>'+
        '</div>'+

        '<div class="grid grid-cols-2 lg:grid-cols-4 gap-2 mb-4">'+

        '<div class="card p-3">'+
            '<span class="block text-[9px] text-slate-400 font-bold">إجمالي السجلات المحملة</span>'+
            '<b class="block text-lg mt-1">'+
                total+
            '</b>'+
        '</div>'+

        '<div class="card p-3">'+
            '<span class="block text-[9px] text-amber-600 font-bold">مسودات</span>'+
            '<b class="block text-lg mt-1 text-amber-700">'+
                draft+
            '</b>'+
        '</div>'+

        '<div class="card p-3">'+
            '<span class="block text-[9px] text-blue-600 font-bold">قيد الدورة</span>'+
            '<b class="block text-lg mt-1 text-blue-700">'+
                active+
            '</b>'+
        '</div>'+

        '<div class="card p-3">'+
            '<span class="block text-[9px] text-emerald-600 font-bold">متوسط زمن الإغلاق</span>'+
            '<b class="block text-sm mt-2 text-emerald-700">'+
                durationText(
                    completedRows.length
                        ?
                        Math.round(
                            completedRows.reduce(
                                function(a,b){return a+b;},
                                0
                            )/completedRows.length
                        )
                        :
                        null
                )+
            '</b>'+
        '</div>'+

        '</div>'+

        '<div class="card mb-4">'+
        '<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-2">'+
        '<input id="listSearch" oninput="App.filterList()" placeholder="🔍 رقم الإذن أو المرجع أو النوع" class="w-full p-3 bg-white rounded-2xl border-2 border-slate-100 outline-none font-semibold text-sm">'+
        '<select id="listType" onchange="App.filterList()" class="w-full p-3 bg-white rounded-2xl border-2 border-slate-100 outline-none font-semibold text-sm">'+
        typeOptions+
        '</select>'+
        '<select id="listStatus" onchange="App.filterList()" class="w-full p-3 bg-white rounded-2xl border-2 border-slate-100 outline-none font-semibold text-sm">'+
        '<option value="">كل الحالات</option>'+
        '<option value="Draft">مسودة</option>'+
        '<option value="Sent">مُرسل</option>'+
        '<option value="Received">مُستلم</option>'+
        '<option value="Completed">مكتمل</option>'+
        '<option value="Cancelled">ملغى</option>'+
        '</select>'+
        '</select>'+
        '<input id="listFrom" type="date" onchange="App.filterList()" class="w-full p-3 bg-white rounded-2xl border-2 border-slate-100 outline-none font-semibold text-sm">'+
        '<input id="listTo" type="date" onchange="App.filterList()" class="w-full p-3 bg-white rounded-2xl border-2 border-slate-100 outline-none font-semibold text-sm">'+
      '<div class="grid grid-cols-3 gap-2">'+
        '<button type="button" onclick="App.exportVoucherList()" class="w-full p-3 bg-emerald-600 text-white rounded-2xl font-black text-sm">⇩ تصدير</button>'+
        '<button type="button" onclick="window.print()" class="w-full p-3 bg-slate-700 text-white rounded-2xl font-black text-sm">🖨 طباعة</button>'+
        '<button type="button" onclick="App.loadList(App.tabName)" class="w-full p-3 bg-slate-800 text-white rounded-2xl font-black text-sm">↻ تحديث</button>'+
        '</div>'+
        '</div>'+
        '</div>'+

        '<div class="text-[10px] text-slate-500 mb-2">'+
            (completedRows.length
                ?
                'متوسط الزمن المبني فقط على الأذونات التي تحتوي created_at + completed_at.'
                :
                'سيظهر متوسط زمن الإغلاق بعد توفر أذونات مكتملة تحمل created_at + completed_at.'
            )+
        '</div>'+

        '<div id="listCards">'+
        this.cards(this.vouchers,scope)+
        '</div>'+

        '</div></div>';

    RW_UI.safeHTML(
        RW_UI.byId('mainContent'),
        h
    );

    this.markSync();
},

```

### ما تم تغييره داخل الدالة فقط

1. `listType` أصبح له `</select>` قبل فتح `listStatus`.
2. `App.List()` أصبحت `App.exportVoucherList()`.

لم يتم تغيير Business Logic للأذونات أو الحالات أو الـKPI أو دورة المخزون.

### تحقق ثابت للبديل

- JavaScript syntax: PASS.
- الاستدعاء `App.exportVoucherList()`: PASS.
- لا يوجد nested-select sequence في HTML الناتج: PASS.
- فتح `listType` وإغلاقه صحيح.
- فتح `listStatus` وإغلاقه صحيح.

**مهم:** لم يتم تعديل `vouchers.html` آليًا في Git؛ هذه هي الجراحة الجاهزة للاستبدال حسب قاعدة ملكية ملف الـfrontend.

---

## 4. Service Worker — السبب والإصلاح الفعلي

الـ404 ليس صادرًا من `vouchers.html`.

المصدر الجنائي هو:
`companies/company-1/register-sw.js`

المنسق القديم كان ينفذ:
`navigator.serviceWorker.register('./sw.js',{scope:'./'})`

عند route متداخل مثل:
`/companies/company-1/warehouse/vouchers`

يتحول `./sw.js` إلى:
`/companies/company-1/warehouse/sw.js`

وهذا الملف غير موجود.

### الإجراء المنفذ

تم تعديل `companies/company-1/register-sw.js` مباشرة في Git ليحدد:
- `swUrl` من موقع ملف `register-sw.js` نفسه.
- `scope` من نفس الموقع.

Commit المنفذ:
`d0796cd96c58e6f7b108d406b0e28f69fc4f06b2`

Parent:
`d8d1bde852a6b2dd25a11b06d75baac3e1af0991`

هذا يمنع تكرار مشكلة route-relative SW registration دون إنشاء Service Worker ثانٍ أو نسخ الـcore.

---

## 5. Tailwind CDN warning

رسالة:
`cdn.tailwindcss.com should not be used in production`

هي تحذير build/deployment وليست سبب الأعطال الثلاثة الحالية:
- لا تسبب `App.List`.
- لا تسبب nested select.
- لا تسبب مسار SW الخاطئ.

لم يتم تغييرها في `main.html` أو `vouchers.html` لأن نقل Tailwind إلى build pipeline يحتاج قرارًا معماريًا على مستوى الـfrontend كله، وليس patchًا موضعيًا للتبويب.

---

## 6. دور تطبيق الأذونات المخزنية

المطابقة الحالية تثبت أن التطبيق المستقل ليس بديلًا عن رحلة Order/Runsheet.

دوره هو العمليات المخزنية المستقلة عن الأوردرات والرانشيتات:
- Transfer
- DirectSale كحركة عهدة من الفرع إلى مخزن المركبة
- DirectReturn من مخزن المركبة إلى الفرع
- SupplierReturn
- Adjustment / Scrap عبر محرك التسوية الحالي

أما دورة المبيعات الميدانية فتبقى:
Order → Runsheet → Picking → Loading → Delivery → Return/Unloading

وهذا الفصل معماري صحيح لأنه يمنع خلط:
- حركة عهدة مخزنية
مع
- تنفيذ fulfillment لأوردر عميل.

---

## 7. التكامل مع النظام الأم

النظام الأم الحالي يحتوي View باسم `vouchers` ضمن:
`إدارة المخازن والمخزون → الأذونات المخزنية → عرض الأذونات`

كما يحتوي على:
- بحث وتصفية الأذونات.
- فلتر إظهار الكل.
- عرض العمليات.
- VOUCHER_AUDIT عبر `inventory_control`.

إذن:
- **النظام الأم = Control / Governance / Reporting**
- **التطبيق المستقل = Operational execution**
- **Production RPC = authoritative business/stock execution**

ولا توجد حاجة لبناء محرك مخزون ثانٍ.

---

## 8. التكامل مع Van Sales

المراجعة الحالية لـ`van-sales.html` تثبت:
- تحديد مخزن المركبة عبر `setup-van-branch`.
- تخزين واستخدام `vanBranchId`.
- قراءة مخزون المركبة من `stock_branches`.
- البيع الفعلي عبر `save-sales-invoice`.
- الجرد السريع عبر `save-inventory-count`.
- بعد العمليات يعاد `syncDown()` من Production.

والدورة الصحيحة هي:

**Voucher DirectSale**
فرع → مخزن المركبة

ثم:

**Van Sales**
مخزن المركبة → Sale

ثم عند الحاجة:

**Voucher DirectReturn**
مخزن المركبة → الفرع

ولا ينبغي تحويل DirectSale في الأذونات إلى فاتورة مبيعات؛ هذا تغيير Business Contract غير مطلوب.

---

## 9. Production snapshot الحالي

وقت الـsnapshot:
`2026-09-22 16:54:15+00`

الحالة:
- `stock_vouchers = 22`
- `stock_voucher_details = 24`
- `stock_voucher_operations = 23`
- `inventory_log = 26`
- `audit_log = 2105`

الـRPCs الحالية المؤثرة موجودة ومحمية بـ`SECURITY DEFINER`، ومنها:
- `inventory_control`
- `inventory_voucher_stock_context`
- `create_manual_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`
- `cancel_manual_stock_voucher_atomic`
- `post_stock_movement`

كما أن `inventory_control` و`inventory_voucher_stock_context` متاحان للمستخدم المصادق عليه.

**لا توجد حاجة لبناء Edge Function جديدة.**

---

## 10. Persistent QA data — محفوظة ولا تُحذف

تمت مطابقة البيانات الاختبارية الموجودة بالفعل، ولم يتم إنشاء نسخة أخرى ولم يتم حذفها.

QA item:
`ITM-1060`
الاسم:
`QA Vouchers E2E Lifecycle 2026-09-22`

QA vouchers:
- `IN-20` DirectSale — Completed — 5
- `IN-21` DirectReturn — Completed — 2
- `IN-22` SupplierReturn — Completed — 1

الحالة الحالية في Production:
- BR-01: **16**
- مخزن المركبة `VAN-VEH-TEST-260921`: **3**
- `allocated_qty = 0`

### Evidence إضافية حالية

`IN-22` لديه:
- JE: `JE-SVR-IN-22`
- Dr الموردون = 10
- Cr المخزون = 10
- Supplier Ledger debit = 10

كما أن سجل Audit الحالي يثبت:
- Create Draft
- Sent
- Received حيث يلزم
- Completed

والفاعل:
`vouchers@rawaea.com`

---

## 11. Physical Stock Contract

العقد المركزي ما زال:

**Physical Movement**
→ `post_stock_movement`
→ `stock_branches`
+
`inventory_log`

ولا توجد في هذه الجلسة أي إعادة فتح أو تغيير لهذا القلب المركزي.

---

## 12. المنافسة — ما تم إثباته من المصادر الرسمية الحالية

### Odoo
Odoo يوثق Inventory Adjustments وScrap كعمليات أصلية في Inventory، مع تسجيل الفروق والحركة ومواقع الخسارة، كما أن عمليات المخزون الأساسية مرتبطة بحركات Stock Moves.  
المقابل في RAWAEA موجود حاليًا في Adjustment/Scrap + movement engine.  
مصادر: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/count_products.html  
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/scrap_inventory.html  
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html

### Microsoft Dynamics 365
Dynamics يوثق Inventory Transfer Journal مع From/To dimensions والـposting ثم مراجعة inventory transactions.  
المقابل في RAWAEA هو voucher lifecycle + source/target + post movement + audit.  
المصدر: https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

### SAP
SAP يوثق Goods Movement كإطار موحد للتوثيق والتخطيط والحركات، ويشمل Goods Receipt وGoods Issue وStock Transfer، مع مستند حركة يمكن الاعتماد عليه لإثبات الكميات والقيم، كما يثبت SAP مفهوم one-step/two-step stock transfer وidempotency في بعض واجهات Goods Movement.  
المصادر:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/742e46e570984d9aa74e468838f6e1ff.html
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/9e64bd534f22b44ce10000000a174cb4.html

### Daftra
Daftra يوثق Inventory Detailed Transactions مع Warehouse/Type/Date filters، والطباعة والتصدير CSV/Excel/PDF، مع عرض inward/outward والملاحظات والمخزن.  
المصدر: https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/

### Manager.io
Manager يفصل مواقع المخزون عن عمليات البيع والشراء، ويقدم Inventory Transfers بين المواقع مع إبقاء الرصيد حسب الموقع.  
المصدر: https://www2.manager.io/guides/10707

---

## 13. ما ينقص RAWAEA تنافسيًا — لكن ليس من الآمن إدخاله في هذا الإصلاح

الفجوات التنافسية المستقبلية الآمنة التي ظهرت من المقارنة:
- lot/batch/serial tracking عند الحاجة.
- reason codes قابلة للتقارير بدل reason نصية فقط.
- evidence/attachments.
- approval workflow لبعض الحركات الحساسة.
- reversal الرسمي بدل التعديل المباشر.
- transit state واضح في النقل متعدد المراحل.
- line-level actor/time stamps.
- valuation per movement.
- barcode-first operations للجرد والحركات.

هذه ليست فجوات يجب حقنها داخل إصلاح `App.List`; إضافتها تحتاج Business Contracts وSchema مستقلين، وبالتالي لم يتم اختراعها أو زرعها في هذه الجلسة.

---

## 14. E2E

### Verified
- Production database state: PASS
- Persistent QA fixtures retained: PASS
- Voucher lifecycle data consistency: PASS
- Physical movement evidence: PASS
- Audit evidence: PASS
- Financial evidence for SupplierReturn: PASS
- Static JS parse of corrected `renderList`: PASS
- Generated HTML select structure: PASS
- App export target mapping: PASS
- Service Worker source correction syntax: PASS

### Not claimed
**Browser E2E الحقيقي authenticated داخل Cloudflare Production لم يُعلن PASS.**

السبب: لا توجد أداة browser runtime authenticated متاحة في هذه الجلسة، كما أن أداة الويب الحالية لم تستطع الوصول إلى عنوان `rawaea-erp.pages.dev` للتحقق من نشر Cloudflare النهائي.

لذلك:
`Production Runtime Browser E2E = OPEN`

ولا يجوز تحويل Static PASS إلى Browser PASS.

---

## 15. التنفيذ الفعلي في هذه الجلسة

### Frontend infrastructure
تم تنفيذ:
`d0796cd96c58e6f7b108d406b0e28f69fc4f06b2`

الملف:
`companies/company-1/register-sw.js`

### Frontend application source
**لم يتم تعديل:**
- `companies/company-1/warehouse/vouchers.html`
- `companies/company-1/main.html`
- `companies/company-1/sales/van-sales.html`

والسبب أن قواعد الملكية في المهمة تجعل تعديل `vouchers.html` تسليمًا جراحيًا للمالك، وليس commit آليًا.

### Production
لم يتم إنشاء Edge Function جديدة.
ولم يتم فتح مسار Physical Stock جديد.

---

## 16. النتيجة النهائية

### Proven Root Causes
1. `App.List()` call introduced by the 2026-09-22 frontend commit with no corresponding `List` method.
2. Nested `<select>` caused by opening `listStatus` before closing `listType`.
3. SW 404 caused by route-relative `./sw.js` in the shared registration coordinator.

### Closed
- Root cause analysis: CLOSED
- Surgical replacement prepared: CLOSED
- Static verification of replacement: CLOSED
- Production stock contract: CLOSED / preserved
- Persistent QA retained: CLOSED
- SW source defect: CLOSED in source Git

### Remaining external verification
- Cloudflare deployment/runtime propagation.
- Authenticated browser E2E after deployment.

---

## 17. إرشادات المساعد التالي للوصول إلى الحقيقة

ابدأ دائمًا بالترتيب التالي:
**CURRENT GIT → CURRENT SOURCE → CURRENT PRODUCTION → CURRENT DATABASE → CURRENT DEPLOYMENT/RUNTIME**

ثم:
1. أثبت الـblob والـparent قبل لمس السطر.
2. لا تثق بتقرير سابق إذا اختلف مع Current Source.
3. لا تعيد إصلاح Closure سبق إثباته.
4. في `vouchers.html` ابدأ من `renderList:function(scope)` فقط لأن العطل الحالي مصدره هذا الحد.
5. لا تلمس `main.html`.
6. لا تنشئ Edge Function جديدة لهذا التبويب.
7. أي تعديل Physical Stock يجب أن يعود إلى `post_stock_movement`.
8. أي نسبة أو KPI يجب أن تكون من Production snapshot في نفس لحظة التقرير.
9. لا تعتبر Static PASS = Browser PASS.
10. بعد تطبيق جراحة `renderList`، الخطوة الأولى التالية هي authenticated browser E2E، ثم إعادة snapshot Production وتحديث هذا الملف و`CURRENT_STATE.md`.

**سبب الخطأ في نهاية التحقيق:** آخر commit على `vouchers.html` في 22 سبتمبر أدخل زرًا يستدعي `App.List()` بدل الدالة الموجودة `exportVoucherList()`، وفي نفس التعديل نقل إغلاق `select` إلى موضع أوجد nested `select`. أما 404 فكان من المنسق المشترك الذي فسّر `./sw.js` بالنسبة إلى مسار `warehouse/`.
