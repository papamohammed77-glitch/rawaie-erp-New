# Report416 — إعادة مزامنة Production وتحديد مواضع التعديل الجراحي لجدول أوردرات المبيعات
**وقت الفحص:** 2026-10-11 16:24 UTC  
**النطاق:** جدول أوردرات المبيعات داخل `RW_Orders` في الملف الأم `erp-frontend/companies/company-1/main.html`.  
**سياسة التعديل:** لم يُعدّل `main.html` ولا أي تطبيق تشغيلي. لم يُنفّذ أي تغيير في Production لأن فحص Core الحي لم يثبت حاجة إلى تغيير جديد.

## 1. SELF-AUDIT
- **Business:** يجب أن يعرض الجدول حالة الأوردر الحالية بعد المرتجع، مع الاحتفاظ بالكمية الأصلية/المرتجعة لأغراض التدقيق، وألا يتيح ضم أوردر POS إلى الرانشيت.
- **Architecture:** واجهة النظام الأم تُدمج من المالك؛ ضمان أهلية الرانشيت في Production RPC وليس في checkbox وحده.
- **Database/Production:** أُعيدت قراءة Production مباشرة في هذه الدورة، لا اعتمادًا على Report415 فقط.
- **Current source:** موصل GitHub أعاد للملف الأم SHA `4f94f9c6ebdde1b59632384628c72767d3bb950d` ومحتوى فارغًا حتى في القراءة المباشرة؛ لذلك لم أستطع إثبات نص الملف الحي أو أرقام أسطره.
- **Historical/snapshot:** تمت قراءة snapshot `rawaie-erp-New/Current/PWA/main.html`، blob `27b777528665dcc985809648f006452c861ae36e`، وعدد أسطره 5,410. أرقام الأسطر التالية تخص هذا الـsnapshot فقط، ولا يجوز إسقاطها على الملف الحي دون مطابقة النص.
- **Execution confidence:** مرتفع في Production data/RPC/RLS؛ غير مثبت في تطابق snapshot مع الملف الأم الحي أو نشر الواجهة وBrowser E2E.

## 2. Production — قراءة جديدة مثبتة
وقت الاستعلام عن رأس الأوردر: `2026-10-11 16:24:40.303032+00`.  
وقت قراءة التفاصيل: `2026-10-11 16:24:45.851205+00`.  
وقت قراءة RLS: `2026-10-11 16:24:53.670833+00`.

| الحقل | القيمة الحية |
|---|---|
| order_code | `ORD-1006` |
| source / created_by | `pos` / `cashier@rawaea.com` |
| created_at | `2026-10-11 07:31:00.768458+00` |
| order_status | `Partially Returned` |
| total_amount / original_total_amount | `135.00 / 185.00` |
| runsheet_id | `NULL` |
| detail rows | 2 |
| remaining quantity | 1 |

تفاصيل السطور: item `1001` qty=1, qty_returned=1, reason=`مرتجع نقطة بيع`; item `1003` qty=1, qty_returned=0. لم تتغير أي بيانات أعمال.

### Production Core / ACL
أُعيدت قراءة التعريف الحي لـ:
- `public.create_runsheet_atomic(uuid,text[],text)`
- `public.append_orders_to_runsheet_atomic(uuid,text,text[],text)`

كلاهما يرفض المصدر خارج `telesales / tele-sales / order-taker / online-store` بعد التطبيع، وبالتالي يرفض `pos` والمصدر الفارغ/المجهول. ACL لكليهما: `anon=false`, `authenticated=false`, `service_role=true`. لا يوجد سبب مثبت لإعادة تعديل RPC أو ACL في هذه الدورة.

سياسة `users_select_company` تسمح بقراءة مستخدمي الشركة لمن يملك صلاحية `users`، أو قراءة المستخدم لسجله. لذلك يجب ألا يعتمد الجدول على اسم المنشئ وحده؛ اعرض `created_by` كـfallback ولا توسّع RLS من أجل العرض.

## 3. خريطة الوصول الجراحي — أرقام snapshot وليست أرقام الملف الحي
المصدر: `Current/PWA/main.html` blob `27b777528665dcc985809648f006452c861ae36e`.

| العنصر | سطر snapshot | الإجراء المطلوب |
|---|---:|---|
| `var ordersData = [];` | 2332 | إضافة helpers مرة واحدة فقط بعده؛ النص الكامل في Report413 §3-A. |
| `async function loadData()` | 2334 | استبدال الدالة كاملة بالنص في Report413 §3-B؛ احتساب السطور ذات الكمية المتبقية فقط، وfallback للمنشئ. |
| `async function refreshRealtimeChannel()` | 2352 | استبدال الدالة المطابقة وفق Report413 §3-C لإعادة تحميل البيانات المشتقة داخل الشركة الحالية. |
| `id="check-all"` | 2394 | تغيير selector إلى `.order-checkbox:not(:disabled)` داخل هذا المعالج فقط. |
| رأس عمود التاريخ | 2396 | استبدال `order_date` بـ`created_at` وعنوان «تاريخ ووقت الإنشاء». |
| رأس «العميل والمنطقة» | 2397 | إضافة عمودي المصدر والمنشئ بعده مباشرة وفق Report413 §3-D. |
| `function _renderTable(rows)` | 2428 | استبدال الدالة المطابقة وفق Report413 §3-E؛ عدد الأعمدة يصبح 11 وتعطيل اختيار المصدر غير المؤهل. |
| `function _validateSelected(selected)` | 2443 | استبدال الدالة المطابقة وفق Report413 §3-F مع فحص الشركة/المصدر/الحالة/الارتباط. |
| `async function _showDetails(code)` | 2450 | إصلاح عرض الأصلي/المرتجع/المتبقي والإجمالي النهائي؛ المرجع التفصيلي Report408 وReport415 §4-G. |
| `async function _printOrder(code)` | 2452 |
| `function _buildPrintWindow(order,items,settings)` | 2454 | فحصهما منفصلين؛ لا يوجد دليل أن إصلاح المودال يصلح الطباعة. لا تستخدم استبدالًا كاملًا من snapshot ما لم يطابق النص الحي. |

**المحدد الآمن:** افتح `RW_Orders` في الملف الأم الحالي وابحث عن التوقيع الدقيق لكل دالة أعلاه. لا تعتمد على رقم السطر وحده، ولا تنفّذ استبدالًا عامًا على مستوى الملف. إذا لم يطابق جسم الدالة snapshot، لا تستبدله بالنص التاريخي؛ سجّل الفرق واشتق patch من النص الحي.

## 4. سجل التنفيذ في هذه الدورة
- أُعيدت قراءة `CURRENT_STATE.md` وملف حوكمة CTO، ثم Report415 وReport413.
- Production: أُعيدت قراءة الرأس والتفاصيل وتعريفات RPC وACL وسياسات RLS.
- فُحصت فروع Supabase: لا توجد Development Branches متاحة حاليًا؛ لذلك لم تُنشأ بيانات تجريبية داخل Production، ولم تُعدّل `ORD-1006`.
- لم تُعدّل أي Edge Function أو SQL أو بيانات أو ملفات واجهة.
- لم يُثبت نشر الواجهة أو Browser E2E أو الطباعة؛ لا يُعلن الإغلاق.

## 5. المطلوب من المالك — دون تكرار التحليل
1. افتح الملف الأم الحالي: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html
2. داخل `RW_Orders` طابق تواقيع العناصر في الجدول أعلاه، ثم ادمج فقط العناصر التي تطابق النص الحالي. النصوص الكاملة للـhelpers و`loadData` وRealtime والجدول والتحقق موجودة في Report413 §3-A إلى §3-F؛ لا تنسخها عميانيًا.
3. طابق `_showDetails`, `_printOrder`, `_buildPrintWindow` مع Report408/Report415؛ يجب أن تعرض التفاصيل والطباعة المرتجع والكمية المتبقية والإجمالي النهائي بصورة متسقة.
4. بعد النشر، سجّل SHA الملف المخدوم واختبر بحساب مصادق: `ORD-1006` للقراءة فقط، مصدر POS غير قابل للاختيار للرانشيت، المصدر المؤهل ما زال قابلًا للاختيار، Realtime، تفاصيل المرتجع، الطباعة، والفرز/الفلاتر. استخدم fixture معزولًا فقط إذا توفرت بيئة Staging؛ نظّفه وأثبت عدم بقاء أثر.

## SELF-AUDIT FINAL
- **What I Proved:** Production snapshot الحالي، تفاصيل المرتجع، أهلية المصدر في RPCs، ACL، وحدود RLS.
- **What I Did Not Prove:** محتوى الملف الأم الحي، تطابقه مع snapshot، النشر، Browser E2E، أو اتساق الطباعة بعد النشر.
- **What I Fixed:** لا تعديل Production جديد؛ Core guard الصحيح تُرك كما هو.
- **What I Initially Missed:** يجب الفصل بين رقم سطر snapshot ورقم سطر الملف الأم الحي، وبين صلاحية قراءة الأوردر وصلاحية قراءة اسم منشئه.
- **What Could Still Be Wrong:** اختلاف الملف الأم الحالي عن snapshot، أو وجود نسخة منشورة لا تطابق Git، أو عدم اتساق الطباعة.
- **Final Confidence:** مرتفع في Production Core/data؛ غير مثبت في الواجهة الحية والنشر.
- **Final Closure Status:** `PRODUCTION CORE VERIFIED / OWNER SURGICAL PATCH SPECIFIED / LIVE SOURCE TEXT UNREADABLE THROUGH CONNECTOR / UI DEPLOYMENT + E2E + PRINT OPEN / NOT CLOSED`.
- **NEXT EXACT RESUMPTION POINT:** اقرأ الملف الأم من محرر GitHub/المصدر الخام بطريقة تعيد النص الكامل؛ طابق `RW_Orders` ثم دمج patch owner-only، وانشر واختبر قبل أي إعلان إغلاق.
