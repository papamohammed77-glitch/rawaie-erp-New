# Report725 — إعادة التحقق من تعارض دور المخزن الشامل

**التاريخ:** 2026-11-14 (Africa/Cairo)  
**Last Verified Event:** LVE-2026-11-14-725  
**نقطة الاستئناف السابقة:** LVE-2026-11-14-724  
**التقرير التاريخي المباشر:** Report718_WAREHOUSE_ROLE_MISMATCH_BOOT_RECOVERY_20261114.md  
**Operational repo:** papamohammed77-glitch/erp-frontend — main  
**Operational HEAD:** 531a63c0a9ba866c858d6623852fef6e807a8578  
**SMART ERP:** fiilmooggumokxanwiyx — ACTIVE_HEALTHY  
**Constitution:** SHA 3a6b1e220af8509e314e94df76563bbc6f84910d — read completely

## 1. الحكم التنفيذي

**ROOT CAUSE CONFIRMED — ACCOUNT ROLE MISMATCH, NOT A CORE/BOOT DEFECT.**

رسالة Console التي قدمها المالك تطابق حرفيًا بوابة الصلاحيات في Warehouse Hub. الجلسة التي وصلت إلى App.start أعادت من Supabase الدور النشط «مرتجعات»، بينما لا يسمح تطبيق المخزن الشامل إلا بالدور «مخزن شامل» أو المالك الموثق. التطبيق يخفي مساحة التشغيل ويعيد إظهار شاشة الدخول عمدًا، ويعرض مسار تبديل الحساب. هذا سلوك fail-closed مقصود وليس توقفًا في شاشة الإقلاع.

قاعدة Production تؤكد وجود حساب مستقل للمخزن الشامل مضبوط بالفعل، وحساب مستقل للمرتجعات. لذلك لم نغير الكود أو الدور أو الصلاحيات؛ التغيير المطلوب الآن هو استخدام الحساب الصحيح. توسيع بوابة الدور لقبول «مرتجعات» سيمنح حسابًا تشغيليًا محدودًا دخولًا إلى مساحة المخزن الشامل ويكون إصلاحًا خاطئًا.

## 2. نقطة الاستئناف والتاريخ

- CURRENT_STATE الحالي قبل هذا التحديث: SHA 3d7b2c47ea058be9ed08644416e017629d0dfdd1، وآخر حدث مثبت LVE-2026-11-14-724.
- Governance repo main HEAD: 26c6a05a06090faad8a044b63ceb1f75d242c18f.
- Report718 سبق أن أثبت السبب نفسه وأضاف زر تسجيل الخروج وتبديل الحساب في commit 3058c881fc5341dc370b4c6866d7e53824cf9280؛ ثم أضيفت مزامنة migrations في 71fa933b3b78fa480f2d50ffb292d1a5bd4f8fa9.
- Report719 وثّق عقد Core المشترك وصلاحيات تطبيقات المخازن.
- Report723 وReport724 هما آخر إغلاقين في مسار Parent Owner Auth، ولا يعيدان فتح مشكلة المخزن.

## 3. GitHub / Source Code — CONFIRMED

- Operational main HEAD الحالي: 531a63c0a9ba866c858d6623852fef6e807a8578.
- مقارنة 36a86359a0ba8d465eed2602cfefb590cd594c38 → 531a63c0a9ba866c858d6623852fef6e807a8578: commit واحد فقط، وتغييره الوحيد _forensic_current_main_extract.md. لا تغيير في warehouse.html أو core.js أو ملفات العمليات منذ commit 36a8635.
- warehouse.html blob: e1cf531deec5c092e007320e67a35e312528ed09.
- core.js blob: 2b2211a3f95049042e27a7b2ecbab3640a584942.
- main.html blob: f49586701ad83e52706bd55fae40b3d2a176e0f0؛ أداة الجلب أعادت SHA دون محتوى، لذلك لم أعتبر Parent main مقروءًا بالكامل في هذا الفحص.

### مسار الإقلاع الفعلي في warehouse.html

1. DOMContentLoaded يستدعي App.init.
2. App.init يستدعي RW_Auth.init.
3. RW_Auth.init يستعيد الجلسة الحالية من Supabase getSession ثم يستدعي get_my_effective_profile.
4. App.start يستدعي get_warehouse_hub_snapshot ويتحقق من تطابق user_id وcompany_id ونطاق الفروع.
5. بعد ذلك يشترط أن يكون active_warehouse_role مساويًا تمامًا لـ «مخزن شامل»، باستثناء المالك الذي تثبت هويته من المصدر المعتمد.
6. عند عدم التطابق، catch يخفي mainApp، ويظهر loginScreen، ويكشف switchAccountBtn لأن رسالة الخطأ تحتوي «الدور المخزني النشط».

الملف يحمل ../core.js بالفعل. ورسالة Core loaded successfully في Console المقدم متسقة مع هذا التسلسل؛ الخطأ يقع بعد تحميل Core وعند بوابة الدور.

### استعادة الحساب ومسار التبديل

- RW_Auth.init يستعيد جلسة Supabase المشتركة المخزنة؛ لذلك قد تنتقل جلسة حساب تطبيق المرتجعات إلى Warehouse Hub عند فتحه.
- زر switchAccountBtn موجود في HTML ومخفي افتراضيًا.
- App.start يكشفه فقط عند role mismatch، ويعرض البريد الحالي والدور.
- App.switchAccount يستدعي RW_Auth.doLogout، ويمسح حالة المستخدم والصلاحيات وكلمة المرور المحلية، ثم يعيد شاشة الدخول برسالة تطلب حساب «مخزن شامل».
- App.doLogin يعيد المصادقة ويحمّل الملف الفعال من get_my_effective_profile قبل إعادة App.start.

## 4. Supabase Production — CONFIRMED

- SMART ERP: ACTIVE_HEALTHY، PostgreSQL 17.6.1.
- migrations المسجلة: 788؛ أحدثها 20261114175736 owner_login_alias_sync_atomic.
- Edge Functions المنشورة: 100. لم يتم تعديل أو نشر أي Function في هذه المهمة.
- get_my_effective_profile يعيد active_warehouse_role من public.users، ولا يعتمد على نص الدور الظاهر في الواجهة.
- get_warehouse_hub_snapshot هو STABLE SECURITY DEFINER، ويفحص الشركة والمستخدم والصلاحية ونطاق الفروع.
- set_active_warehouse_role هو المسار المعتمد لتغيير الدور، ويتطلب مدير النظام أو صلاحية warehouse_supervisor، ويقيد الهدف بعضوية مخزنية/أمين مخزن داخل الشركة ونطاق فروع المشرف. لم يُستدعَ للتحديث ولم يحدث أي تغيير دور.

### الحسابات الفعلية

| الحساب | الوظيفة | الدور المخزني النشط | الحالة | النطاق |
|---|---|---|---|---|
| storekeeper@rawaea.com | أمين مخزن | مخزن شامل | Active | BR-01 |
| returns@rawaea.com | مخزني | مرتجعات | Active | BR-01 |

الاستعلام على جميع الحسابات النشطة ذات active_warehouse_role أكد أن returns@rawaea.com هو الحساب النشط الوحيد بدور «مرتجعات»، وأن storekeeper@rawaea.com هو الحساب النشط المعيّن «مخزن شامل».

### تحقق RPC للملفين

أُجري التحقق داخل معاملات مؤقتة باستخدام SET LOCAL ROLE authenticated وتعيين claims محلية ثم SELECT فقط، مع ROLLBACK في نهاية كل معاملة:

- storekeeper@rawaea.com: get_my_effective_profile أعاد «مخزن شامل» وصلاحيات warehouse وbranches وdash وitems. get_warehouse_hub_snapshot أعاد success=true، والنطاق BR-01، وmain_branch_access=true.
- returns@rawaea.com: get_my_effective_profile أعاد «مرتجعات». get_warehouse_hub_snapshot أعاد success=true والنطاق BR-01؛ لذلك تصل الواجهة إلى بوابة الدور ثم ترفض دخول Hub.

EXECUTE الحالي لكل من get_warehouse_hub_snapshot وset_active_warehouse_role: anon=false، authenticated=true، service_role=true.

### ملاحظة صلاحيات مستقلة — P2 / REVIEW REQUIRED

هناك فرق مقصود أو محتمل بين بوابة الواجهة وعقد snapshot:
- الواجهة لا تسمح إلا بـ «مخزن شامل» أو المالك.
- RPC snapshot يسمح حاليًا بالأدوار المخزنية المعتمدة كلها، ومنها «مرتجعات»، ويعيد لها أرقامًا إجمالية مثل pending_purchase_orders وactive_runsheets وopen_counts قبل أن ترفض الواجهة فتح Hub.
- هذه أرقام إجمالية وليست صفوف مستندات، وقراءة الشركة والفروع ما زالت محكومة داخل الدالة. لكن جدول runsheets لا يحتوي branch_id، واستعلام عدّ الرحلات في الدالة على مستوى الشركة عند تحقق main_branch_access.

هذا لا يسبب رسالة الإقلاع، ولا يثبت تسرب صفوف أو أرصدة. لكنه فرق في تقليل البيانات حسب الدور يستحق قرارًا صريحًا: هل يجوز لكل مستخدم مخزني رؤية مؤشرات Hub الإجمالية، أم تقتصر على المخزن الشامل؟ لم تُعدّل الدالة؛ أي تضييق لها يحتاج ChangeSet وموافقة مالك لأن ذلك تغيير Production.

## 5. CI / Browser E2E — CONFIRMED SOURCE TEST

- Workflow: RAWAEA — Standalone Unified Warehouse E2E.
- Run: 43624957517.
- HEAD المختبر: 36a86359a0ba8d465eed2602cfefb590cd594c38.
- النتيجة: SUCCESS، وكل خطوات Job standalone-warehouse اكتملت بنجاح.
- علامات الاختبار ذات الصلة:
  - WAREHOUSE_ACTIVE_ROLE_GATE_AND_SAFE_ACCOUNT_SWITCH=PASS
  - WAREHOUSE_ACCOUNT_AND_MODULE_LOGOUT_CLEANUP=PASS
  - WAREHOUSE_LOGOUT_RELOGIN_MODULE_REINITIALIZATION=PASS
  - WAREHOUSE_SHARED_AUTH_AND_FOUR_TAB_SHELL=PASS
  - WAREHOUSE_SIX_FULL_NATIVE_OPERATION_WORKSPACES=PASS
  - WAREHOUSE_SEVEN_MANUAL_VOUCHER_ACTIONS=PASS
  - PARENT_NO_DATA_WRITES=PASS

اختبار الدور المقيد في هذا الـE2E يستخدم fixture بدور تحميل، وليس جلسة Production لحساب Returns. لكنه يختبر نفس شرط رفض كل دور غير «مخزن شامل» وإظهار زر التبديل، ثم اختبار الخروج وإعادة الدخول. لا أصف هذا بأنه Production authenticated E2E.

## 6. Deployment / Runtime

- Cloudflare Pages check لمشروع rawaea-erp على HEAD 531a63c: SUCCESS، check run 132539034437، مع Preview URL: https://a08e68fc.rawaea-erp.pages.dev.
- هذا يثبت نجاح نشر المشروع على هذا الـHEAD، ولا يثبت وحده أن alias الإنتاج المخصص أو جلسة المستخدم المصادق عليها تعرض السلوك نفسه.
- check منفصل لمشروع warehouse-supervisor على HEAD نفسه ظهر FAILURE، ورقم check 132538957776؛ لا تتوافر تفاصيل build logs في مصدر GitHub المقروء هنا. لم أخلط هذا الفشل مع نشر rawaea-erp.
- محاولة قراءة صفحة Cloudflare المنشورة عبر المتصفح لم تنجح في هذه الجلسة، كما لم تتوفر جلسة Browser مصادق عليها. لذلك artifact النهائي على alias الإنتاج ونجاح دخول الحساب الحقيقي يظلان UNVERIFIED.
- Console الذي أرسله المالك دليل Runtime مباشر على ظهور رسالة role mismatch، لكنه لا يعرض البريد الإلكتروني للجلسة.

## 7. أثر البيانات والسلامة

الاستعلامات على Production كانت SELECT وقراءات catalog فقط. محاكاة هوية authenticated كانت داخل معاملات محلية وانتهت بـ ROLLBACK. لم يحدث:
- DML أو DDL أو migration أو تغيير RLS/ACL.
- تعديل مستخدم أو active_warehouse_role أو صلاحية.
- استدعاء مسار حركة مخزون أو ترحيل إذن.
- حركة مخزون أو خزينة أو صندوق أو عهدة أو قيد أو دفتر مورد/عميل.
- إنشاء QA rows أو عمليات اختبار في Production.

العدادات الحالية:
- receiving=4، receiving_details=7.
- runsheets=4، run_sheet_details=19.
- stock_vouchers=0، stock_voucher_details=0.
- inventory_counts=1، inventory_count_details=35، inventory_log=83.
- erp_operation_registry=98.
- journal_entries=21، supplier_ledger=3.

تتطابق أهم عدادات المخزن مع خط الأساس المثبت في LVE-719: receiving=4، receiving_details=7، stock_vouchers=0، stock_voucher_details=0، inventory_counts=1، inventory_count_details=35، inventory_log=83، erp_operation_registry=98.

## 8. تفسير Console

- تحذير cdn.tailwindcss.com صادر عن تحميل Tailwind من CDN في رأس warehouse.html. هو تحذير إنتاجي غير حاجب، وليس سبب عدم الدخول.
- core.js loaded successfully يؤكد أن تحميل Core لم يتوقف عند الرسالة المعروضة.
- [Warehouse] boot failed هو سجل catch عام يجمع فشل الإقلاع وفشل التفويض. في الحالة الحالية، الرسالة الداخلية تحدد رفض الدور صراحة.
- إبقاء loginScreen ظاهرًا بعد الرفض إجراء أمني مقصود، وليس شاشة تحميل معلقة.

## 9. القرار والإجراء التالي

**لا يلزم تغيير source أو database لإصلاح الحالة المعروضة.**

الإجراء المطلوب:
1. من شاشة المخزن الشامل استخدم «تسجيل الخروج وتبديل الحساب» إن ظهر.
2. سجّل الدخول بحساب storekeeper@rawaea.com وكلمة مروره الحالية المعروفة للمالك، وليس بحساب returns@rawaea.com.
3. الحساب storekeeper مضبوط بالفعل على «مخزن شامل» ونطاقه BR-01، وقد اجتاز ملفه الفعال وRPC snapshot في تحقق القراءة.
4. بعد الدخول، تحقق من الانتقال إلى لوحة اليوم ثم أعد فتح التطبيق مرة واحدة للتأكد من استعادة الجلسة الصحيحة.

إذا كان المقصود أن يصبح حساب Returns نفسه هو أمين المخزن الشامل، فهذا قرار توزيع أدوار مختلف؛ ينفذه مشرف المخازن عبر set_active_warehouse_role بعد تحديد الحساب المستهدف، ولا يجوز استبدال الدور تلقائيًا.

**حالة الإغلاق:** ROOT CAUSE CONFIRMED — CORRECT ACCOUNT REQUIRED.  
**الجاهزية:** READY WITH LIMITATIONS — المصدر والعقود وProduction reads وCI والنشر موثقة؛ دخول Production المصادق عليه لم يُختبر.  
**الخطوة التالية الوحيدة:** تسجيل الدخول بالحساب المعيّن «مخزن شامل» ثم إثبات الانتقال الفعلي إلى لوحة المخزن. لا تُجرَ أي كتابة في Production ولا تعديل كود قبل ظهور دليل جديد.

---
