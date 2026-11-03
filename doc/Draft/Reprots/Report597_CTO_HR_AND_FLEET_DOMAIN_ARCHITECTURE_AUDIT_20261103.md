# RAWAEA ERP — مراجعة معمارية الموارد البشرية والأسطول

**Checkpoint:** LVE-2026-11-03-597  
**التاريخ:** 2026-11-03  
**الحالة:** HR/FLEET DOMAIN CONTRACTS MAPPED / PERMISSION SOURCE DIVERGENCE BOUNDED / READ-ONLY  
**نقطة البداية:** LVE-596.

---

## 1. الهدف

توثيق المجالين اللذين يحتويان على أوامر ذرية وسجلات تدقيق متخصصة، ومقارنتهما بنموذج الصلاحيات المركزي، دون إنشاء أي Workflow/Executor جديد أو تغيير Production.

---

## 2. الموارد البشرية — HR

### 2.1 واجهة المستخدم وإدارة حساب الموظف

Parent main.html يستدعي:
- save-employee v10.
- delete-employee v4.

save-employee:
- يستخدم service_role داخليًا، لكنه يتحقق من JWT وهوية المستخدم وسياق الشركة وحالة الحساب.
- يتحقق من users permission أو Owner الحقيقي.
- يقرأ owner_profile وauth metadata بدل الاعتماد على users.is_owner.
- يمنع منح wildcard (*) لغير المالك.
- يمنع تعيين role يحتوي wildcard لغير المالك.
- يتحقق من وجود role داخل الشركة.
- يتحقق من branch codes التي يسمح بها الموظف.
- يدمج roles.permissions مع الصلاحيات المطلوبة.
- يحدث Supabase Auth وpublic.users، ويسجل audit_log.
- إذا فشل تحديث Auth بعد تعديل public.users، يحاول إعادة السجل وAuth snapshot إلى حالتهما السابقة.

delete-employee:
- لا يحذف الموظف فعليًا؛ يحوله إلى Inactive.
- يحظر حساب Auth.
- يمنع حذف حساب المالك أو الحساب المستخدم حاليًا.
- يسجل audit ويحافظ على التاريخ.
- إذا فشل Auth ban، يعيد status السابق.

هذه ضوابط جيدة يجب الحفاظ عليها.

### 2.2 HR command architecture

public.hr_command_atomic:
- SECURITY DEFINER.
- EXECUTE ممنوح لـauthenticated وservice_role.
- 643 سطرًا.
- يستقبل command + payload + operation_id + actor_user_id + actor_email.
- يثبت الشركة من سجل المستخدم.
- إذا كان التنفيذ authenticated يطابق actor.auth_id مع auth.uid().
- يشترط operation_id.
- يستخدم hr_command_log مع payload_hash وstatus وresult.
- يرفض إعادة استخدام operation_id مع command/payload مختلف.
- يدعم إعادة نتيجة العملية المكتملة عند retry.
- trigger hr_command_log_enforce_actor_identity يعيد actor_email من public.users ويتأكد من أن actor داخل الشركة ونشط.

### 2.3 نطاق HR commands

الوظيفة تغطي:
- Employee profile.
- Departments / Positions / Assignments.
- Contracts / Contract components.
- Work schedules / Schedule assignments.
- Leave types / balances / leave requests.
- Attendance events and daily attendance.
- HR requests and multi-step approvals.
- Salary advances.
- Payroll periods / calculate / approve / post / accounting map.
- Employee document metadata.

### 2.4 صلاحيات HR

- hr_user_has_permission يتحقق من users.permissions أو roles.permissions، ويأخذ Owner الحقيقي في الاعتبار.
- HR commands الإدارية والمالية تتطلب hr permission.
- Self-service requests تسمح للموظف بتنفيذ طلبه لنفسه فقط.
- HR requests approvals تتحقق من approver_employee_id أو approver_role للخطوة الحالية.
- payroll approve/post وadvance approve/disburse وleave approve/reject/cancel محكومة داخل RPC.

**ملاحظة معمارية:** hr_user_has_permission لا يضم role_permissions.permission_key، بخلاف get_my_effective_profile. لا يوجد حاليًا role_permissions key باسم hr ضمن البيانات التي فُحصت؛ لذلك هذا اختلاف implementation مؤكد لكن لم يثبت أثر حالي على HR. لا توحده عشوائيًا قبل مراجعة role data.

---

## 3. الأسطول — Fleet

### 3.1 Fleet command

public.fleet_command_atomic:
- SECURITY DEFINER.
- EXECUTE ممنوح لـauthenticated وservice_role.
- 1,129 سطرًا.
- يثبت actor من auth.uid() عند وجود JWT، وإلا من p_actor_user_id.
- يطابق p_actor_email مع بريد actor.
- يشترط company active.
- يشترط operation_id.
- يستخدم erp_operation_registry بمفتاح FLEET:operation_id.
- يرفض اختلاف payload عند إعادة استخدام المفتاح.
- يسجل النتيجة ويعيدها عند retry.

### 3.2 Fleet commands

يدعم 18 command رئيسيًا:
- VEHICLE_CREATE / VEHICLE_UPDATE.
- DRIVER_CREATE / DRIVER_UPDATE.
- DRIVER_DOCUMENT_UPSERT.
- VEHICLE_DOCUMENT_UPSERT.
- VEHICLE_CONTRACT_UPSERT.
- DRIVER_ASSIGN.
- ODOMETER_RECORD.
- FUEL_RECORD.
- MAINTENANCE_PLAN_UPSERT.
- MAINTENANCE_RECORD.
- INCIDENT_CREATE.
- PERFORMANCE_EVENT_CREATE.
- EXPENSE_CREATE.
- RUNSHEET_ASSIGN.
- STATUS_CHANGE.
- VEHICLE_OPERATION_BIND.

### 3.3 Fleet authorization

- الأوامر الإدارية الأساسية تتطلب * أو fleet.manage أو دور مدير عام/مدير مخازن.
- بعض الأوامر التشغيلية تسمح بأدوار/صلاحيات warehouse وdelivery وvan-sales وvehicle-count بحسب command.
- يتحقق من أن السائق والمركبة والفرع والرانشيت يتبعون الشركة.
- DRIVER_ASSIGN يغلق التعيين الأساسي السابق وينشئ تعيينًا جديدًا، ثم يزامن vehicles.driver_id وfleet_driver_id.
- ODOMETER_RECORD يتحقق من عدم الرجوع إلى قراءة أقل من أعلى قراءة معروفة.
- FUEL_RECORD يربط الوقود بمركبة وRunsheet/driver.
- يحفظ مستندات السائق والمركبة وعقود المركبات وخطط الصيانة والحوادث.

### 3.4 Fleet query

public.fleet_query:
- SECURITY DEFINER.
- EXECUTE ممنوح لـauthenticated وservice_role.
- يثبت actor من auth.uid أو actor_user_id.
- يفرض read permission عبر fleet.manage/fleet.read/reports أو أدوار تشغيلية محددة.
- يقدم views للوحة الأسطول والمركبات والسائقين والتعيينات والصيانة والوقود والحوادث.

**ملاحظة معمارية:** Fleet يستخدم direct users.permissions وأسماء أدوار صريحة في بعض checks، ولا يضم role_permissions مباشرة. لكنه يسمح صراحة بدور مدير عام ومدير مخازن، ولذلك لا يثبت هذا الفحص وحده منع General Manager الحالي. يبقى هذا اختلافًا عن get_my_effective_profile يجب تتبعه بحسب كل command.

---

## 4. مقارنة HR/Fleet مع بقية النظام

| المبدأ | HR | Fleet | بعض Edge القديمة |
|---|---|---|---|
| actor identity | auth.uid ↔ actor id | auth.uid ↔ actor id + email | JWT + active user فقط |
| company scope | من actor | من actor | غالبًا company check |
| permission | command-level | command-level | أحيانًا غائب |
| idempotency | hr_command_log + payload hash | erp_operation_registry + payload | أحيانًا payload hash أو status فقط |
| self/assignment | self-service + approver scope | driver/vehicle/branch/Runsheet checks | أحيانًا غائب |
| audit | HR command log + trigger | operation registry + domain logs | متفاوت |

HR/Fleet يقدمان أمثلة داخل المشروع على التصميم الذي يجب إعادة استخدامه في المسارات القديمة، بدل بناء محرك جديد.

---

## 5. ما لم يتم

- لم يتم تنفيذ أي HR command أو تعديل موظف أو حظر حساب.
- لم يتم إنشاء مركبة أو سائق أو تعيين أو تسجيل وقود أو صيانة.
- لم يتم اختبار Payroll أو Leave أو Attendance E2E.
- لم يتم اختبار Fleet dashboard عبر مستخدم فعلي.
- لم يتم تعديل أي permission أو RPC أو Edge.
- لم يتم فحص deployed artifact أو Browser runtime.

---

## 6. الحكم

HR وFleet يحتويان على command gateways متخصصة ذات هوية وتفويض وidempotency وسجلات تدقيق أفضل من بعض Edge wrappers القديمة. يجب الحفاظ على هذه البنية القائمة، والاستفادة من مبادئها عند إصلاح Finance/Warehouse/Delivery، دون إنشاء بنية تنفيذ موازية.

الحالة: HR/FLEET SOURCE+DB CONTRACTS CONFIRMED / DOMAIN RUNTIME UNVERIFIED / NOT CLOSED.
