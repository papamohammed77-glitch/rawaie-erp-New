# Report86 — Main7 Forensic Surgery and Main2 Assembly Path — 2026-09-08

## 1. نطاق الجلسة
الهدف كان استرجاع آخر حالة من المصادر الأصلية، إعادة مطابقة Production، تصحيح مسار reconstruction إلى `Current/PWA/main2`, ثم إجراء forensic review كامل لـ`Current/PWA/main2/main7.md` وتوثيق الجراحات المطلوبة دون أن يقوم المساعد بتعديل ملف Main7 نفسه، التزامًا بقاعدة ملكية الملف الأم.

## 2. المصادر المقروءة
- `doc/Draft/medhat/MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP.md`
- `CURRENT_STATE.md` قبل الجلسة
- `doc/Draft/Reprots/Report85_Main6_Recheck_and_Assembly_Boundary_20260908.md`
- `Current/PWA/main2/main7.md` من Git الحالي
- `tools/run_final_main_reconstruction_20260831.py`
- `.github/workflows/forensic_main_assembly.yml`
- تاريخ Git الخاص بـMAIN7 وملفات reconstruction ذات العلاقة
- Production Supabase functions / schema / edge deployments

## 3. Production checkpoint — نفس لحظة التقرير
Production project: `fiilmooggumokxanwiyx`

وقت اللقطة:
`2026-09-08 06:12:44.498422+00`

النتيجة:
- companies: 1
- branches: 2
- users: 24
- items: 17
- stock_branches: 20
- orders: 0
- purchase_orders: 0
- stock_vouchers: 0
- inventory_log: 3

لا توجد Orders أو Purchase Orders أو Stock Vouchers تشغيلية دائمة في Production تسمح باختبار دورة أعمال كاملة دون fixture transactional.

## 4. أهم ما تم إثباته من Production
### 4.1 Physical Stock Writer boundary
المسح الجنائي للدوال الحالية أثبت أن الـdirect physical writers خارج المحركات المسموح بها = 0.

المسموح:
- `post_stock_movement` — Physical Stock Engine.
- `reserve_stock` / `release_stock_reservation` — Reservation only.
- `setup_van_stock` / `create_vehicle_atomic` — initialization of stock rows, وليس حركة مخزنية تشغيلية.

كما أن `complete_runsheet_picking` يغيّر fulfillment quantities وreservation فقط، ولا ينفذ `stock_branches.qty` movement مستقلًا.

### 4.2 Legacy core capabilities
تم إغلاق صلاحية التنفيذ في Production للـlegacy cores:
- `post_manual_stock_voucher_atomic_core_20260828`
- `send_stock_voucher_atomic_core_20260828`

تم التنفيذ عبر migration:
`revoke_legacy_inventory_core_execution_20260908`

لا تزال الـcanonical functions الحالية قابلة للاستخدام، ولا تم حذف الـlegacy definitions حتى يبقى التاريخ محفوظًا.

### 4.3 Current Return / Delivery contracts
`complete-return` Production v25 حاليًا wrapper إلى `complete_return_atomic`، و`complete_return_atomic` يمرر Physical Return عبر `post_stock_movement`.

`complete-order-delivery` Production v14 wrapper إلى `complete_order_delivery_atomic`، وDelivery يغيّر operational fulfillment state فقط؛ الـPhysical Stock تم ترحيله عند Loading.

## 5. Assembly boundary correction
Report85 أثبت أن reconstruction القديم كان يعتمد:
`Current/PWA/main/*`

بينما مصدر العمل الذي حدده المستخدم هو:
`Current/PWA/main2/main1.md ... main11.md`

تم تنفيذ التصحيح في Git:
1. `tools/run_final_main_reconstruction_20260831.py`
   - `CUR` أصبح `Current/PWA/main2`.
   - `PARTS` أصبحت مبنية من `main2/main1..main11`.
2. `.github/workflows/forensic_main_assembly.yml`
   - trigger path أصبح `Current/PWA/main2/**`.
   - canonical source assertion أصبح `main2`.
   - deep source audit أصبح يقارن `Current/PWA/main2/*` مع `Original/PWA/main/*` التاريخي.
   - حالة `Current/PWA/main/*` لم تعد Source of Truth.
3. الـworkflow persistence message أصبح يسجل صراحة أن `main2` هو canonical editable source وأن `New-main` هو generated target.

Git commits الناتجة عن هذا التصحيح:
- `97968baccaa20f42888506b1bc0e1fb5bd1c278d`
- `cd1f022d945ca62bb7668afe78027ea6d7bdcb52`
- `27740512c1da8531869e0a31cc6cee1575c25635`

## 6. CI execution result
تم إطلاق execution باستخدام `[CTO_EXECUTE_P163]` للتحقق الفعلي من المسار الجديد.

الـpush فعّل Workflow آخر موجود تاريخيًا باسم:
`CTO Single Controlled New-main UX 2026-09-03`

الـrun:
`34193895898`

والنتيجة:
`failure`

لم ينتج عن endpoint الـJobs أي Jobs قابلة للفحص (`total_count=0`) في نتيجة API الحالية؛ لذلك لا يوجد دليل كافٍ لإعلان assembly/runtime pass.

الاستنتاج الصحيح:
`MAIN2 SOURCE PATH = CORRECTED IN GIT`
لكن:
`FULL MAIN2 ASSEMBLY = NOT PROVEN CLOSED`
وذلك لأن الـgenerated target وbrowser runtime لم يحصل لهما verification ناجح مثبت من الـrun الحالي.

## 7. Main7 forensic result
الـblob الحالي لـ`Current/PWA/main2/main7.md`:
`6f7aef60ac137cd7f6b74281a17835dbd29595be`

تمت قراءة الملف من بدايته حتى نهايته، وتمت مطابقة الأجزاء الحرجة مع Production current contracts وتاريخ Git.

## 8. Main7 defects proven in source
### M7-01 — Receiving query company scope
`loadReceiving()` يقرأ `receiving` بدون company scope.

### M7-02 — Receiving details scope
`_showReceivingDetails()` يعتمد operation id فقط. بما أن `receiving.operation_id` UNIQUE فهذا ليس identity collision بحد ذاته، لكنه يحتاج company validation إذا كان UI runtime يعتمد tenant context.

### M7-03 — Drivers lookup
`_loadVoucherEntityOptions()` عند `DirectSale/DirectReturn` يقرأ users حسب role فقط دون company scope.

### M7-04 — Vouchers list scope
`loadVouchers()` يقرأ `stock_vouchers` بدون `company_id`.

### M7-05 — Voucher details scope
`_viewVoucherDetails()` يقرأ `stock_voucher_details` بـ`voucher_code` فقط، مع أن `stock_vouchers.voucher_code` UNIQUE داخل الشركة وليس عالميًا.

### M7-06 — Receive idempotency
`_receiveVoucher()` لا يرسل `operation_id` ولا `Idempotency-Key`، رغم أن Production `receive-stock-voucher` و`post_manual_stock_voucher_atomic` يدعمان operation identity للاستلام الجزئي/إعادة المحاولة.

### M7-07 — Empty Voucher creation
`_openNewVoucherModal()` يحاول إنشاء Voucher بـ`items: []`. هذا يتعارض مع عقد الإنشاء الذي يتطلب صنفًا واحدًا على الأقل في المسار canonical.

### M7-08 — Lifecycle status drift
في `loadPicking/loadLoading/loadDelivery/loadReturn` تظهر حالات قديمة:
- `Picked`
- `Loaded`
- `Delivered`
- `Returned`

التاريخ التنفيذي المثبت للـMAIN7 target repair يحدد داخل fragment operational views الحالات:
- `Picking`
- `Loading`
- `Delivering`
- `Returning`

### M7-09 — Delivery payload is semantically wrong
`_openDeliveryModal()` يبني `ordersData` ويعطي لكل Order كامل `run_sheet_details.qty_loaded` لجميع الأصناف.

هذا لا يطابق Production contract الحالي:
`complete-order-delivery` يعالج Order واحدًا (`order_code`) ويطبق quantities على `order_details` لذلك الـOrder فقط.

ثم `complete-delivery` يغيّر Runsheet state إلى `Delivered` فقط، ولا يعالج Order delivery quantities.

وبالتالي payload الحالي قد يسبب misallocation/duplicate fulfillment logic ويجب استبداله بمسار:
`Order -> complete-order-delivery -> ثم complete-delivery`.

### M7-10 — Settlement counted quantity
`_onSettlementRsChange()` يهيئ `countedQty: 0` ولا يربطه فعليًا بنتيجة Inventory Count.

لا يتم اعتبار هذا BUG production-critical الآن لأن contract الخاص بمصدر counted quantity لم يُثبت في هذا الملف وحده؛ يحتاج ربطًا بتاريخ save-inventory-count قبل فرض تعديل نهائي.

### M7-11 — Unloading UI
`_showUnloadingDetails()` يقول صراحة `التفاصيل قيد التطوير`.

لم يتم تحويله تلقائيًا إلى سلوك جديد لأن هذا يحتاج Business Contract واضحًا لـUnloading UI، مع أن Production `post_stock_movement` يدعم Unloading بوجود source+target وidempotency.

## 9. Main7 source surgery instructions to owner
لا يتم تعديل `main7.md` بواسطة المساعد.

التعليمات الجراحية الكاملة التي يجب تنفيذها يدويًا هي في هذه الجلسة/التقرير:
- M7-01 إلى M7-09 إلزامية قبل assembly.
- M7-10 وM7-11 تبقيان OPEN إلى حين إثبات contract التاريخي/Production.

## 10. What was not done
- لم يتم تعديل `Current/PWA/main2/main7.md` مباشرة، التزامًا بقاعدة ownership.
- لم يتم نشر Parent PWA إلى Production.
- لم يتم إعلان Gold/Diamond.
- لم يتم إجراء fixture دائم في Production.

## 11. Failure memory
### Failure A
تم إطلاق CI من commit `[CTO_EXECUTE_P163]`، لكن Workflow تاريخي آخر على `main` انتهى `failure` دون Jobs قابلة للفحص في API.

### Root assessment
لا يوجد دليل كافٍ لتحديد أن failure سببه MAIN2 reconstruction نفسه؛ لذلك تم منع الاستنتاج السببي.

## 12. Final Self-Audit
### What I proved
- Production current snapshot matched immediately before execution.
- Physical Stock direct writers outside allowed set = 0.
- Legacy manual/send inventory cores are no longer executable.
- `complete-return` current Production is centralized.
- `Current/PWA/main2` is now the configured canonical source in the reconstruction tool/workflow.
- Main7 has concrete source defects listed above, including a major delivery semantic defect.

### What I did not prove
- Successful full reconstruction from all 11 `main2` fragments.
- Browser runtime pass of generated target after this source correction.
- Production deployment of a Main2-generated parent.
- Main7 source closure after owner surgery.
- Final real-world E2E of picking/loading/delivery/return because Production has no operational fixture data.

### Current closure
`PRODUCTION INVENTORY WRITER CORE = CLOSED`
`LEGACY INVENTORY CORE EXECUTION = CLOSED`
`MAIN2 RECONSTRUCTION SOURCE PATH = CLOSED`
`FULL MAIN2 ASSEMBLY = OPEN / CI VERIFICATION FAILED`
`MAIN7 SOURCE SURGERY = OPEN / OWNER ACTION REQUIRED`
`PARENT GOLD/DIAMOND = NOT CLOSED`
