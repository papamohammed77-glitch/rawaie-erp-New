# RAWAEA ERP — مراجعة فاتورة POS ومحرك القرار والأثر المحاسبي/المخزني

**Checkpoint:** LVE-2026-11-03-598  
**التاريخ:** 2026-11-03  
**الحالة:** POS BUSINESS FLOW MAPPED / CURRENT AUTHORIZATION CONFLICT CONFIRMED / HISTORICAL RUNTIME DISCREPANCY  
**نقطة البداية:** LVE-597.

---

## 1. الهدف

تتبع فاتورة POS من Edge إلى RPC ومحرك القرار ثم أثر المخزون والمالية، ومطابقة صلاحية POS الحالية مع صلاحية Sales Decision engine.

---

## 2. مسار التنفيذ — CONFIRMED SOURCE

### 2.1 Edge

save-sales-invoice v19:
- verify_jwt=true.
- يتحقق من هوية المستخدم النشط والشركة والفرع.
- يجمع effective permissions من users.permissions وroles.permissions وrole_permissions.
- يقبل pos أو van-sales أو orders بحسب مصدر الفاتورة.
- يفرض POS cash-only وقيود walk-in customer وفق المسار.
- يمرر العملية إلى save_sales_invoice_atomic.
- إذا غاب operation_id يولد deterministic fallback؛ لكن POS UI الحالي يرسل operation_id صريحًا.

### 2.2 RPC save_sales_invoice_atomic

- SECURITY DEFINER.
- يشترط operation_id.
- يحدد company_id من مستخدم نشط مطابق لـp_user_email.
- يمنع تعديل Order مربوط بـRunsheet أو خارج Draft/Confirmed.
- تعديل Order أنشأه مستخدم آخر يتطلب general_manager أو sales_manager أو sales_supervisor أو * في users.permissions.
- يحدد الفرع والعميل والحسابات المحاسبية المطلوبة.
- عند status=Invoiced يستدعي sales_decision_engine_atomic(VALIDATE_ORDER).
- ينشئ order/order_details ثم ينفذ آثار الفاتورة في نفس المعاملة.

### 2.3 Sales Decision engine

sales_decision_engine_atomic:
- يشترط شركة نشطة وactor permission.
- يشترط operation_id.
- يحفظ evaluation مع policy_version وpayload/reasons.
- يطبق max_discount_percent وdiscount_approval_threshold_percent.
- يطبق min_margin_percent على cost_price.
- يطبق credit_mode وحد الائتمان وcredit_buffer_amount.
- يطبق order_approval_threshold_amount.
- يطبق stock_mode على stock_branches.qty - allocated_qty مع FOR UPDATE.
- يدعم ALLOW/WARN/BLOCK/REQUIRE_APPROVAL، ويمنع التنفيذ عندما allow_execution=false.

### 2.4 الأثر المحاسبي والمخزني عند Invoiced

save_sales_invoice_atomic ينفذ:
- POS source: post_stock_movement(POSSale) من فرع البيع إلى NULL.
- Van Sales source: post_stock_movement(VanSale) من mobile branch إلى NULL.
- يحسب total COGS من cost_price.
- ينشئ قيد إيراد/ذمم.
- ينشئ قيد COGS مقابل المخزون.
- Cash sale: post_cash_receipt_atomic؛ POS يتطلب active shift + terminal/treasury mapping.
- Credit sale: post_customer_ledger_entry.
- Van credit sale: post_driver_ledger_entry.
- يربط sales_decision_evaluation بالـorder.

هذا مسار مركزي جيد من حيث atomic business effects؛ يجب الحفاظ عليه.

### 2.5 واجهة POS

companies/company-1/sales/pos.html:
- تنشئ _activeCheckoutOperationId قبل الإرسال.
- ترسل operation_id إلى save-sales-invoice.
- لا تمسح operation_id عند الفشل؛ retry يستخدم نفس المفتاح.
- تخزن pending_updates في IndexedDB وتعيد مزامنتها عند عودة الاتصال.

هذا سلوك idempotency جيد.

---

## 3. تعارض التفويض الحالي — CONFIRMED

### 3.1 Edge يسمح بـPOS

save-sales-invoice v19 يقبل effective permission pos.

### 3.2 RPC الداخلي يرفض POS cashier الحالي

sales_decision_actor_ok(p_company_id,p_user_email,p_write=true) يسمح فقط إذا كان users.permissions يحتوي:
- *
- sales_manager
- general_manager

ولا يسمح بـpos أو van-sales أو orders في write mode.

sales_decision_engine_atomic يستدعي هذا helper بـp_write=true عند VALIDATE_ORDER، وليس فقط عند SAVE/PUBLISH policy.

### 3.3 Production user evidence

- يوجد مستخدم POS نشط واحد بصلاحية مباشرة pos.
- لا يحتوي users.permissions لهذا المستخدم على * أو sales_manager أو general_manager.
- استدعاء sales_decision_actor_ok(company_id,email,true) على المستخدم الحالي يعيد false.
- إذن Edge يمرر المستخدم بناءً على pos، لكن RPC الذي يستدعيه عند Invoiced يرفضه بناءً على شرط manager-only.

**الحكم:** Edge/RPC authorization conflict CONFIRMED. إذا كان المستخدم الحالي هو الكاشير الذي ينفذ الفاتورة، فمسار Invoiced الحالي سيصل إلى Sales Decision engine ثم يرفضه. لم أنفذ فاتورة اختبارية، لذلك Runtime failure UNVERIFIED، لكن نتيجة helper الحالية مباشرة.

---

## 4. الأدلة التاريخية مقابل الحالة الحالية — CONFLICT / UNKNOWN CAUSE

- Production يحتوي 5 POS orders أُنشئت بين 2026-10-10 و2026-10-18 بواسطة دور كاشير.
- توجد 5 sales_decision_evaluations مرتبطة بهذه الفواتير، وكلها decision=ALLOW.
- Edge save-sales-invoice v19 آخر تحديث له 2026-10-16، أي أن آخر 3 POS evaluations حدثت بعد تحديث v19.
- helper الحالي sales_decision_actor_ok يرفض POS cashier الحالي.
- audit_log لمستخدم POS يسجل role/role_id فقط، ولا يسجل old/new permissions؛ لذلك لا يمكن تحديد هل تغيرت صلاحيات المستخدم بعد 18 أكتوبر أم تغير helper/RPC بعد ذلك.

**التصنيف:**
- Current helper result = CONFIRMED DENY.
- Historical evaluations = CONFIRMED ALLOW.
- سبب الاختلاف الزمني = UNKNOWN.
- لا يجوز استنتاج أن المسار يعمل الآن من نجاح فواتير أكتوبر.

---

## 5. قرار الإصلاح المطلوب

لا توسع helper إلى pos بشكل أعمى؛ يجب فصل صلاحيات:
1. Sales Decision policy management/publish — sales_manager/general_manager.
2. VALIDATE_ORDER for invoice execution — الصلاحيات التشغيلية المسموحة حسب المصدر: pos / van-sales / orders، مع قواعد إضافية للخصم والائتمان والمخزون.
3. Approve REQUIRE_APPROVAL — الدور المعتمد للحد/الخصم/الائتمان.
4. Read pending approvals — reports/manager policy.

يجب أن يظل منع الكاشير من تعديل سياسة المحرك قائمًا، دون منعه من تنفيذ فاتورة POS مسموحة.

هذا تغيير DB function/permission contract، ويحتاج:
- exact SQL diff.
- اختبار POS cashier سلبي/إيجابي.
- اختبار sales manager policy publish.
- اختبار discount approval وcredit block وstock shortage.
- اختبار idempotent retry.
- اختبار rollback لعدم إنشاء order/stock/cash/journal عند BLOCK/REQUIRE_APPROVAL.

لا تنفذ قبل موافقة المالك وفق Master §77.2.

---

## 6. مصفوفة التحقق

| الطبقة | النتيجة |
|---|---|
| save-sales-invoice Edge | effective POS permission accepted — CONFIRMED |
| save_sales_invoice_atomic | Invoiced calls decision engine — CONFIRMED |
| sales_decision_actor_ok | Current POS cashier returns false for p_write=true — CONFIRMED |
| POS UI operation_id | stable key + IndexedDB retry — CONFIRMED |
| Stock effect | POSSale/VanSale movement — CONFIRMED SOURCE |
| Accounting effect | cash receipt / revenue journal / COGS journal / customer or driver ledger — CONFIRMED SOURCE |
| Historical POS evaluations | 5 ALLOW records — CONFIRMED |
| Cause of historical/current divergence | UNKNOWN |
| Runtime invoice by current cashier | UNVERIFIED |
| Browser E2E/deployed artifact | UNVERIFIED |

---

## 7. ما تم وما لم يتم

**تم:**
- قراءة save-sales-invoice v19.
- قراءة save_sales_invoice_atomic.
- قراءة sales_decision_engine_atomic وsales_decision_actor_ok.
- فحص POS UI operation_id/offline queue.
- فحص counts وتواريخ POS orders/evaluations.
- تقييم helper مباشرة على المستخدم الحالي بقراءة فقط.

**لم يتم:**
- لم تُنشأ فاتورة POS.
- لم تُجر محاولة HTTP أو UI كاشير.
- لم يتغير permission أو RPC.
- لم تُنفذ حركة stock أو journal أو cash.
- لم يتم نشر أي شيء.

---

## 8. الحكم

**POS invoice path مصمم بمحاسبة ومخزون ذريين ومحرك قرار متقدم، لكن يوجد تعارض حالي بين صلاحية Edge (pos) وصلاحية Sales Decision RPC (sales_manager/general_manager فقط). نجاحات POS القديمة لا تثبت صلاحية المسار الحالي؛ سبب الاختلاف غير محسوم.**

الحالة: POS FLOW SOURCE CONFIRMED / AUTHORIZATION CONFLICT CONFIRMED / HISTORICAL CAUSE UNKNOWN / RUNTIME UNVERIFIED / NOT CLOSED.
