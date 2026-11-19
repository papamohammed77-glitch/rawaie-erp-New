# تقرير CTO اليومي — CountFlow
## Report734 — تدقيق مستقل للتطبيقين وقاعدة rawaea-staging وإعادة إثبات اختبارات Rollback
**التاريخ:** 2026-11-19  
**الحالة:** READY WITH LIMITATIONS للفحص والاختبارات المعزولة فقط؛ BLOCKED لأي تعديل تشغيلي/ACL/RLS أو قبول ميداني قبل اعتماد Change Set المحدد وتوفير حسابات حقيقية.

---

## 1. نطاق المهمة ونقطة الاستئناف

استُكمل العمل من نقطة CountFlow المحلية المسجلة في:
- الشركات/المسار: `papamohammed77-glitch/erp-frontend`، `companies/company-2/Counting/`
- ملف الحالة السابق: `companies/company-2/Counting/CURRENT_STATE.md`، blob `0fa02ef470e63f2dbf1899ff1e3624b73379cbbe`
- آخر حدث محلي سابق: `LVE-2026-11-19-CountFlow-13Sheet-Export-Audit-v6`
- الفرع: `main`
- HEAD الحالي: `3e963eaddb286d6e805e9c8028075df6b20387f5`
- مقارنة نقطة CountFlow السابقة `4ce98fd55435609f210adec46c7f904781200872` إلى HEAD الحالي: **24 commit ahead / 0 behind، و8 ملفات CountFlow متغيرة**. لا تُعمم هذه المقارنة على المستودع كله.

التغييرات الثمانية داخل نطاق CountFlow:
1. `Counter-supervisor.html`
2. `Counter.html`
3. `README.md`
4. `database/migrations/20261119195303_countflow_rpc_and_immutable_ledger_acl_hardening_v1.sql`
5. `database/migrations/20261119195630_countflow_import_batch_sku_lookup_index_v1.sql`
6. `tests/countflow_location_heatmap_rollback.sql`
7. `tests/import_90k_rollback.sql`
8. `tests/rollback-smoke.sql`

الـblobs الحالية:
- Counter: `93ad77a682585b8ec04cdcf224e2ac81b28cb180`
- Supervisor: `11101374a8f27d78d042f750b162dba9303174b6`
- README: `7b85173708c907b772a58717cbbb82659f4c7346`
- Provision Edge source: `74af323b9efda52d01b0326ef71dc0fe5133fa3b`
- Export Edge source: `e0f8f6faf67aee2b7478a1eb99b53c3b64caf0ba`
- ACL migration source: `3ad77235c98b5ac92b5a4eddecf7b69af9d0ca8e`
- SKU index migration source: `8621d833e3afa6cf1c426753ca8ed4f8365e83f2`
- Location/heatmap rollback test: `f44ead6347b4bd901cd312180579f713204af3cd`
- 90k import rollback test: `d72d9ee724071446aa96888fc124a056e3470760`

**حكم النطاق:** CountFlow مسار مستقل عن SMART ERP، ويجب إبقاؤه كذلك. التوجيه الخاص بهذا المسار يحصر أي كتابة مستقبلية في تطبيقات CountFlow وجداول `count_*` ومخازن `counting-*` في مشروع `rawaea-staging`. لا يشمل هذا استثناءً عامًا لبقية ERP ولا يسمح بتعديل أي كيان legacy في المشروع.

## 2. حوكمة الدستور والتعارض المحدود

الدستور التشغيلي الدائم الحالي في مستودع الحالة:
- الملف: `doc/Draft/Reprots/الدستور التشغيلي الدائم.md`
- الفرع: `main`
- blob: `3a6b1e220af8509e314e94df76563bbc6f84910d`

يوجد تعارض نطاقي يجب إبقاؤه موثقًا:
- القاعدة العامة الأقدم في الدستور تقصر الاختبار التشغيلي على SMART ERP Production ولا تسمح بإنشاء بيئة Staging جديدة.
- توجيه المالك الأحدث والمحدد لـCountFlow يطلب بقاء التطبيقين منفصلين عن SMART ERP واستخدام مشروع `rawaea-staging` الموجود بالفعل، مع حصر العمل في `count_*`.
- لا يُعامل ذلك كتغيير عام للدستور أو تفويض لتعديل SMART ERP. طُبّق فقط على CountFlow، ولم يُنشأ مشروع جديد، ولم تُلمس جداول ERP القديمة، ولم تُنفذ أي كتابة دائمة.

## 3. فصل المشاريع ومصدر الحقيقة

تم التحقق من المشروعين مباشرة:
| المشروع | ref | الحالة | المنطقة |
|---|---|---|---|
| SMART ERP | `fiilmooggumokxanwiyx` | ACTIVE_HEALTHY | eu-west-1 |
| rawaea-staging / CountFlow | `hfzznsiprnwkpayskzhu` | ACTIVE_HEALTHY | eu-central-1 |

المعرفان مختلفان؛ لذلك CountFlow ليس داخل قاعدة SMART ERP. لكن `rawaea-staging` نفسه ليس مشروعًا نظيفًا خاليًا من الموروث: يحتوي 70 جدولًا عامًا خارج CountFlow، و24 Edge Functions، و1,868 مستخدم Auth سابقًا. هذا يثبت فصل المشروع عن SMART ERP، لكنه لا يثبت نظافة المشروع من الكيانات القديمة داخله.

لم تُعدّل أي من الجداول أو الوظائف القديمة. ست وظائف legacy من أصل 24 لها `verify_jwt=false`، ولا واحدة منها من وظيفتي CountFlow. يجب أن تبقى خارج هذا النطاق حتى يحدد مالكها ومسار استخدامها.

## 4. بنية CountFlow الحية في Supabase

نتيجة القراءة المباشرة من كتالوج Production الخاص بمشروع CountFlow:
- 21 جدولًا باسم `count_*`.
- RLS مفعّل على الجداول الـ21 كلها.
- 70 RLS policies على جداول CountFlow.
- 72 Foreign Keys معتمدة ومتحقق منها؛ لا توجد FK غير معتمدة.
- لا يوجد جدول CountFlow بلا Primary Key.
- لا توجد صلاحيات مباشرة لـ`anon` على جداول CountFlow.
- لا توجد Policy على جداول CountFlow موجّهة إلى `anon` أو `PUBLIC`.
- لا توجد صلاحيات `TRUNCATE` أو `TRIGGER` أو `REFERENCES` ممنوحة لـ`authenticated`.
- `count_entries` بقي append-only من جهة العميل: SELECT وINSERT فقط؛ UPDATE وDELETE غير متاحين.
- الدوال المساعدة داخل `counting_private` لا تمنح `anon` صلاحية التنفيذ. دالة تفويض Realtime متاحة لـauthenticated فقط.
- الأرصدة الدفترية محمية بTrigger يقفل تعديلها بعد أول عملية عد أو إنشاء تسوية، ويلزم استخدام الوحدة الأساسية.
- Trigger إدخال العد يقفل صف الجلسة `FOR UPDATE` ويتحقق من أن الجلسة `active`، ومن عدم وجود تسوية معتمدة. هذا يحمي سباق إدخال العد مع اعتماد التسوية.

### البيانات الفعلية

عدد الصفوف الدقيق في كل واحد من جداول CountFlow الـ21 يساوي **صفرًا** بعد الاختبارات. كذلك:
- `count_projects=0`
- `count_members=0`
- `count_entries=0`
- `count_audit_log=0`
- مستخدمو Auth = 1,868 قبل الاختبارات وبعدها.
- لا توجد حسابات QA مؤقتة باقية.

لم تُنشأ أي عضوية دائمة أو مشروع CountFlow فعلي. لم يُسند أي مستخدم ERP قديم إلى CountFlow.

## 5. الصلاحيات ومسارات الكتابة — فجوات P1 مثبتة

الفحص لم يكتفِ بعدّ Policies؛ طابق GRANT + RLS Policy + الدور + Triggers + RPC. ظهر أن عددًا من جداول الحالة الحساسة يسمح لـauthenticated supervisor بالكتابة المباشرة، بينما تحتوي RPCs المقابلة على ضوابط أعمال أقوى. هذا يجعل ضوابط الواجهة/RPC قابلة للتجاوز عبر PostgREST مباشرة.

### 5.1 الجداول الحرجة

| الجدول | المسار المباشر الفعّال | الحماية الحية | الفجوة |
|---|---|---|---|
| `count_sessions` | authenticated لديه UPDATE وDELETE؛ Policy كلاهما supervisor | Audit + Broadcast، وTouch Updated At فقط قبل UPDATE | لا يوجد Trigger لحالات الانتقال أو شرط الإغلاق؛ يمكن تجاوز فحوص الواجهة، والحذف قد يزيل بيانات تابعة عند عدم وجود FK مانع |
| `count_reconciliation_runs` | authenticated لديه UPDATE؛ Policy supervisor | Broadcast فقط | لا يوجد Audit Trigger ولا Before Guard؛ يمكن تغيير status إلى approved مباشرة وتجاوز `count_approve_reconciliation` |
| `count_recount_tasks` | authenticated لديه UPDATE وDELETE؛ Policy supervisor | Audit + Broadcast بعد العملية | لا يوجد Before Guard؛ يمكن جعل المهمة reviewed/cancelled أو حذفها مباشرة بدل المرور بـ`count_review_recount_task` |
| `count_import_rows` | authenticated لديه UPDATE وDELETE؛ Policy supervisor | لا توجد Triggers على الجدول | يمكن تعديل `row_status` أو محتوى الصف بعد التحقق؛ `count_commit_import_batch` يعتمد على `row_status='staged'` ولا يعيد التحقق الكامل من الصف |
| `count_alerts` | authenticated لديه UPDATE؛ Policy supervisor | Broadcast فقط | لا يوجد Audit Trigger؛ الواجهة تغيّر الحالة مباشرة ولا تطلب سبب معالجة/تصنيف الإنذار |
| `count_import_batches` | authenticated لديه UPDATE وDELETE؛ Policy supervisor | Audit Status + Broadcast + Touch | يوجد Audit، لكن لا يوجد State Guard يفرض انتقالات الدفعة |

### 5.2 الدليل من العقود الحالية

- `count_approve_reconciliation(p_run_id)` يتحقق من أن الجولة computed والأحدث، ومن ثبات entry_count_snapshot، وعدم وجود مواضع غير معدودة أو مهام إعادة عد مفتوحة أو تنبيهات حرجة؛ ثم يغيّر حالة الجولة إلى approved والجلسة إلى review.
- مع ذلك، Policy `count_recon_runs_update` تسمح للمشرف بتحديث أي عمود، ولا يوجد Trigger على `count_reconciliation_runs` يمنع تغيير الحالة مباشرة أو يسجل ذلك في Audit.
- `count_review_recount_task` يشترط أن تكون المهمة completed، ثم يقرر accept/repeat/cancel ويسجل Audit. لكن UPDATE Policy على الجدول تسمح بتحديث الحالة مباشرة، وDELETE Policy تسمح بالحذف.
- `count_commit_import_batch` يقفل الدفعة ويتحقق من حالتها، لكنه يقرأ الصفوف التي حالتها staged ويعتمدها دون إعادة تشغيل كامل قواعد التحقق الأصلية. Policy UPDATE/DELETE على `count_import_rows` تتيح للمشرف تغيير هذه الصفوف مباشرة.
- `count_sessions` لديه Policy UPDATE وDELETE supervisor، ولا يوجد Trigger يفرض تسلسل planned → active → paused/review → completed أو شروط الاعتماد عند الإغلاق.
- الواجهة تستخدم UPDATE مباشرًا للجلسة عبر `setSession(status)`، وتستخدم UPDATE مباشرًا للتنبيهات في `loadAlerts()`. لذلك ليست الفجوة نظرية فقط.

### 5.3 أثر الأعمال

هذه ليست ثغرة تسمح لمستخدم anon؛ المسار مقيد بمشرف CountFlow authenticated. لكنها ثغرة نزاهة أعمال داخل الدور المخول:
- يمكن تجاوز اعتماد التسوية أو شروط إعادة العد.
- يمكن تجاوز تحقق صفوف الاستيراد.
- يمكن إغلاق جلسة دون تطبيق شروط الانتقال على الخادم.
- يمكن معالجة تنبيه حرج دون سبب تدقيقي موثق.
- يمكن حذف مهمة إعادة عد فيؤثر ذلك على فحص المهام المفتوحة عند الاعتماد.

**التصنيف:** P1. لم يُنفذ استغلال أو DML لاختبار هذه المسارات؛ إثباتها مبني على الصلاحيات والسياسات والتريجرات والعقود الحية. المطلوب Change Set معتمد، وليس تجربة على بيانات حقيقية.

## 6. فجوة Offline وإغلاق الجلسة — P1

تسلسل المصدر الحالي:
1. `Counter.html / activateMembership()` يجلب الجلسات بحالتي active وpaused فقط.
2. `queueCount()` يعرض العمليات المرتبطة بالجلسة الحالية فقط.
3. `syncQueue()` لا يعمل دون session/member/project، ويرسل فقط عمليات الجلسة الحالية.
4. `count_approve_reconciliation` يغيّر حالة الجلسة إلى review ويمنع إدخالات لاحقة عبر Trigger إدخال العد.
5. عند انتقال الجلسة إلى review أو completed، لا يحمل Counter تلك الجلسة في `activateMembership`، فيصبح session=null وتختفي العمليات المحلية المرتبطة بها من عرض الطابور.
6. المشرف لا يطلب من كل جهاز/مندوب تأكيد مزامنة الطابور قبل اعتماد التسوية أو الإغلاق.

النتيجة: عملية عد أُدخلت محليًا أثناء انقطاع الشبكة قد تبقى في IndexedDB ولا تُحذف، لكنها تصبح مخفية وغير قابلة للمزامنة بعد اعتماد/إغلاق الجلسة؛ لأن الخادم يرفض الإدخال بعد تجميد الجلسة. لا يوجد دليل على فقد bytes محليًا، لكن توجد فجوة مؤكدة في الاستعادة والظهور، وقد تُستبعد العملية من نتيجة الجرد المعتمدة.

فجوة إضافية: زر `retryQueueBtn` يصفر `sync_error` لجميع عناصر IndexedDB، لا العناصر التابعة للمشروع/الجلسة الحالية فقط. هذا قد يمحو سبب رفض محفوظًا لسياق آخر قبل أن يراجعه المستخدم.

**التصنيف:** P1 لسلامة نتيجة الجرد؛ وP2 لخلل نطاق إعادة المحاولة.

## 7. خلل التصدير عند إنهاء الجلسة — P1

في `Counter-supervisor.html / setSession(status)`:
- يتم تحديث الجلسة الحالية.
- ثم يُستدعى `loadSessions()` و`loadLive()`.
- `loadSessions()` يعيد تعيين المتغير العام `session` إلى أحدث جلسة planned/active/paused/review أو null.
- بعد ذلك يستخدم الكود `session.id` لعد عمليات الجلسة التي أُغلقت ولتشغيل التصدير.

بذلك يمكن أن يحدث أحد أمرين:
- إذا لم توجد جلسة أخرى، تصبح session=null ثم يفشل الوصول إلى session.id بعد نجاح الإغلاق.
- إذا وُجدت جلسة أخرى، يمكن أن يُحسب أو يُصدّر تقرير الجلسة الأخرى بدل الجلسة التي أُغلقت.

الإصلاح الجراحي المقترح: التقاط `closingSessionId` قبل التحديث، واستخدامه في استعلام العد وطلب Edge Export، وتعديل `downloadServerExport(format, sessionId)` لقبول معرف صريح بدل الاعتماد على المتغير العام المتغير.

## 8. Edge Functions وStorage وRealtime

### Edge Functions
- `counting-provision-member`: ACTIVE v3، verify_jwt=true، ومحتوى المصدر مطابق تمامًا لـGit.
- `counting-export-session`: ACTIVE v6، verify_jwt=true، ومحتوى المصدر مطابق تمامًا لـGit.
- التصدير الخادمي يعلن 13 ورقة XLSX وحدودًا 150k لكل مجموعة و250k إجماليًا؛ لم يُختبر بعد من جلسة بشرية مصادق عليها.
- فجوة Provision: بعد إنشاء Auth user أو تغيير كلمة المرور، إذا فشل إدراج سجل Audit تعيد الوظيفة نجاحًا مع `audit_warning` ولا تعكس التغيير. هذا لا يجعل إنشاء الحساب ذريًا مع التدقيق. **P2**.

### Storage
الحاويات الثلاث خاصة:
- `counting-product-images`
- `counting-evidence`
- `counting-exports`

سياسات القراءة والكتابة مقيدة بمسارات العضوية/المشروع والمشرف. لم يُنفذ رفع/تنزيل حقيقي من جهاز مصادق عليه في هذا التشغيل.

### Realtime
- Broadcast الخاص مفعّل بكود وقنوات project/session/member، مع RLS على `realtime.messages`.
- توجد Broadcast triggers على الجداول التشغيلية.
- توجد أيضًا 7 جداول CountFlow في Publication؛ وجودها لا يثبت استخدام Postgres Changes أو وصول الحدث.
- Supervisor ينفذ refresh احتياطيًا لخريطة المواقع كل 10 ثوانٍ عند ظهور الصفحة.
- لم يُختبر cross-user/cross-device delivery أو reconnect أو duplicate/out-of-order أو latency. لذلك الحالة **CODE PRESENT / RUNTIME UNVERIFIED**، ولا يصح وصف المزامنة بأنها لحظية مثبتة.

## 9. سجل الترحيلات — CONFLICT في قابلية إعادة البناء

التحقق من مجلد Git ومن Migration Ledger الحي:
- SQL migration files في Git: **14**.
- CountFlow migrations في Supabase ledger: **53**.
- 14 اسمًا متعقبًا لها نظير في Ledger الحي.
- **39 migration مطبقة ليس لها ملف SQL مستقل في Git**.
- من أحدث الملفات المفقودة: `20261119195107_countflow_location_hierarchy_guard_and_session_heatmap_v1` و`20261119195202_countflow_session_heatmap_helper_contract_fix_v1`. لا توجد لهما ملفات مصدر في مجلد migrations الحالي، ولم يظهر لهما ملف في بحث GitHub.
- أربعة تغييرات approval/freeze بين 19192305 و19192509 ممثلة في ملف consolidated 19192509 وفق README، لكنها ما زالت مدرجة كأحداث مستقلة في Ledger.
- الملف `20261119195630_countflow_import_batch_sku_lookup_index_v1.sql` يقابله في Ledger version `20261119195750` بالاسم نفسه. الفهرس موجود في قاعدة البيانات؛ الاختلاف في timestamp يحتاج توثيق lineage، ولا يبرر إعادة تطبيق migration.
- ملف `database/migrations/README.md` الحالي blob `45a4f6609398415afab6709ed1af2b4a36ebe31f` يسرد 12 ملفًا فقط ويذكر 19194738 كآخر migration؛ كلاهما قديم.

هذا لا يثبت أن Schema الحالي خاطئ؛ لكنه يثبت أن مجلد SQL الحالي لا يكفي لإعادة بناء قاعدة CountFlow من الصفر دون استعادة/توثيق 39 artifact مفقودًا. **P1 في قابلية الاستعادة والتدقيق**.

## 10. الاختبارات المنفذة فعليًا في هذا التشغيل

### A. استيراد 90,000 صنف — PASS
المصدر: `tests/import_90k_rollback.sql`، SHA `d72d9ee724071446aa96888fc124a056e3470760`.
- تم التحقق من BEGIN وROLLBACK قبل التنفيذ.
- إنشاء Auth user ومشروع ودفعة و90 chunk داخل معاملة واحدة.
- النتيجة: 90,000 submitted، 90,000 staged، 90,000 accepted، 90,000 products committed داخل المعاملة، 90 batch chunks.
- نتيجة SQL: `status=PASS`, `rollback_only=true`.
- بعد ROLLBACK: كل جداول CountFlow الـ21 = 0؛ Auth users بقيت 1,868؛ لا توجد هوية `qa-90k` متبقية.

### B. Hierarchy + Location Heatmap — PASS
المصدر: `tests/countflow_location_heatmap_rollback.sql`، SHA `f44ead6347b4bd901cd312180579f713204af3cd`.
- تم التحقق من BEGIN وROLLBACK قبل التنفيذ.
- نتيجة الاختبار: cycle_guard=passed؛ count_events=2؛ hierarchy_path=`WH / A-01`؛ counted_positions=1؛ coverage_percent=100؛ refresh_stable=true.
- بعد ROLLBACK: كل جداول CountFlow الـ21 = 0.

### ما لم يُختبر
- لم يُشغّل Playwright أو Browser E2E مصادق عليه.
- لم يُختبر تصدير XLSX/CSV عبر مستخدم بشري حقيقي.
- لم تُختبر كاميرا هاتف أو قارئ باركود فعلي.
- لم يُختبر Offline حقيقي مع إغلاق المتصفح وإعادة فتحه.
- لم تُختبر Broadcast latency أو التزامن متعدد الأجهزة.
- لم يُختبر 90k export أو 30–300 مستخدم متزامن.
- لا توجد حسابات CountFlow دائمة أو مشروع CountFlow تشغيلي؛ لذلك لا توجد رحلة عمل ميدانية.

## 11. تجربة المنتج والحدود الحجمية

الموجود في المصدر:
- مسح باركود ومتابعة الصنف، صور الأدلة، IndexedDB queue، مواقع هرمية، تعيينات، استيراد دفعات، تنبيهات، إعادة عد، تسوية، خريطة تغطية، وتصدير خادمي.
- فحص DOM الساكن لم يجد معرّفات ثابتة مفقودة أو مكررة. هذا ليس اختبار Responsive أو Accessibility أو سرعة ميدانية.

حدود الكود التي تحتاج قياسًا:
- تحميل مواقع Counter يتوقف عند 20,000 دون رسالة overflow واضحة.
- `fetchAllRows` يوقف عند 200,000.
- التصدير يحد البيانات بـ150,000 لكل مجموعة و250,000 إجماليًا.
- اختبار 90k import لا يثبت 90k export أو حملًا متزامنًا.

## 12. أثر البيانات والسلامة

لم يحدث:
- DDL أو DML دائم أو ACL/RLS/Grant تغيير.
- نشر Edge Function أو Pages.
- إنشاء Auth user أو CountFlow project/member دائم.
- كتابة على أي جدول ERP legacy.
- أي أثر مخزني أو مالي أو خزينة أو دفتر أستاذ.
- أي اختبار خارج معاملات Rollback.

التنفيذ الفعلي اقتصر على قراءات GitHub وSupabase catalog/SELECT، وتشغيل اختبارين CountFlow داخل BEGIN/ROLLBACK، والتحقق من بقاء جميع جداول CountFlow فارغة بعدهما.

## 13. مصفوفة التحقق

| الطبقة | النتيجة | الدليل |
|---|---|---|
| GitHub Source | CONFIRMED | HEAD `3e963eaddb286d6e805e9c8028075df6b20387f5`، 24 commits منذ CountFlow checkpoint، 8 ملفات ضمن CountFlow |
| Supabase schema/RLS | CONFIRMED ضمن count_* | 21 table، 70 policies، 72 FK validated، لا anon grants |
| RPC/ACL | CONFLICT / P1 | direct UPDATE/DELETE policies على workflow state tables تسمح بتجاوز بعض RPC validations |
| Edge artifact | CONFIRMED | v3 وv6 ACTIVE، JWT required، source byte-match |
| Storage | CONFIRMED catalog | 3 buckets private |
| Realtime runtime | UNVERIFIED | code + triggers + private policy؛ لا cross-device delivery test |
| Deployed Pages artifact | UNKNOWN | لا deployment pointer أو byte parity مثبت |
| Authenticated Browser E2E | BLOCKED | لا حسابات CountFlow دائمة ولا app origin مؤكد |
| Business data effects | CONFIRMED no residue | 21 count tables = 0 بعد rollback، Auth=1,868 |
| Staging | PARTIAL | قاعدة منفصلة عن SMART ERP، لكنها تحتوي legacy ERP objects لم تُمس |

## 14. Change Sets المطلوبة قبل إعلان الجاهزية

### CS-CF-734-A — Server-authoritative workflow and DML boundary (P1)
النطاق:
- `count_sessions`: استبدال direct status UPDATE بعملية خادمية ذات انتقالات محددة، ومنع DELETE غير المصرح.
- `count_reconciliation_runs`: منع direct status mutation، إضافة audit guard، وإبقاء الاعتماد فقط عبر `count_approve_reconciliation`.
- `count_recount_tasks`: منع direct UPDATE/DELETE التي تتجاوز `count_review_recount_task` و`count_assign_recount_task`.
- `count_import_rows`: منع direct mutation بعد staging أو جعل import commit يعيد التحقق من كل الصفوف قبل الإدراج.
- `count_alerts`: إضافة مسار acknowledgment/resolution مركزي مع سبب إلزامي وAudit.
- اختبار كل مسار تحت authenticated role، بما فيه رفض direct DML، ونجاح RPC الصحيح، ومنع تجاوز حالة session.

### CS-CF-734-B — Offline close handshake + export target identity (P1)
النطاق:
- إبقاء الطابور مرئيًا حتى بعد انتقال session إلى review/completed.
- إظهار حالة pending local events وعدم إخفائها عند عدم وجود session active.
- إضافة sync acknowledgement موثوق من كل جهاز/عضو قبل اعتماد/إغلاق الجلسة؛ إذا تعذر إثبات اكتمال المزامنة، يمنع الإغلاق fail-closed.
- حصر زر retry في سياق المشروع/الجلسة/العضو الحالي.
- التقاط closingSessionId قبل loadSessions واستخدامه في count/export request.
- اختبارات انقطاع الشبكة، جلسة review، إغلاق session، إعادة فتح التطبيق، ثم reconciliation/export.

### CS-CF-734-C — Migration lineage recovery (P1)
- استعادة SQL artifacts للمهاجرات الـ39 غير الممثلة، أو إنتاج baseline snapshot موثق من الكتالوج الحي مع تمييزه بوضوح عن migration قابلة لإعادة التطبيق.
- استعادة مصدري 19195107 و19195202 من سجلات التنفيذ إن وجدت؛ لا تُعاد صياغتهما بالتخمين.
- توثيق mapping بين source 19195630 وlive ledger 19195750.
- لا DDL أو reapply قبل مراجعة exact diff واعتماد المالك.

**لا شيء من هذه التغييرات نُفذ.** تتطلب موافقة صريحة على Change Set المحدد قبل كتابة التطبيق أو تعديل ACL/RLS/Schema.

## 15. الحسابات والنشر والقبول الميداني

- لا يوجد CountFlow project أو members أو supervisor account.
- عدد Auth users السابقين 1,868؛ لا يجوز اختيار أي منهم أو إسناد دور له دون roster معتمد.
- وظيفة provisioning لا تستطيع إنشاء أول مشرف دون وجود مشرف نشط؛ مسار bootstrap يتطلب Auth identity حقيقيًا يسجل الدخول ثم ينشئ أول مشروع.
- لا يوجد app origin مؤكد أو Deployment pointer موثوق في هذا التشغيل.
- لا Browser session مصادق عليه؛ لا يمكن إعلان قبول ميداني أو جاهزية تشغيلية.

## 16. حكم الجاهزية والخطوة التالية

**READY WITH LIMITATIONS** للقراءة، تدقيق العقود، وتشغيل اختبارات CountFlow المعزولة التي تنتهي بـROLLBACK.

**BLOCKED** لتعديل سياسات الكتابة/المسارات التشغيلية حتى اعتماد CS-CF-734-A وCS-CF-734-B، ولإجراء Authenticated E2E حتى توفير هوية المشرف الحقيقية وعنوان النشر.

**الخطوة التالية ذات الأولوية الواحدة:** تجهيز واعتماد ثم تنفيذ CS-CF-734-A/B كحزمة واحدة لحماية حالة الجلسة والتسوية وإعادة العد والاستيراد والطابور Offline. السبب: هذه الفجوات تمس صحة نتيجة الجرد واعتمادها قبل أن تصبح البيانات قابلة للاستخدام الميداني. بعد ذلك تُستعاد ملفات الترحيل المفقودة، ثم يُنشأ أول مشرف ويُنفذ Browser E2E.

**الخلاصة:** الهيكل التقني الأساسي لـCountFlow موجود، والاختباران المعزولان 90k import وlocation heatmap نجحا مع ROLLBACK وعدم بقاء بيانات. لكن المنتج **غير جاهز للتشغيل الميداني** بسبب مسارات DML المباشر التي تتجاوز ضوابط RPC، وفجوة Offline عند اعتماد/إغلاق الجلسة، وخلل session identity في التصدير، وعدم وجود حسابات حقيقية أو Runtime/Deployment مثبت. لا تُعلن CLOSED أو READY أو GOLD.
