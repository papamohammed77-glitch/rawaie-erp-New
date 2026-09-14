# Report182 — SALES TARGETS LIVE FORENSIC CLOSURE

**التاريخ:** 2026-09-14
**الحالة المرجعية:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE

## 1. تنبيه حاكم

هذا التقرير لا يعتمد على Report178 أو Report179 أو Report180 أو Report181 كحالة حالية. تلك التقارير استُخدمت فقط لفهم السياق، بينما نتائج هذا التقرير مبنية على الفحص المباشر للمصادر الحالية.

## 2. Current Git — Mother Source

تمت مراجعة مستودع `papamohammed77-glitch/erp-frontend` والفرع `main`.

- HEAD: `9e6645bf3c613f8995785d1fe70a88150ce87c16`
- Direct Parent: `91e50848a65cb0255e95c4e7d8f1a1523eb43e85`
- Parent of Parent: `3398d0952ea723d1de42b076ad93ae19c025bfa3`
- Mother file: `companies/company-1/main.html`
- Current blob: `85a8a3593251a1f7c2ddbc8654cc192db8c4a0c2`
- Source timestamp inside file: `2026-09-14 00:40 UTC`

تمت قراءة محتوى الـblob الحالي حتى وجود EOF داخل نفس المصدر، مع وجود markers النهائية `</script>` ثم `</body>` ثم `</html>`.

## 3. Current Mother Source — Sales Targets

المصدر الحالي يثبت:

1. `RW_Navigation.menuTree` يحتوي `sales-targets`.
2. Dispatcher ينفذ `RW_SalesTargetsMain.render()` عند فتح التبويب.
3. `RW_SalesTargetsMain` موجود في المصدر الحالي.
4. `render()` يستخدم `var c=byId('rw-page-container');`.
5. الاستدعاء التلقائي للخطة الأولى يستخدم `RW_SalesTargetsMain.selectPlan(plans[0].id)`.
6. لا يوجد مسار `rw-page-content` داخل Sales Targets الحالي.
7. `safeHTML` موجود كدالة عامة.
8. Sales Targets يستخدم `RW_UI.safeHTML` رغم عدم وجود تعريف `RW_UI`.

### Root Cause المثبت

الـConsole الحالي أعطى:

`Uncaught (in promise) ReferenceError: RW_UI is not defined`

عند `main:1390` أثناء `RW_SalesTargetsMain.render()`.

هذا يطابق المصدر الحالي؛ أول عملية rendering هي:

```js
RW_UI.safeHTML(c,'<div class="rw-card"><div class="rw-loading">جاري تحميل محرك أهداف المبيعات...</div></div>');
```

بينما المصدر يعرّف بالفعل:

```js
const safeHTML = (el, html) => { if (!el) return; try { el.innerHTML = html; } catch(e) { console.error(e); } };
```

## 4. Owner Surgical Fix — Mother File

**لم يتم تعديل `erp-frontend/companies/company-1/main.html` بواسطة المساعد.**

الإصلاح المطلوب جراحيًا:

### العنصر المحدد

ابحث في `main.html` الحالي عن هذا السطر الكامل:

```js
const safeText = (el, text) => { if (!el) return; try { el.innerText = text; } catch(e) { console.error(e); } };
```

وهو بعد تعريف `safeHTML` مباشرة.

### الإضافة

أضف السطر التالي مباشرة بعده:

```js
const RW_UI = { safeHTML: safeHTML };
```

هذا هو الإصلاح الوحيد المثبت حاليًا لخطأ `RW_UI is not defined`.

لا تعدّل `render()` أو `renderDashboard()` أو `selectPlan()` أو dispatcher؛ لا يوجد دليل حالي يثبت ضرورة تعديلها.

## 5. Current Production — Database

Supabase Production project:

`fiilmooggumokxanwiyx`

الحالة المباشرة الحالية:

- `sales_target_plans = 0`
- `sales_target_assignments = 0`
- `sales_target_runs = 0`
- `sales_target_run_lines = 0`

ولا يوجد Test residue في هذه الجداول.

## 6. Current Production — Sales Target DB Contract

تم التحقق مباشرة من Production:

- `sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)` موجود و`SECURITY DEFINER`.
- `sales_target_engine_gateway(uuid,text,text,uuid,jsonb,text)` موجود و`SECURITY DEFINER`.
- `sales_target_dashboard_atomic(uuid,uuid,text)` موجود و`SECURITY DEFINER`.
- `sales_target_integrity_guard()` موجود و`SECURITY DEFINER`.

الـengine يحتوي العمليات الحالية:

`LIST_PLANS`, `LIST_ASSIGNMENTS`, `LIST_RUNS`, `SAVE_PLAN`, `SAVE_ASSIGNMENT`, `CLONE_PLAN`, `SET_ASSIGNMENT_ACTIVE`, `APPROVE_PLAN`, `CLOSE_PLAN`, `CANCEL_PLAN`, `PREVIEW`, `POST`, `APPROVE_RUN`, `REVERSE_RUN`.

## 7. Current Production — Authorization

المستخدم الموجود في Production:

`sales.manager@rawaea.com`

يمتلك permission `sales_manager`.

اختبار مباشر:

`sales.manager@rawaea.com` → `LIST_PLANS` = PASS والنتيجة `plans=[]`.

`accountant@rawaea.com` → `SAVE_PLAN` = REJECTED برسالة `Sales target management permission required`.

## 8. Production Hardening المنفذ

كان `sales_target_integrity_guard()` يمنح `EXECUTE` لـ:

- PUBLIC
- anon
- authenticated
- postgres
- service_role

تم إغلاق التعرض مباشرة في Production:

```sql
REVOKE ALL ON FUNCTION public.sales_target_integrity_guard()
  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.sales_target_integrity_guard()
  TO postgres, service_role;
```

ثم تم التحقق من Production والنتيجة:

- postgres = EXECUTE
- service_role = EXECUTE
- لا يوجد EXECUTE لـPUBLIC
- لا يوجد EXECUTE لـanon
- لا يوجد EXECUTE لـauthenticated

والتغيير موثق في:

`supabase/migrations/20260914_sales_target_integrity_guard_acl_hardening.sql`

## 9. Index / Constraint Review

تم فحص Indexes الحالية ولم توجد فجوة تبرر إضافة Index جديد؛ الـProduction تحتوي بالفعل على indexes مناسبة لعلاقات Company/Plan/Run/Assignment/Representative/Branch.

لم يتم إنشاء أي Index مكرر.

## 10. Current Edge Deployment

`sales-target-engine` = ACTIVE, version 2, verify_jwt=true.

`sales-target-dashboard` = ACTIVE, version 1, verify_jwt=true.

مصدر Edge الحالي يستخدم `auth_id -> users.company_id` ثم الـgateway، لذلك لم يتم إنشاء version جديدة بلا تغيير وظيفي.

## 11. الاختبارات

### نجح

- Current schema inspection.
- Current function inspection.
- Current grants inspection.
- `LIST_PLANS` للمستخدم المصرح.
- رفض `SAVE_PLAN` للمستخدم غير المصرح.
- ACL hardening.
- التأكد من بقاء `sales_target_plans = 0` وعدم وجود test residue.

### لم يتم تنفيذه عمدًا

لم يتم إنشاء Plan/Assignment/Run اختبارية دائمة في Production لإجبار نجاح دورة الأعمال؛ لأن ذلك سيضيف بيانات وهمية وسجلات audit غير حقيقية.

لذلك لا يتم الادعاء حاليًا بأن التسلسل:

`SAVE → ASSIGN → APPROVE → PREVIEW → POST → APPROVE_RUN → REVERSE_RUN`

تم اختباره كدورة أعمال ناجحة في Production الحالية.

هذا قيد بيانات حقيقي، وليس عذرًا تقنيًا.

## 12. Forensic Conclusion

### السبب الجذري لعدم فتح التبويب

**Missing `RW_UI` symbol in current Mother Source.**

الـBackend قائم، والـdispatcher قائم، والـcontainer الصحيح قائم، والخطأ يقع قبل أول network operation للمحرك.

### Backend

`SALES TARGET BACKEND = VERIFIED`

`SALES TARGET TENANT AUTHORIZATION = VERIFIED`

`SALES TARGET INTEGRITY GUARD ACL = CLOSED`

`SALES TARGET EDGE = VERIFIED`

### Mother UI

`SALES TARGET ROOT CAUSE = PROVEN`

`SALES TARGET OWNER SURGERY = READY`

`LIVE BROWSER E2E = OPEN`

## 13. ما لم يتم تغييره

لم يتم:

- تغيير dispatcher.
- تغيير `render()`.
- تغيير `renderDashboard()`.
- تغيير `selectPlan()`.
- إنشاء Edge Function جديدة.
- إنشاء جدول جديد.
- تغيير Schema الأعمال.
- تعديل `forensic_main_assembly.yml` لأنه صحيح بالفعل.
- إعادة إصلاح إصلاحات موجودة في HEAD الحالي.

## 14. الأخطاء والدروس

1. لا يجوز الاعتماد على تقرير سابق كدليل على الحالة الحالية.
2. وجود `safeHTML` لا يعني وجود `RW_UI`؛ أسماء الـAPIs يجب أن تطابق تعريفاتها الفعلية.
3. وجود Backend صحيح لا يمنع failure قبل أول network call في Mother UI.
4. لا يجوز إنشاء بيانات اختبار دائمة في Production لإنتاج PASS شكلي.

## 15. الحالة النهائية

```text
CURRENT GIT                         = VERIFIED
CURRENT MOTHER SOURCE              = VERIFIED
CURRENT PRODUCTION                 = VERIFIED
CURRENT DATABASE                   = VERIFIED
CURRENT DEPLOYMENTS                = VERIFIED
ROOT CAUSE                         = PROVEN
PRODUCTION HARDENING               = DEPLOYED + VERIFIED
MOTHER FILE SURGERY                = OWNER ACTION REQUIRED
LIVE BROWSER E2E                   = OPEN
SYSTEM-LEVEL SALES TARGETS        = OPEN
```

## 16. إرشادات المساعد القادم — من أين يبدأ وكيف يصل للحقيقة

1. ابدأ بـHEAD الحالي للـ`erp-frontend` ثم Direct Parent ثم Parent of Parent.
2. ثبّت blob الحالي للـmother file، ثم SHA والحجم وtimestamp إن أمكن.
3. أثبت EOF من نفس المصدر، ولا تخترع أرقام أسطر.
4. افحص Console الحالي أولًا وحدد أول exception حقيقي في الـstack.
5. افتح dispatcher ثم module ثم كل helper يستدعيه module.
6. طابق اسم كل helper مع تعريفه في نفس Source of Truth.
7. افحص Production schema/functions/permissions/Edge قبل تعديل backend.
8. لا تثق في Report178–181 كحالة حالية؛ استخدمها للسياق التاريخي فقط.
9. لا تكرر `rw-page-container` أو `selectPlan` لأنهما موجودان بالفعل في HEAD الحالي.
10. Mother file لا يُعدل بواسطة المساعد؛ قدم للمالك حذف/إضافة دقيقة مع anchor كامل.
11. Production defects المثبتة فقط تُصلح مباشرة وتُوثق في migration canonical.
12. بعد Owner surgery: login → إدارة المبيعات → أهداف المبيعات.
13. راقب Console + Network، ثم اختبر Realtime.
14. خذ Production snapshot جديدة في نفس لحظة تقرير الإغلاق.
15. لا تغلق system-level قبل إثبات Browser + Console + Network + Runtime.

## 17. Source of Truth النهائي

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

ولا يستخدم `Current/PWA/main2/*` أو `Original/PWA/main/*` أو `New-main` إلا كمرجع تاريخي.
