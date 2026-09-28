# Report354 — RAWAEA ERP — Warehouse Vouchers — Forensic Modal Runtime Closure
Date: 2026-09-28
Scope: companies/company-1/warehouse/vouchers.html
Target closure: Pending tab → row click → voucher modal
Protected: main.html; vouchers.html source modification by reviewer
Status: surgical owner patch REQUIRED; Production contract CLOSED/VERIFIED

---

## 1. نقطة البداية المعتمدة

تمت قراءة والتحقق من:
- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP
- CURRENT_STATE.md
- أحدث سلسلة التقارير Report349 → Report353
- المصدر الحالي الفعلي من Git
- الـparent commit
- Production / Supabase current state
- Edge Functions الحالية
- Current main.html وvan-sales.html

قاعدة العمل: التقارير تاريخية؛ الحالة الحالية لا تُعتمد إلا من Current Git + Current Source + Current Production + Current Database + Current Deployment Evidence.

---

## 2. CURRENT GIT

### النظام الأم
- HEAD: 950a7e992c4f0e203ed544f4c4e50c944e9b1be0
- parent: 67b902942a797e0efee67bece5869e2c40680ec9
- HEAD message: state: record Report353 transfer destination filter checkpoint

### الواجهة التشغيلية
- Frontend HEAD: 880abe25c42d7c82c79cf133b9880d09ebfc416f
- parent: 1d2103a8903296a33110e83803a355f224c489c5
- vouchers.html blob: cd51d299bc50739c4bc374f9335eaf38f0b29534
- vouchers.html: 6,325 lines / 209,971 chars
- main.html blob: 27b777528665dcc985809648f006452c861ae36e
- van-sales.html blob: 8d61382a8e0025a0d079e71dd94f33d106d9088e

الـcommit 880abe25 هو تطبيق التصحيح السابق الخاص بفلتر وجهة التحويل. تم التحقق أن هذا التصحيح موجود بالفعل:
- old Transfer destination filter = 0
- corrected Transfer destination exception = 1

لا يجوز إعادة تطبيق T-09/T-10/T-11 أو إعادة العمل على Transfer destination.

---

## 3. CURRENT SOURCE — الفحص الكامل

تم جلب vouchers.html الحالي كاملًا من Git وإجراء فحص آلي على كامل النص:
- عدد الدوال المكتشفة: 75
- inline JavaScript parse: PASS
- cards:function(rows,scope) عند line 968
- details:function(code) عند line 1782
- pickSearch:function(key,q) عند line 3714
- receive:function(code,full) موجودة
- topActions+ موجودة ومستخدمة
- old Transfer destination filter غير موجود
- corrected Transfer destination filter موجود مرة واحدة

إذن:
المشكلة الحالية ليست Syntax Error داخل الـinline script.

---

## 4. السبب الجنائي للخطأ

Console:
vouchers:1 Uncaught SyntaxError: Unexpected end of input (at vouchers:1:13)

Stack:
JSEventHandlerForContentAttribute
→ safeHTML @ core.js:495
→ renderList

### العنصر المعيب

File:
companies/company-1/warehouse/vouchers.html

Function:
cards:function(rows,scope)

Current line:
حوالي 1176

ابحث عن هذا العنصر بالنص الحرفي:

~~~javascript
var codeJs=
    JSON.stringify(
        String(v.voucher_code||'')
    );
~~~

وهذا العنصر تستخدم قيمته لاحقًا في سبعة مواضع داخل نفس الدالة عبر:
s.esc(codeJs)

### لماذا ينكسر؟

للقيمة IN-6 مثلًا:

~~~javascript
codeJs = "IN-6"
~~~

ثم يُبنى HTML:

~~~html
onclick="App.details("IN-6")"
~~~

RW_UI.esc الحالية لا ترمز bare double-quote؛ تعالج backslash+quote فقط.

لذلك HTML parser يعامل الجزء الفعلي للـattribute على أنه:

~~~javascript
App.details(
~~~

ثم JSEventHandlerForContentAttribute يحاول compile هذا النص ويعيد:

~~~text
Unexpected end of input
~~~

وهذا يطابق Console حرفيًا ويشرح عدم استجابة الضغط على صف الإذن/فتح المودال.

### إثبات مستقل

تمت محاكاة HTML parser ثم JavaScript parser:
- current IN-6 → handler = App.details( → JS parse FAIL
- corrected IN-6 → handler = App.details('IN-6') → JS parse PASS
- الاختبار مر أيضًا على قيم تحتوي apostrophe وdouble quote وbackslash وampersand.

---

## 5. التعديل الجراحي الوحيد المطلوب من المستخدم

### الملف
companies/company-1/warehouse/vouchers.html

### الدالة
cards:function(rows,scope)

### العنصر المعيب
العنصر التالي فقط:

~~~javascript
var codeJs=
    JSON.stringify(
        String(v.voucher_code||'')
    );
~~~

### الإجراء

ابحث عن العنصر السابق واحذفه بالكامل.

ثم استبدله بالكامل بهذا العنصر:

~~~javascript
var codeJs=
    "'" +
    JSON.stringify(
        String(v.voucher_code||'')
    )
        .slice(1,-1)
        .replace(/'/g,"\\'") +
    "'";
~~~

هذا هو التعديل الجراحي الوحيد المطلوب لعطل المودال.

### النتيجة

IN-6 ستنتج:

~~~html
onclick="App.details(&#39;IN-6&#39;)"
~~~

وبعد HTML entity decoding يصبح:

~~~javascript
App.details('IN-6')
~~~

وبذلك تصبح قيمة الـevent handler صالحة للتنفيذ.

هذا الاستبدال الواحد يصلح مواضع s.esc(codeJs) السبعة داخل cards() دون تعديل أي handler آخر.

---

## 6. لماذا لم يتم تعديل esc() عالميًا

العيب محصور في توليد قيمة JavaScript string داخل HTML attribute.

تعديل RW_UI.esc() على مستوى المشروع كان سيغيّر contract مستخدمًا في مواضع HTML أخرى.

الإصلاح الحالي موضعي:
- يعزل المشكلة في codeJs
- يحافظ على cards() الحالية
- لا يعيد كتابة modal
- لا يعيد كتابة renderList
- لا يلمس main.html
- لا يلمس van-sales

---

## 7. CURRENT MAIN — التكامل

Current:
Current/PWA/main.html
blob: 27b777528665dcc985809648f006452c861ae36e

تم التحقق من:
- Parent Registry
- app entry: vouchers → ./vouchers.html
- تسمية الأذونات المخزنية
- delegation من النظام الأم إلى التطبيقات التشغيلية

النظام الأم يظل Control Plane.
vouchers هو Operational Execution Surface.
Supabase / RPC / Edge هو Transactional Execution Plane.

لا يوجد نقص في main.html يسبب مشكلة المودال الحالية.

main.html لم يُعدّل.

---

## 8. CURRENT VAN-SALES — التكامل

Current:
companies/company-1/sales/van-sales.html
blob: 8d61382a8e0025a0d079e71dd94f33d106d9088e

تم التحقق من:
- save-sales-invoice موجود
- setup-van-branch موجود
- operation_id مستخدم
- van-sales لا يعتمد مباشرة على stock_vouchers في المصدر الحالي

العقد الوظيفي الذي يجب الحفاظ عليه:
- van-sales يملك Sales Invoice / Van Stock execution
- vouchers يملك Manual Stock Voucher execution
- DirectSale وDirectReturn في vouchers يمثلان حركة عهدة/مخزون مرتبطة بالمندوب، وليس بديلًا عن Sales Invoice
- لا يوجد سبب لدمج التطبيقين أو جعل أحدهما تابعًا للآخر داخل هذه النقطة

---

## 9. دورة العمل التي يجب الحفاظ عليها

### Transfer

Draft
→ Send
→ immutable receiver binding
→ Receive / Partial Receive
→ Received
→ Complete

Sender:
- يملك Draft
- يرسل بعد تحقق مسؤولية المصدر
- لا يستلم تحويله

Receiver:
- مرتبط بـ receiver_user_id
- يملك Partial/Full Receive
- لا يمكن إعادة تعيين المسؤولية بعد Send

### Manual vouchers

الأنواع الحالية:
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn

التطبيق مصمم للحركات المخزنية اليدوية غير المرتبطة بدورة order/runsheet.

Lists للتنقل.
Modal للتنفيذ.

هذا البناء لا يجب تغييره لعلاج خطأ HTML event encoding.

---

## 10. CURRENT PRODUCTION / SUPABASE

Project:
fiilmooggumokxanwiyx

أحدث migrations ذات العلاقة:
- 20260928132432 — bind_transfer_source_to_keeper_home_branch
- 20260928120431 — harden_transfer_partial_receive_actor
- 20260928113103 — close transfer responsibility trigger ACL
- 20260928112842 — harden transfer responsibility trigger execute surface
- 20260928090424 — fix transfer receiver UUID selection
- 20260928090051 — transfer responsibility and receiver binding

### Edge Functions الحالية ذات العلاقة

- create-stock-voucher v12 — ACTIVE
- send-stock-voucher v20 — ACTIVE
- receive-stock-voucher v22 — ACTIVE
- complete-stock-voucher v4 — ACTIVE
- cancel-stock-voucher v4 — ACTIVE

إجمالي Edge Functions observed في Production = 100.

لم يتم إنشاء Edge Function جديد.

### RPC

الحالي:
- create_manual_stock_voucher_atomic(...)
- delete_manual_stock_voucher_atomic(...)
- post_manual_stock_voucher_atomic(...)

كلها SECURITY DEFINER مع search_path=public.

لا يوجد Production defect في الـtransactional contract يبرر إنشاء RPC أو Edge Function جديد لمعالجة هذا العطل.

---

## 11. اختبار البيانات في Production

### تنظيف البيانات القديمة

قبل الاختبار كان موجودًا Draft قديم:
IN-6

تم حذف المسودة القديمة عبر delete_manual_stock_voucher_atomic لأن:
- الحالة Draft
- لا توجد حركة مخزنية مرتبطة بها

### إعادة إنشاء fixture للتحقق

تم إنشاء fixture مؤقتة بنفس Production RPC:

operation:
QA-UI-MODAL-20260928-01

النتيجة:
- create = PASS
- voucher created = IN-6
- status = Draft

ثم تم حذف fixture عبر نفس Production RPC.

### النتيجة النهائية

- Manual Completed = 5
- Manual Draft = 0
- Manual Sent = 0
- Manual Received = 0
- voucher residue IN-6 = 0
- voucher details residue = 0
- inventory_log residue = 0

Audit mentions = 16 تاريخية مرتبطة بالاختبارات السابقة؛ لم تُحذف لأنها Audit History وليست business residue.

لم يتم حذف أي سجل Completed تاريخي له أثر مخزني/مالي.

---

## 12. E2E / Deployment Evidence

### Source E2E

- parse كامل vouchers.html = PASS
- current source structural checks = PASS
- malformed inline event reproduction = FAIL كما هو متوقع قبل الـpatch
- corrected inline event reproduction = PASS

### Browser E2E

آخر:
RAWAEA — Warehouse Vouchers Browser E2E
Run 57
HEAD 880abe25c42d7c82c79cf133b9880d09ebfc416f
Result FAIL

الفشل قبل تشغيل browser smoke.

السبب داخل الـworkflow نفسه:

~~~javascript
const a=s.indexOf('<script>',s.indexOf('<body>'));
if(a<0||b<=a) throw new Error('INLINE_SCRIPT_NOT_FOUND');
~~~

الـgate يبحث عن literal <body> لا يحتوي attributes، بينما source الحالي يستخدم body tag بخصائصه.

لذلك:
- source gate = FAIL
- browser install = SKIPPED
- browser smoke = SKIPPED

هذه ليست business workflow failure.

لم يتم تعديل workflow في هذه الجلسة لأن نطاق الإصلاح الحالي هو vouchers.html فقط، ولأن المستخدم طلب تعديلًا جراحيًا محددًا في عنصر العطل.

### Deployment conclusion

Published served artifact لم يُثبت بهذه الجلسة عن طريق Browser بسبب harness gate.

لا يجوز إعلان Browser E2E PASS قبل تطبيق الـowner patch ونشره ثم إعادة الاختبار.

---

## 13. Competitive contract review

### Odoo
Odoo Moves History يوثق:
- Date
- Reference
- Product
- Lot/Serial
- From
- To
- سبب/سياق الحركة

### Microsoft Dynamics 365
Transfer Orders تدعم:
- From warehouse
- To warehouse
- Ship date
- Receive date
- transport lead time
- planned transfer/replenishment
- receiving process configuration

### SAP
Stock Transfer يدعم:
- one-step
- two-step
- goods issue
- goods receipt
- stock in transit
- partial quantity / correction
- valuation context

### Daftra
Manual Transfer يدعم:
- date/time
- attachments / notes
- from/to
- item
- unit price
- quantity
- stock before/after
- total
- detailed inventory transactions
- print/export

### Manager.io
Inventory Transfers تدعم:
- location/source
- destination
- transfer document
- location-based stock accounting

### الفجوات الحالية في vouchers.html

هذه فجوات Business Contract مستقلة، وليست سبب Console الحالي:
- ETA / expected receive date
- transport lead time / expected transit
- discrepancy / variance at receive
- backorder / remainder document
- attachment/document evidence
- lot/serial/expiry tracking
- formal reason taxonomy
- approval actor/state
- reconciliation document vs movement vs stock
- stock-in-transit reporting

لم يتم بناء هذه الطبقات داخل vouchers.html الآن لأن المهمة الحالية حُصرت في إغلاق عطل المودال وعدم لمس الأصل التشغيلي القائم.

مراجع المنافسين:
Odoo:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/moves_history.html

Dynamics 365:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/transfer-orders-warehouse
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-transfer-order-receiving-process

SAP:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/9e64bd534f22b44ce10000000a174cb4.html
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/95f56a29a41e4861ba3424598848ee2b/4d6ed2bb174a74dbe10000000a42189c.html

Daftra:
https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/

Manager:
https://www2.manager.io/guides/10707

---

## 14. Self Audit

### تم إثباته
- current Git verified
- system parent verified
- frontend parent verified
- current vouchers source verified
- main.html verified unchanged
- van-sales verified unchanged
- complete inline JS parse = PASS
- exact runtime defect reproduced
- exact surgical replacement derived
- current transfer destination patch retained and not repeated
- current Production migration state verified
- current Edge Function state verified
- current RPC path verified
- old Draft QA fixture removed
- temporary QA fixture created through Production RPC
- temporary QA fixture removed through Production RPC
- final voucher/inventory residue = 0
- historical audit mentions preserved

### لم يتم ادعاؤه
- لم يتم تعديل vouchers.html.
- لم يتم تعديل main.html.
- لم يتم تعديل van-sales.html.
- لم يتم تعديل أي Edge Function.
- لم يتم تعديل أي RPC.
- لم يتم إنشاء جدول أو migration جديد.
- لم يتم حذف أي Posted/Completed history.
- لم يتم إعلان Browser E2E PASS.
- لم يتم إعادة إصلاح Transfer backend contracts المغلقة.

---

## 15. الحالة عند إغلاق الجلسة

### CLOSED
- Transfer source responsibility
- Transfer destination selection contract
- Receiver binding
- Partial/full receive backend
- DirectReturn receive Production contract
- Existing transactional RPC/Edge path
- Parent ↔ standalone app architecture
- QA residue cleanup
- vouchers inline JS syntax

### OPEN
- Owner surgical source replacement:
  cards() → var codeJs block around line 1176
- Published artifact verification
- Browser E2E after owner patch

### NO CHANGE
- main.html
- van-sales.html
- Production schema
- existing Edge Functions
- existing RPCs
- closed Transfer contracts

---

## 16. نقطة دخول الجلسة القادمة

ابدأ بالترتيب التالي:

1. تحقق من Frontend HEAD وvouchers blob.
2. داخل cards:function(rows,scope)، تحقق:
   - old codeJs block = 0
   - corrected codeJs block = 1
3. parse كامل vouchers.html.
4. تحقق أن rendered handler لـIN-6 يصبح App.details('IN-6').
5. طبّق فقط التعديل الجراحي المحدد أعلاه إذا لم يكن مطبقًا.
6. انشر المصدر.
7. شغّل Browser E2E.
8. تحقق من:
   - Pending table
   - row click
   - modal open
   - Print
   - actionFor
   - Send/Receive/Complete
   - Partial/Full Receive
   - Exit without save
9. تحقق من served artifact identity.
10. لا تعُد إلى أي backend contract مغلق.
11. بعد إغلاق modal runtime افتح Business Contract التالية فقط.

---

## 17. الإرشاد الحاكم للمساعد القادم

لا تبدأ من التقارير.

ابدأ من:
CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT EVIDENCE

ثم قارن فقط مع التقرير الأخير لاستخدامه كخريطة تاريخية.

في هذه النقطة تحديدًا:
- لا تعيد T-09/T-10/T-11.
- لا تعيد T-13/T-14/T-15/T-16.
- لا تعيد receiver binding.
- لا تعيد source responsibility.
- لا تنشئ Edge Function جديد.
- لا تلمس main.html.
- لا تلمس أي بنية backend إلا إذا ظهرت أدلة Current تناقض العقد المغلق.
- لا تستبدل cards() بالكامل.
- لا تعدّل esc() عالميًا.
- ابحث عن عنصر codeJs المحدد عند line ~1176 وبدّله فقط إذا كان الإصلاح غير مطبق.
- لا تعتبر فشل Run 57 فشلًا في Business Workflow؛ فشل الـharness يمنع Browser Smoke قبل تشغيله.

