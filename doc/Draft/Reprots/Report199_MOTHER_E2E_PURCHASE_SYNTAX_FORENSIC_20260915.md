# Report199 — التحقيق الجنائي الحالي لعطل Mother E2E في PurchaseGold

**التاريخ:** 2026-09-15
**Closure Unit:** Mother System Browser E2E — PurchaseGold parser blockers
**Source of Truth:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

## 1. مبدأ حاكم

تم التعامل مع هذه الجلسة على أساس أن التقارير التاريخية للاستدلال فقط، وليست حالة حالية. الحالة المعتمدة هي:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE + CURRENT BROWSER CONSOLE`

ولا يبدأ أي تعديل قبل مطابقة المصدر الحالي والـparent والـdeployment evidence.

## 2. Current Git / Parent

HEAD الحالي:
`f858fb2f909a074dfe97b90134ef5e05b5592cd9`

HEAD message:
`Update comment timestamp in main.html`

Direct parent:
`5767266ffdc853846193494db6d49ece19c3ef7f`

Parent message:
`Refactor button generation loop in main.html`

Parent of parent:
`9b39626e8679e35b8215adf2ba4977b838e1f5d2`

Current mother blob:
`a530b7adb2d590e0f7f476ce8c81f33dcd186e92`

الـHEAD الحالي لا يغير جسم JavaScript؛ التغيير الظاهر في HEAD هو timestamp فقط. وبالتالي فإن العطل الحالي يجب تشخيصه على جسم الـblob الحالي نفسه.

## 3. Current Mother EOF / Source identity

تمت مطابقة الـmother الحالية من Git Contents API والبحث داخل كامل محتوى الـblob الحالي حتى EOF، وتم إثبات النهاية:

```html
</script>
</body>
</html>
```

كما تم العثور داخل نفس الـblob على جميع مواضع `RW_PurchaseGold` ذات الصلة، بما فيها `requests`, `createRequest`, `approveRequest`, `sendRFQ`, `acceptQuotation`, `convertQuotation`, `postInvoice`, و`postReturn`.

أداة GitHub لا تعرض line-map مباشرًا لملف mother الضخم عند طلب ranges، لذلك تم ربط رقم السطر المؤكد بالـBrowser Console الحالي، وعدم اختلاق أرقام لبقية المواضع.

## 4. Forensic correction to Report198

Report198 حدد `raw.split('\\n')` كسبب Parser رئيسي عند line 9263. هذا الاستنتاج **غير صحيح بالنسبة إلى CURRENT SOURCE**.

CURRENT SOURCE يثبت أمرين مختلفين:

1. عند `main:9263:65` يوجد بالفعل malformed JavaScript داخل `requests()` في زر `approveRequest`.
2. داخل `createRequest()` يوجد أيضًا `raw.split('\\\n')` كسطر JavaScript string literal به line continuation. هذا السطر ليس هو الـcurrent `Unexpected string` عند 9263، لكنه خطأ وظيفي يجب إصلاحه لأنه لا يمثل `\n` المقصودة في parser نص الطلبات.

وبالتالي لا يجوز إعادة تنفيذ Report198 حرفيًا باعتباره التشخيص النهائي.

## 5. Current proven parser blocker

العنصر الحالي في CURRENT SOURCE:

```javascript
(x.status === 'PendingApproval' || x.status === 'Draft'
  ? '<button onclick="RW_PurchaseGold.approveRequest(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">اعتماد</button>'
  : '') +
```

الخطأ هو استخدام `\\'` داخل JavaScript string بدل `\'`.

## 6. OWNER SURGICAL PATCH — requests()

**ملف النظام الأم:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

**الموضع المؤكد من Console:** `line 9263`

ابحث عن الدالة `requests(host)` ثم احذف **الثلاثة أسطر كاملة** التالية:

```javascript
        (x.status === 'PendingApproval' || x.status === 'Draft'
          ? '<button onclick="RW_PurchaseGold.approveRequest(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">اعتماد</button>'
          : '') +
```

واستبدلها **بالكامل** بهذا:

```javascript
        (x.status === 'PendingApproval' || x.status === 'Draft'
          ? '<button type="button" onclick="RW_PurchaseGold.approveRequest(\'' + esc(x.id) + '\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">اعتماد</button>'
          : '') +
```

آخر سطر في العنصر المطلوب حذفه هو:

```javascript
          : '') +
```

ولا تحذف السطر:

```javascript
        '</td></tr>';
```

## 7. OWNER SURGICAL PATCH — createRequest()

داخل `RW_PurchaseGold.createRequest()` يبدأ البلوك عند **السطر 9271 تقريبًا في نفس CURRENT SOURCE** وفق التسلسل الحالي المثبت من الـblob وكتلة المستخدم، ويكون موضع `raw.split` عند **السطرين 9285–9286** في هذه النسخة.

ابحث عن **السطرين الكاملين**:

```javascript
        raw.split('\\
').forEach(function (line) {
```

واحذفهما كاملين، حتى السطر:

```javascript
').forEach(function (line) {
```

ثم استبدلهما **بسطر واحد كامل**:

```javascript
        raw.split('\n').forEach(function (line) {
```

هذا إصلاح وظيفي داخل `createRequest()` وليس هو سبب Console 9263.

## 8. Additional CURRENT PurchaseGold syntax defects discovered in same forensic pass

CURRENT SOURCE يحتوي نفس escaping المكسور في عناصر أخرى داخل PurchaseGold، وهي ستة مواضع داخل جدول/إجراءات الشراء:

- `approveRequest`
- `sendRFQ`
- `acceptQuotation`
- `convertQuotation`
- `postInvoice`
- `postReturn`

الأشكال الحالية المعيبة هي من نمط:

```javascript
onclick="RW_PurchaseGold.<function>(\\'' + esc(x.id) + '\\')"
```

بينما النمط الصحيح في JavaScript string هو:

```javascript
onclick="RW_PurchaseGold.<function>(\'' + esc(x.id) + '\')"
```

تم إثبات هذه المواضع مباشرة من CURRENT mother blob؛ لم يتم استنتاجها من تقرير تاريخي.

**مهم:** لأن GitHub connector لا يعطي line-map موثوقًا لملف mother الضخم عند استرجاع ranges، لم يتم اختلاق أرقام أسطر للمواضع الخمسة الأخرى. يستخدم المالك اسم الدالة + السطر الكامل كـanchor جراحي.

### Exact replacements for the five remaining malformed action lines

استبدل فقط السطر الذي يحتوي على كل عنصر من العناصر التالية داخل دالته:

#### `sendRFQ`
احذف:
```javascript
          ? '<button onclick="RW_PurchaseGold.sendRFQ(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">إرسال</button>'
```
استبدل:
```javascript
          ? '<button type="button" onclick="RW_PurchaseGold.sendRFQ(\'' + esc(x.id) + '\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">إرسال</button>'
```

#### `acceptQuotation`
احذف:
```javascript
          ? '<button onclick="RW_PurchaseGold.acceptQuotation(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-emerald-600 text-white">قبول</button>'
```
استبدل:
```javascript
          ? '<button type="button" onclick="RW_PurchaseGold.acceptQuotation(\'' + esc(x.id) + '\')" class="px-3 py-1 rounded-lg bg-emerald-600 text-white">قبول</button>'
```

#### `convertQuotation`
احذف:
```javascript
          ? '<button onclick="RW_PurchaseGold.convertQuotation(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">تحويل لأمر شراء</button>'
```
استبدل:
```javascript
          ? '<button type="button" onclick="RW_PurchaseGold.convertQuotation(\'' + esc(x.id) + '\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">تحويل لأمر شراء</button>'
```

#### `postInvoice`
احذف:
```javascript
          ? '<button onclick="RW_PurchaseGold.postInvoice(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">ترحيل</button>'
```
استبدل:
```javascript
          ? '<button type="button" onclick="RW_PurchaseGold.postInvoice(\'' + esc(x.id) + '\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">ترحيل</button>'
```

#### `postReturn`
احذف:
```javascript
          ? '<button onclick="RW_PurchaseGold.postReturn(\\'' + esc(x.id) + '\\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">ترحيل</button>'
```
استبدل:
```javascript
          ? '<button type="button" onclick="RW_PurchaseGold.postReturn(\'' + esc(x.id) + '\')" class="px-3 py-1 rounded-lg bg-blue-600 text-white">ترحيل</button>'
```

## 9. `createRequest()` full replacement

لمنع خطأ القطع الجزئي في السطور، يمكن للمالك حذف الدالة الكاملة الحالية:

```javascript
async function createRequest() {
```

حتى آخر سطر:

```javascript
  }
```

المطابق لنهاية `createRequest()` قبل `approveRequest()`، واستبدالها بالنسخة التالية:

```javascript
  async function createRequest() {
    var r = await Swal.fire({
      title: 'طلب شراء جديد',
      html:
        '<input id="pg-title" class="swal2-input" placeholder="مسمى الطلب">' +
        '<input id="pg-date" type="date" class="swal2-input">' +
        '<textarea id="pg-items" class="swal2-textarea" placeholder="كود الصنف|الكمية&#10;1001|10"></textarea>' +
        '<textarea id="pg-notes" class="swal2-textarea" placeholder="ملاحظات"></textarea>',
      confirmButtonText: 'حفظ',
      showCancelButton: true,
      preConfirm: function () {
        var raw = document.getElementById('pg-items').value || '';
        var items = [];

        raw.split('\n').forEach(function (line) {
          line = line.trim();
          if (!line) return;

          var p = line.split('|');

          if (p.length < 2) {
            throw new Error('صيغة الصنف: item_code|qty');
          }

          var code = p[0].trim();
          var qty = Number(p[1]);

          if (!code || !Number.isFinite(qty) || qty <= 0) {
            throw new Error('بيانات الصنف غير صالحة: item_code|qty');
          }

          items.push({
            item_code: code,
            qty: qty
          });
        });

        if (!items.length) {
          throw new Error('أضف صنفًا واحدًا على الأقل');
        }

        return {
          title: document.getElementById('pg-title').value.trim(),
          required_by: document.getElementById('pg-date').value || null,
          notes: document.getElementById('pg-notes').value.trim(),
          items: items
        };
      }
    });

    if (!r.isConfirmed) return;

    if (!r.value.title) {
      Swal.fire('تنبيه', 'مسمى الطلب مطلوب', 'warning');
      return;
    }

    showLoader('جاري إنشاء طلب الشراء...');

    try {
      await api('CREATE_REQUEST', r.value);
      hideLoader();
      showToast('تم إنشاء طلب الشراء', 'success');
      await refresh();
    } catch (e) {
      hideLoader();
      Swal.fire('خطأ', e.message, 'error');
    }
  }
```

هذه النسخة ليست مطلوبة لإغلاق Parser 9263 فقط؛ هي أيضًا تمنع إنشاء طلب بلا أصناف، وترفض qty غير الصالحة، وتعالج separator `\n` الحقيقي.

## 10. Backend / Production decision

لا يوجد أي دليل حالي يربط Console 9263 أو هذه syntax defects بـSupabase runtime. لذلك:

- لا جدول جديد.
- لا Edge Function جديدة.
- لا RPC جديد.
- لا تعديل Inventory.
- لا تعديل Accounting.
- لا تعديل Auth.

أي تعديل Production هنا سيكون غير مرتبط بالـroot cause.

تم التحقق أيضًا من وجود البنية الحالية للشراء في Production، ومنها:
`purchase_requests`, `purchase_rfqs`, `purchase_quotations`, `purchase_invoices`, `purchase_returns`, `purchase_payments`.
كما توجد RPCs للحركة الوظيفية مثل:
`purchase_create_request_atomic`, `purchase_approve_request_atomic`, `purchase_create_rfq_atomic`, `purchase_send_rfq_atomic`, `purchase_create_quotation_atomic`, `purchase_accept_quotation_atomic`, `purchase_convert_quotation_to_po_atomic`, `purchase_create_invoice_atomic`, `purchase_post_invoice_atomic`, `purchase_post_payment_atomic`, `purchase_create_return_atomic`, `purchase_post_return_atomic`.

إذن أساس الـPurchase backend موجود، والمشكلة الحالية parser/frontend وليست نقص بنية backend.

## 11. Tailwind warning

الرسالة:

```text
cdn.tailwindcss.com should not be used in production
```

تحذير مستقل. لا يفسر `Unexpected string` عند line 9263، ولا يلزم تغييره لإغلاق هذا الـClosure.

## 12. Verification state

### Proven
- Current HEAD verified.
- Direct parent verified.
- HEAD body unchanged from parent except timestamp.
- Current mother blob verified.
- Current mother EOF verified.
- `forensic_main_assembly.yml` current source-of-truth points إلى `erp-frontend/companies/company-1/main.html`.
- Current Browser parser error at `main:9263:65` is consistent with malformed `approveRequest` escaping.
- Current source also contains the same malformed escaping pattern in five other PurchaseGold action lines.
- `createRequest()` has a separate `raw.split` semantic defect.
- No Production change is justified for this parser closure.

### Not yet proven
- Browser Console = 0 after owner edit.
- Login success after owner edit.
- Authenticated shell after owner edit.
- First navigation.
- Network clean.
- Purchase functional E2E.

Therefore:

```text
ROOT CAUSE CURRENT BLOCKER = PROVEN
SURGICAL FIX SET            = READY
PRODUCTION CHANGE           = NOT REQUIRED
OWNER MAIN.HTML EDIT        = REQUIRED
BROWSER E2E CLOSURE         = OPEN
```

## 13. Required next sequence

```text
OWNER PATCHES ALL CURRENT PURCHASEGold ESCAPES
→ publish current main.html
→ verify published commit
→ fresh browser, not cached tab
→ Console capture
→ Page Errors capture
→ Login rendered
→ Login succeeds
→ authenticated shell
→ first navigation
→ Purchase tab opens
→ requests list renders
→ create request opens
→ create request validation works
→ approve request button executes
→ RFQ button executes
→ quotation actions execute
→ invoice/return action buttons parse and execute
→ Network review
→ re-read Current Git blob
→ re-check EOF
→ mark current Closure closed only after current Browser evidence
→ move directly to next genuinely open E2E Closure
```

## 14. تعليمات البداية للمساعد التالي

لا تبدأ من التقرير القديم. ابدأ من:

```text
CURRENT_STATE
→ CURRENT GIT HEAD
→ DIRECT PARENT
→ CURRENT MOTHER BLOB
→ CURRENT DEPLOYMENT
→ CURRENT CONSOLE
→ CURRENT NETWORK
```

ثم طبّق:

```text
exact console error
→ exact current source anchor
→ compare parent/current diff
→ inspect surrounding function completely
→ inspect related current consumers
→ historical reconstruction only for intent
→ surgical owner patch for mother
→ direct Production change only when Production evidence proves defect
→ publish
→ fresh E2E
→ Console/Page/Network
→ re-read current source
→ close only what is proven
→ next Closure
```

لا تفترض أن تقريرًا تاريخيًا حدد السبب النهائي. لا تعدّل ما ثبت أنه مغلق دون Current evidence. ولا تعتبر نجاح static analysis أو browser run قديم PASS للـProduction الحالية.
