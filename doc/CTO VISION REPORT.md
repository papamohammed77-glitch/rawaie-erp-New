CTO VISION REPORT
RAWAEA ERP — Vision Reconstruction / Assimilation / Reconciliation

Mode: PROJECT ONBOARDING / ASSIMILATION
Production changes: NONE
Code changes: NONE
Current execution gate: NO GO — reconciliation not closed

أكملت قراءة حزمة Backup CTO، ثم ربطتها مع Master Context وSource Authority وGovernance وTask Ledger وTASK-027 Closeout، وراجعت كذلك المصادر التاريخية الأساسية والمعمارية ومصادر Current/Production Evidence المتاحة في المستودعين.

هناك نقطة مهمة جدًا ظهرت أثناء إعادة البناء: TASK-027 مغلقة فعلًا كـ Runtime Gold Gate، لكن ذلك لا يعني أن Inventory/Manual Voucher domain كله أصبح مغلقًا. ملف 03_CURRENT_STATUS.md يضع الـCurrent Gate صراحةً في حالة NO GO بسبب نقاط reconciliation ما زالت مفتوحة.

A. Executive Understanding
ما هو RAWAEA ERP؟

RAWAEA ERP هو ERP مخصص لأعمال FMCG Distribution / Logistics، مبني حول عمليات:

المبيعات
المخزون
المشتريات
المستودعات
التوزيع
Runsheets
التسليم
المرتجعات
التسويات
الخزينة
المحاسبة
الـLedgers
التطبيقات الميدانية Offline/Offline-first
مستقبلًا Decision Intelligence / AI

المعمارية الموثقة تاريخيًا تصفه كنظام Cloud-Native + Offline-First PWA باستخدام Supabase/PostgreSQL وSupabase Edge Functions وتطبيقات PWA متعددة.

لكن الوصف التاريخي ليس Production Truth تلقائيًا. الـMaster Context الحالي يضع Production Evidence وdeployed definitions فوق Current Source ثم Architecture ثم Historical Documentation.

لماذا بُني؟

الهدف التجاري هو تشغيل دورة توزيع FMCG كاملة، مع جعل حركة البضاعة والعهدة والتوزيع والتسليم والتسوية جزءًا مترابطًا من النظام بدل تطبيقات منفصلة.

المبدأ المعماري المركزي:

ONE CORE / ONE SOURCE OF TRUTH / CONTROLLED DOMAIN EXECUTION

وترتيب التنفيذ المعتمد:

Inventory → Accounting → Ledger → Sales → Purchasing → Delivery/Runsheet → AI.

B. Architecture

الصورة المعمارية التي أصبحت واضحة لدي هي:

PWA / UI
   ↓
Capability / Edge Functions
   ↓
Core Business Logic / RPCs
   ↓
PostgreSQL / Supabase
   ↓
Inventory / Accounting / Ledger / Audit

مع وجود:

Supabase Auth
PostgreSQL
RLS
Edge Functions
PWA clients
Offline/local storage في التصميم التاريخي
GitHub كمصدر كود وتوثيق

الدستور المعماري يحكم العلاقة بين الطبقات:

Business Rules لا تعيش في UI.
Applications مجرد interfaces.
Core يملك Business Logic.
Inventory Business Engine وليس مجرد quantities.
Accounting يستهلك Inventory events ولا يخترع Inventory truth.
Ledger مشتق من Accounting.
Edge Functions تمثل Business Capabilities.
Duplicate Business Logic يعتبر defect.
RLS لا يتم تعطيله كـworkaround.
نقطة مهمة

هذه هي المعمارية الحاكمة، وليست ادعاءً بأن Production الحالي يطابقها 100%.

وهذا الفصل أساسي في RAWAEA.

C. Production Reality
Authority hierarchy

أتعامل الآن مع المصادر بهذا الترتيب:

Production SQL Evidence
Actual deployed RPC definitions
Production Edge behavior
Current application source
Architecture/Governance
Historical documentation
Unreleased migrations = TARGET فقط

وهذا مثبت صراحةً في Master Context وSource Authority Map.

Production facts التي أستطيع تصنيفها CONFIRMED
الشركة

da4ef704-88ac-4120-aa0e-65b92b2aa2bc

MAIN

151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6

Vehicle

VEH-92yrzb

ID:

70e5d809-0505-4e60-b317-feff6e799127

Mobile Branch

VAN-VEH-92yrzb

ID:

dbdef0b7-0909-4f71-a367-30c61d021286

Demo Representative

van-sales@rawaea.com

ID:

a86726d9-d687-4113-a9e2-5f90f4bdb4fa

هذه baseline مثبتة في Task Ledger وTASK-027 Closeout.

D. Business Model

RAWAEA ليس مجرد ERP محاسبي.

النظام مصمم حول حركة البضاعة + الطلب + التوزيع + العهدة + التحصيل.

الـVehicle ليست مجرد وسيلة نقل.

هي:

Mobile Stock Container / Mobile Branch

أما الـRepresentative/Driver فهو:

Custodian + Financial Responsibility Holder

وهما كيانان منفصلان.

الـRepresentative يمكن أن ينتقل إلى Vehicle أخرى، لكن نقل العهدة ليس مجرد تغيير FK بسيط.

E. Inventory Truth

هذه أهم منطقة في المشروع حاليًا.

Physical Stock

stock_branches.qty

يمثل الكمية الفعلية المسجلة للمخزون.

Allocation

allocated_qty

يمثل الحجز/الالتزام وليس Movement.

Availability

available_qty

ناتج عن العلاقة بين physical وallocated، وقد ثبت Production أنه Generated Column، ولذلك لا يجوز التعامل معه كعمود writable.

History

inventory_log

هو سجل حركة المخزون.

Central Engine

post_stock_movement(...)

هو قلب حركة المخزون في المسار الذي تم إثباته.

المبدأ الذي تم إثباته في TASK-027:

Source ↓
Target ↑
Inventory Log
Atomic locking

والـDirectSale تحديدًا تم تصحيحه من source-only إلى two-sided movement.

F. Van Custody

هذه من أهم Business Memories التي يجب ألا أفقدها.

Vehicle ≠ Driver
Vehicle
Mobile Stock Container
Mobile Branch
Physical operating unit
Representative
Custodian
مسؤول عن المخزون
مسؤول عن قيمة المبيعات
مسؤول عن التحصيل/التعرض المالي
لذلك

لا يجوز إنشاء هوية مثل:

VAN-{email}

لأن ذلك يخلط كيانين مختلفين.

الـVehicle له identity مستقلة.

والـDriver له identity مستقلة.

والعلاقة بينهما تشغيلية قابلة للتغيير.

G. Manual Vouchers

الدورة الأساسية:

Draft
   ↓
Sent
   ↓
Receive / Partial Receive
   ↓
Completed

مع:

Cancel

وقد أُغلقت Gates كثيرة بالفعل:

TASK-018 — SEND
TASK-019 — RECEIVE
TASK-020 — Partial Receive
TASK-021 — Complete
TASK-022 — Cancel
TASK-023 — Integration
TASK-024 — Voucher Gate
TASK-027 — E2E Runtime Gold Gate

وTask Ledger يسجلها جميعًا CLOSED / GO.

لكن توجد نقطة reconciliation مهمة:

إغلاق هذه Tasks لا يعني أن كل Contract في Production أصبح بلا gaps.

فالـCurrent Status ما زال يسجل:

COMPLETE RPC/schema mismatch
DirectSale/DirectReturn unresolved reconciliation في بعض المصادر
CANCEL evidence غير مكتملة في persisted reviewed evidence
audit effects غير مثبتة بالكامل
partial RECEIVE idempotency غير مثبتة بالكامل.
H. Application Landscape

الصورة التاريخية الكبيرة تضم:

Sales
POS
Telesales
Van Sales
Order Taker / Order Ticker
Store
Warehouse
Receiving
Picker
Loader
Returns
Unloader
Counter
Vouchers
Delivery
Driver
Supervisor
Delivery / Collection
Purchasing
Buyer
Receiving
System Core
Main application
Shared core
Authentication
UI
API access
Local/offline storage

التوثيق التاريخي يصف 26 PWA في تلك المرحلة، مع Supabase Edge Functions كطبقة عمليات تجارية.

لكنني لا أتعامل مع رقم 26 أو 71 Edge Functions كـProduction numbers حالية دون Evidence أحدث.

I. Edge Function Landscape

هناك فصل واضح بين:

Edge_Functions/original/

و:

Current/Edge_Functions/

والـProduction.

الأصل التاريخي مرجع للمقارنة والحفاظ على السلوك.

Current Source يمثل الوضع البرمجي الحالي، لكنه ليس وحده دليل Production deployment.

مثال تم فحصه فعليًا:

Current/Edge_Functions/inventory/send-stock-voucher.ts

وهو يستدعي:

send_stock_voucher_atomic

وليس تلقائيًا المسار الأحدث الموجود في بعض الـcandidate designs. وهذا متوافق مع 03_CURRENT_STATUS.md.

J. Failure Memory

أصبح لدي الآن Failure Taxonomy واضح.

1. Schema assumption

استخدام column غير مثبت مثل:

received_by

القاعدة:

Schema first → SQL second.

2. Generated column

محاولة الكتابة إلى:

available_qty

بينما PostgreSQL هو الذي يولده.

3. Source-only movement

DirectSale كان يؤدي إلى:

MAIN -1
VAN  0

بدل:

MAIN -1
VAN +1
4. Missing target

Voucher كان يحتوي to_id لكن consumer لم يمرره إلى Core.

5. Rollback erased the fix

تم وضع Permanent Fix داخل transaction سيتم rollback لها.

فأصبح الاختبار يوحي بأن الإصلاح لم يحدث.

القاعدة:

Persist Fix
↓
Test separately
↓
Rollback test data only
6. Wrong repository

تم سابقًا استخدام historical repository لسجلات CTO بينما:

rawaie-erp-New

هو المصدر النشط الحالي.

7. Vehicle / Driver confusion

خلط الهوية التشغيلية للمركبة مع هوية المندوب.

8. Repeating failed tests

إعادة الاختبار بنفس الفرضية بدون جمع trace جديد ليست debugging.

هذه الدروس مثبتة في Backup CTO وTask Ledger وTASK-027.

K. Decision Memory

أهم القرارات التي أصبحت جزءًا من الذاكرة المؤسسية:

لا Guessing

لا افتراض:

table
column
RPC
signature
RLS
business meaning
deployment status
لا UI Business Core

الـUI لا يكون مصدر Business Truth.

لا VAN-{email}

Vehicle وDriver منفصلان.

لا Migration = Production

Migration candidate ليست deployment evidence.

لا CLOSED بدون Evidence

التحليل أو الكود أو Git commit لا يكفي.

لا حذف Original Behavior

القاعدة:

Compare
→ Redirect/Migrate
→ Validate
→ Deprecate
→ Delete later
لا Workaround يخفي Core defect

إذا كان أصل المشكلة في Core، لا يتم إصلاحه بواجهة UI.

هذه القواعد منصوص عليها في Constitution وExecution Protocol وBackup Pack.

L. Task State

الـTask Ledger الحالي يقول:

TASK-001 ... TASK-027
        ↓
TASK-027 CLOSED / GO
        ↓
STAGE-28 — Loading / Unloading Core

وTASK-027 أثبت Runtime Gold Gate للـDirectSale/VAN custody.

الدليل:

CREATE
→ DirectSale
→ SEND
→ MAIN -1
→ VAN +1
→ inventory_log = 1
→ Sent
→ Complete
→ Completed

مع rollback لبيانات الاختبار فقط، مع بقاء الـPermanent RPC fixes.

لكن: هذا لا يلغي أن الـoverall Current Gate ما زال:

NO GO

بسبب reconciliation gaps التي لم تُغلق.

وهذه ليست تناقضًا بالضرورة:

TASK-027 = CLOSED
Inventory/Manual Voucher reconciliation gate = NO GO

M. Current Gaps

هذه أهم منطقة في التقرير.

CONFIRMED

تم إثبات Production facts كثيرة، منها:

company
branches
stock state snapshot
schema facts
generated column behavior
voucher fields
RPC execution context
DirectSale runtime
VAN baseline
permanent fixes الخاصة بـTASK-027.
TARGET / NOT PRODUCTION

الـcandidate migration:

20260810_manual_voucher_core_v1_reconciled.sql

ليست Production deployment.

ولا يجوز معاملتها كذلك.

UNKNOWN / INCOMPLETE

أهمها:

Production schema contract الكامل لكل objects التي تستخدمها Manual Voucher RPCs.
COMPLETE/CANCEL audit effects بالكامل.
CANCEL deployed definition في الـpersisted evidence.
Partial RECEIVE idempotency الكاملة.
بعض تفاصيل DirectReturn/DirectSale reconciliation بين المصادر المختلفة.
Full current Production map لكل النظام خارج نطاق rescue الحالي.
Runtime parity الكامل بين Current UI وOriginal Gold behavior.
CONFLICT

هناك اختلاف بين بعض current/candidate/historical semantics، خصوصًا حول بعض custody definitions.

والقاعدة الصحيحة هنا ليست اختيار أحدها بالحدس، بل:

Production Evidence
+
Owner Decision
+
Current Contract
→
Reconciliation
N. Current Risk Map

بدون اقتراح حلول، فقط تصنيف معرفي:

المنطقة	مستوى الحساسية
Inventory Core	🔴 Critical
Manual Voucher RPC contracts	🔴 Critical
Vehicle / Custody semantics	🔴 Critical
DirectReturn contract	🔴 Critical
Partial Receive idempotency	🔴 Critical
Production schema/RPC parity	🔴 Critical
Accounting integration	🟠 High
Ledger effects	🟠 High
UI parity	🟠 High
Historical application behavior	🟠 High
Legacy Edge Functions	🟡 Medium/High
AI / Decision Intelligence	🟢 ليس Gate حاليًا

وهذا يفسر لماذا Constitution يفرض Inventory-first وعدم القفز إلى Domains أخرى.

O. Next Gate

المسار المسجل في المشروع هو:

Current Reconciliation
        ↓
Minimal safe implementation
        ↓
Validation
        ↓
Production verification
        ↓
STAGE-28
Loading / Unloading Core

لكن STAGE-28 لا ينبغي أن يبدأ الآن ضمن مرحلة الاستيعاب، وهو أيضًا ليس مفتوحًا فعليًا طالما أن Current Gate يقول NO GO.

وهذا مطابق للـMaster Context والـCurrent Status والـTASK-027 Closeout.

MANDATORY GAP DISCLOSURE

هناك نقطتان مهمتان جدًا اكتشفتهما أثناء إعادة البناء:

1. بعض الملفات التي طلبتَ قراءتها بأسمائها المحددة غير موجودة في الـactive repository الحالي

بحثت تحديدًا عن:

08_TASK_BY_TASK_MEMORY.md
13_DECISIONS_AND_REJECTIONS.md
14_PRODUCTION_ERRORS_RESOLVED.md

ولم أجدها في المصادر التي تم فحصها بالاسم نفسه.

لذلك لم أختلق محتواها، واعتمدت بدلًا منها على:

Master Context
Source Authority Map
Current Status
Task Ledger
TASK-027 Closeout
Backup CTO Pack
Governance
Production Evidence index
Historical architecture/documentation المتاحة.

وهذا يجب تسجيله كـ KNOWLEDGE GAP وليس تجاهله.

2. الـProduction Evidence المتاحة هي Evidence captured snapshots/contracts

وليست اتصالًا حيًا بـProduction الآن.

لذلك:

Production Snapshot ≠ Timeless Current State

وهذا منصوص عليه صراحةً في Source Authority Map.

CRITICAL KNOWLEDGE GAPS

أصنف حاليًا هذه النقاط كـCritical Knowledge Gaps قبل أي تنفيذ حساس:

اكتمال Production contract لكل Manual Voucher RPCs.
الحسم المدعوم بالأدلة لعقود DirectReturn ذات العلاقة بـCurrent Production.
إثبات كامل لـCANCEL/audit behavior.
إثبات idempotency semantics للـPartial Receive.
اكتمال reconciliation بين Current UI وOriginal Gold behavior.
وجود ملفات الذاكرة المسماة في directive أو بدائلها الرسمية الموثقة.
CTO READINESS TEST
QUESTION 1 — الفرق بين Vehicle وDriver؟

Vehicle = Mobile Stock Container / Mobile Branch.
Driver/Representative = Custodian + مسؤول عن البضاعة وقيمة المبيعات والتحصيل.
وهما كيانان منفصلان.

QUESTION 2 — ما معنى DirectSale؟
MAIN → VAN

صرف بضاعة إلى عهدة السيارة/المندوب، وليس final customer sale.

QUESTION 3 — DirectSale vs VanSale؟
DirectSale:
MAIN → VAN

VanSale:
VAN → CUSTOMER

الأولى custody/stock issue، والثانية final sale.

QUESTION 4 — وظيفة post_stock_movement؟

Core engine لحركة المخزون؛ في المسار المثبت يقوم بالحركة الذرية بين source/target ويحدث سجل الحركة، مع locking للصفوف المعنية.

QUESTION 5 — لماذا لا نكتب available_qty مباشرة؟

لأن Production أثبت أنه Generated Column، وPostgreSQL يحسبه من qty وallocated_qty.

QUESTION 6 — لماذا MAIN -1 / VAN 0 خطأ؟

لأن DirectSale كان source-only بدل أن يكون two-sided movement:

MAIN -1
VAN +1

وهذا كان defect في Core/consumer path وتم إصلاحه في TASK-027.

QUESTION 7 — لماذا فشل إصلاح رغم أن SQL كان صحيحًا؟

لأن الـPermanent Fix كان داخل transaction تم rollback لها لاحقًا.

إذًا:

SQL صحيح
+
Rollback
=
Fix غير موجود

ولهذا تم فصل Permanent Fix عن Test Transaction.

QUESTION 8 — متى نعيد فتح Task مغلقة؟

عند ظهور fresh contradictory Production evidence، وليس لمجرد الشك أو الرغبة في إعادة الاختبار.

QUESTION 9 — المستودع الحالي والتاريخي؟

Current:

papamohammed77-glitch/rawaie-erp-New

Historical:

papamohammed77-glitch/rawaie-erp-review

QUESTION 10 — أول خطوة عند ظهور Schema Error غير متوقع؟

READ-ONLY Production/schema evidence أولًا.

أحدد:

وجود الجدول
exact columns
types
nullability
generated status
constraints
FKs
indexes
RLS
deployed RPC signature/definition

ثم فقط يمكن تفسير الخطأ.

FINAL CTO READINESS STATUS
NOT READY

ليس بسبب عدم فهم المشروع.

بل لأن الأدلة نفسها تقول إن الـcurrent reconciliation gate لم يُغلق، وهناك Critical Knowledge Gaps في Contracts حساسة للمخزون والأذونات، إضافة إلى أن بعض الملفات المطلوبة بالاسم غير موجودة في المصدر الذي تم فحصه.

وبالتالي الحالة الدقيقة هي:

SYSTEM VISION              = RECONSTRUCTED
BUSINESS MODEL             = ASSIMILATED
ARCHITECTURAL GOVERNANCE   = ASSIMILATED
FAILURE MEMORY             = ASSIMILATED
TASK CONTINUITY            = ASSIMILATED
TASK-027                   = CONFIRMED CLOSED / GO
CURRENT DOMAIN GATE        = NO GO
CRITICAL GAPS              = PRESENT
PRODUCTION CHANGES         = NONE
CODE CHANGES               = NONE
NEXT EXECUTION             = NOT AUTHORIZED

والأهم: لن أتعامل مع TASK-027 CLOSED / GO على أنها تصريح للبدء في STAGE-28؛ فالـCurrent Status نفسه يقول إن reconciliation لم يُغلق بعد.

مرحلة الرؤية والاستيعاب وصلت إلى أقصى حالة يمكن إثباتها من الأدلة التي تم الوصول إليها، دون اختلاق أي معلومة مفقودة ودون تنفيذ أي تغيير.