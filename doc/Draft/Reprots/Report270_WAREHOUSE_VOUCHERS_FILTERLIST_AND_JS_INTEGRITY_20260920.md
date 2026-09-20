
# Report270 — الإكمال الجنائي لتطبيق الأذونات المخزنية
## 2026-09-20

## 1. نطاق الدورة
الملف التنفيذي الوحيد:
~~~text
papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/vouchers.html
~~~

لم يتم تعديل:
~~~text
erp-frontend/companies/company-1/main.html
~~~

Production Supabase فُحصت مباشرة. لم يتم إنشاء Edge Function جديدة، ولم تُجرَ أي جراحة Production إضافية في هذه الدورة لأن الـbackend الحالي ثبتت مطابقته للعقد المطلوب.

## 2. المصادر التي تم التحقق منها
- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — قراءة كاملة حتى EOF: 2606 سطر.
- Report269 — قراءة كاملة حتى EOF: 1428 سطر.
- CURRENT_STATE.md — الحالة السابقة أعيدت مطابقتها مع Git/Production/Source.
- Mother current main.html — blob: 453565c39a50fdcf73eb03a97a1fc7d7ac10bb2f.
- Standalone current vouchers.html — SHA: 74a1c28fa6c073abcc6d72e53b5841968b31b4d0.

## 3. Git والـparent
### System repository
~~~text
HEAD   = 488f9d70fcd447ded3c6bcbfad0e58b9e3c0c0a9
PARENT = bc2fce96ef0b4a9d105cd300874cb7e08960aea5
~~~

### Standalone frontend
أحدث commit يمس vouchers.html:
~~~text
d1aaac986f9f729ec47baf56a943dc90477950ef
PARENT = ca15cdaf11fa3aeea0c6fc082df6a18ed0661ab7
~~~

الـparent ca15 كان مجرد rename ولم يغير blob.
الـcommit d1 هو نقطة التغيير الفعلية التي أدخلت الانحراف الحالي.

## 4. ROOT CAUSE — لماذا لم نجد filterList؟
Current vouchers.html يحتوي أربعة مستهلكين مباشرين لـ:
~~~text
App.filterList()
~~~

في:
- listSearch
- listType
- listFrom
- listTo

لكن عدد تعريفات:
~~~text
filterList:function(...) = 0
~~~

مقارنة parent المباشر أثبتت أن d1 حذف الدالة القديمة:
~~~text
-filterList:function(){...}
~~~

ثم أضاف واجهة جديدة تستدعي App.filterList() دون إعادة إضافة method.

إذن:
~~~text
UI CALLERS EXIST
+
METHOD MISSING
=
RUNTIME BREAK
~~~

القول السابق "لم يمكن العثور على الدالة" كان صحيحًا كحالة بحث، لكن العلاج الصحيح هو INSERT وليس REPLACE.

## 5. ROOT CAUSE SECONDARY — تلف JavaScript
Current vouchers.html يحتوي 26 occurrence من escaping زائد:
~~~text
\\'
~~~

كلها داخل:
1. cards — line 89 — 10
2. pickShow — line 372 — 4
3. routeHtml — line 374 — 4
4. renderProducts — line 377 — 4
5. search — line 380 — 2
6. itemDetails — line 381 — 2

النسخ السابقة المستقرة في أغسطس كانت تستخدم:
~~~text
\'
~~~

والـCurrent الحالي أُدخل فيه backslash إضافي.

نتيجة parser للـinline JavaScript الحالي:
~~~text
FAIL — Unexpected string
~~~

وهذا يجعل إضافة filterList وحدها غير كافية.

## 6. الإثبات الجراحي
تم إنشاء نسخة مؤقتة فقط دون تعديل Git، وتم تنفيذ:
~~~text
1. تطبيع 26 occurrence من \\' إلى \'
2. إضافة filterList في موضعه الصحيح
~~~

النتيجة:
~~~text
FULL INLINE JAVASCRIPT PARSE = PASS
filterList definitions       = 1
remaining over-escaped       = 0
~~~

كما تم اختبار منطق التصفية:
~~~text
Text filter       = PASS
Type filter       = PASS
Date range        = PASS
Invalid date range guard = PASS
~~~

ولا توجد كتابة Production في الاختبار.

## 7. الدور الوظيفي المثبت للتطبيق
التطبيق المستقل هو Consumer تشغيلي للعمليات المخزنية غير المرتبطة مباشرة بدورة Order/Runsheet:
~~~text
Transfer
DirectSale
DirectReturn
SupplierReturn
~~~

ولا يعيد بناء:
~~~text
Picking
Loading
Delivery
Runsheet Return
Unloading
~~~

أما Scrap وAdjustment فهما مرتبطان حاليًا بـ bulk-stock-adjustment كـAdjustment Engine مستقل، ولم يثبت عقد يحولهما إلى Voucher Documents.

## 8. التكامل مع النظام الأم
Mother الحالي تحت:
~~~text
إدارة المخازن والمخزون
→ الأذونات المخزنية
→ تحويل مخزني
→ صرف سيارة بيع مباشر
→ استلام مرتجع سيارة
→ مرتجع لمورد
→ عرض الأذونات
~~~

كما أن route الخاص بـvouchers داخل Mother يمر إلى RW_Warehouse.loadVouchers().

الاستنتاج:
~~~text
Mother = Control / Navigation / Unified Visibility
Standalone vouchers = Operational Consumer
Production Core = Transaction Source of Truth
~~~

لا يوجد سبب لتعديل Mother في هذه الجراحة.

## 9. تدفق البيانات
المسار المثبت:
~~~text
Authenticated user
→ users.auth_id
→ users.company_id
→ vouchers.html
→ existing capability Edge
→ canonical manual-voucher RPC
→ stock_vouchers + stock_voucher_details
→ SEND / RECEIVE / COMPLETE / CANCEL
→ post_stock_movement
→ stock_branches + inventory_log
~~~

والرقابة:
~~~text
inventory_control('VOUCHER_AUDIT')
→ voucher
→ details
→ audit
→ movements
~~~

Static source scan أثبت عدم وجود direct writes من vouchers.html إلى:
~~~text
stock_branches
inventory_log
~~~

## 10. Production current truth
وقت الفحص:
~~~text
2026-09-20T14:55:33.633925+00
~~~

العدادات:
~~~text
companies               = 1
branches                = 2
items                   = 17
stock_vouchers          = 0
stock_voucher_details   = 0
stock_voucher_operations= 0
inventory_log           = 3
~~~

الـ3 inventory_log الحالية هي سجلات تاريخية VoidInvoice وليست test residue.

Production RPC signatures المثبتة:
~~~text
create_manual_stock_voucher_atomic 10-arg legacy
create_manual_stock_voucher_atomic 12-arg canonical
post_manual_stock_voucher_atomic
send_stock_voucher_atomic
complete_manual_stock_voucher_atomic
cancel_manual_stock_voucher_atomic
inventory_control
~~~

والـEdge capabilities الحالية ذات العلاقة:
~~~text
create-stock-voucher  = v10
send-stock-voucher    = v20
receive-stock-voucher = v22
complete-stock-voucher= v4
cancel-stock-voucher  = v4
~~~

لم يتم إنشاء Function جديدة.

## 11. الحفاظ على المركزية
العقد الفيزيائي ما زال:
~~~text
PHYSICAL MOVEMENT
→ post_stock_movement
→ stock_branches + inventory_log
~~~

ولا توجد جراحة جديدة مطلوبة في Inventory Core لهذه المشكلة.

## 12. المنافسة
الدراسة الرسمية الحالية تثبت أن المنتجات المنافسة تفصل بين العمليات والحركات والتسويات وتوفر مستوى مرتفعًا من التتبع والبحث:

### Odoo 19
يوثق receipts, deliveries, customer returns, vendor returns, scrap, inventory adjustments, barcode operations وinternal transfers.
Odoo Barcode يتيح كذلك إسناد عمليات الجرد وتنفيذها ميدانيًا.

### Dynamics 365
Inventory Journals تشمل Movement, Inventory adjustment, Transfer, Item arrival, Counting, Tag counting.
وتُفرق Dynamics بين النقل الفوري وبين transfer order عند الحاجة إلى تتبع in-transit.

### SAP S/4HANA
Goods Movement يغطي goods receipt, goods issue, stock transfer, transfer posting مع recording/reporting للحركات.

### Daftra / دفترة
التحويل المخزني يعرض التاريخ، من/إلى، الملاحظات، المنتج، السعر، الكمية، Available Before وAvailable After.

### Manager.io
يفصل Inventory Transfers عن Inventory Write-offs، ويدعم References/Description وInventory locations وDelivery Notes وGoods Receipts.

المصادر الرسمية المستخدمة:
- Odoo 19 Documentation — Inventory Operations / Barcode / Scrap.
- Microsoft Learn — Inventory journals.
- SAP Help — Goods Movement.
- Daftra Knowledge Base — Transferring Items / Transferring Stock.
- Manager.io Guides — Inventory Transfers / Write-offs / Delivery Notes.

## 13. الجراحة المطلوبة من المالك

### الملف
~~~text
papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/vouchers.html
~~~

### A — إصلاح escaping
في الدوال الست التالية فقط:
~~~text
cards:function(rows,scope){       line 89
pickShow:function(key){           line 372
routeHtml:function(){             line 374
renderProducts:function(){        line 377
search:function(q){               line 380
itemDetails:function(id){         line 381
~~~

استبدل جميع المطابقات الحرفية الحالية:
~~~text
\\'
~~~

بالتالي:
~~~text
\'
~~~

العدد المثبت حاليًا = 26 occurrence.

لا تغيّر أي نص آخر في هذه الجراحة.

### B — إضافة filterList
لا تحذف دالة؛ فهي غير موجودة.

ابحث عن هذا التسلسل الحرفي، عند lines 87–89:
~~~js
this.markSync();
},
cards:function(rows,scope){
~~~

أدخل method الجديدة بين line 88 وline 89:

~~~js
filterList:function(){
    var s=this;

    var q=s.norm(
        (RW_UI.byId('listSearch')||{}).value||''
    );

    var type=
        (RW_UI.byId('listType')||{}).value||'';

    var from=
        (RW_UI.byId('listFrom')||{}).value||'';

    var to=
        (RW_UI.byId('listTo')||{}).value||'';

    if(from && to && from>to){
        RW_UI.toast('الفترة الزمنية غير صحيحة','warning');
        return;
    }

    var rows=this.vouchers.filter(function(v){

        var textMatch=
            !q||
            s.norm(v.voucher_code).includes(q)||
            s.norm(v.reference).includes(q)||
            s.norm(v.type).includes(q);

        var typeMatch=
            !type||
            v.type===type;

        var date=
            String(v.voucher_date||'').slice(0,10);

        var fromMatch=
            !from||
            date>=from;

        var toMatch=
            !to||
            date<=to;

        return(
            textMatch &&
            typeMatch &&
            fromMatch &&
            toMatch
        );
    });

    RW_UI.safeText(
        RW_UI.byId('listCount'),
        String(rows.length)
    );

    var box=RW_UI.byId('listCards');

    if(!box){
        return;
    }

    RW_UI.safeHTML(
        box,
        this.cards(rows,this.tabName)
    );
},
~~~

## 14. لماذا هذه الجراحة فقط؟
لأن التحقيق الحالي لم يثبت وجود حاجة جديدة لإعادة بناء:
- loadList
- receive
- prepare
- handleScan
- stock availability
- barcode
- DirectSale validation
- DirectReturn validation
- SupplierReturn validation
- Scrap / Adjustment engine
- realtime subscription
- Inventory Core
- receive idempotency
- VOUCHER_AUDIT
- Mother

إعادة تعديل تلك الأجزاء الآن ستكون إعادة إصلاح لشيء مثبت.

## 15. Production actions in this cycle
~~~text
Additional Production DDL required = NO
New Edge Function                    = NO
RLS relaxation                       = NO
Data deletion                        = NO
Inventory Core rewrite               = NO
~~~

سبب عدم تعديل Production:
الـbackend الحالي canonical ومتوافق مع العقد المستهدف لهذه الجراحة، بينما الخلل الحالي في Consumer source.

## 16. Browser E2E
لم يُعتبر Browser E2E Passed لأن الملف لم يُعدل من المنفذ.

الـgate التالي بعد تطبيق الجراحة:
~~~text
Login
→ open permissions app
→ filter pending/completed
→ CREATE Transfer
→ simulate response loss
→ verify one voucher
→ SEND
→ partial RECEIVE
→ retry same operation
→ verify no extra movement
→ remainder RECEIVE
→ COMPLETE
→ details
→ movements
→ audit
→ filters
→ realtime refresh
~~~

## 17. Open Business Contracts
لا تُفتح في هذه الجراحة:
~~~text
historical before/after movement balances
bulk paste/import
approval workflow
attachments
lot/serial/expiry
richer in-transit lifecycle
formal print/export contract
~~~

هذه Business Contracts مستقلة وليست defects مثبتة في هذه الدورة.

## 18. Self-Audit
### What was proved
- Current source SHA verified.
- System HEAD + parent verified.
- Mother current blob verified.
- Parent history proved filterList existed قبل d1.
- d1 proved حذف filterList أثناء تحديث الملف.
- Current source proved 26 over-escaped quote sequences.
- Current JS parser failed before surgery.
- Corrected temporary source passed parser.
- Filter logic passed direct tests.
- Production voucher core is present and aligned.
- No direct physical stock writes exist in vouchers.html.
- Mother was not modified.
- No additional Production change is required.

### What was not proved
- Browser E2E after owner applies the source patch.
- Real UI behavior in a browser session بعد التعديل.

### Final status
~~~text
CURRENT REALITY RECONSTRUCTED = PASS
ROOT CAUSE PROVEN            = PASS
SURGICAL OWNER PATCH         = READY
STATIC PATCH VALIDATION      = PASS
PRODUCTION CORE              = VERIFIED
MOTHER                       = UNTOUCHED
BROWSER E2E                  = OPEN
VOUCHER CONSUMER CLOSURE     = OPEN
~~~

## 19. Instruction for next session
لا تثق بهذا التقرير كحالة حالية.

ابدأ من:
~~~text
CURRENT GIT
+
CURRENT vouchers.html SHA
+
CURRENT Mother blob
+
CURRENT Production
+
CURRENT deployment
~~~

ثم تحقق:
1. filterList definitions = 1
2. over-escaped quote occurrences in the six target functions = 0
3. inline JS parser = PASS
4. no Mother modification
5. no Production core regression

ثم نفذ Browser E2E وأغلق Voucher Consumer فقط إذا نجحت كل بوابات الوظيفة والتكامل وProduction.

# END REPORT270
