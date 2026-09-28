# Report355 — RAWAEA ERP — التحقيق الجنائي النهائي لعيب أزرار مودال الأذونات المخزنية
**التاريخ:** 2026-09-28  
**النطاق:** companies/company-1/warehouse/vouchers.html  
**الحالة:** Production verified + source defect isolated + surgical owner patch prepared  
**المحمي:** main.html / van-sales.html / backend closed contracts  
**قاعدة التنفيذ:** لا إعادة إصلاح لما أُغلق، ولا ادعاء إغلاق Browser E2E دون دليل.

---

## 1. نقطة الاستئناف الحقيقية

التقارير السابقة استُخدمت كخريطة تاريخية فقط. تم إعادة بناء الحالة من Current Git + Current Source + Current Production + Current Database + Deployment Evidence.

### Current Git

**System / Mother**
- HEAD: 48dc3b35aae8df77bf4b8aaa05ec4cdf98f8bd99
- Parent: 2f2cd1453c2aa8a6ec8f087186b45e22cb7da2bb
- HEAD message: state: finalize Report354 checkpoint commit identity

**Frontend**
- HEAD: 85e825de61333f3b7da014580dd7275146818b2a
- Parent: 880abe25c42d7c82c79cf133b9880d09ebfc416f
- HEAD message: Update voucher code formatting in vouchers.html
- Current vouchers blob: befc3f428e29ea5cb896ac93d2aa05db57293c43
- 6,328 lines / 209,992 chars

الـcompare بين 880abe25 و85e يثبت أن آخر Commit عدّل vouchers.html فقط (+8/-5)، ولم يمس main.html.

### Current protected files

- main.html: blob 810e4f5440f5975f55099a124deb42b086a49183 — لا تعديل.
- van-sales.html: blob 8d61382a8e0025a0d079e71dd94f33d106d9088e — لا تعديل.

---

## 2. التصحيح التاريخي الذي يجب عدم تكراره

التعديل الأخير في Frontend HEAD أصلح بالفعل:

cards:function(rows,scope) حول السطر 1176.

الحالة الحالية هناك:

~~~
var codeJs=
    "'" +
    JSON.stringify(
        String(v.voucher_code||'')
    )
        .slice(1,-1)
        .replace(/'/g,"\\'") +
    "'";
~~~

إذن عيب cards انتهى.

لا تعيد:
- تعديل cards()
- تعديل RW_UI.esc()/esc()
- تعديل renderList()
- إعادة T13/T14/T15/T16
- إعادة إصلاح Transfer destination
- إعادة إصلاح receiver binding
- إعادة إصلاح DirectReturn Production
- إنشاء Edge Function جديدة

---

## 3. سبب Console الحالي — مثبت من المصدر

العيب المتبقي موجود في:

**الملف**
companies/company-1/warehouse/vouchers.html

**الدالة**
details:function(code)

**الموضع الحالي**
حوالي السطر 2047.

### العنصر المعيب حرفيًا

~~~
var codeJs=
    JSON.stringify(
        String(v.voucher_code||'')
    );
~~~

يوجد هذا النمط الحالي مرة واحدة، وهو نسخة ثانية مستقلة عن النسخة التي تم إصلاحها داخل cards().

---

## 4. آلية الفشل

details() يبني topActions داخل SweetAlert.

من المصدر الحالي توجد أزرار مثل:

~~~
onclick="App.editVoucher('+codeJs+')"
onclick="App.deleteVoucher('+codeJs+')"
onclick="App.send('+codeJs+')"
onclick="App.printDraftVoucher('+codeJs+')"
onclick="App.receive('+codeJs+',true)"
onclick="App.receive('+codeJs+',false)"
onclick="App.complete('+codeJs+')"
~~~

عندما تكون قيمة الإذن:

IN-6

فإن JSON.stringify() ينتج:

~~~
"IN-6"
~~~

ويصبح الـHTML الفعلي منطقياً:

~~~
onclick="App.editVoucher("IN-6")"
~~~

يُغلق HTML attribute عند الاقتباس الداخلي.

لذلك يصل JavaScript event-handler parser إلى شيء من الشكل:

~~~
App.editVoucher(
~~~

ويفشل بـ:

~~~
Uncaught SyntaxError: Unexpected end of input
~~~

وهذا يطابق Console المبلغ عنه ومسار SweetAlert2:

JSEventHandlerForContentAttribute

إذن:
**المشكلة Frontend HTML attribute encoding داخل details()، وليست RPC أو Edge Function أو صلاحية تشغيل.**

---

## 5. إثبات مستقل

تمت محاكاة Browser HTML attribute parsing + JavaScript compilation.

### Current

~~~
<td onclick="App.details("IN-6")">
~~~

الـhandler المستخرج:

~~~
App.details(
~~~

النتيجة: FAIL.

### Corrected

~~~
<td onclick="App.details('IN-6')">
~~~

الـhandler:

~~~
App.details('IN-6')
~~~

النتيجة: PASS.

تمثل هذه المشكلة نفسها جميع أزرار modal التي تستخدم codeJs.

---

## 6. لماذا لا نعدل esc() عالميًا

الدالة العامة الحالية في core.js:

~~~
function esc(s) {
    return String(s == null ? '' : s)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}
~~~

هذه دالة escaping عامة مستخدمة عبر تطبيقات كثيرة.

تعديلها لمعالجة هذا الاستخدام الخاص سيغير contract عالميًا بلا ضرورة.

الإصلاح الصحيح هنا **محلي داخل مولد قيمة JavaScript literal**.

---

## 7. التعديل الجراحي الوحيد المطلوب من المالك

### الملف

companies/company-1/warehouse/vouchers.html

### الدالة

details:function(code)

### ابحث حرفيًا عن هذا العنصر

~~~
var codeJs=
    JSON.stringify(
        String(v.voucher_code||'')
    );
~~~

**احذفه بالكامل.**

### واستبدله بالكامل بهذا العنصر

~~~
var codeJs=
    "'" +
    JSON.stringify(
        String(v.voucher_code||'')
    )
        .slice(1,-1)
        .replace(/'/g,"\\'") +
    "'";
~~~

هذا التعديل وحده هو المطلوب لعلاج Console الخاص بأزرار المودال.

---

## 8. لماذا هذا patch لا يعيد بناء أي شيء

بعد التطبيق سيكون لدينا:

- cards(): الكود المصحح موجود بالفعل.
- details(): الكود المصحح يصبح مطابقًا للعقد.
- جميع handlers التي تستخدم codeJs تحصل على JavaScript string صالح.
- actionFor() لا يتغير.
- receive() لا تتغير.
- editVoucher() لا تتغير.
- deleteVoucher() لا تتغير.
- send() لا تتغير.
- complete() لا تتغير.
- printDraftVoucher() لا تتغير.
- printVoucher() لا تتغير.
- exitVoucherDetails() لا تتغير.

لا يوجد سبب لكتابة details() أو cards() كاملة.

---

## 9. Current Source validation

تم جلب vouchers.html كاملًا من Current Frontend HEAD.

### Structural

- inline script blocks: 6
- آخر script: 199,299 chars تقريبًا
- parse كامل: PASS

### Current codeJs state

- var codeJs= total occurrences: 2
- corrected block inside cards(): موجود.
- stale block inside details(): موجود مرة واحدة.
- بعد تنفيذ replacement المقترح في الذاكرة:
  - stale block = 0
  - corrected block = 2

### Existing functional guards

actionFor(v) الحالي تم التحقق منه ولا يحتاج تعديلًا:

- يدعم permissions='*'.
- يرفع المستخدم privileged عند wildcard أو أدوار الإدارة المخزنية المعتمدة.
- Transfer Draft يعتمد creator/privileged.
- Transfer Sent يعتمد receiver_user_id بدقة.
- Transfer Received يسمح بالإكمال وفق العقد الحالي.

---

## 10. دور التبويب والتكامل المعماري

### النظام الأم

main.html هو Control Plane:

- إدارة المستخدمين والأدوار.
- الصلاحيات.
- الشركات والفروع.
- تعريفات المخازن والمركبات والمندوبين.
- الإشراف على التطبيقات المنفصلة.
- فتح تطبيق vouchers من النظام الأم.

لم يتم تعديل main.html.

### vouchers.html

هو سطح التشغيل للحركات المخزنية اليدوية غير المرتبطة مباشرة بدورة Order/Runsheet.

الأنواع الحالية:
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn

القائمة للاستعراض والتنقل.

المودال للتنفيذ والتحكم.

### van-sales.html

يمتلك تنفيذ Sales Invoice ومخزون السيارة الفعلي من خلال القلب المركزي.

vouchers.html لا يحل محل van-sales.html.

العلاقة الصحيحة:

vouchers DirectSale
→ إنشاء/تحميل حركة عهدة المركبة

van-sales
→ تنفيذ البيع الفعلي من مخزن السيارة

و:

vouchers DirectReturn
→ حركة مرتجع العهدة

وليس إعادة بناء تطبيق البيع المباشر داخل vouchers.

---

## 11. دورة Transfer التي يجب الحفاظ عليها

الحالة التشغيلية الصحيحة:

Draft
→ Send
→ تثبيت receiver_user_id
→ Receive أو Partial Receive
→ Received
→ Complete

### المصدر

المخزن المسؤول يلتزم بعقد مصدره وHome/Default branch.

### الوجهة

وجهة Transfer تسمح بالفروع النشطة التابعة للشركة وفق العقد الحالي.

### المستلم

بعد Send يصبح الاستلام bound إلى receiver_user_id.

لا يُسمح بأن يصبح الدور العام بديلًا عن مسؤول الاستلام المحدد.

### الاستلام الجزئي

يبقى ضمن نفس الحركة المركزية ويُسجل الفرق والمتبقي بدل إنشاء جزيرة تشغيل جديدة.

---

## 12. Production / Supabase

المشروع:
fiilmooggumokxanwiyx

الحالة:
ACTIVE_HEALTHY

Postgres:
17.x

### Edge Functions المرتبطة

- create-stock-voucher v12
- send-stock-voucher v20
- receive-stock-voucher v22
- complete-stock-voucher v4
- cancel-stock-voucher v4

لا توجد حاجة إلى Edge Function جديدة لهذه المشكلة.

### RPC المستخدم في العقد الحالي

- create_manual_stock_voucher_atomic
- delete_manual_stock_voucher_atomic
- post_manual_stock_voucher_atomic
- inventory_control
- inventory_voucher_stock_context

المسار المعماري المركزي موجود ويعمل، والمشكلة الحالية لا تستدعي إنشاء RPC جديدة.

### ACL الحالي

تم التحقق:
- الإنشاء/الحذف/النشر المركزي ليست متاحة مباشرة لـanon/authenticated.
- وظائف قراءة الـvoucher audit/context متاحة للمستخدم authenticated وفق عقدها.
- لا تعديل Production مطلوب لهذه الأزمة.

---

## 13. Production test data — تنفيذ واختبار وتنظيف

كان هناك Draft حالي باسم IN-6 من الاختبارات السابقة.

تم حذفه أولًا عبر:
delete_manual_stock_voucher_atomic

ثم أُنشئت Fixture جديدة باستخدام نفس Production RPC:

**Operation**
QA-MODAL-ACTIONS-20260928-01

**Type**
Transfer

**Reference**
QA-MODAL-ACTIONS-20260928

**Source**
BR-01

**Destination**
BR-2

**Item**
1001 — جو كيك 5ج

**Qty**
1

**Creator**
vouchers@rawaea.com

**Create**
PASS

**Voucher**
IN-6

ثم تم حذف الـVoucher عبر نفس Production delete RPC.

### النتيجة بعد التنظيف

Fresh Production query:

- Manual Completed = 5
- Manual Draft = 0
- Manual Sent = 0
- Manual Received = 0
- Voucher IN-6 = 0
- Details الخاصة بالـfixture = 0
- Inventory Log الخاصة بالـfixture = 0

### Operation ledger

تم العثور على سجل:
QA-MODAL-ACTIONS-20260928-01

بعد حذف الـVoucher.

محاولة حذفه يدويًا تم رفضها بواسطة:
guard_stock_voucher_operation_delete_integrity()

بالرسالة التي تفيد أن سجل هوية العملية جزء من سلامة الإعادة ومنع التكرار.

**لم يتم تجاوز الـGuard.**

النتيجة الصحيحة:
- لا Business Voucher residue.
- لا Detail residue.
- لا Inventory movement residue.
- Operation identity ledger محفوظ حسب عقد idempotency.

---

## 14. Production contracts التي لا يعاد فتحها

مغلق بالفعل:

- Transfer source responsibility.
- Transfer destination contract.
- Receiver binding.
- Partial/Full Receive backend contract.
- DirectReturn receive security.
- Existing stock voucher RPC/Edge path.
- QA voucher cleanup.
- Mother ↔ standalone app separation.

لا يوجد Production evidence حالي يناقض هذه الإغلاقات.

---

## 15. Deployment / Browser E2E

### Source parse

PASS

### Runtime defect reproduction

PASS كإثبات للعيب الحالي

### Corrected handler simulation

PASS

### GitHub Actions للـ85e

تم فحص workflow runs المرتبطة بالـcommit الحالي ولم تظهر Runs مرتبطة بهذا الـcommit.

لذلك:

**Browser E2E = OPEN**

ولا يجوز إعلان:
- modal runtime = PASS على Browser حقيقي.
- buttons = E2E PASS.
- published artifact = verified

قبل تطبيق الـowner patch ثم نشر النسخة وتشغيل Browser E2E فعليًا.

التقارير السابقة سجلت أيضًا أن Run 57 تعطل عند gate يبحث عن literal <body> بدل tag مع attributes، ولذلك لا يُعد دليلًا على فشل business flow.

---

## 16. Competitive review — ما الذي يجب أن يظل في Backlog بعد إغلاق عيب المودال

المقارنة الحديثة مع الوثائق الرسمية تؤكد أن نضج إدارة النقل المخزني يتجاوز مجرد From/To/Qty.

### Odoo 19

Moves History يضم Date وReference وProduct وLot/Serial وFrom وTo وQuantity وUnit وStatus، مع Filters وGroup By وتحليلات حركة.

المصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/moves_history.html

Odoo يميز Transit locations لحركة المخزون بين المواقع، ويعرض On Hand وReserved وIncoming وغيرها ضمن التقارير.

المصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html

### Dynamics 365

Transfer Orders تحتوي From/To warehouse وShip date وReceive date، مع إعدادات استقبال وتحكم في receiving process، كما تدعم البنية Transport lead time.

المصادر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-transfer-order-receiving-process
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/transfer-orders-warehouse

### SAP

يُميز النقل ثنائي الخطوة بين Goods Issue وGoods Receipt مع مفهوم Stock in Transit.

المصدر:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/4dd8cb7b1c484b4b93af84d00f60fdb8/82f4c353b677b44ce10000000a174cb4.html

### Daftra

Manual Transfer يتيح التاريخ، المرفقات/الملاحظات، From/To، الصنف، السعر، الكمية، والأرصدة قبل/بعد.

المصادر:
https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/
https://docs.daftra.com/en/tutorial/transferring-stock/

### Manager.io

Inventory Transfers تسجل الحركة من Location إلى Location، مع Reference وDate وDescription وItem وQty وFrom وTo، وتعدل أرصدة المواقع تلقائيًا.

المصدر:
https://www2.manager.io/guides/10707

### فجوات RAWAEA التي تستحق الإغلاق لاحقًا

ليست سبب عطل المودال الحالي:

- ETA / Expected Receive Date
- Transport lead time / SLA
- Stock-in-Transit projection
- Variance / discrepancy reason
- Backorder / remaining-transfer document
- Attachment / proof evidence
- Lot / Serial / Expiry support
- Formal reason taxonomy
- Approval actor/state
- Document vs movement vs stock reconciliation
- Transfer dashboard / aging / overdue
- Operational audit drill-down

هذه طبقات Business Contract مستقلة، ولا تُبنى الآن داخل هذا الإصلاح الجراحي.

---

## 17. UX/Workflow conclusion

النموذج الحالي يجب أن يبقى:

**Table → Row click → Modal → Contextual actions**

بدل زر تشغيل لكل عملية داخل القائمة.

داخل المودال:
- المعلومات أولًا.
- الأثر الفعلي ثانيًا.
- الأثر المالي/المحاسبي.
- التدقيق.
- أزرار التحكم حسب actionFor.

هذا يتفق مع الهدف التشغيلي للتطبيق: القائمة ليست جزيرة تنفيذ؛ المودال هو نقطة التحكم في دورة الإذن.

---

## 18. Self Audit

### تم إثباته

- Current System HEAD + parent: PASS
- Current Frontend HEAD + parent: PASS
- Current vouchers blob: PASS
- Current full inline JS parse: PASS
- Latest frontend commit scope: vouchers.html only
- Existing cards codeJs patch: PRESENT
- Details stale codeJs block: ISOLATED
- Exact runtime failure mechanism: REPRODUCED
- Corrected handler syntax: PASS
- actionFor contract: PRESENT / NO CHANGE REQUIRED
- main.html unchanged: PASS
- van-sales unchanged: PASS
- Production RPC/Edge path: PRESENT
- No new Edge Function required
- Existing backend contracts: CLOSED
- Temporary Draft fixture: CREATED
- Temporary Draft fixture: DELETED
- Voucher residue: 0
- Detail residue: 0
- Inventory log residue: 0
- Operation ledger retention: GUARD-PROTECTED / LEFT IN PLACE
- Manual Production status after cleanup: Completed=5 only

### لم يتم ادعاؤه

- لم يتم تعديل vouchers.html.
- لم يتم تعديل main.html.
- لم يتم تعديل van-sales.html.
- لم يتم تعديل Edge Functions.
- لم يتم تعديل RPCs.
- لم يتم إنشاء migration.
- لم يتم إعلان Browser E2E PASS.
- لم يتم إعلان Published Artifact PASS.

---

## 19. الحالة النهائية

### CLOSED

- Backend Transfer contracts
- Receiver responsibility
- Partial/Full Receive backend
- DirectReturn Production guard
- Existing voucher RPC/Edge infrastructure
- Cards codeJs defect
- QA business-data residue
- Architectural separation

### OPEN

**Owner surgical source patch only:**

details:function(code) → stale var codeJs around line 2047.

بعد التطبيق:
1. Source parse.
2. Served artifact verification.
3. Authenticated Browser E2E.
4. Validate:
   - Pending
   - row click
   - modal open
   - Edit
   - Delete
   - Send
   - Print
   - Receive full/partial
   - Complete
   - Exit
5. Production post-test data integrity.

---

## 20. تعليمات نقطة الدخول للجلسة التالية

ابدأ من Current Git لا من التقرير.

التسلسل الحاكم:

**CURRENT GIT**
→ verify System HEAD/parent  
→ verify Frontend HEAD/parent  
→ verify vouchers blob  
→ verify cards fixed + details stale block

ثم:

**CURRENT SOURCE**
→ owner applies only the exact details codeJs replacement

ثم:

**SOURCE VALIDATION**
→ parse  
→ handler extraction

ثم:

**CURRENT PRODUCTION**
→ no backend change unless new evidence contradicts a closed contract

ثم:

**DEPLOYMENT EVIDENCE**
→ served artifact identity  
→ authenticated Browser E2E

ثم:

**CLOSURE**
→ update CURRENT_STATE  
→ open next Business Contract only after actual evidence.

### ممنوع في نقطة الاستئناف

- لا تلمس main.html.
- لا تعيد تعديل cards().
- لا تعدل esc() عالميًا.
- لا تعيد T13-T16.
- لا تعيد Transfer destination patch.
- لا تعيد receiver binding.
- لا تنشئ Edge Function جديدة.
- لا تحذف Operation ledger بإجبار الـDB.
- لا تعتبر فشل Harness القديم فشل Business Workflow.
