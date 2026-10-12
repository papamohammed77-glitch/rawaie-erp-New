# Report425 — تنفيذ نواة إدارة ورديات الكاشير وربطها المالي
**التاريخ:** 2026-10-13  
**النطاق:** POS / Shift lifecycle / cash reconciliation فقط  
**البيئة:** Supabase Production `fiilmooggumokxanwiyx` + GitHub  
**حالة التنفيذ:** `PRODUCTION DB CORE DEPLOYED + TRANSACTION-TESTED / OWNER POS PATCH REQUIRED / NOT 100% CLOSED`

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** 96/100 — البيع النقدي والمرتجعات النقدية يمران أصلًا عبر عقود مالية موجودة؛ لا يجوز إنشاء دفتر نقدية موازٍ.
- **Architecture Understanding:** 95/100 — POS مستقل، بينما النظام الأم يظل مركز الرقابة؛ لم أعدّل `main.html` أو ملف POS التشغيلي.
- **Database Understanding:** 94/100 — تمت مراجعة تعريفات `orders` و`cash_box` و`treasury` و`sales_payment_receipts` وقيودها ومحركاتها المالية ذات الصلة.
- **Historical Understanding:** 93/100 — قورنت نسخة POS التاريخية بالمصدر الحالي، وقرئت ADR ومقترح الكاشير؛ رفضت SQL المقترح الذي ينشئ دفتر `cash_movements` مستقلًا ويكرر الحقيقة المالية.
- **Production Understanding:** 97/100 — فُحصت قاعدة البيانات الحية وACL والـEdge Functions قبل التغيير وبعده.
- **Current Understanding:** 97/100 — Current POS: `erp-frontend/companies/company-1/sales/pos.html`, blob SHA `54dce2c9ad1e08e154965beb92d9d494607e42c9`, 92,037 characters / 1,575 lines.
- **Execution Confidence:** 90/100 لنواة قاعدة البيانات فقط؛ لا أرفعها إلى 100% لأن واجهة POS لم تُنشر ولا يوجد HTTP/browser E2E حتى الآن.

### مصادر الفحص المباشر

| المصدر | ما تم التحقق منه |
|---|---|
| Current POS | SHA `54dce2c9ad1e08e154965beb92d9d494607e42c9`; لم يتغير خلال التنفيذ |
| Historical POS | `rawaie-erp-review/PWA/sales/pos.html`, SHA `6ad4da791b72260b922847246ebce93b552d2bad`, 80,447 characters / 1,115 lines |
| POS proposal | `doc/Draft/Reprots/اقتراح تطبيق الكاشير-من مساعدد`, blob `d8badc619764e41b77b12a98e80a2b68c99b99cc`, 10,965 characters |
| ADR | `doc/Draft/Reprots/ADR_POS_SHIFT_MANAGEMENT_P0_20261013.md`, blob `3158bd3e3e69be32265641d6fbabc15490f98158` |
| Production sale Edge | `save-sales-invoice v18`, `verify_jwt=true`, SHA `43d20f1465725c4e273f717ac927c070d4b28be48241bd2c9c46a6d43bb40308` |
| Production return Edge | `complete-return v26`, `verify_jwt=true`, SHA `801e390b195522caedfcf68bae8262bb91da06e909c1d43e9344490e3a81f34d` |

**مقارنة Current/Historical:** لم تظهر معرفات HTML جديدة بين النسختين في المسح الآلي؛ توجد 65 دالة `self.*` في Current مقابل 63 في Historical، والدالتان الجديدتان هما `_getPosInvoiceData` و`_escapePosText`. حافظت على بنية البيع الحالية ولم أستبدل الملف.

### حقائق Production قبل التعديل

- لم تكن جداول `pos_terminals` أو `pos_shifts` أو `pos_shift_cash_counts` أو `pos_shift_events` موجودة.
- لم يكن `orders.shift_id` أو `cash_box.shift_id` موجودًا.
- المستخدم التشغيلي `cashier@rawaea.com` لديه `public.users.id = 4cd61391-b14c-4194-813c-221acac9f57e`، بينما `auth_id = 8dbcede3-3a94-40c6-a6c9-7d500f127f4a`. كل التحقق الأمني الجديد يعتمد `auth.uid() → users.auth_id → users.id/company_id`، وليس الخلط بين المعرفين.
- يوجد حاليًا صندوق خزينة نشط واحد للشركة: `CASH-01 / الخزينة الرئيسية`, id `0a9d9357-b5f3-4dfa-886f-7c73de4f274e`. جدول `treasury` لا يحتوي `branch_id`، ومحرك البيع الحالي يرفض الدفع النقدي ما لم توجد خزينة نشطة واحدة بالضبط. لذلك لم أنشئ خزائن فرعية جديدة ولم أغيّر رصيد الخزينة أو منطق البيع.

## ما نُفّذ فعليًا

### 1. Migrations committed and applied

1. `supabase/migrations/20261012233000_pos_shift_management_core.sql`  
   Commit أولي: `07d062a034109fe0a10c5388b0fdeb22e6f26450`; النسخة النهائية للملف: blob SHA `ae63a38f66e82df8b355d382920885b057be4e55`.
2. `supabase/migrations/20261012234000_pos_shift_authenticated_acl.sql`  
   Commit: `9491c9cff615d00f8553348749a78e8942081109`.
3. `supabase/migrations/20261012235000_pos_shift_linkage_hardening.sql`  
   Commit: `8129e3e72f7f22328fe07d68f7dfbff74b317fd7`.

Migration history في Production يثبت تسجيل الثلاثة:
- `20261012232615 / 20261012233000_pos_shift_management_core`
- `20261012232738 / 20261012234000_pos_shift_authenticated_acl`
- `20261012232948 / 20261012235000_pos_shift_linkage_hardening`

### 2. Objects and contracts added

- `public.pos_terminals`: جهاز/نقطة بيع مقيدة بالشركة والفرع، مع `UNIQUE(company_id, terminal_code)`.
- `public.pos_shifts`: فتح/إغلاق وردية، الكاشير، الفرع، الجهاز، الخزينة المعينة، العهدة الافتتاحية، المتوقع/المعدود/الفرق، ومفاتيح idempotency.
- `public.pos_shift_cash_counts`: عدّ الفئات؛ الإجمالي يُحسب في قاعدة البيانات.
- `public.pos_shift_events`: سجل أحداث غير قابل للتكرار بمفتاح العملية.
- `orders.shift_id` و`cash_box.shift_id`: روابط تتبع للوردية؛ لم تتم إعادة كتابة أي سجل تاريخي.
- `trg_pos_assign_order_shift`: يربط فاتورة POS بالوردية المفتوحة المطابقة للشركة والفرع والكاشير.
- `trg_pos_assign_cash_box_shift`: يربط حركة القبض/رد النقد بالوردية المرتبطة بالأوردر، ويرفض تمرير shift مختلف عن shift الأوردر.
- `pos_open_shift`: يثبت هوية المستخدم من JWT، يتحقق من POS permission والفرع المسموح والخزينة التابعة للشركة، ويسجل terminal والوردية بمفتاح idempotency.
- `pos_get_shift_summary`: قراءة X-report من بيانات الوردية والحركات المالية القائمة.
- `pos_close_shift`: يغلق الوردية بقفل صف، ويحسب المتوقع في قاعدة البيانات، ويتحقق من مجموع الفئات، ويطلب سببًا عند وجود فرق، ويخزن لقطة الإغلاق ويعيد نفس النتيجة عند إعادة نفس العملية.
- `pos_shift_expected_cash`: دالة داخلية غير قابلة للاستدعاء من أدوار التطبيق.

### 3. Contract المالي

`expected_cash = opening_float + cash_box receipts linked to shift - cash_box payments linked to shift`

المسار الحالي يربط حركات POS النقدية ومرتجعات POS النقدية. فتح/إغلاق الوردية **لا ينشئ قيدًا ماليًا ولا يغيّر رصيد treasury**؛ هذا يمنع تكرار القبض المسجل أصلًا في `cash_box` والإيصالات والقيود المحاسبية.

لا يوجد حتى الآن عقد معتمد لـPaid In/Paid Out. لم أدرجها في المتوقع ولم أنشئ لها دفترًا بديلًا. كذلك لم أضف `cash_movements` لأن ذلك سيصنع مصدرًا ماليًا ثانيًا.

### 4. Security / ACL — live verification

نتيجة Production بعد المراجعة:

| Function | anon EXECUTE | authenticated EXECUTE | service_role EXECUTE |
|---|---:|---:|---:|
| `pos_open_shift` | false | true | false |
| `pos_get_shift_summary` | false | true | false |
| `pos_close_shift` | false | true | false |
| `pos_shift_expected_cash` | false | false | false |

الجداول الأربعة الجديدة عليها RLS، ولا توجد صلاحيات مباشرة لـ`anon/authenticated/service_role`؛ الوصول التشغيلي يمر عبر RPCs المصادق عليها. لم تُنشأ Edge Function جديدة ولم يتغير إصدار `save-sales-invoice` أو `complete-return`.

## الاختبارات التي نُفذت

### Database transactional test — PASS

داخل معاملة اختبارية تم ضبط سياق JWT على المستخدم الفعلي `cashier@rawaea.com` ثم تنفيذ:

1. فتح وردية على الفرع المسموح `BR-01` مع opening float = 100.00.
2. إعادة نفس open operation؛ المتوقع `duplicate=true`.
3. قراءة الملخص؛ المتوقع النقد = 100.00.
4. إغلاق الوردية بعد عدّ فئة 100 × 1؛ الفرق = 0.
5. إعادة نفس close operation؛ المتوقع `duplicate=true`.
6. اختبار فرع غير مسموح للكاشير؛ رفضه برمز `42501`.

المعاملة أُلغيت بـ`ROLLBACK`. فحص ما بعد الاختبار أثبت:
- `test_terminal_residue = 0`
- `test_shift_residue = 0`
- `test_event_residue = 0`

### ما لم يُختبر بعد

- HTTP E2E من المتصفح الفعلي عبر POS إلى Edge/Core/DB.
- التزامن الحقيقي من جلستين متوازيتين؛ الفهارس الفريدة والقفل موجودان لكن اختبار concurrency runtime لم يُنفذ.
- بيع حقيقي مرتبط بوردية ثم مرتجع حقيقي مرتبط بها؛ لم أنشئ عمليات مالية تجريبية في بيانات Production.
- تطابق النسخة المنشورة من POS مع SHA الحالي في المتصفح.
- لا تزال الواجهة الحالية لا تعرض فتح/إغلاق الوردية؛ لم أعدّل ملف التطبيق التشغيلي حسب القيد الصريح.

## فجوات لا يجوز إخفاؤها

1. **POS UI patch required:** لا يمكن اعتبار الوظيفة متاحة للكاشير قبل أن يطبق المالك التعديل الجراحي أدناه على ملف POS وينشره.
2. **Compatibility rollout:** trigger يربط البيع بالوردية عند وجود وردية مطابقة، لكنه يسمح مؤقتًا ببيع POS بلا shift كي لا يتعطل التطبيق الحالي قبل نشر الواجهة. لا يجوز تحويل هذا إلى الوضع النهائي؛ بعد نشر الواجهة ونجاح E2E يجب تفعيل منع shiftless POS sales في cutover منفصل.
3. **Branch treasury:** Production حاليًا لديه خزينة نشطة واحدة للشركة ولا يوجد `treasury.branch_id`; الوردية تحمل `branch_id` وتُسند إلى خزينة الشركة القائمة. لا أصف ذلك بأنه خزينة مالية مستقلة لكل فرع. إنشاء خزائن متعددة يتطلب تعديلًا منسقًا لعقد `save_sales_invoice_atomic` لأنه يشترط خزينة نشطة واحدة بالضبط.
4. **Paid In/Out وVoid وSupervisor approval:** غير منفذة. لا يجوز إضافة زر يلغي فاتورة أو يصرف نقدًا قبل بناء عقد ذري يربط الخزينة والتدقيق والمحاسبة والعكس المالي. لا تخزّن Supervisor PIN كنص صريح.
5. **Offline checkout:** لا يزال غير مكتمل؛ واجهة البيع الحالية لا تملك writer موثوقًا لطابور `pending_updates`. لا يُسمح بالبيع دون اتصال مع الادعاء بأنه متزامن مع الوردية.

## التعديل الجراحي المطلوب من المالك — لا تعدّل الملف قبل مراجعة SHA

**الملف:** `papamohammed77-glitch/erp-frontend/companies/company-1/sales/pos.html`  
**SHA الحالي:** `54dce2c9ad1e08e154965beb92d9d494607e42c9`  
**ممنوع على المساعد تعديل هذا الملف أو `main.html`.**

### Patch 1 — زر إدارة الوردية

ابحث عن هذا العنصر المحدد:
```html
<div class="relative w-40"><select id="posBranchSel" onchange="POS.onBranchChange()" class="w-full p-2.5 bg-slate-800 border border-slate-600 rounded-lg text-sm font-bold text-white appearance-none"><option value="">🏭 اختر الفرع</option></select></div>
```

استبدله كاملًا بهذا:
```html
<div class="relative w-40"><select id="posBranchSel" onchange="POS.onBranchChange()" class="w-full p-2.5 bg-slate-800 border border-slate-600 rounded-lg text-sm font-bold text-white appearance-none"><option value="">🏭 اختر الفرع</option></select></div>
<button type="button" id="posShiftButton" onclick="POS.openShiftModal()" class="shrink-0 px-3 py-2 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-black"><span id="posShiftButtonLabel">الوردية: جارٍ التحقق</span></button>
```

### Patch 2 — نافذة الوردية

ابحث عن العلامة الدقيقة:
```html
<script>
function fmtNum(n)
```

أدرج الكتلة التالية **قبل** `<script>` مباشرة:
```html
<div id="posShiftModal" class="fixed inset-0 bg-black/80 backdrop-blur-sm z-[70] hidden flex items-center justify-center p-4">
  <div class="bg-slate-900 border border-indigo-600 rounded-2xl w-full max-w-xl max-h-[90vh] overflow-y-auto shadow-2xl">
    <div class="p-4 bg-indigo-950/60 border-b border-indigo-700 flex justify-between items-center">
      <h3 class="font-black text-lg text-indigo-200">إدارة الوردية والخزينة</h3>
      <button type="button" onclick="POS.closeShiftModal()" class="text-slate-400 hover:text-white text-2xl">&times;</button>
    </div>
    <div class="p-4 space-y-4">
      <div id="posShiftOpenPanel" class="space-y-3">
        <p class="text-sm text-slate-300">اختر الفرع أولًا، ثم سجّل النقدية الموجودة فعليًا في بداية الوردية.</p>
        <label class="block text-xs text-slate-400">العهدة الافتتاحية</label>
        <input id="posShiftOpeningFloat" type="number" min="0" step="0.01" value="0" class="w-full p-3 rounded-lg bg-slate-800 border border-slate-600 text-white">
        <button type="button" onclick="POS.startShift()" class="w-full p-3 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-black">بدء الوردية</button>
      </div>
      <div id="posShiftActivePanel" class="hidden space-y-3">
        <div class="grid grid-cols-2 gap-2">
          <div class="p-3 rounded-xl bg-slate-800"><div class="text-xs text-slate-400">النقد المتوقع</div><div id="posShiftExpected" class="text-xl font-black text-emerald-300">0.00</div></div>
          <div class="p-3 rounded-xl bg-slate-800"><div class="text-xs text-slate-400">عدد الفواتير</div><div id="posShiftSaleCount" class="text-xl font-black text-white">0</div></div>
          <div class="p-3 rounded-xl bg-slate-800"><div class="text-xs text-slate-400">قبض نقدي</div><div id="posShiftCashSales" class="font-bold text-white">0.00</div></div>
          <div class="p-3 rounded-xl bg-slate-800"><div class="text-xs text-slate-400">رد نقدي</div><div id="posShiftCashRefunds" class="font-bold text-red-300">0.00</div></div>
        </div>
        <p class="text-xs text-slate-400">X-Report قراءة فقط. إغلاق الوردية يحفظ عدّ النقد والفرق ولا ينشئ قيد قبض مكررًا.</p>
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
          <label class="text-xs text-slate-400">200<input id="posShiftCount200" type="number" min="0" step="1" value="0" oninput="POS.updateShiftCountTotal()" class="mt-1 w-full p-2 bg-slate-800 border border-slate-600 rounded-lg text-white"></label>
          <label class="text-xs text-slate-400">100<input id="posShiftCount100" type="number" min="0" step="1" value="0" oninput="POS.updateShiftCountTotal()" class="mt-1 w-full p-2 bg-slate-800 border border-slate-600 rounded-lg text-white"></label>
          <label class="text-xs text-slate-400">50<input id="posShiftCount50" type="number" min="0" step="1" value="0" oninput="POS.updateShiftCountTotal()" class="mt-1 w-full p-2 bg-slate-800 border border-slate-600 rounded-lg text-white"></label>
          <label class="text-xs text-slate-400">20<input id="posShiftCount20" type="number" min="0" step="1" value="0" oninput="POS.updateShiftCountTotal()" class="mt-1 w-full p-2 bg-slate-800 border border-slate-600 rounded-lg text-white"></label>
          <label class="text-xs text-slate-400">10<input id="posShiftCount10" type="number" min="0" step="1" value="0" oninput="POS.updateShiftCountTotal()" class="mt-1 w-full p-2 bg-slate-800 border border-slate-600 rounded-lg text-white"></label>
          <label class="text-xs text-slate-400">5<input id="posShiftCount5" type="number" min="0" step="1" value="0" oninput="POS.updateShiftCountTotal()" class="mt-1 w-full p-2 bg-slate-800 border border-slate-600 rounded-lg text-white"></label>
          <label class="text-xs text-slate-400">1<input id="posShiftCount1" type="number" min="0" step="1" value="0" oninput="POS.updateShiftCountTotal()" class="mt-1 w-full p-2 bg-slate-800 border border-slate-600 rounded-lg text-white"></label>
          <label class="text-xs text-slate-400">0.5<input id="posShiftCount05" type="number" min="0" step="1" value="0" oninput="POS.updateShiftCountTotal()" class="mt-1 w-full p-2 bg-slate-800 border border-slate-600 rounded-lg text-white"></label>
        </div>
        <div class="p-3 rounded-xl bg-slate-800 flex justify-between"><span class="text-slate-300">إجمالي النقد المعدود</span><strong id="posShiftCountTotal" class="text-xl text-white">0.00</strong></div>
        <label class="block text-xs text-slate-400">سبب الفرق (إلزامي إذا اختلف المعدود عن المتوقع)</label>
        <textarea id="posShiftDiscrepancyReason" rows="2" class="w-full p-3 rounded-lg bg-slate-800 border border-slate-600 text-white" placeholder="سبب فرق العهدة إن وجد"></textarea>
        <button type="button" onclick="POS.closeShift()" class="w-full p-3 rounded-xl bg-red-600 hover:bg-red-500 text-white font-black">إغلاق الوردية وإصدار Z-Report</button>
      </div>
    </div>
  </div>
</div>
```

### Patch 3 — أضف دوال الوردية داخل كائن POS

داخل `var POS = (function() { ... })();` ابحث عن `self.init = function() {` وأدرج الكتلة التالية **قبلها مباشرة**:
```javascript
self._shiftLoaded = false;
self._activeShiftId = null;
self._shiftSummary = null;

self._newShiftOperationId = function() {
    var c = window.crypto, bytes, hex = [], i;
    if (c && typeof c.randomUUID === 'function') return c.randomUUID();
    if (!c || typeof c.getRandomValues !== 'function') return null;
    bytes = new Uint8Array(16);
    c.getRandomValues(bytes);
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    for (i = 0; i < bytes.length; i++) hex.push(bytes[i].toString(16).padStart(2, '0'));
    return hex.slice(0,4).join('') + '-' + hex.slice(4,6).join('') + '-' + hex.slice(6,8).join('') + '-' + hex.slice(8,10).join('') + '-' + hex.slice(10).join('');
};

self._getShiftTerminalCode = function() {
    var code = '';
    try { code = localStorage.getItem('rawaea_pos_terminal_code') || ''; } catch (e) {}
    if (!code) {
        var op = self._newShiftOperationId();
        code = 'POS-' + (op || (String(Date.now()) + '-' + String(Math.floor(Math.random() * 100000000))));
        try { localStorage.setItem('rawaea_pos_terminal_code', code); } catch (e) {}
    }
    return code;
};

self._renderShiftState = function() {
    var label = RW_UI.byId('posShiftButtonLabel');
    var openPanel = RW_UI.byId('posShiftOpenPanel');
    var activePanel = RW_UI.byId('posShiftActivePanel');
    var s = self._shiftSummary && self._shiftSummary.shift;
    if (label) label.innerText = self._activeShiftId ? ('وردية مفتوحة • ' + Number((self._shiftSummary || {}).expected_cash || 0).toFixed(2)) : 'بدء الوردية';
    if (openPanel) openPanel.classList.toggle('hidden', !!self._activeShiftId);
    if (activePanel) activePanel.classList.toggle('hidden', !self._activeShiftId);
    if (s) {
        RW_UI.safeText(RW_UI.byId('posShiftExpected'), Number((self._shiftSummary || {}).expected_cash || 0).toFixed(2));
        RW_UI.safeText(RW_UI.byId('posShiftSaleCount'), String((self._shiftSummary || {}).sale_count || 0));
        RW_UI.safeText(RW_UI.byId('posShiftCashSales'), Number((self._shiftSummary || {}).cash_sales || 0).toFixed(2));
        RW_UI.safeText(RW_UI.byId('posShiftCashRefunds'), Number((self._shiftSummary || {}).cash_refunds || 0).toFixed(2));
    }
};

self.loadShiftState = function(callback) {
    if (!currentUser || typeof supabase === 'undefined' || !supabase || typeof supabase.rpc !== 'function') return;
    supabase.rpc('pos_get_shift_summary', { p_shift_id: null }).then(function(res) {
        if (res.error || !res.data || res.data.success !== true) {
            self._shiftLoaded = false;
            console.error('POS shift summary failed:', res.error || res.data);
            if (typeof callback === 'function') callback(false);
            return;
        }
        self._shiftSummary = res.data;
        self._activeShiftId = res.data.active_shift && res.data.shift ? res.data.shift.id : null;
        self._shiftLoaded = true;
        self._renderShiftState();
        if (typeof callback === 'function') callback(true);
    }).catch(function(err) {
        self._shiftLoaded = false;
        console.error('POS shift summary exception:', err);
        if (typeof callback === 'function') callback(false);
    });
};

self.openShiftModal = function() {
    var modal = RW_UI.byId('posShiftModal');
    if (modal) modal.classList.remove('hidden');
    self.loadShiftState();
};

self.closeShiftModal = function() {
    var modal = RW_UI.byId('posShiftModal');
    if (modal) modal.classList.add('hidden');
};

self.updateShiftCountTotal = function() {
    var ds = [
        ['posShiftCount200',200],['posShiftCount100',100],['posShiftCount50',50],
        ['posShiftCount20',20],['posShiftCount10',10],['posShiftCount5',5],
        ['posShiftCount1',1],['posShiftCount05',0.5]
    ];
    var total = 0, i, el, qty;
    for (i = 0; i < ds.length; i++) {
        el = RW_UI.byId(ds[i][0]);
        qty = el ? Number(el.value || 0) : 0;
        if (!isFinite(qty) || qty < 0 || Math.floor(qty) !== qty) {
            RW_UI.safeText(RW_UI.byId('posShiftCountTotal'), '—');
            return;
        }
        total += ds[i][1] * qty;
    }
    RW_UI.safeText(RW_UI.byId('posShiftCountTotal'), total.toFixed(2));
    return total;
};

self.startShift = function() {
    if (!selBranch || !branchMap[selBranch]) {
        RW_UI.toast('اختر الفرع أولًا', 'warning');
        return;
    }
    var opening = Number(RW_UI.byId('posShiftOpeningFloat').value);
    var op = self._newShiftOperationId();
    if (!isFinite(opening) || opening < 0 || !op) {
        RW_UI.showError('العهدة الافتتاحية أو هوية العملية غير صالحة');
        return;
    }
    RW_UI.showLoader('جاري فتح الوردية والتحقق من الخزينة...');
    supabase.rpc('pos_open_shift', {
        p_branch_id: branchMap[selBranch],
        p_terminal_code: self._getShiftTerminalCode(),
        p_opening_float: opening,
        p_operation_id: op,
        p_treasury_id: null,
        p_terminal_label: 'POS ' + selBranch
    }).then(function(res) {
        RW_UI.hideLoader();
        if (res.error || !res.data || res.data.success !== true) {
            RW_UI.showError((res.error && res.error.message) || 'تعذر فتح الوردية');
            return;
        }
        self.loadShiftState(function(ok) {
            if (ok) RW_UI.toast(res.data.duplicate ? 'الوردية موجودة بالفعل' : 'تم فتح الوردية', 'success');
        });
    }).catch(function(err) {
        RW_UI.hideLoader();
        RW_UI.showError(err && err.message ? err.message : 'تعذر فتح الوردية');
    });
};

self.closeShift = function() {
    if (!self._activeShiftId) {
        RW_UI.toast('لا توجد وردية مفتوحة', 'warning');
        return;
    }
    var ds = [
        ['posShiftCount200',200],['posShiftCount100',100],['posShiftCount50',50],
        ['posShiftCount20',20],['posShiftCount10',10],['posShiftCount5',5],
        ['posShiftCount1',1],['posShiftCount05',0.5]
    ];
    var counts = [], total = 0, i, el, qty, op;
    for (i = 0; i < ds.length; i++) {
        el = RW_UI.byId(ds[i][0]);
        qty = el ? Number(el.value || 0) : 0;
        if (!isFinite(qty) || qty < 0 || Math.floor(qty) !== qty) {
            RW_UI.showError('أدخل أعدادًا صحيحة غير سالبة لفئات النقد');
            return;
        }
        counts.push({ denomination: ds[i][1], quantity: qty });
        total += ds[i][1] * qty;
    }
    op = self._newShiftOperationId();
    if (!op) { RW_UI.showError('تعذر إنشاء هوية آمنة لعملية الإغلاق'); return; }
    RW_UI.showLoader('جاري مطابقة النقد وإغلاق الوردية...');
    supabase.rpc('pos_close_shift', {
        p_shift_id: self._activeShiftId,
        p_counted_cash: Number(total.toFixed(2)),
        p_counts: counts,
        p_operation_id: op,
        p_discrepancy_reason: (RW_UI.byId('posShiftDiscrepancyReason').value || '').trim() || null
    }).then(function(res) {
        RW_UI.hideLoader();
        if (res.error || !res.data || res.data.success !== true) {
            RW_UI.showError((res.error && res.error.message) || 'تعذر إغلاق الوردية؛ تحقق من مجموع الفئات وسبب الفرق');
            return;
        }
        RW_UI.toast('تم إغلاق الوردية. الفرق: ' + Number(res.data.cash_difference || 0).toFixed(2), 'success');
        self._activeShiftId = null;
        self.loadShiftState();
    }).catch(function(err) {
        RW_UI.hideLoader();
        RW_UI.showError(err && err.message ? err.message : 'تعذر إغلاق الوردية');
    });
};
```

### Patch 4 — مزامنة الوردية بعد المصادقة

داخل `self._setupUser = function(user) {` ابحث عن السطرين:
```javascript
currentUser = user;
pubUserId = user.id;
```
أضف بعدهما مباشرة:
```javascript
self.loadShiftState();
```

### Patch 5 — منع فتح الدفع دون وردية

استبدل الدالة الكاملة `self.openPaymentModal` (محدد البحث: `self.openPaymentModal = function() {`) بالنص التالي:
```javascript
self.openPaymentModal = function() {
    self.loadShiftState(function(ok) {
        if (!ok || !self._activeShiftId || !self._shiftSummary || !self._shiftSummary.shift) {
            self.openShiftModal();
            RW_UI.toast('يجب فتح وردية قبل البيع', 'warning');
            return;
        }
        if (!selBranch || !branchMap[selBranch]) {
            RW_UI.toast('اختر الفرع قبل الدفع', 'warning');
            return;
        }
        if (branchMap[selBranch] !== self._shiftSummary.shift.branch_id) {
            RW_UI.showError('الوردية المفتوحة تخص فرعًا آخر؛ أغلقها قبل تغيير الفرع');
            return;
        }
        var t = self.calcTotals();
        if (!t.count) { RW_UI.toast('السلة فارغة', 'warning'); return; }
        RW_UI.safeText(RW_UI.byId('modalPayableTotal'), fmtNum(t.total) + ' ' + currency);
        RW_UI.byId('paymentModal').classList.remove('hidden');
        RW_UI.byId('txtTendered').value = '';
        RW_UI.safeText(RW_UI.byId('lblChangeDue'), '0.00');
        activePaymentMethod = 'cash';
        self.setPaymentMethod('cash');
    });
};
```

### Patch 6 — حارس نهائي قبل إرسال الفاتورة

داخل `self.finalizeCheckout = function() {` أدرج هذا النص **قبل** السطر الحالي `var t = self.calcTotals();`:
```javascript
if (!self._shiftLoaded || !self._activeShiftId || !self._shiftSummary || !self._shiftSummary.shift) {
    RW_UI.showError('لا يمكن ترحيل فاتورة دون وردية مفتوحة ومتحقق منها');
    self.openShiftModal();
    return;
}
if (!selBranch || !branchMap[selBranch] || branchMap[selBranch] !== self._shiftSummary.shift.branch_id) {
    RW_UI.showError('فرع الفاتورة لا يطابق فرع الوردية المفتوحة');
    return;
}
```

### Patch 7 — منع تبديل الفرع أثناء الوردية

استبدل الدالة الحالية القصيرة `self.onBranchChange`:
```javascript
self.onBranchChange = function() { selBranch = RW_UI.byId('posBranchSel') ? RW_UI.byId('posBranchSel').value : null; self.renderProducts(); };
```
بهذه:
```javascript
self.onBranchChange = function() {
    var select = RW_UI.byId('posBranchSel');
    var next = select ? select.value : null;
    var s = self._shiftSummary && self._shiftSummary.shift;
    if (self._activeShiftId && s) {
        var allowedCode = '';
        var code;
        for (code in branchMap) {
            if (Object.prototype.hasOwnProperty.call(branchMap, code) && branchMap[code] === s.branch_id) {
                allowedCode = code;
                break;
            }
        }
        if (allowedCode && next !== allowedCode) {
            RW_UI.toast('لا يمكن تغيير الفرع أثناء الوردية؛ أغلق الوردية أولًا', 'warning');
            if (select) select.value = allowedCode;
            next = allowedCode;
        }
    }
    selBranch = next;
    self.renderProducts();
};
```

**أثر التعديل المتوقع:** فتح/قراءة/إغلاق الوردية من RPC مصادق عليه، X-report للقراءة، Z-report مع عدّ فئات، منع فتح الدفع أو ترحيل البيع دون وردية، وربط فواتير POS وحركات القبض/الرد بالوردية. لا يتغير التصميم العام ولا دورة المرتجعات ولا دفتر الخزينة الحالي.

## الاختبار بعد تطبيق المالك

1. افتح POS بحساب كاشير فعلي، واختر `BR-01`، وافتح وردية بعهدة 100.
2. أعد طلب فتح الوردية بنفس `operation_id` في اختبار API معزول؛ يجب أن يرجع `duplicate=true`.
3. نفذ بيعًا نقديًا حقيقيًا واحدًا في بيئة اختبار معزولة؛ تحقق أن `orders.shift_id` و`cash_box.shift_id` يشيران إلى الوردية نفسها.
4. نفذ مرتجعًا نقديًا للأوردر التجريبي نفسه؛ تحقق أن مبلغ الرد ينقص المتوقع مرة واحدة فقط.
5. افتح X-report مرتين؛ لا يتغير وضع الوردية ولا يتولد قيد.
6. أغلق مع عدّ صحيح؛ يجب أن يصبح `status=closed` وأن يحفظ الفرق وسبب الفرق عند الحاجة.
7. أعد نفس close operation؛ يجب أن يرجع نفس ملخص الإغلاق دون إعادة كتابة.
8. حاول البيع دون وردية، أو من فرع آخر، أو بعد الإغلاق؛ يجب رفضه.
9. تحقق أن `cash_box`/الإيصالات/القيود المالية لم تتضاعف، وأن رصيد الخزينة لم يتغير بسبب فتح/إغلاق الوردية.
10. تحقق من عدم وجود test terminal/shift/event بعد تنظيف الـfixture، ثم أثبت SHA للنسخة المنشورة وHTTP/browser E2E.

## SELF-AUDIT FINAL

- **What I Proved:** Production migration history؛ الجداول والروابط والـtriggers؛ ACLs؛ idempotency لفتح/إغلاق الوردية؛ حساب المتوقع من الحركات المرتبطة؛ منع فرع غير مسموح؛ rollback مع residue = 0.
- **What I Did Not Prove:** HTTP/browser E2E؛ نشر واجهة POS؛ concurrency runtime حقيقي؛ sale→return end-to-end على وردية؛ خزائن مستقلة لكل فرع؛ Paid In/Out؛ Void؛ supervisor approval؛ offline checkout.
- **What I Fixed:** أضفت نواة الوردية، عدّ الفئات، X/Z RPCs، روابط orders/cash_box، تحقق الشركة/الفرع/المستخدم، idempotency، وأزلت EXECUTE عن anon وservice_role للـRPCs الثلاثة.
- **What I Initially Missed:** ACL الافتراضي أعطى service_role EXECUTE على RPCs؛ أغلقت ذلك بمigration مستقلة. كما شددت trigger ربط cash_box حتى لا يقبل shift_id لا يطابق shift الأوردر.
- **What Could Still Be Wrong:** لم يثبت بعد أن Edge sale core يرفض shiftless sale بعد cutover؛ تركته متوافقًا مؤقتًا حتى لا تتعطل الواجهة الحالية. ولا يجوز تفعيل خزائن متعددة قبل تعديل محرك البيع الذي يشترط خزينة نشطة واحدة.
- **Final Confidence:** 90/100 لنواة قاعدة البيانات بعد الاختبارات؛ غير قابل للتعميم على التطبيق المنشور.
- **Final Closure Status:** `PRODUCTION DB CORE DEPLOYED / TRANSACTION TESTS PASS / OWNER POS SURGICAL PATCH REQUIRED / HTTP E2E OPEN / NOT 100% CLOSED`.

### تعليمات الاستئناف للجلسة التالية

1. أعد فحص Production وmigration history وEdge versions قبل أي تغيير.
2. لا تعد إنشاء الجداول أو تكرار المigrations؛ الثلاثة موجودة في Production.
3. اطلب من المالك تطبيق Patch 1–7 على POS الحالي فقط، ثم تحقق من SHA الجديد.
4. اختبر في بيئة معزولة البيع والمرتجع والوردية والإغلاق، وبعدها نفّذ cutover يمنع POS sales بلا shift.
5. لا تبدأ Paid In/Out أو Void قبل مراجعة التعريفات الحية لعقود القسائم والخزينة والمحاسبة؛ لا تنشئ Edge Function جديدة.
