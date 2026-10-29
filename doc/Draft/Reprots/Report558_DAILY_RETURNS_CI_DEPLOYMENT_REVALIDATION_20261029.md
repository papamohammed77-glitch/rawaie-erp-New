# Report558 — إعادة التحقق اليومية من إصلاح المرتجعات وبوابة CI وأدلة النشر

**Last Verified Event:** `LVE-2026-10-29-558`  
**التاريخ:** 2026-10-29  
**نقطة البداية الإلزامية:** `CURRENT_STATE.md` عند `LVE-2026-10-29-557`، ثم Report545 والدستور التشغيلي الدائم وReport557.  
**النطاق:** تطبيق المرتجعات المستقل، تكامل Parent، بوابة JavaScript/Browser-E2E، Supabase Production، وأدلة Cloudflare المتاحة.  
**الحالة:** `RETURNS ROOT CAUSE STILL CONFIRMED / R8-S1 SEARCH PATCH PASSED IN-MEMORY STATIC+LOGIC CHECK / MAIN CI GATE STILL STALE / CLOUDFLARE CHECK STATUS OBSERVED / EXACT ARTIFACT + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED`

## 0. القرار التنفيذي

لم يتغير السبب الجذري: `returns.html` على `main` ما زال يعرض جميع الرانشيتات `Delivered` دون شرط وجود كمية متبقية، بينما إصلاح الأهلية موجود في Draft PR #8 فقط. أعدت تطبيق رقعتي البحث R8-S1-A/B **في الذاكرة فقط** على Blob الفرع الحالي؛ المحددان فريدان، والـinline JavaScript ينجح في التحليل، واختبار منطق معزول يعيد `RS-2` و`Returning` المسند إلى المستخدم الحالي فقط. لم أكتب إلى أي ملف تشغيلي ولم أدمج PR.

الاكتشاف التشغيلي الجديد الأهم: بوابة Parent على `main` ما زالت تستخدم فحص Payroll النصي القديم. تشغيلها على commit `0351897` فشل عند assertion قديم قبل فحص JavaScript الكامل أو بدء Playwright. PR #7 يحتوي تصحيح البوابة، لكنه Draft وغير مدموج ومبني على HEAD أقدم؛ لذلك لا توجد حتى الآن نتيجة CI تثبت تحليل Parent الحالي بعد إصلاح المصدر.

## 1. نقطة البداية والحالة المسجلة

- بدأ الفحص من `CURRENT_STATE.md`، لا من أحدث تقرير. نقطة البداية `LVE-2026-10-29-557` وReport557 هما مرجع الاستئناف، بينما التقارير الأقدم أدلة تاريخية.
- مستودع الحالة/التقارير: `papamohammed77-glitch/rawaie-erp-New`, فرع `main`, HEAD الحالي المرصود `17c9bf41c7d4a18244e0937f8b45ca4e6fc8e187` (توقيت commit: `2026-10-29T18:47:00Z`).
- المستودع التشغيلي: `papamohammed77-glitch/erp-frontend`, فرع `main`, HEAD `416de1c1d829c48b7c82442242a2a039e3d7e48c`.
- لا يُعاد فتح مشكلة Driver مستقلة بلا دليل جديد؛ ملف Driver بقي عند SHA `d7ace0b9be52c936aee1d5f5e1250b6d2e9a48f0`.

## 2. CONFIRMED

### GitHub / SOURCE CODE

- `companies/company-1/warehouse/returns.html` على `main`: Blob `36c20e03c94dc734e015610dec1e8208697df32a`. الكود الحالي يستعلم عن `Delivered` دون تصفية حسب المتبقي، ويحسب العرض القديم من `qty_loaded > qty_delivered` دون طرح `qty_returned`.
- Draft PR #8 مفتوح وغير مدموج، HEAD `3ad370c83f8f3c7880d7ace9ac24eabb5833f9cf`, وBase الحالي `416de1c1d829c48b7c82442242a2a039e3d7e48c`. Blob الفرع `9cc013a419f6dac2c656471b72f0e629a622a5b6`.
- رقعة R8-S1-A/B على Blob الفرع الحالي: كل محدد استبدال ظهر مرة واحدة؛ بعد تركيبها في الذاكرة اجتاز الـinline JavaScript الوحيد التحليل بـV8. اختبار منطق معزول أثبت أن `RS-1` ذي المتبقي صفر يُستبعد، و`RS-2` ذي المتبقي الموجب يظهر، و`Returning` لا يظهر إلا إذا تطابق `return_handler_id` مع المستخدم الحالي. هذه فحوص Static/logic فقط وليست Browser E2E.
- Parent: commit `0351897cf8758bc903ce4d0a52666db538c7b828` أصلح مقطع HTML/JavaScript المعيب؛ Blob الحالي لـ`companies/company-1/main.html` هو `3a5d2e565a04262081d024f6e514e1372d372e84`. HEAD الحالي يتضمن هذا commit.
- Driver: ملف `companies/company-1/delivery/driver.html` عند SHA `d7ace0b9be52c936aee1d5f5e1250b6d2e9a48f0`؛ كتلتا JavaScript المضمنتان اجتازتا التحليل في هذه الجولة. لا يوجد دليل جديد يربطه بعيب تصفية المرتجعات.

### CI / WORKFLOW

- ملف Workflow على `main`، Blob `7f821b2afdcb8d15f205782218b427d06da03a6e`، ما زال يحتوي assertion القديم `Canonical RW_HR payroll syntax not present` ولا يحتوي بوابة `Validate exact Mother inline JavaScript syntax` ولا trigger لـ`pull_request`.
- تشغيل `browser-e2e` على commit `0351897`: run `40928363996`, job `123639862789`. فشل عند `2026-10-29T18:11:07.2839783Z` برسالة `AssertionError: Canonical RW_HR payroll syntax not present`. لم يصل إلى تحليل Parent JavaScript ولم يبدأ Playwright؛ لذلك لا يثبت هذا التشغيل أن Parent الحالي صالح أو غير صالح نحويًا.
- فحص `inventory-forensic` في run `40928363894`, job `123639862762`, فشل عند `2026-10-29T18:11:03.1268319Z` لأن فاحص placeholder وجد كلمتي TODO. هذا فشل بوابة Static مستقلة، وليس دليلًا على عيب Inventory وقت التشغيل.
- PR #7 ما زال Draft/open وغير مدموج، HEAD `a38c5d15aadcb5c1af2c310a61077f0a73560b97`، وBase المسجل له `626df80fae8101fa6b1fe0ba0b6bc8d4ae69f8ca` الأقدم من HEAD الحالي. ملف Workflow في فرعه Blob `2e83d1e974646af6a3dcee5f03a68e6ac65bc307` ويحتوي بوابة التحليل الجديدة. التشغيل السابق على ذلك الفرع وصل إلى Node وفشل عند line 15839 قبل إصلاح Parent؛ لكنه لم يُثبت نجاح البوابة على Parent الحالي.

### Supabase Production

- مشروع `SMART ERP`, ref `fiilmooggumokxanwiyx`, حالته `ACTIVE_HEALTHY`، PostgreSQL `17.6.1.121`. قائمة migrations الحالية تحتوي 693 سجلًا، وآخر سجل مرصود `20261029153314 / capture_assigned_delivery_order_location_20261029`.
- قراءة SQL الحالية أكدت:
  - `RS-1`: `Delivered`, خمسة أسطر تفاصيل، إجمالي المتبقي `0`, وأسطر ذات متبقٍ `0`.
  - `RS-2`: `Delivered`, سبعة أسطر تفاصيل، إجمالي المتبقي `5`, وأسطر ذات متبقٍ `5`.
  - لا توجد حاليًا سجلات `Returning` في مجموعة البيانات المفحوصة.
- أعمدة `qty_loaded`, `qty_delivered`, `qty_returned`, `return_handler_id` موجودة. RLS مفعّل على `runsheets` و`run_sheet_details`. منح `authenticated` القراءة على الجدولين موجود؛ تحديث `run_sheet_details` غير ممنوح. السياسات الحالية تقيّد القراءة بنطاق الشركة والصلاحيات/الإسناد. Trigger `trg_audit_runsheets` يدقق عمليات runsheets. لم يتغير أي من ذلك في هذه الجولة.
- Edge Functions ذات الصلة ما زالت `start-return v4 ACTIVE` و`complete-return v26 ACTIVE` مع `verify_jwt=true`. لم تُستدعَ أو تُعدّل أي وظيفة في هذا التحقيق.

### Runtime logs

- سجلات Supabase عند `2026-10-29T18:17:11.783Z` و`18:17:11.784Z` تسجل طلبَي `GET 200` لقائمة `runsheets` باستخدام الإسقاط القديم `run_sheet_details(count)` للحالتين `Delivered` و`Returning`.
- حقلا `request.headers.referer` وOrigin كانا فارغين في السجلات المعروضة. الدليل يثبت أن عميلًا نفّذ الطلب القديم، لكنه **لا يحدد** إن كان العميل من Production أو Preview ولا يثبت محتوى الاستجابة/عدد الصفوف.

### Cloudflare checks

- GitHub check-runs على commit `416de1c`: مشروع `rawaea-erp` = success عند `2026-10-29T18:32:25Z`؛ `erp-frontend`, `rawaea-store`, `warehouse-supervisor` = failure.
- على commit PR #8 `3ad370c`: `rawaea-erp` Preview = success؛ المشروعات الثلاثة الأخرى = failure.
- نجاح check-run يثبت تقرير تكامل Cloudflare عن ذلك الـcommit، ولا يثبت وحده تطابق بايتات الملف الذي يقدمه النطاق أو صحة سلوك المستخدم.

## 3. UNKNOWN

- أي نسخة/نطاق أنتج طلبات Supabase القديمة عند 18:17Z؛ Origin/Referer غير متاحين.
- هل إخفاقات المشروعات الثلاثة الأخرى تمنع نشرًا مطلوبًا في مسارنا الحالي؛ لم تُقرأ Logs الخاصة بها.
- محتوى الاستجابة الفعلي للطلبات القديمة، وهوية HTML/JS الذي يقدمه Production حاليًا بايتًا ببايت.
- نتيجة قراءة RLS من جلسة المستخدم الفعلية بعد تطبيق الرقعة؛ استعلام SQL الإداري لا يحل محل اختبار جلسة مصادق عليها.

## 4. CONFLICT

- **بوابة CI متعارضة بين الفرعين:** `main` يشغّل assertion Payroll قديمًا ويفشل قبل syntax gate؛ فرع PR #7 يستبدله ببوابة تحليل JavaScript ويضيف `pull_request`. التغيير الصحيح ما زال في Draft غير مدموج، وقاعدته أقدم من Main الحالي.
- **إتاحة Browser connector:** CURRENT_STATE/Report557 استندا إلى لقطة Dashboard سابقة، لكن محاولة `Browser.list_tabs` في هذه الجولة أعادت `Browser access requires the originating browser context`. فتح نطاقات Cloudflare عبر أداة الويب تعذر، و`curl` تعذر بسبب DNS. لذلك لقطة Dashboard السابقة ليست فحصًا مباشرًا متجددًا لهذه الجولة.
- لا يوجد تعارض بين قيم Production واحتساب الأهلية: القيم الحالية تؤيد إخفاء `RS-1` وإظهار `RS-2` عند تنفيذ شرط المتبقي الصحيح.

## 5. UNVERIFIED

- تحليل JavaScript للملف الكامل Parent بعد commit `0351897`: لم يُنفّذ؛ GitHub fetch لا يعيد محتوى ملف Parent البالغ نحو 1.8 MB، وتشغيل CI على Main توقف عند assertion القديم.
- تشغيل بوابة syntax الجديدة على Parent الحالي ثم وصول Playwright إلى E2E.
- تطابق Artifact/headers/cache الذي يخدمه Cloudflare مع SHA المصدر.
- جلسة Browser مصادق عليها تثبت القائمة والبحث بعد الرقعة: `RS-1` مخفي، `RS-2` ظاهر، و`Returning` مقصور على المسند إليه.
- سلوك `Returning` في Production؛ لا توجد عينة حالية، ولم تُنشأ بيانات اختبار.

## 6. مصفوفة التحقق

| الطبقة | النتيجة | الدليل/الحد |
|---|---|---|
| GitHub/source — Returns main | CONFIRMED | HEAD `416de1c`, Blob `36c20e03...`; لا يحتوي إصلاح الأهلية |
| GitHub/source — PR #8 | CONFIRMED | HEAD `3ad370c`, Blob `9cc013a4...`; مفتوح وغير مدموج |
| Static patch R8-S1 | PASS in-memory | محددان فريدان، تحليل V8 كامل للـinline block، واختبار منطق معزول؛ لم يُكتب المصدر |
| GitHub/source — Parent | CONFIRMED partially | commit `0351897` موجود؛ Blob `3a5d2e...`; لا يوجد تحليل كامل ناجح |
| GitHub CI | BLOCKED | Main workflow stale assertion؛ PR #7 draft/old base؛ Playwright لم يعمل على Parent الحالي |
| Supabase Production | CONFIRMED | RS-1 pending=0؛ RS-2 pending=5؛ RLS/grants/policies مقروءة |
| Deployed artifact | UNVERIFIED | Cloudflare check status متاح؛ مطابقة البايتات غير متاحة |
| Runtime/E2E | UNVERIFIED | سجل طلب قديم دون Origin؛ Browser context غير متاح |
| Business-data effects | NO MUTATION | لا DDL/DML/RPC/Edge mutation؛ لم تُنشأ بيانات اختبار |

## 7. ما نُفّذ فعليًا

1. إعادة جلب HEAD والـblobs والـPRs والـworkflow الحالي من GitHub.
2. تحليل كامل للـinline JavaScript في `returns.html` على Main وفرع PR #8؛ كلاهما يجتاز التحليل النحوي، لكن Main ما زال يحمل العيب المنطقي.
3. تطبيق R8-S1-A/B في نسخة ذاكرة فقط؛ نجاح التحليل والاختبار المنطقي المعزول.
4. قراءة Production SQL للمخطط والقيم والسياسات والصلاحيات، واستعراض migrations وEdge Function registry.
5. قراءة Supabase runtime logs وGitHub check-runs/job logs لتحديد ما حدث فعليًا.
6. محاولة الوصول إلى Browser/Cloudflare artifact؛ فشلت الأدوات المتاحة كما هو موثق أعلاه.

## 8. ما لم يُنفّذ ولماذا

- لم يُكتب `returns.html` أو `main.html` أو أي ملف تشغيلي؛ قاعدة Report545 تحصر Parent في تطبيق المالك، وR8-S1 ما زالت Owner Patch.
- لم يُدمج PR #8 أو PR #7 ولم يُنشأ PR/Workflow جديد.
- لم تُجرَ أي تغييرات في Production schema/RLS/grants/RPC/Edge Functions أو بيانات المخزون/المحاسبة/الرانشيتات.
- لم يُنشر شيء من هذه الجولة؛ لا توجد جلسة Browser أو وسيلة تنزيل مباشرة تثبت Artifact أو E2E.
- لم تُنسب أسباب فشل Cloudflare للمشروعات الثلاثة إلى التطبيق لأن Logs السبب غير متاحة.

## 9. الخطوة التالية الواحدة ذات الأولوية

**يطبّق المالك R8-S1-A/B فقط على فرع PR #8 بعد إعادة جلب Blob SHA والتحقق من المحددين الفريدين؛ ثم يعاد فحص الـinline JavaScript كاملًا وتشغيل تحقق الأهلية على RS-1/RS-2 قبل أي دمج.** يظل الدمج/الإغلاق ممنوعًا حتى تُفهم إخفاقات Cloudflare، وتُثبت هوية Artifact، وتنجح جلسة E2E مصادق عليها. وبالتوازي، يجب تحديث/اعتماد بوابة PR #7 على أساس Main الحالي حتى لا يبقى assertion Payroll القديم حاجزًا أمام التحقق من Parent.

## Mutation Ledger

- Operational GitHub files: **لم تتغير**.
- Supabase Production schema/RLS/grants/functions/data: **لم تتغير**.
- Cloudflare configuration/deployment: **لم تتغير**.
- Browser E2E: **لم يُنفّذ**.
- التغيير الوحيد المسموح في هذه الجولة هو توثيق هذا التحقيق في مستودع الحالة، دون ادعاء إغلاق المشكلة.
