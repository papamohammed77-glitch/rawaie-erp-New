# Report509 — التحقيق الجنائي لتكامل مشرف التوصيل مع النظام الأم والتطبيقات التشغيلية

**وقت المطابقة الحية:** 2026-10-26 16:31 UTC  
**الحالة:** `PARTIAL — ROOT CAUSE CONFIRMED / CROSS-LAYER CONTRACT NOT CLOSED / NO BUSINESS DATA MUTATED`  
**Production project:** `fiilmooggumokxanwiyx` (SMART ERP)  
**Operational repository:** `papamohammed77-glitch/erp-frontend`, branch `main`  
**Documentation repository:** `papamohammed77-glitch/rawaie-erp-New`, branch `main`  
**نطاق المهمة:** تكامل تطبيق مشرف التوصيل مع النظام الأم، Fleet/Runsheets، تطبيق مندوب التوصيل، Edge/Core/PostgreSQL، مع الفصل بين السائق ومندوب التوصيل.

> هذه المهمة لا تُغلق بتبديل `driver_id` إلى `deliverer_id` في واجهة واحدة. يجب أن يتفق التعيين، وقراءة الرانشيت، وبدء الرحلة، وإتمامها، والتسجيل المحاسبي/التشغيلي على هوية واحدة ودورة حالة واحدة.

---

## 1. PRE-CHANGE SELF-AUDIT

| المجال | التقدير المدعوم | سبب التقدير |
|---|---:|---|
| Business Understanding | 97/100 | توثيق المالك يفصل بين Driver وDelivery Representative؛ Production schema تحتوي حقلي `driver_id` و`deliverer_id` منفصلين. |
| Architecture Understanding | 95/100 | ثبت وجود Parent/Fleet command، تطبيق مشرف منفصل، تطبيق مندوب، Core، Edge وRPCs. |
| Database Understanding | 96/100 للنطاق المفحوص | تمت قراءة schema الحية لـrunsheets/vehicles/delivery_agents، RLS، تعريفات RPC، ACL وtriggers ذات الصلة. |
| Historical Understanding | 88/100 | تمت قراءة CURRENT_STATE وReport508 وwriting-block والبرومبت التشغيلي؛ لم تكتمل ancestry لكل Function/كل migration. |
| Production Understanding | 97/100 للحقائق المدرجة | استعلامات مباشرة في Production عند 16:27 و16:31 UTC؛ Edge registry/source جُلب مباشرة. |
| Consumer Trace | 86/100 | تتبع مشرف التوصيل، Parent Fleet assignment، وواجهات Edge الخاصة بالمندوب؛ لم يكتمل فحص جميع consumers غير المباشرين والـserved HTML. |
| Execution Confidence | 95/100 للتشخيص؛ 0% لإثبات E2E ناجح | لم يُنفذ HTTP/Browser E2E مصادق عليه؛ لا يوجد ادعاء نجاح Runtime. |

### حالة الأدلة

- **CONFIRMED:** واجهة المشرف تكتب إلى `runsheets.driver_id` مباشرة؛ Parent Fleet يستخدم `fleet_command_atomic('RUNSHEET_ASSIGN')` لتعيين المركبة والسائق قبل التحميل؛ RPC الحي يرفض تعديل الرانشيت في حالة `Loaded`؛ واجهة المندوب وEdge الحالية تعتمد على `driver_id`؛ RLS لا تمنح صلاحية `delivery_supervisor` وحدها حق الكتابة المباشرة على runsheets.
- **UNKNOWN:** تطابق HTML الذي يقدمه Cloudflare مع Blob الحالي؛ نتائج Browser E2E مصادق عليه؛ اكتمال Git→deployed Edge provenance لكل الدوال.
- **CONFLICT:** العقد الذي يطلبه المالك يفرق بين Driver وDelivery Representative، بينما مشرف التوصيل الحالي يستخدم `driver_id` لتمثيل مندوب التوصيل.
- **UNVERIFIED:** لم يثبت أن المسار المتكامل يعمل حاليًا end-to-end، ولم يُنشر أي إصلاح في هذه الدورة.

### المصادر التي فُتحت

- `CURRENT_STATE.md` كاملًا: LVE-508 هو آخر حدث مثبت قبل هذه الدورة.
- `doc/Draft/Reprots/Report508_DELIVERY_SUPERVISOR_DRIVER_INTEGRATION_FORENSIC_20261026.md`.
- `doc/Draft/Reprots/writing-block.md` كاملًا، بما فيه وحدة المهمة التنفيذية النهائية؛ المهمة الثابتة داخله تخص Loader/Picker، لكن تكليف المالك الأحدث في المحادثة حدد Delivery Supervisor، لذا اتُّبع النطاق الأحدث ولم يُعدّل Loader/Picker.
- `erp-frontend/companies/company-1/delivery/supervisor.html` — Blob `4108d2330e567c432f08197013b9c3cf6221a5c7`.
- `erp-frontend/companies/company-1/delivery/driver.html` — Blob `2df69860184f5a7c1b211ba059e1d6f57826c96b`.
- `erp-frontend/companies/company-1/core.js` — Blob `ff2f581d9900543c16f7cb026e13446520c0329d`.
- `erp-frontend/companies/company-1/main.html` — جُلب عبر Git blob SHA `11f29e07c10ae1767db334fe101c382eca23bd00` (1,785,871 حرفًا؛ الملف كبير ولا يُدّعى أن كل نطاقاته قُرئت line-by-line).
- Production: PostgreSQL schema/functions/RLS/ACL/triggers/rows، Edge registry، وdeployed source للدوال المذكورة أدناه.
- `CURRENT_STATE.md` قبل التحديث كان Blob SHA `1930c9261f94a0105b717088d43b92d687626ecf`.

---

## 2. LIVE PRODUCTION SNAPSHOT

**آخر وقت SQL مباشر في هذه الدورة:** `2026-10-26 16:31:11.405051+00`.

### 2.1 الرانشيتات الحالية

| Runsheet | Status | `vehicle_id` | `driver_id` | `deliverer_id` | Company |
|---|---|---|---|---|---|
| RS-1 | Loaded | موجود | NULL | NULL | `00000000-0000-0000-0000-000000000001` |
| RS-2 | Loaded | موجود | NULL | NULL | `00000000-0000-0000-0000-000000000001` |

لم تُستخدم RS-1 أو RS-2 كـfixtures ولم تتغير أي بيانات أعمال. وجود `vehicle_id` مع `driver_id=NULL` في هذه اللقطة لا يثبت وجود تعيين سائق مكتمل؛ لا يجوز افتراض ذلك.

### 2.2 عقد المخطط الحي

- `public.runsheets` يحتوي `driver_id uuid`, `vehicle_id uuid`, `deliverer_id uuid`, ومراحل `picker/loader/delivery`.
- `public.vehicles` يحتوي `driver_id`, `fleet_driver_id`, `mobile_branch_id` وغيرها من بيانات المركبة.
- `public.users` لا يحتوي عمود `vehicle_id`؛ استعلام سابق حاول قراءته ورُفض من PostgreSQL برسالة `column "vehicle_id" does not exist`. لذلك لا يجوز بناء علاقة السائق بالمركبة على `users.vehicle_id`.
- مستخدم المشرف الحي `driver.supervisor@rawaea.com` له `delivery_supervisor`, `customers`, `runsheets`.
- مستخدمو المندوبين في العينة لهم `permissions=["delivery"]` وحالتهم Active.
- RLS على `runsheets` تتطلب صلاحية `runsheets` للقراءة/التحديث، ولا تمنح `delivery_supervisor` وحدها حق SELECT/UPDATE المباشر.
- Trigger `trg_audit_runsheets` يعمل على INSERT/UPDATE/DELETE في `runsheets`.
- `manage_runsheet_atomic(uuid,text,text,text,uuid,uuid)` هو `SECURITY DEFINER` وACL الحالي `postgres, service_role` فقط؛ يقبل UPDATE على `Open/Confirmed` فقط. لا يصلح لإسناد مندوب إلى `Loaded` كما هو.

### 2.3 Edge Production Registry — قراءة مباشرة

كل الوظائف التالية ظهرت `ACTIVE` و`verify_jwt=true` في registry الحالي:

| Edge | Version | `ezbr_sha256` |
|---|---:|---|
| `start-delivery` | 7 | `7e87dd0a29d57d3d286c19e05aed70c8b40c7e74645fc73f593e6eee2610399e` |
| `complete-delivery` | 4 | `9510e7ef441d3b1256f860c775094c43f5102381488580d99601b26c1b482753` |
| `complete-order-delivery` | 14 | `15c67bde52401897fc0ccc4156670fd5cdc026152617401aabca232c1b046fb2` |
| `get-driver-dashboard` | 1 | `59f6bbd39fb8331109966c312fda3327077f17cceda8d9b4b1c9a1c6f652f58e` |
| `force-unassign-runsheet` | 1 | `4fec814c60d3899ba12b1a6f7af07228a954cf56fe3ce0eb617abdeb8af514b9` |
| `manage-runsheet` | 1 | `c065bcec8e5d8fc432ea04fc6f2c0e4fb3bdea4f4ed9f64cf401ecab4ccf6891` |

هذه digests من Registry وليست Git SHAs. لا توجد مطابقة byte-for-byte مع HTML المنشور على Cloudflare.

---

## 3. Consumer Trace — المسار الفعلي

### 3.1 النظام الأم / Fleet

في `main.html`، أمر Parent الحالي:

```js
await command('RUNSHEET_ASSIGN', {
  runsheet_id: p.runsheet.id,
  vehicle_id: val('fa-vehicle'),
  driver_user_id: val('fa-driver') || null,
  fleet_driver_id: chosenDriver.id || null
});
```

ويستدعي `fleet_command_atomic`. فرع `RUNSHEET_ASSIGN`:
- يقفل الرانشيت والمركبة.
- يرفض الحالات غير `Open/Confirmed`.
- يتحقق من الشركة والمركبة والسائق الإداري.
- يراجع السعة الوزنية والحجم.
- يستدعي `manage_runsheet_atomic` لتعيين `runsheets.driver_id` و`runsheets.vehicle_id`.

**المعنى:** هذا مسار تعيين المركبة والسائق للرانشيت قبل/أثناء التخطيط الأولي. لا يجوز إعادة استخدامه مباشرةً لتعيين مندوب إلى رانشيت محمّل؛ شرط الحالة سيمنع ذلك، كما أن تغيير `driver_id` سيخلط الوظيفتين.

### 3.2 تطبيق مشرف التوصيل

الملف الحالي `supervisor.html` يفعل الآتي:
- `init()`: يسمح للمالك أو `delivery_supervisor` بالدخول.
- `renderDashboard()`: يقرأ `runsheets` و`users` مباشرةً، ولا يعالج كل أخطاء الاستعلام بوضوح.
- `renderTeam()`: يجلب المستخدمين أصحاب `delivery` ويحسب الأداء من `runsheets.driver_id`.
- `openAssignModal()`: يعرض الرانشيتات `Loaded` التي `driver_id IS NULL`.
- `assignDriver()`: يقرأ المستخدم بالبريد ثم يكتب `runsheets.driver_id` مباشرة.
- `unassignDriver()`: يكتب `driver_id=NULL,status='Loaded'` مباشرة، دون تحقق من حالة الرانشيت أو نطاق الشركة.
- `forceUnassign()`: يستدعي Edge موجودة، لكن Edge نفسها لا تفرض company/permission scope كما ينبغي.

**النتيجة:** الخلل ليس UI فقط؛ المسار الحالي يناقض RLS ويستخدم عمود هوية غير صحيح للوظيفة المطلوبة.

### 3.3 تطبيق مندوب التوصيل

`driver.html` هو فعليًا تطبيق **مندوب التوصيل**، لكنه وبعض Endpoints لا يزالون يستخدمون `driver_id`:
- `get-driver-dashboard v1` يقرأ المستخدم بالبريد، ويطلب من `runsheets` `runsheet_code,status,run_date,vehicle_id,delivery_start,total_amount` دون `id`، ثم يستخدم `activeRS.id` لجلب الطلبات والتفاصيل. هذا خطأ مثبت.
- `start-delivery v7` يحدد المستخدم بالبريد ثم يشترط `runsheets.driver_id = public.users.id`، ولا يفرض صراحةً permission `delivery`.
- `complete-delivery v4` لا يتحقق أن المنفذ هو المندوب المعيّن للرانشيت.
- `complete-order-delivery v14` يربط المستخدم بـ`auth_id`، لكنه لا يتحقق في Edge من `deliverer_id` أو حالة `Delivering` قبل استدعاء RPC؛ وCore `complete_order_delivery_atomic` لا يستقبل actor user id ولا يفرض التعيين داخل المعاملة.
- `force-unassign-runsheet v1` يبحث عن المستخدم بالبريد، ويقرأ الرانشيت بالكود فقط دون company scope، ويحدث الرانشيت بالـid فقط، ويمسح `driver_id` لا `deliverer_id`.
- تتبع العداد في `start-delivery/complete-delivery` يستخدم معرف مندوب التطبيق كـ`vehicle_tracking.driver_id`؛ هذا يحتاج ربطًا واضحًا بسائق المركبة المعيّن في Parent قبل اعتماده.

### 3.4 العقد المستهدف

```
Parent / Fleet:
  runsheets.vehicle_id + runsheets.driver_id
  = المركبة والسائق المرتبطان بالرانشيت

Delivery Supervisor:
  runsheets.deliverer_id
  = مندوب التوصيل المعيّن للرانشيت

Delivery App:
  المصادقة → public.users.auth_id → public.users.id
  → runsheets.company_id + deliverer_id + status
  → Edge/Core/DB
```

يسمح هذا العقد للشركة بإسناد الشخص نفسه للدورين إذا كان تسجيله/صلاحياته يدعم ذلك، أو إسناد سائق ومندوب مختلفين، دون الكتابة فوق هوية السائق أو المركبة.

---

## 4. ROOT CAUSE

**السبب الجذري المثبت:** تطبيق مشرف التوصيل بُني على نموذج أقدم يعتبر مندوب التوصيل هو `runsheets.driver_id`، بينما النظام الأم/Fleet الحالي فصل السائق التشغيلي والمركبة عن مندوب التوصيل، ويوجد بالفعل حقل `runsheets.deliverer_id`. وُضعت مسؤولية إسناد الرانشيت المحمّل على كتابة مباشرة في PWA، في حين أن RLS تمنع هذا المسار للمشرف وحده. وفي المقابل، تطبيق المندوب وEdge ما زالت تعتمد على `driver_id`، لذلك إصلاح المشرف وحده سيُنشئ حالة يراها المشرف ولا يراها تطبيق المندوب.

### فرضيات مستبعدة

- **ليس مجرد خلل عرض:** لأن RLS وRPC الحي يثبتان أن القراءة/الكتابة المباشرة لا تمثل عقدًا صالحًا.
- **ليس نقصًا في عمود قاعدة البيانات:** `deliverer_id` موجود بالفعل.
- **ليس آمنًا إعادة استخدام `manage_runsheet_atomic` أو `RUNSHEET_ASSIGN`:** كلاهما مرتبط بحالات `Open/Confirmed` وتعيين المركبة/السائق.
- **لا دليل على تلف بيانات Production:** لم تُجرَ أي كتابة أعمال في هذه الدورة.
- **لا يمكن اعتبار نجاح تحميل صفحة المشرف دليلًا على نجاح التعيين أو وصول الرانشيت إلى المندوب.**

---

## 5. LOSS / GAIN / RESPONSIBILITY MATRIX

| المسؤولية | الحالة | الدليل |
|---|---|---|
| تعيين المركبة من Parent | RETAINED | `RUNSHEET_ASSIGN` يكتب `vehicle_id` عبر Fleet Core. |
| تعيين السائق للرانشيت من Parent | RETAINED | `fleet_command_atomic` يمرر `driver_user_id` إلى `manage_runsheet_atomic` الذي يكتب `driver_id`. |
| تعيين مندوب التوصيل بعد التحميل | MISSING | لا يوجد فرع `RUNSHEET_ASSIGN_DELIVERER` في `delivery_logistics_command_atomic`; المشرف يكتب مباشرةً إلى العمود الخطأ. |
| قراءة لوحة المشرف تحت RLS | CONFLICT | direct SELECT لا يطابق صلاحية `delivery_supervisor` وحدها. |
| إسناد `Loaded` ذريًا | MISSING | `manage_runsheet_atomic` يرفض `Loaded`. |
| إلغاء إسناد المندوب دون تغيير حالة الرحلة | MISSING | UI الحالي يمسح `driver_id` ويعيد الحالة إلى `Loaded`. |
| تحميل المندوب لرانشيت معيّن | CONFLICT | Edge/driver app تعتمد على `driver_id` لا `deliverer_id`. |
| بدء/إنهاء الرحلة من المندوب المعيّن فقط | MISSING | `complete-delivery` لا يفرض التعيين؛ `start-delivery` يستخدم العمود الخطأ بالنسبة للعقد المطلوب. |
| عزل الشركة في كل عمليات المشرف | CONFLICT | direct writes و`force-unassign-runsheet` لا تضمن scope كاملًا. |
| vehicle/driver tracking | CONFLICT | يجب أن يعكس معرف السائق الفعلي للمركبة، لا معرف مندوب التطبيق تلقائيًا. |
| أثر المخزون | RETAINED / MUST NOT CHANGE | التعيين لا يغير `stock_branches.qty`, `allocated_qty`, `inventory_log`. |
| أثر مالي | RETAINED / MUST NOT CHANGE | لا ينشئ التعيين قيدًا أو تحصيلًا ماليًا. |

---

## 6. إصلاحات الواجهة المطلوبة من المالك — PROPOSED ONLY

**لا تطبق الرقع التالية قبل نشر واختبار عقد Backend الخاص بتعيين `deliverer_id`.** سبب هذا الترتيب أن استدعاء RPC غير موجود بعد لن يعمل، وتبديل العمود وحده سيقطع اتصال التطبيق الميداني.

### Patch S1 — ملف المشرف: `assignDriver`

- **المستودع/الفرع:** `papamohammed77-glitch/erp-frontend` / `main`
- **المسار:** `companies/company-1/delivery/supervisor.html`
- **Blob SHA:** `4108d2330e567c432f08197013b9c3cf6221a5c7`
- **محدد البحث الفريد:** `assignDriver: function(runsheetCode,driverEmail){`
- **الإجراء:** استبدل جسم الدالة فقط باستدعاء RPC مركزي `delivery_logistics_command_atomic` بعد إضافة فرع `RUNSHEET_ASSIGN_DELIVERER` في DB.
- **النص البديل الكامل للجسم:**

```js
assignDriver: function(runsheetCode,driverEmail){
    var self=this;
    var target=(this.driversList||[]).filter(function(u){return String(u.email).toLowerCase()===String(driverEmail).toLowerCase();})[0];
    if(!target||!target.id){RW_UI.toast('مندوب التوصيل غير موجود','error');return;}
    var operationId='DELIVERER_ASSIGN:'+String(runsheetCode)+':'+String(target.id)+':'+String(Date.now());
    Swal.showLoading();
    supabase.rpc('delivery_logistics_command_atomic',{
        p_company_id:self.currentUser.company_id,
        p_command:'RUNSHEET_ASSIGN_DELIVERER',
        p_payload:{runsheet_code:runsheetCode,deliverer_user_id:target.id},
        p_operation_id:operationId,
        p_actor_user_id:null,
        p_actor_email:self.currentUser.email
    }).then(function(res){
        Swal.close();
        if(res.error||!res.data||res.data.success===false){
            throw new Error((res.data&&(res.data.msg||res.data.message))||(res.error&&res.error.message)||'فشل تعيين مندوب التوصيل');
        }
        RW_UI.toast('تم تعيين مندوب التوصيل بنجاح','success');
        self.renderRunsheets();
        self.renderTeam();
    }).catch(function(err){Swal.close();RW_UI.toast(err.message||'فشل التعيين','error');});
},
```

**ملاحظة:** يعتمد هذا النص على `this.driversList` المحتوية على `id,email` كما يعرضها `renderTeam`. يجب أن يتأكد Patch S2 من تحميلها تحت عقد قراءة Backend مصادق عليه، لأن القراءة المباشرة الحالية تصطدم بـRLS.

### Patch S2 — ملف المشرف: مصدر قائمة الرانشيتات

- **محدد البحث:** `supabase.from('runsheets').select('runsheet_code,run_date,total_amount').eq('status','Loaded').is('driver_id',null)`
- **التعديل المطلوب:** لا تستبدل `driver_id` بـ`deliverer_id` مع إبقاء direct SELECT. يجب تحويل قراءة الرانشيتات المحمّلة إلى endpoint/RPC مقيّد بصلاحية `delivery_supervisor` ونطاق الشركة، يعيد فقط `runsheet_code,run_date,total_amount,deliverer_id`، ويعرض `Loaded AND deliverer_id IS NULL` للتعيين الجديد.
- **الحالة:** PROPOSED؛ يحتاج عقد قراءة backend قبل النص النهائي؛ لا يوجد endpoint آمن حاليًا مثبت لهذا الاستعلام.

### Patch S3 — ملف المشرف: فك الإسناد العادي

- **محدد البحث:** `unassignDriver: function(runsheetCode){`
- **التعديل:** استبدل الكتابة المباشرة `update({driver_id:null,status:'Loaded'})` باستدعاء نفس RPC المركزي مع `p_command:'RUNSHEET_ASSIGN_DELIVERER'` و`p_payload:{runsheet_code:runsheetCode,deliverer_user_id:null}`.
- **شرط backend:** السماح بفك إسناد `deliverer_id` فقط عندما تكون الحالة `Loaded`; رفض `Delivering/Delivered/Returning` في المسار العادي. لا تغير `driver_id`, `vehicle_id`, `status`, أو مراحل التسليم.
- **الحالة:** PROPOSED؛ لا تطبق قبل نشر عقد RPC.

### Patch S4 — فريق المشرف وإحصاءاته

- **محدد البحث:** `var driver=rs.driver_id||'';`
- **التعديل:** بعد توفير قراءة آمنة ومقيدة للشركة، تُحسب إحصاءات مندوبي التوصيل باستخدام `deliverer_id`، وتُسمّى الواجهة «مناديب التوصيل» لا «السائقين». لا تُغيّر أسماء أو بيانات السائقين في Parent/Fleet.
- **الحالة:** PROPOSED؛ يعتمد على RPC read model لم يُثبت وجوده.

---

## 7. تغييرات Backend اللازمة قبل تطبيق رقع الواجهة

### B1 — تعيين مندوب إلى Loaded runsheet

العقد المطلوب: فرع جديد في RPC موجود `delivery_logistics_command_atomic` باسم `RUNSHEET_ASSIGN_DELIVERER`، وليس Edge Function جديدة. يجب أن يقوم الفرع داخل معاملة واحدة بما يلي:

1. الاعتماد على `auth.uid() → public.users.auth_id`، والتحقق من `company_id` و`status='Active'` وصلاحية `delivery_supervisor` أو owner wildcard المعتمد.
2. التحقق من `p_operation_id` وتثبيت idempotency payload كما تفعل الدالة الحالية.
3. قفل الرانشيت `FOR UPDATE` داخل الشركة، والتحقق أن `status='Loaded'`.
4. التحقق أن `deliverer_user_id` ينتمي للشركة، Active، وله `delivery` أو دور توصيل موثق؛ السماح بـNULL لفك الإسناد فقط في حالة Loaded.
5. تحديث `runsheets.deliverer_id` وحده؛ لا يكتب `driver_id` أو `vehicle_id` ولا يغير status أو inventory.
6. إرجاع النتيجة وتسجيل التدقيق من خلال آلية audit الحالية.
7. قصر ACL على `authenticated/service_role` بحسب نمط RPC الحالي؛ لا تمنح anon EXECUTE.

**لم أنفذ هذا التغيير في Production.** بيئة `rawaea-staging` كانت `INACTIVE`; أُرسل أمر restore بنجاح، لكن اتصال قاعدة بيانات Staging ظل غير متاح في المحاولتين التاليتين (`Database is possibly not accessible at the moment`). لم أطبّق DDL غير مختبر في Production ولم أكتب بيانات أعمال. هذا قرار سلامة، وليس ادعاء أن المهمة مغلقة.

### B2 — قراءة مشرف التوصيل

يجب توفير قراءة آمنة لبيانات الفريق والرانشيتات عبر RPC موجود أو endpoint قائم بعد إثبات صلاحياته، بدل direct SELECT المتعارض مع RLS. لا توسع RLS العامة على `runsheets/users` ولا تمنح المشرف صلاحية إدارية واسعة لمجرد جعل الواجهة تعمل.

### B3 — تطبيق المندوب والـEdge

يلزم عقد موحد:
- `get-driver-dashboard`: استخدام `auth_id` بدل البريد، تضمين `id` في SELECT، واستخدام `deliverer_id` لاسترجاع الرانشيت.
- `start-delivery`: التحقق من `delivery`، الشركة، `status='Loaded'` و`deliverer_id=public.users.id` قبل انتقال مشروط ذريًا إلى Delivering.
- `complete-delivery`: التحقق من هوية المندوب المعيّن وحالة Delivering والشركة؛ لا يكفي التحقق من الحالة فقط.
- `complete-order-delivery` و`complete_order_delivery_atomic`: يجب أن يتحقق العقد المركزي من actor assignment/status داخل المعاملة، لا في UI فقط ولا في Edge منفردة فقط.
- `force-unassign-runsheet`: يجب التحقق من `auth_id`, `delivery_supervisor`, الشركة، الحالة والتعيين؛ قفل الرانشيت، والحفاظ على الكميات المسلّمة، ومسح `deliverer_id` فقط. لا يمسح `driver_id` ولا يعيد الحالة إلا وفق سياسة lifecycle المعتمدة.
- `vehicle_tracking.driver_id`: يجب أن يعكس سائق المركبة/الرانشيت الحقيقي، لا مندوب التطبيق افتراضيًا.
- لا تنشئ Edge Function جديدة؛ استخدم الدوال القائمة أو RPC مركزيًا.

**لا أنشر هذه التغييرات قبل وجود Staging صالح واختبارات على Fixture معزول.** نشر التعيين دون تحديث consumers سيؤدي إلى أن يعيّن المشرف `deliverer_id` بينما لا يجد تطبيق المندوب الرانشيت.

---

## 8. اختبار التكامل — مصفوفة النتائج

| الاختبار | النتيجة | الدليل |
|---|---|---|
| قراءة schema الحية وفصل driver/deliverer | PASS | `runsheets` يحوي العمودين؛ `vehicles` يحوي driver/fleet driver fields. |
| قراءة RLS للرانشيتات والمستخدمين | PASS | السياسات الحية لا تسمح للمشرف وحده بالـdirect writes المطلوبة. |
| Parent Fleet assignment trace | PASS | `RUNSHEET_ASSIGN → fleet_command_atomic → manage_runsheet_atomic`; يعمل في Open/Confirmed فقط. |
| تحديد أن Parent command لا يصلح لتعيين مندوب بعد Loading | PASS | شرط `manage_runsheet_atomic` يرفض حالات غير Open/Confirmed. |
| التحقق من وجود `deliverer_id` في Production | PASS | عمود حي موجود، ولا حاجة لإنشاء عمود جديد. |
| اكتشاف direct DB writes في supervisor.html | PASS | `assignDriver` و`unassignDriver` يكتبان `driver_id/status` مباشرة. |
| اكتشاف missing id في get-driver-dashboard select | PASS | المصدر المنشور لا يحدد `id` ثم يستخدم `activeRS.id`. |
| Authenticated supervisor HTTP E2E | NOT RUN | Staging غير متاح، وProduction runsheets ليست fixtures. |
| Driver HTTP E2E: assignment → start → order delivery → complete | NOT RUN | لا يوجد Fixture معزول متاح، ولم تُجرَ كتابة أعمال. |
| Concurrency / duplicate / wrong-company / wrong-representative | NOT RUN | يتطلب عقد assignment وإعداد بيئة اختبار صالحة. |
| Cloudflare served HTML parity | UNVERIFIED | لا توجد نسخة HTML منشورة جرى جلبها ومطابقتها byte-for-byte. |
| Baseline restoration / fixture cleanup | NOT APPLICABLE | لم تُنشأ fixtures ولم تتغير بيانات أعمال. |
| Production deploy of repairs | NOT RUN | لم تُنشر إصلاحات في هذه الدورة. |

### اختبار التكامل لا يثبت الإغلاق

التحقيق أثبت سبب الانقطاع والعقود المتعارضة، لكنه لم يثبت نجاح المسار التشغيلي. لا يوجد ادعاء `VERIFIED` أو `CLOSED` للتكامل النهائي.

---

## 9. Benchmark — المبدأ الصناعي

المقارنة مع الوثائق الرسمية لـSAP Transportation Management تدعم فصل موارد المركبات والسائقين عن مستند/طلب النقل، وتسمح بإسناد السائق إلى مورد المركبة أو أمر الشحن، مع التحقق من صلاحية السائق وتوافره وعدم تداخل تكليفاته. كما تميز عملية تنفيذ النقل بين تخطيط الرحلة، تحميل الشاحنة، مغادرة الموقع، وتتبع التنفيذ. لا يعني ذلك نسخ نموذج SAP حرفيًا؛ المبدأ المستقر المتوافق مع RAWAEA هو فصل:
1. **Vehicle** — أصل/مورد نقل.
2. **Driver** — مسؤول القيادة، مرتبط بالمركبة/الرانشيت من Parent.
3. **Delivery Representative** — مسؤول العملاء والبضاعة والتحصيل والمرتجعات، مرتبط بالرانشيت من تطبيق المشرف.
4. **Runsheet execution** — سجل مركزي يربط المورد والسائق والمندوب وحالة التنفيذ.

المراجع:
- SAP Help Portal, “Use of Drivers in Freight Order Management”: https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e3dc5400c1cc41d1bc0ae0e7fd9aa5a2/f494ff5544367b43e10000000a4450e5.html
- SAP Learning, “Planning Interactively / Driver Management”: https://learning.sap.com/courses/business-processes-in-sap-s-4hana-transportation-management/planning-interactively_f95c171e-e105-4ec0-90b7-cfce1959ffc8
- SAP Help Portal, “Creation and Editing of Freight Orders” (2025 FPS02, Oct 2026): https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e3dc5400c1cc41d1bc0ae0e7fd9aa5a2/14a4c6617d904a3686f5c00ba9b40e54.html

---

## 10. Mutation Ledger

| الأصل | ما حدث | الحالة |
|---|---|---|
| Production business data | لم تُجرَ INSERT/UPDATE/DELETE | UNCHANGED |
| Production schema/functions | لم تُعدّل | UNCHANGED |
| Production Edge deployments | لم تُنشر | UNCHANGED |
| Operational `supervisor.html` / `driver.html` / `core.js` | قراءة فقط | UNCHANGED |
| Parent `main.html` | قراءة عبر Git blob فقط | UNCHANGED |
| Staging project | أُرسل restore؛ قاعدة البيانات لم تصبح متاحة في هذه الدورة | RESTORE REQUESTED / CONNECTIVITY UNVERIFIED |
| Documentation repo | سيتم حفظ هذا التقرير وتحديث CURRENT_STATE فقط | DOCUMENTATION MUTATION |

---

## 11. المخاطر المفتوحة وإجراء الإغلاق

1. **OPEN — Atomic Loaded assignment:** تجهيز migration لتوسيع `delivery_logistics_command_atomic` بفرع `RUNSHEET_ASSIGN_DELIVERER`; اختباره على Staging أولًا، ثم Production verification.
2. **OPEN — Safe supervisor reads:** استخدام RPC/endpoint مقيد بالشركة والصلاحية بدل direct table reads.
3. **OPEN — Consumer parity:** تحديث `supervisor.html`, `driver.html`, والدوال القائمة لتستهلك `deliverer_id` مع الحفاظ على `driver_id/vehicle_id` من Parent.
4. **OPEN — Security:** إصلاح force-unassign وفرض assigned-representative checks في start/complete/order-delivery.
5. **OPEN — Runtime E2E:** سيناريو معزول: Loaded runsheet + vehicle/driver من Parent + delivery rep من Supervisor → start → per-order outcomes → complete → verify stock unchanged and ledger only changes where the existing contract requires it → restore baseline.
6. **OPEN — Provenance/served HTML:** ربط كل نشر Edge بالـartifact source، ومطابقة Cloudflare HTML.
7. **OPEN — Historical lineage:** فحص migrations والـcommits التي أدخلت `deliverer_id` وفصل Fleet/Delivery قبل إنشاء migration canonical.

### قرارات يجب الحفاظ عليها

- لا تكتب من تطبيق المشرف إلى `runsheets` مباشرة.
- لا تكتب `driver_id` من مشرف التوصيل.
- لا تغيّر `vehicle_id` أو `driver_id` من تطبيق المندوب.
- لا تنشئ Edge جديدة لمجرد سد الفجوة.
- لا توسع RLS العامة.
- لا تستخدم RS-1/RS-2 كـfixtures.
- لا تغيّر المخزون عند الإسناد أو فك الإسناد.
- لا تعلن 100% قبل E2E فعلي وBaseline restoration.

---

## 12. SELF-AUDIT FINAL

**What I Proved**
- Production يحتوي `driver_id` و`deliverer_id` منفصلين.
- Parent Fleet assignment يعالج المركبة والسائق عبر `RUNSHEET_ASSIGN` و`manage_runsheet_atomic`.
- تطبيق المشرف الحالي يكتب إلى `driver_id` مباشرة، فيصطدم بـRLS ويخلط دور المندوب بالسائق.
- Edge/Core الحالية لا تكمل عقد `deliverer_id` عبر كل دورة التسليم.
- `get-driver-dashboard` به defect مستقل مثبت: missing `id` في SELECT ثم استخدامه.
- لا توجد كتابة أعمال أو نشر إصلاح في هذه الدورة.

**What I Did Not Prove**
- نجاح رحلة Browser/HTTP E2E مصادق عليها.
- أن Cloudflare يقدم نفس Blob الحالي.
- Provenance قابلة لإعادة البناء لكل Edge artifact.
- أن Staging أصبح متاحًا بعد طلب الاستعادة.
- إغلاق جميع مسارات المحاسبة والتحصيل والمرتجعات التابعة للمندوب.

**What I Fixed**
- لا إصلاح تشغيلي نُشر في هذه الدورة. جرى تثبيت السبب الجذري، وحدود الإصلاح الآمن، وعقد الهدف، والرقع المقترحة. لا أصف التشخيص بأنه إصلاح.

**What I Initially Missed**
- التمييز الجوهري بين `runsheets.driver_id` و`runsheets.deliverer_id`، وأن تبديل عمود واحد لا يكفي دون إصلاح Consumers.
- حقيقة أن Parent `RUNSHEET_ASSIGN` هو مسار للسائق/المركبة في `Open/Confirmed` وليس لتعيين مندوب إلى `Loaded`.

**What Could Still Be Wrong**
- قد توجد Consumers إضافية لـ`driver_id/deliverer_id` لم تُجرد بالكامل.
- قد يختلف HTML المنشور على Cloudflare عن Git.
- قد تحتاج Accounting/Ledger/Returns contracts إلى حواجز إضافية عند إعادة الإسناد بعد بدء التوصيل.

**Final Confidence:** 95% في السبب الجذري ضمن المصادر المفحوصة؛ 0% في ادعاء نجاح E2E النهائي.  
**Final Closure Status:** `PARTIAL — NOT CLOSED`.

**أول إجراء تنفيذي تالٍ:** استعادة إتاحة `rawaea-staging`، ثم إضافة/اختبار عقد `RUNSHEET_ASSIGN_DELIVERER` على Staging، ثم مواءمة `get-driver-dashboard/start-delivery/complete-delivery/complete-order-delivery/force-unassign-runsheet` مع `deliverer_id`، ثم تقديم رقع HTML الجراحية للمالك وتطبيق E2E كامل قبل النشر/الإغلاق.
