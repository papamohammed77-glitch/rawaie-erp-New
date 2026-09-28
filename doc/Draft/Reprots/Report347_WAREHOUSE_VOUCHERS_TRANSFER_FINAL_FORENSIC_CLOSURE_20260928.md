# تقرير 347 — إغلاق جنائي حالي لدورة تحويل إذن مخزني بين الفروع
## التاريخ
2026-09-28

## 1. نقطة البداية المعتمدة
تم الاستئناف من أحدث حالة مثبتة، والتقارير السابقة استُخدمت للتاريخ والنية فقط، لا كحالة حالية.

ترتيب التحقق:
1. CURRENT PRODUCTION
2. CURRENT DATABASE
3. CURRENT GIT
4. CURRENT SOURCE
5. CURRENT DEPLOYMENT EVIDENCE
6. التقارير السابقة للاستدلال التاريخي.

تمت مراجعة MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS، CURRENT_STATE.md، Report345، Report346، أحدث commits وparent، vouchers.html، picker.html، van-sales.html، وMother main.html blob الحالي، ثم Production/RPC/Trigger.

## 2. الحالة الحالية المثبتة

### System Git
HEAD قبل إنشاء هذا التقرير:
eba0d43b88e258f31fc99627f62ff93fdf0196dd

Parent:
b96654e4f31f69a8372433d18546e134863a7dd8

الـHEAD الأخير كان checkpoint للحالة ولم يغيّر منطق Transfer.

### Frontend Git
HEAD:
f07bdcc4abbbe899af569f8bfaccde04df279416

Parent:
cc35f3a9da6ababf4c8cd87b05ab93539cdae087

التغيير الأخير محصور في vouchers.html، وكان T-05 لحقن topActions داخل details() وإغلاق زر X أثناء استلام التحويل.

### vouchers.html
SHA:
9e3a9cbd0124639934cdf98abc9ec579f4b19f61

عدد الأسطر:
6074

فحص JavaScript syntax:
PASS

لم يتم تعديل الملف في هذه الجلسة.

### Mother main.html
Blob:
810e4f5440f5975f55099a124deb42b086a49183

يوجد به:
- إدارة المخازن والمخزون
- الأذونات المخزنية
- تحويل مخزني
- allowed_branch_ids
- default_branch_id
- active_warehouse_role

لم يتم تعديل main.html.

### Picker
SHA:
c7ad267d852d415b680aed7716833eea9bcffdf6

925 سطر.

المصدر الحالي يثبت التعامل مع qty_picked، النقص، والكمية الفعلية الجزئية.

### Van Sales
SHA:
8d61382a8e0025a0d079e71dd94f33d106d9088e

2297 سطر.

المسار الحالي:
setup-van-branch
ثم
save-sales-invoice

لا توجد فجوة Transfer مثبتة تستوجب تعديله.

## 3. العقد التشغيلي المحفوظ

Draft
→ لا حركة مخزنية
→ Send
→ خصم مخزون الفرع المصدر
→ Sent
→ Receive جزئي أو كلي
→ received_qty
→ عند اكتمال كل البنود: Received
→ Complete.

هذا العقد محفوظ بالكامل في Production.

## 4. التدفق المعماري

Mother:
- يضبط المستخدم.
- يضبط active_warehouse_role.
- يضبط default_branch_id.
- يضبط allowed_branch_ids.
- يملك السلطة العليا على تعيينات التشغيل.

Standalone vouchers app:
- ينفذ العمليات الميدانية.
- لا ينشئ مصدر صلاحيات مستقل.
- يعرض العمليات حسب actor responsibility.

Production:
- RPCs تنفذ الحركة الذرية.
- Trigger يثبت مسؤول الاستلام.
- inventory_log يثبت الأثر.
- stock_voucher_details.received_qty يحمل الاستلام الفعلي.

## 5. النتيجة الجنائية لمسؤولية Transfer

عند Draft → Sent:
- الحركة Branch → Branch.
- منشئ الإذن هو Sender.
- يبحث Production عن مسؤول واحد فقط في فرع الوجهة:
  - نفس الشركة.
  - role = مخزني.
  - active_warehouse_role = أذونات.
  - default_branch_id = الوجهة.
  - ليس Sender.
  - يسمح له النطاق بالوجهة.
- صفر = رفض.
- أكثر من واحد = رفض.
- واحد = snapshot في receiver_user_id وreceiver_assigned_at.

بعد Sent:
- Receiver immutable.
- Receive متاح لهذا الـreceiver فقط.
- Sender لا يستطيع Receive.

## 6. ملاحظة تاريخية حاسمة عن نطاق الفروع

Migration history يثبت أن السماح لدور أذونات بتنفيذ تحويلات فروع الشركة كان مقصودًا في السابق، ومن أمثلته:

20260923062835_allow_vouchers_role_all_company_branch_transfers
20260923063006_allow_vouchers_role_receive_transfer_all_company_branches

لذلك لم يتم عكس هذا السلوك أو تضييقه تخمينيًا.

الحماية ليست في تقييد قائمة المصدر للمرسل؛ الحماية الفعلية هي actor binding + receiver snapshot + DB enforcement.

## 7. Production hardening تم تنفيذه الآن

تم اكتشاف أن:

public.enforce_transfer_responsibility_contract()

كانت SECURITY DEFINER وقابلة لـEXECUTE من anon وauthenticated وPUBLIC.

وهي Trigger Function وليست API عامة.

تم تنفيذ:

20260928095000_harden_transfer_responsibility_trigger_execute_surface

ثم:

20260928095500_close_transfer_responsibility_trigger_acl

الحالة النهائية:
- anon EXECUTE = false
- authenticated EXECUTE = false
- PUBLIC EXECUTE = false
- service_role EXECUTE = true
- Trigger ما زال يعمل.

لم يتم إنشاء Edge Function.

## 8. Edge Functions

عدد Edge Functions الحالي:
100

الوظائف المتعلقة بالهدف:
- create-stock-voucher v12
- send-stock-voucher v20
- receive-stock-voucher v22
- complete-stock-voucher v4

لم يتم إنشاء أي Function جديدة، ولم تتم إعادة بناء backend.

## 9. Production E2E بعد الـHardening

تم تنفيذ سيناريو Transfer داخل Transaction ثم إجباره على ROLLBACK.

السيناريو:
BR-01 → BR-2
item 1001
qty 2
Sender = vouchers@rawaea.com
Receiver = vouchers3@rawaea.com

النتيجة:
- Create PASS
- Send PASS
- status = Sent
- source stock 8 → 6
- receiver snapshot مطابق لمسؤول BR-2
- محاولة تغيير receiver بعد التثبيت مرفوضة:
  مسؤول الاستلام لا يمكن تغييره بعد تثبيته
- محاولة Sender تنفيذ Receive مرفوضة:
  لا يملك هذا المستخدم مسؤولية استلام تحويل الفرع
- Partial Receive qty 1 PASS
- destination 3 → 4
- Full remaining Receive qty 1 PASS
- destination 4 → 5
- status = Received

جميع بيانات الاختبار تم Rollback لها.

بعد التحقق:
- QA transfer residue = 0
- QA operations = 0
- QA inventory-log QA rows = 0
- source = 8
- destination = 3

## 10. لماذا لا يوجد Backend Patch جديد

العقد المطلوب موجود بالفعل:
- Sender identity
- Receiver identity
- creator-only Draft mutation
- receiver-only Receive
- self-send/self-receive prevention
- partial receipt
- full receipt
- idempotency
- stock movement
- Received transition
- completion
- audit evidence

إعادة بناء أي RPC أو Edge Function ستكون تكرارًا وخطرًا.

## 11. T-06 — العيب الحالي المحدد في UI

الملف:
companies/company-1/warehouse/vouchers.html

الدالة:
cards:function(rows,scope)

الموضع التقريبي:
905–924

ابحث عن العنصر الكامل التالي واحذفه:

    if(act==='draft'){
        a+=
            '<button onclick="event.stopPropagation();App.editVoucher(\''+
            s.esc(v.voucher_code)+
            '\')" class="bg-amber-500 text-white px-3 py-2 rounded-xl text-xs font-black">تعديل</button>';

        a+=
            '<button onclick="event.stopPropagation();App.deleteVoucher(\''+
            s.esc(v.voucher_code)+
            '\')" class="bg-rose-600 text-white px-3 py-2 rounded-xl text-xs font-black">حذف</button>';

        a+=
            '<button onclick="event.stopPropagation();App.send(\''+
            s.esc(v.voucher_code)+
            '\')" class="bg-indigo-600 text-white px-3 py-2 rounded-xl text-xs font-black">إرسال</button>';
    }

واستبدله بالكامل بـ:

    if(act==='draft'){
        a+=
            '<button onclick="event.stopPropagation();App.editVoucher(\''+
            s.esc(v.voucher_code)+
            '\')" class="bg-amber-500 text-white px-3 py-2 rounded-xl text-xs font-black">تعديل</button>';

        a+=
            '<button onclick="event.stopPropagation();App.deleteVoucher(\''+
            s.esc(v.voucher_code)+
            '\')" class="bg-rose-600 text-white px-3 py-2 rounded-xl text-xs font-black">حذف</button>';

        a+=
            '<button onclick="event.stopPropagation();App.send(\''+
            s.esc(v.voucher_code)+
            '\')" class="bg-indigo-600 text-white px-3 py-2 rounded-xl text-xs font-black">إرسال</button>';

        a+=
            '<button onclick="event.stopPropagation();App.printDraftVoucher(\''+
            s.esc(v.voucher_code)+
            '\')" class="bg-slate-700 text-white px-3 py-2 rounded-xl text-xs font-black">طباعة</button>';
    }

سبب التعديل:
Print function موجودة بالفعل؛ العيب هو عدم وجود زرها في بطاقة Draft.

## 12. T-07 — اسم خروج مسؤول الاستلام

الملف:
companies/company-1/warehouse/vouchers.html

الدالة:
details:function(code)

ابحث عن الكائن الكامل:

    var topActions=
        transferReceiver
            ?
            '<div class="flex flex-wrap justify-end gap-2 mb-3 no-print">'+
            '<button type="button" onclick="App.receive(\''+
            s.esc(v.voucher_code)+
            '\',true)" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">استلام كلي</button>'+
            '<button type="button" onclick="App.receive(\''+
            s.esc(v.voucher_code)+
            '\',false)" class="px-3 py-2 rounded-xl bg-teal-600 text-white text-xs font-black">استلام تفصيلي</button>'+
            '<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
            '<button type="button" onclick="App.exitVoucherDetails()" class="px-3 py-2 rounded-xl bg-slate-500 text-white text-xs font-black">خروج</button>'+
            '</div>'
            :
            '<div class="flex flex-wrap justify-end gap-2 mb-3 no-print">'+
            '<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
            '<button type="button" onclick="App.exportVoucher()" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">⇩ تصدير CSV</button>'+
            '</div>';

احذفه بالكامل واستبدله بـ:

    var topActions=
        transferReceiver
            ?
            '<div class="flex flex-wrap justify-end gap-2 mb-3 no-print">'+
            '<button type="button" onclick="App.receive(\''+
            s.esc(v.voucher_code)+
            '\',true)" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">استلام كلي</button>'+
            '<button type="button" onclick="App.receive(\''+
            s.esc(v.voucher_code)+
            '\',false)" class="px-3 py-2 rounded-xl bg-teal-600 text-white text-xs font-black">استلام تفصيلي</button>'+
            '<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
            '<button type="button" onclick="App.exitVoucherDetails()" class="px-3 py-2 rounded-xl bg-slate-500 text-white text-xs font-black">خروج بدون حفظ</button>'+
            '</div>'
            :
            '<div class="flex flex-wrap justify-end gap-2 mb-3 no-print">'+
            '<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
            '<button type="button" onclick="App.exportVoucher()" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">⇩ تصدير CSV</button>'+
            '</div>';

لا تعدل exitVoucherDetails().

## 13. T-08 — تسمية حفظ الاستلام التفصيلي

الملف:
companies/company-1/warehouse/vouchers.html

الدالة:
receive:function(code,full)

الموضع التقريبي:
2300–2340

ابحث عن العنصر الكامل التالي:

    return Swal.fire({
        html:h,
        showCancelButton:true,
        confirmButtonText:'تنفيذ الاستلام',
        cancelButtonText:'إلغاء',
        preConfirm:function(){

            var out=[];

            d.forEach(function(x,i){

                var el=
                    RW_UI.byId(
                        'rq'+i
                    );

                if(!el){
                    return;
                }

                var q=
                    Number(el.value||0);

                var m=
                    Number(el.max||0);

                if(q<0||q>m){
                    throw new Error(
                        'كمية غير صالحة'
                    );
                }

                if(q){
                    out.push({
                        itemId:x.item_id,
                        itemCode:x.item_code,
                        receivedQty:q
                    });
                }

            });

            if(!out.length){

                Swal.showValidationMessage(
                    'أدخل كمية استلام'
                );

                return false;
            }

            return out;
        }
    });

واستبدله بالكامل بـ:

    return Swal.fire({
        html:h,
        showCancelButton:true,
        confirmButtonText:'حفظ الكميات المستلمة',
        cancelButtonText:'إلغاء',
        preConfirm:function(){

            var out=[];

            d.forEach(function(x,i){

                var el=
                    RW_UI.byId(
                        'rq'+i
                    );

                if(!el){
                    return;
                }

                var q=
                    Number(el.value||0);

                var m=
                    Number(el.max||0);

                if(q<0||q>m){
                    throw new Error(
                        'كمية غير صالحة'
                    );
                }

                if(q){
                    out.push({
                        itemId:x.item_id,
                        itemCode:x.item_code,
                        receivedQty:q
                    });
                }

            });

            if(!out.length){

                Swal.showValidationMessage(
                    'أدخل كمية استلام'
                );

                return false;
            }

            return out;
        }
    });

لا تغيّر منطق الكميات أو operation_id.

## 14. ما لا يحتاج تعديلًا

Draft:
- Edit موجود.
- Delete موجود.
- Send موجود.
- Details موجود.
- Draft print function موجود.

Receiver:
- فتح تفاصيل التحويل موجود.
- استلام كلي موجود.
- استلام تفصيلي موجود.
- طباعة موجودة.
- الخروج بدون حفظ موجود وظيفيًا.
- X مغلق أثناء الاستلام.

Security:
- DB trigger موجود.
- receiver snapshot موجود.
- immutable receiver موجود.
- sender/receiver separation موجود.

لا تعيد أي جزء أعلاه.

## 15. مقارنة وظيفية تنافسية

Odoo:
Internal Transfers، وحركة داخلية بين المواقع، ويمكن وجود Transit Location للحالة بين المخازن.

Dynamics 365:
Transfer Order Receiving يدعم فصل التسجيل عن الاستلام والاستلام الجزئي.

SAP:
Two-step Stock Transfer مع Goods Issue وGoods Receipt والحالة قيد النقل.

Manager.io:
Inventory Transfers بين المواقع مع تعديل الكميات في المصدر والوجهة.

Daftra:
Manual stock transfer يعتمد على From/To والأصناف والكميات ويعرض أثر المخزون حسب الموقع.

روائع يحافظ على هذه القدرات ويضيف actor-bound receiving، فصل المسؤوليات، idempotency، وتشغيلًا ميدانيًا منفصلًا تحت سيطرة Mother.

مصادر خارجية:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-transfer-order-receiving-process
https://help.sap.com/docs/SAP_ERP/75c4b203fca64320b998cc04e2eb1468/719bc7536e8e2a4be10000000a174cb4.html
https://www2.manager.io/guides/10707
https://docs.daftra.com/en/tutorial/transferring-stock/

## 16. فجوات مستقبلية حقيقية لم تُفتح

- Transport lead time / ETA / SLA
- ASN / container / license plate
- barcode scanning عند الاستلام
- discrepancy approval workflow
- reason-code catalog
- attachments / photos / proof of receipt
- custody handoff
- aging alerts
- transfer control dashboard.

هذه ليست عيوبًا مثبتة في عقد Transfer الحالي، لذلك لم تُنفذ في هذه الجلسة.

## 17. Deployment Evidence

Current Source:
PROVEN

Current Production DB/RPC/Trigger:
PROVEN

Authenticated live Browser E2E:
OPEN

لا توجد جلسة Browser مصادق عليها في الأدوات الحالية تسمح بإثبات آخر متر من الواجهة المنشورة بحسابي Sender وReceiver. لذلك لا يعلن إغلاق Browser النهائي.

## 18. Self Audit

- لم يتم تعديل main.html.
- لم يتم تعديل vouchers.html.
- لم يتم إنشاء Edge Function.
- لم يتم إعادة بناء Transfer backend.
- لم يتم عكس historical all-company scope.
- تم اختبار self-receive prevention.
- تم اختبار receiver immutability.
- تم اختبار partial/full receipt.
- تم اختبار stock conservation.
- تم Rollback لبيانات QA.
- تم إغلاق EXECUTE surface لدالة Transfer Trigger.
- تم تجهيز Owner patches دقيقة.

## 19. مستوى الإغلاق

PRODUCTION / DATABASE = CLOSED

BUSINESS CONTRACT = CLOSED

SECURITY CONTRACT = CLOSED

SOURCE UI = T-06 / T-07 / T-08 READY FOR OWNER MERGE

BROWSER E2E = OPEN

## 20. نقطة الاستكمال للجلسة القادمة

لا تبدأ من الصفر.

1. تحقق من System HEAD وparent.
2. تحقق من Frontend HEAD وparent.
3. تحقق من vouchers.html SHA.
4. تحقق من أن T-06/T-07/T-08 لم تُدمج بعد.
5. لا تعيد Production Transfer migrations.
6. لا تنشئ Edge Function.
7. لا تلمس main.html.
8. لا تلمس DirectSale أو DirectReturn أو SupplierReturn أو Runsheet.
9. بعد Owner merge نفّذ Authenticated Browser E2E بمرسل BR-01 ومستقبل BR-2.
10. عند نجاح Browser E2E أغلق Transfer نهائيًا.
11. بعدها انتقل لأول Business Contract Gap جديدة.

## 21. إرشاد الحقيقة للمساعد القادم

CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT EVIDENCE
→ BUSINESS CONTRACT
→ SURGICAL REPAIR
→ PRODUCTION VERIFY
→ SOURCE VERIFY
→ BROWSER VERIFY
→ CURRENT_STATE UPDATE

القواعد:
لا تصلح ما ثبت أنه صالح.
لا تعتبر التقرير حالة حالية.
لا تعتبر وجود الدالة إغلاقًا.
لا تعتبر نجاح RPC وحده إغلاقًا للواجهة.
لا تعتبر إخفاء الزر حماية أمنية.
لا تعيد بناء ما هو Production-closed.

# END REPORT 347
