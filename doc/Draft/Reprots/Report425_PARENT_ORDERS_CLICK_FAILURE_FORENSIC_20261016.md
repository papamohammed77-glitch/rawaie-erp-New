# Report425 — تحقيق عدم استجابة فتح تفاصيل أوردرات المبيعات
**التاريخ:** 2026-10-16  
**النطاق:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`، وحدة `RW_Orders` فقط.  
**قيود التنفيذ:** لم يتم تعديل `main.html` أو أي تطبيق تشغيلي، ولم تُنفّذ أي تغييرات على مخطط قاعدة البيانات أو بيانات Production.

## PRE-CHANGE SELF-AUDIT

- **Business understanding:** الضغط على صف الأوردر يجب أن يفتح تفاصيله؛ فشل التفاعل مع ظهور طلبات REST متكررة إلى `orders`.
- **Architecture understanding:** الواجهة الأم هي المستهلك؛ القراءة الحالية تتم مباشرة من Supabase REST، ولا يوجد دليل من السجل المعروض على أن طلب فتح التفاصيل يستدعي Edge Function.
- **Database understanding:** Production query بتاريخ 2026-10-16 18:47:17 UTC أكد وجود جدول `public.orders` و10 أوردرات للشركة `00000000-0000-0000-0000-000000000001`.
- **Historical understanding:** ملف الحالة الحالي يوثق أن وحدة `RW_Orders` سبق أن خضعت لتعديلات؛ لا يجوز إعادة تطبيق تقاريرها التاريخية آليًا.
- **Production understanding:** سجل Supabase الحالي أظهر طلبات GET على `/rest/v1/orders?select=*%2Crunsheets%28runsheet_code%29...` ناجحة بحالة HTTP 200.
- **Current understanding:** GitHub أعاد blob SHA الحالي للملف `a192704e07d984fdbecd00ce40a73e95fa806a7e`، لكن أداة جلب الملف الكبير أعادت جسمًا فارغًا حتى عند تحديد نطاق الأسطر؛ لذلك لا يمكن توثيق نص المقطع الحالي أو أرقام أسطره من المصدر في هذه الدورة.
- **Execution confidence:** مرتفع في استبعاد عطل ثابت في REST/جدول orders من الأدلة المتاحة؛ متوسط في ترجيح إعادة الرسم/تجديد DOM كسبب لعدم استجابة النقر؛ غير كافٍ لإصدار بديل كود دقيق دون جسم المصدر الحالي.

## الأدلة المؤكدة

1. سجل Console المقدم من المالك يبين أن `render` داخل مسار وحدة الأوردرات يستدعى من `setInterval` عند `main:10323`، كما يظهر مسار `render` آخر عند `main:30347`. هذا يثبت وجود مسار تحديث زمني، لكنه لا يثبت وحده أن كل تحديث يستبدل صفوف الجدول.
2. سجل Supabase الحي بين 18:33 و18:47 UTC أظهر 3–7 طلبات GET للأوردرات في الدقيقة في العينات المعروضة، وكل الطلبات المعروضة HTTP 200؛ متوسط `response.origin_time` تراوح تقريبًا بين 150 و763 ms.
3. لذلك فإن `ERR_CONNECTION_CLOSED` الذي ظهر في لقطة Console لا يثبت أن قاعدة البيانات أو صلاحيات القراءة هي سبب عدم استجابة النقر؛ سجلات Production الحديثة تثبت أن endpoint كان يستجيب بنجاح في طلبات لاحقة.
4. تحذير Tailwind CDN ورسالة `favicon.ico 404` ليستا سببًا مباشرًا مثبتًا لتعطل فتح تفاصيل الأوردر.
5. لا يوجد ما يبرر تعديل Production SQL/RPC/ACL أو إدخال بيانات تجريبية في هذه المرحلة.

## Root-cause assessment

**الاحتمال الأقوى الذي يجب اختباره أولًا:** التحديث الزمني يستدعي `render()` كاملًا بدل تحديث البيانات/العناصر المتغيرة فقط، وقد يؤدي ذلك إلى استبدال صف الجدول أو فقدان/إبطال عنصر النقر أو handler أثناء التفاعل. هذا متسق مع stack trace، لكنه يظل **ترجيحًا يحتاج إثباتًا من جسم المصدر وDOM وقت النقر**، وليس حقيقة نهائية مثبتة بعد.

**ما لم يثبت:** أن Supabase REST هو سبب المشكلة؛ أن كل استدعاء `render` يبدّل DOM؛ أو أن handler الخاص بتفاصيل الأوردر مفقود. لم يتم تعديل Production لعدم وجود defect backend مثبت.

## فحص Console مؤقت — لا يغيّر بيانات النظام

الصق هذا المقطع في DevTools Console بعد فتح تبويب أوردرات المبيعات، ثم اضغط على صف أوردر مرة واحدة وانتظر 8 ثوانٍ. يراقب النقرات وتغيّر DOM وأخطاء/حالات طلبات الأوردرات دون تعديل البيانات أو كود النظام:

```js
(() => {
  if (window.__rawaeaOrdersForensic?.stop) window.__rawaeaOrdersForensic.stop();

  const state = { startedAt: new Date().toISOString(), clicks: 0, mutations: 0, orderRequests: 0, orderFailures: 0 };
  const originalFetch = window.fetch;
  const onClick = (e) => {
    const el = e.target instanceof Element ? e.target : e.target?.parentElement;
    const row = el?.closest('tr');
    const text = (row?.innerText || el?.innerText || '').trim().replace(/\s+/g, ' ').slice(0, 240);
    state.clicks++;
    console.log('[RAWAEA click]', { at: new Date().toISOString(), tag: el?.tagName, id: el?.id, className: String(el?.className || '').slice(0, 160), rowFound: !!row, rowConnected: row?.isConnected, text });
    queueMicrotask(() => console.log('[RAWAEA click+microtask]', { rowStillConnected: row?.isConnected, rowStillSame: !!row && document.contains(row) }));
    setTimeout(() => console.log('[RAWAEA click+500ms]', { rowStillConnected: row?.isConnected, rowStillSame: !!row && document.contains(row) }), 500);
  };
  document.addEventListener('click', onClick, true);

  const observer = new MutationObserver((records) => {
    state.mutations += records.length;
    const relevant = records.filter(r => {
      const target = r.target instanceof Element ? r.target : r.target?.parentElement;
      return !!target?.closest('table, [id*="order" i], [class*="order" i]');
    });
    if (relevant.length) console.log('[RAWAEA orders DOM mutation]', { records: relevant.length, total: state.mutations, at: new Date().toISOString() });
  });
  observer.observe(document.body, { subtree: true, childList: true });

  window.fetch = async function(...args) {
    const url = String(args[0]?.url || args[0] || '');
    const isOrders = /\/rest\/v1\/orders(?:\?|$)/i.test(url);
    if (isOrders) state.orderRequests++;
    try {
      const response = await originalFetch.apply(this, args);
      if (isOrders) console.log('[RAWAEA orders HTTP]', { status: response.status, ok: response.ok, url: url.slice(0, 240), at: new Date().toISOString() });
      if (isOrders && !response.ok) state.orderFailures++;
      return response;
    } catch (error) {
      if (isOrders) {
        state.orderFailures++;
        console.error('[RAWAEA orders FETCH FAILED]', { url: url.slice(0, 240), error: String(error), at: new Date().toISOString() });
      }
      throw error;
    }
  };

  window.__rawaeaOrdersForensic = {
    state,
    stop() {
      document.removeEventListener('click', onClick, true);
      observer.disconnect();
      window.fetch = originalFetch;
      console.log('[RAWAEA forensic summary]', { ...state, finishedAt: new Date().toISOString() });
      delete window.__rawaeaOrdersForensic;
    }
  };
  console.log('RAWAEA forensic monitor active. Click one order, wait 8 seconds, then run: window.__rawaeaOrdersForensic.stop()');
})();
```

## القرار الجراحي

- لا تعدّل `main.html` قبل استرجاع نص المقطع الحالي حول `RW_Orders.render` / `setInterval` وhandler فتح التفاصيل من الـblob الحالي.
- بعد إثبات المقطع: التعديل المستهدف هو **إزالة إنشاء مؤقت متكرر من داخل دورة render**، وجعل المؤقت يُنشأ مرة واحدة فقط عند تهيئة الوحدة، ويستدعي refresh محميًا من التداخل؛ لا يُستبدل صف الجدول أثناء فتح مودال التفاصيل. يجب الحفاظ على منطق الفلاتر والاختيار والتحديث اللحظي الحالي.
- لا أقدم كتلة استبدال كاملة أو أرقام أسطر بديلة الآن لأن محتوى الملف الحالي لم يُسترجع من أداة المصدر؛ اختلاقها سيخالف شرط عدم التخمين.
- بعد تطبيق تعديل المالك: اختبر فتح التفاصيل بالنقر على الصف وعلى زر التفاصيل إن وجد، مع استمرار التحديث، ثم راقب عدم استبدال الصف أثناء التفاعل. اختبر الطلبات عبر Network وتأكد من عدم وجود تداخل polling أو تكرار مؤقتات بعد التنقل ذهابًا وإيابًا.

## Production change

**NONE.** لا يوجد إصلاح SQL/RPC/ACL مثبت مطلوب لهذه المشكلة، ولم تتغير بيانات Production.

## SELF-AUDIT FINAL

- **What I Proved:** طلبات Production إلى orders نجحت بحالة 200 في العينات الحية؛ الجدول يحتوي 10 أوردرات للشركة؛ stack trace المقدم يربط render بمسار setInterval.
- **What I Did Not Prove:** المقطع البرمجي الدقيق المسؤول عن إبطال النقر؛ هل الصف يُستبدل فعليًا عند كل tick؛ ونجاح الإصلاح بعد نشره في المتصفح.
- **What I Fixed:** لم أجرِ تغييرًا تخمينيًا في الواجهة أو قاعدة البيانات؛ أعددت فحص Console غير هدّام وحددت موضع الإصلاح المرشح.
- **What I Initially Missed:** السجلات السابقة وحدها لا تثبت عطل REST؛ يجب فصل network transient عن سلوك DOM.
- **What Could Still Be Wrong:** قد يكون handler التفاصيل مفقودًا أو يرمي استثناءً مستقلًا، وقد يكون `ERR_CONNECTION_CLOSED` مشكلة شبكة عابرة.
- **Final Confidence:** متوسط.
- **Final Closure Status:** **OPEN — لا يجوز إعلان الإغلاق قبل استرجاع المقطع الحالي وإثبات السبب ثم نجاح Browser E2E.**
