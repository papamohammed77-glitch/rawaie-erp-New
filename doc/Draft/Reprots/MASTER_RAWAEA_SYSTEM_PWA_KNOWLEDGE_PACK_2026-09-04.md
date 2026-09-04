# RAWAEA ERP — VERIFIED SYSTEM & PWA CONSUMER KNOWLEDGE PACK

**Date:** 2026-09-04
**Repository:** `papamohammed77-glitch/rawaie-erp-New`
**Branch:** `main`
**Supabase:** `SMART ERP` / `fiilmooggumokxanwiyx`
**Status:** VERIFIED KNOWLEDGE BASELINE FOR SUCCESSOR CTO

---

## 0. PURPOSE

هذا الملف ليس تقرير رأي ولا إعادة صياغة للتقارير السابقة. وظيفته سد الفجوة المعرفية التي ظهرت في `doc/Draft/Reprots/النقص المعرفي للمساعد الجديد`، وإعطاء أي Successor CTO خريطة تشغيلية موثقة لدور النظام الأم، وحدود تطبيقات PWA المنفصلة، ومكان الملفات التاريخية والخطط، وما هو ثابت وما زال يحتاج Runtime proof.

المبدأ:

```text
INHERIT EVIDENCE, NOT CONFIDENCE
PRODUCTION / DATABASE > CURRENT GIT > VERIFIED EVIDENCE RECORDS > HISTORY / REPORTS
```

---

# 1. THE WHOLE RAWAEA SYSTEM

الروائع ERP ليس مجرد صفحة PWA واحدة. البنية التي تثبتها المصادر الحالية هي:

```text
RAWAEA ERP BUSINESS SYSTEM
        |
        +--> PWA / UI CONSUMERS
        |       |
        |       +--> New-main / main.html / role-specific PWAs / store / vouchers
        |
        +--> Shared PWA Runtime
        |       |
        |       +--> core.js
        |       +--> service-worker coordination
        |
        +--> Supabase Edge Functions / RPC contracts
        |
        +--> PostgreSQL / Supabase SSOT
```

القاعدة المعمارية الحاكمة:

```text
PWA = interface + orchestration + presentation
Edge/RPC/DB = business execution / authority
PostgreSQL = system of record
```

أي تطبيق PWA منفصل لا يصبح business authority مستقلًا لمجرد أنه صفحة مستقلة.

---

# 2. CANONICAL CURRENT APPLICATION TARGET

الهدف الحالي في مسار استكمال المنتج هو:

```text
Current/PWA/New-main
```

الفحص المباشر للـmain الحالي يثبت أنه **HTML/CSS/JS كامل**، وليس ملفًا وصفيًا قصيرًا. بداية المصدر الحالية تتضمن RTL HTML، وCSS كامل لواجهة الدخول والـsidebar والـdashboard، وروابط manifest وservice-worker coordinator وSupabase client.

Current source values:

```text
rw-login-title = 58px
rw-login-logo = 88 × 88
```

Current login identity surface:

```text
RAWAEA ERP ENTERPRISE
الروائع ERP
منصة إدارة الأعمال الذكية والمتكاملة
```

وجود اختلافات مع Original لا يثبت regression بحد ذاته.

---

# 3. WHAT `main.html` AND `New-main` MEAN

`New-main` = **canonical current product target** في خط الاستكمال الحالي.

`main.html` = **current parent/main dashboard application surface** داخل `Current/PWA`، وليس بديلًا مثبتًا عن `New-main`.

لا يجوز التعامل مع `main.html` و`New-main` كأن أحدهما database authority والآخر consumer؛ كلاهما طبقات واجهة ضمن النظام، مع كون `New-main` هو target الحالي في مسار الاستكمال.

داخل `Current/PWA/main/` توجد ملفات `main1.md` … `main11.md`. هذه ليست أحد عشر تطبيقًا مستقلاً. هي مواد/أجزاء مرتبطة بعقد الـParent PWA وتاريخه.

---

# 4. SHARED RUNTIME — `core.js`

الفحص المباشر لـ`Current/PWA/core.js` يثبت وجود النواة المشتركة التالية:

```text
RW_Auth
RW_DB
RW_API
RW_UI
```

### RW_Auth

- يستعيد Supabase Auth session عبر `getSession()`.
- يعتمد على Auth user metadata لاستخراج `isOwner`, `role`, `permissions`, و`active_warehouse_role`.
- `checkPermission()` يعامل `isOwner=true` أو `permissions` التي تحتوي `*` كصلاحية كاملة على مستوى الواجهة.
- الطلبات الخلفية تستخدم bearer access token.

### RW_DB

- غلاف Dexie محلي مشترك.
- schema محلي يتضمن customers, items, stock, branches, orders, pending_updates.
- يدعم `syncDown()` و`syncUp()`.
- التخزين المحلي ليس بديلًا عن PostgreSQL SSOT؛ هو طبقة تشغيل/مزامنة للواجهة.

### RW_API

- يستدعي Supabase Edge Functions عبر `/functions/v1/<function>`.
- يرسل `Authorization: Bearer <token>`.
- يوفر retry wrapper.

### RW_UI

- طبقة UI المشتركة؛ وجودها لا ينقل business authority إلى المتصفح.

---

# 5. SERVICE-WORKER / CACHE BOUNDARY

الـPWA تستخدم:

```text
register-sw.js
sw.js
manifest.json / New-main.manifest.json
```

`register-sw.js` ينسق تسجيل الـservice worker، ويجري update checks ويعيد تحميل الصفحة بعد `controllerchange`.

إذن عندما تكون:

```text
SOURCE = CONFIRMED
```

فهذا لا يساوي:

```text
BROWSER RUNTIME = CONFIRMED
```

وهناك ثلاث طبقات يجب فصلها دائمًا:

```text
SOURCE ARTIFACT
DEPLOYED REVISION
BROWSER CACHE / SERVICE WORKER
```

حتى تاريخ هذا الملف لا يوجد fresh browser E2E proof يثبت التطابق بين الثلاثة.

---

# 6. PWA CONSUMER MAP

الملفات التالية هي **application/consumer entry surfaces** موجودة حاليًا في `Current/PWA`:

## Parent / Main

```text
New-main
main.html
```

## Sales / Orders

```text
telesales.html
order-taker.html
van-sales.html
pos.html
```

هذه التطبيقات تستهلك عقود sales/order والخدمات الخلفية المشتركة. لا تعتبر `orders` داخل المتصفح business authority مستقلة.

## Warehouse / Physical Operations

```text
picker.html
loader.html
receiver.html
unloader.html
warehouse.manager.html
warehouse.supervisor
Returns.html
```

هذه واجهات لأدوار/مراحل تشغيل المستودع. التنفيذ الحقيقي للحركة أو الحالة التشغيلية يجب أن يُراجع على Edge/RPC/DB وليس من وجود زر أو view فقط.

## Driver / Delivery

```text
driver.html
driver.supervisor.html
```

## Purchasing / Finance / Management

```text
buyer.html
buyers.supervisor.html
accountant.html
finance-manager.html
general-manager.html
hr.html
sales.manager.html
sales.supervisor.html
```

## Owner / General Entry Surfaces

```text
owner.html
counter.html
index.html
app.html
```

هذه entry surfaces وليست دليلاً على أن أحدها هو backend authority.

## Online Store

```text
store.index.html
store.track.html
```

## Vouchers

```text
vouchers.html
```

---

# 7. SHARED SUPPORT FILES — NOT APPLICATIONS

```text
core.js
sw.js
register-sw.js
New-main.manifest.json
manifest.json
schema-validator.js
vouchers-gold-master-ui.js
New-main-icon.svg
_headers
```

وجود ملف دعم مشترك لا يعني أنه تطبيق وظيفي مستقل.

---

# 8. BUSINESS BACKEND MAP — DIRECT PRODUCTION EVIDENCE

Supabase Production هو:

```text
SMART ERP
project_ref = fiilmooggumokxanwiyx
europe region = eu-west-1
PostgreSQL 17.6
status = ACTIVE_HEALTHY
```

وتظهر طبقة Edge Functions واسعة تغطي، من بين ما تم التحقق منه مباشرة:

```text
Items / Customers / Suppliers / Branches / Employees / Settings / Roles
Orders / Sales
Runsheet / Picking / Loading / Delivery / Return
Stock Vouchers
Purchasing
Accounting / Reporting
Audit / Supporting workflows
```

أمثلة مباشرة من Production:

```text
save-sales-invoice       v15
create-runsheet          v26
start-picking            v34
complete-picking         v17
start-loading            v5
complete-loading         v11
start-delivery           v7
complete-delivery        v4
complete-return          v25
unload-runsheet          v6
send-stock-voucher       v20
receive-stock-voucher    v22
receive-purchase         v12
save-journal-entry       v8
```

هذه **production deployment facts** عن وجود الإصدارات؛ ولا تعني تلقائيًا أن كل runtime path مقبول وظيفيًا 100%.

معظم business functions التي تمت مراجعتها تحمل:

```text
verify_jwt = true
```

وفي المقابل توجد مجموعة historical/test/recovery/E2E functions بــ:

```text
verify_jwt = false
```

وهذه مساحة خطر تحتاج تصنيفًا صريحًا، لا معالجة عمياء.

---

# 9. DATABASE BUSINESS AUTHORITY

Production schema يثبت وجود مجالات مركزية منها:

```text
companies
branches
users
roles
role_permissions
app_settings
items
customers
suppliers
orders
order_details
runsheets
run_sheet_details
stock / stock_branches
stock vouchers
purchasing
accounting / treasury
workflow / audit / notifications
vehicles / delivery / complaints / credit
```

الـinventory invariant المثبت:

```text
available_qty = qty - allocated_qty
```

والقاعدة التشغيلية الحاكمة في مشروع الإنقاذ:

```text
allocated_qty != physical qty
PWA != stock authority
```

وحيث ثبت سابقًا:

```text
post_stock_movement = physical stock movement authority
reserve_stock = reservation authority
```

لا تعاد كتابة هذا العقد إلا بدليل Production جديد وقاطع.

---

# 10. OWNER / LICENSE CONTRACT — CRITICAL

Production DB verified owner state:

```text
email = owner@alrawae.com
permissions = ["*"]
status = Active
role = مدير النظام
role_id = e8a76adb-8efe-4bc5-b760-0ee660f10e9f
auth_id = 0a6089e6-0c33-4cf9-9aa0-31fc42774b89
owner_profile = linked
license_status = active
```

العقد الصحيح:

```text
OWNER
=
AUTH OWNER IDENTITY
+
isOwner=true
+
permissions=["*"]
+
VALID owner_profile
+
ACTIVE LICENSE
```

**ممنوع** استبدال `*` بقائمة role permissions تخمينية، وممنوع استخدام `role_id` بدل owner identity.

---

# 11. LICENSE MANAGEMENT TAB

مصدر `New-main/main` يتضمن contract خاصًا بمسار الترخيص:

```text
view = license
label = إدارة الترخيص
perm = owner
route = RW_OwnerLicense.render
owner gate = hasOwner()
```

وفي `core.js`:

```text
isOwner=true -> full frontend permission
permissions includes '*' -> full frontend permission
```

لذلك:

```text
SOURCE ROUTE = CONFIRMED
OWNER CONTRACT = CONFIRMED
BROWSER TAB VISIBILITY = NOT PROVEN WITHOUT FRESH RUNTIME
DEPLOYED REVISION = NOT PROVEN
CACHE/SW = NOT PROVEN
```

لا تضف route بديلًا قبل ظهور دليل runtime أن الموجود فعليًا مفقود.

---

# 12. HISTORICAL ORIGINAL VS CURRENT

Direct inspection of `Original/PWA/main/main1.md` proves historical values including:

```text
<title>الروائع ERP | نظام متكامل</title>
rw-login-title = 64px
rw-login-logo = 120 × 120
rw-company-name = 34px
```

Current `New-main` has smaller login values and a current identity surface containing `RAWAEA ERP ENTERPRISE` plus `الروائع ERP`.

Classification:

```text
DIFFERENCE = PROVEN
REGRESSION = NOT PROVEN
INTENTIONAL REBRAND / MODERNIZATION = NOT PROVEN
```

Do not convert Original-vs-Current difference into a patch without owner intent or runtime/business evidence.

---

# 13. HISTORICAL FILES / PLANS / REPORTS — HOW TO READ THEM

Historical material is valuable for recovering intent, chronology, contracts, and previous failures, but it is not the current truth by itself.

Examples of useful historical evidence:

```text
rawaie-erp-review/
Edge_Functions/original/03_loading/
Original/PWA/main/main1.md
Current/PWA/main/main1.md ... main11.md
doc/Draft/Reprots/*
doc/Draft/Hussin/*
doc/Draft/Hytham/*
doc/Draft/Khalid/*
doc/Draft/medhat/*
```

استخدمها بهذا الترتيب:

```text
Current Production reality
→ Current main source
→ Evidence records / deployment records
→ Historical source / plans
→ Reports / prompts as search leads
```

إذا اختلف التاريخ عن Production، فالتاريخ لا يحكم الواقع الحالي.

---

# 14. CURRENT GIT CHRONOLOGY — IMPORTANT

Verified latest `main` sequence at time of this pack:

```text
67fd5b327139be15964e4ecaa98218b0b7345ccf
[CTO] Refresh PROJECT_MEMORY with verified GitHub/Supabase review 2026-09-04

4b93e9178397028b6345c3a863d65e659a696331
[CTO] Sync CURRENT_STATE with Report50 and corrected main ancestry

391de3fb38cb63f5c9ea6a3e62a91a5a3727a1a
[CTO] Add Report50 forensic PWA consumer inventory and state reconciliation

8d64f747cdf06cd4197a379b7697b1855ecefeca
[CTO] Sync CURRENT_STATE with Report49 and V12 latest forensic checkpoint
```

Important historical commits that touched `Current/PWA/New-main` existed on independent/alternate parent chains and are not by message alone evidence of current-main ancestry:

```text
2118dff88f25ff09a397211293753898d1d9316a
94ffee68ee6d039661fe8eb0d3b06a15a789b830
6d7291026cf658e4d4c3b0b02f771dbefbe62ad1
```

Rule:

```text
CURRENT main ancestry > orphan/alternate repair chain
commit message != deployment proof
```

---

# 15. WHAT THE PREVIOUS KNOWLEDGE-GAP REPORT GOT WRONG

The previous `النقص المعرفي للمساعد الجديد` correctly refused to patch under uncertainty, but it recorded several UNKNOWNs that are now materially resolved:

### Resolved — New-main identity

It is not a 56-line descriptive file. Direct current-main fetch shows the full HTML/CSS/JS artifact.

### Resolved — CSS location

Critical login CSS is inline in `Current/PWA/New-main`, including `.rw-login-title` and `.rw-login-logo`.

### Resolved — Shared runtime location

`Current/PWA/core.js` is the shared runtime and its auth/API/local-store boundaries are directly inspectable.

### Resolved — Owner DB contract

The owner record and wildcard semantics are directly verified in Production.

### Still open — Browser runtime

The source is known, but fresh E2E browser execution is still not established.

### Still open — Intent of brand differences

Current-vs-Original differences are proven, but intentional rebrand intent is not proven.

---

# 16. DO NOT REPEAT THESE ERRORS

```text
Do not restart the project from zero.
Do not treat report claims as runtime proof.
Do not infer file absence from a failed/partial read.
Do not confuse `New-main` with a tiny description file.
Do not confuse `main.html` with the whole ERP backend.
Do not treat PWA consumers as business authorities.
Do not replace owner ["*"] with enumerated role permissions.
Do not use role_id as the owner identity source.
Do not assume Source == Deployment == Browser.
Do not copy an alternate repair commit into current main merely because its message says restore/Gold/closed.
Do not patch a branding discrepancy without owner intent evidence.
Do not reopen Inventory/Accounting/Ledger solely because a historical report mentioned them.
Do not delete historical reports.
```

---

# 17. SUCCESSOR BOOT SEQUENCE

كل Successor CTO يبدأ بهذه السلسلة:

```text
1. Read CURRENT_STATE.md to EOF.
2. Read latest numbered report to EOF.
3. Read this Knowledge Pack to EOF.
4. Discover current main HEAD directly.
5. Verify target blob directly.
6. Check relevant Production Edge version / schema / logs.
7. Classify every claim:
   THEORETICAL
   CURRENT ONLY
   STAGING VERIFIED
   PRODUCTION DEPLOYED
   PRODUCTION RUNTIME VERIFIED
   100% CLOSED
8. Select exactly one Closure Unit.
9. Patch only the smallest proven window.
10. Recheck source + deployment + runtime where available.
11. Write a dated report.
12. Update CURRENT_STATE with the new checkpoint.
```

---

# 18. OPEN KNOWLEDGE BOUNDARY

At this checkpoint the following remain unproven and must not be faked:

```text
Fresh browser E2E
Exact deployed revision for New-main
Service-worker/cache identity in the active browser
Full PR/issue closure history
Whole-system Gold/Diamond acceptance
Intent behind all historical brand differences
Lifecycle classification of every verify_jwt=false test/recovery function
```

Open items do not invalidate the map above; they define the next evidence gates.

---

# 19. RAW SOURCE INDEX

```text
CURRENT_STATE
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/CURRENT_STATE.md

LATEST PROJECT MEMORY
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/PROJECT_MEMORY.md

THIS KNOWLEDGE PACK
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/Reprots/MASTER_RAWAEA_SYSTEM_PWA_KNOWLEDGE_PACK_2026-09-04.md

REPORT50
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/Reprots/%D8%AA%D9%82%D8%B1%D9%8A%D8%B150.md

NEW-MAIN
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/New-main

MAIN.HTML
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/main.html

CORE
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/core.js

REGISTER SW
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/register-sw.js

SERVICE WORKER
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/sw.js

CURRENT MAIN1
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/main/main1.md

ORIGINAL MAIN1
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Original/PWA/main/main1.md
```

---

# 20. FINAL PRINCIPLE

```text
The RAWAEA ERP system is one business system.
Its PWA files are consumers, not competing business systems.
Its shared runtime is a boundary, not the database authority.
Supabase/PostgreSQL remains the business system of record.
Historical files explain origin and intent; Current + Production establish reality.
```
