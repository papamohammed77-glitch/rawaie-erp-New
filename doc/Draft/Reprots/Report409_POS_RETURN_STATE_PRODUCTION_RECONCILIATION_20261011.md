# Report409 — تحقيق إنتاجي لتناسق مرتجعات POS وتفاصيل أوردرات النظام الأم
**التاريخ:** 2026-10-11  
**النطاق الحصري:** تفاصيل فاتورة POS بعد المرتجع، وعدد الأصناف وتفاصيل الأوردر في النظام الأم.  
**Production project:** `fiilmooggumokxanwiyx`  
**قاعدة التنفيذ:** لم أعدّل `main.html` أو `pos.html` أو بيانات الأعمال؛ مسؤولية نشر ملفات الواجهة محفوظة للمالك حسب توجيه المهمة.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** المرتجع يخفض الكمية القابلة للبيع والقيمة النهائية، لكنه لا يمحو سطر البيع الأصلي من سجل التدقيق. واجهة التشغيل يجب أن تعرض الأصلي والمرتجع والمتبقي، مع استخدام إجمالي الأوردر المركزي الحالي.
- **Architecture Understanding:** POS يقرأ الفواتير والتفاصيل عبر `public.get_pos_invoice_data(text,text)`. تنفيذ المرتجع في Production يمر عبر Edge Function `complete-return` ثم `complete_sales_return_credit_note_atomic` / `complete_return_atomic`؛ حركة المخزون تتم داخل الـCore. النظام الأم يعرض `orders` و`order_details` عبر `RW_Orders`.
- **Database Understanding:** Production يحتوي `orders.total_amount`, `orders.original_total_amount`, وحقول `order_details.qty`, `qty_returned`, `reason_return`, `notes`, `line_amount`. لا يوجد دليل يبرر تعديل `qty` الأصلية عند المرتجع.
- **Historical Understanding:** راجعت `CURRENT_STATE.md` وReport407 وReport408، ثم قارنتها بالمصدر الحالي وProduction. عوملت التقارير كقرائن لا كبديل عن التحقق الحي.
- **Production Understanding:** تمت قراءة تعريف RPC الحي، ACL، تعريفات Edge Functions الحية، أعمدة قاعدة البيانات، migrations المسجلة، وبيانات الفاتورة التجريبية الموجودة أصلًا `ORD-1006`.
- **Current Understanding:** آخر commit لملف POS هو `12e68f21eca5be19beb7e9b678a1917dc1d40d71`، وblob `0160f7cf9c4f194d954d2c7498d91fc639a5f419`. ملف النظام الأم الحي `erp-frontend/companies/company-1/main.html` له blob `4f94f9c6ebdde1b59632384628c72767d3bb950d`، لكن GitHub connector أعاد محتوى فارغًا حتى مع طلب نطاقات أسطر وbase64؛ لذلك لم أتعامل مع snapshot تاريخي باعتباره مطابقًا للملف الحي.
- **Execution Confidence:** مرتفع بشأن صحة عقد بيانات Production وسبب الخلل في العرض بحسب snapshot المتاح؛ متوسط بشأن تطابق تفاصيل وظائف النظام الأم المرجعية مع الملف الحي؛ لا توجد أدلة Browser/HTTP E2E أو نشر واجهة تسمح بإغلاق تجربة المستخدم.

### مصادر الفحص
- Historical/current state: `rawaie-erp-New/CURRENT_STATE.md`.
- POS live source: `erp-frontend/companies/company-1/sales/pos.html`.
- POS source commit: [12e68f21](https://github.com/papamohammed77-glitch/erp-frontend/commit/12e68f21eca5be19beb7e9b678a1917dc1d40d71).
- Main app live blob: `4f94f9c6ebdde1b59632384628c72767d3bb950d` (المحتوى لم يرجع من أداة القراءة؛ لا أدّعي قراءة النص الكامل).
- Main snapshot used only as reference: `rawaie-erp-New/Current/PWA/main.html`, blob `27b777528665dcc985809648f006452c861ae36e`.
- Prior complete owner changeset: [Report408](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report408_POS_RETURN_STATE_DETAILS_AND_OWNER_CHANGESET_20261011.md).
- Current POS read RPC migration: `supabase/migrations/20261010_pos_authenticated_invoice_read_rpc.sql`.
- Production suffix-resolution migration: `supabase/migrations/20261011_pos_invoice_lookup_numeric_suffix.sql`, commit [0296c0d](https://github.com/papamohammed77-glitch/rawaie-erp-New/commit/0296c0d2d331c1a09e9e60694d6933a1b225c923).
- Production migration registry confirms:
  - `20261011075858 / pos_cash_return_refund_atomic`
  - `20261011080138 / pos_return_zero_value_guard`
  - `20261011080435 / pos_return_remaining_total_discount`
  - `20261011080529 / pos_return_cost_accounting`
  - `20261011085921 / pos_invoice_lookup_numeric_suffix_20261011`

## 1. نتيجة التحقيق في Production

### 1.1 حالة فعلية مثبتة
استعلام Production للفاتورة `ORD-1006` أعاد:

| الحقل | القيمة الحية |
|---|---:|
| `order_status` | `Partially Returned` |
| `total_amount` | 135.00 |
| `original_total_amount` | 185.00 |
| عدد سطور التفاصيل الأصلية | 2 |
| مجموع `qty` الأصلي | 2 |
| مجموع `qty_returned` | 1 |
| مجموع الكمية المتبقية | 1 |
| `remaining_gross` المحسوب من `qty - qty_returned` | 135.00 |

والتفاصيل الحية:

- الصنف `1001 / جو كيك 5ج`: `qty=1`, `qty_returned=1`, `line_amount=50.00`, `reason_return=مرتجع نقطة بيع`.
- الصنف `1003 / شيبس تايجر طعوم 10ج`: `qty=1`, `qty_returned=0`, `line_amount=135.00`.

**الاستنتاج:** قاعدة البيانات تحتفظ بسطر البيع الأصلي عمدًا وتفصل عنه الكمية المرتجعة؛ وهي ليست مطالبة بأن تحذف الصنف أو تغير `qty` الأصلية. العيب في المستهلك الذي يعرض `qty` و`line_amount` الأصليين دون حساب المتبقي، أو يعيد اشتقاق إجمالي الأوردر من السطور الأصلية.

### 1.2 RPC والصلاحيات
تم فحص `public.get_pos_invoice_data(text,text)` مباشرة من Production:

- `SECURITY DEFINER = true`، و`search_path` فارغ.
- `anon EXECUTE = false`.
- `authenticated EXECUTE = true`.
- `service_role EXECUTE = true`.
- يفرض المستخدم المصادق عليه، صلاحية POS، سياق الشركة، الفروع المسموحة، ومصدر `pos`.
- التفاصيل تعيد `qty`, `qty_delivered`, `qty_returned`, و`line_amount`.
- تم التحقق من أن migration `20261011_pos_invoice_lookup_numeric_suffix.sql` موجودة في Git ومسجلة في Production؛ إذن دعم البحث برقم الفاتورة المختصر ليس تعديلًا غير موثق في Production.

تم فحص Edge `complete-return` المنشورة: **v26**، و`save-sales-invoice`: **v18**. لا يوجد دليل في نتائج هذا التحقيق يبرر إعادة نشر أي منهما لإصلاح مشكلة العرض الحالية.

## 2. السبب الجذري

### POS
الـcommit `12e68f21eca5be19beb7e9b678a1917dc1d40d71` عدّل `self._viewActiveInvoice` ليعرض:
- الكمية الأصلية.
- الكمية المرتجعة.
- الكمية المتبقية.
- قيمة المتبقي.
- ملاحظة `مرتجع جزئي` أو `مرتجع بالكامل`.
- الإجمالي النهائي من `order.total_amount`.

التغيير موجود في Git، لكنه **ليس دليلًا على نشره إلى الاستضافة أو اجتياز Browser E2E**. لا تكرر هذا التعديل ولا تعدّل الملف نيابةً عن المالك.

**حد مهم:** الملاحظة في التغيير الحالي تصف حالة المرتجع (جزئي/كامل)، وليست بالضرورة نص `reason_return` الفعلي. إذا كان المطلوب إظهار سبب المرتجع المسجل حرفيًا، فيلزم تعديل RPC لتعيد `reason_return` ثم ربطه بالواجهة؛ هذا تحسين إضافي وليس سبب التناقض الأساسي.

### النظام الأم
في snapshot المرجعي `Current/PWA/main.html`:
- `RW_Orders.loadData()` يحسب كل سطر في `order_details` ضمن عدد الأصناف، حتى إن أصبح `qty - qty_returned = 0`.
- `RW_Orders._showDetails(code)` يعرض الكمية وقيمة السطر الأصليتين ويعيد اشتقاق الإجمالي من السطور ورسوم التوصيل بدل الاعتماد على `orders.total_amount` النهائي.

هذا يفسر التناقض الذي وصفه المالك، لكن **لا أزعم أن هذه هي نصوص الوظائف الحية حرفيًا** لأن أداة GitHub أعادت محتوى فارغًا للملف الحي. لا تُستبدل وظائف الملف الحي اعتمادًا على snapshot فقط.

## 3. الإصلاحات والقرارات

| الطبقة | القرار | الدليل/السبب |
|---|---|---|
| Production data | **لا تعديل** | `qty_returned` والحالة والإجمالي النهائي متسقة في `ORD-1006`; تعديل `qty` الأصلية يفسد التدقيق |
| PostgreSQL return core | **لا تعديل جديد** | Production يعكس حالة مرتجع فعلية؛ لم يثبت عيب في عقد البيانات يسبب عرض السطور الأصلية |
| POS source | **الإصلاح موجود في Git** | commit `12e68f21...`; النشر وBrowser E2E غير مثبتين |
| Main app source | **Owner-side change مطلوب** | الملف الحي لا يمكن قراءة نصه عبر الموصل في هذه الدورة، وتعليمات المالك تمنعني من تعديله |
| Migrations / provenance | **تمت المطابقة** | migration البحث بالرقم المختصر موجودة في Git ومسجلة في Production |

لم أضف migration أو RPC أو Edge Function جديدة؛ لأن ذلك لن يصلح من تلقاء نفسه طريقة حساب الواجهة التي تقرأ الجداول مباشرة، وسيكون تغييرًا غير مستخدم بلا Consumer مثبت.

## 4. إجراء المالك الدقيق — النظام الأم

افتح الملف الحي:
`erp-frontend/companies/company-1/main.html`

داخل كائن `RW_Orders` ابحث عن التعريفين:
1. `async function loadData()`
2. `async function _showDetails(code)`

**لا تستبدلهما قبل مقارنة النص الحي كاملًا** مع المرجع. بعد التحقق من النص الحي، استخدم بديلَي الدالتين الكاملين الموجودين في قسم **OWNER CHANGESET** داخل Report408، مع هذه العقود الإلزامية:

- في `loadData()`: احتساب عدد سطور الأصناف المتبقية فقط عندما `max(0, qty - qty_returned) > 0`. لا تغيّر `qty` ولا تحذف سطورًا.
- في `_showDetails(code)`: عرض الأصلي والمرتجع والمتبقي والملاحظة؛ استخدام `orders.total_amount` للإجمالي النهائي المسجل؛ لا تستنتج رأس الفاتورة من `line_amount` الأصلي.
- إذا اختلفت الدالة الحية عن snapshot في المدخلات أو أزرار التأكيد/الحذف/الطباعة أو التبعيات، فادمج منطق المرتجع جراحيًا داخل النص الحي بدل استبدال الدالة بلا مقارنة.
- افحص `_printOrder` / `_buildPrintWindow` بعد ذلك لضمان أن الطباعة لا تعرض الإجمالي/الكميات القديمة. لم أغيّر الطباعة دون قراءة نصها الحي.
- بعد الدمج، انشر من مسار النشر المعتاد، ثم اختبر الفاتورة العادية والمرتجع الجزئي والكامل في الجدول والمودال والطباعة.

## 5. اختبارات مطلوبة قبل الإغلاق

- [x] Production data read-only: حالة جزئية، إجمالي نهائي، كميات أصلية ومرتجعة ومتبيقة.
- [x] تعريف RPC الحي وACL.
- [x] تحقق سجل migrations لآخر إصلاح بحث الفاتورة.
- [x] فحص commit تعديل POS وتحديد الـblob.
- [ ] نشر POS source إلى الاستضافة.
- [ ] Browser/HTTP E2E حقيقي بعد النشر.
- [ ] دمج تعديل النظام الأم بعد مقارنة الملف الحي.
- [ ] تحقق جدول الأوردرات ومودال التفاصيل والطباعة.
- [ ] اختبار company/branch isolation من الواجهة.
- [ ] إعادة فحص Production بعد النشر وتسجيل artifact المنشور.

## SELF-AUDIT FINAL

- **What I Proved:** Production يحفظ `qty` الأصلية و`qty_returned` منفصلة؛ `ORD-1006` حالتها `Partially Returned` وإجماليها النهائي 135 مقابل 185 أصليًا؛ RPC تعيد بيانات المرتجع اللازمة لعرض الكمية المتبقية؛ صلاحيات RPC مقيدة؛ migration البحث بالرقم المختصر مسجلة في Production.
- **What I Did Not Prove:** أن commit POS منشور فعليًا؛ Browser/HTTP E2E؛ النص الكامل للـ`main.html` الحي؛ أن snapshot النظام الأم مطابق للملف الحي؛ اتساق الطباعة بعد الإصلاح.
- **What I Fixed:** لم أغيّر قاعدة البيانات لأن العيب المثبت في حسابات العرض وليس في حفظ الكميات؛ وثّقت بدقة ما يلزم للمالك دون لمس ملفات الواجهة.
- **What I Initially Missed:** وجود migration مستقلة `20261011_pos_invoice_lookup_numeric_suffix.sql` التي تفسر الفرق بين تعريف RPC الحالي والنسخة الأقدم من migration.
- **What Could Still Be Wrong:** قد يحتوي `main.html` الحي على اختلافات في `RW_Orders` أو التبعيات؛ وقد تكون نسخة POS المنشورة أقدم من Git. يلزم إثبات ذلك من المصدر المنشور والمتصفح.
- **Final Confidence:** مرتفع في تشخيص سبب تناقض عرض المرتجع؛ متوسط في مطابقة وظائف النظام الأم بسبب تعذر قراءة الملف الحي؛ منخفض/غير مثبت في النشر وE2E.
- **Final Closure Status:** `DATABASE CONTRACT VERIFIED / POS FIX COMMITTED BUT DEPLOYMENT UNVERIFIED / MAIN OWNER PATCH PENDING / NOT CLOSED`.

**قاعدة الجلسة التالية:** ابدأ بقراءة Production وGit في نفس الدورة. لا تغيّر `qty` الأصلية، ولا تعاود نشر Edge/RPC دون عيب مثبت. أتمم دمج `RW_Orders` داخل النص الحي أولًا، ثم انشر واختبر المتصفح والطباعة، وبعدها حدّث هذا الملف و`CURRENT_STATE.md`.
