# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-13 11:35 UTC  
**Current checkpoint:** Report155 — CTO E2E للنظام الأم — Current Reality / Items / Warehouse / Detailed Reports.

## 0. GOVERNANCE — CURRENT TRUTH ONLY

الحالة الحالية لا تُبنى على التقارير السابقة. التقارير والملفات التاريخية تستخدم لفهم السياق والعقود فقط.

الحالة المعتمدة هي:

```text
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
```

الـSource of Truth للواجهة المنشورة:

```text
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html
```

`Current/PWA/main2/*` و`Original/PWA/main/*` = historical/reference only.

## 1. CURRENT GIT — LIVE

Repository:

```text
papamohammed77-glitch/erp-frontend
```

```text
HEAD:
5bdb2863570085edd19265465937aea3c674b52c

DIRECT PARENT:
02166a9f8e94ac0b2cc15257eb0aec8e039848bd

CURRENT MAIN.HTML BLOB:
2485901f759b88995ac80e1060883554b1177bbe
```

HEAD الحالي جاء بعد الـparent الذي كان يحتوي Regression نحوية، والـHEAD الحالي ثبت منه:

- إصلاح escaping داخل `_renderTable()`.
- إعادة قوس إغلاق `_renderTable()` قبل `_sort(field)`.

لذلك لا يجوز إعادة تطبيق Report154 أو Report153 على هذه المنطقة.

## 2. FORENSIC ASSEMBLY

`forensic_main_assembly.yml` تم التحقق منه مباشرة وهو صحيح:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

No change required.

## 3. PRODUCTION — CATEGORY DATA INTEGRITY

Production project:

```text
SMART ERP
fiilmooggumokxanwiyx
```

في Company `00000000-0000-0000-0000-000000000001` تم إصلاح master-data الخاص بالتصنيفات بناءً على البيانات الفعلية، وليس التخمين.

الصنف الذي بقي بعد الإصلاح الأول تم تحديده مباشرة:

```text
ITM-1057
صنف تجريبي2
category = تكنولوجيا
```

ثم تم إنشاء Category `تكنولوجيا` وربط الصنف بها.

الحالة النهائية المثبتة:

```text
categories = 5
items = 17
items with non-null category and NULL category_id = 0
```

سُجلت الإصلاحات في `audit_log` باستخدام action مدعوم من الـschema.

## 4. ITEMS — CURRENT SOURCE

المصدر الحالي يحتوي فعليًا على:

```text
List
Search
Category filter
Stock-status filter
Sorting
Branch stock columns
Movement report
Branch stock matrix
Branch filter
Excel export
CSV/XLS/XLSX upload
Bulk stock adjustment
Category CRUD
Item CRUD
Three item-form tabs
Opening stock
Marketing fields
Image handling
```

الـrenderer الحالي يستخدم `rowHtml +=` ويحتوي على branch drill-down و`_renderStockMovementReport(itemCode,itemName,branchId,branchName)`.

**Items historical feature loss = NOT PROVEN in current source.**

## 5. ITEMS — MOVEMENT / MATRIX / EXCEL

حركة الصنف الحالية تعتمد على `inventory_log` مع company/item/optional branch filtering وتفريق أنواع الحركة المادية.

المصفوفة حسب الفروع موجودة، وكذلك Excel export والتحديث الجماعي من CSV/XLS/XLSX.

لا يوجد دليل حالي يبرر استبدال هذه المسارات بالنسخة التاريخية الأقدم.

## 6. WAREHOUSE / STOCK TRANSFERS

Current `loadVoucherForm(type)` يستعلم عن الفروع Company-scoped ويستعلم عن المندوبين ثم السيارات النشطة المرتبطة بهم.

Production الحالية:

```text
Active branches = 2
Active direct-sales reps = 1
Active vehicles = 0
Active vehicles attached to direct-sales reps = 0
```

إذن عدم ظهور السيارات سببه عدم وجود سيارات Active في Production، وليس خللًا مثبتًا في الاستعلام الحالي.

لا يجوز إنشاء بيانات وهمية لإخفاء المشكلة.

Current `create-stock-voucher` Production version 10 ويدعم `operation_id`/`Idempotency-Key` وRPC canonical.

## 7. PHYSICAL STOCK CONTRACT

العقد الحالي المثبت:

```text
PHYSICAL STOCK MOVEMENT
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

المسارات التي تمت مراجعتها تستخدم هذا المركز ولا يوجد Physical Stock Engine ثانٍ مثبت داخل هذه closure.

## 8. RECEIVE PURCHASE

Production الحالية تحتوي على `receive_purchase_atomic` بتوقيع 5 معاملات يتضمن:

```text
p_operation_id uuid
```

و`receiving.operation_id` عليه UNIQUE constraint.

Current `receive-purchase` Edge Function = version 12، ويرسل `operation_id` ويقبل `Idempotency-Key`.

Current `main.html` نفسه يرسل:

```text
Idempotency-Key = receiveOperationId
operation_id    = receiveOperationId
```

لذلك لا يوجد Owner frontend patch إضافي مثبت لهذه النقطة حاليًا.

## 9. DETAILED REPORTS

تمت مراجعة `_generateReport()` والمسارات الرئيسية للتقارير.

العديد من المسارات الحالية تحمي المصفوفات قبل `.length`/`.map` باستخدام:

```javascript
data = r.data || [];
```

أو:

```javascript
Array.isArray(...)
```

أو ما يعادلها.

لكن رسالة:

```text
Cannot read properties of undefined (reading 'length')
```

لم يُثبت حتى الآن expression واحد بعينه في CURRENT SOURCE كسبب نهائي دون browser stack trace/runtime reproduction حالي.

لذلك:

```text
Detailed Reports root cause = OPEN / NOT PROVEN
```

ولا توجد تعليمات Owner patch غير مثبتة.

## 10. SECURITY EVIDENCE

Supabase security advisors الحالية تعرض تحذيرات مستقلة، منها SECURITY DEFINER functions قابلة للتنفيذ من أدوار API في عدد من الوظائف، وتحذير `auth_leaked_password_protection`.

هذه لا تُنسب إلى مشاكل Items/Transfers/Reports الحالية دون evidence specific.

## 11. SESSION FILES

تم إنشاء التقرير الجديد:

```text
doc/Draft/Reprots/Report155_CTO_E2E_Main_CurrentReality_20260913.md
```

Git commit:

```text
57d5cf7b942754d0254c0deecfd2ceb6ed1b7325
```

لم يتم تعديل:

```text
erp-frontend/companies/company-1/main.html
Current/PWA/main2/*
Original/PWA/main/*
forensic_main_assembly.yml
```

## 12. FAILED / CORRECTED ATTEMPTS

- أول تسجيل لإصلاح Category audit استخدم action غير مسموح به، فرفضه الـCHECK constraint؛ أعيد باستخدام `update` ونجح.
- اختبار Purchase Receive الاصطناعي الأول لم يكن دليل idempotent كافيًا؛ تم رفض اعتباره PASS ثم تم تثبيت Operation ID صريح في Production.
- تم اكتشاف أن الـfrontend كان بالفعل يحتوي على `receiveOperationId`؛ لذلك تم رفض إعادة اقتراح نفس التعديل.

## 13. BROWSER E2E

لا توجد في هذه البيئة أداة Browser Automation حقيقية لتنفيذ E2E فعلي.

لذلك:

```text
Browser E2E PASS = NOT CLAIMED
```

ولا يجوز تحويل static/runtime/deployment evidence إلى Browser PASS.

## 14. NEXT CTO / ASSISTANT — START HERE

```text
1. اقرأ HEAD الحقيقي من Git.
2. افتح parent المباشر وقارن diff.
3. افتح CURRENT main.html من ref=main.
4. اعتبر Report153/154 تاريخًا فقط، ولا تعيد إصلاح ما دخل HEAD الحالي.
5. افحص Production قبل كل تقرير جديد.
6. افحص Database schema/RPCs/triggers/permissions.
7. افحص Edge deployment versions الفعلية.
8. عند أي defect، حدّد exact function + exact expression + runtime evidence.
9. فرّق بين Regression وCapability جديدة.
10. Owner-only frontend: لا تلمس الملف؛ أعطِ block كاملًا مع بداية/نهاية ورقم السطر الحالي.
11. Production defect مثبت: أصلحه مباشرة.
12. بعد كل إصلاح أعد Production/Deployment verification.
13. لا تجعل synthetic test بديلًا عن Browser E2E.
14. أي Unknown أو Conflict أو Unverified Claim مؤثر يمنع 100% Closure.
15. لا تنتقل إلى closure جديد قبل إغلاق السابق أو توثيق سبب بقائه OPEN بالدليل.
16. المصدر النهائي للواجهة دائمًا companies/company-1/main.html.
```

## 15. FINAL STATUS

```text
CURRENT GIT RECONCILIATION = COMPLETE
CURRENT SOURCE RECONCILIATION = COMPLETE
CURRENT PRODUCTION RECONCILIATION = COMPLETE FOR THIS CLOSURE
CATEGORY DATA REPAIR = COMPLETE
ITEMS NAMED ISSUES = NO ADDITIONAL FRONTEND PATCH PROVEN
TRANSFER UI = CURRENT SOURCE VALID; DATA LIMITATION EXPLAINED
RECEIVE PURCHASE OPERATION ID = COMPLETE
DETAILED REPORTS = OPEN / ROOT CAUSE NOT PROVEN
BROWSER E2E = OPEN
GLOBAL INVENTORY ZERO-DEBT = NOT YET DECLARED 100% CLOSED
GOLD/DIAMOND = OPEN
```

## 16. GOVERNANCE RULE

```text
REPORT
↓
PRIMARY SOURCE
↓
CURRENT GIT
↓
CURRENT SOURCE
↓
CURRENT PRODUCTION
↓
CURRENT DATABASE
↓
CURRENT DEPLOYMENT
↓
REPRODUCTION
↓
ROOT CAUSE
↓
SURGICAL FIX
↓
STATIC VERIFY
↓
DEPLOY
↓
RUNTIME VERIFY
↓
BROWSER E2E
↓
CLOSE
```

هذا التسلسل هو نقطة البداية الإلزامية لأي مساعد أو CTO لاحق.