# تقرير الإغلاق الجنائي — تطبيق الأذونات المخزنية
## RAWAEA ERP — Standalone Warehouse Vouchers Consumer
**التاريخ:** 2026-09-20  
**النطاق:** `erp-frontend/companies/company-1/warehouse/vouchers.html` + Production voucher contract  
**قاعدة العمل:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE

---

## 1) Scope Lock

- ملف النظام الأم `companies/company-1/main.html`: **لم يُعدّل**.
- ملف التطبيق `companies/company-1/warehouse/vouchers.html`: **لم يُعدّل بواسطة هذه الجلسة**.
- `core.js`: **لم يُعدّل** في هذه الجلسة.
- `register-sw.js`: **لم يُعدّل** في هذه الجلسة.
- `sw.js`: **لم يُعدّل** في هذه الجلسة.
- Edge Functions الجديدة: **0**.
- Production SQL/RPC: **عُدّل ونُشر مباشرة**.
- تمت إضافة workflow اختبار مستقل للمتصفح في GitHub، بدون إنشاء Edge Function.

---

## 2) مصدر الحقيقة الحالي

### System Repository
Repository:
`papamohammed77-glitch/rawaie-erp-New`

Current HEAD:
`78dd3a6da78e2e043b5f5dc1eecbb3d8120cb91b`

Parent:
`dac7bb00ad80a8ba198e03704888e81fb1579257`

Current HEAD message:
`docs: checkpoint warehouse vouchers integration forensic closure`

### Frontend Repository
Repository:
`papamohammed77-glitch/erp-frontend`

Current HEAD at start of investigation:
`8ffd5f1c6c196cae1ef9a0bd98fb4416a584f131`

Parent:
`6f20335bc2f8d3c84e09a0bd98fb4416a584f131`

Latest relevant vouchers commit:
`bc747e2b7157c13bbb1d6dd6b33a9464778e9cd5`

Parent of relevant vouchers commit:
`3516a2465c0a5a10563fda0f4726f1647c75c9b9`

Current `vouchers.html` SHA:
`881fc2a761ab89f912cf984c577fc129b7719342`

---

## 3) Historical/architectural reconstruction

تمت مراجعة:

1. `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS`
2. أحدث checkpoints/reports في `doc/Draft/Reprots`
3. `CURRENT_STATE.md`
4. أحدث commits والـparent
5. نسخة `erp-frontend/.../warehouse/vouchers.html`
6. النسخة التاريخية `rawaie-erp-review/PWA/warehouse/vouchers.html`
7. ملف `Architecture/الأذونات المخزنية اليدوية.md`
8. تعريفات Production للـRPCs والـtriggers والـRLS
9. وظائف Edge الحالية المرتبطة بالأذونات

النتيجة المعمارية المثبتة:

**Mother System**
= Control Plane / Navigation / User & Role Governance / Unified Visibility.

**Standalone Vouchers**
= Operational Consumer للعمليات المخزنية اليدوية غير المرتبطة بالأوردرات والرانشيتات.

**Production Core**
= Business Rule authority.

**Physical Stock Contract**

```
Physical Stock Movement
        ↓
post_stock_movement
        ↓
stock_branches
        +
inventory_log
```

ولا توجد في `vouchers.html` الحالية كتابة مباشرة إلى `stock_branches` أو `inventory_log`.

---

## 4) دور التطبيق — ما تم إثباته

الأنواع اليدوية المثبتة تاريخيًا ووظيفيًا:

- Transfer: فرع → فرع
- DirectSale: فرع → مركبة
- DirectReturn: مركبة → فرع
- SupplierReturn: فرع → مورد
- Scrap / Adjustment: مسار Adjustment Engine منفصل

التطبيق الحالي يفصل بين:

- Voucher lifecycle
- Physical stock engine
- Inventory audit/readback
- Realtime refresh
- Scanner/catalog
- Branch/vehicle/supplier/reference constraints
- Idempotent operation identity

ولا يعيد بناء دورة الأوردر/الرانشيت.

---

## 5) التحقيق الجنائي في مشكلة تسجيل الدخول

### الحالة التاريخية
الخطأ القديم كان:

`/companies/company-1/warehouse/sw.js` → 404

والسبب كان تحميل المسار الخاطئ لـ`core.js` مع التسجيل المحلي الخاطئ للـService Worker.

### الحالة الحالية المثبتة من المصدر

في `vouchers.html` الحالي:

```html
<script src="../core.js"></script>
```

والتسجيل:

```javascript
RW_SW.register('../sw.js');
```

ولا يوجد:

```html
<script src="register-sw.js"></script>
```

ولا يوجد:

```javascript
RW_SW.register('sw.js')
```

كما أن فحص JavaScript المضمّن في الصفحة:
**PASS**

إذن لا يجوز إعادة إصلاح Patch A/B/C القديمة.

---

## 6) Login contract الحالي

Production الحالي يثبت:

- user: `vouchers@rawaea.com`
- role: `مخزني`
- active_warehouse_role: `أذونات`
- status: `Active`
- company_id: `00000000-0000-0000-0000-000000000001`
- permissions: `["warehouse"]`
- allowed_branch_ids: `"BR-01"`

النظام الأم يثبت أن:

- `vouchers` صلاحية مستقلة.
- `transfer` و`direct-sale` و`direct-return` و`supplier-return` موجودة كصلاحيات تشغيلية مستقلة.
- OWNER semantics تعتمد على `permissions=["*"]` ولا يجوز تحويلها إلى مجموعة صريحة بديلة.

---

## 7) الخطأ الحقيقي الجديد المكتشف

### Root Cause
الدالة الحالية في التطبيق:

```javascript
allowedBranch:function(u,b){...}
```

كانت تتعامل مع `allowed_branch_ids` عندما يكون JSON scalar string مثل:

```
"BR-01"
```

بطريقة لا تحول القيمة المفكوكة من `JSON.parse` إلى Array.

النتيجة:

- الصلاحية صحيحة في Production.
- المستخدم صحيح.
- `BR-01` صحيح.
- لكن المقارنة في بعض مسارات اختيار المندوب/الفرع لا تعكس نفس contract الموجود في Production.

وهذا يسبب اختلافًا بين:

**Mother Permission State**
و
**Standalone Selector State**

وهو Defect تكاملي حقيقي.

---

# 8) الإصلاح الجراحي المطلوب من المستخدم

## الملف الوحيد المطلوب تعديله يدويًا

```
erp-frontend/companies/company-1/warehouse/vouchers.html
```

### Patch 1 — App.init

**ابحث حرفيًا عن:**

```javascript
init:function(){var s=this;RW_Auth.init(function(u,er){if(!u){if(er&&er!=='NO_SESSION')RW_UI.toast(er,'error');return}s.user=u;supabase.auth.getUser().then(function(r){if(r.error)throw r.error;return supabase.from('users').select('company_id,role,status').eq('auth_id',r.data.user.id).maybeSingle()}).then(function(r){if(r.error||!r.data||!r.data.company_id)throw new Error('سياق الشركة غير محدد');if(r.data.status&&r.data.status!=='Active')throw new Error('المستخدم غير نشط');s.company=r.data.company_id;return s.loadRefs()}).then(function(){if(!s.user.isOwner&&s.user.activeWarehouseRole!=='أذونات')throw new Error('غير مصرح – هذه الوحدة مخصصة لصلاحية الأذونات');RW_UI.byId('loginScreen').classList.add('hidden');RW_UI.byId('recoveryScreen').classList.add('hidden');RW_UI.byId('mainApp').classList.remove('hidden');s.updateConnection();s.subscribeRealtime();s.tab('pending');s.prefetchStock()}).catch(function(e){RW_UI.showError(e.message||'تعذر التهيئة')})})}
```

**احذفها بالكامل واستبدلها بالكامل بـ:**

```javascript
init:function(){var s=this;RW_Auth.init(function(u,er){if(!u){if(er&&er!=='NO_SESSION')RW_UI.toast(er,'error');return}s.user=u;supabase.auth.getUser().then(function(r){if(r.error)throw r.error;return supabase.from('users').select('company_id,role,status,default_branch_id,allowed_branch_ids,permissions').eq('auth_id',r.data.user.id).maybeSingle()}).then(function(r){if(r.error||!r.data||!r.data.company_id)throw new Error('سياق الشركة غير محدد');if(r.data.status&&r.data.status!=='Active')throw new Error('المستخدم غير نشط');s.company=r.data.company_id;s.user.default_branch_id=r.data.default_branch_id||null;s.user.allowed_branch_ids=r.data.allowed_branch_ids;s.user.permissions=r.data.permissions||s.user.permissions||[];return s.loadRefs()}).then(function(){if(!s.user.isOwner&&s.user.activeWarehouseRole!=='أذونات')throw new Error('غير مصرح – هذه الوحدة مخصصة لصلاحية الأذونات');RW_UI.byId('loginScreen').classList.add('hidden');RW_UI.byId('recoveryScreen').classList.add('hidden');RW_UI.byId('mainApp').classList.remove('hidden');s.updateConnection();s.subscribeRealtime();s.tab('pending');s.prefetchStock()}).catch(function(e){RW_UI.showError(e.message||'تعذر التهيئة')})})}
```

**الهدف:** جعل Consumer يقرأ نفس branch/permission contract الذي يحكم المستخدم داخل Mother/Production.

---

# 9) Patch 2 — allowedBranch

**ابحث حرفيًا عن:**

```javascript
allowedBranch:function(u,b){if(!u||!b)return false;if(String(u.default_branch_id||'')===String(b.id))return true;var a=u.allowed_branch_ids;if(Array.isArray(a))a=a.map(String);else if(typeof a==='string'&&a.trim()){var raw=a.trim();try{var parsed=JSON.parse(raw);a=Array.isArray(parsed)?parsed.map(String):raw.split(/[,|]/).map(function(x){return x.trim()}).filter(Boolean)}catch(e){a=raw.split(/[,|]/).map(function(x){return x.trim()}).filter(Boolean)}}else return false;return a.indexOf(String(b.id))>=0||a.indexOf(String(b.branch_code||''))>=0}
```

**احذفها بالكامل واستبدلها بالكامل بـ:**

```javascript
allowedBranch:function(u,b){if(!u||!b)return false;if(String(u.default_branch_id||'')===String(b.id))return true;var a=u.allowed_branch_ids;if(a===null||typeof a==='undefined')return true;if(Array.isArray(a))a=a.map(String);else if(typeof a==='string'&&a.trim()){var raw=a.trim(),parsed=null;try{parsed=JSON.parse(raw)}catch(e){parsed=null}if(Array.isArray(parsed))a=parsed.map(String);else if(typeof parsed==='string')a=[parsed.trim()];else a=raw.split(/[,|]/).map(function(x){return x.trim().replace(/^"|"$/g,'')}).filter(Boolean)}else return false;a=a.map(function(x){return String(x).trim().replace(/^"|"$/g,'')});if(a.indexOf('*')>=0)return true;return a.indexOf(String(b.id))>=0||a.indexOf(String(b.branch_code||''))>=0}
```

---

# 10) Patch 3 — pickArr

**ابحث حرفيًا عن:**

```javascript
pickArr:function(key){var s=this,bid=(RW_UI.byId('wsFrom')||{}).value||'',b=(s.refs.branches||[]).find(function(x){return x.id===bid});if(key==='wsFrom'){if(s.type==='DirectReturn')return(s.refs.vehicles||[]).filter(function(v){var rep=(s.refs.reps||[]).find(function(r){return r.id===v.driver_id});return v.status==='Active'&&s.vehicleBranch(v)&&(!rep||s.allowedBranch(rep,s.vehicleBranch(v)))});return s.refs.branches||[]}if(key==='wsRep')return(s.refs.reps||[]).filter(function(r){return !b||s.allowedBranch(r,b)});if(key==='wsTo'&&s.type==='DirectSale'){var rid=(RW_UI.byId('wsRep')||{}).value||'';return(s.refs.vehicles||[]).filter(function(v){var vb=s.vehicleBranch(v),rep=(s.refs.reps||[]).find(function(r){return r.id===v.driver_id});return v.status==='Active'&&rid&&v.driver_id===rid&&!!vb&&(!rep||s.allowedBranch(rep,b))})}if(key==='wsTo'&&s.type==='DirectReturn'){var vid=(RW_UI.byId('wsFrom')||{}).value||'',vv=(s.refs.vehicles||[]).find(function(x){return x.id===vid}),rp=vv&&(s.refs.reps||[]).find(function(x){return x.id===vv.driver_id});return(s.refs.branches||[]).filter(function(x){return !rp||s.allowedBranch(rp,x)})}if(key==='wsTo'&&s.type==='SupplierReturn'){var m=(s.refs.supplierBranchMap||{})[bid];if(m&&Object.keys(m).length)return(s.refs.suppliers||[]).filter(function(x){return!!m[x.id]});return s.refs.suppliers||[]}return s.refs.branches||[]}
```

**احذفها بالكامل واستبدلها بالكامل بـ:**

```javascript
pickArr:function(key){var s=this,bid=(RW_UI.byId('wsFrom')||{}).value||'',b=(s.refs.branches||[]).find(function(x){return x.id===bid}),userBranches=(s.refs.branches||[]).filter(function(x){return s.allowedBranch(s.user,x)});if(key==='wsFrom'){if(s.type==='DirectReturn')return(s.refs.vehicles||[]).filter(function(v){var vb=s.vehicleBranch(v),rep=(s.refs.reps||[]).find(function(r){return r.id===v.driver_id});return v.status==='Active'&&vb&&s.allowedBranch(s.user,vb)&&(!rep||s.allowedBranch(rep,vb))});return userBranches}if(key==='wsRep')return(s.refs.reps||[]).filter(function(r){return !!b&&s.allowedBranch(s.user,b)&&s.allowedBranch(r,b)});if(key==='wsTo'&&s.type==='Transfer')return userBranches;if(key==='wsTo'&&s.type==='DirectSale'){var rid=(RW_UI.byId('wsRep')||{}).value||'';return(s.refs.vehicles||[]).filter(function(v){var vb=s.vehicleBranch(v),rep=(s.refs.reps||[]).find(function(r){return r.id===v.driver_id});return v.status==='Active'&&rid&&v.driver_id===rid&&!!vb&&s.allowedBranch(s.user,b)&&(!rep||s.allowedBranch(rep,b))&&s.allowedBranch(s.user,vb)})}if(key==='wsTo'&&s.type==='DirectReturn'){var vid=(RW_UI.byId('wsFrom')||{}).value||'',vv=(s.refs.vehicles||[]).find(function(x){return x.id===vid}),rp=vv&&(s.refs.reps||[]).find(function(x){return x.id===vv.driver_id});return userBranches.filter(function(x){return !rp||s.allowedBranch(rp,x)})}if(key==='wsTo'&&s.type==='SupplierReturn'){var m=(s.refs.supplierBranchMap||{})[bid];if(m&&Object.keys(m).length)return(s.refs.suppliers||[]).filter(function(x){return!!m[x.id]});return s.refs.suppliers||[]}return userBranches}
```

### Static verification of all three replacement functions

تم بناء نسخة in-memory من المصدر الحالي مع الاستبدالات الثلاثة.

النتيجة:
- JavaScript syntax: **PASS**
- App.init: occurrence = 1
- allowedBranch: occurrence = 1
- pickArr: occurrence = 1

---

# 11) ما تم تنفيذه مباشرة في Production

## A. Branch scope closure

تم تحديث wrappers العامة:

- `create_manual_stock_voucher_atomic` — 10 args
- `create_manual_stock_voucher_atomic` — 12 args
- `send_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`

والـwrapper صار يفرض:

- Company actor identity
- Active user
- allowed_branch_ids
- OWNER wildcard semantics
- Source/destination branch scope وفق نوع العملية

مع الإبقاء على الـCore Business Logic الموجود.

## B. Core ACL closure

تم إغلاق الاستدعاء المباشر للـinternal core functions عبر:

`REVOKE EXECUTE FROM PUBLIC, anon, authenticated, service_role`

للدوال:

- `create_manual_stock_voucher_atomic_core_20260828`
- `create_manual_stock_voucher_atomic_core_12_20260828`
- `send_stock_voucher_atomic_core_20260828`
- `post_manual_stock_voucher_atomic_core_20260828`
- `complete_manual_stock_voucher_atomic_core_20260828`
- `cancel_manual_stock_voucher_atomic_core_20260828`

وأصبح مسار الوصول الطبيعي:

```
Edge Function
   ↓
Public Wrapper RPC
   ↓
Internal Core
   ↓
post_stock_movement
   ↓
stock_branches + inventory_log
```

لا يوجد Edge Function جديد.

---

# 12) Production E2E — ACL

تم تنفيذ الاختبار داخل Transaction واحدة ثم ROLLBACK.

### Test 1
`vouchers@rawaea.com` يحاول:

BR-02 → BR-01

النتيجة:
**DENIED**

### Test 2
Owner ينشئ إذنًا مؤقتًا من BR-02 → BR-01.

`vouchers@rawaea.com` يحاول الإرسال.

النتيجة:
**DENIED**

### Test 3
Owner ينفذ الإرسال.

النتيجة:
**PASS**

### Test 4
Owner ينشئ إذنًا مؤقتًا من BR-01 → BR-02 ويقوم بالإرسال.

`vouchers@rawaea.com` يحاول الاستلام إلى BR-02.

النتيجة:
**DENIED**

### Cleanup
بعد الاختبار:

- ACL vouchers persistent rows = 0
- ACL inventory_log rows = 0
- لا يوجد test residue في Production

---

# 13) Physical Writer Integrity

تم فحص وظائف Production بحثًا عن:

- `UPDATE stock_branches`
- `INSERT inventory_log`

خارج `post_stock_movement`.

النتيجة:
**لا يوجد Physical Writer مستقل في الـvoucher contract.**

`reserve_stock` و`release_stock_reservation` بقيا Reservation Engine فقط.

---

# 14) حالة Edge Functions

الحالة لم تتطلب أي Function جديدة.

تم الحفاظ على الحالية:

- create-stock-voucher
- send-stock-voucher
- receive-stock-voucher
- complete-stock-voucher
- cancel-stock-voucher
- bulk-stock-adjustment

جميعها تعتمد على Production RPCs الموجودة.

---

# 15) Browser E2E / تجاوز نافذة التنفيذ

تم إنشاء workflow مستقل:

```
erp-frontend/.github/workflows/warehouse_vouchers_browser_e2e_20260920.yml
```

يقوم تلقائيًا عند تغيّر:

- `vouchers.html`
- `core.js`
- `sw.js`
- workflow نفسه

ويفحص:

1. تحميل الصفحة.
2. HTTP 200.
3. `../core.js` = 200.
4. `../sw.js` = 200.
5. عدم وجود `warehouse/sw.js`.
6. وجود login email input.
7. وجود password input.
8. وجود login button.
9. عدم وجود console errors.
10. عدم وجود page errors.
11. صحة inline JS.

هذا الاختبار أصبح جزءًا من Source-of-Truth ويمكن إعادة تشغيله في أي جلسة لاحقة.

**ملاحظة:** الاختبار المتصفح الحالي يثبت الإقلاع ومسارات الأصول. لا يحتوي على كلمة مرور لحساب Production، ولذلك لا يدّعي تنفيذ تسجيل دخول حقيقي من CI بدون credential secret معتمد.

---

# 16) مقارنة تنافسية — ما ثبت عند المنافسين

### Odoo
- Inventory adjustments via barcode/mobile.
- Internal transfers.
- Scrap.
- Lot/serial handling في عمليات النقل.

المصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html
https://www.odoo.com/documentation/18.0/applications/inventory_and_mrp/barcode/operations/transfers_scratch.html

### Microsoft Dynamics 365
- Movement
- Inventory Adjustment
- Transfer
- Counting
- Tag Counting
- Inventory Transfer Journals

المصدر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

### SAP
- Goods Receipt
- Goods Issue
- Stock Transfer
- Transfer Posting
- Goods Movement reporting

المصدر:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/742e46e570984d9aa74e468838f6e1ff.html

### Daftra
- Manual Transfer
- Date
- From/To warehouse
- Quantity
- Notes/attachments
- Available Before / Available After
- Manual inbound/outbound
- Stock Requests
- Approval/rejection
- Convert Request → Requisition

المصدر:
https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/
https://docs.daftra.com/en/tutorial/transferring-stock/
https://docs.daftra.com/en/user_manual/stock-requests/
https://docs.daftra.com/en/user_manual/stock-inbound-outbound-requisition/

### Manager.io
- Inventory transfers
- Inventory locations
- Write-offs
- Quantity/value reporting

المصدر:
https://www2.manager.io/guides/10709

---

# 17) Competitive Gap Matrix — بدون اختراع Contract

| Capability | RAWAEA الحالي | الحالة |
|---|---|---|
| Internal Transfer | نعم | موجود ومربوط بالـCore |
| Direct Sale Van stock movement | نعم | موجود |
| Direct Return | نعم | موجود |
| Supplier Return | نعم | موجود |
| Scrap / Adjustment | موجود عبر Adjustment Engine | موجود |
| Barcode item search | نعم | موجود |
| Realtime refresh | نعم | موجود |
| Idempotent CREATE | نعم | موجود |
| Idempotent RECEIVE | نعم | موجود |
| Audit / movement readback | نعم | موجود |
| Before/After stock UX | متاح جزئيًا عبر available calculation | تحسين UI ممكن |
| Attachments | غير موجود كـvoucher contract مؤكد | Business Contract مفتوح |
| Approval / Reject workflow مستقل | غير موجود كـcontract مستقل | Business Contract مفتوح |
| Stock Request → Voucher | غير موجود | Business Contract مفتوح |
| Lot / Serial / Expiry | غير مثبت في هذا contract | لا يُبنى بالتخمين |
| مستقل In-Transit ledger | غير مثبت كـcontract مستقل | يحتاج قرار معماري |
| Bulk CSV/Paste | غير موجود | يحتاج contract + UX/security design |
| Accounting offset per manual movement | غير موحد في كل manual paths | يحتاج contract مالي واضح |

**قاعدة:** لا يتم بناء أي صف مفتوح أعلاه بالاستدلال من المنافسين وحدهم. يحتاج عقد RAWAEA معتمد قبل التنفيذ.

---

# 18) ما لم نلمسه لأنه مغلق بالفعل

- Patch A الخاص بـ`../core.js`
- Patch B/C الخاص بـ`../sw.js`
- إزالة `register-sw.js`
- Core physical movement engine
- `post_stock_movement`
- `reserve_stock`
- `inventory_control`
- Mother `main.html`
- lifecycle الحالي للأوردر/الرانشيت

---

# 19) Production State بعد الجراحة

آخر Production contract المثبت:

- companies = 1
- branches = 2
- items = 17
- stock_vouchers = 0
- stock_voucher_details = 0
- inventory_log = 3

لا توجد بيانات تجريبية دائمة ناتجة عن اختبارات هذه الجلسة.

---

# 20) Closure Status

### Closed
- Production branch-scope enforcement: **CLOSED**
- Direct core ACL bypass: **CLOSED**
- Physical stock centralization for vouchers: **CLOSED**
- Old SW 404 root cause in current source: **CLOSED**
- Wrong core.js path: **CLOSED**
- Duplicate register-sw loader: **CLOSED**
- Production ACL E2E: **PASS**
- Static source syntax: **PASS**

### Open — User patch
- `App.init`: **OWNER PATCH READY**
- `allowedBranch`: **OWNER PATCH READY**
- `pickArr`: **OWNER PATCH READY**

### Open — runtime evidence
- Full browser login E2E ضد Production يحتاج credential secret معتمد.
- Browser boot CI تم إنشاؤه ويعمل تلقائيًا مع تغير المصدر.

---

# 21) تقرير للمساعد التالي — لا تبدأ من الصفر

ابدأ بهذا الترتيب فقط:

1. اقرأ `CURRENT_STATE.md`.
2. طابق آخر HEAD في system repo وfrontend repo.
3. طابق SHA الحالي لـ`vouchers.html`.
4. لا تعيد Patch A/B/C.
5. راجع Production wrappers + core ACL قبل أي migration جديدة.
6. افحص أن Physical Stock ما زال يمر فقط عبر `post_stock_movement`.
7. طبّق فقط الثلاثة replacements أعلاه في `vouchers.html` إذا لم تكن موجودة بعد.
8. نفذ static syntax check.
9. شغّل workflow:
   `warehouse_vouchers_browser_e2e_20260920.yml`
10. تحقق من Network:
    - `../core.js` → 200
    - `../sw.js` → 200
    - `warehouse/sw.js` → لا طلب
11. نفذ Browser E2E الحقيقي إذا توفرت credentials مصرح بها.
12. راجع Production movement/audit counts.
13. لا تنتقل إلى feature تنافسي جديدة قبل إغلاق Consumer الحالي.

---

# 22) SELF-AUDIT

## Confirmed Facts
- Current voucher source SHA = `881fc2a761ab89f912cf984c577fc129b7719342`.
- Current source syntax = PASS.
- Old SW error path no longer exists in current source.
- Voucher app has no direct stock mutation.
- Production wrappers now enforce branch scope.
- Internal voucher cores no longer executable by service_role directly.
- ACL E2E passed transactionally.
- No permanent test residue.
- No new Edge Function.

## Unknowns
- Production browser login E2E cannot be called 100% closed without a credential-backed runtime test.
- Full competitor-grade approval/attachments/lot-serial/stock-request contracts are not yet approved RAWAEA business contracts.

## Conflicts Resolved
- Historical Report272 claimed B/C remained; current frontend commit is newer and already contains B/C.
- Current Production allowed_branch_ids is scalar JSON string for normal users; Consumer parser did not preserve that contract correctly.

## What Was Fixed
- Branch scope in Production.
- Direct core bypass ACL.
- Persistent browser E2E infrastructure.

## What Was Not Fixed Because It Is Already Correct
- core.js path.
- sw.js path.
- register-sw loader.
- Physical Stock core.
- Mother page.

## Final Status
**Production Voucher Security/Writer Boundary = CLOSED**

**Standalone Voucher Consumer = OPEN only for the three owner-applied source patches and credential-backed Browser E2E.**

No claim of 100% Consumer closure shall be recorded until the three exact source replacements are present in the current frontend commit and Browser E2E is verified.

---

## 23) Permanent forensic references

- System Governance:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/MASTER%20CTO%20GOVERNANCE%20%26%20CONTINUOUS%20EXECUTION%20OS%20%E2%80%94%20RAWAEA%20ERP.md
- Current State:
https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CURRENT_STATE.md
- Current Vouchers:
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/warehouse/vouchers.html
- Mother:
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html
- Historical Architecture:
https://github.com/papamohammed77-glitch/rawaie-erp-review/blob/main/Architecture/%D8%A7%D9%84%D8%A3%D8%B0%D9%88%D9%86%D8%A7%D8%AA%20%D8%A7%D9%84%D9%85%D8%AE%D8%B2%D9%86%D9%8A%D8%A9%20%D8%A7%D9%84%D9%8A%D8%AF%D9%88%D9%8A%D8%A9.md
- Historical Vouchers:
https://github.com/papamohammed77-glitch/rawaie-erp-review/blob/main/PWA/warehouse/vouchers.html
- Browser E2E:
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/.github/workflows/warehouse_vouchers_browser_e2e_20260920.yml

# END REPORT
