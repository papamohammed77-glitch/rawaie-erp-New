# Report705 — إصلاح تصنيف قائمة الاستلام وسجل العمليات المكتملة في Receiver والمخزن الشامل
**التاريخ:** 2026-11-12 (Africa/Cairo)  
**نقطة العمل:** LVE-2026-11-12-705  
**الحالة:** تنفيذ الكود واختبارات CI E2E ناجحة؛ نشر Cloudflare الحي والتحقق بجلسة موظف Production غير مثبتين.

## 1. نطاق التكليف والحوكمة
- ملف التعليمات الحاكم: `doc/Draft/Reprots/writing-block-8888-10.md`، تمت قراءته كاملًا (27,617 حرفًا)، SHA `928a98e94624e1c0a5bf4b3e97aaff560c33fcd8`.
- الدستور التشغيلي الدائم: `doc/Draft/Reprots/الدستور التشغيلي الدائم.md`، تمت قراءته كاملًا، SHA `3a6b1e220af8509e314e94df76563bbc6f84910d`.
- تمت مراجعة `CURRENT_STATE.md` ونقطة LVE-2026-11-11-704، وReport704 وReport700، إضافة إلى تاريخ التعديلات والتزامات تقرير الاستلام.
- المستودع التشغيلي الوحيد: `papamohammed77-glitch/erp-frontend`، الفرع `main`. لم يُنشأ فرع أو بيئة Supabase منفصلة.
- قاعدة البيانات: SMART ERP / Supabase `fiilmooggumokxanwiyx`. كل استعلامات القاعدة في هذا العمل كانت للقراءة فقط.
- بقي التغيير جراحيًا في نقطة تصنيف قائمة PO فقط. لم تتغير مخططات أو جداول أو قيود أو سياسات RLS أو RPC أو Edge Functions أو Service Worker.

## 2. الحالة الفعلية قبل التصحيح
### المشكلة الأولى — قائمة «قيد الاستلام»
كان مصدر قائمة PO يعتمد على حالة أمر الشراء، وهي ليست وحدها إثباتًا دقيقًا للكمية المتبقية. ظهر أمر حالته `Approved` مع أن كل تفاصيله مستلمة: `qty_received = qty_ordered = 5`. لذلك كان يظهر مرة أخرى في الانتظار رغم عدم وجود أي كمية متبقية.
- المستند: `QA-SR-PO-20260927`.
- حالته: `Approved`.
- الكمية المطلوبة والمستلمة: 5/5.
- لا يوجد له Header فعلي في `receiving` ولا `operation_id` لاستلام مسجل.

**قرار سلامة ملزم:** يُستبعد هذا PO من قائمة الانتظار لأن المتبقي صفر، لكن لا يُنشأ له سجل مكتمل مصطنع؛ لا يُدرج في «مكتملة» إلا حدث استلام موجود فعلًا في سجل `receiving`. لم يتم تعديل هذا السجل أو إنشاء حدث تعويضي في Production.

### المشكلة الثانية — «مكتملة»
تحقق القراءة المباشرة من SMART ERP من وجود ثلاثة أحداث استلام حقيقية مسجلة، مع ستة أسطر تفاصيل، وكلها بالحالة العربية `مكتمل`:
1. PO `PO-20260928`: سطران، مرسل 15، مقبول 15، المسؤول `receiver@rawaea.com`.
2. شراء سوق سريع `PINV-1002`: سطران، مرسل 15، مقبول 15، المسؤول `receiver@rawaea.com`.
3. شراء سوق سريع `PINV-1003`: سطران، مرسل 9، مقبول 9، المسؤول `storekeeper@rawaea.com`.

المراجع بالمستندات والفروع وعمليات الاستلام قابلة للربط في البيانات الحالية. تبويب المكتملة يستند إلى حدث الاستلام الفعلي في `receiving` وتفاصيله، لا إلى حالة PO وحدها. لم يتم تعديل سجل مكتمل قائم أو إجراء ترحيل جديد.

## 3. التصحيح المنفذ
تم إدخال المرشح التالي بعد إرفاق تفاصيل PO وقبل بناء قائمة الانتظار، في كل من Receiver المستقل والنسخة المضمّنة في Warehouse Hub:

```javascript
all=all.filter(function(row){
    if(row.doc_type==='QUICK_MARKET')return true;
    var items=row.items||[];
    if(!items.length)return true;
    return items.some(function(item){
        return Number(item.qty_received||0)<Number(item.qty_ordered||0);
    });
});
```

دلالات الحارس:
- يبقي PO في «قيد الاستلام» إذا كان لديه سطر واحد على الأقل بكمية متبقية موجبة.
- يستبعد PO عندما تكون جميع أسطره مستلمة بالكامل، حتى لو بقيت حالته الإدارية قديمة مثل `Approved`.
- يستخدم مقارنة رقمية دقيقة مطابقة لقاعدة العمل، من دون سماحية تقريب قد تخفي كمية صغيرة متبقية.
- إذا غابت تفاصيل PO، يبقيه ظاهرًا بدل إسقاطه تلقائيًا على أساس بيانات ناقصة؛ وهذا يحافظ على مبدأ fail-open للعرض مع منع قرار اكتمال غير موثق.
- لا يغير حالة PO ولا كميات الاستلام ولا حركة المخزون ولا القيود.
- لا يغير مسار Quick Market؛ الـRPC الحالي يعيد فقط الفواتير والأصناف التي ما زال لها مقدار تسليم/استلام متبقٍ.
- لا يضيف تبويبًا جديدًا. تظهر أحداث الاستلام الفعلية في تبويب «مكتملة» الموجود أصلًا، مع المستند والمسؤول ووقت العملية والتفاصيل.

### الملفات وبصمات المصدر النهائي
| الملف | Blob SHA النهائي | التغيير |
|---|---|---|
| `companies/company-1/warehouse/receiver.html` | `c97079058eb201572e784f89fd48c7a28fdd2a0b` | حارس المتبقي الدقيق في قائمة PO |
| `companies/company-1/warehouse/warehouse.html` | `3d07af3e015cbdef190dbccde998bcd2ed4e24de` | نفس الحارس في Receiver المضمّن |
| `.github/workflows/warehouse_hub_browser_e2e_20261110.yml` | `eaef5a9c018100d6dd2778d931ca91e4cde27bb8` | تغطية PO المكتمل وإعادة الدخول واختبار Receiver المستقل |

### سلسلة commits ذات الصلة
- Receiver: `07a70f221b9469efc21531280f36e62fbae60ce1`، ثم مطابقة دقة المقارنة `85f7e9478425cec1b27c489ecae0cf79b8799abc`.
- Warehouse Hub: `4b71f053ae1c3a5d9b48d3b7612dab8b04075d11`، ثم مطابقة دقة المقارنة `243c90b72715e4c2d41323cbae3dca007a178995`.
- تغطية Browser E2E النهائية: `8a9a11186e1f9b20138a4317d1bdfe3d7e12588a`.
- Operational `main` HEAD المتحقق بعد الاختبار: `8a9a11186e1f9b20138a4317d1bdfe3d7e12588a`.

## 4. اختبار التكامل وE2E
**Workflow:** RAWAEA — Standalone Unified Warehouse E2E  
**Run:** 43241826072 — Run #107  
**النتيجة:** `completed / success`، جميع خطوات job `standalone-warehouse` انتهت بنجاح، بما فيها Static source contract وPlaywright Browser E2E ورفع التشخيص والتنظيف.  
**الرابط:** https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/43241826072

### Receiver داخل Warehouse Hub
- تحقق عقد الوحدات السبعة واشتراكها في جلسة Auth/عميل Supabase واحد.
- دخول تبويب العمليات وفتح Receiver المضمّن.
- PO جزئي وQMP غير مكتمل يظلان في الانتظار.
- PO ذو كمية 5/5 وحالة Approved لا يظهر في الانتظار.
- عمليات PO وQMP وPO المكتمل تظهر في سجل المكتملة.
- فتح تفاصيل الاستلام ومراجعة الصنف والكمية المقبولة/المرفوضة وسبب الفرق ومعرف العملية.
- العودة إلى قائمة المكتملة، التبديل إلى الانتظار ثم إعادة فتح المكتملة؛ السجل لا يختفي.
- اختبار سيناريو رفض شراء السوق السريع بالكامل دون طلب حركة مخزون.

### Receiver المستقل
أضيف اختبار Playwright يفتح `receiver.html` مباشرة، منفصلًا عن التطبيق المجمّع، ويثبت:
- الدخول بدور الاستلام النشط.
- ظهور PO الجزئي وQMP غير المكتمل في قائمة الانتظار وعدم ظهور PO المستلم بالكامل.
- دعم شكل نطاق الفروع القديم `allowed_branch_ids = 'BR-01'` وتحويله إلى UUID الفرع المسموح بعد قراءة الفروع النشطة.
- عرض السجلات الثلاثة في «مكتملة».
- فتح زر `open-history` داخل بطاقة PO المكتمل، والتحقق من `operation_id` ومحتوى التفاصيل.

### علامات القبول الأساسية المسجلة في CI
- `WAREHOUSE_RECEIVER_FULLY_RECEIVED_PO_QUEUE_GUARD=PASS`
- `WAREHOUSE_RECEIVER_COMPLETED_AUDIT_HISTORY=PASS`
- `WAREHOUSE_RECEIVER_COMPLETED_HISTORY_REENTRY=PASS`
- `WAREHOUSE_STANDALONE_RECEIVER_PO_QUEUE_LEGACY_BRANCH_AND_COMPLETED_HISTORY=PASS`
- `WAREHOUSE_RECEIVER_PO_PHYSICAL_RECEIPT_GUARDS=PASS`
- `WAREHOUSE_RECEIVER_QUICK_MARKET_FULL_REJECTION_NO_STOCK_REQUEST=PASS`
- `WAREHOUSE_SEVEN_NATIVE_OPERATION_BUNDLES=PASS`
- `WAREHOUSE_ALL_SEVEN_MODULES_SHARED_AUTH_NO_DUPLICATE_CLIENT=PASS`
- `WAREHOUSE_SIX_FULL_NATIVE_OPERATION_WORKSPACES=PASS`
- اختبارات Picker وLoader وReturns وUnloader وCounter وVouchers والصلاحيات ونطاق الفرع والتسجيل والخروج وإعادة الدخول نجحت ضمن الـWorkflow.

**حد الاختبار:** Playwright هنا يستخدم Supabase/Auth mocks وبيانات QA مؤقتة داخل المتصفح. هذا يثبت سلوك الواجهة والتكامل الداخلي للعقود المحاكية، ولا يساوي جلسة موظف مصادقًا عليها في Production ولا تنفيذ استلام فعلي في قاعدة البيانات.

## 5. Supabase / أثر الإنتاج بعد الاختبار
لم تُنفذ INSERT/UPDATE/DELETE أو RPC لترحيل استلام أو مخزون أو مال. لم تنشأ بيانات QA في Production. الأعداد المقروءة بعد الاختبار:
- `receiving = 3`، و`receiving_details = 6`.
- `inventory_log = 82`، و`stock_branches = 60`.
- `journal_entries = 21)، و`supplier_ledger = 3)، و`stock_vouchers = 0`.

ارتفع `inventory_log` من 78 إلى 82، و`stock_branches` من 58 إلى 60 مقارنة بلقطة Report704 السابقة. تم تحديد سبب الفرق في سجلات فعلية مؤرخة 2026-11-11: استلاما شراء سوق سريع `PINV-1002` و`PINV-1003`، لكل منهما سطران `PurchaseIn` مع مفاتيح idempotency وأسماء المنفذين المتوافقة مع سجلات `receiving` و`audit_log`. هذه حركات أعمال حقيقية متزامنة سبقت تنفيذ اختبارنا، وليست أثر Playwright؛ لم نعدلها أو نعكسها.

### الصلاحيات وRLS
- حساب Receiver الاحتياطي لديه دور نشط `استلام` وصلاحية `warehouse` ونطاق فرع محفوظ كنص مفرد `BR-01`.
- حساب المخزن الشامل لديه دور `مخزن شامل` وصلاحية `warehouse` والنطاق ذاته محفوظًا كمصفوفة.
- سياسات SELECT في `receiving` و`receiving_details` تسمح لنفس الشركة مع صلاحيات `warehouse/reports/finance` أو مسؤولية السجل، والمنشئ الحالي داخل سجل الاستلام معروف.
- `resolveBranchScope()` الحالي يدعم المصفوفة والنص المفرد ويحوّل كود الفرع النشط إلى UUID. تم اختبار حالة النص المفرد في E2E المستقل.
- لم يتم تعديل RLS أو GRANT أو أدوار المستخدمين أو نطاقات فروعهم.

## 6. حدود النشر وما بقي مفتوحًا
1. **Cloudflare Pages:** لوحة Cloudflare المتاحة كانت تعرض لقطة قديمة لـProduction/main عند commit `c03a47ee...`، ولم أتمكن من إثبات أن Pages نشرت HEAD النهائي `8a9a111...`. لذلك النشر الحي **UNVERIFIED**. تفعيل Automatic deployments لا يثبت وحده نجاح نشر هذا commit.
2. **جلسة Production:** لم تتوفر جلسة متصفح موثقة الدخول لمستخدم Receiver في Production؛ لذلك لا أعلن اختبارًا فعليًا لمستخدم Production أو إغلاقًا نهائيًا للنشر.
3. **سجل PO التاريخي `QA-SR-PO-20260927`:** الكميات 5/5 لكن لا يوجد سجل استلام مقابل في `receiving`. استُبعد من الانتظار وفق المتبقي الفعلي، ولم يُنشأ له سجل مكتمل مصطنع. يحتاج مراجعة مستقلة لمصدر التحديث السابق في تفاصيل PO، ولا يدخل ضمن إصلاح الواجهة الحالي.
4. لا توجد حاجة لتعديل RPC أو RLS لإصلاح سلوك التصنيف الذي عالجه هذا التغيير؛ لا توسعة لنطاق المهمة إلى حزمة Inventory Control أو أي مسار مالي/مخزني آخر.

## 7. قرار الإغلاق
- **CONFIRMED:** إصلاح تصنيف PO ذي الرصيد المتبقي صفر في Receiver المستقل والمضمّن، على المصدر التشغيلي `main`.
- **CONFIRMED:** تبويب المكتملة يحتفظ بعقده القائم المبني على سجل الاستلام الفعلي؛ الاختبارات تعرض PO وQMP المكتملين وتفتح تفاصيلهم وتعيد الدخول إلى التبويب بنجاح.
- **CONFIRMED:** CI Playwright النهائي #107 نجح، بما في ذلك اختبار مستقل لـ`receiver.html` واختبار Receiver داخل `warehouse.html`.
- **CONFIRMED:** لا توجد كتابة Production أو تغيير أرصدة/دفاتر/قيود أو تغيير RLS/RPC أثناء هذه المهمة.
- **UNVERIFIED:** Cloudflare Pages deployment على HEAD النهائي، وجلسة E2E فعلية لحساب Production.
- **OPEN DATA INTEGRITY REVIEW:** PO `QA-SR-PO-20260927` بلا حدث استلام موثق رغم 5/5 في تفاصيله.

**نقطة الاستئناف:** LVE-2026-11-12-705، operational HEAD `8a9a11186e1f9b20138a4317d1bdfe3d7e12588a`.  
**المهمة التالية المرتبطة:** التحقق من Cloudflare Production parity بعد النشر، ثم جلسة قراءة فعلية بحساب Receiver دون تنفيذ ترحيل إنتاجي، ومراجعة بيانات PO التاريخي غير المرتبط بسجل استلام.

### المراجع
- Operational HEAD: https://github.com/papamohammed77-glitch/erp-frontend/commit/8a9a11186e1f9b20138a4317d1bdfe3d7e12588a
- Receiver: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/warehouse/receiver.html
- Warehouse Hub: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/warehouse/warehouse.html
- E2E workflow: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/.github/workflows/warehouse_hub_browser_e2e_20261110.yml
- Successful run #107: https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/43241826072
- Prior checkpoint Report704: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report704_DAILY_CTO_REVIEW_INVENTORY_TRANSFER_AND_RETURNS_GATE_20261111.md
