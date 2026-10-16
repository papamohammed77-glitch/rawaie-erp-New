# Report426 — مراجعة POS الجنائية وإصلاح عقد الفرع والعميل النقدي — 2026-10-16

## PRE-CHANGE SELF-AUDIT

**Business Understanding:** الكاشير موظف تنفيذي؛ لا يختار الفرع بحرية، ولا يحوّل عملية POS النقدية إلى بيع آجل أو يربطها بعميل حسابي من خلال تعديل طلب HTTP. يجب أن يظل بيع POS داخل الشركة والفرع المعيّن، وأن تظل حركة المخزون والحسابات من خلال عقد البيع المركزي الموجود.

**Architecture Understanding:** POS PWA → `save-sales-invoice` (JWT) → `service_role` → `save_sales_invoice_atomic` → مخزون/مبيعات/نقدية/قيود. لم أضف Edge Function جديدة ولم أمنح الواجهة صلاحية تنفيذ Core مباشرة.

**Database Understanding:** Production يحتوي `users.default_branch_id` و`users.allowed_branch_ids`، ودالة `get_pos_branches()` ترجع الفروع المسموح بها فقط. `save_sales_invoice_atomic(jsonb,jsonb,text,text)` ما زالت `service_role` فقط.

**Historical Understanding:** راجعت POS التاريخي `rawaie-erp-review/PWA/sales/pos.html`، SHA `6ad4da791b72260b922847246ebce93b552d2bad`، وتقارير Report421–Report425 وADR إدارة الورديات بوصفها أدلة تاريخية، ثم طابقت النتائج مع المصدر الحالي وProduction.

**Production Understanding:** فحصت تعريفات RPC والـACL وبيانات المستخدم والفروع، ثم نشرت تحديثًا على Edge القائمة وأعدت جلبها من Production.

**Current Understanding:** أحدث مصدر POS المقروء هو `erp-frontend/companies/company-1/sales/pos.html`، SHA `5f2ad2fa52c2c63d9e307cbaa27f6455351f738d`، 111,290 حرفًا / 1,904 أسطر. أحدث commit ظاهر في سجل المستودع هو `6f30e2d78aa824ed92a5b3a0607edc8cb68ea9dc` (إضافة تبويب «خزينتي»). ملف POS و`main.html` لم أعدّلهما.

**Execution Confidence:** مرتفع في فحص المصدر وProduction وتحديث Edge؛ غير كافٍ لإعلان إغلاق E2E لأن جلسة Browser/JWT لكاشير حقيقي لم تكن متاحة لهذه الدورة.

### Confirmed Facts

- المستخدم الإنتاجي `cashier@rawaea.com` نشط، صلاحية `pos`، الشركة `00000000-0000-0000-0000-000000000001`.
- `default_branch_id = NULL`، و`allowed_branch_ids = "BR-01"`. إذن الفرع المعيّن الوحيد المثبت حاليًا هو `BR-01`.
- `BR-01` هو «الفرع الرئيسي»، نشط، ومعرّفه `a38332b6-6cea-480a-ada1-6eb6ab0590db`.
- Production `get_pos_branches()` و`get_pos_bootstrap_data()` يتحققان من سياق المستخدم والصلاحية والشركة، لكن واجهة POS الحالية ما زالت تعرض عنصر اختيار الفرع.
- قبل الإصلاح، `save-sales-invoice` كان يتحقق من وجود الفرع داخل الشركة، لكنه لم يطبق `branchAllowed(...)` على مصدر `pos`. لذلك كان يمكن تجاوز قيد الواجهة بإرسال فرع آخر داخل الشركة عبر طلب مباشر.
- قبل الإصلاح، Edge لم يفرض عقد «عميل نقدي + دفع نقدي» على الطلبات التي مصدرها `pos`؛ كان يعتمد على بيانات الواجهة. هذا ليس حدًا أمنيًا كافيًا.
- عينة فواتير POS الحالية في Production: `ORD-1004` و`ORD-1005` و`ORD-1006` مسجلة كـ`نقدي` وعميل عام بلا `customer_id` وعلى `BR-01`؛ التعديل الخادمي متوافق مع السلوك المرصود.
- لا توجد ورديات أو محطات أو أحداث وردية حالية في Production: `pos_shifts=0`، `pos_terminals=0`، `pos_shift_events=0`. لم أنشئ بيعًا أو مرتجعًا أو وردية تجريبية في بيانات Production.

### Unknowns / Conflicts / Unverified Claims

- **Conflict تم حسمه:** `CURRENT_STATE.md` كان يسجل SHA أقدم للـPOS `1c5ee4b...`؛ المصدر الحالي الذي أعاده GitHub في هذه الدورة هو `5f2ad2...`. تم اعتماد SHA الحالي، وسيُحدّث ملف الحالة.
- **UNVERIFIED:** تطابق ملف POS في Git مع النسخة المخدومة فعليًا على الاستضافة.
- **UNVERIFIED:** HTTP/Browser E2E بمصادقة كاشير بعد نشر Edge؛ لا أملك جلسة JWT مستخدم قابلة للاستعمال من أدوات هذه الدورة.
- **UNVERIFIED:** تطبيق المالك لتعديلات واجهة POS الواردة أدناه؛ لم أكتب إلى ملف التطبيق التشغيلي وفق توزيع الأدوار.

## 1. التغيير الفعلي المنفذ

### Production Edge Function

- Function: `save-sales-invoice`
- قبل التعديل: v18، `verify_jwt=true`
- بعد التعديل: **v19 ACTIVE**، `verify_jwt=true`
- Production `ezbr_sha256`: `bdbe8fdeed5e3b7344241c07193d52cbec46bf8f58bf8d1ab443ee885065fd1f`
- مصدر Git الرسمي: `Current/Edge_Functions/save-sales-invoice`
- Git commit: `622ab42fbc96307f76fb074ae699f95a0c4de4c8`
- Git blob SHA بعد التحديث: `2a90d34d1c7d3ae63a51e1cf3f2bb43ee6bdc5bc`
- بعد النشر، أعدت جلب Function من Production وتحققت أن محتوى `index.ts` مطابق حرفيًا لمحتوى ملف Git الحالي؛ عدد الأحرف 8,182 في المصدرين.

### التعديلات الخادمية

1. جلب الفرع أصبح يتضمن `is_active`، ويرفض الفرع غير النشط أو غير الموجود ضمن الشركة.
2. إذا كان مصدر العملية `pos` والمستخدم ليس Owner:
   - إذا كان `default_branch_id` موجودًا، يجب أن يطابق الفرع المطلوب حرفيًا.
   - إذا لم يوجد فرع افتراضي، يجب أن تكون `allowed_branch_ids` محددة بفرع واحد فقط، وأن يطابق معرّف الفرع أو رمزه ذلك التعيين.
   - لا يُقبل غياب التعيين أو تعدد الفروع المسموحة دون فرع افتراضي.
3. إذا كان `canonicalSource === 'pos'`، يفرض الخادم:
   - `customer_code = ''`
   - `custName = 'عميل نقدي'`
   - `area = ''`
   - `paymentType = 'نقدي'`
   - `deliveryFees = 0`
   - إزالة `customer_email` و`customer_phone` و`shipping_address` المرسلة من العميل.
4. بقيت هوية العملية `operation_id` ومناداة `save_sales_invoice_atomic` كما هما؛ لم يُستبدل محرك البيع المركزي.
5. لم تُنشأ Edge Function جديدة، ولم تتغير صلاحيات Core. إعادة التحقق الحية أكدت:
   - `save_sales_invoice_atomic(jsonb,jsonb,text,text)`: `anon=false`, `authenticated=false`, `service_role=true`.
   - `get_pos_bootstrap_data()`, `get_pos_branches()`, `get_pos_invoice_data(text,text)`: متاحة لـ`authenticated` وليست لـ`anon`.
   - RPCs الوردية الثلاثة تبقى `authenticated=true`, `anon=false`، و`service_role=false`.

## 2. اختبارات التحقق المنفذة

| الاختبار | النتيجة |
|---|---|
| تطابق Current Edge وProduction v19 | PASS — تطابق حرفي بعد إعادة الجلب |
| `verify_jwt` بعد النشر | PASS — ما زال `true` |
| ACL لمحرك البيع المركزي | PASS — service_role فقط |
| الفرع الافتراضي المحدد | PASS — يطابق `default_branch_id` عند وجوده |
| فرع واحد مسموح دون default | PASS — يقبل التطابق الدقيق فقط |
| طلب فرع مختلف عن تعيين الكاشير | PASS في اختبار منطق ثابت محلي |
| قائمة فروع متعددة بلا default | PASS في اختبار منطق ثابت محلي — تُرفض |
| عدم وجود أي تعيين | PASS في اختبار منطق ثابت محلي — يُرفض |
| بيانات Production بعد النشر | PASS — الطلبات 9، الورديات 0، المحطات 0، أحداث الورديات 0؛ لم تُضف بيانات اختبار |
| HTTP E2E بمصادقة كاشير | UNVERIFIED — لا توجد جلسة JWT/Browser متاحة؛ لم أختلق نتيجة تشغيل |

اختبارات منطق التعيين المحلية الخمسة نجحت جميعها. هذه اختبارات منطقية للشرط وليست بديلًا عن HTTP E2E.

## 3. التعديل الجراحي المطلوب من المالك — ملف POS فقط

**الملف:** `erp-frontend/companies/company-1/sales/pos.html`  
**SHA الذي يجب أن يطابقه المالك قبل التعديل:** `5f2ad2fa52c2c63d9e307cbaa27f6455351f738d`  
**لا تعدّل `main.html`. لا تطبق أي جزء إذا تغيّر SHA قبل بدء الاستبدال؛ أعد قراءة المصدر الحالي أولًا.**

### Patch A — تثبيت حقل العميل النقدي

**الموضع:** السطر 86، عنصر `select#posCustSelect`.

ابحث عن هذا السطر كاملًا واحذفه:

```html
                    <div class="relative flex-1"><select id="posCustSelect" onchange="POS.onCustomerChange()" class="w-full p-2.5 bg-slate-800 border border-slate-600 rounded-lg text-sm font-bold text-white appearance-none"><option value="">👤 عميل نقدي (عام)</option></select></div>
```

واستبدله كاملًا بهذا:

```html
                    <div class="relative flex-1"><select id="posCustSelect" disabled aria-label="عميل نقدي ثابت" onchange="POS.onCustomerChange()" class="w-full p-2.5 bg-slate-800 border border-slate-600 rounded-lg text-sm font-bold text-white appearance-none opacity-80 cursor-not-allowed"><option value="">👤 عميل نقدي (عام)</option></select></div>
```

### Patch B — منع اختيار الفرع قبل تحميل التعيين

**الموضع:** السطر 87، عنصر `select#posBranchSel`.

ابحث عن هذا السطر كاملًا واحذفه:

```html
                    <div class="relative w-40"><select id="posBranchSel" onchange="POS.onBranchChange()" class="w-full p-2.5 bg-slate-800 border border-slate-600 rounded-lg text-sm font-bold text-white appearance-none"><option value="">🏭 اختر الفرع</option></select></div>
```

واستبدله كاملًا بهذا:

```html
                    <div class="relative w-40"><select id="posBranchSel" disabled aria-label="الفرع المرتبط بالكاشير" onchange="POS.onBranchChange()" class="w-full p-2.5 bg-slate-800 border border-slate-600 rounded-lg text-sm font-bold text-white appearance-none opacity-80 cursor-not-allowed"><option value="">🏭 جارٍ تحميل فرع المستخدم</option></select></div>
```

تقوم الدالة التالية بفتح الاختيار للـOwner فقط، وتثبيت الفرع للمستخدم التنفيذي.

### Patch C — استبدال `self.loadBranches` بالكامل

**الموضع:** الدالة التي تبدأ عند السطر 623 وتنتهي عند السطر 635.  
ابحث عن `self.loadBranches = function() {` واحذف الدالة كاملة حتى `};` التي تغلقها، ثم استبدلها كاملة بالنص التالي:

```javascript
    self.loadBranches = function() {
        var s = RW_UI.byId('posBranchSel');
        if (!db || !s) {
            if (s) {
                s.disabled = true;
                RW_UI.safeHTML(s, '<option value="">🏭 تعذر تحميل الفروع</option>');
            }
            return;
        }

        db.branches.toArray().then(function(br) {
            branchMap = {};

            var isOwner = !!(currentUser && (
                currentUser.isOwner === true ||
                (Array.isArray(currentUser.permissions) && currentUser.permissions.indexOf('*') !== -1)
            ));
            var defaultBranchId = currentUser && currentUser.defaultBranchId
                ? String(currentUser.defaultBranchId) : '';
            var rawAllowed = currentUser ? currentUser.allowedBranchIds : null;
            var assignedBranches = Array.isArray(rawAllowed)
                ? rawAllowed.map(function(x) { return String(x).trim(); }).filter(Boolean)
                : (typeof rawAllowed === 'string' && rawAllowed.trim()
                    ? [rawAllowed.trim()] : []);
            var assigned = null;
            var i;

            for (i = 0; i < br.length; i++) {
                branchMap[br[i].branch_code] = br[i].id;
            }

            if (!isOwner) {
                if (defaultBranchId) {
                    for (i = 0; i < br.length; i++) {
                        if (String(br[i].id) === defaultBranchId) {
                            assigned = br[i];
                            break;
                        }
                    }
                } else if (assignedBranches.length === 1) {
                    for (i = 0; i < br.length; i++) {
                        if (String(br[i].id) === assignedBranches[0] ||
                            String(br[i].branch_code) === assignedBranches[0]) {
                            assigned = br[i];
                            break;
                        }
                    }
                }

                if (!assigned) {
                    selBranch = null;
                    s.disabled = true;
                    RW_UI.safeHTML(s, '<option value="">⚠️ راجع ربط فرع الكاشير في النظام الأم</option>');
                    var grid = RW_UI.byId('productsGrid');
                    if (grid) RW_UI.safeHTML(grid,
                        '<div class="col-span-full p-6 text-center text-amber-300 font-bold">لا يوجد فرع افتراضي واحد مؤكد لهذا المستخدم. راجع ربط الفرع في النظام الأم.</div>');
                    if (!self._branchAssignmentErrorShown) {
                        self._branchAssignmentErrorShown = true;
                        RW_UI.toast('لا يمكن البيع قبل تعيين فرع واحد للكاشير من النظام الأم', 'error');
                    }
                    return;
                }
            }

            var h = isOwner ? '<option value="">🏭 اختر الفرع</option>' : '';
            for (i = 0; i < br.length; i++) {
                h += '<option value="' + br[i].branch_code + '">' +
                    (br[i].name || br[i].branch_code) + '</option>';
            }
            RW_UI.safeHTML(s, h);

            if (isOwner) {
                s.disabled = false;
                if (selBranch && branchMap[selBranch]) {
                    s.value = selBranch;
                } else {
                    selBranch = '';
                    s.value = '';
                }
            } else {
                s.value = assigned.branch_code;
                s.disabled = true;
                selBranch = assigned.branch_code;
                self._branchAssignmentErrorShown = false;
            }

            self.renderProducts();
        }).catch(function(err) {
            s.disabled = true;
            selBranch = null;
            RW_UI.safeHTML(s, '<option value="">🏭 فشل تحميل الفرع المعين</option>');
            console.error('POS assigned-branch load failed:', err);
            RW_UI.toast('تعذر تأكيد فرع الكاشير؛ لم يتم فتح اختيار بديل', 'error');
        });
    };
```

### Patch D — استبدال `self.loadCustomers` بالكامل

**الموضع:** الدالة التي تبدأ عند السطر 637 وتنتهي عند السطر 644.  
احذف الدالة كاملة واستبدلها:

```javascript
    self.loadCustomers = function() {
        selCust = null;
        var s = RW_UI.byId('posCustSelect');

        if (s) {
            RW_UI.safeHTML(s, '<option value="">👤 عميل نقدي (عام)</option>');
            s.value = '';
            s.disabled = true;
            s.setAttribute('aria-label', 'عميل نقدي ثابت');
        }

        RW_UI.safeText(RW_UI.byId('cartCustName'), 'عميل نقدي (عام)');
        RW_UI.safeHTML(RW_UI.byId('cartCustDetails'), '');
    };
```

### Patch E — استبدال `self.onCustomerChange` بالكامل

**الموضع:** الدالة التي تبدأ عند السطر 646 وتنتهي عند السطر 653.  
احذف الدالة كاملة واستبدلها:

```javascript
    self.onCustomerChange = function() {
        selCust = null;
        var s = RW_UI.byId('posCustSelect');
        if (s) {
            s.value = '';
            s.disabled = true;
        }
        RW_UI.safeText(RW_UI.byId('cartCustName'), 'عميل نقدي (عام)');
        RW_UI.safeHTML(RW_UI.byId('cartCustDetails'), '');
    };
```

### Patch F — تثبيت العميل النقدي داخل حمولة البيع

**الموضع:** داخل `self.finalizeCheckout`، الأسطر 965–978.  
ابحث عن المقطع الذي يبدأ بـ`var custCode = selCust ? selCust.customer_code : '';` وينتهي بقوس `};` الخاص بكائن `hdr`، واحذفه كاملًا واستبدله:

```javascript
    var custCode = '';
    var custName = 'عميل نقدي';
    var hdr = {
        customer_code: '',
        custName: 'عميل نقدي',
        area: '',
        total: t.total,
        deliveryFees: 0,
        status: 'Invoiced',
        source: 'pos',
        paymentType: 'نقدي',
        taxAmount: 0,
        taxRate: 0
    };
```

لا تغيّر بقية `finalizeCheckout`، ولا تمسح منطق `operation_id` أو إعادة المحاولة.

## 4. Benchmark مختصر — ما يجب الحفاظ عليه وما ينقص

الموجود حاليًا في POS: بحث/باركود، تصنيفات، الأكثر مبيعًا واقتراحات، تعليق واستئناف الفاتورة، نقدي وحساب الباقي، إيصال، فواتير اليوم، مرتجع مربوط بالفاتورة الأصلية، فتح/إغلاق وردية وعدّ فئات النقد، ملخص X/Z وخزينة «خزينتي» بتحديث كل 5 ثوانٍ.

توضح وثائق الأنظمة المرجعية أن POS الاحترافي يتضمن أيضًا ضوابط الدرج/الوردية، التسويات النقدية، Paid In/Out وCash Pickup، سياسات مرتجع وصلاحيات مشرف، وتدفق Offline متين؛ كما يربط وسائل الدفع بحساباتها بدل تسجيلها شكليًا. المصادر الرسمية:
- Oracle Retail Xstore — Till Management: https://docs.oracle.com/en/industries/retail/retail-xstore-point-of-service/24.0/rpxmg/till-management.htm
- Microsoft Dynamics 365 Commerce — POS operations: https://learn.microsoft.com/en-us/dynamics365/commerce/pos-operations
- Microsoft Dynamics 365 Commerce — returns and refund policy: https://learn.microsoft.com/en-us/dynamics365/commerce/refund_policy_returns
- Microsoft Dynamics 365 Commerce — offline POS: https://learn.microsoft.com/en-us/dynamics365/commerce/dev-itpro/pos-offline-functionality
- Odoo POS — payment methods and accounting journals: https://www.odoo.com/documentation/19.0/applications/sales/point_of_sale/payment_methods.html

الفجوات التالية لا تُفعّل بواجهة شكلية ولا بقيود مالية مكررة:
1. تسليم عهدة الكاشير للمحاسب بإقرار استلام موثق.
2. اعتماد مشرف آمن ومحدود المحاولات للمرتجع، مفروض داخل Edge/Core.
3. Offline checkout حقيقي: حفظ محلي durable، operation identity، إعادة إرسال آمنة، منع التكرار، ومصالحة عند التعارض. وجود قارئ `pending_updates` وحده لا يثبت وجود كاتب/طابور Offline.
4. Paid In/Out وCash Pickup/Transfer عبر عقود الخزينة/السندات القائمة، لا عبر Ledger نقدي ثانٍ.
5. إلغاء/عكس فاتورة بعقد ذري يعكس المخزون والنقد والحسابات مرة واحدة.
6. تسوية البطاقة/المحفظة/المختلط مع حسابات وقنوات دفع معتمدة. تبقى هذه الخيارات معطلة حاليًا ولا يجوز اعتبارها مدعومة.
7. تعدد الخزائن حسب الفرع؛ Production المرصود لديه خزينة نشطة واحدة للشركة، ولا يجوز افتراض وجود خزينة لكل فرع.

## 5. SELF-AUDIT FINAL

**What I Proved**
- Current POS source and historical baseline were fetched directly.
- Production cashier profile and branch assignment were queried live.
- Confirmed the pre-change server gap for POS branch/customer/payment enforcement.
- Updated the existing Edge Function only; deployed v19 with JWT verification still enabled.
- Re-fetched Production Edge and verified exact content parity with the Git Current artifact.
- Verified that the Core sale RPC remains service_role-only and Production test-data counts did not increase.

**What I Did Not Prove**
- Served POS HTML parity with Git.
- Authenticated HTTP/Browser E2E after v19.
- Runtime verification of the owner-applied UI patches; they have not been applied by this assistant.
- Full closure of handover, supervisor approval, offline checkout, void, or non-cash settlements.

**What I Fixed**
- Server-side enforcement of the assigned branch for POS.
- Rejection of inactive branches.
- Server-side forcing of POS to the generic cash customer and cash payment contract.
- Git Current artifact and Production deployment synchronized.

**What I Initially Missed**
- The saved state SHA for POS was stale relative to the current Git source.
- The Edge branch allow-list guard excluded `pos` even though the bootstrap branch list was scoped.
- The cash-only assumption existed in the UI but was not enforced by the server contract.

**What Could Still Be Wrong**
- The hosted POS could still serve a different blob until the owner deploys the current UI.
- The new Edge contract has not yet been exercised through an authenticated HTTP sale in this session.
- If a cashier is configured with multiple allowed branches and no `default_branch_id`, sales now fail closed by design until the parent system assigns one default branch.

**Final Confidence:** High for Git/Production source, ACL, and server contract; not sufficient for full runtime closure.

**Final Closure Status:** `PRODUCTION EDGE v19 DEPLOYED + SOURCE-SYNCED / POS OWNER PATCH READY / AUTHENTICATED E2E OPEN / NOT 100% CLOSED`.

## تعليمات استئناف العمل

1. ابدأ دائمًا بإعادة جلب Production Edge الحالي، `CURRENT_STATE.md`، وPOS HTML من GitHub، ولا تعتمد على SHA هذا التقرير إذا تغيّر الفرع.
2. لا تعِد تنفيذ إصلاحات Report421–Report425 الموجودة بالفعل؛ افحص الـblob الحالي أولًا.
3. المالك يطبق Patches A–F فقط على `pos.html` إذا ظل SHA `5f2ad2fa52c2c63d9e307cbaa27f6455351f738d` مطابقًا.
4. بعد نشر واجهة POS، نفّذ اختبارًا معتمدًا بحساب كاشير: الفرع المعين فقط، العميل النقدي الثابت، وردية مفتوحة، بيع نقدي، إعادة محاولة بنفس `operation_id`، ورفض فرع مختلف/مصدر غير POS غير مصرح به.
5. لا تُنشئ بيانات بيع تجريبية في بيانات العملاء الحقيقية. استخدم Staging أو شركة اختبار معزولة، ثم أثبت أن البيانات التجريبية أزيلت.
6. لا تعلن الإغلاق حتى يتوفر HTTP E2E مصادق عليه، وتثبت هوية النسخة المخدومة، وتتحقق من المخزون والنقد والقيد المحاسبي وعدم التكرار.
