# الخريطة الذهنية لمشروع RAWAEA ERP وتطبيقاته التشغيلية

**رقم الحدث:** LVE-2026-10-25-500  
**التاريخ:** 2026-10-25  
**الغرض:** خريطة وظيفية أولية مبنية على ملفات المستودع التشغيلي `papamohammed77-glitch/erp-frontend`، الفرع `main`، مع فصل الحقائق المؤكدة عن الأدوار المستنتجة.  
**نطاق التغيير:** توثيق فقط داخل مستودع `rawaie-erp-New`. لم يتم تعديل تطبيق تشغيلي أو قاعدة البيانات أو أي Edge Function.

## 1. SELF-AUDIT قبل التقرير

| البند | الحكم | أساس الحكم |
|---|---|---|
| فهم الرؤية العامة | CONFIRMED بدرجة جيدة | README الجذر، وملفات `index.html` و`app.html` و`core.js` |
| فهم هيكل التطبيقات | CONFIRMED جزئيًا | README يحدد تقسيم المجلدات وعددًا تقريبيًا للتطبيقات؛ تم جلب ملفات فعلية من المجلدات المذكورة |
| مطابقة كل ملف في `companies/company-1` | INCOMPLETE | أداة الملفات المتاحة لا تعرض شجرة المجلد كاملة، وبعض أسماء الملفات لم تثبت |
| مطابقة تشغيل Production لكل تطبيق | NOT PERFORMED | المطلوب الحالي خريطة مصدرية؛ لم يُجر اختبار E2E لكل تطبيق |
| صلاحيات كل دور وتفاصيل ACL | NOT CLAIMED | أسماء التطبيقات وأدوارها لا تثبت وحدها صلاحياتها الفعلية |
| أي ادعاء بأن جميع التطبيقات متكاملة 100% | NOT CLAIMED | الخريطة تصف المقصد الوظيفي ومسارات التكامل، لا اعتمادًا نهائيًا لكل مسار |

**قاعدة القراءة:** «مؤكد» يعني أن الاسم/العنوان/الهيكل ظهر في مصدر تمت قراءته. «الدور الوظيفي» يصف الدور الذي يدل عليه عنوان التطبيق وسياق النظام، ولا يعني أن كل قواعد العمل أو الصلاحيات اختُبرت بالكامل.

## 2. الخريطة العليا — Mind Map

```
RAWAEA ERP
│
├── A. النظام الأم ومركز القيادة
│   ├── main.html  → الإدارة المركزية والرقابة وإدارة النظام
│   ├── app.html   → بوابة/موجّه دخول تطبيقات الموظفين
│   ├── index.html → شاشة اختيار: تطبيقات الموظفين أو النظام الأم
│   └── core.js    → النواة المشتركة للمصادقة وملف المستخدم والصلاحيات
│
├── B. البيانات والخدمات المركزية
│   ├── Supabase Auth → هوية جلسة المصادقة
│   ├── public.users / get_my_effective_profile → ملف المستخدم والشركة والصلاحيات الفعالة
│   ├── PostgreSQL + RPCs/Triggers → قواعد البيانات والعقود والمعاملات المركزية
│   ├── Edge Functions → واجهات تنفيذ موثقة بين التطبيق والخدمات الخلفية
│   └── stock_branches / inventory_log / post_stock_movement
│       → الأرصدة وحركات المخزون وفق عقد المخزون الفعلي المعتمد
│
├── C. التطبيقات التشغيلية
│   ├── Sales
│   │   ├── POS → البيع المباشر/نقطة البيع
│   │   ├── Telesales → تسجيل ومتابعة طلبات التلي سيلز
│   │   ├── Order Taker → إدخال الطلبات بواسطة مندوب/ملتقط الطلب
│   │   └── Van Sales → المبيعات الميدانية من مخزون المركبة
│   │
│   ├── Warehouse
│   │   ├── Picker → تجهيز/تحضير الأصناف للرانشيت
│   │   ├── Loader → تحميل الكميات المحضّرة إلى المركبة
│   │   ├── Receiver → استلام البضائع الواردة للمخزن
│   │   ├── Unloader → تفريغ/إرجاع حمولة المركبة إلى المخزن
│   │   ├── Returns → معالجة المرتجعات ضمن عقد المرتجع
│   │   ├── Counter → الجرد/عدّ المخزون
│   │   ├── Vouchers → الأذونات المخزنية
│   │   ├── Supervisor → متابعة وإشراف عمليات المخزن
│   │   └── Manager → متابعة/إدارة عمليات المخزن
│   │
│   ├── Delivery
│   │   └── Driver → تنفيذ دورة التوصيل لدى المندوب
│   │
│   ├── Purchasing
│   │   └── Buyer → عمليات مسؤول المشتريات
│   │
│   └── Store
│       ├── index.html → واجهة المتجر الإلكتروني
│       └── track.html → تتبع الطلب من جهة المتجر
│
└── D. الاستضافة والتشغيل
    ├── GitHub → المصدر وتاريخه
    ├── Cloudflare Pages → استضافة الواجهات وفق توثيق المشروع
    └── PWA / Manifest / Service Worker → تثبيت التطبيق وإدارة موارد الواجهة
```

## 3. مركز القيادة والطبقة المشتركة

### 3.1 `companies/company-1/index.html`
**CONFIRMED:** عنوان الصفحة «الروائع ERP»، وتعرض خيارين واضحين: «تطبيقات الموظفين» عبر `app.html`، و«النظام الأم (مركز القيادة)» عبر `main.html`. هذا يجعلها شاشة اختيار/بوابة، وليس بديلًا عن النظام الأم.

المصدر: [index.html](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/index.html) — blob `ed2bbdf2859e0947453e18e3fd2785977e8e0130`.

### 3.2 `companies/company-1/app.html`
**CONFIRMED:** صفحة دخول الموظفين، وتستخدم Supabase Auth لتسجيل الدخول. وجودها لا يثبت وحده أن جميع الروابط أو سياسات إظهار التطبيقات كاملة؛ ذلك يحتاج قراءة قواعد التوجيه والصلاحيات داخل الملف كاملًا.

المصدر: [app.html](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/app.html) — blob `ec75f89c11620f6e8b8ef5996cf1a3289dcf20b4`.

### 3.3 `companies/company-1/core.js`
**CONFIRMED:** النواة المشتركة تتضمن `RW_Auth`، وتستعيد جلسة Supabase، وتستدعي RPC باسم `get_my_effective_profile` لتحميل ملف المستخدم والشركة والحالة والدور والصلاحيات. كما تُنشئ كائن مستخدم موحدًا يضم `id` و`auth_id` و`company_id` و`permissions` وبيانات نطاق الفرع.

**حد مهم:** وجود هذا المسار في Core لا يثبت أن كل تطبيق يستخدمه على نحو صحيح، ولا يثبت أن كل Edge Function يطبق تفويضًا مطابقًا. يلزم Consumer/ACL tracing مستقل عند تدقيق الصلاحيات.

المصدر: [core.js](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/core.js) — blob `ff2f581d9900543c16f7cb026e13446520c0329d`.

### 3.4 `companies/company-1/main.html`
**CONFIRMED:** الملف موجود في المستودع؛ blob SHA `bb10422217fc57a9a42c2bf65a55e9470a19537c`. لكن أداة جلب الملف أعادت محتوى فارغًا لهذا الملف الكبير، لذلك لا أدّعي أنني قرأت كل أسطره في هذه الدورة، ولا أن هذه الخريطة جرد كامل لتبويباته. يلزم استكمال قراءة مقسّمة/أداة بديلة قبل إصدار خريطة تفصيلية لكل تبويب إداري.

## 4. التطبيقات التشغيلية التي ثبتت ملفاتها

### 4.1 المبيعات — Sales

| الملف | الدور الوظيفي | دليل المصدر |
|---|---|---|
| `sales/pos.html` | نقطة البيع؛ تنفيذ البيع المباشر عبر واجهة POS | عنوان HTML «نقطة البيع»؛ blob `4b34e63747b4b533c663e488049e80a1b81dd537` |
| `sales/telesales.html` | استقبال/إدارة طلبات التلي سيلز | عنوان HTML «التلي سيلز»؛ blob `290a8fdfb6aaaa27cdc1b7c0560f7127efffd647` |
| `sales/order-taker.html` | إدخال الطلبات بواسطة مندوب/ملتقط الطلب | عنوان HTML «مندوب المبيعات»؛ blob `bd4bd542770c774265d06b8adeee70bf6171026b` |
| `sales/van-sales.html` | البيع الميداني من المركبة/مخزون الفان | عنوان HTML «فان سيلز»؛ blob `b754208f38a52b67794e9d02003ed8751f3a7c68` |

README الجذر يذكر أن مجلد Sales يحتوي 6 تطبيقات، لكن هذه الدورة أثبتت 4 ملفات فقط؛ أسماء الملفين الآخرين ودورهما الدقيق **UNKNOWN** هنا، ولا يصح اختراعهما.

### 4.2 المخازن — Warehouse

| الملف | الدور الوظيفي | دليل المصدر |
|---|---|---|
| `warehouse/picker.html` | تحضير الأصناف للرانشيت والتحقق من الكميات قبل التحميل | عنوان HTML «محضّر»؛ blob `d483bd15b36585b975b63c2ef641481a01d5d084` |
| `warehouse/loader.html` | تحميل الأصناف المحضّرة إلى المركبة وربط عملية التحميل بالرانشيت | عنوان HTML «المحمّل»؛ blob `370d666e2ba2a75806d416aeccba85d215f00329` في جلب هذه الدورة |
| `warehouse/receiver.html` | استلام البضائع | عنوان HTML «مسؤول الاستلام»؛ blob `fedab298e5217c82bc07b2a3972e63038ce288d2` |
| `warehouse/unloader.html` | تفريغ الحمولة | عنوان HTML «مسؤول التفريغ»؛ blob `11e80107b7b8ea4ba76e686f1b0f82235b57a303` |
| `warehouse/returns.html` | واجهة المرتجعات | عنوان HTML «المرتجعات»؛ blob `36c20e03c94dc734e015610dec1e8208697df32a` |
| `warehouse/counter.html` | الجرد الذكي/عدّ المخزون | عنوان HTML «الجرد الذكي»؛ blob `938d9b1959705fb2b73cd12fa7b5d9415860b808` |
| `warehouse/vouchers.html` | الأذونات المخزنية | عنوان HTML «الأذونات المخزنية»؛ blob `85e709d0f41c189c6624a6160965d3b1a41960ba` |
| `warehouse/supervisor.html` | إشراف المخازن | عنوان HTML «مشرف المخازن»؛ blob `38efd5eccf83a5540a1fa29689b93beaa75c7adf` |
| `warehouse/manager.html` | إدارة المخازن | عنوان HTML «مدير المخازن»؛ blob `f3fe6fa42e51be6c659b062eed7e6762251add32` |

README يذكر 8 تطبيقات مخازن، بينما الملفات التسعة أعلاه ظهرت في الاستعلامات المباشرة. هذا **تعارض بين عدد README والجرد الجزئي المباشر**، وقد يعني أن README قديم أو أن تعريف العدّ يختلف؛ لا أعدّل README ولا أختار تفسيرًا دون فحص الشجرة كاملة.

### 4.3 التوصيل — Delivery

| الملف | الدور الوظيفي | دليل المصدر |
|---|---|---|
| `delivery/driver.html` | واجهة مندوب التوصيل لتنفيذ دورة التسليم | عنوان HTML «مندوب التوصيل»؛ blob `2df69860184f5a7c1b211ba059e1d6f57826c96b` |

README يذكر تطبيقين في Delivery، لكن الملف الثاني لم يُحدَّد من الأدلة التي جُمعت في هذه الدورة؛ اسمه ودوره **UNKNOWN**.

### 4.4 المشتريات — Purchasing

| الملف | الدور الوظيفي | دليل المصدر |
|---|---|---|
| `purchasing/buyer.html` | واجهة مسؤول المشتريات | عنوان HTML «مسؤول المشتريات»؛ blob `27fe0812faebc218ddfd8454b41e55ef858a0043` |

README يذكر تطبيقين للمشتريات، لكن لم يثبت اسم التطبيق الثاني في هذه الدورة؛ لا يُفترض أنه شاشة استلام أو أوامر شراء دون قراءة الملف الفعلي.

### 4.5 المتجر — Store

| الملف | الدور الوظيفي | دليل المصدر |
|---|---|---|
| `store/index.html` | واجهة المتجر الإلكتروني | عنوان HTML «متجر الروائع»؛ blob `75cca148ade533a3e6d7c73469c7a989c8016644` |
| `store/track.html` | تتبع الطلب باستخدام رقم الطلب أو الهاتف | عنوان HTML «تتبع الطلب»؛ blob `6f1df4012e5b86df5a2912a73bc8f7c8b407b968` |

### 4.6 العمليات المكتبية — Office

README يذكر خمسة تطبيقات مكتبية، لكن لم يتم إثبات أسماء ملفاتها في هذه الدورة. لذلك تبقى **UNKNOWN** بدل إدراج أسماء تخمينية. يجب استخراج شجرة `office/` كاملة، ثم ربط كل ملف بعنوانه وواجهاته واستدعاءاته قبل إكمال هذه الطبقة من الخريطة.

## 5. تدفق العمل التشغيلي الرئيسي

```
إنشاء الطلب
  ├── POS: بيع مباشر
  ├── Telesales: طلب تلي سيلز
  ├── Order Taker: إدخال طلب بواسطة مندوب
  └── Store: طلب إلكتروني
          │
          ▼
النظام الخلفي/عقود الطلبات
          │
          ▼
تجميع الطلبات في Runsheet
          │
          ▼
Picker — تحضير الأصناف والكميات
          │
          ▼
Loader — تحميل ما تم تحضيره إلى المركبة
          │
          ▼
Driver — التوصيل وتسجيل نتيجة كل طلب
          │
          ├── تسليم ناجح
          ├── رفض/تسليم جزئي وفق ما يدعمه العقد
          └── مرتجع/تسوية عند انطباق المسار
          │
          ▼
Core / PostgreSQL / Inventory + Ledger
```

هذا مخطط مفاهيمي لدورة الأعمال، وليس إثباتًا بأن كل مصدر طلب يسلك المسار نفسه أو أن كل حالة جزئية مفعلة في Production. يجب إثبات انتقالات الحالات الفعلية من كل Consumer وعقد Edge/RPC.

## 6. عقد التكامل الذي يجب الحفاظ عليه

1. **النظام الأم هو مركز الإدارة والرقابة**؛ التطبيقات التشغيلية تنفذ مهامها المحددة ولا تُنشئ سياسات متعارضة مستقلة.
2. **Core مشترك لا يعني تفويضًا تلقائيًا:** كل تطبيق يجب أن يحمّل ملف المستخدم والشركة والصلاحيات، وكل Backend endpoint يجب أن يتحقق من الهوية والصلاحية ونطاق الشركة على الخادم.
3. **الطلب والرانشيت والمخزون كيانات مترابطة:** تغيير حالة UI وحده لا يثبت اكتمال الأثر التشغيلي.
4. **Physical stock movement لا يُنشأ من واجهة التطبيق مباشرةً** إذا كان عقد النظام يفرض المحرك المركزي؛ يجب تتبع الاستدعاء حتى RPC/DB وإثباته.
5. **الحجز ليس حركة فعلية:** `allocated_qty` و`qty` يمثلان معنيين مختلفين، ولا يجوز دمجهما في تعديل واجهة.
6. **المركبة ليست مندوبًا:** هوية Vehicle/Van ومخزونها يجب أن تبقى منفصلة عن هوية Representative/Driver.
7. **الخصوصية متعددة الشركات:** يجب أن يحمل كل Consumer نطاق الشركة والفرع من هوية موثوقة، لا من اختيار واجهة غير موثوق أو `app_settings.limit(1)`.
8. **التقارير السابقة ليست دليل Runtime:** يجب مطابقة Git الحالي مع Production وسجلات التشغيل عندما يكون الادعاء متعلقًا بالنشر أو السلوك الفعلي.

## 7. الأدلة والمراجع المباشرة

- [المستودع التشغيلي — مجلد الشركة](https://github.com/papamohammed77-glitch/erp-frontend/tree/main/companies/company-1)
- [README.md](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/README.md)
- [index.html](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/index.html)
- [app.html](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/app.html)
- [core.js](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/core.js)
- [Picker](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/warehouse/picker.html)
- [Loader](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/warehouse/loader.html)
- [Delivery Driver](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/delivery/driver.html)
- [Buyer](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/purchasing/buyer.html)
- [Store](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/store/index.html)
- [Store Order Tracking](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/store/track.html)

## 8. Outstanding Gap Register

| الفجوة | التصنيف | الإجراء التالي |
|---|---|---|
| قراءة محتوى `main.html` كاملًا | UNKNOWN/UNVERIFIED | استكمال القراءة بأداة تدعم الملف الكبير/نطاقات قابلة للتحقق |
| جرد شجرة `companies/company-1` بالكامل | OPEN | الحصول على tree listing موثوق لكل الملفات والمجلدات |
| ملفات Sales المتبقية | UNKNOWN | تحديدها من الشجرة ثم قراءة عناوينها ومساراتها |
| ملف Delivery الثاني | UNKNOWN | تحديده من الشجرة ثم فحصه |
| ملف Purchasing الثاني | UNKNOWN | تحديده من الشجرة ثم فحصه |
| تطبيقات Office الخمسة | UNKNOWN | استخراج أسماء الملفات وقراءة كل تطبيق |
| اختلاف عدد Warehouse في README (8) عن الملفات التسعة التي ظهرت | CONFLICT | حسمه من شجرة Git الكاملة وتاريخ README |
| خرائط Consumers لكل تطبيق إلى Edge/RPC/DB | OPEN | مسح الاستدعاءات في كل ملف ثم مطابقتها بعقود الخدمات |
| صلاحيات كل تطبيق على Production | NOT VERIFIED | مراجعة RLS/ACL والتحقق من هوية المستخدم ونطاق الشركة لكل مسار |
| Production Runtime لكل تطبيق | NOT TESTED | اختبارات HTTP/E2E منفصلة ببيانات معزولة وخطة استعادة baseline |

## 9. الحكم التنفيذي

الخريطة الحالية مفيدة لفهم التقسيم الوظيفي العام، وتثبت وجود نواة مشتركة وبوابة موظفين وتطبيقات تشغيلية منفصلة ضمن المستودع. لكنها **ليست جردًا كاملًا لكل الملفات ولا شهادة بأن كل الوظائف أو الصلاحيات أو مسارات الإنتاج مكتملة**.

لم تُجرَ أي تغييرات في `erp-frontend` أو Supabase خلال هذه المهمة. هذا التقرير توثيقي فقط. لا يجوز اعتبار فجوات الملفات المجهولة «غير موجودة»؛ حالتها UNKNOWN حتى تُستخرج الشجرة الكاملة وتُقرأ الملفات.

## 10. SELF-AUDIT FINAL

- **What I Proved:** وجود بوابة اختيار، وتطبيق دخول موظفين، وCore مشترك للمصادقة/الملف الفعال، والملفات التشغيلية المسماة في الجداول أعلاه وعناوينها.
- **What I Did Not Prove:** محتوى `main.html` كاملًا، جميع ملفات الشركة، جميع المستهلكين، صلاحيات كل تطبيق، وتطابق كل سلوك مع Production Runtime.
- **What I Fixed:** لا إصلاحات تشغيلية؛ أعددت خريطة توثيقية فقط.
- **What I Initially Missed:** اختلاف عدد تطبيقات Warehouse بين README والجرد المباشر الجزئي؛ عُرض صراحةً كـCONFLICT بدل تسويته بالتخمين.
- **What Could Still Be Wrong:** أسماء أو أدوار التطبيقات التي لم تُقرأ، وتدفقات الأعمال التي تختلف حسب نوع الطلب أو صلاحيات الشركة/الفرع.
- **Final Confidence:** مرتفعة في الملفات والعناوين المثبتة؛ متوسطة في الرسم الوظيفي المفاهيمي؛ منخفضة/غير محسومة في اكتمال الجرد الكلي.
- **Final Closure Status:** DOCUMENTATION DELIVERED / GLOBAL FILE INVENTORY OPEN / NOT A PRODUCTION-CLOSURE CLAIM.
