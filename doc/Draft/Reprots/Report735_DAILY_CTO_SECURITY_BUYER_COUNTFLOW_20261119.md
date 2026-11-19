# Report735 — مراجعة CTO اليومية: أمن المشاريع، Buyer، وCountFlow
**التاريخ:** 2026-11-19  
**وقت التحقق:** 23:08 تقريبًا — Africa/Cairo  
**آخر حدث مثبت:** LVE-2026-11-19-735  
**الحكم التنفيذي:** BLOCKED للتشغيل/الكتابة/النشر في نطاقي SMART ERP وCountFlow حتى معالجة مخاطر P0 واعتماد Change Set محدد. القراءة والتحليل والتوثيق فقط مسموحة حاليًا.

---

## 1. نقطة البداية والاستئناف

### مصادر الحالة والحاكمية
- مستودع الحالة: papamohammed77-glitch/rawaie-erp-New.
- CURRENT_STATE.md الحالي: blob 3e02eefbebf269c661b00635f5df4eecb80b2ad7، 2,534 سطرًا. آخر حدث داخله ما زال LVE-2026-11-08-719؛ لذلك هو متأخر عن Report733 وReport734 ولا يمثل وحده نقطة الاستئناف الأحدث.
- الدستور التشغيلي الدائم قُرئ كاملًا: doc/Draft/Reprots/الدستور التشغيلي الدائم.md، blob 3a6b1e220af8509e314e94df76563bbc6f84910d.
- Report733 قُرئ كاملًا: Report733_BUYER_PARENT_MODAL_FORENSIC_AND_STAGED_REPAIR_20261119.md، blob d6eba8429cc0e2a4ec2000cbdb0d5ef870f2a4a5.
- Report734 قُرئ كاملًا: Report734_COUNTFLOW_DAILY_AUDIT_AND_ROLLBACK_VERIFICATION_20261119.md، blob b33479cf60c2ea6d7886c8e522e8c50a67a133ed.
- ملف الحالة المحلي لـCountFlow: blob 2eabcc4ae8dd41aec99f45493a0acdf08764a7c5، ويسجل LVE734.
- ملف الذاكرة Current/CTO/RAWAEA_PROJECT_MEMORY_117-02.md: blob 9c9ffe7c435bd8fc7d6d7902ff1bc46318e47773.

### نقطة Git الحالية
- المستودع التشغيلي: papamohammed77-glitch/erp-frontend.
- الفرع: main.
- HEAD الحالي: 4f7fba271d35d463364a5659f8e181dabad41215.
- نقطة المقارنة التشغيلية السابقة في Report733: ebb2a01d07c8dc1460bd4f577962a7b8c26be920.
- المقارنة: 228 commit ahead، و54 ملفًا متغيرًا، 0 behind.
- التغييرات ذات الصلة التي تمت مراجعتها: main.html، buyer.html، buyer.tailwind.css، Workflow البناء، خمس migrations، خمس rollback scripts، ملفا الاختبار، وملفات CountFlow. لم يظهر تغيير على core.js ضمن قائمة الملفات المتغيرة في هذه المقارنة؛ لذلك لم تُفتح مراجعة Core شاملة جديدة بلا سبب.
- ملف main.html كبير؛ تمت قراءة الـblob الحالي والسابق واستخراج الدالة المتغيرة RW_Purchases.savePO كاملة، لا الادعاء بقراءة الملف كله سطرًا بسطر.

**نقطة الاستئناف:** استكمال مساري Buyer/الاستلام بعد Report733، واستكمال CountFlow بعد LVE734، مع أولوية طارئة لمخاطر الصلاحيات التي ظهرت في المشروعين.

## 2. CONFIRMED

### 2.1 SMART ERP — خمس migrations جديدة مطبقة
مشروع Supabase fiilmooggumokxanwiyx بحالة ACTIVE_HEALTHY. سجل الترحيلات الحي يؤكد تطبيق خمس نسخ جديدة مرتبطة بمسار المشتريات:
- 20261119000955_buyer_po_invoice_atomic_eligibility_guards_20261119
- 20261119001800_buyer_po_invoice_idempotency_order
- 20261119002638_buyer_goods_custody_handover_progress_truth_20261119
- 20261119005759_quick_market_supplier_credit_receiving_atomic
- 20261119010201_quick_market_supplier_credit_receiving_trigger_guard

ملفا المصدر الأخيران اسمهما في Git 20261119004000_... و20261119005000_...؛ اختلاف timestamp بين اسم المصدر ونسخة Ledger الحية موثق أدناه كفجوة lineage، ولا يبرر إعادة تطبيق أي migration.

### 2.2 Edge Functions الحالية
- save-purchase-order: النسخة المنشورة v44، verify_jwt=true، ومحتوى المصدر المنشور مطابق بايتًا ببايت لملف Git الحالي.
- receive-purchase: النسخة المنشورة v18، verify_jwt=true، ومحتوى المصدر المنشور مطابق بايتًا ببايت لملف Git الحالي.
- مسار receive_quick_market_purchase_atomic لا يتيح EXECUTE لـanon أو authenticated؛ التنفيذ لـservice_role فقط عبر Edge Function. وظيفة receive-purchase تستخرج المستخدم من JWT، وتتحقق من سجل المستخدم النشط وملف الشركة والدور/الصلاحية، ثم تمرر بريد المستخدم المستخرج من Auth، لا بريدًا حرًا من جسم الطلب.
- purchase_create_po_invoice_atomic وpurchase_update_po_invoice_atomic متاحان لـauthenticated ويحتويان على تحقق auth.uid() وصلاحيات المشتريات.
- purchase_post_buyer_invoice_atomic يتحقق من هوية المستخدم وصلاحيات المشتريات والمالية قبل استدعاء مسار الترحيل المركزي.
- get_quick_market_receiving_queue_atomic يتحقق من المستخدم المصادق عليه ونطاقه.
- Trigger الحراسة app_private.guard_po_receiving_status موجود ومربوط بجدول receiving.

### 2.3 Buyer — السلوك المقصود في SQL
- إنشاء فاتورة مرتبطة بـPO يمر عبر purchase_create_po_invoice_atomic، ويتطلب PO معتمدًا، ويمنع تجاوز الكميات/الأسعار، ويُبقي الفاتورة Draft ولا ينشئ وحده حركة مخزون أو خزينة أو قيدًا.
- تحديث Draft مرتبط بـPO يمر عبر purchase_update_po_invoice_atomic ويمنع استبدال PO أو إضافة أصناف غير تابعة له أو تجاوز الكميات/الأسعار.
- إعادة المحاولة على نفس operation_id تُعاد كنتيجة idempotent قبل فحص تفرد رقم فاتورة المورد؛ وهذا ترتيب صحيح في النسخة الثانية من migration.
- buyer_goods_custody_get_invoice_handover_progress_atomic يعرض الكمية المثبتة بأحداث التسليم والكمية المتبقية؛ وحدث إثبات التسليم لا يغير رصيد المخزون أو الخزينة بذاته.

### 2.4 CountFlow — الهيكل الخاص به
مشروع Supabase rawaea-staging ref hfzznsiprnwkpayskzhu بحالة ACTIVE_HEALTHY، منفصل عن SMART ERP من حيث project ref.
- 21 جدولًا count_*.
- RLS مفعّل على الجداول الـ21.
- 70 Policy و72 FK معتمدة.
- لا توجد صلاحيات anon مباشرة على جداول count_*.
- عدد صفوف جداول CountFlow الـ21 = صفر؛ count_projects=0 وcount_members=0.
- عدد Auth users = 1,868.
- counting-provision-member وcounting-export-session منشورتان، JWT مطلوب، ومصدرهما مطابق لـGit.
- لا توجد حسابات CountFlow أو عضويات أو مشروع تشغيل فعلي.

## 3. UNKNOWN

1. Artifact المنشور من Cloudflare Pages لـmain.html وbuyer.html غير مثبت بربط deployment SHA أو مقارنة bytes.
2. Runtime Browser مصادق عليه غير متاح في هذا التشغيل؛ لا Console/Network أو DOM E2E.
3. لا يوجد عنوان نشر مؤكد لتطبيق CountFlow، ولا جلسة مستخدم CountFlow مصادق عليها.
4. لا يوجد اختبار cross-device فعلي لـRealtime أو reconnect أو latency.
5. لا توجد قياسات حقيقية لزمن إنجاز مهام Buyer أو Counter أو Supervisor على هاتف/لوحي.
6. لم تُنفذ مقارنة تنافسية حديثة مع SAP/Dynamics/Odoo/ERPNext/Daftra/Manager.io في هذا التشغيل؛ الأولوية كانت مخاطر الأمن والنزاهة.
7. لم تُراجع جميع تطبيقات RAWAEA أو جميع مستهلكي كل جدول في هذه الدورة؛ نطاق التغطية موضح أدناه.

## 4. CONFLICT

### 4.1 مشروع rawaea-staging ليس معزولًا عن legacy ERP داخله
التوجيه التاريخي لـCountFlow يحصر العمل في count_* وcounting-* ولا يسمح بتعديل كيانات ERP القديمة. الفحص الحي أثبت أن المشروع يحتوي 70 جدولًا عامًا خارج CountFlow، منها 65 جدولًا RLS معطلًا، و56 جدولًا لها صلاحيات DML لـanon. لذلك هو منفصل عن SMART ERP على مستوى المشروع، لكنه ليس قاعدة نظيفة أو معزولة عن legacy ERP داخل المشروع نفسه.

### 4.2 سياسة Supplier Credit / AP مقابل GRNI
المهاجرة الحية quick_market_supplier_credit_receiving_atomic تجعل الاستلام الفعلي المقبول في Supplier Credit ينشئ:
- حركة PurchaseIn للكمية المقبولة.
- قيدًا محاسبيًا Dr 124 / Cr 211.
- حركة في supplier_ledger.
- حالة AP_OPEN.

وعند الاستلام الجزئي يمكن أن يظهر أثر المورد والقيد بينما تبقى حالة الفاتورة Draft/PartiallyPaid حتى اكتمال الاستلام. هذا يحقق شرط عدم الأثر قبل الواقعة الفعلية، لكنه يحسم محاسبيًا لصالح إثبات الالتزام مباشرة على حساب المورد عند الاستلام، لا على حساب GRNI مستقل ثم إعادة تصنيف عند اعتماد فاتورة المورد. Report733 سجل هذه السياسة كسؤال مالك مفتوح. التوجيه الحالي يؤكد أن رصيد المورد لا يتأثر قبل التسليم الفعلي، لكنه لا يحسم حساب المقابل المحاسبي. لا يجوز افتراض أن AP المباشر هو القرار المعتمد.

### 4.3 Lineage لترحيلات الاستلام
اسما ملفي Git 20261119004000 و20261119005000 لا يطابقان نسختي Ledger الحيتين 20261119005759 و20261119010201. العقود الحية موجودة والوظائف منشورة، لكن لا يوجد توثيق mapping رسمي يثبت لماذا اختلف timestamp.

### 4.4 الحالة المرجعية
CURRENT_STATE.md الجذري ما زال عند LVE719، بينما Report733 وReport734 أحدث منه. لا يصح اعتباره نقطة الاستئناف الوحيدة دون إلحاق الحدث الجديد به.

## 5. UNVERIFIED

- لم يُختبر نشر أو Runtime لأي تغيير في Buyer أو CountFlow.
- لم تُنفذ اختبارات SQL الجديدة الخاصة بـBuyer في هذا التشغيل؛ ملفاتها موجودة ومصممة للـrollback، لكن وجودها لا يثبت تشغيلها.
- لم يوجد اختبار rollback مخصص لمسار استلام Quick Market Supplier Credit الجديد.
- لم تُختبر معالجة التزامن الفعلي أو duplicate/out-of-order events.
- لم يُختبر offline الحقيقي بعد إغلاق المتصفح وإعادة فتحه.
- لم تُختبر كاميرا أو BarcodeDetector على جهاز فعلي.
- لم يُختبر التصدير XLSX/CSV من جلسة مستخدم حقيقية.
- لا يجوز وصف أي من هذه البنود بأنه PASS أو E2E.

## 6. مصفوفة التحقق حسب الطبقة

| النطاق | GitHub/Source | Supabase | Deployment Artifact | Runtime/E2E | Business Effects |
|---|---|---|---|---|---|
| Buyer PO invoice | CONFIRMED ضمن الملفات والدوال المتغيرة | CONFIRMED: migrations/functions/ACL | UNKNOWN | UNVERIFIED | لا QA records معروفة؛ لا اختبار جديد نُفذ |
| Quick Market Supplier Credit receiving | CONFIRMED | CONFIRMED: RPC/trigger/ACL | Edge v18 CONFIRMED | UNVERIFIED | لا توجد فواتير QMP Supplier Credit أو قيود QMP ناتجة حاليًا |
| CountFlow schema | CONFIRMED | CONFIRMED: 21/70/72 | UNKNOWN | BLOCKED | جميع جداول CountFlow فارغة |
| CountFlow state machine | CONFIRMED | CONFLICT: direct DML يتجاوز بعض RPC guards | UNKNOWN | UNVERIFIED | لا بيانات CountFlow |
| CountFlow Realtime | CONFIRMED كودًا وتريجرات | CONFLICT: إرسال Broadcast يسجل تحذيرات بسبب partitioning | UNKNOWN | UNVERIFIED | لا حدث cross-device مثبت |
| SMART ERP authorization | CONFIRMED كتالوجيًا | P0 exposure في role_permissions/categories | لا ينطبق | لم يُنفذ استغلال | لا كتابة أو تغيير من هذا التدقيق |

## 7. ما تم فعليًا في هذا التشغيل

- قراءة CURRENT_STATE الجذري والدستور كاملين.
- قراءة Report733 وReport734 كاملين.
- مقارنة main من checkpoint Report733 إلى HEAD الحالي.
- فحص الملفات المتغيرة ذات الصلة في Buyer وCountFlow.
- قراءة migrations الخمس وrollback scripts الخمس واختباري Buyer.
- مطابقة Edge v44 وv18 مع المصدر الحالي.
- فحص كتالوج Supabase في SMART ERP وrawaea-staging للـSchema/RLS/ACL/Functions/Triggers/Migrations/Advisors.
- فحص بيانات QMP ذات الصلة بعدد الصفوف فقط؛ لم تُقرأ بيانات فواتير أو موردين أو عملاء فردية.
- لم تُقرأ قيم password hashes أو رسائل بريد أو بيانات شخصية من جدول users.
- لم يُستدعَ أي RPC تشغيلي، ولم يُنفذ DML/DDL/ACL/RLS أو نشر أو إنشاء حساب.
- لم يُنفذ اختبار استغلال لأي مسار أمني.

## 8. تدقيق موثوقية التقارير السابقة

### Report733
- صحيح تاريخيًا كنقطة Buyer قبل التغييرات اللاحقة.
- لم يعد يصف المصدر الحالي كاملًا؛ بعده تغير main.html وbuyer.html وCSS وأُضيفت خمس migrations واختبارات.
- لا يُنقل حكمه السابق عن عدم تطبيق migrations إلى اليوم؛ Ledger SMART ERP يؤكد تطبيق خمس نسخ جديدة.
- لم يُعد فتح ملفات أو مسارات لم تتغير بلا دليل.

### Report734
- ما زالت أرقام CountFlow الأساسية صحيحة: 21 جدولًا و70 Policy و72 FK، و0 مشاريع/عضويات CountFlow، و1,868 Auth users.
- ملفات Counter وSupervisor لم تتغير منذ SHA المسجل في Report734.
- README تغير من blob 7b851737... إلى 70940904625bf51fb9d5168ce979e5ddb6f461f6.
- تقريره عن 53 migration باسم countflow_* صحيح لهذه المجموعة؛ Ledger الكلي يضم أيضًا 7 migrations تأسيسية باسم counting_*، فيصبح إجمالي CountFlow/Counting 60 من أصل 122 migration في المشروع.
- Report734 ذكر 1,992 تحذيرًا؛ القراءة الحالية سجلت 2,027، أي 35 تحذيرًا إضافيًا في العينة الحالية. لا يعني ذلك وحده 35 خطأ جديدًا في CountFlow.
- تقريره ذكر 70 legacy table داخل المشروع، لكنه لم يفصل مخاطر RLS/ACL للجدول users؛ الفحص الحالي كشف أن public.users مكشوف لـanon مع password_hash وصلاحيات DML. هذا اكتشاف جديد، ولا يُنسب إلى التقرير السابق.

## 9. الأمن والصلاحيات — P0

### 9.1 SMART ERP: role_permissions
المشروع fiilmooggumokxanwiyx:
- public.role_permissions عليه RLS، لكن Policy باسم Allow all for all من نوع ALL للـPUBLIC مع USING true وWITH CHECK true.
- ACL الجدول يمنح anon وauthenticated صلاحيات SELECT/INSERT/UPDATE/DELETE، ولا يوجد Trigger تدقيق على الجدول.
- يحتوي الجدول 21 صفًا موزعة على 3 role IDs.
- الدالة get_my_effective_profile() من نوع SECURITY DEFINER تقرأ role_permissions وتدمج مفاتيح الصلاحيات في ملف المستخدم.
- current_user_has_effective_permission يعتمد على ملف الصلاحيات الفعال.
- ثماني دوال قاعدة بيانات تستخدم role_permissions؛ كلها SECURITY DEFINER، لذلك يمكن حجب الوصول المباشر للجدول دون حجب قراءة هذه الدوال إذا اختيرت السياسة بعناية.
- Edge Function save-role v9 لا يكتب إلى جدول role_permissions مباشرة؛ يستخدم roles وusers وaudit_log.
- نتيجة ذلك: يمكن لمستخدم anon قراءة role IDs من الجدول المفتوح ثم إدخال/تعديل permission key، بما في ذلك *، لدور قائم؛ وبعد دخول مستخدم من ذلك الدور يمكن أن يحصل ملفه الفعال على صلاحيات أوسع. لم يُنفذ هذا المسار.

**التصنيف: P0 — مسار تصعيد صلاحيات مباشر مثبت من GRANT + POLICY + consumer function.**

### 9.2 SMART ERP: categories
- public.categories عليه RLS، لكن Policy Allow all for all تسمح بالقراءة والكتابة للجميع.
- ACL يمنح anon CRUD وTRUNCATE.
- main.html يقرأ categories مباشرة مع company filter في الاستعلام، لكن الحماية الحالية لا تفرض company filter من RLS.
- الكتابة التشغيلية التي تم تتبعها تمر عبر save-category Edge Function v6 مع verify_jwt=true والتحقق من المستخدم والصلاحية والشركة.
- لذلك صلاحيات anon المباشرة غير لازمة لمسار الكتابة الحالي، وتسمح بإفساد تصنيفات الشركات أو حذفها.

**التصنيف: P1 — تجاوز عزل الشركة وإفساد Master Data.**

### 9.3 SMART ERP: عناصر أخرى
- v_finance_employee_directory View مصنف security-definer؛ لا يملك anon SELECT، وauthenticated يراه عبر شرط الشركة وصلاحية Finance/HR أو سجل المستخدم نفسه. لم يثبت مسار anon مباشر، لكنه يحتاج اختبارًا بعد إصلاح role_permissions.
- get_public_store_catalog وget_public_store_order_tracking دالتان عامتان للقراءة. وظيفة تتبع الطلب تقبل order code أو phone منفردًا في بعض الفروع؛ يجب مراجعة قابلية تخمين المعرفات وكمية البيانات التي ترجعها. P2 privacy review.
- 24 جدولًا RLS enabled بلا Policy؛ هذا يمنع الوصول عبر RLS ولا يُصنف وحده كاختراق.

### 9.4 rawaea-staging: legacy ERP exposure
المشروع hfzznsiprnwkpayskzhu:
- 65 جدولًا عامًا خارج CountFlow لا يملك RLS.
- 56 جدولًا لها صلاحيات DML لـanon.
- public.users نفسه RLS معطل، وanon لديه SELECT/INSERT/UPDATE/DELETE/TRUNCATE.
- يحتوي public.users على 1,871 صفًا، ومن أعمدته password_hash وpermissions وrole وauth_id وبيانات الموظف. لم تُقرأ قيم هذه الأعمدة.
- role_permissions وcategories في هذا المشروع أيضًا RLS معطل وanon لديه صلاحيات CRUD.
- ثلاث دوال SECURITY DEFINER قابلة للتنفيذ من anon: post_inventory_adjustment_atomic وreceive_purchase_atomic وsave_sales_invoice_atomic.
- أجسام هذه الدوال تعتمد على p_user_email الممرر وتبحث عن سجل مستخدم، ولا تحتوي على تحقق auth.uid() يربط البريد بهوية المستدعي.
- بما أن جدول users نفسه قابل للقراءة والكتابة من anon، فإن بيانات الهوية والصلاحيات ليست حدًا أمنيًا موثوقًا لهذه الدوال.
- ست Edge Functions legacy من أصل 24 لها verify_jwt=false؛ لم تُختبر ولم تُعدل.
- تطبيق Counter وSupervisor يضعان URL وanon key الخاصين بالمشروع في HTML العام؛ وهذا متوقع تقنيًا لمفتاح anon لكنه يجعل سياسات المشروع هي الحاجز الأمني الفعلي.

**التصنيف: P0 — المشروع ليس معزولًا أمنيًا عن legacy ERP، ويوجد سطح كتابة مجهول الهوية يشمل بيانات المستخدمين ووظائف مخزون/شراء/بيع. لا يُسمح بنشر CountFlow أو إنشاء حسابات تشغيلية على هذا المشروع قبل الاحتواء.**

## 10. تدقيق Buyer — التغييرات الجديدة

### main.html
- Blob السابق: 1af4430e34bb5434327cb24a3dca50b538188f42.
- Blob الحالي: 00456494de918b36fc6792bef302319a9f65605d.
- التغيير داخل RW_Purchases.savePO() يحول إنشاء PO إلى Edge contract save-purchase-order / CREATE_PO، ويرسل items وoperation_id ويعتمد json.id وjson.code.
- الـpayload الحالي متوافق مع عقد Edge وRPC purchase_create_po_atomic.
- فجوة idempotency: operationId يُنشأ داخل كل استدعاء savePO() ولا يبقى ثابتًا عبر إعادة المحاولة بعد timeout/انقطاع رد. إذا نجح الخادم ولم يصل الرد ثم ضغط المستخدم حفظًا مرة أخرى، سينشأ operation ID جديد، فلا تتعرف قاعدة البيانات على أنها إعادة المحاولة نفسها. لا يوجد دليل على duplicate فعلي؛ الخطر في نمط إعادة المحاولة.
- لا يوجد في الدالة نفسها إبطال صريح لكاش قائمة PO أو إعادة تحميلها بعد النجاح؛ يعتمد ظهور المستند فورًا على تحديث مشترك أو إعادة تحميل لم يُثبتا.

**P1:** تثبيت operation ID على مستوى نموذج PO حتى النجاح أو تغير الحمولة، ومنع النقر المكرر، ثم refresh/invalidate لقائمة PO بعد النجاح.

### buyer.html
- SHA الحالي: 387a26c9ef43818430f88f8af143f785aada188f.
- التغيير يضيف عرض handed_over_qty وremaining_qty وشرط إظهار إجراء إثبات تسليم السوق السريع.
- invoiceOperationId يُنشأ عند بدء رحلة إنشاء الفاتورة ويعاد استخدامه داخل المحاولة نفسها؛ هذا أفضل من سلوك parent savePO الحالي.
- إجراء إثبات التسليم يستخدم operation ID، ويفحص نتيجة التقدم عند الشك في نجاح العملية، ولا يحذف ملف الإثبات إذا كانت النتيجة غير محسومة.
- لم يثبت تشغيل الواجهة أو نجاح upload حقيقي.

### CSS Workflow
- buyer.tailwind.css SHA الحالي: da868d771f365088e85384afd009aa7595b6ad8b.
- Workflow buyer-tailwind-build.yml SHA الحالي: 6800751cd76284cc70da520afa4cc6f110315c85.
- Workflow يجري Node syntax check للـinline scripts ثم يبني Tailwind، وله contents: write ويدفع CSS مباشرة إلى main. يوجد commit آلي من github-actions لتحديث CSS.
- هذا ليس Deployment ولا Browser E2E. يجب إبقاء صلاحية الكتابة الآلية إلى main تحت مراجعة حوكمة؛ لا يوجد دليل على حماية branch أو موافقة مراجعة قبل كل push.

## 11. تدقيق مسار الاستلام وSupplier Credit

- receive-purchase v18 يتحقق من JWT ويجلب Auth user ثم يطابق سجل المستخدم النشط والشركة والدور/الصلاحية.
- مسار PO يستخدم receive_purchase_atomic، والدالة تتحقق من دور الاستلام/نطاق الفرع.
- مسار Quick Market Supplier Credit يستخدم receive_quick_market_purchase_atomic من خلال service_role بعد تحقق Edge.
- وظيفة receive_quick_market_purchase_atomic تقفل الفاتورة، تتحقق من source/settlement/branch/items/remaining quantities وoperation id، وتسجل receiving/details/custody event وstock movement.
- عند كمية مقبولة أكبر من صفر تنشئ قيدًا Dr 124 / Cr 211 وتضيف supplier ledger credit. لا تنشئ treasury/cash movement.
- عند الاستلام الجزئي يمكن أن تبقى حالة الفاتورة Draft بينما يظهر AP_OPEN والقيد على الكمية المقبولة؛ هذا يتطلب حسم سياسة GRNI/AP.
- Trigger الحراسة على receiving مثبت.
- Snapshot الحالي: لا توجد فواتير QUICK_MARKET + SUPPLIER_CREDIT، ولا قيود QuickMarketReceiving، ولا supplier ledger rows من هذا المصدر. إذن مسار الاستلام الجديد غير مستخدم بعد ولا يوجد أثر حي منه حتى وقت الفحص.
- توجد 6 receiving documents و8 details مرتبطة بفواتير شراء في قاعدة SMART ERP، لكنها لا تثبت استخدام QMP Supplier Credit؛ لا تُنسب إليها هذه الوظيفة.

## 12. الاختبارات وجودتها

### Buyer
يوجد ملفان SQL:
- supabase/tests/buyer_po_invoice_atomic_eligibility_guards_20261119.sql
- supabase/tests/buyer_goods_custody_handover_progress_20261119.sql

كلاهما يستخدم نمط DO/exception subtransaction مع sentinel rollback، ويحتوي Assertions لعدم أثر المخزون/المالية في إنشاء Draft وإثبات التسليم. لم يُنفذا في هذا التشغيل بسبب P0 في طبقة الصلاحيات، وعدم وجود بيئة معزولة آمنة. وجود الملف لا يساوي PASS.

لا يوجد اختبار مخصص لـreceive_quick_market_purchase_atomic يغطي:
- partial receipt ثم full receipt.
- duplicate operation replay.
- unauthorized actor / branch mismatch.
- stock movement + journal + supplier ledger.
- no treasury/cash movement.
- rollback reconciliation.

### CountFlow
Report734 أثبت سابقًا اختباري 90k import وlocation heatmap داخل rollback، لكن هذا لا يثبت Browser E2E أو تشغيلًا ميدانيًا. لم يُعاد تشغيلهما اليوم؛ لا يوجد تغير في كود CountFlow يبرر تكرار الاختبارين.

### سبب إيقاف الاختبارات
وجود مسار P0 مجهول الهوية في SMART ERP وrawaea-staging يجعل أي كتابة اختبارية جديدة غير مناسبة قبل احتواء ACL/RLS. لم تُنفذ أي كتابة دائمة أو rollback test جديد في هذا التشغيل.

## 13. CountFlow — صحة المنتج والتطبيقين

### قاعدة البيانات والترحيلات
- Ledger الكلي في rawaea-staging: 122 migration؛ منها 53 باسم countflow_* و7 تأسيسية باسم counting_*.
- مجلد migrations يحتوي 14 SQL files فقط؛ 46 migration مطبقة لا يوجد لها ملف مستقل حاليًا.
- ملف migration archive موجود لكنه سجل استعادة/مراجعة، وليس migration قابلة لإعادة التطبيق تلقائيًا.
- README الحالي blob 70940904625bf51fb9d5168ce979e5ddb6f461f6.
- Migration README الحالي blob a9b7912309259a6ecb109efada17960238848b1a.
- Migration archive الحالي blob d63f...؛ لا يُعاد تطبيقه.
- هذا يضعف قابلية إعادة البناء حتى لو كان Schema الحالي قائمًا.

### صلاحيات الجداول الحرجة
تمت إعادة مطابقة GRANT + Policy + Trigger + RPC:
- count_sessions: authenticated supervisor لديه UPDATE/DELETE مباشر؛ لا State Guard يمنع انتقالات غير صحيحة.
- count_reconciliation_runs: UPDATE مباشر يسمح بتجاوز count_approve_reconciliation.
- count_recount_tasks: UPDATE/DELETE مباشر يتجاوز count_review_recount_task.
- count_import_rows: UPDATE/DELETE مباشر؛ لا Trigger تدقيق أو State Guard.
- count_alerts: UPDATE مباشر؛ لا Audit Trigger ولا سبب إلزامي.
- count_import_batches: UPDATE/DELETE مباشر؛ يوجد Audit للحالة لكن لا State Guard.

هذه فجوات P1 داخل دور المشرف، وليست صلاحية anon على جداول CountFlow.

### Recount بعد الاعتماد
count_generate_recount_tasks يقبل run.status = computed أو approved، والواجهة لا تمنع الاستدعاء بعد الاعتماد. بينما count_reconcile_session يرفض إنشاء جولة جديدة عند وجود جولة approved. يمكن إذن إنشاء مهام إعادة عد بعد اعتماد نهائي دون مسار واضح لإعادة التسوية؛ هذا تعارض دورة عمل P1.

### Offline
- Counter.html يستخدم IndexedDB queue، لكن queueCount() يربط العرض بالجلسة الحالية فقط.
- activateMembership() لا يحمل review/completed كجلسة نشطة.
- بعد تجميد الجلسة يصبح session=null وتختفي عناصر الطابور المحلية من العرض، ولا تستطيع syncQueue() إرسالها.
- retryQueueBtn يصفر sync_error لجميع عناصر الطابور بدل نطاق المشروع/العضو/الجلسة.
- لا توجد Service Worker registration أو manifest في الملفين؛ لذلك Offline queue لا يثبت Offline boot أو استعادة التطبيق بعد إغلاق المتصفح.

### Supervisor export
setSession(status) يعيد تحميل الجلسات قبل عدّ/تصدير الجلسة التي أُغلقت. loadSessions() يغير المتغير العام session؛ لذلك قد يكون null أو جلسة أخرى. المطلوب التقاط closingSessionId قبل التحديث وتمريره صراحة إلى التصدير.

### Realtime
- التطبيقان يشتركان في Broadcast channels خاصة.
- توجد triggers ترسل realtime.broadcast_changes.
- جدول realtime.messages partitioned parent، لكن لا توجد child partitions.
- سجل Supabase الحالي يحوي 2,027 warning attempts؛ 35 أكثر من العينة المسجلة في Report734.
- التحذير يصدر من مسار realtime.send عند محاولة الإرسال؛ لا يوجد دليل على وصول Broadcast إلى عميل.
- Supervisor لديه refresh احتياطي لخريطة المواقع كل 10 ثوانٍ، لكنه لا يغطي كل لوحات الجلسة/التنبيهات/الحضور. لذلك لا يصح وصف التزامن بأنه لحظي.

### UX/UI static audit
- Counter وSupervisor يحددان العربية وRTL وviewport.
- توجد media queries قليلة في الملفين؛ هذا فحص مصدر فقط، لا اختبار responsive.
- لا توجد aria-label صريحة في العناصر التي تم فحصها، ولا Service Worker/manifest في الملفين.
- لم تُختبر الكاميرا أو BarcodeDetector أو الطباعة أو لوحة المفاتيح أو focus أو التباين أو أجهزة فعلية.
- لا توجد حسابات أو مشاريع CountFlow؛ لا يمكن رسم رحلة ميدانية كاملة لأي دور.

## 14. صحة دورة الأعمال من المورد إلى المخزن

المسار الذي تثبته العقود الحالية:
1. PO ينشأ Draft/Approved دون حركة مخزون أو خزينة.
2. Buyer ينشئ PO invoice Draft مرتبطة بـPO؛ لا ترحيل بمجرد الإنشاء.
3. الاستلام الفعلي عبر Receiver/Edge يثبت الكميات المقبولة.
4. PO receipt يمر عبر receive_purchase_atomic، ويولد حركة المخزون والقيود وفق المسار المركزي.
5. QMP Supplier Credit receipt الجديد يمر عبر receive_quick_market_purchase_atomic؛ وهو غير مستخدم بعد.
6. إثبات تسليم البضاعة من المورد إلى عهدة المشتري يسجل custody event فقط ولا يغير المخزون.
7. اعتماد الفاتورة/التسوية يمر عبر RPCs منفصلة وصلاحيات منفصلة.
8. السداد/الخزينة لا يُستنتج من receipt أو Draft.

**الفجوة:** سياسة AP/GRNI غير محسومة، كما أن receive_quick_market_purchase_atomic لم يُختبر في rollback أو runtime. لا تُعلن دورة P2P مكتملة.

## 15. التخطيط والتنبؤ ومركز القرار الذكي

لم تُثبت في هذا التشغيل دقة توقع أو forecast مقابل actual، أو reorder point محسوب ومقاس، أو demand planning متعدد الفروع، أو cash-flow forecast. لا تُمنح درجة لهذه القدرات من وجود Dashboard أو جداول فقط. الحالة: UNKNOWN.

## 16. Benchmark التنافسي

لم يُنفذ بحث رسمي حديث في هذا التشغيل. المقارنة مع SAP S/4HANA، Dynamics 365، Odoo، ERPNext، Daftra، Manager.io، وNext ERP تبقى OPEN؛ يجب تحديد منتج Next بالناشر والإصدار قبل إدخاله في المقارنة. لا يوجد ادعاء تكافؤ أو تفوق.

## 17. مصفوفة النضج — نطاق الأدلة الحالي فقط

| المجال | الدرجة المحافظة | سبب التقييم |
|---|---:|---|
| السلامة التقنية والمعمارية | 1/5 | بنية وخدمات قائمة، لكن P0 authorization exposure |
| تكامل التطبيقات والبيانات | 2/5 | عقود وRPCs موجودة؛ Realtime غير مثبت وCountFlow direct DML |
| العمليات التجارية | 2/5 | Buyer/Receiving flows موجودة في المصدر، بلا Runtime E2E |
| الرقابة المالية والمحاسبية | 1/5 | مسارات مركزية موجودة، لكن AP/GRNI غير محسوم واختبار QMP غير موجود |
| المخزون وسلاسل الإمداد | 2/5 | Receiving/CountFlow schema موجودان؛ لا قبول ميداني |
| التوزيع والعمل الميداني | UNKNOWN | لم يفحص هذا النطاق اليوم |
| التخطيط والتنبؤ | UNKNOWN | لا قياسات forecast |
| التقارير وBI | 1/5 | Export code موجود؛ لا اختبار بشري أو قياس جودة |
| الأمان والصلاحيات والتدقيق | 0/5 | مسارات anon CRUD/permission escalation مثبتة |
| الأداء والاستقرار والتوسع | UNKNOWN | لا حمل أو latency قياسي |
| تجربة المستخدم والإنتاجية | 1/5 | RTL موجود؛ فجوات offline/export/accessibility وغياب Runtime |
| الجاهزية التشغيلية والتنافسية | 0/5 | P0 مفتوح، لا حسابات CountFlow ولا Browser acceptance ولا benchmark |

هذه درجات نطاقية مؤقتة وليست تقييمًا شاملًا لكل التطبيقات.

## 18. خريطة Parent/Core/Source of Truth

- لم يتغير core.js في المقارنة من checkpoint إلى HEAD.
- التغيير الحي في main.html محصور في مسار إنشاء PO داخل RW_Purchases.savePO.
- Edge save-purchase-order v44 هو المسار الخادمي الحالي لعمليات PO/Buyer، وEdge receive-purchase v18 هو مسار الاستلام.
- Parent يظل مصدر البيانات المرجعية والصلاحيات وفق العقود القائمة؛ لم يُجرَ تغيير على Router/Auth/Core.
- لا يوجد دليل نشر أو byte parity للـParent الحالي.
- لا يجوز اعتبار CountFlow جزءًا من SMART ERP؛ له project ref منفصل، لكن مشروع rawaea-staging يحتوي legacy ERP داخله.

## 19. مصفوفة المزامنة

| الكيان | Producer | المسار المركزي | المستهلك | الآلية | النتيجة |
|---|---|---|---|---|---|
| PO invoice | Buyer | save-purchase-order → purchase_create_po_invoice_atomic | Parent/Buyer | RPC + refresh/cache غير مثبت | Source/DB CONFIRMED، UI runtime UNKNOWN |
| PO receipt | Receiver | receive-purchase → receive_purchase_atomic | Parent/Inventory | DB transaction + Realtime محتمل | Edge/DB CONFIRMED، delivery UNKNOWN |
| QMP receipt | Receiver | receive-purchase → receive_quick_market_purchase_atomic | Inventory/Finance | DB transaction + Broadcast | غير مستخدم في البيانات الحالية |
| Count entry | Counter | count RPC/DB | Supervisor/Reports | IndexedDB + Broadcast | offline/realtime gaps |
| Session/reconciliation | Supervisor | RPCs مع direct DML بديل | Counter/Export | Broadcast + heatmap polling | State guard ناقص |

لا توجد قياسات latency، ولا إثبات cross-device delivery أو reconnect.

## 20. سجل التغطية

| النطاق | فُحص اليوم | ما لم يُفحص |
|---|---|---|
| CURRENT_STATE والدستور | كاملان | لا استثناء |
| Report733/734 | كاملان | تقارير أقدم غير ذات صلة مباشرة |
| Buyer | الملف المتغير والدوال ذات الصلة | كامل رحلة UI في Browser |
| Parent main.html | دالة savePO المتغيرة كاملة | كامل الملف 2MB وجميع المستهلكين غير المتأثرين |
| Supabase SMART ERP | migrations/RPC/ACL/Triggers/Advisors ذات الصلة | كل الجداول والـRPCs الأخرى |
| CountFlow | Counter/Supervisor/README/State/Migrations/Edge/Schema | بقية تطبيقات ERP |
| Deployment | لا دليل artifact | Cloudflare Pages/browser |
| Runtime/E2E | لا اختبار | جلسة بشرية/أجهزة |
| Benchmark | لم يُبحث | كل المنافسين والشركات النظيرة |

## 21. المخاطر والاعتماديات

- P0: role_permissions في SMART ERP مفتوح للكتابة من anon ويغذي effective permissions.
- P0: rawaea-staging.public.users مكشوف، RLS معطل، anon CRUD/TRUNCATE، ويتضمن password_hash.
- P0: ثلاث SECURITY DEFINER RPCs في rawaea-staging متاحة لـanon بلا ربط auth.uid بهوية المستخدم.
- P1: CountFlow direct DML يتجاوز state machine.
- P1: CountFlow Broadcast لا يثبت التسليم بسبب partition warnings.
- P1: Counter queue يختفي بعد review/completed.
- P1: Supervisor export قد يستخدم session id مختلفًا.
- P1: parent savePO لا يثبت operation id عبر retry.
- P1: AP/GRNI policy غير محسومة.
- P1: 46 migration artifact غير مستقلة في CountFlow.
- P2: categories public CRUD.
- P2: Buyer parent list refresh غير مثبت.
- P2: accessibility/Responsive/Offline boot غير مثبت.
- P2: public store tracking privacy review.
- P2/P3: advisor performance backlog.

## 22. Change Set المقترح — لا يُنفذ دون موافقة

### CS-735-P0-A — SMART ERP role_permissions
الأصل الحي:
- public.role_permissions ACL: anon=arwdDxtm وauthenticated=arwdDxtm.
- RLS=true، Policy Allow all for all، USING true وWITH CHECK true.
- 21 صفًا/3 أدوار، لا Triggers.
- المستهلك: get_my_effective_profile() SECURITY DEFINER، وثماني دوال SECURITY DEFINER أخرى تستخدم الجدول.
- لا يوجد direct table access في main.html أو save-role Edge v9 ضمن الفحص.

التغيير المقترح:
~~~~sql
BEGIN;
REVOKE ALL ON TABLE public.role_permissions FROM anon, authenticated;
DROP POLICY IF EXISTS "Allow all for all" ON public.role_permissions;
COMMIT;
~~~~
السبب: جميع المستهلكين الذين عُثر عليهم SECURITY DEFINER؛ قراءة الجدول تستمر داخل الوظائف الموثوقة، بينما يُغلق direct PostgREST access.
ما لن يتغير: بيانات الأدوار والصفوف والدوال المركزية.
اختبارات القبول: anon/authenticated direct SELECT/INSERT/UPDATE/DELETE مرفوض؛ get_my_effective_profile يعيد نفس الصلاحيات المتوقعة؛ save-role وRLS policies تعمل.
لا يُنفذ دون موافقة صريحة.

### CS-735-P0-B — SMART ERP categories
الأصل الحي:
- ACL يمنح anon/authenticated CRUD/TRUNCATE.
- Policy Allow all for all.
- main.html يقرأ مع company_id؛ الكتابة المتتبعة عبر save-category Edge v6 مع JWT/permission/company checks.

التغيير المقترح:
~~~~sql
BEGIN;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.categories FROM anon, authenticated;
DROP POLICY IF EXISTS "Allow all for all" ON public.categories;
GRANT SELECT ON TABLE public.categories TO authenticated;
CREATE POLICY categories_company_select
ON public.categories FOR SELECT TO authenticated
USING (company_id = app_private.current_user_company_id());
COMMIT;
~~~~
الاختبارات: anon لا يقرأ/يكتب؛ authenticated يقرأ شركته فقط؛ create/update/delete عبر save-category Edge المصرح فقط.
يجب فحص مستهلكي public storefront قبل التنفيذ النهائي.

### CS-735-P0-C — rawaea-staging legacy containment
لا توجد صيغة SQL آمنة واحدة لكل 65 جدولًا دون inventory كامل لسياسات كل تطبيق legacy. الخيارات التي تحتاج قرار مالك:
1. السماح بقفل legacy tables/functions في المشروع الحالي مع RLS/ACL مصمم لكل مستهلك.
2. عزل CountFlow في schema مستقل داخل المشروع الحالي وتعديل exposed schemas/clients/Edge/Realtime؛ هذا Change Set معماري كبير.
لا يُنشأ مشروع Supabase جديد، ولا تُعدل legacy objects قبل قرار صريح.
الحد الأدنى الذي يجب إغلاقه: public.users، role_permissions، categories، 56 جدول anon-DML، وثلاث RPCs الخطرة.

### CS-735-P1-D — CountFlow workflow boundary
- منع direct DML على جداول الحالة الحساسة.
- جعل session transitions وalert resolution وimport/recount/reconciliation عبر RPCs فقط.
- منع إنشاء recount tasks بعد approved.
- إضافة Audit/State Guards واختبارات رفض direct DML.

### CS-735-P1-E — CountFlow offline/realtime
- إبقاء queue مرئيًا بعد تجميد الجلسة.
- إضافة sync acknowledgment لكل جهاز قبل الإغلاق.
- حصر retry في scope الصحيح.
- إصلاح closingSessionId.
- إصلاح Realtime partition/service delivery أو اعتماد polling موحد مثبت.

### CS-735-P1-F — Buyer idempotency
- حفظ operation ID ثابت على مستوى نموذج PO حتى النجاح أو تغيير الحمولة.
- منع النقر المكرر.
- تحديث parent list/cache بعد نجاح الإنشاء.
- اختبار retry بعد commit مع فقد الرد، والتأكد من رجوع نفس PO لا إنشاء PO جديد.

### CS-735-P1-G — Supplier Credit policy
قرار مالك مطلوب: هل الاستلام يسجل GRNI ثم يعاد تصنيفه إلى AP عند اعتماد فاتورة المورد، أم يسجل AP مباشرة على الكمية المقبولة؟ لا تعديل أو اختبار ترحيل قبل الحسم.

## 23. الاختبارات ومعايير عدم التراجع

قبل أي Change Set:
1. Baseline read-only للـACL/RLS/Policies/Functions/Triggers والبيانات.
2. حفظ exact source/DB definitions.
3. اختبار anon denial وauthenticated role scoping.
4. اختبار جميع consumers المتأثرة.
5. اختبارات rollback-only داخل transaction مع إثبات عدم بقاء صفوف/حركات.
6. اختبار Edge/JWT/branch/role.
7. Browser E2E مصادق عليه بعد توفير حسابات وArtifact.
8. Reconciliation للمخزون والدفاتر والخزينة قبل/بعد.
9. عدم نشر أو DDL/DML حتى موافقة Change Set.

## 24. الجاهزية واستلام شعلة التطوير

- READY WITH LIMITATIONS للقراءة والتحليل والتوثيق فقط.
- BLOCKED لتشغيل CountFlow أو إنشاء حسابات عليه حتى احتواء legacy exposure في rawaea-staging.
- BLOCKED لأي كتابة في SMART ERP حتى إغلاق P0 role_permissions أو اعتماد استثناء أمني مكتوب.
- لا توجد حسابات CountFlow؛ لا يجوز اختيار أيًا من 1,868 Auth user أو 1,871 legacy public.users rows. لم تُنشأ حسابات.
- لا يوجد deployment/browser artifact مثبت؛ لا E2E.
- لا يوجد فرع أو مشروع جديد أو Edge Function جديد.
- لم تُنفذ أي تغييرات تشغيلية أو مالية أو مخزنية في هذا التشغيل.

## 25. التزام الدستور وحماية البيانات

- الدستور الحالي قُرئ كاملًا وسُجل SHA.
- لم تُعدل main.html أو core.js أو Buyer أو Counter أو Supervisor.
- لم تُنفذ DDL/DML/ACL/RLS/Edge deploy/Pages deploy.
- لم تُقرأ قيم password_hash أو عناوين البريد أو بيانات العملاء.
- لم يُستدعَ أي RPC يرحّل مخزونًا أو مالية.
- لم تُنفذ اختبارات جديدة في Production بسبب P0.
- التغيير الوحيد المطلوب حاليًا هو توثيق الحالة؛ لا يغير أي بيانات أعمال.

## 26. الخطوة التالية الواحدة

**إعداد واعتماد حزمة احتواء أمنية P0 للمشروعين قبل أي تشغيل أو اختبار جديد.** تبدأ بإغلاق direct anon access إلى role_permissions في SMART ERP، ثم احتواء public.users والـRPCs والـlegacy tables في rawaea-staging مع الحفاظ على CountFlow داخل المشروع الموجود فقط بعد تصميم حدود schema/API واضحة. السبب: هذه المخاطر تسبق أي تحسين UX أو استكمال حسابات أو اختبار ميداني، وقد تسمح بتغيير الصلاحيات أو البيانات من دون هوية موثوقة.

**معيار الإغلاق:** لا يستطيع anon قراءة/تعديل صلاحيات الأدوار أو بيانات المستخدمين أو تنفيذ RPCs مخزنية/مالية؛ وتستمر المسارات المصرح بها فقط عبر JWT/Edge/RPC المركزي، مع إثبات company/branch scoping واختبارات عدم الأثر. حتى ذلك الحين تبقى الحالة BLOCKED.

---
**نهاية Report735 — لا يوجد ادعاء FIXED أو CLOSED أو READY للتشغيل.**
