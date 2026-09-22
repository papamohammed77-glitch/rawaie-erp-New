# تقرير 304 — التحقيق الجنائي والإغلاق الجراحي لتطبيق الأذونات المخزنية
## RAWAEA ERP — Vouchers Current-Head Forensic Syntax / Supplier Smart Search / KPI / Top Panel Closure
**التاريخ:** 2026-09-22  
**النطاق:** `companies/company-1/warehouse/vouchers.html` فقط على مستوى Source Patch المقدم للمالك، مع تحقق Production مباشر.  
**ملفات ممنوع تعديلها في هذه المهمة:** `main.html` و`companies/company-1/warehouse/vouchers.html` و`companies/company-1/sales/van-sales.html`.  
**Production المبنية تحت هذه المهمة:** لا توجد DDL جديدة؛ تم إنشاء سجل QA دائم واحد فقط `IN-8` بطلب المستخدم، وبقي Draft دون حركة مخزنية.

---

# 1. الحكم التنفيذي

تم الوصول إلى السبب الحقيقي للخطأ الحي في تطبيق الأذونات المخزنية، وليس إلى عرض جانبي.

## السبب الجذري المثبت

الملف الحالي `vouchers.html` يحتوي داخل JavaScript المضمّن على ستة مقاطع HTML مولّدة بسلاسل JavaScript أحادية الاقتباس، وقد فُقدت منها الـescaping اللازمة للاقتباسات المفردة داخل `onclick`.

المواضع المثبتة حاليًا:

- السطر 560 — `App.send`
- السطر 565 — `App.cancel`
- السطر 574 — `App.receive`
- السطر 583 — `App.complete`
- السطر 668 — `App.details`
- السطر 1541 — `App.pickSelect`

هذا يكسر الـJavaScript parser قبل اكتمال تعريف `App`.

وبالتالي:

`SyntaxError`
→ تعذر تنفيذ Script الرئيسي
→ لم يُنشأ `App`
→ أي inline `onclick="App...."` يفشل
→ `App is not defined`

إذن مشكلة عدم تخطي شاشة الدخول، ومشكلة القائمة المنسدلة للمورد، وتعطل أزرار الإذن ليست ثلاث مشاكل مستقلة؛ أصلها الحالي واحد: **script parse failure**.

---

# 2. الحالة المرجعية التي تم التحقيق منها

## System Repository

**Repository:** `papamohammed77-glitch/rawaie-erp-New`

**HEAD الحالي المثبت:**
`28b4a9b8848d942cf3a455c87bd929280c0c2356`

**Parent:**
`b5d1c7b02b7895b4c1d02de45a03611a73490e6b`

آخر commitين الخاصين بإغلاق/تثبيت تقرير الأذونات المخزنية هما:

- `b5d1c7b...` — final vouchers execution closure
- `28b4a9b...` — finalize CURRENT_STATE for Report303

لم يتم التعامل مع التقارير باعتبارها Production؛ تم الرجوع إليها كـHistorical Evidence فقط ثم مطابقة Git/Source/Production.

## Frontend Repository

**Repository:** `papamohammed77-glitch/erp-frontend`

**HEAD الحالي:**
`54227e9d6ecf56d1f54ba1329ce518805bcc93cb`

**Parent:**
`6715825ec05e62482a4e37335ab366f5512805cf`

الـParent المباشر `6715825e...` يحتوي إصلاح Source Branch initialization في `newWorkspace()` الخاص بالصرف المباشر، ولم يكن سبب مشكلة الـparser الحالية.

**Current vouchers source blob:**
`4170178303d97162bd668904b822725cd3be5d15`

لم يتم تعديل هذا الملف في هذه المهمة بناءً على تعليمات المالك.

## CURRENT_STATE

تمت قراءة الملف الحالي كاملًا برمجيًا.

**Current blob SHA قبل هذا التقرير:**
`1231a772277885ea3725673fc4cef223b708999c`

**عدد الأسطر قبل الإضافة:** 10,937

آخر checkpoint قبل هذه المهمة كان Report303.

---

# 3. Production Snapshot — لحظة الإغلاق

تم أخذ Snapshot جديد من Supabase قبل تثبيت هذا التقرير.

- companies = 1
- branches = 3
- vehicles = 1
- stock_vouchers = 8
- stock_voucher_details = 10
- stock_voucher_operations = 8
- inventory_log = 6
- audit_log = 2041

حالات الأذونات:

- Draft = 7
- Sent = 0
- Received = 0
- Completed = 0
- Cancelled = 1

هذا snapshot هو المرجع الحالي لهذه الجلسة.

---

# 4. QA Production Data — محفوظ عمدًا

السجل الجديد الذي تم إنشاؤه في هذه المهمة:

### IN-8

- النوع: SupplierReturn
- الحالة: Draft
- المرجع: `QA-VOUCHERS-SYNTAX-SUPPLIER-20260922`
- المصدر: BR-01
- الوجهة: SUPP-1001
- الصنف: 1001
- الكمية: 1
- operation_id:
  `QA-VOUCHERS-SYNTAX-SUPPLIER-20260922-01`
- voucher_id:
  `b8a075ed-e10a-4333-affa-e55325a6692b`

Production proof بعد الإنشاء:

- details = 1
- operations = 1
- physical inventory movements = 0
- audit record موجود

لم يُحذف هذا السجل.

وجميع QA vouchers من `IN-2` حتى `IN-8` أثبت الفحص المباشر أنها لا تحمل أي Physical Stock Movement.

---

# 5. Login Failure — Root Cause Closure

الـLogin implementation الحالي نفسه صحيح من حيث التسلسل:

`DOMContentLoaded`
→ `App.init()`
→ `RW_Auth.init()`
→ استعادة Session
→ جلب `users`
→ تحديد `company_id`
→ `loadRefs()`
→ تحقق صلاحية `أذونات`
→ إخفاء `loginScreen`
→ إظهار `mainApp`

المصدر الحالي يحتوي هذا المنطق في:

`doLogin:function()` — السطر 30  
`init:function()` — السطر 31

لذلك لم يتم تعديل Login/Auth contract.

العائق الحقيقي كان أن parser يتوقف قبل الوصول إلى تعريف التطبيق كاملًا.

**نتيجة:** إصلاح الاقتباسات الستة يعالج السبب الجذري بدل إضافة workaround لتجاوز Login.

---

# 6. Static Parser Verification

تم أخذ نسخة In-Memory من نفس `vouchers.html` الحالي.

تم تطبيق الإصلاحات الجراحية الستة عليها فقط.

تم استخراج كل inline scripts وعددها = 6.

النتيجة قبل الإصلاح:

- Script 0 PASS
- Script 1 PASS
- Script 2 PASS
- Script 3 PASS
- Script 4 PASS
- Script 5 FAIL — `SyntaxError: Invalid or unexpected token`

النتيجة بعد الإصلاح In-Memory:

- Script 0 PASS
- Script 1 PASS
- Script 2 PASS
- Script 3 PASS
- Script 4 PASS
- Script 5 PASS

إذن الإصلاحات الستة كافية لإزالة الـSyntaxError المثبت، ولم يظهر SyntaxError آخر في الـinline scripts.

---

# 7. Surgical Owner Patch — vouchers.html فقط

## V-304-01 — SEND

**الدالة:** `cards:function(rows,scope)`

**ابحث عن هذا المقطع حرفيًا:**

```javascript
                    '<button onclick="event.stopPropagation();App.send(''+
                    s.esc(v.voucher_code)+
                    '')" class="bg-indigo-600 text-white px-3 py-2 rounded-xl text-xs font-black">إرسال</button>';
```

**احذفه واستبدله بهذا المقطع كاملًا:**

```javascript
                    '<button onclick="event.stopPropagation();App.send(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-indigo-600 text-white px-3 py-2 rounded-xl text-xs font-black">إرسال</button>';
```

---

## V-304-02 — CANCEL

**الدالة:** `cards:function(rows,scope)`

**ابحث عن:**

```javascript
                    '<button onclick="event.stopPropagation();App.cancel(''+
                    s.esc(v.voucher_code)+
                    '')" class="bg-rose-600 text-white px-3 py-2 rounded-xl text-xs font-black">إلغاء</button>';
```

**احذف واستبدل بـ:**

```javascript
                    '<button onclick="event.stopPropagation();App.cancel(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-rose-600 text-white px-3 py-2 rounded-xl text-xs font-black">إلغاء</button>';
```

---

## V-304-03 — RECEIVE

**الدالة:** `cards:function(rows,scope)`

**ابحث عن:**

```javascript
                    '<button onclick="event.stopPropagation();App.receive(''+
                    s.esc(v.voucher_code)+
                    '')" class="bg-emerald-600 text-white px-3 py-2 rounded-xl text-xs font-black">استلام</button>';
```

**احذف واستبدل بـ:**

```javascript
                    '<button onclick="event.stopPropagation();App.receive(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-emerald-600 text-white px-3 py-2 rounded-xl text-xs font-black">استلام</button>';
```

---

## V-304-04 — COMPLETE

**الدالة:** `cards:function(rows,scope)`

**ابحث عن:**

```javascript
                    '<button onclick="event.stopPropagation();App.complete(''+
                    s.esc(v.voucher_code)+
                    '')" class="bg-violet-600 text-white px-3 py-2 rounded-xl text-xs font-black">إكمال</button>';
```

**احذف واستبدل بـ:**

```javascript
                    '<button onclick="event.stopPropagation();App.complete(\''+
                    s.esc(v.voucher_code)+
                    '\')" class="bg-violet-600 text-white px-3 py-2 rounded-xl text-xs font-black">إكمال</button>';
```

---

## V-304-05 — DETAILS CARD

**الدالة:** `cards:function(rows,scope)`

**ابحث عن:**

```javascript
            '<div class="card mb-3 cursor-pointer" onclick="App.details(''+
                s.esc(v.voucher_code)+
            '">'+
```

**احذف واستبدل بـ:**

```javascript
            '<div class="card mb-3 cursor-pointer" onclick="App.details(\''+
                s.esc(v.voucher_code)+
            '\')">'+
```

---

## V-304-06 — Supplier / Branch / Vehicle Smart Dropdown

**الدالة:** `pickSearch:function(key,q)`

**ابحث عن:**

```javascript
                    '<div class="smart-row" onclick="App.pickSelect(''+
                        s.esc(key)+
                        '',''+
                        s.esc(x.id)+
                    '')">'+
```

**احذف واستبدل بهذا المقطع كاملًا:**

```javascript
                    '<div class="smart-row" onclick="App.pickSelect(\''+
                        s.esc(key)+
                        '\',\''+
                        s.esc(x.id)+
                    '\')">'+
```

هذه النقطة تعالج الـparser، وبالتالي تعيد تشغيل `pickSearch()` و`pickSelect()` بدل محاولة إصلاح Supplier logic بفلتر جديد.

---

# 8. ما لم يتم تعديله عمدًا

## Top Panel

الدالة الحالية:

`toggleTopPanel:function()`

في الأسطر 105–143.

وقد ثبت أنها تطبق:

`wsRoutePanel`
+
`wsTopPanel`

بنفس حالة collapse.

إذن مشكلة طي/توسيع القائمة العليا **ليست defect حالية في source** ولا يجوز إعادة إصلاحها.

الـhistorical commit `745a615...` نقل `routeHtml()` خارج `wsTopPanel`، ثم أصبح `toggleTopPanel()` الحالي يطوي الاثنين. إعادة patch لهذه النقطة الآن ستكون إعادة إصلاح غير مبررة.

**الحكم:** CLOSED / DO NOT REOPEN.

---

# 9. KPI — لا يوجد نقص Frontend حالي يستوجب إعادة بناء

المصدر الحالي يعرض بالفعل:

- بداية الإذن
- بداية التنفيذ
- النهاية المثبتة
- مدة الدورة
- العمر الحالي
- إنشاء → إرسال
- إرسال → استلام
- استلام → إكمال

كما أن Production `inventory_control('VOUCHER_AUDIT')` يحتوي العقد الإضافي:

- start_at
- sent_at
- received_at
- completed_at
- end_at
- created_to_sent_seconds
- sent_to_received_seconds
- received_to_completed_seconds
- created_to_completed_seconds
- current_age_seconds

لذلك لا يتم إنشاء KPI جديد أو إعادة بناء ما سبق.

---

# 10. Supplier Smart Search — الحكم الجنائي

الـbackend/source relation الحالية ليست عشوائية.

`loadRefs()` يجلب:

- suppliers داخل `company_id`
- purchase_orders داخل `company_id`

ثم:

`pickArr('wsTo')` في SupplierReturn يعتمد على `supplierBranchMap`.

عند عدم وجود علاقة موثقة:

`[]`

وهذا سلوك fail-closed صحيح.

الـQA Production الحالية أثبتت علاقة:

`SUPP-1001 ↔ BR-01`

وبالتالي `IN-7` و`IN-8` يمثلان حالات SupplierReturn صحيحة يمكن أن تظهر في القائمة.

لا يوجد ما يبرر فتح الموردين غير المرتبطين بالفرع.

---

# 11. Service Worker 404 — التحقيق

Production source الحالي يحتوي:

### `companies/company-1/sw.js`

وموجود فعليًا.

بينما:

### `companies/company-1/warehouse/sw.js`

غير موجود.

أما:

### `companies/company-1/register-sw.js`

فيحتوي شرطًا صريحًا يستثني:

`/vouchers.html`

من التسجيل.

والـcore الحالي `RW_SW.register(swPath)` يستخدم المسار الذي يمرره التطبيق.

والـvouchers الحالية تستدعي:

`RW_SW.register('../sw.js')`

أي أن التصميم الحالي يعتمد على SW المشترك الموجود في `company-1/sw.js`، وليس إنشاء SW ثاني داخل `warehouse/`.

لذلك رسالة:

`script https://rawaea-erp.pages.dev/companies/company-1/warehouse/sw.js 404`

لا تتوافق مع مسار `register-sw.js` الحالي المثبت في Git.

**الحكم الجنائي:**

هذه الرسالة لا تثبت defect في Source الحالي؛ بل تشير إلى artifact منشور/قديم أو browser cache/stale deployment.

لا يتم إنشاء `warehouse/sw.js`، لأن ذلك سيصنع محرك Service Worker موازيًا بلا عقد معماري.

**الحالة:** Deployment/Browser verification OPEN — وليس Source defect.

---

# 12. Van Sales

لم يظهر في هذه المراجعة Defect جديد في:

`companies/company-1/sales/van-sales.html`

تم الحفاظ على:

- Vehicle identity
- Mobile Branch
- Direct Sales Rep
- Voucher integration
- operation identity
- save-sales-invoice path

لا يتم تعديل `van-sales.html` في هذه closure.

---

# 13. النظام الأم

`main.html` لم يتم تعديله.

التكامل الحالي للتطبيق المنفصل يعتمد على:

`Session/Auth`
→ `users.company_id`
→ `warehouse permission / active warehouse role`
→ `inventory_control / voucher RPCs`
→ `stock_vouchers`
→ `stock_voucher_details`
→ `stock_voucher_operations`
→ `inventory_log`
→ `audit_log`

هذا يحافظ على فصل التطبيق التشغيلي مع إبقاء الـProduction control في المركز.

---

# 14. Physical Stock Contract

لم يتم إعادة فتحه.

العقد القائم:

`Physical Stock Movement`
→ `post_stock_movement`
→ `stock_branches`
+
`inventory_log`

و:

`reserve_stock`

محرك Reservation فقط.

لم يتم إدخال Writer جديد.

---

# 15. Competitive Review — ما هو موجود وما هو المستقبل

المراجعة الحالية لم تقلد واجهة أي منافس؛ قارنت Business Capabilities فقط.

### Odoo

Odoo 19 يدعم Inventory Adjustments، barcode scanning، assigned counting tasks، scheduled counts، expected quantity controls، وaudit/history.  
Source: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management/count_products.html  
Source: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html

### Dynamics 365

Dynamics يوفر Inventory Journals للـadjustment/transfer/counting/reclassification، مع ربط الحركة بالمخزون والدفتر المالي.  
Source: https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-count-adjust-reclassify  
Source: https://learn.microsoft.com/en-us/dynamics365/finance/general-ledger/inventory-posting

### SAP

SAP S/4HANA Goods Movement يغطي Goods Receipt، Goods Issue، Stock Transfer، Transfer Posting، مع مستندات وحركة تاريخية.  
Source: https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae130c0c/742e46e570984d9aa74e468838f6e1ff.html

### Daftra

Daftra يعرض detailed inventory transactions مع timestamp، type، warehouse، inward/outward، notes، ويدعم serial/lot/expiry.  
Source: https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/  
Source: https://docs.daftra.com/en/user_manual/how-to-perform-inventory-stocktaking-of-tracked-products/

### Manager.io

Manager يوفر Inventory Transfers بتاريخ وReference وDescription وItem وQty وFrom/To location، ويعدل المخزون آليًا عند تسجيل النقل.  
Source: https://www2.manager.io/guides/10707

---

# 16. Genuine future contract gaps

هذه ليست أخطاء حالية، ولم تُدخل في هذه patch لأن إدخالها يتطلب Contract/Schema جديدًا:

- lot / serial / expiry
- document date/time editable contract
- formal approval workflow
- evidence attachments
- explicit discrepancy taxonomy
- in-transit stock
- counting sessions assigned to users
- before/after stock snapshots
- richer document print/export
- valuation / line-value exposure داخل شاشة الإذن

لا يتم تحويل هذه البنود إلى UI fake fields قبل وجود Business Contract وProduction schema مناسب.

---

# 17. E2E Status

## Verified

- Production current snapshot
- current Git HEAD
- parent commits
- current vouchers source
- current register-sw/core/sw structure
- current Login/Auth call chain
- current KPI source
- current Supplier mapping
- persistent QA `IN-8`
- QA voucher has no physical movement
- static JavaScript parser before patch = FAIL
- static parser after six exact patches = PASS
- no additional syntax failure

## Not claimable yet

Authenticated Browser E2E against the deployed Cloudflare artifact لم يُغلق بعد، لأن هذه الجلسة لا توفر browser-authentication runtime مباشرًا إلى التطبيق المنشور.

لذلك:

**Backend / Source Integrity = VERIFIED**

ولا يجوز تسجيل:

**Browser E2E = PASS**

قبل تطبيق owner patch ثم نشر artifact واختبار المتصفح الفعلي.

---

# 18. Final Closure Matrix

| نقطة | النتيجة |
|---|---|
| Login عدم التخطي | ROOT CAUSE PROVEN — parser failure |
| App undefined | ROOT CAUSE PROVEN — consequence of parser |
| SEND handler | Surgical patch ready |
| CANCEL handler | Surgical patch ready |
| RECEIVE handler | Surgical patch ready |
| COMPLETE handler | Surgical patch ready |
| DETAILS handler | Surgical patch ready |
| Supplier smart dropdown handler | Surgical patch ready |
| Supplier relation | PRODUCTION PROVEN |
| KPI backend | CLOSED |
| KPI frontend | Existing / preserved |
| Top panel collapse | CLOSED in current source |
| Vehicle picker | CLOSED historically |
| Mobile Branch | CLOSED historically |
| Van Sales | Preserved / no new defect |
| Physical Stock centralization | CLOSED / not reopened |
| Service Worker source | Current canonical SW exists |
| SW browser 404 | Deployment/browser evidence OPEN |
| New Edge Function | NONE |
| New Physical Stock Writer | NONE |
| New DB table/column | NONE |
| Persistent QA | RETAINED |

---

# 19. Instructions for the next CTO / owner

ابدأ دائمًا من:

`CURRENT GIT`
+
`CURRENT SOURCE`
+
`CURRENT PRODUCTION`
+
`CURRENT DATABASE`
+
`CURRENT DEPLOYMENT EVIDENCE`

ثم:

1. تحقق من Frontend HEAD والـblob قبل أي تعديل.
2. لا تعيد Vehicle Picker أو Top Panel أو KPI repairs السابقة.
3. طبّق فقط V-304-01 إلى V-304-06.
4. شغّل parser/static check.
5. انشر `erp-frontend`.
6. افتح التطبيق في Browser authenticated.
7. تحقق من Login.
8. افتح Warehouse → Stock Vouchers.
9. اختبر:
   - Pending
   - DirectSale
   - collapse/expand
   - Branch → Rep → Vehicle
   - DirectReturn
   - SupplierReturn → supplier dropdown
   - Details
   - KPI
10. افحص Console.
11. تحقق من Production.
12. خذ Production snapshot جديدًا في نفس لحظة تقرير Browser E2E.
13. لا تعلن Browser PASS من DB PASS.
14. لا تنشئ Service Worker جديدًا.
15. لا تلمس `main.html`.

---

# 20. سبب الخطأ النهائي — الخلاصة

**الخطأ ليس في Supabase Login، ولا في Supplier relation، ولا في KPI، ولا في Vehicle Picker.**

السبب المحدد هو:

> فقدان JavaScript escaping داخل ستة inline event-handler string fragments في `vouchers.html`.

أول موضع قاتل هو السطر 560، ثم تبقى خمس مواضع مماثلة يجب إصلاحها في نفس الـsource حتى لا ينتقل الخطأ إلى handler آخر بعد إزالة الأول.

الإصلاح الصحيح هو **تصحيح الاقتباسات فقط**، وليس إعادة كتابة التطبيق أو تجاوز Login أو إنشاء Edge Function جديد.

**Production structural change required for this incident = NONE.**

**Owner source change required = vouchers.html فقط، V-304-01..V-304-06.**

---

**Closure Status:**  
`ROOT CAUSE = PROVEN`  
`SURGICAL PATCH = READY`  
`PATCH STATIC PARSE = PASS`  
`PRODUCTION QA = VERIFIED`  
`QA DATA = RETAINED`  
`MAIN.HTML = UNTOUCHED`  
`VAN-SALES = UNTOUCHED`  
`NEW EDGE FUNCTIONS = 0`  
`BROWSER E2E = OPEN`  
`SW DEPLOYMENT ARTIFACT = OPEN`
