# Report90 — Main7 Final Tenant-Scope Addendum — 2026-09-08

## 1. سبب الإضافة
بعد إغلاق مراجعة Delivery وSettlement وInventory Count، تمت مراجعة بقية الجزء التشغيلي من `Current/PWA/main2/main7.md` بحثًا عن نفس نوع Tenant/Company drift. ظهرت نقاط إضافية مثبتة من الكود الحالي ومن عقد Production.

لم يتم تعديل `main7.md` نفسه، التزامًا بملكية المالك للجزء الأم.

## 2. نقاط إضافية يجب تنفيذها يدويًا

### A. `loadPicking()`
المقطع الحالي يقرأ:
`supabase.from('runsheets').select('*').in('status', ['Open', 'Confirmed'])`

استبدله باستعلام يستخدم:
`company_id = RW_STATE.app.companyId`
مع نفس حالات `Open` و`Confirmed`.

### B. `_showPickingDetails(code)`
المقطع الحالي يجلب Runsheet بواسطة `runsheet_code` فقط.

استبدل الاستعلام ليستخدم:
`company_id + runsheet_code`.

ثم اجلب `run_sheet_details` بواسطة `runsheet_id` الناتج.

### C. `loadVehicleCount()` — Runsheets selector
المقطع الحالي:
`supabase.from('runsheets').select('runsheet_code, driver_id').in('status', ['Loaded', 'Delivering', 'Delivered', 'Returning'])`

استبدله باستعلام يحمل `company_id = RW_STATE.app.companyId` مع نفس الحالات.

### D. `_searchDriver(query)`
المقطع الحالي:
`supabase.from('users').select('email, name').in('role', ['driver','سائق','مندوب']).ilike('name', '%' + query + '%')`

استبدله باستعلام يضيف:
`.eq('company_id', companyId)`
مع التحقق من `companyId` قبل الاستعلام.

### E. `loadUnloading()`
المقطع الحالي:
`supabase.from('runsheets').select('*').in('status', ['Open','New'])`

استبدله باستعلام يضيف:
`.eq('company_id', companyId)`
مع التحقق من سياق الشركة.

## 3. نقاط لا تتغير
- M7-08 lifecycle.
- Driver.html business workflow.
- `complete_order_delivery_atomic`.
- `complete_return_atomic`.
- Physical Stock core.

## 4. Production status
لا يوجد تعديل Production مطلوب بسبب هذه النقاط في هذه الجلسة؛ العقود Production الحالية التي يعتمد عليها Main7 صحيحة. الإصلاحات المطلوبة في هذه النقاط هي Parent/Main7 integration fixes.

## 5. Closure status
`MAIN7 FORENSIC REVIEW = COMPLETE`
`MAIN7 SOURCE SURGERY = OPEN / OWNER ACTION REQUIRED`
`DELIVERY CONTRACT = PROVEN`
`INVENTORY COUNT CONTRACT = PROVEN`
`TENANT-SCOPE REVIEW = OPEN UNTIL OWNER APPLIES ALL LISTED SURGERIES`
