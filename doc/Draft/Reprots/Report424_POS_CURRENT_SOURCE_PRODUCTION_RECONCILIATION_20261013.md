# Report424 — مراجعة تكامل تطبيق الكاشير ومزامنة Production — 2026-10-13

## 0. نطاق التنفيذ والقيود

النطاق الحصري: تطبيق POS `erp-frontend/companies/company-1/sales/pos.html`، عقد البيع والمرتجع في Supabase Production، واقتراح إدارة الورديات/الخزينة وملف الحالة. لم أعدّل `main.html` أو ملف POS التشغيلي، ولم أنشئ Edge Function جديدة أو بيانات بيع/مرتجع تجريبية في Production.

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** بيع POS نقدي يجب أن ينتج فاتورة ومخزونًا وآثارًا مالية متسقة؛ المرتجع النقدي مرتبط بإيصال البيع الأصلي؛ لا يجوز عرض وسيلة دفع على أنها متاحة قبل اكتمال عقد التسوية.
- **Architecture Understanding:** PWA مستقل ← RPC bootstrap/قراءة مصادق عليه ← Edge البيع/المرتجع مع JWT ← service_role ← Core SQL. لا تُمنح الواجهة صلاحية تنفيذ Core المالي أو المخزني مباشرة.
- **Database Understanding:** تم الاستعلام عن Production schema وACL الحية. لا توجد حاليًا جداول `shifts`, `cash_movements`, `cash_count_details`, `pos_terminals` ولا `orders.shift_id`.
- **Historical Understanding:** تمت قراءة نسخة POS التاريخية `rawaie-erp-review/PWA/sales/pos.html` ومقارنتها بنيويًا مع المصدر الحالي. المصدر التاريخي SHA `6ad4da791b72260b922847246ebce93b552d2bad` (80,447 حرفًا/1,115 سطرًا).
- **Production Understanding:** تمت قراءة Edge Function المنشورة `save-sales-invoice v18` و`complete-return v26`، وفحص SQL ACL الحي في نفس دورة العمل.
- **Current Understanding:** المصدر الحالي مختلف عن SHA المسجل في Report423؛ التحديثات الأربعة الخاصة بواجهة الدفع/المرتجع أصبحت موجودة بالفعل، لذلك لم أكررها.
- **Execution Confidence:** مرتفع لنتائج Git وProduction SQL وACL؛ غير كافٍ لإثبات served-artifact parity أو Browser E2E لأن أداة هذه الجلسة لا تقدم دليلًا على تشغيل المتصفح على نسخة الإنتاج.

### مصادر مثبتة

| المصدر | النتيجة |
|---|---|
| Current POS | `erp-frontend/companies/company-1/sales/pos.html`, blob SHA `54dce2c9ad1e08e154965beb92d9d494607e42c9`, 92,037 حرفًا / 1,575 سطرًا |
| أحدث commit متعلق بتسميات POS | `f662358147c170be4a7119e8a8001d995f2706ff`, “Enhance POS button labels and descriptions”، 2026-10-13 02:05 +03 |
| Historical POS | `rawaie-erp-review/PWA/sales/pos.html`, SHA `6ad4da791b72260b922847246ebce93b552d2bad` |
| ADR | `doc/Draft/Reprots/ADR_POS_SHIFT_MANAGEMENT_P0_20261013.md`, blob SHA `3158bd3e3e69be32265641d6fbabc15490f98158` |
| Proposal | `doc/Draft/Reprots/اقتراح تطبيق الكاشير-من مساعدد`, blob SHA `d8badc619764e41b77b12a98e80a2b68c99b99cc` |
| Supabase Production | project `fiilmooggumokxanwiyx`; آخر SQL check في هذه الدورة `2026-10-12 23:12:40.470287+00` |

ملاحظة: SHA الحالي `54dce2...` هو هوية الملف المسترجع من main، وهو أيضًا SHA عند قراءة الملف على commit `f662358...`. هذا يثبت هوية مصدر Git فقط ولا يثبت أن الاستضافة الثابتة تخدم نفس البايتات.

## 2. ما تم تنفيذه سابقًا وأصبح موجودًا في Current Git

راجعت العناصر داخل المصدر الحالي؛ النتائج:

1. **إزالة قراءة إعدادات غير مقيّدة بالشركة:** `_setupUser(user)` لم يعد يستعلم من `app_settings` مباشرة. العملة تأتي من `get_pos_bootstrap_data()` ذي السياق المحدد للشركة.
2. **تعطيل الدفع بالبطاقة والمختلط:** `btnPayCard` و`btnPaySplit` معطلان في HTML، مع توضيح أن عقد التسوية قيد الربط.
3. **حماية إضافية على الخادم/الواجهة:** `finalizeCheckout()` يرفض أي `activePaymentMethod !== 'cash'` بدل تسجيل البطاقة أو المختلط كأنهما نقد.
4. **تصحيح لغة المرتجع:** التحذير يشرح أن الرد النقدي مرتبط بعقد الخادم وإيصال البيع الأصلي، ويذكر أن رد البطاقة/المحفظة غير مدعوم حاليًا.
5. **تصحيح تسمية زر المرتجع:** `btnPayReturn` يعرض «تسجيل المرتجع ورد النقد (للفواتير النقدية)».

**القرار:** هذه التعديلات صحيحة وموجودة في Current Git؛ لا تُكررها ولا تستبدلها مرة أخرى. لم أجد في هذه الدورة دليلًا يثبت أن نسخة الاستضافة المنشورة للـPWA مطابقة للـSHA الحالي.

## 3. Production — تحقق مباشر في هذه الدورة

### Edge Functions المنشورة

| Function | Version | verify_jwt | ezbr_sha256 |
|---|---:|---|---|
| `save-sales-invoice` | 18 | true | `43d20f1465725c4e273f717ac927c070d4b28be48241bd2c9c46a6d43bb40308` |
| `complete-return` | 26 | true | `801e390b195522caedfcf68bae8262bb91da06e909c1d43e9344490e3a81f34d` |

### ACL — النتائج الحية

| SQL function | anon | authenticated | service_role |
|---|---:|---:|---:|
| `get_pos_bootstrap_data()` | false | true | true |
| `get_pos_branches()` | false | true | true |
| `get_pos_invoice_data(text,text)` | false | true | true |
| `save_sales_invoice_atomic(jsonb,jsonb,text,text)` | false | false | true |
| `complete_sales_return_credit_note_atomic(uuid,text,text,boolean,text,jsonb,text)` | false | false | true |
| `post_stock_movement(..., p_idempotency_key text)` | false | false | true |
| `post_stock_movement(... legacy signature without idempotency key)` | false | false | false |

إذن إصلاح ACL السابق للـreturn core ما زال قائمًا عند إعادة الفحص؛ لا يوجد مبرر لإعادة تطبيق REVOKE أو لتوسيع صلاحيات الواجهة. المسار الصحيح ما زال Edge JWT → service_role → Core.

### عينة أوامر Production (قراءة فقط)

وقت الاستعلام: `2026-10-12 23:12:40.470287+00`.

- `order-taker / Pending / نقدي`: 4
- `pos / Invoiced / نقدي`: 2
- `pos / Partially Returned / نقدي`: 1
- `telesales / Pending / نقدي`: 2

لم أضف أو أعدّل أي طلب/فاتورة في Production.

## 4. فجوات حقيقية لم تُغلق

### 4.1 إدارة الورديات والخزينة — OPEN

لم يُعثر في Production على `shifts`, `cash_movements`, `cash_count_details`, `pos_terminals` أو `orders.shift_id`. كما أن المصدر الحالي لا يحتوي `shift_id` أو `shiftId`.

اقتراح الكاشير يحدد أهدافًا صحيحة (فتح/إغلاق وردية، X/Z report، جرد فئات النقد، Paid In/Out، اعتماد المشرف، تعيين محطة، سجل تدقيق)، لكن DDL المقترح ليس صالحًا للاعتماد كما هو: فيه `company_id` مكرر، ومفاتيح/علاقات الشركة غير محكمة، ونقص في idempotency وRLS وقيود التزامن والعكس المالي. الـADR الحالي هو أساس التصميم، وليس دليلًا على تنفيذ الوظيفة.

**قرار التنفيذ:** لم أنشئ جداول معزولة أو أجعل البيع يتطلب `shift_id` قبل وجود تكامل منسق في الواجهة وعقد البيع المنشور. فرض العمود الآن سيكسر مبيعات POS الحالية، وإضافة جداول وحدها ستنتج ميزة غير قابلة للاستخدام وليست Closure.

### 4.2 Offline sales — DEFECT مثبت

المصدر يفتح التطبيق بالبيانات المحلية عند انقطاع الشبكة، ويقرأ `db.pending_updates` ويحدّث حالة الصفوف بعد نجاح المزامنة، لكنه لا يحتوي أي writer من نوع `pending_updates.add/put/bulkAdd`. كما أن `finalizeCheckout()` يرسل مباشرة إلى `save-sales-invoice` ولا ينشئ عملية بيع محلية دائمة عند انقطاع الاتصال.

لذلك **Offline cache موجود، لكن Offline checkout غير مثبت/غير مكتمل**. فتح الواجهة دون اتصال لا يعني أن البيع يمكن اعتماده دون اتصال. لا يجوز وصف POS بأنه Offline-First مكتمل قبل بناء مسار durable queue بهوية عملية ثابتة، payload موثوق، معالجة تكرار/تعارض، وحالة Pending ظاهرة، ثم مزامنته عبر عقد البيع الحالي واختباره.

### 4.3 Served artifact + Browser E2E — UNVERIFIED

لا توجد في هذه الدورة أدلة تثبت أن Cloudflare/الاستضافة تقدم SHA الحالي، ولا تشغيل متصفح موثق يثبت الدخول والبيع النقدي والمرتجع وإعادة المحاولة. لم أنشئ معاملات مالية اصطناعية في Production لملء هذه الفجوة.

## 5. ما الذي ينبغي أن تراه جديدًا في التطبيق؟

إذا كانت نسخة الاستضافة قد نُشرت من Current Git الحالي، فالتغييرات المرئية المؤكدة في المصدر هي:

- خياري «بطاقة» و«مختلط» يظهران بحالة معطلة وعبارة «قيد الربط»، ولا يمكن الاعتماد عليهما كطرق دفع مكتملة.
- زر المرتجع يوضح أنه خاص برد النقد للفواتير النقدية.
- نافذة المرتجع تشرح أن رد النقد يخضع لعقد الخادم، وتستبعد رد البطاقة/المحفظة حاليًا.
- لا ينبغي أن ترى شاشة فتح/إغلاق وردية أو X/Z أو جرد فئات النقد؛ هذه الوظائف **لم تُبنَ في Production بعد**.
- لا ينبغي اعتبار ظهور التطبيق عند انقطاع الإنترنت دليلًا على إمكان تسجيل بيع Offline؛ مسار إنشاء البيع المحلي الدائم غير موجود في المصدر الحالي.

هذه تغييرات مثبتة في Git وليست تأكيدًا بأنها وصلت إلى المتصفح الحي.

## 6. التعديل الجراحي التالي

**لا تعِد تطبيق تعديلات الدفع/المرتجع الأربعة**؛ هي موجودة بالفعل.

أولوية الإغلاق الوظيفي هي **P0 Shift Management** وفق ADR، مع rollout مرحلي: schema وRLS/ACL، ثم RPCs مصادق عليها لفتح/إغلاق الوردية والتسوية النقدية، ثم ربط واجهة POS وعقد البيع الموجود، ثم E2E وProduction verification. لا تضف Edge Function جديدة. لا تفرض `shift_id` على المبيعات الحالية قبل نشر التكامل المتوافق.

التعديل الصغير المقترح للمالك داخل `finalizeCheckout()` هو رفض محاولة إتمام البيع بوضوح عندما `navigator.onLine === false`، إلى أن يُنفذ Offline queue الحقيقي؛ فهذا يمنع أن تبدو شاشة Offline وكأنها تدعم إتمام البيع. هذا لا يُعتبر حلًا لـOffline sales، بل حاجز سلامة مؤقتًا موثقًا. أما الحل الدائم فيتطلب عقد Offline queue كاملًا ولا يصح اختزاله في سطر واجهة.

## 7. الاختبارات المطلوبة قبل إغلاق POS

1. نشر ملف POS الحالي ثم إثبات SHA/هوية artifact المنشور أو بصمة محتواه.
2. دخول مستخدم POS مصادق عليه؛ التأكد أن الفروع والمخزون والعملاء والعملة من الشركة الصحيحة.
3. بيع نقدي واحد في Staging/بيئة معزولة: فاتورة واحدة، حركة مخزون مركزية واحدة، أثر قبض صحيح، و`operation_id` ثابت.
4. إعادة نفس الطلب: لا فاتورة/حركة/قبض مكرر.
5. مرتجع نقدي لفاتورة POS أصلية: التحقق من الكمية المتاحة للمرتجع، الإشعار الدائن، رد المبلغ لخزينة الإيصال الأصلي، وحركة المخزون المركزية، ثم retry بلا تكرار.
6. اختبار مباشر للـreturn core كـauthenticated: يجب رفضه؛ واختبار Edge المصادق عليه: يجب أن يعمل عبر service_role.
7. لاختبار Offline: بعد بناء queue الحقيقي، افصل الشبكة، أنشئ بيعًا معلّقًا، أعد الاتصال، وتحقق من sync/idempotency، ثم أعد baseline إلى حالته الأصلية.
8. بعد تنفيذ Shift Management: duplicate open shift، إغلاق متزامن، فرق العهدة، Paid In/Out، company isolation، وإعادة المحاولة دون تكرار مالي.

## 8. SELF-AUDIT FINAL

- **What I Proved:** Current POS SHA وتفاصيل التعديلات الأربعة؛ Historical baseline SHA؛ إصدارات Edge المنشورة؛ ACL الحية؛ عدم وجود بنية Shift المطلوبة؛ عدم وجود writer للـoffline pending sales؛ عينة Production الحالية.
- **What I Did Not Prove:** تطابق النسخة المنشورة مع Git؛ Browser E2E؛ إتمام بيع/مرتجع في هذه الدورة؛ اكتمال Offline sales؛ وجود Shift Management.
- **What I Fixed:** لا تعديل جديد على Production كان مبررًا في هذه الدورة؛ إصلاح ACL السابق أُعيد التحقق منه. لم ألمس `main.html` أو ملف POS التشغيلي.
- **What I Initially Missed:** المصدر الحالي تغيّر عن SHA في Report423، والتعديلات الأربعة لم تعد تغييرات مطلوبة؛ أصبحت موجودة بالفعل في Current Git. كما أن فتح التطبيق من cache لا يثبت وجود Offline checkout.
- **What Could Still Be Wrong:** قد تختلف النسخة المقدمة للمستخدم عن مصدر Git؛ لم يُجر اختبار متصفح حي. وقد تكون هناك آليات Offline خارج الملف لم تثبتها المصادر المفتوحة هنا.
- **Final Confidence:** عالٍ في نتائج المصدر/SQL المذكورة، متوسط في اكتمال تتبع كل المستهلكين، وغير مثبت في runtime/browser.
- **Final Closure Status:** `CURRENT SOURCE + PRODUCTION ACL VERIFIED / FOUR UI FIXES PRESENT IN GIT / SHIFT MANAGEMENT OPEN / OFFLINE CHECKOUT OPEN / SERVED ARTIFACT + BROWSER E2E UNVERIFIED / NOT 100% CLOSED`.
