# تقرير 191 — إغلاق Loyalty Mother UI بعد مطابقة Production

**التاريخ:** 2026-09-15
**المرحلة:** Loyalty Transaction Engine / Mother UI
**الهدف:** استكمال الإغلاق الوظيفي للنقطة المفتوحة دون إعادة إصلاح ما ثبت إصلاحه، ثم تثبيت نقطة الاستكمال التالية.

> ## تنبيه حاكم
> التقارير السابقة Historical/Reference فقط. لا تُعامل كحالة Production حالية.
> الحالة المعتمدة في هذه الجلسة هي فقط:
> `CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`.
> ولإغلاق Browser E2E يلزم أيضًا `CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`.
>
> **Source of Truth للنظام الأم:**
> `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`
>
> `Current/PWA/main2/*` و`Original/PWA/main/*` و`New-main` مراجع تاريخية فقط.

---

## 1. النتيجة التنفيذية

تمت مطابقة الحالة الفعلية قبل أي استنتاج.

### Production

جداول Loyalty الموجودة فعليًا:

- `loyalty_programs`
- `loyalty_rewards`
- `loyalty_accounts`
- `loyalty_points`
- `loyalty_transactions`

الحالة الدائمة عند بداية التحقق:

```text
loyalty_programs     = 0
loyalty_rewards      = 0
loyalty_accounts     = 0
loyalty_points       = 0
loyalty_transactions = 0
```

الـRPC الحالي:

```text
loyalty_engine_atomic(uuid,text,text,jsonb,text)
```

ويغطي العمليات:

```text
LIST_PROGRAMS
LIST_REWARDS
SAVE_PROGRAM
SAVE_REWARD
GET_ACCOUNT
LIST_TRANSACTIONS
EARN_ORDER
SYNC_ORDER
REDEEM
ADJUST
EXPIRE
REVERSE
```

الاستعلام الفعلي:

```text
LIST_PROGRAMS → success=true → program_count=0
```

إذن **Production engine لا يعلق**؛ الحالة الصحيحة هي وجود صفر برامج، وليست حالة خطأ.

### Root Cause الفعلي للواجهة

في النسخة الحالية من `main.html`، `renderConfig()` يضع داخل الشبكة:

```text
جاري التحميل...
```

ثم يبحث عن `Active` program.

عندما لا يوجد برنامج Active، لا توجد أي عملية لاحقة تستبدل placeholder، فيظل:

```text
جاري التحميل...
```

بلا نهاية.

وهذا يفسر المشكلة المرصودة بدقة من Production نفسها: قاعدة البيانات خالية من البرامج، والواجهة تتعامل مع غياب البرنامج على أنه انتظار.

---

## 2. CURRENT GIT FORENSICS

Repository:
`papamohammed77-glitch/erp-frontend`

Current branch:
`main`

Current HEAD:
`24e0124bedf6356103cb28bf365cef8e46be8027`

Direct parent:
`1f7928e0fa0320670df92c6e944afab0f28e2c0d`

Current mother blob:
`324b0deb53b6a58b379b08748d063d40a2aef92b`

### Parent-commit verification

الـparent `1f7928...` كان قد أصلح فقط ترتيبًا asynchronous في `RW_LoyaltyMain.render()`:

```javascript
loadPrograms().then(function(){
    renderProgramSummary();
    renderConfig();
}).catch(function(e){ showToast(e.message,'error'); });
loadCustomerOptions();
subscribeRealtime();
```

والـHEAD `24e0124...` نقل فقط:

```javascript
window.RW_SalesTargetsMain = RW_SalesTargetsMain;
```

من بعد Loyalty إلى قبلها.

لم يغير HEAD منطق `renderConfig()`.

### EOF verification

تم فتح الـblob الحالي مباشرة، والبحث عن نهاية الجسم أثبت النهاية:

```html
</script>
</body>
</html>
```

أي أن التحليل مبني على الـblob الحالي نفسه وليس fragment تاريخيًا.

---

## 3. CURRENT MOTHER UI — EXACT FORENSIC ANCHORS

### Loyalty render anchor

في `RW_LoyaltyMain.render()`، المنطقة الحالية حول السطر `2064` كانت أصلًا نقطة إصلاح asynchronous في الـparent.

ولا نعيد إصلاحها لأنها أصبحت بالصيغة الصحيحة في Current Source.

### renderConfig anchor

الدالة الحالية تحتوي حرفيًا على:

```javascript
function renderConfig(){
    var out=byId('rw-loyalty-config-panel'); if(!out) return;
    if(!canConfig()){ safeHTML(out,''); return; }
    safeHTML(out,'<div class="flex items-center justify-between mb-4"><h3 class="font-black text-lg">إعدادات المكافآت</h3><button class="text-indigo-600 font-bold" onclick="RW_LoyaltyMain.newReward()">إضافة مكافأة</button></div><div id="rw-loyalty-rewards-grid" class="grid grid-cols-1 md:grid-cols-2 gap-3"><div class="text-gray-400">جاري التحميل...</div></div>');
    var active=currentPrograms.find(function(x){return x.status==='Active';});
    if(active) loadRewards(active.id).then(renderRewards).catch(function(e){showToast(e.message,'error');});
}
```

وهي متبوعة مباشرة بـ:

```javascript
function renderRewards(){
```

وهذا هو **العنصر الجراحي المحدد**.

---

## 4. OWNER-ONLY SURGICAL PATCH — MAIN.HTML

هذا التعديل في النظام الأم، والمالك هو الذي يطبقه.

### ابحث عن الدالة كاملة

ابدأ من السطر الحالي التقريبي `renderConfig()` داخل `RW_LoyaltyMain`.

**احذف الدالة كاملة** من:

```javascript
function renderConfig(){
```

حتى السطر الأخير التالي مباشرة قبل:

```javascript
function renderRewards(){
```

### استبدلها بالدالة الكاملة التالية

```javascript
function renderConfig(){
    var out=byId('rw-loyalty-config-panel'); if(!out) return;
    if(!canConfig()){ safeHTML(out,''); return; }

    safeHTML(out,'<div class="flex items-center justify-between mb-4"><h3 class="font-black text-lg">إعدادات المكافآت</h3><button class="text-indigo-600 font-bold" onclick="RW_LoyaltyMain.newReward()">إضافة مكافأة</button></div><div id="rw-loyalty-rewards-grid" class="grid grid-cols-1 md:grid-cols-2 gap-3"><div class="text-gray-400">جاري التحقق من برنامج الولاء...</div></div>');

    var active=currentPrograms.find(function(x){return x.status==='Active';});
    var grid=byId('rw-loyalty-rewards-grid');

    if(!active){
        if(grid){
            safeHTML(grid,'<div class="col-span-full p-5 bg-slate-50 rounded-xl border border-slate-200"><div class="font-black text-slate-700 mb-1">لا يوجد برنامج ولاء نشط حاليًا</div><div class="text-sm text-slate-500">أنشئ أو فعّل برنامج ولاء أولًا، ثم ستظهر المكافآت المرتبطة به هنا.</div></div>');
        }
        return;
    }

    loadRewards(active.id).then(renderRewards).catch(function(e){
        if(grid){
            safeHTML(grid,'<div class="col-span-full p-5 bg-red-50 rounded-xl border border-red-200 text-red-700"><div class="font-black mb-1">تعذر تحميل المكافآت</div><div class="text-sm">'+esc(e.message||'خطأ غير معروف')+'</div></div>');
        }
        showToast(e.message,'error');
    });
}
```

**لا تحذف أو تعدل:**

```javascript
function renderRewards(){
```

ولا تعدل `loadPrograms()` أو `renderProgramSummary()` أو navigation أو permission map أو routing أو `window.RW_SalesTargetsMain = RW_SalesTargetsMain;`.

### لماذا هذا هو الإصلاح الصحيح

الواجهة أصبحت تميز بين حالتين مختلفتين:

```text
LIST_PROGRAMS succeeded + Active program exists
        ↓
loadRewards(active.id)

LIST_PROGRAMS succeeded + no Active program
        ↓
explicit empty state
```

وبذلك لا تستخدم عبارة `جاري التحميل...` كحالة دائمة لبيانات غير موجودة.

---

## 5. PRODUCTION TRANSACTION ENGINE VERIFICATION

تم تنفيذ اختبار داخل Transaction مؤقتة على Production، ثم `ROLLBACK` كامل.

الاختبار أنشأ مؤقتًا:

- Active Loyalty Program
- Reward
- Customer
- Draft Order
- Order Detail بقيمة مؤهلة 1000

ثم نُفذت دورة:

```text
SAVE_PROGRAM
↓
SAVE_REWARD
↓
UPDATE Order → Invoiced
↓
Deferred Loyalty Trigger
↓
EARN_ORDER
↓
REDEEM
↓
نفس REDEEM operation_id مرة ثانية
↓
REVERSE
```

كما تم إثبات أن trigger:

```text
trg_orders_loyalty_auto_earn
```

هو فعلًا:

```text
DEFERRABLE = true
INITIALLY DEFERRED = true
```

والـtrigger يستعمل operation identity حتميًا:

```text
AUTO:EARN_ORDER:<company_id>:<order_id>
```

### نتيجة الاختبار

تم إنشاء معاملات Loyalty مؤقتة أثناء الاختبار ثم تم التراجع عنها.

العدّادات النهائية بعد الاختبار:

```text
loyalty_programs     = 0
loyalty_rewards      = 0
loyalty_accounts     = 0
loyalty_transactions = 0
```

وكذلك لا توجد Customer مؤقتة متبقية.

### نتيجة Production Runtime

```text
LIST_PROGRAMS = PASS
SAVE_PROGRAM  = PASS داخل transaction
SAVE_REWARD   = PASS داخل transaction
AUTO EARN     = PASS داخل transaction
REDEEM        = PASS داخل transaction
IDEMPOTENCY   = PASS داخل transaction
REVERSE       = PASS داخل transaction
ROLLBACK      = PASS
DATA HYGIENE  = PASS
```

---

## 6. ما لم يتم ادعاؤه

لم يتم تنفيذ Browser E2E على متصفح فعلي من داخل بيئة التنفيذ الحالية.

لذلك لا يُحوّل:

```text
Production/Database PASS
```

إلى:

```text
Browser E2E PASS
```

بعد تطبيق المالك للتعديل أعلاه وإعادة النشر، يجب اختبار:

```text
فتح Loyalty
↓
إعدادات المكافآت
↓
LIST_PROGRAMS
↓
no Active program
↓
ظهور "لا يوجد برنامج ولاء نشط حاليًا"
```

ثم بعد إنشاء/تفعيل برنامج:

```text
LIST_PROGRAMS
↓
Active program
↓
LIST_REWARDS
↓
ظهور المكافآت
```

مع فحص Console وNetwork وعدم وجود JavaScript error.

---

## 7. التعديلات التي نُفذت فعليًا في Production

لا توجد حاجة لإنشاء Loyalty tables جديدة؛ البنية الحالية موجودة بالفعل ومطابقة للـengine.

لا توجد حاجة لإنشاء Edge Function ثانية؛ capability الحالية:

```text
loyalty-engine
```

والـRPC:

```text
loyalty_engine_atomic
```

كافيان للبنية الحالية.

الإصلاح المطلوب في هذه الجلسة هو **Mother UI state handling** وليس إضافة backend بديل أو جدول إضافي.

هذا مهم حتى لا نخلق ازدواجية أو Core موازيًا.

---

## 8. خطأ وقع أثناء التنفيذ

تم في الاختبار الأول إرسال كتلة `DECLARE` خارج `DO $$ ... $$`، فرفض PostgreSQL التنفيذ بخطأ syntax.

لم تُكتب أي بيانات نتيجة هذا الخطأ.

تم تصحيح صيغة الاختبار وإعادة التنفيذ بالصيغة الصحيحة داخل Transaction مؤقتة.

---

## 9. SELF-AUDIT

### What I Proved

- Current frontend HEAD = `24e0124...`.
- Direct parent = `1f7928...`.
- Current mother blob = `324b0d...`.
- Current mother source reaches EOF with `</html>`.
- Current Production Loyalty tables exist.
- Current Production Loyalty table counts are zero.
- `loyalty_engine_atomic` is present and operational.
- `LIST_PROGRAMS` returns success with zero programs.
- Auto-earn trigger is genuinely deferred.
- Transaction cycle works inside a temporary transaction.
- Idempotency works for the tested transaction path.
- Production contains no residual E2E Loyalty data after rollback.
- The UI defect is specifically the no-Active-program branch of `renderConfig()`.

### What I Did Not Prove

- Browser E2E after the owner's new patch.
- Console cleanliness after the owner's republish.
- Network timing in the real browser.

### What I Fixed

تم تنفيذ/تثبيت بنية Production اللازمة سابقًا، ولم توجد حاجة لإعادة بناء tables أو Edge Function.
تم تحديد الإصلاح الجراحي الصحيح للـMother UI، وهو استبدال `renderConfig()` فقط.

### What I Initially Missed

التقرير السابق كان يركز على asynchronous ordering في `render()` فقط. ذلك الإصلاح كان صحيحًا لكنه غير كافٍ عندما يكون Production نفسه بلا Active Program.

### What Could Still Be Wrong

الاحتمال المتبقي الوحيد المؤثر هو تنفيذ المالك للدالة الجديدة في Current Mother File بصورة غير مطابقة أو عدم إعادة نشر النسخة الحالية، ثم فشل Browser E2E.

### Final Confidence

```text
Production Loyalty backend: HIGH / VERIFIED
Production transaction engine: HIGH / VERIFIED
Mother UI root cause: HIGH / VERIFIED
Browser E2E: OPEN
```

### Final Closure Status

```text
LOYALTY DATABASE = CLOSED
LOYALTY RPC ENGINE = CLOSED
LOYALTY EDGE CAPABILITY = CLOSED
LOYALTY TRANSACTION E2E (DB) = PASS
LOYALTY MOTHER UI = OWNER PATCH REQUIRED
BROWSER E2E = OPEN
GLOBAL LOYALTY = NOT FULLY CLOSED UNTIL BROWSER E2E
```

---

## 10. تعليمات بداية الاستكمال للمساعد التالي

لا تبدأ من الصفر.

ابدأ بهذا التسلسل فقط:

1. اقرأ هذا التقرير باعتباره Historical clue فقط.
2. تحقق من `CURRENT GIT` في `erp-frontend`، ثم HEAD وparent والـblob الحالي لملف `companies/company-1/main.html`.
3. افتح الـblob الحالي نفسه وابحث عن `renderConfig()`، ولا ترث أرقام الأسطر من أي تقرير قديم.
4. تحقق من أن الدالة الجديدة تعطي empty state عند عدم وجود `Active` program.
5. تحقق من Production الحالية مباشرة: counts + `loyalty_engine_atomic` + deployed `loyalty-engine`.
6. لا تُنشئ جداول أو RPCs جديدة إذا كانت الموجودة الحالية ما تزال مطابقة للعقد.
7. بعد تأكيد التعديل في `main.html`، اجعل المالك يعيد النشر ثم نفذ Browser/Console/Network E2E على النسخة المنشورة الحالية.
8. لا تعلن Loyalty = CLOSED قبل أن يثبت Browser E2E.
9. بعد إغلاق Browser E2E، لا تعد لإصلاح Loyalty مرة أخرى إلا عند ظهور Defect جديد مثبت.
10. نقطة الاستكمال التالية حسب العقد الحالي هي:

```text
RETURN → LOYALTY REVERSAL POLICY
```

وقبل أي Production change هناك يجب إعادة بناء العقد التاريخي لـReturn وربطه بدورة order/runsheet/settlement والنتيجة المالية والـloyalty، دون افتراض أن كل Return يجب أن يخصم Loyalty.

**القاعدة العليا:**
لا تثق بالتقرير، ولا بالذاكرة، ولا بالحالة السابقة. ثق فقط بالحقيقة الحالية التي تثبتها بنفسك من Git + Source + Production + Database + Deployment evidence + Browser عند E2E.
