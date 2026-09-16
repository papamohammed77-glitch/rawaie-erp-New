# Report 209 — GLOBAL INVENTORY CORE INTEGRITY / MOTHER E2E FORENSIC

**التاريخ:** 2026-09-16  
**الحقيقة المعتمدة:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.  
**تنبيه حاكم:** التقارير السابقة استُخدمت للاسترشاد فقط، ولم تُعامل كحالة حالية.

## 1. نطاق التنفيذ

تم استئناف العمل من آخر حالة مثبتة، مع فحص مباشر للـfrontend الحالي، Git/parent، Production Supabase، Edge deployments، RPC definitions، schema/constraints، audit path، realtime publication، ثم تنفيذ الإصلاحات التي ثبتت ضرورتها فقط.

النظام الأم المعتمد:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

الأجزاء التاريخية `Current/PWA/main2/*` و`Original/PWA/main/*` وNew-main ليست Source of Truth.

## 2. Current Git / Parent

المستودع الحالي:
`papamohammed77-glitch/erp-frontend`

الفرع:
`main`

Current HEAD:
`e0c806e47a761561fc4177ffd2a4d9fc8d7d7dc9`

Direct parent:
`06468385d01bbddab4e078dc2fc24282cea43733`

الـHEAD الحالي غيّر Mother HTML فعليًا بإضافة `inventory-control` إلى Inventory menu وإضافة route إلى `RW_Warehouse.loadInventoryControl()`.

تمت مراجعة الـparent ولم يُعامل رقم HEAD وحده كدليل.

## 3. Mother Current Source

تمت قراءة المصدر الحالي والبحث عن consumers ومسارات المخزون.

ثبت وجود `RW_Warehouse` والعمليات:
`loadReceiving`, `loadVouchers`, `loadVoucherForm`, `loadPicking`, `loadLoading`, `loadDelivery`, `loadReturn`, `loadUnloading`, `loadVehicleCount`, `loadBranchCount`, `loadGeneralCount`, `loadSettlement`.

ثبت وجود route:
`if (view === 'inventory-control') { RW_Warehouse.loadInventoryControl(); return; }`

لكن البحث الحالي في نفس المصدر لم يجد تعريفًا تنفيذيًا مستقلًا لـ `loadInventoryControl()`؛ الموجود هو الاستدعاء فقط. لذلك **مسار Inventory Control الحالي غير مغلق وظيفيًا** حتى يثبت وجود implementation أو تتم إضافته جراحيًا في Mother بواسطة المالك.

لم يتم تعديل Mother HTML من جانبي.

لم يظهر في المصدر الحالي أثناء البحث:
`قيد التطوير`, `جاري التطوير`, `TODO`, `FIXME`.

## 4. Daftra Comparison — Warehouse / Inventory only

المقارنة استُخدمت لتحديد القدرات المطلوبة، لا لنسخ النظام الآخر.

المصادر الرسمية لـDaftra تُظهر قدرات تشمل:
- إدارة المنتجات والمشتريات ودورة الشراء والموردين وطلبات المخزون والجرد.
- إدارة متعددة المخازن وتحويلات المخزون وتقارير الحركة.
- جرد فعلي مقابل رصيد النظام وإظهار العجز/الزيادة.
- التتبع بحسب Serial/Lot/Expiry عند الحاجة.
- التكامل المحاسبي مع حركة المخزون.

المصادر:
`https://www.daftra.com/features/inventory-management`
`https://help.daftra.com/en/tutorials/inventory-transfer/`
`https://help.daftra.com/en/tutorials/stocktaking/`

النتيجة المعمارية لـRAWAEA: Inventory Control يجب أن يكون Control Plane مركزيًا، بينما تبقى Picking/Loading/Delivery/Return/Unloading تطبيقات تشغيلية ميدانية منفصلة.

## 5. Production Physical Stock Contract — forensic result

العقد المثبت فعليًا:

```text
Physical Movement
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```

Reservation only:
`reserve_stock`
`release_stock_reservation`

Global writer discovery في PostgreSQL لم يجد Physical Stock Writer مستقلاً آخر غير `post_stock_movement`.

`create_vehicle_atomic` و`setup_van_stock` يقومان بتهيئة مخزون/فرع عند إنشاء البنية ولا يمثلان محرك حركة موازياً.

## 6. COMPLETE RETURN — CLOSED

Current Edge:
`complete-return` — Production version `26` — `verify_jwt=true`.

Current path:
`complete-return Edge → users/auth context → complete_sales_return_credit_note_atomic → complete_return_atomic → post_stock_movement → stock_branches/inventory_log`.

المسار المالي والـcredit note والـoperation registry مرتبطان بالـcompany.

E2E transactional proof:
- إنشاء Customer/RunSheet/Order/Order Detail مؤقتين.
- تنفيذ return.
- النتيجة الأولى: `success=true`, `duplicate=false`.
- stock delta = `+1` للصنف المختبر.
- تنفيذ نفس الطلب مرة ثانية أعاد `duplicate=true` واحتفظ بنفس credit note/operation key.
- rollback كامل بعد الاختبار.
- بعد rollback: temporary orders = 0، runsheets = 0، credit_notes = 0.

نتيجة Closure:
**CLOSED — Production logic verified transactionally.**

## 7. COMPLETE ORDER DELIVERY — CLOSED

Current Edge:
`complete-order-delivery` — Production version `14` — `verify_jwt=true`.

Current contract:
Delivery يعدّل fulfillment state فقط. Physical Stock لا يتحرك هنا؛ الحركة الفيزيائية تم تسجيلها في Loading وفق العقد الحالي.

المسار:
`Mother delivery consumer → complete-order-delivery Edge → users/auth company → complete_order_delivery_atomic → order_details → orders → run_sheet_details derived sync → audit`.

الـRPC يستخدم `erp_operation_registry` لحماية duplicate/conflict.

تم تنفيذ اختبار transactional على RPC نفسه مع نفس الطلب مرتين وrollback كامل؛ لم ينتج أي residue دائم.

نتيجة Closure:
**CLOSED — Delivery has no parallel physical stock writer.**

## 8. PICKING — CLOSED

Current Edge:
`complete-picking` — Production version `17` — `verify_jwt=true`.

Current RPC:
`complete_runsheet_picking(..., p_operation_id uuid)`.

الدليل:
- يحجز عبر `reserve_stock` فقط.
- لا يكتب `inventory_log`.
- لا ينقص Physical Stock.
- يحدّث `order_details.qty_picked`.
- يحوّل runsheet من Picking إلى Picked.
- registry يمنع duplicate operation.

Transactional test:
- first call success/duplicate=false.
- stock qty ظل `2` قبل وبعد.
- allocated_qty أصبح `1`.
- order_detail qty_picked أصبح `1`.
- retry بنفس operation_id أعاد `duplicate=true`.
- rollback كامل.

نتيجة Closure:
**CLOSED — Reservation boundary proven.**

## 9. LOADING / UNLOADING — Production correction

### Root cause found

Loading/Unloading كانا يمران في النهاية عبر `post_stock_movement`، لكن operation identity على مستوى الـbusiness operation لم تكن محفوظة بصورة كافية لإعادة المحاولة بعد تغيير state.

### Surgical Production fix

تم إنشاء operation registry باستخدام الموجود فعليًا:
`erp_operation_registry`

Loading operation key:
`TASK-028|Loading|<loading_cycle_id>`

Unloading operation key:
`TASK-028|Unloading|<runsheet_code>|<loading_cycle_id>`

تمت إضافة:
- request fingerprint/payload.
- duplicate/conflict detection.
- completed response persistence.
- audit record.
- المحافظة على `post_stock_movement` كمحرك Physical Stock الوحيد.

### Defect found during verification

قيمة audit action أضيفت أولًا كـ`complete`، لكن Production CHECK يسمح فقط:
`create / update / delete / login / logout / failed_login`.

تم تصحيحها إلى `update` قبل إعادة التحقق.

### Additional forensic finding

اختبار Loading بدون Reservation فشل برسالة تجاوز الكمية المحجوزة. هذا ليس defect؛ بل إثبات أن Loading يحترم عقد Picking→Reservation.

كما كشف الاختبار أن `order_details` يؤدي إلى إنشاء `run_sheet_details` عبر trigger مشتق؛ لذلك تم منع أي Dual Write يدوي في الاختبار.

### Current status

Production functions أصبحت operation-aware ومحمية من duplicate على مستوى الدورة.

However, **browser-authenticated runtime E2E لـLoading/Unloading لم يُنفذ في هذه الجلسة لعدم امتلاك Browser/Session harness مصادق**؛ لذلك لا أدعي 100% closure للنقطة إلا من منظور DB/RPC deployment verification.

## 10. GLOBAL WRITER DISCOVERY

Search مباشر في PostgreSQL عن functions التي تغيّر `stock_branches` أو تكتب `inventory_log` أعاد:

- `post_stock_movement` — Physical writer المركزي.
- `reserve_stock` — reservation only.
- `release_stock_reservation` — reservation only.
- `create_vehicle_atomic` — initialization.
- `setup_van_stock` — initialization.

لا يوجد Physical Movement Engine مستقل آخر مثبت حاليًا.

## 11. Realtime

Production publication تحتوي على الجداول التشغيلية الأساسية:
`stock_branches`, `inventory_log`, `orders`, `order_details`, `runsheets`, `run_sheet_details`, `stock_vouchers`, `stock_voucher_details`.

`erp_operation_registry` ليست ضمن publication الحالية.

هذا لا يكسر الحركة نفسها لأن operation registry داخلي idempotency/audit state، لكن إذا أردنا عرض operation status لحظيًا في Mother فسيحتاج ذلك تصميمًا صريحًا في Control Plane لاحقًا.

## 12. Mother exact consumer review

### Return
Mother يستدعي:
`/functions/v1/complete-return`
ويُرسل `runsheet_code`/`items`.

Current Production return operation key حتمي، لذلك عدم وجود client operation id ليس blocker حاليًا.

### Delivery
Mother يستدعي:
`/functions/v1/complete-order-delivery`
ويُرسل `runsheet_code`/`order_code`/`items`.

Current RPC operation key حتمي من business payload، لذلك لا توجد ضرورة حالية لإضافة client operation id إلى Mother.

### Picking
Mother يرسل `Idempotency-Key` و`operation_id`.

### Loading
Mother يرسل `runsheet_code` و`items`; Production يستخرج operation identity من `loading_cycle_id`.

### Unloading
Mother يستدعي `unload-runsheet`; Production يستخدم loading cycle كهوية العملية.

**لا يوجد Mother patch مطلوب الآن لهذه الخمس closures.**

## 13. Mother Inventory Control — OPEN

الـlatest HEAD أضاف القائمة والroute، لكن forensic search في current Mother لم يجد implementation لـ:
`RW_Warehouse.loadInventoryControl`.

إذن إضافة route وحدها ليست إغلاقًا وظيفيًا.

### Owner surgical action

داخل:
`var RW_Warehouse = (function() { ... })();`

ابحث عن return object الذي يبدأ بـ:
`return {`
ويحتوي على:
`loadReceiving: loadReceiving,`
`loadVouchers: loadVouchers,`
`_openNewVoucherModal: _openNewVoucherModal,`

ثم يجب أن تُضاف implementation حقيقية لـ`loadInventoryControl` قبل `return {`، وبعدها تُضاف property:
`loadInventoryControl: loadInventoryControl,`
داخل نفس return object.

**مهم:** لا أقدم line number مخمّنًا لهذا الجزء لأن extraction الحالي لم يعرض line mapping موثوقًا للـBlob الضخم. لا يجب للمستخدم أن يعتمد رقمًا غير مثبت.

الوظيفة المطلوبة يجب أن تكون Control Plane فعليًا فوق:
`SNAPSHOT`
`MOVEMENTS`
`REPLENISHMENT`
`COUNT_*`
`REQUEST_*`
مع filtering حسب branch/item/date/status، refresh، وقراءة النتائج من Production لا من بيانات hard-coded.

## 14. Security findings not silently ignored

Production advisor الحالي كشف أيضًا:
- `inventory_stock_requests` و`inventory_stock_request_details` public tables بدون RLS.
- عدة SECURITY DEFINER functions قابلة للتنفيذ من authenticated/anon خارج نطاق inventory closure.
- ثلاث views security-definer.
- mutable search_path في ثلاث functions.

هذه ليست جزءًا من Writer Closure الحالي ولم تُعدّل عشوائيًا حتى لا تكسر consumers غير موثقة. ستدخل كمسار Security Closure مستقل مع مراجعة consumer/authorization قبل التغيير.

## 15. Historical data integrity

لا يجوز حذف/إعادة نسب cross-company stock rows بناء على العدد وحده.

Production يثبت `items.item_code` كـUNIQUE عالميًا، لذلك بعض العلاقات التي تبدو cross-company قد تكون متوافقة مع contract العالمي للصنف.

لم يتم حذف هذه الصفوف في هذه الجلسة.

## 16. Tests and failures

### Passed
- Return transactional E2E: PASS.
- Return duplicate: PASS.
- Delivery transactional E2E: PASS/rollback clean.
- Picking transactional E2E: PASS + duplicate PASS + reservation-only PASS.
- Global physical writer discovery: PASS.
- Audit trigger existence: PASS.
- Current Edge deployment inspection: PASS.

### Failed/intermediate harness attempts
- Loading harness syntax typo: `vehicle?`; test did not execute.
- Loading harness branch-code length exceeded varchar(20); test did not execute business code.
- Direct run-sheet-details insertion caused expected unique conflict because authoritative trigger already derives the row.
- Loading without reservation correctly rejected.
- Initial audit action `complete` correctly rejected by Production CHECK; fixed to `update`.

لا يوجد دليل على بقاء أثر دائم من هذه المحاولات.

## 17. Closure matrix

| Closure | Edge | RPC | Physical Stock | Reservation | Idempotency | Audit | Result |
|---|---|---|---|---|---|---|---|
| complete-return | v26 | complete_sales_return_credit_note_atomic → complete_return_atomic | post_stock_movement | no | deterministic registry | yes | CLOSED DB/RPC |
| complete-order-delivery | v14 | complete_order_delivery_atomic | none by design | no | registry | yes | CLOSED DB/RPC |
| picking | v17 | complete_runsheet_picking(op_id) | none | reserve_stock only | registry | operational tables + audit | CLOSED DB/RPC |
| loading | v11 | complete_runsheet_loading | post_stock_movement | requires prior reservation | loading_cycle registry | yes | DEPLOYED; browser E2E OPEN |
| unloading | v6 | complete_runsheet_unloading | post_stock_movement | follows loading state | loading-cycle registry | yes | DEPLOYED; browser E2E OPEN |

## 18. Final Self-Audit

### What I proved
- Current frontend HEAD is `e0c806...` and parent is `064683...`.
- Mother source is `erp-frontend/companies/company-1/main.html`.
- Physical stock writer discovery found no independent movement engine outside `post_stock_movement`.
- Return, Delivery, Picking are transactionally verified.
- Loading/Unloading now have production idempotency registry and audit paths.
- Loading correctly requires Reservation.
- `run_sheet_details` is derived by an existing trigger and must not be dual-written blindly.

### What I did not prove
- Authenticated browser/network E2E against current Mother with a real session.
- Full functional implementation of `RW_Warehouse.loadInventoryControl()`.
- Browser/runtime confirmation of Loading/Unloading after the latest Production deployment.

### What I fixed
- Production Loading operation identity/idempotency.
- Production Unloading operation identity/idempotency.
- Production Loading/Unloading audit compatibility.
- Documentation of current Git/source/deployment truth.

### What I initially missed
- `audit_log_action_check` rejects `complete`.
- Loading cannot be validly tested without Reservation.
- `run_sheet_details` is derived; manual test insertion was a false failure.

### What could still be wrong
- Mother route currently points to an unproven/nonexistent `loadInventoryControl()` implementation.
- Production browser integration may still have consumer/UI errors not observable without authenticated Browser/Network evidence.

### Final status

```text
RETURN                 = CLOSED (DB/RPC transactional proof)
DELIVERY               = CLOSED (DB/RPC transactional proof)
PICKING                = CLOSED (DB/RPC transactional proof)
LOADING                = DEPLOYED + DB verified; Browser E2E OPEN
UNLOADING              = DEPLOYED + DB verified; Browser E2E OPEN
PHYSICAL WRITERS OUTSIDE post_stock_movement = 0
MOTHER INVENTORY CONTROL = OPEN
AUTHENTICATED MOTHER E2E = OPEN
GLOBAL INVENTORY ZERO-DEBT = NOT YET 100%
```

## 19. Instructions for the next CTO / assistant — exact route to truth

1. Ignore previous report percentages as current state.
2. Read current frontend HEAD and its direct parent first.
3. Open only `companies/company-1/main.html` as the Mother Source of Truth.
4. Take a fresh Production snapshot at the same time.
5. For the capability being investigated, map exactly:
   `Mother Consumer → Edge → RPC → DB → Trigger/Constraint → Audit → Realtime`.
6. Search PostgreSQL directly for every writer touching the affected physical tables before changing anything.
7. Determine whether each strange behavior is historical contract, bridge, compatibility behavior, or defect.
8. Close one Closure Unit only:
   `Discover → Root Cause → Historical Context → Surgical Fix → Test → Deploy → Production Verify`.
9. Never infer line numbers from reports; extract them from current source.
10. Never insert a second `run_sheet_details` writer if the trigger already derives it.
11. Never call Loading a valid flow unless Reservation was established by Picking.
12. Never declare browser/runtime closure from DB-only evidence.
13. After every Mother owner patch, reread the current Git blob because the merged file is the only Source of Truth.
14. Only after current Browser + Console + Network + DB + Realtime agree may the status be promoted to 100% closed.

## 20. Conclusion

هذه الجلسة لم تعتبر وجود الـRPCs أو Edge Functions إغلاقًا شكليًا. الإغلاق ثبت فقط عندما أمكن إثبات المسؤولية ومسار البيانات وحماية التكرار ومكان الحركة الفيزيائية.

الـProduction الآن يحافظ على Physical Stock Core موحدًا، والـPicking يحافظ على كونه Reservation Engine، والـDelivery لا يعيد خصم المخزون، والـReturn يعيد المخزون عبر الـPhysical Core، والـLoading/Unloading أصبحا مرتبطين بهوية دورة تشغيل واحدة.

لكن المهمة الكلية **ليست 100% CLOSED بعد** لأن Mother Inventory Control implementation والـauthenticated Browser/Network E2E النهائي ما زالا غير مثبتين.
