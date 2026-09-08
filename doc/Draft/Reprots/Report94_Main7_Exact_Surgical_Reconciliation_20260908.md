# Report94 — Main7 Exact Surgical Reconciliation — 2026-09-08

## 1. الغرض
إعادة فحص `Current/PWA/main2/main7.md` من Git مباشرة، بعد Report93، مع مطابقة Production الحالية قبل أي قرار، ثم تحديد الجراحات المتبقية فقط.

## 2. مصادر تم فحصها
- `doc/Draft/medhat/MASTER - RAWAEA ERP.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`
- `doc/Draft/medhat/تقرير مبادئ حاكمة`
- `doc/Draft/medhat/برومبت استكمال مهام`
- `CURRENT_STATE.md`
- Report87 / Report88 / Report89 / Report90 / Report91 / Report92 / Report93
- `.github/workflows/forensic_main_assembly.yml`
- `Current/PWA/main2/main7.md`
- `Current/PWA/driver.html`
- Production Supabase الحالية.

## 3. أهم نتيجة في إعادة المطابقة
Report93 كان يشير إلى SHA أقدم. المصدر الحالي المباشر لـ `Current/PWA/main2/main7.md` هو:

`d6ee5ed58faf82d23bd8d0ab73f70d5979d41f19`

وآخر commit مخصص لتحديث Main7 الظاهر في التاريخ هو:

`bf9baf2571790e9000a7db99ca93bf250d07c9e6`

بتاريخ 2026-09-08 11:24:34 UTC.

وبالتالي تم اعتماد `d6ee...` كهوية المصدر الحالي، وليس SHA الموجود في CURRENT_STATE/Report93.

## 4. Production snapshot — مطابقة مباشرة
وقت الفحص:
`2026-09-08 12:45:30.904425+00 UTC`

- companies = 1
- branches = 2
- users = 24
- items = 17
- stock_branches = 20
- orders = 0
- order_details = 0
- runsheets = 0
- run_sheet_details = 0
- stock_vouchers = 0
- inventory_log = 3
- inventory_counts = 0
- inventory_count_details = 0

## 5. Production contracts التي تم التحقق منها
- `post_stock_movement` موجود بتوقيع 10 معاملات idempotent، إضافة إلى overload أقدم 9 معاملات.
- `post_inventory_adjustment_atomic` يفوض Physical Movement إلى `post_stock_movement`.
- `post_manual_stock_voucher_atomic` يفوض Physical Movement إلى core الذي يفوضه إلى `post_stock_movement`.
- `send_stock_voucher_atomic` يفوض Physical Movement إلى core.
- `complete_runsheet_loading` يستخدم `post_stock_movement` للحركة الفعلية.
- `complete_order_delivery_atomic` يعمل على Order واحد.
- `complete_return_atomic` يعمل بسياق company + runsheet/order ويستخدم `post_stock_movement` عند إعادة المخزون.
- `receive_purchase_atomic` الحالي يقبل `p_operation_id uuid` ويستخدم `receiving.operation_id` كهوية عملية idempotent.
- `create_manual_stock_voucher_atomic` لديه overload حديث من 12 معاملًا يشمل `p_rep_id` و`p_operation_id`.
- `items.item_code` لديه `UNIQUE` عالمي في Production.
- `receiving.operation_id` لديه `UNIQUE`.

## 6. Delivery contract — محمي ولا تغيير
التاريخ والـProduction يثبتان:
`Open / Confirmed → Picking → Picked → Loading → Loaded → Delivering → Delivered → Returning → Returned`

ولا يوجد أي مبرر لتغيير `Picked` إلى `Picking` أو `Loaded` إلى `Loading` أو أي تبديل مشابه.

`driver.html` يستخدم Delivery Order-by-Order عبر `runsheet_code + order_code`، وMain7 الحالي يحتوي بالفعل النسخة الصحيحة من `_openDeliveryModal(rsCode)` التي تبدأ Delivery مرة واحدة ثم تعالج Orders واحدًا واحدًا، وبعدها تغلق Runsheet.

## 7. ما ثبت أنه مطبق بالفعل في Main7 الحالي — لا تعاد طلبه
- `voucherReference` موجود في `loadVoucherForm(type)`.
- `_openDeliveryModal(rsCode)` Order-by-Order موجود.
- Receiving company scope موجود.
- Receiving details company validation موجود.
- Voucher list/details company scoped.
- Receive remaining quantity + `Idempotency-Key` + `operation_id` موجودة.
- `_openNewVoucherModal()` يوجه إلى `loadVoucherForm()`.
- Picking تستخدم `Open / Confirmed`.
- `loadSettlement()` company scoped.
- `_onSettlementRsChange()` في النسخة الحالية يستخدم `order_id` للوصول إلى `order_details`، و`voucher_id` للوصول إلى `stock_voucher_details`، ويحدد `vehicle.mobile_branch_id || vehicle.id` ثم آخر `inventory_counts`.
- `_saveVehicleCount()` يمر عبر `users.id` ثم `vehicles.id` ويستخدم `runsheets.vehicle_id` عند وجود Runsheet.
- `_saveGeneralCount()` يحل `main_branch_id` داخل Company Scope.
- `loadPicking()` و`_showPickingDetails()` و`loadVehicleCount()` و`_searchDriver()` و`loadUnloading()` و`loadLoading()` و`loadDelivery()` و`loadReturn()` تحتوي على Company Scope.
- `_showDeliveryDetails()` و`_showReturnDetails()` تحتويان على Company Scope.
- `_loadVoucherEntityOptions(type)` الحالي يستخدم UUIDs ومصادر Company Scope، وDirectSale يربط المركبات بمستخدمي `مندوب بيع مباشر`.
- `_saveAndSendVoucher()` الحالي يرسل `rep_id` لسيناريو DirectSale ويستخدم `main_branch_id` وUUIDs.

## 8. الجراحات المتبقية المؤكدة فقط
### M7-15A — `loadVoucherForm(type)` config
المواضع الحالية: **السطر 126 إلى السطر 129**.

ابحث عن السطور الأربعة الكاملة التالية داخل `var configs = {`:

`'Transfer':      { title: 'تحويل مخزني', entityLabel: 'الفرع المحول إليه', showPrice: false, fromType: 'Branch', fromId: 'null', toType: 'Branch', toId: '', endpoint: 'save-voucher' },`

`'DirectSale':    { title: 'صرف سيارة بيع مباشر', entityLabel: 'المندوب / السيارة', showPrice: true, fromType: 'Branch', fromId: 'null', toType: 'Vehicle', toId: '', endpoint: 'save-voucher' },`

`'DirectReturn':  { title: 'استلام مرتجع سيارة', entityLabel: 'المندوب / السيارة', showPrice: true, fromType: 'Vehicle', fromId: '', toType: 'Branch', toId: 'null', endpoint: 'save-voucher' },`

`'SupplierReturn':{ title: 'مرتجع لمورد', entityLabel: 'المورد', showPrice: true, fromType: 'Branch', fromId: 'null', toType: 'Supplier', toId: '', endpoint: 'save-voucher' }`

احذف السطور الأربعة واستبدلها حرفيًا بـ:

```javascript
            'Transfer':      { title: 'تحويل مخزني', entityLabel: 'الفرع المحول إليه', showPrice: false, fromType: 'Branch', fromId: null, toType: 'Branch', toId: null, endpoint: 'save-voucher' },
            'DirectSale':    { title: 'صرف سيارة بيع مباشر', entityLabel: 'المندوب / السيارة', showPrice: true, fromType: 'Branch', fromId: null, toType: 'Vehicle', toId: null, endpoint: 'save-voucher' },
            'DirectReturn':  { title: 'استلام مرتجع سيارة', entityLabel: 'المندوب / السيارة', showPrice: true, fromType: 'Vehicle', fromId: null, toType: 'Branch', toId: null, endpoint: 'save-voucher' },
            'SupplierReturn':{ title: 'مرتجع لمورد', entityLabel: 'المورد', showPrice: true, fromType: 'Branch', fromId: null, toType: 'Supplier', toId: null, endpoint: 'save-voucher' }
```

هذا تنظيف نوعي فقط؛ لا يغير Business Flow ولا آلية إنشاء/إرسال الإذن.

### M7-14 — `_showLoadingDetails(code)`
الدالة تبدأ حاليًا في **السطر 762** وتنتهي في **السطر 772**.

ابحث عن بداية الدالة كاملة:
```javascript
    async function _showLoadingDetails(code) {
```

احذف الدالة كاملة حتى القوس `}` الذي ينتهي مباشرة قبل التعليق الكامل:
```text
    // ==================== DELIVERY ====================
```

واستبدلها كاملة بـ:

```javascript
    async function _showLoadingDetails(code) {
        showLoader('جاري التحميل...');

        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
        if (!companyId) {
            hideLoader();
            showToast('سياق الشركة غير محدد', 'error');
            return;
        }

        try {
            var rsRes = await supabase.from('runsheets')
                .select('id')
                .eq('company_id', companyId)
                .eq('runsheet_code', code)
                .maybeSingle();

            if (rsRes.error) throw rsRes.error;
            if (!rsRes.data) {
                hideLoader();
                showToast('الرانشيت غير موجود في الشركة الحالية', 'error');
                return;
            }

            var itemsRes = await supabase.from('run_sheet_details')
                .select('*')
                .eq('runsheet_id', rsRes.data.id);

            if (itemsRes.error) throw itemsRes.error;

            hideLoader();

            var items = itemsRes.data || [];
            if (!items.length) {
                showToast('لا توجد أصناف', 'info');
                return;
            }

            var h = '<div class="text-right"><table class="w-full border"><thead class="bg-slate-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الكمية المحضّرة</th><th class="p-2 text-center">الكمية المحمّلة</th></tr></thead><tbody>';
            items.forEach(it => {
                h += '<tr><td class="p-2 font-bold">' + (it.item_name||'') + '</td><td class="p-2 text-center">' + (it.qty_picked||0) + '</td><td class="p-2 text-center font-bold text-orange-600">' + (it.qty_loaded||0) + '</td></tr>';
            });
            h += '</tbody></table></div>';

            Swal.fire({
                title: 'تفاصيل التحميل: ' + code,
                html: h,
                width: '700px',
                showCloseButton: true,
                showConfirmButton: false
            });
        } catch (e) {
            hideLoader();
            showToast('فشل تحميل تفاصيل التحميل: ' + (e.message || ''), 'error');
        }
    }
```

## 9. ما لم يتم تغييره
- `Current/PWA/main2/main7.md` لم يكتب فيه المساعد أي تغيير.
- `driver.html` لم يتغير.
- `_openDeliveryModal(rsCode)` لم يتغير.
- lifecycle labels لم تتغير.
- `_showUnloadingDetails()` لم يتغير.
- `.github/workflows/forensic_main_assembly.yml` لم يتغير.
- Production لم تُعدّل في هذه الجلسة، لأن العقود المطلوبة لـMain7 كانت صحيحة بالفعل عند التحقق المباشر.

## 10. Assembly decision
Assembly **لم يبدأ** عمدًا.

السبب الوحيد: `main7.md` ما زال عند SHA `d6ee5ed58faf82d23bd8d0ab73f70d5979d41f19` ولم تُطبق بعد الجراحتان اليدويتان M7-15A وM7-14.

تشغيل Assembly الآن سيعني بناء `New-main` من مصدر معروف أنه ما زال يحتوي على العيب المؤكد في `_showLoadingDetails()` وبقايا string sentinel `'null'`.

بعد تطبيق الجراحتين فقط، تصبح الخطوة التالية:
`READ main7 FROM SOF → EOF → syntax/integrity recheck → full main2 reconstruction → integration checks → production verification`.

## 11. Self-Audit
### What I Proved
- مصدر Main7 الحالي الحقيقي هو `d6ee5ed58faf82d23bd8d0ab73f70d5979d41f19`.
- Report93/CURRENT_STATE كانا يحملان SHA أقدم.
- Delivery Order-by-Order contract محفوظ.
- Physical Stock ownership محفوظ ومركزي.
- Production contracts اللازمة لـMain7 موجودة ومتوافقة.
- معظم الجراحات السابقة أصبحت مطبقة بالفعل، ولا ينبغي تكرارها.
- بقي عنصران فقط في Main7 الحالي يحتاجان تدخل المالك.

### What I Did Not Prove
- لم يثبت Assembly النهائي لأن Main7 لم يُحدّث بعد.
- لم يثبت Runtime end-to-end للتوصيل/الجرد لعدم وجود Runsheet/Orders تشغيلية في Production الحالية.
- لم يثبت Gold/Diamond النهائي للـParent.

### Final Status
`PRODUCTION INVENTORY WRITER CORE = CLOSED / VERIFIED`
`DELIVERY CONTRACT = PROTECTED`
`MAIN7 FORENSIC RECHECK = COMPLETE`
`MAIN7 OWNER SURGERY = 2 EXACT ITEMS PENDING`
`MAIN2 ASSEMBLY = BLOCKED BY OWNER PATCHES`
`PARENT GOLD/DIAMOND = NOT YET CLOSED`
