# Report602 — التحقيق الجنائي والمطابقة الحالية لتطبيق Buyer
**التاريخ:** 2026-11-03 — Africa/Cairo  
**الحالة:** المصدر وProduction تمت مطابقتهما في نطاق التحقيق؛ ظهرت فجوة صلاحيات جديدة في مرتجعات الشراء؛ الوظائف التجارية P1 ما زالت مفتوحة؛ Cloudflare وE2E غير مثبتين.
**نقطة البداية:** LVE-2026-11-03-601.  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` / `main`.  
**Production:** SMART ERP — `fiilmooggumokxanwiyx`.

## 1. الملخص التنفيذي
تمت مواصلة العمل من الحالة الحالية، لا من الصفر. ثبت أن إصلاحات P0 السابقة على جداول الفواتير، حارس استلام PO، وتأخير حركة النقدية حتى إقرار الموظف موجودة بالفعل في المصدر وProduction؛ لا يعاد تنفيذها. كشف الفحص الحالي أن جدولي `purchase_returns` و`purchase_return_details` ما زالا يمنحان الأدوار العميلية صلاحيات DML واسعة، وأن RPC ترحيل مرتجع المورد يخرج المخزون ويخفض حساب المورد دون إثبات قبول المورد للبضاعة داخل عقد الترحيل. كما ثبت أن Buyer لا يحتوي بعد على دورة سوق مستقلة، ولا دفتر عهدة بضاعة لسيارة المشتريات، وأن واجهة إصدار العهدة النقدية تعرض رسالة لا تطابق عقد Production الجديد.

لم يتم تعديل `buyer.html` أو `main.html` أو Receiver، ولم تُجر أي كتابة أو Migration أو تعديل ACL/RLS أو بيانات في Production. الحزم الجديدة مؤثرة ماليًا ومخزنيًا، وMaster CTO §77.2–§77.4 يفرض عرض التغيير الدقيق ثم موافقة المالك الصريحة عليه. لذلك جرى تجهيز الإصلاحات الجراحية ومواصفات الحزم في التقرير دون تجاوز بوابة الموافقة. لم تُنشأ Edge Function جديدة أو بيانات اختبارية في Production.

## 2. نقطة البداية وتسوية سجل الحالة
كان أعلى `CURRENT_STATE.md` عند LVE-601 يذكر أن بعض إصلاحات P0 لم تنفذ، بينما السجل الملحق في نهاية الملف (الأسطر 4837–4860) يسجل تنفيذها لاحقًا. المصدر الحالي وProduction يؤيدان السجل الملحق. هذا تعارض في ترتيب سجل الحالة، وليس مبررًا لإعادة الإصلاح. يضيف هذا التقرير LVE-602 أعلى الملف مع الإبقاء على التاريخ السابق كاملًا.

## 3. GitHub / source
**CONFIRMED:**
- Operational repo: `papamohammed77-glitch/erp-frontend`, branch `main`.
- HEAD `743c9b170bf2314a9e4d64fd4d8104f2cc1aee8c`; parent `2ce93c6d80ec4c38353bdf88880d06ae9e0abdde`.
- رسالة HEAD: `chore(db): remove mismatched custody migration filename`؛ التغيير يزيل اسم migration القديم غير المتطابق. Migration العهدة الحالي اسمه متوافق مع نسخة Production `20261103160902`.
- Governance repo: `papamohammed77-glitch/rawaie-erp-New`, branch `main`; HEAD `ad8b49f835b9a8b9116c201640426394966306ba`; parent `fb0af6503042a2640a563eaa308c97487f23b551`.
- Buyer blob `aee14e6a4edbccd5fb95dff24f21daf1c6d21fcc` (140,456 chars / 1,047 lines).
- core.js blob `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1`; Receiver blob `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6`.
- Buyer يحتفظ بتسعة تبويبات: اليوم، الموردون، PR، عروض الأسعار، PO، فواتيري، عهدتي، رصيد السيارة، حسابي. لم يُعد بناء أي تبويب.

## 4. CONFIRMED — إصلاحات P0 المنفذة بالفعل
1. Migration `20261103155029_buyer_invoice_tables_central_writer_only`: `purchase_invoices`, `purchase_invoice_details`, `purchase_attachments` أصبحت قراءة SELECT للمستخدم المصادق عليه؛ لا كتابة مباشرة من الواجهة. فحص شجرة company-1 (30 HTML و4 JS كما هو مثبت بالسجل، ثم إعادة فحص الشجرة الحالية) لم يجد DML مباشرًا من التطبيقات على هذه الجداول.
2. Migration `20261103155444_receive_purchase_role_and_branch_authorization`: RPC ذو 5 معاملات يتحقق من المستخدم النشط والصلاحيات الفعلية ودور `استلام` ونطاق الفرع. overload الأربعة arguments محجوز لـservice_role. Edge `receive-purchase` v13 نشطة و`verify_jwt=true` وتتحقق من المستخدم والصلاحيات ثم تستدعي العقد المحكوم.
3. Migration `20261103160902_buyer_custody_cash_disbursement_requires_employee_ack_20261103`: إنشاء العهدة والزيادة لا يصرف نقدية؛ التسجيل يعيد `PendingEmployeeAcknowledgement`. لا يُسجل cash_box أو journal entry إلا من إقرار الموظف صاحب العهدة، مع idempotency وقفل الصفوف والتحقق من اتساق سجل النقدية والقيد.
4. إصلاح Buyer السابق منع ملء سعر الشراء تلقائيًا من `cost_price`، وحافظ على السعر الفارغ، وأضاف `operation_id` عند إنشاء فاتورة جديدة وتعديل المسودة. `quickAddItem` الحالي يضع `unit_price:null`؛ لا تعاد هذه الإصلاحات.

## 5. Supabase Production — الحالة الحالية
**CONFIRMED:**
- المشروع `fiilmooggumokxanwiyx` بحالة ACTIVE_HEALTHY؛ migrations المسجلة 737.
- `save-purchase-order` v22 ACTIVE و`verify_jwt=true`؛ SHA-256 `a0885a8a636b0d57ef9ab54b476001be8e3dd1f4227b921f511b002f58642ffb`.
- `receive-purchase` v13 ACTIVE و`verify_jwt=true`؛ SHA-256 `50ab45ae026a0bb4d1de7837c872c4cc42da47b6a603f340e48d023d839310cc`.
- العملة الحالية في `app_settings` هي EGP.
- جداول العهدة الخمسة، `receiving`، `purchase_returns`، `purchase_return_details`، و`fleet_vehicle_assignments` بها صفر سجلات في لقطة الفحص. `vehicles=2`، `purchase_invoices=3`، `stock_vouchers=0`، `inventory_log=76`، `supplier_ledger=2`، `journal_entries=19`، `cash_box=8`.
- قائمة Supabase development branches للمشروع أعادت صفر فروع؛ لا توجد بيئة branch جاهزة ضمن هذا المشروع للاختبار المعزول.

### 5.1 فجوة صلاحيات مرتجعات الشراء — CONFIRMED
نتيجة `information_schema.role_table_grants` أثبتت أن `anon` و`authenticated` يملكان على كلا الجدولين `purchase_returns` و`purchase_return_details` منحًا تشمل SELECT وINSERT وUPDATE وDELETE وREFERENCES وTRIGGER. وسياسة RLS `purchase_returns_company` تعمل بـ`ALL` على role `public` وتقيّد الرأس بـ`company_id = app_private.current_user_company_id()`. وسياسة `purchase_return_details_company` تعمل بـ`ALL` وتتحقق من أن التفاصيل تابعة لمرتجع داخل الشركة.
هذا عزل على مستوى الشركة، لكنه ليس تطبيقًا لمبدأ الكاتب المركزي؛ إذ يتيح نظريًا لمستخدم داخل الشركة تجاوز دورة العمل وتغيير حالة المستند أو تفاصيله مباشرة إذا استخدم اتصالًا مناسبًا. لم يثبت استغلال فعلي من جلسة anon أو مستخدم عادي؛ قابلية الاستغلال الفعلية UNVERIFIED، أما المنح الواسعة فهي CONFIRMED.
فحص 34 ملف HTML/JS الحالي في `companies/company-1` لم يجد DML مباشرًا لهذه الجداول. ظهر اسما الجدولين في Buyer ضمن Realtime/cache invalidation فقط. لم يشمل الفحص تكاملات خارجية أو مستودعات أخرى.

**Change Set P0-D المقترح — غير مطبق:** سحب كل امتيازات الكتابة وTRIGGER وREFERENCES على `purchase_returns` و`purchase_return_details` من `PUBLIC`, `anon`, و`authenticated`، وإعادة منح SELECT إلى `authenticated` فقط، ثم استبدال السياستين الحاليتين بسياسات SELECT فقط إلى `authenticated` مع الحفاظ على شرطي الشركة الحاليين. تبقى صلاحيات `service_role` دون مساس. يجب قبل التطبيق التأكد من كل المستهلكين الخارجيين، ثم اختبار قراءات Buyer/Parent والتطبيقات الأخرى وعمليات `CREATE_RETURN`, `POST_RETURN`, `CANCEL_DOCUMENT` عبر Edge v22. لم ينفذ أي SQL من هذا المقترح في هذه الدورة.

### 5.2 ترحيل مرتجع المورد — CONFIRMED
تعريف `purchase_post_return_atomic(uuid,uuid,text)` الحالي هو SECURITY DEFINER، وEXECUTE مقصور على service_role. الدالة تقفل سجل المرتجع، تتحقق من Draft والفرع، ثم تنفذ `post_stock_movement(...,'SupplierReturn',...)` لكل بند، وتنشئ قيدًا مدينًا لحساب المورد 211 ودائنًا للمخزون 124، وتسجل supplier_ledger debit، ثم تحول الحالة إلى Posted.
لا يظهر داخل هذا العقد فحص لقبول المورد للبضاعة أو توقيعه أو الكميات المقبولة/المرفوضة جزئيًا. وبالتالي فإن ربط إخراج المخزون وتخفيض AP بترحيل مستند واحد قبل إثبات قبول المورد يمثل فجوة عمل حقيقية. لا تعدل الدالة مباشرة؛ يلزم عقد منفصل للحيازة والتسليم وقبول المورد ثم التخفيض.

## 6. Buyer — الفجوات المثبتة
### 6.1 الشراء السريع
`quickPurchase()` عند السطر 762 مجرد alias إلى `createPurchaseInvoice()`. لا توجد عملية سوق مستقلة بكيان Payee/بائع عارض، ونوع شراء، ومستند سوق، وصور الفاتورة والبنود، وطريقة دفع، واستلام مادي مستقل عن PO. فاتورة Draft بلا PO يمكن إنشاؤها، لكن ترحيل الفاتورة السريعة بلا PO مرفوض حاليًا بـ`PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED` وفق Report599 والعقد الحالي. لا تنشئ PO وهميًا.
### 6.2 الاستلام
`receiver.html` يستدعي Edge `receive-purchase` مع `po_code` و`itemsReceived`؛ واجهة الاستلام الحالية PO فقط. حارس الاستلام الحالي يحمي هذا المسار، لكنه لا يستلم فاتورة سوق مباشرة بلا PO. أي توسعة يجب أن تستخدم البوابة والـRPC القائمين لا Edge جديدة.
### 6.3 عهدة سيارة المشتريات
`renderVehicleBalance()` عند الأسطر 617–629 يقرأ `fleet_vehicle_assignments` و`vehicles` ويبحث عن `driver_user_id` الحالي. يوضح المصدر أن دفتر عهدة بضاعة المشتريات غير مفعل، ويحذر من حساب رصيد من PO أو فاتورة أو إذن استلام. لا توجد جداول Buyer/Purchasing Goods Custody في المخطط المفحوص. المركبتان الموجودتان في Production هما سجلان من vehicles، ولا توجد fleet assignments في لقطة الفحص. لا تستخدم Delivery Van Stock أو Fleet Driver Assignment بدل دفتر عهدة المشتريات.
### 6.4 مصروفات العهدة
`submitCustodyExpense()` يقبل فاتورة Draft مرتبطة بمورد وPO وإذن استلام مكتمل ويرفع مستندي الفاتورة والاستلام. لا توجد أنواع مصروف PURCHASE/FUEL/TRANSPORT/OTHER في مسار Buyer الحالي. يجب الفصل بين شراء بضاعة نقدًا من العهدة، ومصروف تشغيل، وفاتورة مورد على الحساب، وسداد فعلي، ومنع إنشاء AP أو Payment مرتين.

### 6.5 خطأ واجهة مؤكد مع عقد العهدة الحالي
في `App.issueCustody`: السطر 870 يقول إن النظام سيسجل سند صرف ويحدث الخزينة والقيد بمجرد تسجيل الإصدار؛ والسطر 880 يعرض نجاح ربط العهدة بالخزينة والحسابات. لكن عقد Production الحالي ينتظر إقرار الموظف قبل تسجيل الحركة المالية. هذا تعارض نصي مؤكد، لا خطأ في RPC.

**التعديل الجراحي المقترح للمالك — غير مطبق:**
1. في `App.issueCustody`، السطر 870، استبدل النص:
```js
'<p class="text-xs text-amber-700">يجب أن تكون النقدية قد سُلّمت فعليًا. سيُسجل النظام سند صرف من الخزينة إلى حساب عهد الموظفين ويُحدّث رصيد الخزينة والقيد العام.</p></div>';
```
بالنص:
```js
'<p class="text-xs text-amber-700">سيُسجل الآن طلب تسليم العهدة فقط. لن تتغير الخزينة أو القيود المحاسبية إلا بعد أن يؤكد الموظف صاحب العهدة استلام النقدية فعليًا من حسابه المصادق عليه.</p></div>';
```
2. في السطر 880، استبدل:
```js
RW_UI.toast('تم تسجيل تسليم العهدة وربطه بالخزينة والحسابات','success');
```
بـ:
```js
RW_UI.toast('تم تسجيل طلب تسليم العهدة وبانتظار إقرار الموظف بالاستلام الفعلي','success');
```
3. استبدل دالة `acknowledgeCustody` كاملة (الأسطر 907–910) بالدالة التالية:
```js
acknowledgeCustody:async function(id){
    var ok=await Swal.fire({
        title:'تأكيد استلام العهدة النقدية',
        text:'هل استلمت مبلغ العهدة المذكور فعليًا يدًا بيد؟ لن تُثبت حركة الخزينة والقيد العام إلا بعد هذا الإقرار.',
        icon:'question',
        showCancelButton:true,
        confirmButtonText:'نعم، استلمت المبلغ فعليًا',
        cancelButtonText:'إلغاء'
    });
    if(!ok.isConfirmed)return;
    try{
        await this.api('ACKNOWLEDGE_CUSTODY',{custody_id:id});
        this.invalidate();
        await this.renderCustody();
        RW_UI.toast('تم تأكيد استلام العهدة وتسجيل أثرها النقدي والمحاسبي','success');
    }catch(e){
        this.notifyError(e);
    }
},
```
الأثر المتوقع: تصحيح رسالة الواجهة وإضافة تأكيد بصري للواقعة المادية فقط؛ لا تغيير في SQL أو RPC أو الحسابات. بعد تطبيق المالك يجب اختبار صاحب العهدة ومستخدم آخر غير صاحبها.

## 7. تصميم دورة العمل الواجب استكمالها
| الواقعة | الأثر الصحيح | ما لا يحدث |
|---|---|---|
| المورد يسلم للمشتري/سيارة المشتريات | عهدة بضاعة للمورد موثقة بالصنف والكمية والمستند والمشتري والمركبة | لا مخزون مؤسسة ولا AP ولا خزينة |
| المشتري يسلم للمخزن | محضر استلام وفحص مع مقبول/مرفوض/تالف | لا قبول للكميات غير المفحوصة |
| أمين المخزن يعتمد المقبول | زيادة مخزون الفرع للمقبول فقط واعتراف الالتزام حسب السياسة المحاسبية | لا ترحيل للمرفوض أو التالف |
| المخزن يصرف مرتجعًا للمشتري | عهدة مرتجع في الطريق للمورد | لا تخفيض AP بعد |
| المورد يقبل المرتجع | تخفيض التزام المورد وعكس مخزون/ضريبة الكميات المقبولة فقط، مرة واحدة | لا تخفيض الكميات المرفوضة |
| الموظف يقر باستلام النقدية | صرف خزينة وقيد واحد بعد إقرار المستخدم الصحيح | لا أثر نقدي بمجرد إنشاء طلب العهدة |

الكيانات/الحقول التي يلزم تصميمها قبل الكود: نوع مصدر الشراء (Supplier/MarketSeller)، Payee، مستند السوق، عملة النظام، وسيلة الدفع، فواتير وصور خاصة، بنود الصنف والوحدة والكمية والسعر والخصم والضريبة، كميات فعلية/مقبولة/مرفوضة/تالفة، فرع ومخزن، المشتري والمركبة المخصصة للمشتريات، أطراف الحركة (Supplier→BuyerVehicle→Warehouse والعكس)، proof path، actor/time، operation_id وسجل تدقيق. وللمصروفات: expense_type PURCHASE/FUEL/TRANSPORT/OTHER وpayee_kind، وربط اختياري بالمورد والفاتورة والاستلام والمركبة. هذه مواصفة تصميم، وليست جداول منفذة.

## 8. المقارنة التنافسية من الوثائق الرسمية
- **Dynamics 365:** استلام مخزون المورد (consignment) يسجل الحيازة المادية دون قيود GL ما دامت الملكية للمورد؛ انتقال الملكية يسجل لاحقًا عبر Inventory Ownership Change. [Microsoft Learn — Set up consignment](https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/consignment) و[Change ownership](https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/change-ownership-consignment).
- **Odoo 19:** يتيح استلام مخزون أمانة بمالك هو المورد، وظهوره في تتبع الحركة دون إضافته إلى قيمة مخزون الشركة؛ كما يفصل Credit Note عن اعتماد المرتجع أو استرداد المال. [Consignment](https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/shipping_receiving/daily_operations/owned_stock.html) و[Credit notes and refunds](https://www.odoo.com/documentation/19.0/applications/finance/accounting/customer_invoices/credit_notes.html).
- **SAP Business One:** يميز Goods Return عن A/P Credit Memo، ويدعم الربط بالوثيقة الأصلية والعودة الجزئية. [SAP Learning — Goods Returns and A/P Credit Memos](https://learning.sap.com/courses/managing-logistics-in-sap-business-one/solving-issues-in-purchasing).
- **Daftra:** يوثق دورة طلب/عروض/PO/فاتورة/استلام كامل أو جزئي/سداد/مرتجع، ويفصل أثر المنتج عن الخدمة وبعض آثار الاستلام والسداد. [Daftra Complete Purchase Cycle](https://docs.daftra.com/en/tutorial/the-complete-purchase-cycle/) و[Purchase Invoice](https://docs.daftra.com/en/user_manual/adding-purchase-invoice/).
- **Manager.io:** Purchase Invoice يزيد AP عند الشراء الآجل، والسداد معاملة منفصلة؛ Goods Receipt يفصل المتابعة الكمية عن المالية؛ Debit Note يعالج مردود المورد ولا يمثل بذاته استردادًا نقديًا. [Purchase invoices](https://www2.manager.io/guides/7189)، [Goods receipts](https://www2.manager.io/guides/36498)، [Debit notes](https://www2.manager.io/guides/7426).

الاستفادة المشتركة: فصل الملكية والحيازة والاستلام والسداد والإشعار الدائن، مع تتبع كامل. لا تنسخ أي نظام دون الحفاظ على عمليات الروائع الميدانية وتكامل النظام الأم.

## 9. مصفوفة الأدلة
| الطبقة | الحالة |
|---|---|
| GitHub/source | CONFIRMED: HEAD/parent وBuyer/core/Receiver وmigration الحالية |
| Supabase Production | CONFIRMED: إصدارات Edge، migrations، ACL/RLS/RPC، العملة والـcounts، DML grants على المرتجعات |
| Deployed artifact | UNVERIFIED: لم يثبت تطابق Cloudflare artifact مع Buyer blob الحالي |
| Runtime / authenticated E2E | UNVERIFIED: لا توجد جلسة Buyer مصادق عليها أو اختبار Browser موثق لهذه الدورة |
| Business effects | baseline CONFIRMED؛ اختبار الأثر الفعلي UNVERIFIED: لم تُنشأ معاملات اختبار ولم تتغير الأرصدة |

المتصفح المتاح عرض صفحة Parent عند `https://rawaea-erp.pages.dev/companies/company-1/main`، ولم يعرض Buyer مصادقًا عليه. كما تعذر إثبات نسخة Buyer المخدومة من Cloudflare. نجاح static parse أو SQL لا يثبت E2E.

## 10. مصفوفة E2E المطلوبة قبل إعلان الإغلاق
1. Draft/PO/RFQ/Quotation: لا مخزون أو نقدية أو AP بمجرد الإنشاء أو الموافقة.
2. PO partial/full receipt: إعادة المحاولة بنفس operation_id دون ازدواج stock/AP/journal.
3. Quick Market Purchase بلا PO: بائع ومستند سوق واستلام موثق؛ المقبول فقط للمخزون؛ لا PO وهمي ولا AP مزدوج.
4. Cash custody: لا أثر عند الإصدار؛ أثر واحد بعد إقرار الموظف؛ رفض أي موظف آخر؛ لا ازدواج في retry.
5. PURCHASE مقابل FUEL/TRANSPORT/OTHER: أدلة ومحاسبة منفصلة؛ لا تحويل مصروف عهدي إلى AP دون سبب تجاري حقيقي.
6. Purchasing vehicle custody: المورد→المشتري→المخزن ثم المخزن→المشتري→المورد، مع كميات مرفوضة وجزئية.
7. Supplier Return: لا تخفيض للمورد قبل قبول المورد؛ جزئي/مرفوض/إعادة إلى المخزن؛ ربط بالفاتورة الأصلية.
8. Authorization: مستخدم بلا صلاحية/شركة أخرى/فرع آخر/مستخدم ليس مسؤول الاستلام.
9. Regression: Buyer/Receiver/Parent read, stock vouchers, delivery driver, van-sales, supplier ledger, finance reports, realtime.
10. Cloudflare parity + authenticated Browser E2E + Console/Network ثم snapshots قبل/بعد لكل من stock_branches وinventory_log وreceiving وpurchase_invoices وpurchase_returns وsupplier_ledger وjournal_entries وtreasury وcash_box وجداول custody.

## 11. ما تم وما لم يتم
**تم:** التحقيق من GitHub، المطابقة المباشرة لـProduction، تحقق إصدارات Edge وRPCs وACL/RLS، فحص المستهلكين الحاليين ضمن شجرة company-1، تحديد الفجوات، إعداد الإصلاحات الجراحية، إعداد تقرير CTO.
**لم يتم:** لا تعديل Buyer/Receiver/main، لا SQL/DDL/RLS/ACL/Grant/RPC/Edge changes، لا تعديل بيانات Production، لا fixtures، لا نشر Cloudflare، لا authenticated E2E، ولا إعلان إغلاق للعمل.

## 12. توجيهات مساعد CTO التالي
ابدأ من `CURRENT_STATE.md` عند LVE-602 ثم Master CTO §§29 و32 و58–60 و77.2–77.4، ثم هذا Report602 وReport600 وReport599 وReport589 §19 وReport585. أعد جلب HEAD/parent والمصدر وقاعدة Production قبل أي تنفيذ.
الخطوة التالية ذات الأولوية: حسم المستهلكين الخارجيين ثم عرض Change Set P0-D للمالك لإزالة DML العميل على `purchase_returns` و`purchase_return_details` مع إبقاء SELECT المقيد للشركة. لا تنفذ قبل موافقة صريحة على التغيير المحدد. بعده صمم Quick Market Purchase وGoods Custody للسيارة وقبول Supplier Return في عقد مترابط، دون Edge جديدة أو لمس `main.html`.
لا تعِد تنفيذ إصلاحات P0 المثبتة. لا تختبر Production ببيانات مالية أو مخزنية. لا تخلط Fleet/Delivery Van Stock مع عهدة سيارة المشتريات. لا تعتبر وجود وظيفة أو نجاح SQL دليلًا على تشغيل ناجح.

**الحكم:** P0 الفواتير والاستلام وإقرار العهدة مثبتة؛ فجوة DML على المرتجعات مؤكدة؛ Quick Market Purchase وعهدة السيارة وقبول مرتجع المورد وتصنيف مصروفات العهدة لم تُغلق؛ النشر وE2E غير مثبتين. **OVERALL: OPEN / NOT PRODUCTION-READY.**
---

## الملحق التنفيذي P0-D — SQL المقترح كاملًا للمراجعة قبل الموافقة (لم يُنفذ)

**الهدف:** جعل مرتجعات الشراء تتبع مبدأ الكاتب المركزي المطبق بالفعل على فواتير الشراء. يحافظ على قراءة المستخدم المصادق عليه داخل الشركة، ويمنع DML من PUBLIC/anon/authenticated، ويترك Service Role على منحها الحالية.

### 1) Migration مقترحة

```sql
BEGIN;

REVOKE ALL PRIVILEGES
ON TABLE public.purchase_returns, public.purchase_return_details
FROM PUBLIC, anon, authenticated;

GRANT SELECT
ON TABLE public.purchase_returns, public.purchase_return_details
TO authenticated;

DROP POLICY IF EXISTS purchase_returns_company
ON public.purchase_returns;

CREATE POLICY purchase_returns_company
ON public.purchase_returns
FOR SELECT
TO authenticated
USING (company_id = app_private.current_user_company_id());

DROP POLICY IF EXISTS purchase_return_details_company
ON public.purchase_return_details;

CREATE POLICY purchase_return_details_company
ON public.purchase_return_details
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.purchase_returns r
    WHERE r.id = purchase_return_details.return_id
      AND r.company_id = app_private.current_user_company_id()
  )
);

COMMIT;
```

### 2) Preflight إلزامي قبل تطبيق Migration

- إعادة استعلام المنح الفعلية بعد تحديد grantee بما فيه PUBLIC وanon وauthenticated وservice_role.
- التحقق من relrowsecurity وrelforcerowsecurity للجدولين.
- إعادة فحص جميع مستهلكي Purchase Return خارج مجلد company-1، وأي تكامل أو تقرير أو تطبيق يكتب مباشرة.
- إثبات أن عمليات الإنشاء/التعديل/الترحيل/الإلغاء تمر عبر save-purchase-order v22 فقط، ولا تحتاج Client DML.
- حفظ تعريف السياستين والمنح الحالية Snapshot مستقلًا للـrollback.
- التأكد من أن قراءات Parent وBuyer وwarehouse/vouchers لا تتعطل.

### 3) Rollback محدد — لا يستخدم إلا عند إثبات فشل بعد التغيير

```sql
BEGIN;

DROP POLICY IF EXISTS purchase_returns_company
ON public.purchase_returns;

CREATE POLICY purchase_returns_company
ON public.purchase_returns
FOR ALL
TO public
USING (company_id = app_private.current_user_company_id())
WITH CHECK (company_id = app_private.current_user_company_id());

DROP POLICY IF EXISTS purchase_return_details_company
ON public.purchase_return_details;

CREATE POLICY purchase_return_details_company
ON public.purchase_return_details
FOR ALL
TO public
USING (
  EXISTS (
    SELECT 1
    FROM public.purchase_returns r
    WHERE r.id = purchase_return_details.return_id
      AND r.company_id = app_private.current_user_company_id()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.purchase_returns r
    WHERE r.id = purchase_return_details.return_id
      AND r.company_id = app_private.current_user_company_id()
  )
);

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, UPDATE
ON TABLE public.purchase_returns, public.purchase_return_details
TO anon, authenticated;

COMMIT;
```

هذا Rollback يعيد صلاحيات المنح والسياسات المسجلة قبل التغيير؛ لا يُستخدم لمجرد ظهور خطأ واجهة، بل بعد تحديد السبب والتأكد أن إعادة DML لا تعيد تجاوز الكاتب المركزي. إذا اختلف أي grant أو policy في Snapshot preflight، يجب تعديل rollback ليتطابق مع الـSnapshot الفعلي بدل تنفيذ هذا النص حرفيًا.

### 4) Acceptance بعد التغيير

1. anon: لا SELECT ولا DML على الجدولين.
2. authenticated: SELECT لبيانات الشركة المصرح بها فقط.
3. authenticated: INSERT/UPDATE/DELETE/TRIGGER/REFERENCES مرفوضة مباشرة.
4. service_role: لا تتغير صلاحياته السابقة؛ عمليات بوابة المشتريات تستمر.
5. اختبارات CREATE_RETURN وPOST_RETURN وCANCEL_DOCUMENT مع idempotency وrejection paths.
6. لا تتغير stock_branches أو inventory_log أو supplier_ledger أو journal_entries أو cash_box عند فشل أي عملية.
7. Company/branch negative tests وقراءة Parent وBuyer وwarehouse/vouchers.

**قرار التنفيذ:** هذه الحزمة لم تُنفذ. يلزم اعتماد المالك الصريح لهذا النص المحدد وفق Master CTO §77.2 قبل Migration أو أي تغيير Production.