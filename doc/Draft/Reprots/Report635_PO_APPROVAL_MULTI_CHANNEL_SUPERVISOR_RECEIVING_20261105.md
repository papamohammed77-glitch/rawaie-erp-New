# Report635 — اعتماد PO من قناتين وإكمال تطبيق مشرف المشتريات وحارس الاستلام
**التاريخ:** 2026-11-05  
**الحالة:** تحقيق حي ومراجعة تنفيذ مكتملان؛ ChangeSet تنفيذي محدد معروض للموافقة. لم تحدث أي كتابة تشغيلية بعد.

---

## 1. القرار التنفيذي

اعتماد أمر الشراء PO يتم من قناتين مستقلتين، بعقد صلاحيات واحد على الخادم:

**أولًا — النظام الأم**
- المستخدم الذي يستطيع الدخول إلى إدارة المشتريات ← دورة المشتريات بصلاحية purchases يستطيع اعتماد أمر الشراء من مودال تفاصيل PO.
- لا يشترط أن يحمل المستخدم دور أو صلاحية purchases_supervisor.
- المالك وصاحب الصلاحية الشاملة * يظلان مخولين.

**ثانيًا — تطبيق supervisor.html**
- يدخل التطبيق مستخدم بصلاحية purchases_supervisor أو المالك أو *.
- يعرض جميع أوامر الشراء التابعة للشركة، لجميع مسؤولي المشتريات، لا أوامر مسؤول واحد.
- يعرض منشئ PO وبياناته وبنوده وحالة الاستلام.
- يتيح للمشرف فتح التفاصيل واعتماد PO بحالة Draft.

**بوابة الخادم**
- يسمح Edge وRPC بالاعتماد إذا كان المستخدم يحمل purchases أو purchases_supervisor أو صلاحية المالك/النجمة.
- لا يُسمح بتحديث PO مباشرة من واجهة المستخدم؛ جدول purchase_orders لا يمنح authenticated حق UPDATE.
- الاعتماد يغيّر Draft إلى Approved فقط. لا ينشئ حركة مخزون أو ذمم مورد أو قيدًا محاسبيًا أو حركة خزينة.
- تطبيق Receiver يعرض Approved. لا يمكن إنشاء Receiving لأمر Draft حتى عبر تجاوز الواجهة أو استدعاء مباشر.

لا نضيف Edge جديدة. نعيد استخدام save-purchase-order القائمة، ونضيف RPC واحدة وحارس Receiving صغيرًا.

## 2. Current Reality — الأدلة الحية

### 2.1 النشر والمستودع

- Repo التشغيل: papamohammed77-glitch/erp-frontend، branch main.
- آخر Production deployment ظاهر في Cloudflare Pages: commit 4f433c4a014d24d317201936b2473c2335352119، الرسالة Update purchase order query and status handling.
- رابط Deployment المرتبط بالـcommit: https://44e89385.rawaea-erp.pages.dev
- الدومين المستمر: https://rawaea-erp.pages.dev
- Automatic deployments: enabled.
- صفحة النظام الأم المفتوحة على النطاق المنشور تعرض دورة المشتريات وأمر الشراء الحالي بحالة «مسودة»، وهو متوافق مع قراءة قاعدة البيانات.

### 2.2 الملفات المنشورة

| الملف | Blob SHA الحالي | نتيجة المراجعة |
|---|---|---|
| companies/company-1/main.html | 2ecd4936e5a5f328d56e3cc5f8d6dbcca8487122 | زر الاعتماد وموداله ودالة approvePO موجودة؛ شرط الصلاحية الحالي خطأ لأنه يشترط purchases_supervisor في النظام الأم. |
| companies/company-1/warehouse/receiver.html | 223dcc9c690510f83922c54fb616f9cfd20a4ed5 | إضافة Approved وقراءة details عبر po_id وحساب الكمية المستلمة والمتبقية وparseFloat موجودة بالفعل. توجد حواف خطأ/كمية صفرية نغلقها أدناه. |
| companies/company-1/purchasing/supervisor.html | d13e3ff72972641fa300fb956d1f5119e2019743 | تطبيق موجود لكنه عرض فقط؛ استعلامه محدود بـ50 PO ولا توجد تفاصيل أو وظيفة اعتماد، كما أن بوابة دخوله تشترط purchases بدل purchases_supervisor. |
| companies/company-1/core.js | f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1 | RW_API.call() موجود ويكفي لإرسال العملية إلى Edge القائمة؛ لا تغيير مطلوب في Core. |

### 2.3 سبب رسالة APPROVE_PO

Edge save-purchase-order الحالية ACTIVE v29، SHA-256:
35caa4f2759ba608a7f3bf86640b4773280bc84447872267d6e4d53896743e04

العملية APPROVE_PO غير موجودة في dispatch الخاص بها. بعد مرور authorization تصل العملية إلى المسار الأخير:
~~~ts
throw new Error("عملية مشتريات غير مدعومة: " + op);
~~~

لذلك رسالة 400 التي ظهرت في Console مطابقة تمامًا لغياب العملية من Edge، وليست خطأ في رقم PO أو في Supabase client. واجهة main.html تستدعي العملية فعلًا عبر api('APPROVE_PO', { id: poId })، لكن الخادم v29 لا يعرفها.

Edge receive-purchase الحالية ACTIVE v13، SHA-256:
50ab45ae026a0bb4d1de7837c872c4cc42da47b6a603f340e48d023d839310cc

### 2.4 قاعدة البيانات

قراءة Production الحالية أثبتت:
- purchase_orders = 1؛ الحالة الوحيدة Draft؛ Approved = 0.
- مستخدمون نشطون يحملون purchases = 2.
- مستخدم نشط يحمل purchases_supervisor = 1.
- RLS على purchase_orders وpurchase_order_details يمنح authenticated SELECT ولا يمنحه UPDATE.
- purchase_status_history موجود، ومعه trg_purchase_orders_status_history الذي يسجل تغيير حالة PO تلقائيًا.
- Trigger التاريخ يلتقط قيمة rawaea.purchase_actor من إعداد المعاملة؛ يجب ضبطها قبل UPDATE.
- لا توجد RPC باسم purchase_approve_po_atomic.
- لا يوجد Trigger حالي على receiving.
- receive_purchase_atomic هو المسار المركزي الوحيد الذي ينشئ public.receiving؛ جسمه الحالي لا يرفض Draft حسب حالة PO.
- receive_purchase_atomic يقوم بعد إنشاء Receiving بحركة PurchaseIn وتحديث qty_received وحالة PO وتسجيل ذمة المورد والقيود اللازمة؛ لذلك يجب تنفيذ حارس الحالة قبل INSERT في receiving حتى يفشل كامل الاستلام قبل أي أثر مخزني/محاسبي.

أمر PO الحقيقي الوحيد الحالي لم يتم اعتماده أو استخدامه كتجربة، ولم تنشأ بيانات اختبار أو آثار مالية/مخزنية.

## 3. تعديل main.html — سطران فقط

### 3.1 عرض زر الاعتماد لأي مستخدم يصل إلى دورة المشتريات

الموضع: RW_Purchases.openPO(poCode).

الموجود حاليًا:
~~~js
var canApprovePO = poRes.data.status === 'Draft' && RW_Permissions_check('purchases_supervisor');
~~~

يستبدل بهذا:
~~~js
var canApprovePO = poRes.data.status === 'Draft' && RW_Permissions_check('purchases');
~~~

### 3.2 شرط دالة الاعتماد

الموجود حاليًا داخل RW_PurchaseGold.approvePO(poId):
~~~js
if (!RW_Permissions_check('purchases_supervisor')) {
  showToast('اعتماد أمر الشراء يتطلب صلاحية مشرف المشتريات', 'error');
  return;
}
~~~

يستبدل بهذا:
~~~js
if (!RW_Permissions_check('purchases')) {
  showToast('اعتماد أمر الشراء يتطلب صلاحية الوصول إلى دورة المشتريات', 'error');
  return;
}
~~~

لا يستبدل مودال التفاصيل ولا الدالة كاملة ولا ملف main.html. باقي منطق التأكيد والاستدعاء والتحديث يبقى كما هو.

## 4. Edge القائمة save-purchase-order — v29 إلى v30

### 4.1 شرط التفويض

في كتلة authorization الحالية التي تبدأ بـ:
~~~ts
if (op === "SAVE_SETTINGS") {
~~~

يُدخل الشرط التالي قبلها:
~~~ts
if (op === "APPROVE_PO") {
  requireAny(["purchases", "purchases_supervisor"]);
} else if (op === "SAVE_SETTINGS") {
~~~

بالتالي:
- مستخدم purchases من النظام الأم يستطيع الاعتماد.
- مشرف purchases_supervisor من التطبيق المستقل يستطيع الاعتماد.
- المستخدم الذي لا يحمل أيًا منهما يرفضه الخادم.
- لا يُفرض دور المشرف على النظام الأم.

### 4.2 فرع التنفيذ

بعد فرع CREATE_PO وقبل SUBMIT_REQUEST، يضاف:
~~~ts
    } else if (op === "APPROVE_PO") {
      ({ data, error } = await profileClient.rpc("purchase_approve_po_atomic", {
        p_po_id: p.id
      }));
~~~

يستخدم profileClient الذي يحمل JWT المستخدم، ويستدعي RPC لا تحديثًا مباشرًا. تظل Edge نفسها ولا تُنشأ Edge جديدة.

## 5. Migration واحدة — RPC اعتماد PO وحارس الاستلام

اسم Migration المقترح:
purchase_order_approval_multi_channel_and_receiving_gate_20261105

### 5.1 RPC الاعتماد

~~~sql
CREATE OR REPLACE FUNCTION public.purchase_approve_po_atomic(
  p_po_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_po public.purchase_orders%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_AUTH_REQUIRED';
  END IF;

  SELECT u.*
    INTO v_actor
  FROM public.users u
  WHERE u.auth_id = auth.uid()
    AND COALESCE(u.status, 'Active') = 'Active'
  FOR SHARE;

  IF NOT FOUND OR v_actor.company_id IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_APPROVER_NOT_ACTIVE_IN_COMPANY';
  END IF;

  IF NULLIF(BTRIM(v_actor.email), '') IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_APPROVER_EMAIL_REQUIRED';
  END IF;

  IF NOT (
    app_private.current_user_has_effective_permission('purchases')
    OR app_private.current_user_has_effective_permission('purchases_supervisor')
  ) THEN
    RAISE EXCEPTION 'PURCHASE_PO_APPROVAL_PERMISSION_REQUIRED';
  END IF;

  SELECT po.*
    INTO v_po
  FROM public.purchase_orders po
  WHERE po.id = p_po_id
    AND po.company_id = v_actor.company_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PURCHASE_PO_NOT_FOUND_IN_COMPANY';
  END IF;

  IF v_po.status = 'Approved' THEN
    RETURN jsonb_build_object(
      'success', true,
      'duplicate', true,
      'id', v_po.id,
      'code', v_po.po_code,
      'status', 'Approved'
    );
  END IF;

  IF v_po.status <> 'Draft' THEN
    RAISE EXCEPTION 'PURCHASE_PO_NOT_APPROVABLE_FROM_STATUS:%', v_po.status;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.purchase_order_details d
    WHERE d.po_id = v_po.id
      AND COALESCE(d.qty_ordered, 0) > 0
  ) THEN
    RAISE EXCEPTION 'PURCHASE_PO_HAS_NO_VALID_ITEMS';
  END IF;

  PERFORM set_config('rawaea.purchase_actor', v_actor.email, true);

  UPDATE public.purchase_orders
  SET status = 'Approved',
      updated_at = now()
  WHERE id = v_po.id
    AND company_id = v_actor.company_id
    AND status = 'Draft';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PURCHASE_PO_APPROVAL_CONCURRENT_CHANGE';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'duplicate', false,
    'id', v_po.id,
    'code', v_po.po_code,
    'from_status', 'Draft',
    'status', 'Approved',
    'approved_by', v_actor.email
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.purchase_approve_po_atomic(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_approve_po_atomic(uuid) TO authenticated;
~~~

ضوابط التنفيذ:
- الشركة مأخوذة من المستخدم المصادق عليه، لا من payload.
- التحقق من المستخدم النشط وصلاحية purchases أو purchases_supervisor داخل قاعدة البيانات.
- قفل PO بـFOR UPDATE.
- لا يقبل إلا Draft؛ Approved يعيد duplicate success دون تكرار.
- لا يمنع منشئ PO من الاعتماد؛ هذا يطبق قرار المالك بأن صلاحية الوصول لدورة المشتريات تكفي.
- لا يغير أي بيانات PO سوى status وupdated_at.
- set_config يسمح لـtrigger الحالي بتسجيل actor في purchase_status_history. لا نضيف سجل تاريخ يدويًا مكررًا.
- لا حركة مخزون، ولا AP/GL، ولا خزينة.

### 5.2 حارس حالة PO قبل تسجيل الاستلام

~~~sql
CREATE OR REPLACE FUNCTION app_private.guard_po_receiving_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_po_status text;
BEGIN
  IF NULLIF(BTRIM(NEW.po_number), '') IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.company_id IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_RECEIVING_COMPANY_REQUIRED';
  END IF;

  SELECT po.status
    INTO v_po_status
  FROM public.purchase_orders po
  WHERE po.company_id = NEW.company_id
    AND po.po_code = NEW.po_number
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PURCHASE_PO_NOT_FOUND_FOR_RECEIVING';
  END IF;

  IF COALESCE(v_po_status, '') NOT IN ('Approved', 'Sent', 'Partially Received') THEN
    RAISE EXCEPTION 'PURCHASE_PO_NOT_APPROVED_FOR_RECEIVING';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION app_private.guard_po_receiving_status() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_receiving_require_approved_po ON public.receiving;

CREATE TRIGGER trg_receiving_require_approved_po
BEFORE INSERT ON public.receiving
FOR EACH ROW
EXECUTE FUNCTION app_private.guard_po_receiving_status();
~~~

الحالات المقبولة:
- Approved: الاستلام الأول بعد اعتماد المشرف/مخول النظام الأم.
- Sent: أوامر قديمة مرسلة بالفعل، توافقًا مع دورة البيانات التاريخية.
- Partially Received: استكمال الاستلام الجزئي.

Draft وReceived وCancelled مرفوضة. إذا كان سجل Receiving مرتبطًا برقم PO، فإن عدم وجود الشركة أو عدم العثور على PO يؤدي إلى رفض Fail-Closed. إذا كان po_number فارغًا، فلا يطبق هذا الحارس على عمليات Receiving غير المرتبطة بأوامر شراء.

## 6. استكمال تطبيق supervisor.html

### 6.1 بوابة الدخول

الموجود حاليًا يتحقق من purchases. يتغير شرط has إلى:
~~~js
var perms = Array.isArray(user.permissions) ? user.permissions : [];
var has = user.isOwner === true ||
          perms.indexOf('*') !== -1 ||
          perms.indexOf('purchases_supervisor') !== -1;
~~~

لا يمنح ذلك المستخدم صلاحيات مالية أو كتابة مباشرة على PO.

### 6.2 Realtime

أول سطر داخل switchTab:
~~~js
this.currentTab = t;
~~~

يعالج أن currentTab يستخدم في callbacks الحالية لكنه غير مضبوط عند تغيير التبويب.

### 6.3 Helpers

تضاف قبل تعريف App:
~~~js
function RW_PurchSupervisorEsc(v) {
    return String(v == null ? '' : v).replace(/[&<>"']/g, function(ch) {
        return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch];
    });
}
function RW_PurchSupervisorStatus(s) {
    var labels = {
        Draft:'مسودة',
        Approved:'تم الاعتماد',
        Sent:'مرسل للمورد',
        'Partially Received':'استلام جزئي',
        Received:'مكتمل الاستلام',
        Cancelled:'ملغي'
    };
    return labels[s] || s || '—';
}
~~~

ويضاف إلى App:
~~~js
currentOrders: [],
currentTab: 'dashboard',
~~~

### 6.4 استبدال renderOrders فقط

استبدل وظيفة renderOrders الحالية وحدها:
~~~js
renderOrders: async function(){
    var self = this;
    var companyId = this.currentUser && this.currentUser.company_id;
    if (!companyId) {
        RW_UI.showError('سياق الشركة غير متاح');
        return;
    }

    RW_UI.showSkeleton('mainContent', 3, 'card');

    try {
        var all = [];
        var offset = 0;
        var pageSize = 200;

        while (true) {
            var page = await supabase.from('purchase_orders')
                .select('id,company_id,po_code,po_date,supplier_name,branch_id,created_by,expected_delivery_date,total_amount,currency,status,notes,created_at')
                .eq('company_id', companyId)
                .order('po_date', {ascending:false})
                .order('created_at', {ascending:false})
                .range(offset, offset + pageSize - 1);

            if (page.error) throw page.error;

            var batch = page.data || [];
            all = all.concat(batch);

            if (batch.length < pageSize) break;
            offset += pageSize;
        }

        var branchResult = await supabase.from('branches')
            .select('id,name')
            .eq('company_id', companyId);

        if (branchResult.error) throw branchResult.error;

        var branchMap = {};
        (branchResult.data || []).forEach(function(b){ branchMap[b.id] = b.name || ''; });

        self.currentOrders = all;

        RW_UI.safeHTML(RW_UI.byId('mainContent'),
            '<div class="flex flex-col gap-3 mb-4">' +
              '<div><h2 class="text-lg font-black">جميع أوامر الشراء</h2>' +
              '<p class="text-xs text-gray-500">كل أوامر الشركة لجميع مسؤولي المشتريات — إجمالي ' + all.length + ' أمر</p></div>' +
              '<div class="grid grid-cols-1 md:grid-cols-2 gap-2">' +
                '<input id="pws-po-search" class="w-full p-3 border rounded-xl" placeholder="ابحث برقم PO أو المورد أو مسؤول المشتريات">' +
                '<select id="pws-po-status" class="w-full p-3 border rounded-xl">' +
                  '<option value="">كل الحالات</option>' +
                  '<option value="Draft">مسودة</option>' +
                  '<option value="Approved">تم الاعتماد</option>' +
                  '<option value="Sent">مرسل للمورد</option>' +
                  '<option value="Partially Received">استلام جزئي</option>' +
                  '<option value="Received">مكتمل الاستلام</option>' +
                  '<option value="Cancelled">ملغي</option>' +
                '</select>' +
              '</div>' +
            '</div>' +
            '<div class="bg-white rounded-2xl border overflow-auto">' +
              '<table class="w-full min-w-[1050px] text-sm"><thead class="bg-slate-50"><tr>' +
                '<th class="p-3">رقم PO</th><th class="p-3">التاريخ</th><th class="p-3">مسؤول المشتريات</th>' +
                '<th class="p-3">المورد</th><th class="p-3">الفرع</th><th class="p-3">موعد التوريد</th>' +
                '<th class="p-3">الحالة</th><th class="p-3">القيمة</th><th class="p-3">إجراء</th>' +
              '</tr></thead><tbody id="pws-po-rows"></tbody></table>' +
            '</div>'
        );

        var body = RW_UI.byId('pws-po-rows');
        var search = RW_UI.byId('pws-po-search');
        var statusSelect = RW_UI.byId('pws-po-status');

        function drawRows() {
            var q = String(search.value || '').trim().toLowerCase();
            var status = statusSelect.value || '';
            var rows = self.currentOrders.filter(function(o) {
                var haystack = [o.po_code,o.supplier_name,o.created_by,branchMap[o.branch_id]]
                    .join(' ').toLowerCase();
                return (!q || haystack.indexOf(q) !== -1) &&
                       (!status || o.status === status);
            });

            if (!rows.length) {
                RW_UI.safeHTML(body, '<tr><td colspan="9" class="text-center p-8 text-slate-400">لا توجد أوامر مطابقة.</td></tr>');
                return;
            }

            var html = '';
            rows.forEach(function(o) {
                html += '<tr class="border-t">' +
                  '<td class="p-3 font-black">' + RW_PurchSupervisorEsc(o.po_code) + '</td>' +
                  '<td class="p-3">' + RW_PurchSupervisorEsc(o.po_date || '—') + '</td>' +
                  '<td class="p-3 text-xs">' + RW_PurchSupervisorEsc(o.created_by || '—') + '</td>' +
                  '<td class="p-3">' + RW_PurchSupervisorEsc(o.supplier_name || '—') + '</td>' +
                  '<td class="p-3">' + RW_PurchSupervisorEsc(branchMap[o.branch_id] || '—') + '</td>' +
                  '<td class="p-3">' + RW_PurchSupervisorEsc(o.expected_delivery_date || '—') + '</td>' +
                  '<td class="p-3 font-bold">' + RW_PurchSupervisorEsc(RW_PurchSupervisorStatus(o.status)) + '</td>' +
                  '<td class="p-3 font-black">' + Number(o.total_amount || 0).toLocaleString() + ' ' + RW_PurchSupervisorEsc(o.currency || 'EGP') + '</td>' +
                  '<td class="p-3"><button type="button" data-pws-po-id="' + RW_PurchSupervisorEsc(o.id) + '" class="px-3 py-2 rounded-lg bg-fuchsia-50 text-fuchsia-700 font-black">عرض</button></td>' +
                '</tr>';
            });

            RW_UI.safeHTML(body, html);

            Array.from(body.querySelectorAll('[data-pws-po-id]')).forEach(function(btn) {
                btn.addEventListener('click', function() {
                    self.openPO(btn.getAttribute('data-pws-po-id'));
                });
            });
        }

        search.addEventListener('input', drawRows);
        statusSelect.addEventListener('change', drawRows);
        drawRows();

    } catch(e) {
        RW_UI.safeHTML(RW_UI.byId('mainContent'),
            '<div class="p-5 rounded-2xl bg-red-50 text-red-700 font-bold">' +
            RW_PurchSupervisorEsc(e.message || 'تعذر تحميل جميع أوامر الشراء') +
            '</div>'
        );
    }
},
~~~

هذه pagination متتابعة ولا تقف عند أول 50. تعرض جميع PO للشركة مع created_by. شرط company_id مع RLS يمنع رؤية شركة أخرى.

### 6.5 مودال التفاصيل والاعتماد

أضف داخل App قبل renderSuppliers:
~~~js
openPO: async function(poId) {
    var self = this;
    var po = this.currentOrders.find(function(x){ return String(x.id) === String(poId); });
    if (!po) {
        RW_UI.showError('أمر الشراء غير موجود في القائمة الحالية');
        return;
    }

    RW_UI.showLoader('جاري تحميل تفاصيل أمر الشراء...');
    try {
        var details = await supabase.from('purchase_order_details')
            .select('item_code,item_name,unit,qty_ordered,qty_received,unit_price')
            .eq('po_id', po.id)
            .order('created_at', {ascending:true});

        if (details.error) throw details.error;

        var html = '<div class="text-right space-y-3">' +
          '<div class="grid grid-cols-2 gap-2">' +
            '<div class="p-3 bg-slate-50 rounded-xl"><small>المورد</small><div class="font-black">' + RW_PurchSupervisorEsc(po.supplier_name || '—') + '</div></div>' +
            '<div class="p-3 bg-slate-50 rounded-xl"><small>مسؤول المشتريات</small><div class="font-black">' + RW_PurchSupervisorEsc(po.created_by || '—') + '</div></div>' +
            '<div class="p-3 bg-slate-50 rounded-xl"><small>الحالة</small><div class="font-black">' + RW_PurchSupervisorEsc(RW_PurchSupervisorStatus(po.status)) + '</div></div>' +
            '<div class="p-3 bg-slate-50 rounded-xl"><small>موعد التوريد</small><div class="font-black">' + RW_PurchSupervisorEsc(po.expected_delivery_date || '—') + '</div></div>' +
          '</div>' +
          '<div class="overflow-auto border rounded-xl"><table class="w-full text-sm"><thead class="bg-slate-50"><tr>' +
            '<th class="p-2">الصنف</th><th class="p-2">المطلوب</th><th class="p-2">المستلم</th><th class="p-2">المتبقي</th><th class="p-2">السعر</th>' +
          '</tr></thead><tbody>';

        (details.data || []).forEach(function(x) {
            var ordered = Number(x.qty_ordered || 0);
            var received = Number(x.qty_received || 0);
            html += '<tr class="border-t">' +
              '<td class="p-2"><b>' + RW_PurchSupervisorEsc(x.item_name || x.item_code) + '</b><div class="text-xs text-slate-400">' + RW_PurchSupervisorEsc(x.item_code) + '</div></td>' +
              '<td class="p-2 text-center">' + ordered + ' ' + RW_PurchSupervisorEsc(x.unit || '') + '</td>' +
              '<td class="p-2 text-center">' + received + '</td>' +
              '<td class="p-2 text-center font-black">' + Math.max(0, ordered - received) + '</td>' +
              '<td class="p-2 text-center">' + Number(x.unit_price || 0).toLocaleString() + '</td>' +
            '</tr>';
        });

        html += '</tbody></table></div>' +
          '<div class="font-black text-lg">الإجمالي: ' + Number(po.total_amount || 0).toLocaleString() + ' ' + RW_PurchSupervisorEsc(po.currency || 'EGP') + '</div>' +
          '<p class="text-xs text-slate-500">الاعتماد يصرح بالتوريد والاستلام فقط، ولا يثبت استلامًا أو حركة مخزون أو قيدًا ماليًا.</p>' +
        '</div>';

        RW_UI.hideLoader();

        var canApprove = po.status === 'Draft';
        var result = await Swal.fire({
            title: 'أمر الشراء ' + RW_PurchSupervisorEsc(po.po_code),
            html: html,
            width: '1000px',
            showCloseButton: true,
            showCancelButton: canApprove,
            showConfirmButton: canApprove,
            confirmButtonText: 'اعتماد أمر الشراء',
            cancelButtonText: 'إغلاق',
            confirmButtonColor: '#059669'
        });

        if (canApprove && result.isConfirmed) {
            self.approvePO(po.id);
        }
    } catch(e) {
        RW_UI.hideLoader();
        RW_UI.showError(e.message || 'تعذر تحميل تفاصيل أمر الشراء');
    }
},

approvePO: function(poId) {
    var self = this;
    if (!poId || !this.currentUser) {
        RW_UI.showError('بيانات الاعتماد غير مكتملة');
        return;
    }

    var perms = Array.isArray(this.currentUser.permissions) ? this.currentUser.permissions : [];
    if (!(this.currentUser.isOwner === true || perms.indexOf('*') !== -1 || perms.indexOf('purchases_supervisor') !== -1)) {
        RW_UI.showError('اعتماد PO يتطلب صلاحية مشرف المشتريات');
        return;
    }

    var operationId = (window.crypto && crypto.randomUUID)
        ? crypto.randomUUID()
        : 'PO-APPROVE-' + String(poId) + '-' + String(Date.now());

    RW_UI.showLoader('جاري اعتماد أمر الشراء...');
    RW_API.call('save-purchase-order', {
        operation: 'APPROVE_PO',
        payload: { id: poId },
        operation_id: operationId
    }, function(json, err) {
        RW_UI.hideLoader();

        if (err || !json || json.success !== true) {
            RW_UI.showError((json && json.msg) || err || 'فشل اعتماد أمر الشراء');
            return;
        }

        Swal.fire({
            icon: 'success',
            title: 'تم اعتماد أمر الشراء',
            text: 'أصبح الأمر مصرحًا بتوريده والاستلام به في المخزن.'
        }).then(function() {
            self.renderOrders();
        });
    });
},
~~~

المشرف لا يجري UPDATE من التطبيق. يستخدم Edge نفسها وRPC نفسها. هذا يجعل سجل التاريخ وسلوك الاعتماد موحدين من القناتين.

## 7. Receiver — ما تم إصلاحه بالفعل وما بقي

الموجود في Receiver الحالي صحيح ويجب الحفاظ عليه:
- Approved داخل قائمة الحالات، مع Sent وPartially Received.
- تحميل purchase_orders.id.
- تحميل التفاصيل عبر purchase_order_details.po_id = purchase_orders.id.
- قراءة qty_received وعرض المطلوب/المستلم/المتبقي.
- parseFloat للكميات الكسرية.

### 7.1 التعامل الصحيح مع خطأ تحميل التفاصيل

داخل loadPODetails بعد:
~~~js
.then(function(r) {
~~~

أضف:
~~~js
            if (r.error) {
                RW_UI.safeHTML(
                    RW_UI.byId('details-' + i),
                    '<p class="text-rose-600 text-center py-4">تعذر تحميل تفاصيل أمر الشراء: ' + String(r.error.message || 'خطأ') + '</p>'
                );
                return;
            }
~~~

### 7.2 لا ترسل أسطرًا صفرية

استبدل:
~~~js
items.push({ itemCode: itemCode, itemName: '', receivedQty: q, reason: '' });
~~~

بـ:
~~~js
if (q > 0) {
    items.push({ itemCode: itemCode, itemName: '', receivedQty: q, reason: '' });
}
~~~

وبعد انتهاء الحلقة مباشرة وقبل RW_UI.showConfirm أضف:
~~~js
if (!items.length) {
    RW_UI.showError('أدخل كمية موجبة لصنف واحد على الأقل قبل اعتماد الاستلام');
    return;
}
~~~

### 7.3 منع استلام صفري في Edge receive-purchase

داخل Edge v13 بعد إنشاء مصفوفة items أضف:
~~~ts
if (!items.some((x: any) => Number(x.received_qty) > 0)) {
  throw new Error("يجب إدخال كمية موجبة لصنف واحد على الأقل");
}
~~~

يصبح الإصدار v14، وتبقى صلاحيات مستلم المخزن والفرع الحالية كما هي.

## 8. تسلسل التنفيذ بعد الموافقة

1. تطبيق Migration واحدة تتضمن RPC اعتماد PO وحارس Receiving.
2. تحديث Edge القائمة save-purchase-order من v29 إلى v30.
3. تحديث Edge القائمة receive-purchase من v13 إلى v14.
4. تعديل سطرَي الصلاحية في main.html.
5. استكمال supervisor.html بالبوابة الخاصة والصفحات التفصيلية والاعتماد.
6. تعديل الحواف الصغيرة في receiver.html.
7. Commit إلى main؛ لا Branch ولا PR منفصل. Cloudflare Pages تنشر تلقائيًا.
8. حفظ نسخ Edge قبل/بعد النشر في EdgeSnapshots وتحديث CURRENT_STATE وProject Memory.
9. التحقق من Production deployment commit ثم اختبارات E2E للقناتين والاستلام.

## 9. اختبارات القبول والبيانات التجريبية

لا نستخدم PO الحقيقي الحالي QA-SR-PO-20260927 ولا نغيّر حالته للتجربة.

تُنشأ بيانات PO اختبارية اصطناعية بعلامة QA-PO-APPROVAL-TXN داخل معاملة SQL معزولة وتُعاد بـROLLBACK كامل بعد الاختبار؛ لا تترك PO أو تفاصيل أو History أو Receiving أو Inventory Log أو Supplier Ledger أو Journal أو Treasury. تُستخدم هوية/صلاحية مستخدم test مناسبة وتُضبط claims في transaction test، دون تغيير صلاحيات أي مستخدم حقيقي.

الاختبارات:
- مستخدم purchases فقط يستطيع اعتماد PO من النظام الأم.
- مشرف purchases_supervisor فقط يستطيع الدخول إلى supervisor.html واعتماد PO.
- مستخدم لا يملك أيًا من الصلاحيتين يُرفض في Edge/RPC حتى باستدعاء مباشر.
- Owner/* يستطيع الاعتماد من القناتين.
- قائمة المشرف تتجاوز 50 PO بواسطة pagination، وتعرض كل منشئي الأوامر.
- PO من شركة أخرى لا يظهر ولا يمكن اعتماده.
- Draft يتحول إلى Approved مرة واحدة ويسجل trigger الانتقال والفاعل.
- تكرار اعتماد Approved يعيد duplicate success ولا ينشئ سجل حالة مكررًا.
- Draft لا يمكن استلامه؛ الحارس يرفض قبل أي أثر.
- Approved يسمح بالاستلام، والكمية الجزئية تظل ضمن المتبقي، وReceived لا يقبل استلامًا جديدًا.
- Receiver يتعامل مع فشل تحميل التفاصيل ولا يعرضه على أنه قائمة فارغة.
- الكمية صفر أو مصفوفة استلام بلا كمية موجبة تُرفض في UI وEdge.
- لا توجد حركة مخزون أو AP/GL أو خزينة بمجرد الاعتماد؛ بعد الاستلام الفعلي فقط ينفذ محرك receive_purchase_atomic أثره الحالي.

## 10. التراجع

- main.html وsupervisor.html وreceiver.html: الرجوع عن commit التعديلات الجراحية فقط.
- save-purchase-order: إعادة نشر نسخة v29 المحفوظة قبل v30؛ لا تنشأ Edge أخرى.
- receive-purchase: إعادة نشر v13 المحفوظة قبل v14.
- Migration عكسية تحذف trigger المحدد، ثم دالة guard، ثم RPC بعد التأكد من عدم وجود مستهلك آخر.
- لا يعاد PO Approved إلى Draft تلقائيًا ولا يحذف purchase_status_history.
- أي استلام حقيقي بعد النشر لا يُعكس بحذف بيانات؛ يخضع لدورة العكس المخزني/المحاسبي المعتادة.

## 11. ما لم يُنفذ في هذه المراجعة

لم يتم تعديل main.html أو receiver.html أو supervisor.html، ولم يتم تحديث Edge، ولم تُطبق Migration أو RPC أو Trigger، ولم تتغير حالة PO الحقيقي، ولم تُنشأ بيانات اختبار. كل النتائج أعلاه مبنية على قراءة Git وCloudflare وSupabase فقط.

## 12. اعتماد ChangeSet

هذا التقرير يحتوي عقد الصلاحيات المعدل ومقاطع main الجراحية وتعديلات supervisor/receiver ومصدر Edge وSQL والاختبارات والتراجع. طبقًا لـMaster CTO Governance §77.2، لا يتم إجراء كتابة Production أو نشر Edge أو تطبيق Migration قبل اعتماد المالك لهذه الحزمة الدقيقة.

بعد الاعتماد الصريح على Report635، يقوم CTO بتنفيذ جميع تغييرات Production بنفسه، ثم الاختبار والنشر والتحقق وتحديث CURRENT_STATE وProject Memory.