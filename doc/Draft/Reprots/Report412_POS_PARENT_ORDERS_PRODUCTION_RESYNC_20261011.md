# Report412 — إعادة مزامنة Production وتدقيق تكامل مرتجعات POS مع النظام الأم
**التاريخ:** 2026-10-11  
**النطاق:** إعادة فحص الحقيقة الحالية قبل أي تعديل، والتحقق من استمرار عيوب عرض مرتجعات POS في تبويب أوردرات المبيعات بالنظام الأم.  
**المستودعات:** `papamohammed77-glitch/rawaie-erp-New` و`papamohammed77-glitch/erp-frontend`  
**Supabase Production:** `fiilmooggumokxanwiyx`

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** يجب الاحتفاظ بكميات البيع الأصلية للتدقيق، وعرض المرتجع والمتبقي بصورة صحيحة، وأن يتطابق عدد الأصناف المعروضة وإجمالي الأوردر مع الحالة النهائية في قاعدة البيانات.
- **Architecture Understanding:** POS تطبيق مستقل، والنظام الأم مستهلك لبيانات `orders/order_details`. إصلاح العرض والتزامن لا يبرر إنشاء Edge Function أو تعديل Core ما دامت البيانات وعقد القراءة صحيحين.
- **Database Understanding:** أعيد الاستعلام من Production مباشرة عن `ORD-1006` وعن أعمدة العقد المعنية.
- **Historical Understanding:** تمت مراجعة `CURRENT_STATE.md` وReport408 وReport411؛ عوملت التقارير كدلائل تاريخية فقط وأعيد التحقق من Production وGit في هذه الدورة.
- **Production Understanding:** الاستعلام المباشر في هذه الدورة أكد أن `ORD-1006` حالتها `Partially Returned`، والإجمالي الحالي 135.00 مقابل أصلي 185.00، وسطران، والكمية الأصلية 2 والمرتجعة 1 والمتبقية 1.
- **Current Understanding:** snapshot `rawaie-erp-New/Current/PWA/main.html` عند blob `27b777528665dcc985809648f006452c861ae36e` ما زال يحتوي على عدّ تفاصيل دون `qty_returned`، وتحديث Realtime لكائن الرأس فقط، وعرض تفاصيل بالقيم الأصلية. الملف الحي `erp-frontend/companies/company-1/main.html` أعاد محتوى فارغًا عبر GitHub connector رغم طلب نطاق أسطر؛ SHA المرصود `4f94f9c6ebdde1b59632384628c72767d3bb950d`.
- **Execution Confidence:** مرتفع في حقائق Production وعقد البيانات؛ غير كافٍ لإثبات تطابق نص الملف الأم الحي مع snapshot أو النشر الفعلي.

### Evidence captured this cycle

وقت استعلام Production: `2026-10-11 14:53:52.674996+00`.

| العنصر | النتيجة الحية |
|---|---|
| Order | `ORD-1006` |
| source / created_by | `pos` / `cashier@rawaea.com` |
| order_status | `Partially Returned` |
| total_amount / original_total_amount | `135.00 / 185.00` |
| company_id | `00000000-0000-0000-0000-000000000001` |
| branch_id | `a38332b6-6cea-480a-ada1-6eb6ab0590db` |
| detail_rows | 2 |
| original / returned / remaining quantity sums | 2 / 1 / 1 |

- أعمدة `orders` و`order_details` اللازمة للعرض موجودة وفق `information_schema.columns`.
- لم يُنفّذ تغيير SQL أو RPC أو ACL أو Edge أو بيانات أعمال.
- لم تُنشأ بيانات اختبار في Production؛ استخدام فاتورة حقيقية لاختبار mutation غير آمن.
- المصدر المنفصل POS في Git يتضمن بالفعل إصلاح عرض المرتجع في commit `12e68f21eca5be19beb7e9b678a1917dc1d40d71`، وblob `0160f7cf9c4f194d954d2c7498d91fc639a5f419`. لا يثبت ذلك أن الاستضافة تقدم هذا الـartifact أو أن Browser E2E اجتاز.
- قائمة Edge الحالية أعادت `complete-return v26` و`save-sales-invoice v18` كـACTIVE مع `verify_jwt=true`؛ لا يوجد دليل جديد يبرر نشر Edge آخر لهذه المشكلة.

## Root cause confirmed in the available main snapshot

1. `RW_Orders.loadData()` يقرأ `order_id,item_code` فقط ويعد كل التفاصيل؛ لا يستخدم `qty_returned` لاستبعاد السطر الذي لا توجد له كمية متبقية.
2. `refreshRealtimeChannel()` يحدّث كائن رأس الأوردر في الذاكرة، لكنه لا يعيد تحميل التفاصيل ولا يعيد حساب `itemsCount`.
3. `_showDetails(code)` في snapshot يعرض الكمية وقيمة السطر الأصليتين ويشتق الإجمالي بدل الاعتماد على `orders.total_amount` كالإجمالي النهائي المسجل.
4. جدول الأوردرات في snapshot لا يعرض `source` و`created_by`.
5. توحيد الطباعة مع حالة المرتجع لم يثبت بعد.

## Surgical owner changeset — لا تعديل مباشر على main.html أو pos.html

الملف الحي الحساس: `erp-frontend/companies/company-1/main.html`. يجب على المالك دمج التعديلات يدويًا بعد فتح النص الحي ومقارنته؛ لا يجوز استبدال دوال من snapshot دون مطابقة.

**المرجع التنفيذي الكامل:** [Report411 — التعديلات الجراحية للنظام الأم](Report411_POS_RETURN_PARENT_ORDERS_INTEGRATION_20261011.md)، ويحتوي النص الكامل للاستبدال. وللدالة الكاملة `_showDetails(code))، راجع [Report408 — Owner Changeset](Report408_POS_RETURN_STATE_DETAILS_AND_OWNER_CHANGESET_20261011.md).

التغييرات المحددة:
1. استبدال `RW_Orders.loadData()` بحيث يجلب `qty_returned` ويحسب فقط سطور الأصناف ذات `qty - qty_returned > 0`.
2. استبدال `RW_Orders.refreshRealtimeChannel()` بحيث يعيد تحميل بيانات الشركة عبر `_refreshData()` عند تغير رأس الأوردر؛ لا تضف اشتراكًا غير مقيّد على تفاصيل الأوردر.
3. إضافة عمودي المصدر والمنشئ إلى رأس الجدول، مع زيادة `colspan` في حالات التحميل والخطأ من 9 إلى 11 في هذا الجدول فقط.
4. استبدال `RW_Orders._renderTable(rows)` بنسخة Report411 التي تعرض المصدر والمنشئ وتُبقي إجراءات الأوردر الحالية.
5. استبدال `RW_Orders._showDetails(code)` بنسخة Report408 التي تعرض الأصلي/المرتجع/المتبقي وتستخدم `orders.total_amount` للإجمالي النهائي.
6. مراجعة الطباعة وتوحيد عرض الكميات المرتجعة والمتبقية؛ هذه نقطة مفتوحة صريحة وليست إصلاحًا منجزًا.

### اختبار بعد الدمج والنشر

- قراءة فقط: `ORD-1006` يجب أن يظهر مصدره «كاشير»، منشئه `cashier@rawaea.com`، وعدد الأصناف المتبقية 1، والإجمالي النهائي 135.00 EGP.
- التفاصيل: السطر المرتجع يعرض أصلي 1 / مرتجع 1 / متبقي 0؛ والسطر الآخر أصلي 1 / مرتجع 0 / متبقي 1.
- اختبار Realtime يتطلب fixture معزولًا في Staging أو بيئة اختبار؛ لا تنفذ مرتجعًا جديدًا على `ORD-1006`.
- اختبر الفلاتر والفرز والتحديد وإنشاء/ضم الرانشيت والتأكيد والحذف للأوردرات المؤهلة، والطباعة، وCompany Isolation.
- بعد النشر، تحقق من SHA المنشور وService Worker وConsole/Network ثم أعد قراءة Production وتأكد من عدم وجود test residue.

## ما نُفّذ في هذه الدورة

- أُعيدت قراءة Production الحالية وبيانات `ORD-1006` وحقول الجداول.
- أُعيد فحص snapshot الحالي في Git، وملف POS المصدر، وقائمة Edge Functions.
- لم يتم تغيير أي بيانات أعمال أو مخزون أو محاسبة، ولم يتم تغيير Production SQL/Edge.
- لم يتم تعديل `main.html` أو `pos.html` احترامًا لقاعدة المالك الخاصة بالملفين الحساسين.
- لم يُدّعَ نشر واجهة أو نجاح Browser/HTTP E2E؛ هذه الأدلة غير متاحة في هذه الدورة.

## SELF-AUDIT FINAL

- **What I Proved:** حقيقة Production الحالية للفاتورة، وجود الحقول المطلوبة، ووجود عيوب العرض في snapshot المحدد.
- **What I Did Not Prove:** نص الملف الأم الحي، تطابقه مع snapshot، نشر الواجهة، Browser/HTTP E2E، واتساق الطباعة.
- **What I Fixed:** لا تغيير كود أو بيانات في Production؛ تم تثبيت أحدث نتيجة تدقيق وخطوات الدمج الدقيقة في هذا التقرير.
- **What I Initially Missed:** يلزم تعديل `colspan` مع إضافة عمودين، وإصلاح Realtime وحده لا يكفي دون إعادة حساب التفاصيل المشتقة.
- **What Could Still Be Wrong:** اختلاف الملف الحي عن snapshot، أو عدم نشر commit POS، أو وجود cache/Service Worker قديم، أو استمرار اختلاف الطباعة.
- **Final Confidence:** مرتفع في قراءة Production؛ متوسط في انطباق changeset على الملف الحي؛ غير مثبت في النشر وE2E.
- **Final Closure Status:** `PRODUCTION DATA VERIFIED / OWNER PATCH SPECIFIED / LIVE MAIN SOURCE PARITY UNVERIFIED / DEPLOYMENT + BROWSER E2E + PRINT OPEN / NOT CLOSED`.
- **Next exact step:** يفتح المالك `erp-frontend/companies/company-1/main.html` من محرر المصدر المنشور، يطابق SHA والتوقيعات الفعلية، ثم يدمج فقط التغييرات 1–6 أعلاه، وينشر عبر المسار المعتمد ويثبت Browser E2E قبل إغلاق الوحدة.
