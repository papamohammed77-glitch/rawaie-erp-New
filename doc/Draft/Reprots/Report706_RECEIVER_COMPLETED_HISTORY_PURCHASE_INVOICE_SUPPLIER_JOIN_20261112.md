# Report706 — إصلاح سجل الاستلام المكتمل: علاقة المورد غير المطابقة لمخطط purchase_invoices
**التاريخ:** 2026-11-12 (Africa/Cairo)  
**نقطة العمل:** LVE-2026-11-12-706  
**الحالة:** التصحيح الجراحي على operational main واختبارات CI E2E ناجحة؛ نشر Cloudflare للـHEAD الجديد لم يُثبت بعد.

## 1. الدليل المباشر وسبب الخطأ
بلاغ Console سجّل:
- HTTP 400 على REST endpoint الخاص بـ`purchase_invoices`.
- PostgreSQL `42703`: `column purchase_invoices.supplier_name does not exist`.
- مصدر الاستدعاء `loadReceivingHistory()` في Receiver، ثم `renderCompleted()` و`switchTab('completed')`.
- نفس كود Receiver مضمّن داخل `warehouse.html`، ولذلك ظهر الأثر في التطبيقين.

الخطأ ليس انقطاع اتصال ولا نقص صلاحية على جدول `purchase_invoices`: الاستعلام نفسه يطلب عمودًا غير موجود، فيُرفض قبل عرض سجل المكتملة.

## 2. مطابقة مخطط SMART ERP
تمت قراءة `information_schema.columns` مباشرة من مشروع Supabase Production `fiilmooggumokxanwiyx`، وتأكد:
- `purchase_invoices` يحتوي `supplier_id uuid NOT NULL`.
- لا يحتوي على عمود `supplier_name`.
- جدول `suppliers` يحتوي `id` و`name` و`company_id`.
- المفتاح الأجنبي الفعلي هو `purchase_invoices_supplier_id_fkey`: `purchase_invoices.supplier_id -> suppliers.id`.

مطابقة فعلية عبر SQL LEFT JOIN أعادت:
- `PINV-1002` → المورد «خميس مشيط».
- `PINV-1003` → المورد «حسين أبو العلا».

## 3. التصحيح الجراحي
استُبدل إسقاط العمود غير الموجود داخل استعلام فواتير السوق السريع في النسختين فقط:

```javascript
.select('id,invoice_code,branch_id,supplier:suppliers!purchase_invoices_supplier_id_fkey(name),total_amount,supplier_invoice_no')
```

واستُبدل استخراج اسم المورد ليقرأ العلاقة المضمّنة بأمان مع الحفاظ على PO الأصلي:

```javascript
supplier_name:(invoice&&invoice.supplier&&invoice.supplier.name)||doc.supplier_name||'—',
```

النتيجة:
- PO يستمر في قراءة `purchase_orders.supplier_name`، وهو حقل صالح هناك.
- Quick Market يقرأ اسم المورد من العلاقة الأجنبية الصحيحة.
- إذا كانت علاقة المورد غير مرئية للمستخدم بسبب RLS، تبقى العملية وسجلها وتفاصيلها ظاهرة ويكون اسم المورد `—` بدل إسقاط سجل الاستلام أو إظهار رسالة فشل.
- لا توجد `!inner`؛ علاقة المورد اختيارية ولا يجوز أن تتحول إلى شرط لحذف سجل الاستلام المكتمل.
- لم تتغير وظيفة تحميل Header أو Details ولا هوية المنشئ ولا `operation_id` أو الفرع أو الكميات.

### الملفات وبصمات المصدر النهائية
| الملف | Blob SHA |
|---|---|
| `companies/company-1/warehouse/receiver.html` | `e1244408988007905f10a06a0037ea12467c93d4` |
| `companies/company-1/warehouse/warehouse.html` | `e3eb994acb4beb3c75aec237ae898c12f96c47e9` |
| `.github/workflows/warehouse_hub_browser_e2e_20261110.yml` | `8c2c8a2c5701289b0b370f7f241a8c3dbee35ea6` |

## 4. حماية RLS والخصوصية
- `authenticated` يملك SELECT table privilege على `purchase_invoices` و`suppliers`، لكن RLS على `suppliers` يحدد صفوف الموردين حسب صلاحية `suppliers` أو `purchases` أو دور `أذونات`.
- الحسابان التشغيليان الحاليان `receiver@rawaea.com` (`استلام`) و`storekeeper@rawaea.com` (`مخزن شامل`) يحملان `warehouse` فقط.
- لم أوسع سياسة `suppliers_select_company` ولم أضف صلاحيات مشتريات للمستلم؛ توسيع رؤية بيانات الموردين ليس مطلوبًا لإظهار حدث الاستلام، وسيكون تغييرًا أمنيًا منفصلًا.
- استعلام العلاقة المضمّنة يستخدم سلوك LEFT embedding القياسي؛ عند عدم وجود صف مورد مرئي تكون العلاقة `null` ولا تختفي صفوف الفاتورة الأم. وثائق Supabase: https://supabase.com/docs/guides/database/joins-and-nesting
- أُضيف اختبار E2E لحالتين: علاقة المورد مرئية فتظهر التسمية، وعلاقة المورد `null` بسبب RLS فيظل سجل الاستلام قابلًا للعرض.

## 5. تغطية الاختبارات
**Workflow:** RAWAEA — Standalone Unified Warehouse E2E  
**Run:** `43243311887`  
**النتيجة:** `completed / success` على HEAD `c3397ea3b1334dac9573435626c5d6d344987eba`.  
**URL:** https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/43243311887

علامات القبول:
- `WAREHOUSE_RECEIVER_QUICK_MARKET_SUPPLIER_FK_SELECT=PASS`
- `WAREHOUSE_RECEIVER_COMPLETED_AUDIT_HISTORY=PASS`
- `WAREHOUSE_RECEIVER_HISTORY_SURVIVES_HIDDEN_SUPPLIER_RELATION=PASS`
- `WAREHOUSE_RECEIVER_COMPLETED_HISTORY_REENTRY=PASS`
- `WAREHOUSE_STANDALONE_RECEIVER_PO_QUEUE_LEGACY_BRANCH_AND_COMPLETED_HISTORY=PASS`
- بقية اختبارات التطبيقات السبعة ونطاقات الفروع والصلاحيات وتدفقات الأذونات نجحت أيضًا.

**نوع الاختبار:** Playwright مع Supabase/Auth mocks وبيانات QA مؤقتة في المتصفح؛ يثبت منطق العرض وتوافق الاستعلام مع عقد العلاقة في المصدر، ولا يُعد جلسة Production مصادقًا عليها. لم يتم تنفيذ أي استلام حي أو RPC للترحيل.

## 6. أثر Production بعد الاختبار
كل تفاعلات Supabase في هذه المهمة كانت Read-only. أعداد الجداول بعد الاختبار بقيت مطابقة للقراءة السابقة:
- `receiving = 3`
- `receiving_details = 6`
- `inventory_log = 82`
- `stock_branches = 60`
- `journal_entries = 21`
- `supplier_ledger = 3`
- `stock_vouchers = 0`

لم يتم تعديل أو إنشاء سجلات أو حركات أو أرصدة أو قيود، ولم يتم نشر Migration أو RPC أو Edge Function أو تغيير RLS/GRANT.

## 7. النشر والإغلاق
- **CONFIRMED:** سبب 42703 محدد ومطابق للمخطط الفعلي.
- **CONFIRMED:** الاستعلامان في Receiver المستقل والمضمّن لا يطلبان `purchase_invoices.supplier_name`؛ كلاهما يستخدم FK الصحيح.
- **CONFIRMED:** CI E2E النهائي نجح مع اختبار RLS-hidden supplier relation.
- **CONFIRMED:** بيانات Production بقيت دون كتابة.
- **UNVERIFIED:** Cloudflare Pages Production لم يثبت بعد أنه نشر HEAD `c3397ea3b1334dac9573435626c5d6d344987eba`. لوحة النشر المفتوحة عند آخر فحص كانت تعرض آخر إصدار عند `8a9a111...`; يلزم إعادة فحص Pages بعد اكتمال النشر الآلي.
- **UNVERIFIED:** لم تُجر جلسة متصفح حيّة بحساب استلام Production بعد هذا التصحيح.

**نقطة الاستئناف:** LVE-2026-11-12-706؛ operational HEAD `c3397ea3b1334dac9573435626c5d6d344987eba`.  
**التالي:** إثبات Cloudflare SHA parity ثم اختبار قراءة حي للتبويب المكتمل دون تنفيذ أي معاملة استلام أو ترحيل في Production.
