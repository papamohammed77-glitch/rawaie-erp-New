# Report557 — التحقيق التشغيلي لتصفية رانشيتات المرتجعات ومطابقة Parent/Driver/Returns

**Last Verified Event:** `LVE-2026-10-29-557`  
**تاريخ التحقق:** 2026-10-29  
**النطاق:** النظام الأم `companies/company-1/main.html`، تطبيق مندوب التوصيل `companies/company-1/delivery/driver.html`، تطبيق المرتجعات `companies/company-1/warehouse/returns.html`، وبيانات Supabase Production.  
**الحالة:** `RETURNS ROOT CAUSE CONFIRMED / FIX EXISTS IN DRAFT PR #8 ONLY / SEARCH HANDLER-SCOPE GAP IDENTIFIED / PARENT SOURCE PATCH COMMITTED / CLOUDFLARE PRODUCTION COMMIT OBSERVED / AUTHENTICATED E2E + BYTE-IDENTICAL ARTIFACT NOT VERIFIED / NOT CLOSED`

## 0. القرار التنفيذي

العطل المبلغ عنه في التطبيق المستقل ليس نقصًا في بيانات الرانشيتات أو عيبًا ثبت في RLS. السبب المباشر مثبت في المصدر: قائمة المرتجعات تجلب كل الرانشيتات بحالة `Delivered` دون اشتراط وجود كمية فعلية متبقية للمرتجع. والبحث كان يكرر المشكلة نفسها.

تم العثور على رقعة مقترحة موجودة بالفعل في Draft PR #8 في المستودع التشغيلي. الرقعة تطبق حساب المتبقي الصحيح على القائمة والبحث، وتضيف معالجة صريحة لأخطاء الاستعلامات، لكنها **ليست مدمجة في main** ولا يجوز وصفها بأنها إصلاح منشور. أثناء إعادة التحقق ظهر أيضًا اختلاف في البحث: الرقعة الحالية تسمح بعرض كل سجلات `Returning` في نتائج البحث، بينما القائمة الرئيسية تقصر السجلات النشطة على المستخدم المسند إليه المرتجع. يلزم تصحيح هذا التفاوت قبل اعتماد الرقعة.

لم يُعدّل المساعد أي ملف تشغيلي أو قاعدة بيانات أو بيانات أعمال. أُعد هذا التقرير كمرجع استئناف وOwner Change Set.

## 1. مراجع الحوكمة والاستمرارية

- قُرئ الدستور التشغيلي الدائم، مع التركيز على استعادة الذاكرة، مصادر الحقيقة، فصل المصدر عن Production والنشر، حدود صلاحيات المساعد والمالك، التعديل الجراحي، الاختبارات، وتصنيفات اليقين.
- قُرئ Report545 بوصفه مرجع الحوكمة الملزم، مع مراجعة تقارير المهمة الحديثة Report552 وReport554 وReport555، وقراءة نقاط الاستئناف ذات الصلة من `CURRENT_STATE.md`.
- يشير `CURRENT_STATE.md` إلى LVE-2026-10-29-556، لكن المسار المتوقع `Report556_STANDALONE_RETURNS_ELIGIBILITY_FILTER_20261029.md` لم يكن موجودًا في مجلد التقارير عند جلبه مباشرة. لا يُعد ذلك دليلًا على أن محتوى نقطة الحالة خطأ؛ إنه نقص توثيقي، ويضيف Report557 سجلًا قابلًا للاستعادة دون استبدال التاريخ.
- المستودع التشغيلي: `papamohammed77-glitch/erp-frontend`.
- مستودع الحالة والتقارير: `papamohammed77-glitch/rawaie-erp-New`.
- Supabase Production: `fiilmooggumokxanwiyx`.
- لا توجد تعديلات على `main.html` أو `driver.html` أو `returns.html` في هذا التقرير.

## 2. أدلة المصدر الحالي

### 2.1 تطبيق المرتجعات المستقل

- ملف main: `companies/company-1/warehouse/returns.html`
- Blob SHA على main: `36c20e03c94dc734e015610dec1e8208697df32a`
- Branch الرقعة الحالية: `fix/returns-only-pending-runsheets-20261029`
- Blob SHA للملف في الفرع: `9cc013a419f6dac2c656471b72f0e629a622a5b6`
- Commit الرقعة: `3ad370c83f8f3c7880d7ace9ac24eabb5833f9cf`
- Draft PR: [#8 — show only runsheets with outstanding returns](https://github.com/papamohammed77-glitch/erp-frontend/pull/8)، مفتوح وغير مدموج.

### 2.2 ما تحتويه الرقعة الموجودة بالفعل

في `App.loadRunsheets()`:
1. إزالة العلاقة غير الضرورية `run_sheet_details(count)` من استعلامي قائمة الرانشيت.
2. فحص أخطاء الاستعلامين الأساسيين واستعلام الكميات بدل تحويل الخطأ إلى قائمة فارغة.
3. جلب `qty_loaded, qty_delivered, qty_returned`.
4. احتساب سطر الصنف الذي لديه كمية متبقية فقط وفق `qty_loaded - qty_delivered - qty_returned > 0`.
5. تصفية قائمة `Delivered` بحيث لا يظهر الرانشيت إلا إذا كان لديه سطر واحد على الأقل بكمية متبقية.
6. تعديل حساب المتبقي في معاينة الرانشيت.

في `App.onSearchInput()`:
- أُضيف فحص خطأ الاستعلام وتفاصيل الرانشيت، وتصفية `Delivered` وفق وجود كمية متبقية.
- لكن الاستعلام لا يقرأ `return_handler_id`، والشرط الحالي `rs.status !== 'Delivered' || pending[rs.id] === true` يسمح بعرض كل `Returning` في البحث، حتى لو كان مسندًا إلى مستخدم آخر. هذا لا يطابق عقد القائمة الرئيسية التي تقرأ فقط `Returning` المسندة إلى `currentUser.id || currentUser.email`.
- استدعاء تفاصيل البحث الداخلي لا يُعاد من callback الخارجي؛ لذلك رفض Promise على مستوى النقل قد لا يصل إلى `.catch()` الخارجي. استجابات PostgREST التي تحتوي `error` يجري فحصها بالفعل، لكن ربط Promise الداخلي بالخارجي تحسين لازم لاكتمال معالجة الفشل.

### 2.3 النظام الأم ومندوب التوصيل

- أحدث commit مؤكد يعدل `companies/company-1/main.html` هو `0351897cf8758bc903ce4d0a52666db538c7b828`، بعنوان `Refactor return details rendering in main.html`. Diff هذا commit يصلح سلسلة HTML/JavaScript المعطوبة في جدول المرتجعات، ويصحح أعمدة تفاصيل الكميات إلى: محمّل، مسلّم، متبقٍ، مرتجع.
- HEAD المرصود بعده هو `416de1c1d829c48b7c82442242a2a039e3d7e48c`. مقارنة commits أثبتت أن HEAD متقدم بcommit واحد فقط عن `0351897`، وأن ذلك commit يغيّر الملف المساعد `_forensic_current_main_extract.md` لا `main.html`. إذن تعديل Parent موجود في سلسلة المصدر الحالية.
- ملف Parent حجمه نحو 1.8 MB؛ أداة جلب الملف أعادت SHA لكن لم تُعد محتوى الملف، لذلك لم يُدّعَ إجراء تحليل syntax كامل جديد على كامل الملف في هذه الجولة.
- ملف مندوب التوصيل `companies/company-1/delivery/driver.html` SHA `d7ace0b9be52c936aee1d5f5e1250b6d2e9a48f0`. لم يظهر من الأدلة الحالية ما يربط هذا الملف بعيب تصفية قائمة المرتجعات؛ لا مبرر لتعديله في هذا النطاق.
- لم يُثبت اختبار E2E مصادق عليه عبر الرحلة Parent → Driver → Returns في هذه الجولة.

## 3. قراءة Supabase Production — Read-only

تم تنفيذ استعلام SQL للقراءة فقط على `runsheets` و`run_sheet_details`، مع تجميع الكمية المتبقية لكل رانشيت.

| الرانشيت | الحالة | تفاصيل الأصناف | وحدات المتبقي للمرتجع | أسطر الأصناف ذات المتبقي |
|---|---|---:|---:|---:|
| `RS-1` | `Delivered` | 5 | 0 | 0 |
| `RS-2` | `Delivered` | 7 | 5 | 5 |

الاستعلام المنفصل للحالات أعاد رانشيتين فقط بحالة `Delivered`، ولا توجد حاليًا سجلات `Returning` في مجموعة البيانات المفحوصة. لذلك:
- منطق أهلية `Delivered` يمكن اختباره على بيانات قائمة دون إنشاء أي سجل.
- سلوك إبقاء `Returning` المسند إلى المستخدم الحالي لا يمكن اختباره ببيانات Production الحالية؛ لا تُنشئ بيانات تجريبية لهذا الغرض.
- لم تتغير بيانات الأعمال أو المخزون أو المحاسبة أو حالة الرانشيتات.

## 4. Owner Surgical Change Set — Patch R8-S1

**النطاق:** فرع المراجعة `fix/returns-only-pending-runsheets-20261029` فقط، ملف `companies/company-1/warehouse/returns.html`. لا تكتب التغيير مباشرة إلى main ولا تدمج PR قبل اكتمال الاختبارات. قبل التطبيق، أعد جلب الملف وتأكد أن SHA ما زال `9cc013a419f6dac2c656471b72f0e629a622a5b6` وأن المحددات التالية فريدة.

### Patch R8-S1-A — اقرأ هوية المسند إليه في نتائج البحث

ابحث عن استعلام البحث الحالي:

```javascript
supabase.from('runsheets').select('id, runsheet_code, status, run_date, driver_id').in('status', ['Delivered', 'Returning'])
```

واستبدل جزء `select` فقط:

```javascript
supabase.from('runsheets').select('id, runsheet_code, status, run_date, driver_id, return_handler_id').in('status', ['Delivered', 'Returning'])
```

### Patch R8-S1-B — وحّد أهلية البحث مع القائمة الرئيسية واربط Promise

داخل `App.onSearchInput()`، استبدل هذا المقطع الأصلي:

```javascript
                supabase.from('run_sheet_details').select('runsheet_id, item_code, qty_loaded, qty_delivered, qty_returned').in('runsheet_id', rowIds).then(function(detailsRes) {
                    if (detailsRes.error) {
                        console.error('[RW_Returns] runsheet search details query failed:', detailsRes.error);
                        self.searchResults = [];
                        self.renderSearchDropdown();
                        return;
                    }
                    var pending = {}, counts = {};
                    (detailsRes.data || []).forEach(function(det) {
                        counts[det.runsheet_id] = (counts[det.runsheet_id] || 0) + 1;
                        var remaining = (Number(det.qty_loaded) || 0) - (Number(det.qty_delivered) || 0) - (Number(det.qty_returned) || 0);
                        if (remaining > 0) pending[det.runsheet_id] = true;
                    });
                    self.searchResults = rows.filter(function(rs) {
                        return rs.status !== 'Delivered' || pending[rs.id] === true;
                    }).map(function(rs) {
                        rs.detail_count = counts[rs.id] || 0;
                        return rs;
                    });
                    self.renderSearchDropdown();
                });
```

بالمقطع البديل:

```javascript
                return supabase.from('run_sheet_details').select('runsheet_id, item_code, qty_loaded, qty_delivered, qty_returned').in('runsheet_id', rowIds).then(function(detailsRes) {
                    if (detailsRes.error) {
                        console.error('[RW_Returns] runsheet search details query failed:', detailsRes.error);
                        self.searchResults = [];
                        self.renderSearchDropdown();
                        return;
                    }
                    var pending = {}, counts = {};
                    (detailsRes.data || []).forEach(function(det) {
                        counts[det.runsheet_id] = (counts[det.runsheet_id] || 0) + 1;
                        var remaining = (Number(det.qty_loaded) || 0) - (Number(det.qty_delivered) || 0) - (Number(det.qty_returned) || 0);
                        if (remaining > 0) pending[det.runsheet_id] = true;
                    });
                    self.searchResults = rows.filter(function(rs) {
                        if (rs.status === 'Delivered') return pending[rs.id] === true;
                        if (rs.status === 'Returning') return rs.return_handler_id === (self.currentUser.id || self.currentUser.email);
                        return false;
                    }).map(function(rs) {
                        rs.detail_count = counts[rs.id] || 0;
                        return rs;
                    });
                    self.renderSearchDropdown();
                });
```

السبب: نتائج البحث يجب أن تطبق عقد الأهلية نفسه الذي تطبقه القائمة، لا أن تعيد إظهار `Delivered` بلا متبقي أو `Returning` غير المسند إلى المستخدم الحالي. كما أن `return` يجعل رفض Promise الداخلي يصل إلى `.catch()` الخارجي الموجود بالفعل.

**ما يجب أن يبقى دون تغيير:** دوال بدء/إلغاء/إنهاء المرتجع، عقود `start-return` و`complete_return_atomic`، المخزون والمحاسبة، `core.js`، Parent `main.html`، Driver `driver.html`، المخطط وRLS وEdge Functions.

## 5. النشر وRuntime

### CONFIRMED
- Draft PR #8 ما زال مفتوحًا وغير مدموج، ويغيّر ملف `returns.html` فقط.
- تعليقات Cloudflare على commit `3ad370c` سجلت فشل build لمشروعات `erp-frontend` و`rawaea-store` و`warehouse-supervisor`.
- سجل Cloudflare أظهر نجاح نشر Preview لمشروع `rawaea-erp` على commit `3ad370c`، بعنوان Preview `https://da5fcdde.rawaea-erp.pages.dev` وفرع Preview `https://fix-returns-only-pending-run.rawaea-erp.pages.dev`.
- صفحة Cloudflare المفتوحة تعرض نشر Production لمشروع `rawaea-erp` على `main` عند commit `416de1c` ورابط deployment `https://b469734c.rawaea-erp.pages.dev`. وهذا commit يتضمن تعديل Parent `0351897` في سلسلة المصدر.

### UNVERIFIED
- لم تُثبت مطابقة بايتات ملف `returns.html` الذي يقدمه نطاق Production مع Blob محدد.
- لم يُنفذ اختبار متصفح مصادق عليه لتأكيد أن `RS-1` مخفي وأن `RS-2` ظاهر في القائمة والبحث بعد نشر الرقعة.
- لم تُراجع تفاصيل Logs الخاصة بفشل مشروعات Cloudflare الثلاثة؛ لذلك لا يُنسب فشل البناء إلى رقعة المرتجعات أو إلى Parent دون دليل مباشر.
- لم يُثبت تشغيل CI ناجح لبوابة syntax/E2E على Parent بعد commit `0351897`. أداة حالة الـcommit أعادت قائمة checks فارغة؛ لا تُفسر القائمة الفارغة على أنها PASS.

## 6. مصفوفة التحقق

| الطبقة | النتيجة | الدليل / الحد |
|---|---|---|
| GitHub — Returns main | `CONFIRMED` | Blob `36c20e03...` ما زال على main؛ الإصلاح ليس مدموجًا |
| GitHub — Returns review branch | `CONFIRMED` | Blob `9cc013a4...`, commit `3ad370c...`, Draft PR #8 |
| Supabase Production | `CONFIRMED` | RS-1 المتبقي 0؛ RS-2 المتبقي 5؛ قراءة فقط |
| Parent current source | `CONFIRMED` | Commit `0351897` يصلح مقطع HTML/JS؛ HEAD `416de1c` يتضمنه |
| Driver current source | `CONFIRMED` | SHA `d7ace0b9...`؛ لا دليل على عيب به في هذه الواقعة |
| Cloudflare Production artifact | `PARTIALLY VERIFIED` | لوحة النشر تعرض commit `416de1c`، لكن المطابقة البايتية وRuntime E2E غير مثبتين |
| Authenticated end-to-end | `UNVERIFIED` | لم تُنفذ رحلة Parent → Driver → Returns بعد التغيير |

## 7. Mutation Ledger

- `companies/company-1/warehouse/returns.html`: لم يكتب المساعد إلى الملف؛ توجد رقعة مقترحة فقط في Draft PR #8.
- `companies/company-1/main.html`: لم يكتب المساعد إلى الملف. أظهر GitHub أن commit المالك `0351897` عدّل المقطع المعطوب.
- `companies/company-1/delivery/driver.html`: لم يتغير.
- Supabase Production: استعلامات قراءة فقط؛ لا DDL، ولا RPC، ولا RLS/ACL، ولا بيانات أعمال.
- Cloudflare: لم تُنفذ تغييرات نشر أو إعدادات.
- لا توجد بيانات اختبار أُنشئت أو تُركت في Production.

## 8. شروط الإغلاق والخطوة التالية

1. يراجع المالك Patch R8-S1-A/B على فرع PR #8 بعد التأكد من SHA وحدود النص، ويطبقها على الفرع فقط.
2. يعاد فحص JavaScript inline block كاملًا في `returns.html` واختبارات الثوابت: RS-1 مخفي، RS-2 ظاهر، البحث يطبق الشرط نفسه، و`Returning` لا يظهر إلا للمستخدم المسند إليه.
3. يراجع مالك المشروع تفاصيل فشل Cloudflare للمشروعات الثلاثة دون افتراض السبب؛ ثم يعاد اختبار البناء على الفرع المحدث.
4. يُتحقق من Artifact الذي يخدمه Production، ثم تُنفذ جلسة E2E مصادق عليها: فتح التطبيق، ظهور RS-2 فقط، البحث عن RS-1 فلا يظهر، البحث عن RS-2 فيظهر، وفتح التفاصيل دون بدء أو إنهاء مرتجع أثناء الاختبار.
5. تُختبر حالة `Returning` فقط إذا كانت هناك حالة عمل حقيقية مصرح بها؛ لا تُنشأ بيانات اصطناعية في Production.
6. لا يدمج PR ولا تُعلن الحالة `FIXED AND E2E VERIFIED` قبل نجاح الاختبارات والتحقق من النشر.

**الحالة النهائية:** `ROOT CAUSE CONFIRMED / CORE FILTER PATCH DRAFTED / SEARCH SCOPE MICRO-PATCH READY FOR OWNER / PARENT SOURCE PATCH COMMITTED / PRODUCTION DEPLOYMENT SHOWN BY CLOUDFLARE / EXACT ARTIFACT + AUTHENTICATED E2E OPEN / NOT CLOSED`
