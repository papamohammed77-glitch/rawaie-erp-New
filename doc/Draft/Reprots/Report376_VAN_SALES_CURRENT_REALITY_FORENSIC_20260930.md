# تقرير تدقيق جنائي — VAN SALES / الحالة الحالية وخطة الإغلاق
## 2026-09-30

## SELF-AUDIT — PRE-CHECK
- فهم الأعمال: 99/100
- فهم المعمارية: 99/100
- فهم قاعدة البيانات: 100/100
- فهم التاريخ: 99/100
- فهم Production: 100/100
- فهم Current: 100/100
- ثقة التنفيذ: 98/100
- الحقائق المؤكدة: 30+
- Unknowns المؤثرة: 1
- Conflicts: 1 — CURRENT_STATE متأخر عن Git الفعلي
- Unverified Claims: 0 في النتائج البنيوية أدناه

---
## 1. مصادر الحقيقة
تمت مراجعة MASTER CTO GOVERNANCE حتى النهاية، وCURRENT_STATE، والتقارير 372–375، ثم تم تجاوزها كمراجع تاريخية والتحقق من الحالة الحالية مباشرة من Git وSupabase Production وقاعدة البيانات والسجلات.

تم تأكيد أن مستودع Edge_Functions التاريخي يحتوي أصلًا على original وcurrent وarchive، لذلك لا يوجد مبرر لاعتبار النسخ التاريخية غير متاحة.

---
## 2. الحالة الحالية الفعلية لملف Van Sales
المستودع: papamohammed77-glitch/erp-frontend
الملف: companies/company-1/sales/van-sales.html
Current SHA: b5d7b2efe653b328bd2b020ac5b10d347bc8ad76
آخر commit مؤثر: 74b122f9c2721178f27dd8f495cfd61134bb5399
Parent: df0137d062a990cfccf7acbdfd53bc2af34ba610
الحجم الحالي: 3055 سطرًا / 143123 حرفًا.

وهذا أحدث من الحالة المسجلة في CURRENT_STATE/Report375، لذلك لا يجوز استخدام رقم 3048 سطرًا أو SHA e696a82... كحالة راهنة.

---
## 3. collectPayment — لم يعد مفتوحًا كمصدر كود
آخر commit 74b122... أضاف فعليًا حذف operationStorageKey بعد النجاح.
العنصر المضاف:

```javascript
try {
    localStorage.removeItem(operationStorageKey);
} catch (e) {}
```

وبذلك أصبح defect الذي سجله Report375 مطبقًا في Git الحالي.

لا يوجد Backend defect مثبت في هذه الوحدة يحتاج تعديلًا.

Production backend verified:
- save-receipt-voucher v8 ACTIVE
- post_van_sales_collection_atomic موجود كـSECURITY DEFINER
- operation-level idempotency عبر erp_operation_registry
- company/customer/user/treasury/account validation
- customer ledger + driver ledger + cash receipt ضمن transaction واحدة.

كما تم تنفيذ اختبار Production DB داخل Transaction مع ROLLBACK:
- عملية أولى: SUCCESS
- إعادة نفس operation_id: duplicate=true
- عملية ثانية مستقلة بنفس العميل والمبلغ: SUCCESS
- بعد rollback: لا receipts ولا registry ولا ledger residue.

الحكم: Backend collection atomicity/idempotency = VERIFIED.

لكن Browser E2E بعد آخر commit غير مثبت هنا، لأن الملف محمي.

---
## 4. vehicle/custody — verified ولا حاجة لإعادة فتحه
setup-van-branch v5 ACTIVE يستخدم authenticated public.users → company_id → fleet_vehicle_sales_rep_assignments → vehicle → mobile_branch_id.
وProduction يثبت وجود direct-sales assignments فعالة.
هذا ينسجم مع Route Stock Management في SAP وwarehouse↔truck transfers في Dynamics 365، حيث المخزون الميداني يظل ضمن مخزون الشركة أثناء انتقاله بين المواقع الداخلية. https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e322becd165844e5868e590bc8efafaf/2182ceda05df4084b478b9a9cf2a17e8.html
https://learn.microsoft.com/en-us/dynamics365/field-service/transfer-inventory

---
## 5. Customer Accounts — verified
Production RPC get_van_sales_customer_accounts يعتمد authenticated user عبر public.users.auth_id ويحدد company_id والدور والتخصيصات، ثم يعيد العملاء ذوي المديونية والفواتير والمدفوعات وكشف الحساب والأقساط.
Production logs تثبت أن Van Sales client يستدعي RPC فعليًا ويستلم HTTP 200.

الحكم: customer-account backend = VERIFIED.

---
## 6. العيوب الحالية في frontend التي ما زالت فعلية

### A. loadCustomerPatterns() — السطر 499
الاستعلام الحالي يجلب orders بواسطة created_by فقط ثم يجلب كل order_details بلا تقييد order_id/company/source، ويستخدم customer_id كأنه customer_code.
هذا يخلق خطر خلط قنوات البيع/الشركات ويكسر هوية العميل في أنماط الشراء.
الإجراء الجراحي المطلوب:
- إضافة company_id + source='van-sales' إلى orders.
- قصر order_details على order_ids الناتجة.
- تحويل customer_id UUID إلى customer_code الفعلي بواسطة customers داخل نفس company.

### B. loadKPIs() — السطر 674
الاستعلام الحالي: created_by + order_date فقط.
الإجراء: إضافة company_id + source='van-sales'.

### C. loadHomeSalesSummary() — السطر 846
نفس العيب: created_by + date فقط.
الإجراء: إضافة company_id + source='van-sales'.

### D. loadMyInvoices() — السطر 1620
نفس العيب: created_by + date فقط.
الإجراء: إضافة company_id + source='van-sales'.

### E. loadHomeBalanceSummary() — السطر 873
driver_ledger محدد بالبريد فقط.
Production schema يثبت وجود driver_ledger دون company_id، لذلك لا يجوز إضافة filter وهمي غير موجود.
الحل الصحيح ليس patch شكليًا؛ يجب إبقاء هذه الوحدة حتى تُحدد طريقة عزل العهدة المالية في العقد الحالي، بدل تخمين عمود غير موجود.

### F. loadBalanceDetail() — السطر 1872
نفس ملاحظة E؛ لا company_id في driver_ledger. لا يُخترع filter.

### G. repeatOrder() — السطر 1324
يستخدم order.customer_id UUID للبحث داخل Dexie myCustomers.customer_code النصي.
هذا mismatch فعلي.
الحل: customer UUID → customers.id مع company_id → customer_code، ثم فتح السلة بالكود الحقيقي.

### H. initiateEndOfDay() — السطر 1948
إغلاق الوردية حاليًا client-only عبر self.eodLocked.
Production لديه post_daily_settlement_atomic كـCore دائم، لكنه يتطلب runsheet Delivered/Returned وoperation_id.
إذن هذه وحدة مستقلة تحتاج إغلاق Contract الخاص بـVan Sales EOD وربطها بالـsettlement الموجود، ولا يجوز اختراع shortcut جديد.

---
## 7. ما ليس بحاجة لتعديل الآن
- loadMyCustomers() — يستخدم get_van_sales_customer_accounts الحالي.
- showRecentCustomers() — company/source scoped.
- _loadVehicleStock() — مصدر العهدة الحي صحيح، واستعلام المبيعات اليومي company/source scoped.
- submitQuickInventory() — العقد الحالي متوافق مع save-inventory-count v5.
- submitQuickSale() — يستخدم save-sales-invoice v15 ويحدد source='van-sales'.
- loadHomeStockSummary() — يقرأ stock_branches من VAN canonical branch؛ القيمة الظاهرة قيمة بيع تقريبية وليست تقييم تكلفة، ولا يُغير دون عقد محاسبي.

---
## 8. Production evidence الحالي
Production logs بتاريخ 2026-09-30 تثبت أن تطبيق Van Sales يستخدم REST queries للمبيعات والمخزون والعهدة وRPC customer accounts من متصفح فعلي.
وهذا يجعل عيوب scope في loadKPIs/loadHomeSalesSummary/loadMyInvoices وليست نظرية فقط، لأنها تقرأ بيانات Production فعلية عبر نفس الواجهة.

في المقابل، لم توجد Edge logs حديثة لـsave-receipt-voucher في نافذة الاستعلام الأخيرة، لذلك لا ندعي أن Browser collection الحالي تم اختباره بعد آخر frontend commit.

---
## 9. Production database snapshot
- لا توجد حاليًا أوامر Van Sales وفق snapshot الذي تم فحصه.
- لا توجد customer_assignments فعالة حاليًا.
- توجد 2 direct-sales primary vehicle assignments فعالة.
- توجد 34 stock master rows صفرية لمخازن VAN، وهي rows تأسيسية ولا ينبغي حذفها تلقائيًا.
- لا توجد test runsheets/orders/customers من أنماط الاختبار التي تم فحصها.

---
## 10. Competitor benchmark — principle only
SAP Route Stock Management يعطي visibility للمخزون من التحميل عبر route execution حتى settlement، ويدعم transfer إلى route stock عند حدث التحميل/الخروج. Dynamics يوضح نقل المخزون بين warehouse وtechnician truck مع نقصان المصدر وزيادة الوجهة. Odoo يعتمد المواقع الداخلية وقواعد routes ويفصل المواقع الداخلية عن المواقع الخارجية. https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e322becd165844e5868e590bc8efafaf/2182ceda05df4084b478b9a9cf2a17e8.html
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e322becd165844e5868e590bc8efafaf/966e5a1b8f1d4f828e4a14d0a57875a4.html
https://learn.microsoft.com/en-us/dynamics365/field-service/transfer-inventory
https://www.odoo.com/documentation/17.0/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management.html

RAWAEA يحتفظ بنموذجه الميداني الخاص، لكن يجب أن تكون القراءات المالية والتشغيلية company/channel scoped.

---
## 11. قرار التنفيذ
لا توجد حاليًا Production DB/Edge changes لازمة للعيوب الأمامية المحددة في هذه الوحدة.
المرحلة التالية هي تطبيق Owner surgical patches على الملف المحمي، ثم Browser E2E، ثم إغلاق كل وحدة بالتتابع.

الترتيب:
1. collectPayment — Source fixed; Browser E2E pending.
2. loadMyCustomers — already aligned; verify only.
3. loadCustomerPatterns — OPEN.
4. loadKPIs — OPEN.
5. loadHomeSalesSummary — OPEN.
6. loadMyInvoices — OPEN.
7. loadHomeBalanceSummary/loadBalanceDetail — contract decision + verification required; no guessed company_id.
8. repeatOrder — OPEN.
9. initiateEndOfDay — OPEN; integrate with existing settlement contract.

لا نعيد فتح الوظائف المغلقة بلا defect جديد.

---
## 12. Self-Audit Final
### What I Proved
الواقع الحالي لـGit وProduction وDB، أن collectPayment patch موجود بالفعل، وأن collection Core ذري/idempotent، وأن vehicle identity وcustomer accounts وcustody source متوافقون مع العقد الحالي، وأن عدة frontend reads ما زالت غير company/channel scoped، وأن repeatOrder يحمل UUID/code mismatch، وأن EOD ما زال client-only.

### What I Did Not Prove
لم أثبت Browser E2E بعد آخر commit للواجهة المحمية.

### What I Fixed
لا Frontend file تم تعديله بسبب الحماية. لا Production business data تم تغييره بشكل دائم.

### What I Initially Missed
الاعتماد على Report375 كان سيؤدي إلى إعادة تنفيذ collectPayment رغم أن commit 74b أصلحه بالفعل.

### What Could Still Be Wrong
قد توجد frontend consumers إضافية خارج الوحدات التي تم فحصها، ولذلك يجب أن يكون كل closure مبنيًا على search مباشر للرموز والاستدعاءات قبل التعديل.

### Final Confidence
98/100

### Final Closure Status
VAN SALES = INCOMPLETE
Current next exact unit = loadCustomerPatterns()
Owner action required before browser closure = Apply surgical patch to protected van-sales.html.

---
## 13. تعليمات الاستئناف للمساعد التالي
ابدأ من Git الحالي لا من Report375.
تحقق من SHA الحالي للملف.
لا تعيد collectPayment أو custody أو customer-account backend بلا defect جديد.
ابدأ بـloadCustomerPatterns()، قارنها بالـProduction contract، طبّق patch Owner-only، ثم اختبر من المتصفح عند توفر النسخة المعدلة.
بعد نجاحها أغلق الوحدة وانتقل مباشرة إلى loadKPIs().
أي نقص يُكتشف: عالجه في نفس الوحدة، لا تحمله إلى الأمام.
END.
---
## 14. OWNER SURGICAL PATCHES — EXACT ELEMENTS

### Patch 1 — loadCustomerPatterns() — line 499
احذف الكتلة الحالية ابتداءً من:

```javascript
supabase.from('orders')
    .select('id, customer_id, customer_name, order_date')
    .eq('created_by', this.currentUser.email)
    .order('order_date', { ascending: false })
```

وحتى نهاية الـthen المتداخل الذي يجلب order_details ويبني detailMap.

استبدلها بالكتلة:

```javascript
supabase.from('orders')
    .select('id, customer_id, customer_name, order_date')
    .eq('company_id', self.companyId)
    .eq('created_by', self.currentUser.email)
    .eq('source', 'van-sales')
    .not('customer_id', 'is', null)
    .order('order_date', { ascending: false })
    .then(function(oRes) {
        if (oRes.error) throw oRes.error;
        var orders = oRes.data || [];
        if (!orders.length) return [];

        var orderIds = orders.map(function(o) { return o.id; });
        var customerIds = [];
        for (var i = 0; i < orders.length; i++) {
            if (orders[i].customer_id && customerIds.indexOf(orders[i].customer_id) === -1) {
                customerIds.push(orders[i].customer_id);
            }
        }

        return Promise.all([
            supabase.from('customers')
                .select('id,customer_code')
                .eq('company_id', self.companyId)
                .in('id', customerIds),
            supabase.from('order_details')
                .select('order_id,item_code,item_name,qty')
                .in('order_id', orderIds)
        ]).then(function(parts) {
            if (parts[0].error) throw parts[0].error;
            if (parts[1].error) throw parts[1].error;

            var customerMap = {};
            (parts[0].data || []).forEach(function(c) {
                customerMap[String(c.id)] = c.customer_code || String(c.id);
            });

            var orderMap = {};
            orders.forEach(function(o) { orderMap[String(o.id)] = o; });

            var detailMap = {};
            (parts[1].data || []).forEach(function(d) {
                var ord = orderMap[String(d.order_id)];
                if (!ord || !ord.customer_id) return;
                var customerCode = customerMap[String(ord.customer_id)];
                if (!customerCode) return;
                if (!detailMap[customerCode]) detailMap[customerCode] = {};
                if (!detailMap[customerCode][d.item_code]) {
                    detailMap[customerCode][d.item_code] = { count: 0, totalQty: 0, name: d.item_name };
                }
                detailMap[customerCode][d.item_code].count++;
                detailMap[customerCode][d.item_code].totalQty += Number(d.qty) || 0;
            });

            var patterns = [];
            for (var customerCode in detailMap) {
                if (!detailMap.hasOwnProperty(customerCode)) continue;
                for (var itemCode in detailMap[customerCode]) {
                    if (!detailMap[customerCode].hasOwnProperty(itemCode)) continue;
                    var x = detailMap[customerCode][itemCode];
                    patterns.push({
                        customer_code: customerCode,
                        item_code: itemCode,
                        frequency: x.count,
                        avgQty: x.count ? Math.ceil(x.totalQty / x.count) : 0,
                        item_name: x.name || itemCode
                    });
                }
            }
            return patterns;
        });
    })
    .then(function(patterns) {
        if (db && db.customerPatterns) {
            return db.customerPatterns.clear().then(function() {
                return db.customerPatterns.bulkPut(patterns);
            });
        }
    });
```

### Patch 2 — loadKPIs() — line 674
احذف:

```javascript
.eq('created_by', this.currentUser.email)
.eq('order_date', today)
```

واستبدلها بـ:

```javascript
.eq('company_id', this.companyId)
.eq('created_by', this.currentUser.email)
.eq('source', 'van-sales')
.eq('order_date', today)
```

### Patch 3 — loadHomeSalesSummary() — line 846
نفس الاستبدال السابق حرفيًا.

### Patch 4 — loadMyInvoices() — line 1620
استبدل:

```javascript
.eq('created_by', this.currentUser.email)
.eq('order_date', dateFilter)
```

بـ:

```javascript
.eq('company_id', this.companyId)
.eq('created_by', this.currentUser.email)
.eq('source', 'van-sales')
.eq('order_date', dateFilter)
```

### Patch 5 — repeatOrder() — line 1324
احذف فقط lookup Dexie التالي:

```javascript
db.myCustomers.where('customer_code').equals(order.customer_id).first()
```

واستبدله بـ lookup Supabase:

```javascript
supabase.from('customers')
    .select('id,customer_code,name,area,payment_type')
    .eq('company_id', self.companyId)
    .eq('id', order.customer_id)
    .maybeSingle()
```

ثم اجعل فتح السلة يستخدم `customer_code` الناتج، وليس UUID.

### Patch 6 — driver_ledger
لا تضف `company_id` إلى `driver_ledger`؛ العمود غير موجود في Production schema الذي تم التحقق منه.
أي إصلاح يجب أن يعتمد على العقد الصحيح في Core، وليس Filter مخترعًا.

### Patch 7 — initiateEndOfDay() — line 1948
لا يُنفذ patch شكلي في هذه الدورة. هذه Closure Unit مستقلة لأنها تحتاج Contract دائمًا يحدد أي Runsheet يُسوّى وما هو تعريف نهاية يوم Van Sales. Production لديه `save-daily-settlement v4` و`post_daily_settlement_atomic` كقاعدة موجودة بالفعل.

END PATCH SECTION