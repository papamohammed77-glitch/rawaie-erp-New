# Report568 — المراجعة اليومية لـ RAWAEA ERP
## قنوات Realtime في النظام الأم، مسارات القراءة المصرّح بها، وتعارض عقد الصلاحيات

**التاريخ:** 2026-10-31  
**وقت الفحص:** نحو 21:39 بتوقيت القاهرة  
**مشروع Production:** SMART ERP — `fiilmooggumokxanwiyx`  
**مستودع المصدر التشغيلي:** `papamohammed77-glitch/erp-frontend` / الفرع `main`  
**مستودع الحوكمة والتقارير:** `papamohammed77-glitch/rawaie-erp-New` / الفرع `main`

---

## 1. نقطة البداية — CURRENT_STATE أولاً

بدأت بقراءة ملف `CURRENT_STATE.md` كاملًا في مستودع الحوكمة. كان آخر checkpoint مسجل هو **LVE-2026-10-31-567B**، بعملية commit بتاريخ 2026-10-31 الساعة 16:03:06Z، وكان يسجل رأس مستودع المصدر التشغيلي عند:

`8140235b7460401f10abe117ce9358c88c38114a`

بعد ذلك اكتشفت وجود ملف `CURRENT_STATE.md` ثانٍ داخل مستودع المصدر التشغيلي نفسه، وقرأت ملفه كاملًا (472 سطرًا). هذا الملف أحدث؛ إذ يسجل أن العمل النشط هو:

**Phase 3 — معالجة تعارض قنوات Realtime المتبقية في النظام الأم واستكمال تصنيف حداثة البيانات.**

آخر تحديث لهذا الـhandoff كان بالـcommit:

`1f190a46d55929a3155ddb225dbb5bc15f40faf2` — الساعة 17:20:22Z.

ويحيل إلى:
- `REALTIME_SYNC_EXECUTION_20261031.md`، وبالأخص القسم 8.
- `REALTIME_SYNC_PHASE2_PARENT_BOOTSTRAP_20261031.md`.
- `REALTIME_SYNC_PHASE3_INVENTORY_COUNTS_20261031.md`.

كما تمت قراءة بروتوكول الحوكمة والاستمرارية الأساسي، وتقارير Phase 2 وPhase 3 قبل بدء التحقيق.

**النتيجة:** ملف الحالة في مستودع المصدر أحدث من ملف الحالة في مستودع الحوكمة، ورأس Git الفعلي أحدث من الاثنين. رأس `erp-frontend/main` الحالي هو:

`65799d282acc79359b17a1a13dcd68f62859e1fb` — بتاريخ 2026-10-31 الساعة 17:23:29Z، ومتقدم 26 commit على الرأس الذي سجله checkpoint 567B. آخر أربعة commits بعد تحديث handoff تضيف نسخًا مصدرية لدوال Edge المنشورة، ولم تغيّر ملف Parent `main.html`.

### هدف المراجعة اليوم

استكمال Phase 3 بتحديد طريقة تحديث الوحدات الأربع في النظام الأم عبر مسارات قراءة خلفية مصادق عليها، دون إضعاف RLS أو كشف جداول `service_role`. لم أعد فتح إصلاح `inventory_counts` المغلق، ولم أعتبر وجود كود أو قناة Realtime دليلًا على نجاح التشغيل.

---

## 2. CONFIRMED — حقائق مثبتة

### 2.1 حالة GitHub والمصدر الحي

- المستودع التشغيلي: `papamohammed77-glitch/erp-frontend`.
- الفرع: `main`.
- HEAD الحالي: `65799d282acc79359b17a1a13dcd68f62859e1fb`.
- ملف النظام الأم `companies/company-1/main.html`: Blob `53b5a9e9d0433a785c3d5471a9c0d68c25497882`، وعدد أسطره 33,358.
- المحرك المشترك `companies/company-1/core.js`: Blob `a95ee6b29ff54b4a240ce4b81f9a535aa87686db`، وعدد أسطره 1,002.
- Blob ملف الحالة التشغيلي في مستودع المصدر: `2f7b391c556a0118d418d0d1d4eb83c0e81ebf25`.
- Blob ملف الحالة المرجعي في مستودع الحوكمة عند بدء المراجعة: `c0039234b93d009de67d26123a607472c4921b73`.

أظهر فحص ملف Parent وجود **11 موضعًا مباشرًا لاستدعاء `.channel(`**، وليس 8 كما ورد في handoff التشغيلي. القنوات الأربع محل Phase 3 هي:

| الوحدة | موضع المصدر | الجداول التي تشترك مباشرة |
|---|---:|---|
| مركز قرار المبيعات | `main.html:3488–3492` | `sales_decision_policies`، `sales_decision_evaluations`، `sales_decision_approvals` |
| الولاء | `main.html:4406–4409` | `loyalty_programs`، `loyalty_rewards`، `loyalty_accounts`، `loyalty_transactions` |
| تحصيلات العملاء | `main.html:20362–20388` | `sales_payment_receipts`، `sales_payment_allocations` |
| العمولات | `main.html:21400–21405` | `commission_plans`، `commission_assignments`، `commission_runs`، `commission_run_lines` |

ملف Parent:
- لا يحمل `core.js`.
- لا يستخدم `RW_Realtime`.
- لا يستدعي `get_my_effective_profile`.
- لا يحتوي على listener لـ`focus` أو `visibilitychange`.

وبالتالي لا يوجد fallback مثبت لتحديث هذه الوحدات عند عودة المستخدم للصفحة أو ظهورها مجددًا. المؤقتات الموجودة في وحدات أخرى لا تثبت تحديث هذه الوحدات الأربع.

كما أثبت فحص المصدر عدم وجود أي استدعاء مباشر من نوع `.from()` لقراءة الجداول الثلاثة عشر الخاصة بالوحدات الأربع داخل Parent `main.html`. قراءاتها الأساسية تتم عبر Edge Functions القائمة؛ ولذلك فالقنوات المباشرة الحالية هي آليات invalidation فقط، وليست مسار القراءة الأساسي. هذا يجعل استبدالها بتحديث مصادق عليه عبر واجهات القراءة الحالية خيارًا معماريًا ممكنًا.

**ملاحظة أمنية خاصة بقناة الولاء:** اشتراكات الجداول الأربعة لا تتضمن فلترًا خادميًا على `company_id`. يعتمد الكود على فحص `payload.new.company_id` داخل المتصفح، ويتجاوز الفحص عندما لا تكون `payload.new` موجودة، مثل بعض أحداث DELETE. لا يوجد دليل على وصول أحداث عابرة للشركات حاليًا لأن RLS والنشر يمنعان وصول الصفوف للمستخدم المصادق. لكن لا يجوز تفعيل هذه القناة بتوسيع RLS أو النشر؛ وأي invalidation مستقبلي يجب أن يكون tenant-scoped من جهة الخادم.

### 2.2 عقد Realtime وRLS في Production

استعلامات PostgreSQL للقراءة فقط على مشروع SMART ERP أثبتت:

- منشور `supabase_realtime` يحتوي على 81 جدولًا.
- جداول مركز قرار المبيعات **غير موجودة** في المنشور، وسياسات `anon` و`authenticated` عليها تستخدم صراحةً `USING (false)` و`WITH CHECK (false)`.
- جداول الولاء **غير موجودة** في المنشور، وسياسات `anon` و`authenticated` عليها تستخدم صراحةً `USING (false)` و`WITH CHECK (false)`.
- جداول تحصيلات العملاء موجودة في المنشور، لكن سياساتها المسموح بها مقتصرة على `service_role`.
- جداول العمولات موجودة في المنشور، لكن سياساتها المسموح بها مقتصرة على `service_role`.

إذًا القنوات الأربع غير متوافقة مع عقد الصلاحيات والنشر الحالي في Production. هذا يثبت عدم وجود صلاحية صفوف للمستخدم المصادق على هذه الجداول؛ لكنه لا يثبت وحده هل تعرض القناة في المتصفح `CHANNEL_ERROR` أم `SUBSCRIBED` دون أحداث أم حالة أخرى. ذلك يحتاج اختبار Runtime مباشرًا.

**القرار:** لا توسّع RLS ولا تضف هذه الجداول إلى النشر بغرض جعل القنوات تعمل.

### 2.3 مسارات القراءة الخلفية الموجودة بالفعل

الوحدات الأربع تستخدم بالفعل Edge Functions لقراءة البيانات وتنفيذ العمليات:

| الوحدة | المسار الخلفي الحالي | حالة Production |
|---|---|---|
| مركز قرار المبيعات | `sales-decision-center` — مثل `GET_POLICY` و`GET_PENDING_APPROVALS` و`VALIDATE_ORDER` | ACTIVE v1، و`verify_jwt=true` |
| الولاء | `loyalty-engine` — مثل `LIST_PROGRAMS` و`LIST_REWARDS` و`GET_ACCOUNT` و`LIST_TRANSACTIONS` | ACTIVE v1، و`verify_jwt=true` |
| تحصيلات العملاء | `sales-payment-allocation` — `catalog` و`open_orders` و`list` و`detail` و`create` | ACTIVE v2، و`verify_jwt=true` |
| العمولات | `commission-engine` — `LIST_REPS` و`LIST_PLANS` و`LIST_RUNS` وعمليات العمولات | ACTIVE v3، و`verify_jwt=true` |

تمت مقارنة المصدر الفعلي في Git مع نسخة Production المنشورة byte-for-byte، وكانت المطابقة كاملة للثلاثة التالية:
- `supabase/functions/sales-decision-center/index.ts` — Blob `95dfc768b956d1b58990942cc5031d7359c6f4bf`.
- `supabase/functions/loyalty-engine/index.ts` — Blob `076b6f4b9618dfc66f15e8b92051040eeedddfb5`.
- `supabase/functions/sales-payment-allocation/index.ts` — Blob `1c6dd356284079e346196b37b1f9813154c535c8`.

**فجوة مصدر العمولات:** دالة Production `commission-engine` الإصدار v3 نشطة، وهاش مصدرها المنشور:

`5172830aa0de5bf51ee4b010d6503de675071fca0fc29001e5b6aaab430a3555`

لكن لا يوجد لها مجلد أو ملف مصدر في `supabase/functions` بالمستودع التشغيلي، ولم يظهر لها مصدر في مستودع الحوكمة. يمكن فحص النسخة المنشورة، لكن لا يمكن حاليًا مراجعتها أو إعادة إنتاجها من مصدر Git موثق.

### 2.4 تعارض عقد الصلاحيات — اكتشاف جوهري

الدالة المركزية في Production `get_my_effective_profile()` تجمع الصلاحيات من ثلاثة مصادر:
1. `users.permissions`
2. `roles.permissions`
3. `role_permissions.permission_key`

المحرك المشترك التشغيلي `core.js` يستدعي هذه الدالة ويستخدم الصلاحيات الفعالة الناتجة عنها.

أما Parent `main.html` فلا يستخدم هذا العقد:
- مسار تسجيل الدخول في الأسطر `1268–1298` يقرأ `users.permissions` فقط.
- مسار استعادة الجلسة في الأسطر `33235–33250` يأخذ الصلاحيات من JWT metadata أو يضع افتراضيًا `['*']`، ولا يعيد قراءة الصلاحيات الفعالة من قاعدة البيانات قبل بناء حالة التطبيق.

كما أن مسارات التفويض في Edge/RPC ليست موحدة:
- `sales-decision-center` يفحص `users.permissions` المباشرة فقط، ودالة Production `sales_decision_actor_ok` تفحص المصدر المباشر نفسه فقط.
- `loyalty_engine_atomic` يفحص `actor.permissions` من سجل المستخدم المباشر فقط.
- `sales-payment-allocation` يجمع الصلاحيات المباشرة مع `roles.permissions`، لكنه لا يضم `role_permissions`.
- `commission-engine` المنشور يفعل الشيء نفسه: الصلاحيات المباشرة مع `roles.permissions`، دون `role_permissions`.
- دالتا RPC الخاصتان بالدفع والعمولات قابلتان للتنفيذ من `service_role` وليس `authenticated`؛ لذلك فإن فحص الصلاحية في Edge Function هو بوابة الوصول الفعلية لهاتين العمليتين.

استعلام Production للقراءة فقط أثبت وجود 21 سجلًا في `role_permissions` موزعة على 3 أدوار. ويوجد مستخدم نشط واحد على الأقل مرتبط بـAuth يعتمد على `role_permissions` وحدها للحصول على كل صلاحية من المفاتيح التالية: `finance` و`orders` و`pos` و`purchases` و`warehouse`. لم يتم إظهار أي بيانات تعريفية عن الحساب.

هذا يثبت وجود اختلاف حقيقي بين عقد الصلاحيات الفعالة وبعض مسارات التفويض؛ فقد تمنح الدالة المركزية صلاحية لا تتعرف عليها واجهة Parent أو بعض Edge/RPC. لم يتم اختبار تجربة الحساب المتأثر فعليًا. لا تعالج هذا الاختلاف بمنح وصول مباشر للجداول أو بتوسيع RLS.

### 2.5 إعادة التحقق من إغلاق جزء Inventory Counts

إصلاح حدود المستأجر الذي نُفذ في Phase 3 ما زال ظاهرًا في Production:
- migration `20261031171715` مطبقة.
- سياسة القراءة الحالية هي `inventory_counts_select_company_authorized`.
- القراءة المباشرة من anon غير مسموحة.
- authenticated لديه SELECT، بينما الكتابة المباشرة INSERT/UPDATE/DELETE غير مسموحة.
- احتفظ `service_role` بصلاحيات الكتابة.
- جدول `inventory_counts` يحتوي حاليًا على صفر صفوف.

ملف `warehouse/counter.html` الحالي Blob `32d0dc8ca0edb7cc68660f0fbd6246408117498d` يحتوي على تصحيح إرسال `null` في حقل كيان الجرد العام. ومصدر Production `save-inventory-count` v5 مطابق لمصدر Git تمامًا.

لا يوجد حاليًا مستخدم نشط مرتبط بـAuth يحمل `active_warehouse_role='جرد'`، ولذلك اختبار Counter الفعلي ما زال متعذرًا. كما أن المستخدمين النشطين المرتبطين بـAuth في Production يتبعون شركة واحدة فقط؛ فلا يمكن إثبات العزل بين شركتين في E2E حاليًا.

### 2.6 CI

على HEAD الحالي `65799d2` توجد أربعة Workflow runs ناجحة. لكنها ليست اختبار Parent Realtime مصادقًا عليه.

أما تشغيل `Warehouse Vouchers Browser E2E` رقم `41217489614` على commit `8140235` فقد انتهى بالفشل، ولم يُعد تشغيله على HEAD الحالي. كما أن شروط تشغيل الـworkflow تركز على `warehouse/vouchers.html` و`core.js` و`sw.js`، ولا تشمل وحدات Parent الأربع محل هذا التحقيق.

---

## 3. UNKNOWN — معلومات لا تكفي الأدلة لتحديدها

- الحالة الفعلية التي تعرضها القنوات الأربع في المتصفح، وهل تفشل عند الاشتراك أم تتصل دون تسليم أحداث.
- هل يوجد مستخدم مصادق يشاهد إحدى الوحدات الأربع وقت حدوث تغيير من مستخدم آخر.
- هل جرّب الحساب الذي يعتمد على `role_permissions` عمليات Finance أو Loyalty عبر Parent أو تطبيق آخر.
- مصفوفة حداثة البيانات الكاملة لجميع صفحات التشغيل الثلاثين؛ ما زالت مفتوحة.
- عنوان Cloudflare Production الحالي بصورة موثقة، وبايتات الـartifact الذي يقدمه الخادم، وسلسلة commit/build، وCache headers، وسلوك التشغيل الفعلي.

## 4. CONFLICT — تعارضات مؤكدة

1. **ملفا حالة مختلفان:** ملف الحالة المرجعي في مستودع الحوكمة كان عند LVE-567B ويسجل HEAD `8140235`، بينما ملف الحالة داخل مستودع المصدر يسجل handoff أحدث لمرحلة Phase 3 عند 17:20، ثم تقدم Git الفعلي إلى `65799d2` عند 17:23.
2. **عدد القنوات:** handoff التشغيلي يسجل 8 قنوات مباشرة في Parent، بينما المصدر الحالي يحتوي على 11 موضعًا لاستدعاء `.channel(`.
3. **عقد الصلاحيات:** `core.js` والدالة المركزية يستخدمان الصلاحيات الفعالة التي تشمل `role_permissions`، بينما Parent وبعض مسارات Edge/RPC لا تستخدم العقد نفسه.
4. **مصدر migrations:** Production يؤكد تطبيق migration `20261031153418` و`20261031171715`، لكن لا توجد ملفات مطابقة لهما داخل مجلد `supabase/migrations` الحالي في المستودع التشغيلي.

## 5. UNVERIFIED — ادعاءات لم يجر اختبارها مباشرة

- لم تتم مطابقة أي artifact منشور على Cloudflare مع Git HEAD.
- لم يتم إجراء Browser E2E بحساب مصادق عليه أو اختبار تسليم أحداث Realtime.
- لم يتم اختبار عزل شركتين.
- لم يتم اختبار الحساب الذي يعتمد على `role_permissions` وحدها عبر Edge Function.
- لم يتم تنفيذ معاملة تجارية أو اختبار أثرها على المخزون أو الحسابات في هذه المراجعة.

## 6. مصفوفة التحقق

| الطبقة | التصنيف | الدليل |
|---|---|---|
| GitHub / Source | CONFIRMED | HEAD `65799d2`، Blob Parent `53b5a9e`، Blob Core `a95ee6b`، 11 موضع قناة، ثلاثة مصادر Edge مطابقة، ومصدر Commission غير موجود في Git |
| Supabase Production | CONFIRMED | عضوية Realtime، سياسات RLS، صلاحيات تنفيذ RPC، إصدارات Edge، بيانات role_permissions، وسجل migrations |
| Deployed Artifact | UNVERIFIED | تعذر جلب صفحة التطبيق، ولا توجد وسيلة Cloudflare مباشرة متاحة في هذا التشغيل |
| Runtime / E2E | UNVERIFIED | لا توجد جلسة متصفح للمستخدم، ولم ينفذ اختبار قناة أو حدث بحساب مصادق |
| Business-data effects | CONFIRMED: لا توجد تغييرات في هذا التشغيل | فحص SQL/catalog للقراءة فقط؛ لا توجد كتابة أو fixtures أو معاملة تجارية |

## 7. ما تم فعليًا وسجل التغييرات

### ما تم
- قراءة `CURRENT_STATE.md` المرجعي كاملًا قبل أي إجراء آخر.
- قراءة ملف الحالة التشغيلي الكامل، وبروتوكول الحوكمة، وتقارير Phase 2 وPhase 3 وسجل التنفيذ الحالي.
- إعادة جلب HEAD الفعلي للمستودعين، ومقارنة مصدر التشغيل مع checkpoint المسجل، وإعادة فتح Parent/Core ومصادر Edge الحالية.
- تنفيذ استعلامات Production للقراءة فقط عن Realtime publication وRLS وRPC grants وتعريفات الدوال وmigrations ومصادر صلاحيات المستخدمين وحالة inventory_counts.
- مقارنة مصادر Edge الثلاثة الموجودة في Git مع إصدارات Production النشطة byte-for-byte.
- محاولة الوصول إلى مسارات Cloudflare Pages المعروفة؛ تعذر جلبها.

### ما لم يتم
- لم يتم تعديل أي HTML تشغيلي أو مصدر Edge Function.
- لم يتم تعديل RLS أو grants أو publication أو migrations أو RPCs أو Edge deployments أو بيانات الأعمال.
- لم يتم إنشاء PR أو Workflow أو Executor أو بنية موازية.
- لم يتم تحديث ملف `CURRENT_STATE.md` داخل مستودع التطبيق التشغيلي؛ لأن الكتابة إلى فرع `main` قد تطلق نشر Pages غير مراقب، بينما أدوات التحكم في Cloudflare غير متاحة. تم تحديث ملف الحالة المرجعي في مستودع الحوكمة والتقرير والذاكرة بدلًا من ذلك.

## 8. السبب الجذري والخطوة التالية

المشكلة ليست أن الجداول تحتاج إلى فتح RLS أو إضافتها جميعًا إلى Realtime. هذه الوحدات تقرأ بياناتها عبر Edge Functions مصادق عليها، لكن قنواتها المباشرة تحاول الاستماع إلى جداول لا تسمح للمستخدم المصادق برؤية صفوفها، أو غير موجودة في منشور Realtime أصلًا.

**الأولوية التنفيذية التالية الواحدة:** توحيد تفويض Parent وEdge Functions مع عقد `get_my_effective_profile` بما يشمل `role_permissions`، مع حفظ مصدر `commission-engine` v3 في Git. بعد إثبات عقد الصلاحيات، يجهز المالك تعديلًا جراحيًا في Parent يستبدل القنوات الأربع غير الصالحة بتحديث عند عودة الصفحة/ظهورها، مع polling محدود أثناء عرض الوحدة، باستخدام Edge read APIs الحالية. تظل سياسات RLS وعضوية Realtime كما هي.

**قرار الإغلاق:** توافق قنوات Parent الأربع ما زال OPEN. لم يتم إعلان إصلاح أو جاهزية Production.
