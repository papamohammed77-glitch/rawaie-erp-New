# Report714 — استكمال التحقق من نشر المخزن الشامل وحدود تكامل النظام الأم
**التاريخ:** 2026-11-13 (Africa/Cairo)  
**نقطة الاستئناف:** LVE-2026-11-13-713  
**الحكم:** READY WITH LIMITATIONS — تم إثبات نجاح بناء ونشر Cloudflare Pages لمشروع rawaea-erp على commit الحالي، ونجاح CI. لم يكتمل قبول Production Runtime أو الصور الفعلية أو ظهور سجل العمليات داخل واجهات النظام الأم.  
**النطاق:** Warehouse Hub / Picker / Loader / Returns / Unloader، Cloudflare Pages check runs، CI، فحص read-only لمخطط Supabase ومراجع الصور، ومراجعة مصدر main.html.

## 1. استعادة الحالة
- تمت مراجعة CURRENT_STATE والدستور الدائم وتقارير LVE-712 وLVE-713 قبل الاستكمال.
- Operational HEAD المؤكد من سجل commits: `930c6eb1b860b74be9b08563566736e27c8a068e`.
- لا توجد commits تشغيلية أحدث من HEAD أعلاه وقت الفحص.
- تغييرات التطبيق السابقة محفوظة في `a47dd90df1d410a84e5275a6e3295c4563689fef`، وتصحيح CI في `930c6eb1b860b74be9b08563566736e27c8a068e`.

## 2. أدلة النشر وCI الجديدة

### Cloudflare Pages
**CONFIRMED — Build/Deploy success for target Pages project**
- GitHub check run: `Cloudflare Pages: rawaea-erp`.
- Commit: `930c6eb1b860b74be9b08563566736e27c8a068e`.
- النتيجة: completed / success / “Deployed successfully”.
- Cloudflare Preview URL: https://d71efa19.rawaea-erp.pages.dev
- Deployment details: https://dash.cloudflare.com/?to=/504e4fe3e1141a251c622ea69fd4ad06/pages/view/rawaea-erp/d71efa19-541b-48d1-8513-78f526ecec40

**تنبيه دقيق:** نجاح Cloudflare check يثبت اكتمال Build/Deploy للـPreview المرتبط بالـcommit؛ لا يثبت أن custom Production alias `rawaea-erp.pages.dev` قد تحول إلى هذه النسخة، ولا يثبت نجاح جلسة مستخدم مصادق عليها.

- ظهرت أيضًا ثلاثة Cloudflare Pages check runs فاشلة لمشروعات منفصلة: `warehouse-supervisor` و`rawaea-store` و`erp-frontend`. ليست هذه check run الخاصة بمشروع `rawaea-erp` المستهدف في هذه المهمة؛ يجب عدم خلطها بنتيجة نشر Warehouse Hub المستهدف.

### GitHub Actions
- Warehouse E2E Run `43462936571`: SUCCESS، على HEAD نفسه.
- Job `132014344969`: جميع الخطوات مكتملة بنجاح، بما فيها Static source contract وPlaywright Browser E2E.
- رابط: https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/43462936571
- اجتاز الاختبار المحلي الأصلي ست مساحات تشغيل native، سجل العمليات المكتملة، أهلية التفريغ، الأذونات الخمسة، طلب استلام الفرع، وعرض الصور باستخدام صور QA اصطناعية مع اختبار fallback.
- الاختبارات تستخدم mock/local fixtures؛ لا تمثل قياسًا لشبكة صور Production ولا جلسة مستخدم Production.

## 3. فحص Source وSupabase الإضافي

### بنية التطبيق
- فحص `warehouse.html` الحالي يؤكد عدم وجود iframe أو srcdoc؛ التطبيق يحتوي على أربع واجهات عليا: اليوم، العمليات، الأذونات، حسابي، ومساحات التشغيل native.
- فحص workflow يؤكد وجود اختبارات لمساحات التشغيل الستة، وأوضاع الجرد الثلاثة، وسجل الأحداث، وعمليات الأذونات.
- مصدر صور البنود ما زال `items.image_url`؛ `run_sheet_details` لا يحتوي عمود `image_url`.
- استعلام information_schema للقراءة فقط أكد أعمدة الشركة/نوع العملية/الحالة/الحمولات في `erp_operation_registry`، وعمود `items.image_url`، وحقول دورة التحميل في `runsheets`.

### روابط الصور الفعلية
- استعلام SELECT حديث على RS-1 إلى RS-4 أعاد 19 مرجع صورة مرتبطة بالبنود.
- العينة تضم روابط Googleusercontent وروابط Supabase Storage؛ لا تغيير على أي رابط أو كائن.
- محاولة فتح روابط Googleusercontent وSupabase Storage عبر قناة الويب لم تستطع الوصول إليها، وكذلك Preview URLs. هذا عجز أداة الوصول وليس دليلًا على أن الصور نفسها معطوبة.
- لم تتوفر جلسة Browser ذات originating context؛ لذلك لم يمكن قياس HTTP status أو `naturalWidth` في المتصفح الحقيقي.
- **الحكم:** مصدر الروابط والارتباطات CONFIRMED؛ سلامة تحميل الصور في Production Runtime ما زالت UNKNOWN/UNVERIFIED.

### النظام الأم
- مراجعة مصدر `companies/company-1/main.html` لم تجد استهلاكًا مباشرًا لـ`erp_operation_registry` أو أنواع أحداث `complete_runsheet_picking/loading/unloading`.
- هذا يثبت غياب قارئ مباشر لسجل الأحداث بهذه الأنواع في الملف الحالي، لكنه لا يثبت وحده أن هناك تبويبًا أموميًا مطلوبًا لعرض هذه الأحداث؛ يجب مطابقة ذلك مع عقد كل تبويب/تقارير المخزون الحالية قبل أي تعديل.
- لم يُعدل `main.html` أو `core.js`؛ لا يجوز إدخال واجهة/تقرير جديد في النظام الأم دون Change Set محدد يثبت موضع العرض ومصدر البيانات ومنع التكرار.

## 4. حدود الوصول التي بقيت
- GitHub Actions وCloudflare check run أمكن قراءتهما.
- فتح Preview URLs وروابط الصور عبر Web غير متاح في هذه الجلسة.
- Browser connector يتطلب originating browser context، ولم يقدم هذه الجلسة.
- لا يوجد دليل حالي يثبت alias Production أو دخول مستخدم فعلي أو ظهور الصور في DOM أو انعكاس أحداث التحضير/التحميل/التفريغ في تبويبات الأم.

## 5. السلامة والأثر
- Supabase: SELECT فقط على information_schema وبيانات الصور المرجعية.
- لا DML/DDL، لا Migration، لا RPC، لا Edge Function.
- لا تعديل في مخزون/خزينة/محاسبة/موردين/عهد.
- لا تعديل في main.html أو core.js أو سياسات RLS/GRANT.
- لا QA writes في Production.

## 6. مصفوفة الإغلاق
| البند | الحالة | الدليل |
|---|---|---|
| Picker/Loader/Unloader source repairs | CONFIRMED | commits a47dd90 + 930c6eb |
| Warehouse static contract + local Browser E2E | PASS | Run 43462936571 |
| Cloudflare Pages build/deploy for rawaea-erp preview | SUCCESS | Cloudflare check run on 930c6eb |
| Custom Production alias parity | UNVERIFIED | Preview success لا يثبت alias |
| Authenticated Production runtime | UNVERIFIED | originating browser context غير متاح |
| Real image HTTP/naturalWidth | UNVERIFIED | تعذر فتح الروابط وغياب المتصفح |
| Parent tab visibility of picker/load/unload event history | OPEN / CONTRACT TO CONFIRM | main.html لا يقرأ registry مباشرة؛ لا تعديل دون إثبات موضع العرض |
| Production business-data effects | NONE BY THIS TASK | لا عمليات كتابة أو تنفيذ RPC/Edge |

## 7. القرار ونقطة الاستئناف التالية
لا توجد حجة تقنية تبرر تغيير روابط الصور أو تخزينها الآن؛ ذلك سيكون تغييرًا غير قائم على قياس. كما لا يوجد ما يبرر تعديل main.html لمجرد غياب قارئ registry قبل تحديد التبويب الأمومي المطلوب وعقد البيانات الذي يجب أن يعرضه.

**الأولوية التالية المحددة:**
1. فتح Preview/Production من جلسة Browser مصادق عليها وإجراء Forced Reload ثم تسجيل SHA/URL الفعليين.
2. قياس صور RS-1 وRS-2 من Googleusercontent وصور RS-3 وRS-4 من Storage: HTTP status وnaturalWidth، في Picker وLoader وReturns.
3. مقارنة النتائج نفسها في Hub وفي التطبيقات الأصلية.
4. تتبع مستندات/حركات كل عملية إلى التبويب الأمومي الصحيح (استلام، حركات مخزون، أذونات، أو سجل تشغيل) وإثبات عدم ازدواج السجلات.
5. إذا ثبتت فجوة في main.html، إعداد Change Set جراحي منفصل وعدم تعديل Core أو DB إلا بعد إثبات الحاجة.

**Readiness:** READY WITH LIMITATIONS — Source + CI + Cloudflare Preview deploy confirmed; Production alias/runtime/images/parent presentation not closed.
