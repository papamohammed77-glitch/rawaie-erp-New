# Report634 — اعتماد أوامر الشراء من النظام الأم وربط الاعتماد بإتاحة الاستلام
**التاريخ:** 2026-11-05  
**النطاق:** ChangeSet جراحي معروض للمالك. هذه الوثيقة لا تنفذ أي تغيير تشغيلي أو كتابة في Production.

## 1. المطلوب

إضافة اعتماد PO من النظام الأم داخل دورة المشتريات ← أوامر الشراء. يفتح المستخدم أمر الشراء من القائمة، ويظهر للمشرف المخول زر «اعتماد أمر الشراء» داخل مودال التفاصيل. بعد الاعتماد تتحول الحالة إلى Approved، وتعرض بالعربية «تم الاعتماد»، ويصبح الأمر ظاهرًا في تطبيق استلام المخزن.

اعتماد PO لا يثبت استلامًا ولا ينشئ حركة مخزون أو ذمم موردين أو قيد دفتر أستاذ أو حركة خزينة. هذه الآثار تظل مرتبطة باستلام الكمية الفعلية عبر محرك الاستلام الحالي.

لا نضيف تبويبًا جديدًا ولا نعيد بناء الشاشة أو المودال. تبويب أوامر الشراء ومودال عرض التفاصيل موجودان بالفعل؛ المطلوب إضافة إجراء اعتماد صغير داخل المودال وربطه بخدمة خادم محمية.

## 2. الأدلة الحية

- مستودع التشغيل: papamohammed77-glitch/erp-frontend، الفرع main، آخر HEAD موثق عند نقطة البدء: 7060bbbf6040bae5c4f02145d6c0a638b6131087.
- الملف الأم: companies/company-1/main.html. [فتح الملف](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html)
- التبويب موجود في RW_PurchaseGold.tabs()، والقائمة تعرضها RW_PurchaseGold.orders(host) في الأسطر الحالية 13244–13298. زر «عرض» يستدعي RW_Purchases._openPO(po_code).
- مودال التفاصيل موجود في RW_Purchases.openPO(poCode) بالأسطر الحالية 12059–12072. يعرض المورد والحالة والبنود والإجمالي ولا يحتوي زر اعتماد.
- RW_PurchaseGold.api() موجود بالفعل ويرسل العمليات إلى Edge الحالية save-purchase-order؛ يعاد استخدام Edge نفسها ولا تنشأ Edge جديدة.
- RW_Permissions_check('purchases_supervisor') موجود في النظام الأم، ويعرف صلاحية المشرف والمالك ونجمة الصلاحيات.
- Production: جدول purchase_orders عليه RLS، وauthenticated لديه SELECT ولا يملك UPDATE. سياسات الجدول الحالية للقراءة فقط. لذلك تحديث الحالة مباشرة من JavaScript غير مسموح وغير مقبول.
- Edge save-purchase-order حية ACTIVE v29، SHA-256: 35caa4f2759ba608a7f3bf86640b4773280bc84447872267d6e4d53896743e04. لا تحتوي العملية APPROVE_PO.
- قاعدة البيانات لا تحتوي RPC لاعتماد PO. الموجود purchase_create_po_atomic ينشئ Draft، وpurchase_approve_request_atomic يخص طلب الشراء PR وليس أمر الشراء PO.
- جدول purchase_status_history موجود، والـtrigger trg_purchase_orders_status_history يسجل تغير حالة PO تلقائيًا. يلتقط trigger قيمة rawaea.purchase_actor كمنفذ؛ نضبطها قبل تحديث الحالة ولا نضيف سجلًا يدويًا ثانيًا.
- يوجد حاليًا في Production أمر شراء واحد وحالته Draft. لا يجوز استخدام هذا المستند الحقيقي كتجربة اعتماد.
- فحص صلاحيات المستخدمين الحالي أعاد وجود مستخدم نشط واحد يحمل purchases_supervisor، ويحمل أيضًا purchases ونجمة الصلاحيات؛ لذلك يستطيع رؤية عنصر دورة المشتريات في قائمة النظام الأم. هذا تحديث عن لقطة Report633 السابقة.
- Receiver يعرض حاليًا PO بحالتي Sent وPartially Received فقط، فلا يعرض Approved.
- عيب Receiver إضافي مثبت: يستعلم عن purchase_order_details.po_code رغم أن العمود غير موجود؛ الربط الصحيح هو purchase_order_details.po_id = purchase_orders.id.
- receive_purchase_atomic يتحقق من مستلم المخزن والفرع والكمية، ثم ينشئ Receiving ويثبت PurchaseIn ويحدث المخزون وذمة المورد. لكنه لا يفرض حاليًا حالة PO مؤهلة للاستلام؛ لذلك يلزم حارس خادمي قبل إنشاء Receiving.

## 3. دورة العمل المستهدفة

1. مسؤول المشتريات ينشئ PO بالطريقة الحالية؛ تظل الحالة Draft.
2. مشرف المشتريات يفتح PO من النظام الأم. يظهر زر الاعتماد عندما تكون الحالة Draft وتتوفر صلاحية purchases_supervisor.
3. الخادم يعيد التحقق من صلاحية المشرف ومن حالة Draft ومن أن المشرف ليس منشئ الأمر. ثم يعتمد PO ذريًا إلى Approved.
4. trigger التاريخ الموجود يسجل انتقال Draft → Approved وهوية منفذ الاعتماد ووقت الحدث.
5. قائمة Receiver تعرض Approved باسم «تم الاعتماد»، وتتيح فتح تفاصيله واستلام المتبقي فقط.
6. أول استلام يحول PO إلى Partially Received أو Received بالطريقة القائمة. يظل الاستلام الجزئي اللاحق مسموحًا.
7. لا ينشئ اعتماد PO وحده أي أثر مخزني أو محاسبي؛ الأثر ينتج عند الاستلام الفعلي فقط.

## 4. التعديل الجراحي في main.html

### 4.1 ترجمة الحالة في جدول أوامر الشراء

الموضع: RW_PurchaseGold.orders(host)، السطر الحالي 13289.

المقطع الحالي:
~~~js
'<td class="p-3">' + esc(x.status) + '</td>' +
~~~

استبدله بهذا السطر فقط:
~~~js
'<td class="p-3">' + esc(({Draft:'مسودة',Approved:'تم الاعتماد',Sent:'مرسل للمورد','Partially Received':'استلام جزئي',Received:'مكتمل الاستلام',Cancelled:'ملغي'})[x.status] || x.status || '—') + '</td>' +
~~~

### 4.2 إضافة زر الاعتماد إلى مودال PO الحالي

الموضع: RW_Purchases.openPO(poCode)، بعد السطر الذي ينهي بناء جدول البنود والإجمالي مباشرة، أي بعد:
~~~js
h += '</tbody></table><div class="mt-4 font-black text-lg">الإجمالي: ' + (Number(poRes.data.total_amount) || 0).toLocaleString() + ' EGP</div></div>';
~~~

أضف بعده:
~~~js
      var canApprovePO = poRes.data.status === 'Draft' && RW_Permissions_check('purchases_supervisor');
      if (canApprovePO) {
        h += '<div class="mt-4 flex justify-start"><button type="button" id="po-approve-btn" class="px-5 py-3 rounded-xl bg-emerald-600 text-white font-black"><i class="fa-solid fa-check ml-2"></i>اعتماد أمر الشراء</button></div>' +
          '<p class="mt-2 text-xs text-slate-500">بعد الاعتماد يصبح الأمر متاحًا للاستلام بالمخزن. الاعتماد لا يثبت استلامًا ولا ينشئ حركة مخزون أو قيدًا محاسبيًا.</p>';
      }
~~~

وفي سطر الحالة داخل بناء رأس المودال، استبدل التعبير فقط:

الموجود:
~~~js
esc(poRes.data.status)
~~~

البديل:
~~~js
esc(({Draft:'مسودة',Approved:'تم الاعتماد',Sent:'مرسل للمورد','Partially Received':'استلام جزئي',Received:'مكتمل الاستلام',Cancelled:'ملغي'})[poRes.data.status] || poRes.data.status || '—')
~~~

استبدل سطر فتح Swal الحالي:
~~~js
hideLoader(); Swal.fire({ title: 'تفاصيل ' + esc(poCode), html: h, width: '820px', showConfirmButton: false, showCloseButton: true });
~~~

بهذا المقطع فقط:
~~~js
      hideLoader();
      Swal.fire({
        title: 'تفاصيل ' + esc(poCode),
        html: h,
        width: '820px',
        showConfirmButton: false,
        showCloseButton: true,
        didOpen: function () {
          var approveBtn = byId('po-approve-btn');
          if (approveBtn) approveBtn.addEventListener('click', function () {
            Swal.close();
            if (window.RW_PurchaseGold && typeof window.RW_PurchaseGold.approvePO === 'function') {
              window.RW_PurchaseGold.approvePO(poRes.data.id);
            } else {
              showToast('مسار اعتماد أمر الشراء غير متاح', 'error');
            }
          });
        }
      });
~~~

### 4.3 إضافة إجراء الاعتماد داخل RW_PurchaseGold

الموضع: داخل RW_PurchaseGold، أضف الوظيفة التالية قبل async function orders(host) { مباشرة. لا تستبدل orders() ولا أي دالة كاملة.

~~~js
  async function approvePO(poId) {
    if (!RW_Permissions_check('purchases_supervisor')) {
      showToast('اعتماد أمر الشراء يتطلب صلاحية مشرف المشتريات', 'error');
      return;
    }
    if (!poId) {
      showToast('معرّف أمر الشراء غير صالح', 'error');
      return;
    }

    var confirmation = await Swal.fire({
      title: 'اعتماد أمر الشراء؟',
      text: 'ستتحول الحالة من مسودة إلى تم الاعتماد، ويصبح الأمر متاحًا للاستلام بالمخزن. الاعتماد وحده لا يثبت حركة مخزون أو قيدًا ماليًا.',
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'اعتماد الأمر',
      cancelButtonText: 'إلغاء',
      confirmButtonColor: '#059669'
    });
    if (!confirmation.isConfirmed) return;

    showLoader('جاري اعتماد أمر الشراء...');
    try {
      var result = await api('APPROVE_PO', { id: poId });
      hideLoader();
      if (!result || result.success === false) throw new Error((result && result.msg) || 'فشل اعتماد أمر الشراء');
      showToast('تم اعتماد أمر الشراء وأصبح جاهزًا للاستلام', 'success');
      active = 'orders';
      await refresh();
    } catch (e) {
      hideLoader();
      showToast(e.message || 'تعذر اعتماد أمر الشراء', 'error');
    }
  }
~~~

وفي return object الموجود في نهاية RW_PurchaseGold، أضف خاصية واحدة فقط بعد approveRequest:
~~~js
    approvePO: approvePO,
~~~

لا تستخدم supabase.from('purchase_orders').update() في النظام الأم؛ صلاحية UPDATE غير ممنوحة لـauthenticated، ويجب أن يتم التحديث من RPC محمية.

## 5. التغيير الخادمي الضروري في Edge الحالية

Edge save-purchase-order الحالية v29 يعاد استخدامها. لا تنشئ Edge جديدة ولا تعِد نشر نسخة قديمة من المستودع فوق المصدر الحي.

### 5.1 شرط الصلاحية

في كتلة authorization التي تبدأ حاليًا بـ:
~~~ts
if (op === "SAVE_SETTINGS") {
~~~

أضف الشرط التالي قبلها:
~~~ts
if (op === "APPROVE_PO") {
  requireAny(["purchases_supervisor"]);
} else if (op === "SAVE_SETTINGS") {
~~~

بهذا لا تكفي صلاحية purchases وحدها؛ الاعتماد يحتاج purchases_supervisor أو المالك/الصلاحية الشاملة طبقًا لمساعد الصلاحيات الموجود.

### 5.2 تنفيذ العملية

في كتلة dispatch، بعد فرع CREATE_PO وقبل SUBMIT_REQUEST، أضف:
~~~ts
    } else if (op === "APPROVE_PO") {
      ({ data, error } = await profileClient.rpc("purchase_approve_po_atomic", {
        p_company_id: companyId,
        p_po_id: p.id,
        p_actor_email: user.email
      }));
~~~

يصل RPC رمز المستخدم نفسه عبر profileClient، ويعيد التحقق من الصلاحية داخل قاعدة البيانات أيضًا؛ لا يعتمد على إخفاء الزر بالواجهة.

## 6. SQL — RPC اعتماد PO

هذه وظيفة جديدة منفصلة، وليست تعديلًا على purchase_create_po_atomic أو purchase_approve_request_atomic. تعيد استخدام سجل purchase_status_history والـtrigger الموجودين.

~~~sql
CREATE OR REPLACE FUNCTION public.purchase_approve_po_atomic(
  p_company_id uuid,
  p_po_id uuid,
  p_actor_email text
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
    AND u.company_id = p_company_id
    AND COALESCE(u.status, 'Active') = 'Active'
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PURCHASE_APPROVER_NOT_ACTIVE_IN_COMPANY';
  END IF;

  IF NOT app_private.current_user_has_effective_permission('purchases_supervisor') THEN
    RAISE EXCEPTION 'PURCHASE_PO_APPROVAL_PERMISSION_REQUIRED';
  END IF;

  IF NULLIF(BTRIM(v_actor.email), '') IS NULL
     OR LOWER(BTRIM(v_actor.email)) IS DISTINCT FROM LOWER(BTRIM(COALESCE(p_actor_email, ''))) THEN
    RAISE EXCEPTION 'PURCHASE_PO_APPROVER_IDENTITY_MISMATCH';
  END IF;

  SELECT po.*
    INTO v_po
  FROM public.purchase_orders po
  WHERE po.id = p_po_id
    AND po.company_id = p_company_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PURCHASE_PO_NOT_FOUND';
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

  IF LOWER(BTRIM(COALESCE(v_po.created_by, ''))) = LOWER(BTRIM(v_actor.email)) THEN
    RAISE EXCEPTION 'PURCHASE_PO_SELF_APPROVAL_FORBIDDEN';
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
    AND company_id = p_company_id
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

REVOKE ALL ON FUNCTION public.purchase_approve_po_atomic(uuid, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_approve_po_atomic(uuid, uuid, text) TO authenticated;
~~~

الضوابط:
- Auth UID والشركة والمستخدم النشط وصلاحية purchases_supervisor يتم التحقق منها خادميًا.
- يقفل PO بـFOR UPDATE لمنع اعتماد متزامن.
- لا يعتمد إلا Draft، ويعيد نتيجة مكررة بلا أثر إن كان Approved مسبقًا.
- يمنع منشئ الأمر من اعتماد أمره بنفسه.
- لا يغير الأصناف أو الكميات أو الأسعار أو المورد أو الفرع.
- لا يكتب مخزونًا أو AP/GL أو خزينة.
- يسجل trigger الموجود الانتقال Draft → Approved وهوية المشرف ووقت التغيير؛ لا نضيف INSERT يدويًا ثانيًا إلى سجل التاريخ.
- لا تضاف أعمدة جديدة إلى purchase_orders.

## 7. حارس الاستلام الخادمي

إضافة Approved إلى قائمة Receiver وحدها لا تكفي؛ receive_purchase_atomic الحالي لا يمنع Draft على مستوى قاعدة البيانات. لتجنب استبدال الدالة الطويلة، يعزل الحارس في trigger صغير على سجل Receiving. يعمل فقط إذا تطابق رقم الاستلام مع أمر شراء موجود؛ سجلات Receiving غير المرتبطة بـPO لا تتأثر.

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

DROP TRIGGER IF EXISTS trg_receiving_require_approved_po ON public.receiving;

CREATE TRIGGER trg_receiving_require_approved_po
BEFORE INSERT ON public.receiving
FOR EACH ROW
EXECUTE FUNCTION app_private.guard_po_receiving_status();
~~~

حالات الاستلام المسموح بها للتوافق: Approved وSent القديمة وPartially Received. Draft وReceived وCancelled لا تسمح بإنشاء سجل استلام جديد. وقد فُحصت دوال Production، وكان receive_purchase_atomic هو مسار INSERT الوحيد إلى public.receiving؛ لذلك يمكن أن يكون الحارس fail-closed عند وجود po_number: يرفض غياب company_id أو عدم العثور على PO بدل المرور الصامت. إذا فشل الحارس تتراجع المعاملة كلها قبل حركة المخزون أو ذمة المورد.

## 8. التعديل الجراحي المطلوب في Receiver

هذا الجزء ليس داخل main.html، لكنه لازم حتى يترجم اعتماد المشرف إلى ظهور PO للمخزن.

الملف: companies/company-1/warehouse/receiver.html  
[فتح الملف](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/warehouse/receiver.html)

### 8.1 إظهار Approved في قائمة الاستلام

استبدل:
~~~js
supabase.from('purchase_orders').select('po_code, po_date, supplier_name, status, total_amount').in('status', ['Sent', 'Partially Received'])
~~~

بـ:
~~~js
supabase.from('purchase_orders').select('id, po_code, po_date, supplier_name, status, total_amount').in('status', ['Approved', 'Sent', 'Partially Received'])
~~~

### 8.2 ترجمة الحالة

استبدل السطرين الحاليين:
~~~js
var sc = po.status === 'Sent' ? 'bg-amber-50 text-amber-600' : 'bg-orange-50 text-orange-600';
var sl = po.status === 'Sent' ? 'مُرسل' : 'استلام جزئي';
~~~

بهذين السطرين:
~~~js
var sc = po.status === 'Approved' ? 'bg-emerald-50 text-emerald-700' : po.status === 'Sent' ? 'bg-amber-50 text-amber-600' : 'bg-orange-50 text-orange-600';
var sl = po.status === 'Approved' ? 'تم الاعتماد' : po.status === 'Sent' ? 'مُرسل' : 'استلام جزئي';
~~~

### 8.3 ربط تفاصيل PO بالمفتاح الصحيح

داخل loadPODetails(i, code)، استبدل استعلام التفاصيل الحالي:
~~~js
supabase.from('purchase_order_details').select('item_code, item_name, qty_ordered, unit').eq('po_code', code).then(function(r) {
~~~

بالمقطع التالي:
~~~js
        var po = self.purchaseOrders.find(function (x) { return x.po_code === code; });
        if (!po || !po.id) {
          RW_UI.safeHTML(RW_UI.byId('details-' + i), '<p class="text-rose-600 text-center py-4">تعذر ربط تفاصيل أمر الشراء.</p>');
          return;
        }
        supabase.from('purchase_order_details')
          .select('item_code, item_name, qty_ordered, qty_received, unit')
          .eq('po_id', po.id)
          .then(function(r) {
~~~

وداخل حلقة عرض الأصناف، استبدل جسم بناء السطر الحالي بالمقطع التالي ليعرض المطلوب والمستلم والمتبقي، ولا يعيد طلب كامل الكمية بعد استلام جزئي:
~~~js
             for (var j = 0; j < items.length; j++) {
                 var it = items[j];
                 var ordered = Number(it.qty_ordered) || 0;
                 var received = Number(it.qty_received) || 0;
                 var remaining = Math.max(0, ordered - received);
                 html += '<div class="flex justify-between items-center p-3 border-b"><div><p class="font-bold">' + (it.item_name || '') + '</p><p class="text-xs text-slate-400">' + it.item_code + ' | مطلوب: ' + ordered + ' | مستلم: ' + received + ' | متبقي: ' + remaining + ' ' + (it.unit || 'حبة') + '</p></div><input type="number" step="0.01" id="qty-' + i + '-' + j + '" value="' + remaining + '" min="0" max="' + remaining + '" class="w-20 p-2 border rounded-xl text-center font-bold text-sm" data-item-code="' + it.item_code + '"></div>';
             }
~~~

وفي submitReceiving استبدل:
~~~js
var q = parseInt(qtyInputs[j].value) || 0;
~~~

بـ:
~~~js
var q = parseFloat(qtyInputs[j].value) || 0;
~~~

هذا يمنع اقتطاع الكميات الكسرية قبل إرسالها لمحرك الاستلام.

## 9. ترتيب التنفيذ

لا تطبق زر الواجهة وحده. الترتيب الفني الصحيح:
1. إنشاء RPC اعتماد PO وحارس Receiving.
2. إضافة شرط الصلاحية وفرع التنفيذ إلى Edge الحية save-purchase-order ثم نشر نسخة جديدة من نفس Edge.
3. إدخال تعديلات main.html أعلاه.
4. إدخال تعديلات Receiver أعلاه.
5. إجراء اختبارات قبول في بيئة اختبار منفصلة أو PO اختبار قابل للتنظيف بالكامل، لا على أمر Draft الحقيقي الموجود في Production.

## 10. اختبارات القبول

- مستخدم purchases فقط: لا يظهر له زر الاعتماد، واستدعاء APPROVE_PO مباشرة يُرفض.
- مشرف نشط بصلاحية purchases_supervisor: يرى زر الاعتماد لأمر Draft فقط.
- منشئ PO لا يعتمد أمره بنفسه.
- الاعتماد الصحيح يحول Draft إلى Approved مرة واحدة، ويسجل الحدث وهوية المشرف في purchase_status_history.
- إعادة الاعتماد لا تنتج سجل تاريخ مكررًا أو أثرًا آخر.
- PO Draft لا يظهر في Receiver ولا يمكن إنشاء Receiving له عبر استدعاء مباشر.
- PO Approved يظهر في Receiver وتُحمّل تفاصيله عبر po_id.
- الاستلام الجزئي يسمح بالكمية المتبقية فقط، ويحول الحالة إلى Partially Received؛ وتظهر الكمية المتبقية في المحاولة التالية.
- الاستلام الكامل يحول الحالة إلى Received.
- اعتماد PO وحده لا يغير المخزون أو ذمم المورد أو القيود أو الخزينة.
- اختبارات رفض مستخدم غير مخول، وPO خارج الشركة، وحالة غير Draft للاعتماد، وكمية تتجاوز المتبقي.

لا تستخدم PO الحقيقي الحالي كتجربة؛ لا تغيّر حالته لغرض الاختبار.

## 11. المخاطر والتراجع

- لا تفتح UPDATE مباشرًا على purchase_orders ولا تخفف RLS.
- لا تمنح مشرف المشتريات صلاحيات المالية أو الاستلام لمجرد تشغيل الاعتماد.
- لا تغير purchase_create_po_atomic ولا منطق ترحيل الفاتورة أو محرك PurchaseIn.
- عند الفشل: أوقف زر الواجهة وأعد Edge إلى النسخة السابقة من نفس المصدر. لا تحذف حالات Approved المسجلة ولا تعدّل سجل التاريخ تلقائيًا.
- تراجع حارس الاستلام: حذف trigger المحدد ثم دالة الحارس بعد التأكد من عدم اعتماد مسار الاستلام عليها. لا ترجع حالات PO إلى Draft آليًا.
- Buyer وفصل فاتورة المورد يظلان خارج هذا التغيير.

## 12. ما لم يُنفذ

لم يتم تعديل main.html أو receiver.html أو Edge، ولم يتم إنشاء RPC أو trigger أو migration، ولم يتم نشر Cloudflare أو Edge جديدة. لم تتغير أي بيانات Production ولم يُعتمد PO ولم تُنشأ بيانات اختبار. هذه وثيقة تغيير معروضة للمالك وليست إثباتًا بأن الخاصية أصبحت حية.

**بوابة Report614 §14:** لا يبدأ أي تغيير تشغيلي في النظام الأم أو Production قبل اعتماد المالك للحزمة الدقيقة.
