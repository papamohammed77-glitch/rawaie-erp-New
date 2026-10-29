# Report560 — إعادة المطابقة الحالية لفلترة المرتجعات وفجوة البحث — 2026-10-29

**Last Verified Event:** `LVE-2026-10-29-560`  
**التاريخ:** 2026-10-29  
**النطاق:** تكامل النظام الأم `main.html` وتطبيق مندوب التوصيل `driver.html` وتطبيق المرتجعات المستقل `returns.html`؛ أهلية الرانشيتات في قائمة المرتجعات والبحث، ومطابقة GitHub / Supabase Production / Cloudflare.  
**مرجع الحوكمة:** [الدستور التشغيلي الدائم](الدستور%20التشغيلي%20الدائم.md)، Report545، Reports552–559، مع إعادة فحص المصدر الحالي مباشرة.  
**الحالة:** `ROOT CAUSE RECONFIRMED / MAIN STILL DEFECTIVE / CORE FILTER ONLY IN DRAFT PR #8 / OWNER SEARCH PATCH REQUIRED / PRODUCTION READ-ONLY / SERVED BYTES + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED`

## 0. القرار التنفيذي

تمت قراءة الدستور التشغيلي الدائم وReport545 وCURRENT_STATE عند LVE-559، ثم مراجعة تقارير المرتجعات ذات الصلة (552، 553، 557، 558، 559) ومطابقتها بمصدر التشغيل الحالي وProduction ولقطة Cloudflare الحالية.

**السبب الجذري مؤكد في `main` داخل تطبيق المرتجعات:** قائمة المرتجعات تحمّل كل الرانشيتات ذات الحالة `Delivered`، وتحسب السطور المتبقية اعتمادًا على `qty_loaded - qty_delivered` من دون طرح `qty_returned`، ولا تصفي قائمة `Delivered` حسب وجود كمية إيجابية مستحقة للمرتجع. كما أن البحث في `main` يعرض الحالات `Delivered` و`Returning` دون حساب أهلية أي منهما.

يوجد إصلاح أساسي جاهز في Draft PR #8، لكنه **غير مدموج** ولا يدخل ضمن المصدر الرئيسي أو نشر Production الحالي. الرقعة الموجودة تصلح تصفية القائمة وحساب المتبقي وتضيف معالجة أخطاء، لكنها لا تزال تحتاج تصحيحًا موضعيًا في البحث: استعلام البحث لا يجلب `return_handler_id`، والمرشح يسمح بعرض أي رانشيت `Returning` حتى إن كان مسندًا إلى مندوب مرتجعات آخر. كذلك يجب إعادة Promise استعلام تفاصيل البحث حتى تصل أخطاء الرفض إلى `.catch()` الخارجي.

لم يُعدّل أي ملف تشغيل أو Production في هذه الجولة. ووفق الدستور، يكون التغيير على ملف التطبيق من المالك وحده. لا حاجة إلى تغيير `main.html` أو `driver.html` أو المخطط أو RLS أو RPC أو Edge Functions لعلاج العيب المثبت في `returns.html`.

## 1. الأدلة الحالية وهوية المصدر

### 1.1 GitHub — مصدر التشغيل

- المستودع: `papamohammed77-glitch/erp-frontend`، الفرع `main`.
- HEAD الحالي: `416de1c1d829c48b7c82442242a2a039e3d7e48c`، ورسالة آخر commit: `forensic: persist current Mother HR extract`. المقارنة تؤكد أن هذا الـcommit غيّر `_forensic_current_main_extract.md` فقط، وأن commit النظام الأم السابق `0351897cf8758bc903ce4d0a52666db538c7b828` لا يزال في تاريخ الفرع.
- Parent `companies/company-1/main.html`: Blob `3a5d2e565a04262081d024f6e514e1372d372e84`. إصلاح سلسلة HTML/JavaScript في جدول المرتجعات وتصحيح أعمدة الكميات موجودان في تاريخ المصدر الحالي منذ commit `0351897`. لم يظهر في الأدلة الحالية سبب يبرر إعادة تعديل Parent لهذا العيب.
- Driver `companies/company-1/delivery/driver.html`: Blob `d7ace0b9be52c936aee1d5f5e1250b6d2e9a48f0`. لا دليل مباشر على أن الملف سبب عيب أهلية قائمة المرتجعات؛ لا يُعدّل ضمن هذه الرقعة.
- Returns على `main`: Blob `36c20e03c94dc734e015610dec1e8208697df32a`. عيب الأهلية موجود في المصدر الحالي.
- Draft PR #8: [show only runsheets with outstanding returns](https://github.com/papamohammed77-glitch/erp-frontend/pull/8)، الفرع `fix/returns-only-pending-runsheets-20261029`، HEAD `3ad370c83f8f3c7880d7ace9ac24eabb5833f9cf`، Returns Blob `9cc013a419f6dac2c656471b72f0e629a622a5b6`. الحالة `open / draft / unmerged` وقاعدة الفرع `main` عند `416de1c`.

### 1.2 العيب في Returns على main

في `App.loadRunsheets()`، المصدر الحالي ينفذ ما يلي:

1. يستعلم عن `Returning` المسند إلى `currentUser.id || currentUser.email`.
2. يستعلم عن **كل** `Delivered` حتى حد القائمة، دون شرط كمية متبقية.
3. يطلب تفاصيل `qty_loaded, qty_delivered` فقط.
4. يضيف إلى `remainingMap` كل سطر فيه `loaded > delivered`، دون أن يطرح `qty_returned`.
5. يمرر قائمة `available` إلى `renderRunsheetGrid` دون تصفيتها إلى الرانشيتات التي لديها كمية مرتجعة متبقية موجبة.

وفي `App.onSearchInput()`، يستعلم البحث عن كل `Delivered` و`Returning` المطابقة لرقم الرانشيت، ثم يعرض النتائج دون حساب كمية المرتجعات أو مطابقة إسناد حالة `Returning` للمستخدم الحالي.

### 1.3 ما هو موجود بالفعل في PR #8

الفرع المقترح يعالج أصل خلل القائمة: يجلب `qty_returned`، ويحسب المتبقي لكل سطر وفق:

`max(0, qty_loaded - qty_delivered - qty_returned)`

ويعرض رانشيت `Delivered` فقط إذا احتوى سطر واحد على الأقل على كمية متبقية موجبة، مع إبقاء الرانشيتات النشطة `Returning` المسندة إلى المستخدم ضمن القائمة. كما يحسن التعامل مع أخطاء الاستعلامات.

لا تعاد كتابة هذا الجزء ولا يُنقل إلى `main` يدويًا قبل مراجعة PR واختبار كامل. التغيير المطلوب الآن هو Patch R8-S1-A/B الموضح في القسم 4، على فرع PR #8 وحده، بعد مطابقة SHA والمحددات.

## 2. Supabase Production — قراءة مستقلة فقط

نُفذ استعلام قراءة فقط على مشروع `SMART ERP`، المرجع `fiilmooggumokxanwiyx`.

- وقت التحقق من قاعدة البيانات: `2026-10-29 19:03:17.860357+00` (UTC).
- PostgreSQL: `17.6`.
- الاستعلام جمع تفاصيل `Delivered` و`Returning` و`Returned` وحسب إجمالي المتبقي كالتالي:

`sum(greatest(coalesce(qty_loaded,0) - coalesce(qty_delivered,0) - coalesce(qty_returned,0), 0))`

| الرانشيت | الحالة الحالية | تفاصيل الأصناف | وحدات المتبقي للمرتجع |
|---|---|---:|---:|
| `RS-1` | `Delivered` | 5 | 0 |
| `RS-2` | `Delivered` | 7 | 5 |

لم تُرجع العينة الحالية أي رانشيت بحالة `Returning` أو `Returned`. لذلك لا يُنشأ أي سجل تجريبي في Production؛ يمكن التحقق من شرط الأهلية على بيانات قائمة: يجب إخفاء `RS-1` وإظهار `RS-2`. أما أهلية `Returning` حسب المسند إليه فتحتاج إلى اختبار معزول، أو جلسة/بيانات اختبار معتمدة خارج Production.

**سجل سلامة البيانات:** لم يُنفذ أي DDL أو DML أو RPC كتابي، ولم تتغير حالات الرانشيتات أو المخزون أو الحسابات أو RLS/ACL أو Edge Functions. لم تُنشأ أو تُحذف بيانات اختبار.

## 3. Cloudflare والنشر — فصل المصدر عن Artifact

لقطة Cloudflare Dashboard المفتوحة أثناء هذه الجولة تعرض:

- Production لمشروع Pages `rawaea-erp` على commit `416de1c`، وdeployment URL `https://b469734c.rawaea-erp.pages.dev/`.
- Preview لفرع `fix/returns-only-pending-runsheets-20261029` على commit `3ad370c`، وdeployment URL `https://da5fcdde.rawaea-erp.pages.dev/`.
- ظهرت كذلك معاينات أخرى من الفرع؛ لا تعدّ المعاينة أو وجود commit دليلًا على تحديث Production.

لا يمكن الجزم من لقطة لوحة النشر وحدها بتطابق HTML/JavaScript الذي يخدمه النطاق العام بايتًا ببايت مع Blob بعينه. محاولة قراءة رابط Pages مباشرة من أداة الويب لم تكن متاحة في هذه البيئة. كما أن لقطة التطبيق الأم لا تثبت رحلة تشغيل مصادق عليها؛ لذلك تبقى هوية Artifact المنشور وسلوك القائمة والبحث في جلسة مصادق عليها `UNVERIFIED`.

تقارير 558/559 تشير إلى حالات CI/Cloudflare فاشلة في مشروعات أخرى، لكن لم تُقرأ سجلات البناء التفصيلية في هذه الجولة. لا تُنسب أسباب تلك الإخفاقات إلى هذه الرقعة دون Logs مباشرة.

## 4. Owner Surgical Change Set — R8-S1-A/B فقط

**الهدف:** توحيد أهلية البحث مع القائمة الرئيسية داخل `companies/company-1/warehouse/returns.html` على فرع `fix/returns-only-pending-runsheets-20261029` فقط.

**شرط التطبيق:** أعد جلب المصدر من الفرع قبل التعديل. لا تُطبق الرقعة إلا إذا بقي Blob SHA `9cc013a419f6dac2c656471b72f0e629a622a5b6`، وكان محدد كل تغيير فريدًا. في التحقق الحالي، ظهر كل من محدد الاستعلام ومحدد كتلة تفاصيل البحث والشرط القديم مرة واحدة. إذا تغير SHA أو النص أو عدد المطابقات، أعد بناء الرقعة على النسخة الجديدة؛ لا تلصق مقطعًا تاريخيًا عميانيًا.

### Patch R8-S1-A — تضمين هوية المسند إليه ضمن إسقاط البحث

ابحث عن السطر الحالي:

```javascript
supabase.from('runsheets').select('id, runsheet_code, status, run_date, driver_id').in('status', ['Delivered', 'Returning'])
```

واستبدل هذا السطر وحده بـ:

```javascript
supabase.from('runsheets').select('id, runsheet_code, status, run_date, driver_id, return_handler_id').in('status', ['Delivered', 'Returning'])
```

### Patch R8-S1-B — أهلية موحّدة وربط Promise تفاصيل البحث

داخل `App.onSearchInput()`، استبدل كتلة البحث الداخلية الآتية فقط.

**النص الأصلي في Blob الحالي للفرع:**

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

**النص البديل الكامل:**

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

**سبب التغيير:** `Delivered` لا يظهر في البحث إلا إذا كان لديه متبقٍ موجب بعد طرح الكمية المسلمة والمرتجعة؛ و`Returning` لا يظهر في البحث إلا وفق عقد الإسناد المستخدم في القائمة الرئيسية. كلمة `return` قبل استعلام التفاصيل تجعل رفض Promise الداخلي قابلًا للوصول إلى `.catch()` الخارجي الموجود بالفعل.

**ما لا يتغير:** دوال بدء/إلغاء/إنهاء المرتجع، RPCs/Edge Functions، الكميات أو الحالة في Production، المخزون والمحاسبة، `main.html`، `driver.html`، `core.js`، schema، RLS وACL.

## 5. التحقق الذي أُنجز وحدوده

### CONFIRMED
1. المصدر الحالي على `main` يحتوي السبب الجذري؛ Blob `36c20e03...`.
2. PR #8 يحتوي إصلاح القائمة وحساب المتبقي؛ Blob `9cc013a4...`، لكنه Draft وغير مدموج.
3. فجوة البحث في PR #8 مثبتة؛ حقول الاستعلام والشرط القديم موجودان بمطابقة واحدة لكل محدد.
4. Production: `RS-1` متبقيه صفر، و`RS-2` متبقيه خمس وحدات.
5. Cloudflare Dashboard تعرض Production على `416de1c` وPreview الفرع على `3ad370c`.
6. شغّلت اختبار منطق معزول ببيانات ثابتة داخل الذاكرة: استبعد `RS-1`، وأبقى `RS-2`، وأبقى حالة `Returning` المسندة إلى المستخدم الجاري، واستبعد حالة `Returning` المسندة إلى مستخدم آخر والحالة غير المدعومة. هذا اختبار للمقطع المقترح، وليس سجلًا حقيقيًا أو E2E.
7. لم تتغير ملفات التشغيل أو قاعدة البيانات في هذه الجولة.

### UNKNOWN / UNVERIFIED
1. لا توجد عينة `Returning` حالية في Production لإثبات حالة الإسناد ببيانات فعلية دون اختبار منفصل.
2. لم تُثبت مطابقة بايتات Artifact الذي يخدمه Production.
3. لم ينفذ Browser E2E مصادق عليه بعد التطبيق والنشر.
4. لم تُقرأ Logs تفصيلية لكل حالات Cloudflare CI المشار إليها سابقًا.
5. لم يُنفذ فحص `node --check` للملف الكامل بعد تطبيق Owner Patch؛ لم يُطبق التغيير بعد. اختبار المنطق المعزول لا يحل محل هذا الفحص.

## 6. شروط إغلاق المهمة

1. يعيد المالك تطبيق R8-S1-A/B فقط على فرع PR #8 بعد تحقق SHA والمحددات، ثم يسجل commit جديدًا.
2. يُفحص JavaScript المضمن كاملًا في الملف الناتج باستخدام بوابة syntax معتمدة، وتُختبر أهلية القائمة والبحث: `RS-1` مخفي، `RS-2` ظاهر، و`Returning` لا يظهر إلا للمستخدم المسند إليه.
3. لا يبدأ أي مرتجع ولا يُنهى أثناء اختبار العرض؛ لا تغييرات مخزون/حسابات/حالات بسبب اختبارات الأهلية.
4. تُقرأ سجلات فشل البناء الفعلية وتُعالج أسبابها المثبتة فقط.
5. بعد النشر، يثبت المالك هوية Artifact ويجري E2E في جلسة مصادق عليها: Parent → Driver/تسليم → Returns list/search → فتح تفاصيل الرانشيت، مع Console/Network/DOM منقحة من الأسرار.
6. لا يُدمج PR #8 ولا يُعلن الإغلاق قبل اجتياز هذه البوابات.

## 7. Mutation Ledger

- `companies/company-1/main.html`: لم يتغير.
- `companies/company-1/delivery/driver.html`: لم يتغير.
- `companies/company-1/warehouse/returns.html` على `main` وفرع PR #8: لم يتغيرا في هذه الجولة.
- Supabase Production schema/data/RLS/ACL/RPC/Edge Functions: قراءة فقط؛ لم تتغير.
- Cloudflare deployment/settings: لم تتغير.
- لا سجلات اختبار أنشئت أو حذفت.
- التغييرات المنفذة في هذه الجولة تقتصر على توثيق إعادة التحقق وتحديث سجل الحالة/الذاكرة.

**Final Status:** `ROOT CAUSE CONFIRMED / CURRENT MAIN DEFECT CONFIRMED / CORE FIX IN DRAFT PR #8 ONLY / OWNER SEARCH PATCH REQUIRED / PRODUCTION READ-ONLY / ARTIFACT + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED`.

**Next exact action:** طبّق R8-S1-A/B على فرع PR #8 فقط بعد إعادة التحقق من SHA `9cc013a419f6dac2c656471b72f0e629a622a5b6`، ثم أعد فحص Syntax والاختبارات المعزولة قبل أي دمج أو ادعاء بإصلاح Production.
