# Report726 — المراجعة التشغيلية اليومية لـ RAWAEA ERP
**التاريخ:** 2026-11-15  
**وقت التشغيل المرجعي:** 21:41 بتوقيت القاهرة  
**نقطة الاستئناف:** LVE-2026-11-14-725  
**الحكم:** READY WITH LIMITATIONS  
**نطاق التركيز اليوم:** Buyer.html — وحدات الشراء، حفظ فاتورة الشراء السريع/PO، عهدة المشتري، عقد Supabase، والمزامنة

---

## 1. نقطة البداية — Last Verified Event / Checkpoint

- تمت استعادة CURRENT_STATE.md كاملًا من papamohammed77-glitch/rawaie-erp-New:
  - Blob SHA: 015a1433fa2f2688a8fb294eaf2517e15476fd77
  - الحجم: 222,143 حرفًا / 2,206 سطرًا.
  - آخر حدث مثبت قبل هذا التشغيل: LVE-2026-11-14-725.
- تمت قراءة الدستور التشغيلي الدائم كاملًا:
  - doc/Draft/Reprots/الدستور التشغيلي الدائم.md
  - Blob SHA: 3a6b1e220af8509e314e94df76563bbc6f84910d
  - الحجم: 19,916 حرفًا.
- تمت مراجعة آخر تقريرين تشغيليين Report724 وReport725، ثم التقارير المرتبطة بالمشتريات والعهدة من Report667 وReport668 وReport669 وReport670 وReport676 وReport677 وReport679.
- تمت قراءة سجل الذاكرة المرجعي Current/CTO/RAWAEA_PROJECT_MEMORY_117-02.md:
  - Blob SHA قبل هذا التحديث: 5bc5b06a5bde2f10c015e48a023d7569196c5f48.
  - آخر إدخال سابق: LVE-2026-11-14-725.
- Report725 ثبّت أن HEAD التشغيلي آنذاك كان 531a63c0a9ba... لم تُعد فتح مشكلة دور أمين المخزن التي أغلقها ذلك التقرير بلا دليل جديد.
- الهدف التنفيذي الذي استُكمل اليوم: التحقق من تغييرات Buyer التي تلت LVE725، وإثبات عقد الوحدة والعهدة من الواجهة إلى RPC والاستلام، ثم التحقق من عدم وجود أثر مالي/مخزني غير مقصود.

## 2. CONFIRMED — حقائق مثبتة

### 2.1 GitHub / Source
- المستودع التشغيلي: papamohammed77-glitch/erp-frontend.
- الفرع: main.
- HEAD الحالي: 5f36edbbc5fb18821076277c04227df3a6cf1ece.
- سلسلة التغييرات بعد نقطة Report725 تتكون من سبعة commits، وكل ملفاتها ضمن:
  - companies/company-1/purchasing/buyer.html
  - companies/company-1/purchasing/buyer.tailwind.css
- لم تتغير main.html أو core.js في سلسلة هذه التغييرات.
- SHA الملفات الحالية:
  - buyer.html: a35226841036c03c3ed0f84296479d7599b0a20b — 263,830 حرفًا.
  - buyer.tailwind.css: 2fd9aff5289e6e71bbf77f9c42438f54ceb332a4 — 20,468 حرفًا.
  - core.js: 2b2211a3f95049042e27a7b2ecbab3640a584942 — 53,676 حرفًا.
  - main.html: blob f49586701ad83e52706bd55fae40b3d2a176e0f0، وهو نفس blob المثبت في Report725؛ لم يتغير في commits محل المراجعة.
- التغييرات البرمجية الأخيرة لم تلمس النظام الأم أو Core؛ لذلك لا يوجد دليل على أثر جانبي من هذه commits على Router أو Boot أو Auth المركزي.

### 2.2 وحدة الشراء — الواجهة
- يوجد حقل وحدة منسدلة في مودال الشراء السريع bqm-unit.
- يوجد حقل وحدة منسدلة في مودال فاتورة PO bpi-unit.
- كلاهما يحمّل الوحدة الأساسية من items.unit، ويعرض الوحدة البديلة فقط إذا كان alt_unit موجودًا ومعامل alt_unit_qty رقمًا صالحًا أكبر من صفر.
- سلة الشراء تعرض الوحدة المختارة ومعامل التحويل/السعر المكافئ للوحدة الأساسية.
- الواجهة ترسل unit إلى API؛ ولا تعتمد على قيمة معامل تحويل يرسلها المتصفح بوصفها مصدر الحقيقة. قاعدة البيانات تستخرج المعامل من سجل الصنف.

### 2.3 وحدة الشراء — Production RPC
تمت قراءة التعريفات الحية من Production، وليس من تقرير تاريخي فقط:

- purchase_create_invoice_atomic:
  - يتحقق أن الوحدة المختارة هي الوحدة الأساسية أو البديلة المعرّفة للصنف.
  - يرفض الوحدة البديلة إذا كان معامل التحويل غير صالح.
  - يحفظ base_unit وunit_conversion_factor في تفاصيل الفاتورة.
- purchase_update_draft_invoice_atomic:
  - يطبق تحقق الوحدة والتحويل نفسه عند تعديل Draft.
- purchase_create_po_invoice_atomic:
  - يمرر تفاصيل PO إلى مسار إنشاء الفاتورة المركزي؛ ولا ينشئ منطق تحويل موازيًا.
- purchase_update_po_invoice_atomic:
  - يمرر التعديل إلى مسار تحديث Draft المركزي.
- purchase_create_quick_market_invoice_atomic وpurchase_update_quick_market_invoice_atomic:
  - يستخدمان مسار الفاتورة المركزي، ويتحققان من الوحدة/المعامل.
- receive_quick_market_invoice_atomic وreceive_quick_market_purchase_atomic:
  - يستخدمان qty * unit_conversion_factor عند ترحيل كمية المخزون.
- purchase_post_invoice_atomic:
  - يقارن كمية الفاتورة المستهلكة بمعامل وحدة PO والكمية المستلمة، ويطبع سعر الوحدة للمقارنة على أساس الوحدة الأساسية.

**النتيجة:** عقد تحويل الوحدة موجود في Production عبر الإنشاء والتعديل والاستلام ومطابقة PO. هذا إثبات لعقد الكود/قاعدة البيانات، وليس إثباتًا لاختبار متصفح كامل بعد التغيير.

### 2.4 العهدة — السبب الجذري لتصميم الرفض السابق
- النسخة السابقة من buyer.html عند commit 8a0a28571e25bf297c87c4077810d2fe95bdcfd7 كانت تحتوي على شرط رفض محلي قبل استدعاء API:
  - total > Number(availableByCustody[custodyId] || 0) + 0.005
  - عند تحقق الشرط كانت تعرض رسالة «العهدة المختارة لا تغطي إجمالي الفاتورة» وتوقف preConfirm.
- النسخة الحالية عند HEAD 5f36ed... لا تحتوي هذا الرفض المحلي؛ تتحقق من اختيار العهدة ثم ترسل الطلب إلى المسار المركزي، وتعرض تفاصيل خطأ الخادم إذا رفضه.
- هذا يزيل احتمال أن تمنع قيمة واجهة قديمة أو ناقصة عملية الحفظ قبل أن تتحقق قاعدة البيانات من الرصيد الحقيقي.
- دالة Production purchase_create_quick_market_invoice_atomic:
  - تتحقق من هوية المستخدم والشركة والصلاحية purchases وملكية العهدة والعملة والحالة.
  - تسمح بحالة العهدة Issued أو UnderReview.
  - تقفل سجل العهدة بـ FOR UPDATE لتسلسل عمليات الحفظ المتزامنة على العهدة نفسها.
  - تحسب الرصيد المتاح من السلف المعتمدة، والمصروفات الملتزم بها، والفواتير المفتوحة المحجوزة، والمرتجعات النقدية.
  - ترفض فقط إذا تجاوز إجمالي الفاتورة الرصيد المتاح المحسوب من قاعدة البيانات.

### 2.5 لقطة العهدة الحية — قراءة فقط
لقطة Production الحالية للعهدة النشطة بالجنيه:

| البند | القيمة |
|---|---:|
| السلف المعتمدة ذات صندوق/قيد مثبت | 5,000 EGP |
| المصروفات Submitted/Approved | 250 EGP |
| الفواتير المفتوحة المحجوزة | 1,430 EGP |
| المرتجعات النقدية المسجلة | 0 EGP |
| **المتاح المحسوب** | **3,320 EGP** |

- الفواتير المحجوزة: PINV-1002 = 1,000 EGP وPINV-1003 = 430 EGP.
- المصروفات البالغة 250 EGP حالتها Submitted، وليست سدادًا مثبتًا؛ لا يوجد لها payment_id أو journal_entry_id.
- لا توجد فروق في العهد النشطة بين returned_amount ومجموع buyer_custody_returns وcash_returned في التسويات.
- عملة app_settings.currency الحالية هي EGP، وعملة العهدة نفسها EGP.
- نتيجة اللقطة: إذا كان إجمالي الفاتورة الجديدة أقل من 3,320 EGP ولم تتغير البيانات بالتزامن، فالحساب الحي لا يبرر رفضها بسبب عدم كفاية العهدة. لا يعني ذلك أن حفظًا فعليًا قد اختُبر.

### 2.6 أثر الاستلام الفعلي للفواتير الحالية
- PINV-1002 وPINV-1003 حالتهما المستندية Draft، لكن is_received=true وreceipt_status=RECEIVED، بينما settlement_status=UNSETTLED وpaid_amount=0.
- يوجد لهما 3 مستندات استلام، و5 تفاصيل استلام، و5 حركات PurchaseIn في inventory_log.
- لا توجد قيود يومية أو حركات في supplier_ledger مرتبطة بهاتين الفاتورتين، ولا يوجد سداد مثبت لهما.
- هذا متسق مع السياسة: **المخزون تأثر بواقعة استلام فعلية موثقة، لا بمجرد إنشاء Draft؛ ولا يوجد أثر سداد/خزينة لمجرد الفاتورة.**
- تفاصيل الفواتير القديمة الـ11 في Production كلها بوحدة الصنف الأساسية ومعامل 1؛ base_unit فارغ في السجلات القديمة، لكن لم يظهر أي سطر بوحدة بديلة أو اختلاف عن وحدة الصنف الأساسية.

### 2.7 Core / Edge / صلاحيات
- مسار buyer.html يستدعي RW_API من ../core.js؛ لم يُنشأ Core موازٍ.
- مصدر Edge Function supabase/functions/save-purchase-order/index.ts:
  - blob SHA: 7fb26398519971918f7e6d2aefaf68bf669d5139
  - الحجم: 56,481 حرفًا.
- Edge Function المنشورة save-purchase-order:
  - Version 41، Active، verify_jwt=true.
  - تحديثها: 2026-11-09T20:18:38Z.
  - SHA المنشور: 31e49eaeb035b236eaad0942047b97e89434bd706c8202ae943b82d6f166950d.
  - محتوى الملف المنشور يطابق ملف GitHub الحالي byte-for-byte.
- عمليات إنشاء/تعديل PO وQuick Market تستخدم profileClient مع JWT المستخدم لاستدعاء RPC المركزي؛ لا تستبدل هوية المستخدم بـ service-role عند تنفيذ هذه العمليات.
- RPCs الأربعة الخاصة بالإنشاء/التعديل SECURITY DEFINER وsearch_path مضبوط، anon EXECUTE=false، وauthenticated EXECUTE=true. لا توجد إشارة إلى توسيع صلاحيات anon لهذه المسارات.
- سياسات RLS الحالية على فواتير الشراء وتفاصيلها والعهد ومرفقاتها مقيدة بالشركة/المستخدم/صلاحيات المالية حسب الجدول.

### 2.8 صحة مشروع Supabase
- المشروع SMART ERP، ref: fiilmooggumokxanwiyx.
- الحالة: ACTIVE_HEALTHY.
- PostgreSQL: 17.6.1.121، المنطقة eu-west-1.
- لا توجد كتابة أو DDL أو DML نفذها هذا التشغيل.

## 3. UNKNOWN — ما لا تكفي الأدلة لحسمه
- هل نُفذت عملية حفظ فاتورة جديدة من واجهة Buyer بعد commit 5f36ed؟ لا يوجد طلب Edge بعد هذا commit في نافذة السجلات التي فُحصت.
- هل النسخة التي يفتحها المستخدم من Cloudflare هي نفس Artifact الذي اجتاز Check؟ لم تُجلب bytes المنشورة أو cache headers.
- هل اختيار الوحدة البديلة الجديدة مرّ فعليًا عبر المتصفح ثم ظهر base_unit وunit_conversion_factor في سجل جديد؟ لا توجد فاتورة جديدة بعد Migration UOM، ولم ننشئ واحدة للاختبار.
- هل المقصود أن يدعم كل صنف ثلاثة مستويات مستقلة (حبة/علبة/كرتونة) أم وحدة أساسية ووحدة بديلة واحدة؟ نموذج البيانات الحالي لا يحسم المقصود التجاري.
- لم يُنفذ Benchmark جديد مع SAP/Dynamics/Odoo/Daftra/Manager.io/Next ERP في هذا النطاق؛ لا تصدر نتيجة تكافؤ تنافسي.

## 4. CONFLICT — اختلافات مثبتة

### 4.1 Production migrations مقابل GitHub
- Production migration history: 791 سجلًا، وآخر إصدار 20261115171442.
- آخر ملف في erp-frontend/main/supabase/migrations: 20261114180000_owner_login_alias_sync_atomic.sql؛ الدليل المتاح في المجلد 84 ملفًا.
- توجد ثلاثة إصدارات مطبقة في Production ولا توجد ملفاتها في مجلد migrations التشغيلي:
  1. 20261115161918_buyer_quick_market_alternate_units_conversion_20261115
  2. 20261115162526_buyer_quick_market_custody_balance_uom_group_fix_20261115
  3. 20261115171442_buyer_po_invoice_units_and_qmp_live_custody_check_20261115
- التعريفات الحية للدوال موجودة وتعمل على مستوى الكتالوج، لكن تاريخ SQL القابل لإعادة البناء في GitHub لا يطابق Production.
- هذا استمرار لفجوة migration parity التي سجلها Report679؛ لا يجوز افتراض أن Production قابل لإعادة البناء من GitHub الحالي.

### 4.2 سجل QA قديم في Production
- وُجد سجل واحد باسم QA-SR-INV-20260927:
  - status=Draft
  - is_received=true
  - receipt_status=LEGACY_UNVERIFIED
  - settlement_status=LEGACY_UNVERIFIED
  - إجمالي 375 EGP، وسطر واحد، received_qty=5.
- لم يظهر له مستند استلام، أو receiving_details، أو حركة inventory_log، أو Stock Voucher، أو Journal Entry، أو Supplier Ledger، أو Audit Log، أو Operation Registry مرتبط.
- لم يظهر أي سجل مخزون للصنف المرتبط به.
- هذا سجل QA-labeled قديم ذو حالة متناقضة، لكن منشأه غير محسوم. لم ينشئه هذا التشغيل ولم يحذفه أو يعدله. لا يُحذف قبل تحديد مصدره واعتماد المالك وخطة معالجة أثره.

### 4.3 Unit model
- جدول items يحتوي unit وalt_unit وalt_unit_qty فقط؛ لا توجد بنية item_units أو جدول تحويلات متعدد المستويات.
- لذلك المتاح حاليًا لكل صنف: وحدة أساسية + بديل واحد صالح كحد أقصى، وليس ثلاثة مستويات مستقلة.
- من 35 صنفًا: 10 لها alt_unit، و9 بدائل معاملها صالح، وواحد له alt_unit بمعامل صفر. لم توجد تفاصيل PO حالية تستخدم البديل غير الصالح.

## 5. UNVERIFIED — نتائج لم تختبر مباشرة
- حفظ فاتورة Quick Market وPO من متصفح مصادق عليه بعد آخر commits.
- التحقق من Artifact المنشور وRuntime Console/Network بعد آخر commits.
- وصول أحداث Realtime فعليًا إلى جلسة Buyer، وقياس latency.
- تجربة استلام فاتورة جديدة بوحدة بديلة والتحقق من أثرها في inventory_log في بيئة QA معزولة.
- اختبار تزامن مستخدمين اثنين على العهدة نفسها في بيئة معزولة.

## 6. مصفوفة التحقق

| الطبقة | النتيجة | الدليل | الحكم |
|---|---|---|---|
| GitHub / Source | HEAD وملفات Buyer/Core/Edge محددة؛ Syntax parse للـinline scripts نجح | HEAD 5f36ed... وملفاتها | CONFIRMED |
| Supabase Production | المشروع Healthy؛ RPC/UOM/custody/RLS تمت قراءتها؛ 791 migration | SQL catalog + migrations + policies | CONFIRMED مع فجوة source parity |
| Deployed Artifact | Check لـrawaea-erp نجح، لكن bytes المنشورة لم تُجلب | GitHub Check Run | UNVERIFIED |
| Runtime / E2E | لا جلسة Browser مصادق عليها، ولا طلب بعد آخر commit | Browser tool غير متاح؛ Logs | UNVERIFIED |
| Business-Data Effects | استلامات موجودة مع PurchaseIn؛ لا سداد/قيود للفواتير الحالية | receiving + inventory_log + journal/ledger | CONFIRMED |
| Staging | لم تُستخدم بيئة معزولة ولم تُنشأ بيانات QA في Production | لا توجد كتابة اختبار | UNKNOWN / NOT RUN |

## 7. ما تم فعليًا في هذا التشغيل
1. قراءة CURRENT_STATE والدستور كاملين، ومراجعة التقارير التاريخية ذات الصلة.
2. فحص سلسلة commits من 531a63c... إلى 5f36ed...؛ جميعها Buyer/CSS فقط.
3. جلب Buyer.html كاملًا وإجراء JavaScript syntax parse لكل inline scripts؛ النتيجة PASS.
4. إنشاء harness محلي داخل الذاكرة فقط لاختبار:
   - اختيار الوحدة الأساسية والبديلة الصالحة في Quick Market: PASS.
   - رفض/إخفاء بديل معامل تحويله صفر: PASS في Quick Market.
   - حساب حجز العهدة 5,000 - 250 - 1,430 = 3,320: PASS.
   - اختيار PO لوحدة بديلة غير صالحة: كشف خلل UX موضح في القسم 11.
5. قراءة تعريفات RPC من Production، وRLS/Grants/Publication، وسجلات Edge/Postgres.
6. فحص Supabase Security/Performance/Health Advisors.
7. لم يُجرَ أي INSERT/UPDATE/DELETE/DDL أو Deploy أو تعديل في التطبيقات التشغيلية.

## 8. ما لم يتم ولماذا
- لم ينفذ Browser E2E: لا توجد جلسة Browser مصادق عليها في هذا التشغيل.
- لم يُنشأ Staging أو QA fixture: البروتوكول الحالي يمنع إنشاء بيانات اختبار في Production، ولم تتوفر بيئة معزولة مثبتة.
- لم تُعد ملفات migrations: لا يمكن اختلاق النص الأصلي للمigrations المفقودة من أسمائها وحدها؛ يجب استخراج SQL الحي ومراجعته وإعادة بنائه كمصدر موثق دون إعادة تطبيقه.
- لم تُعالج مشكلة وحدة PO غير الصالحة في الكود؛ التعديل يمس ملفًا تشغيليًا ويتطلب ChangeSet وموافقة المالك حسب الدستور.
- لم تُغير سياسات RLS أو Grants أو Branch Protection أو إعدادات Auth.

## 9. صحة التطبيقات والتغطية
| النطاق | حالة اليوم |
|---|---|
| Buyer.html | فُحص كاملًا على مستوى المصدر، والعقد الحي، والـharness المحلي؛ Runtime E2E غير منفذ |
| save-purchase-order Edge | فُحص المصدر المنشور ومطابقته؛ Version41 |
| main.html / core.js | لم تتغير في commits الجديدة؛ Core فُحص، وMain blob مطابق لنقطة LVE725 |
| Warehouse / Supervisor | لا إعادة فتح لمشكلة الدور المغلقة؛ ظهر فشل Pages check منفصل يحتاج logs |
| باقي التطبيقات التشغيلية | لم تُفحص ملفاتها اليوم لعدم وجود تغيير مباشر فيها؛ لا يُعلن أنها سليمة |
| Finance / Treasury / Supplier Ledger | فُحصت آثار فواتير PINV-1002/1003 فقط؛ لا مراجعة شاملة للدفاتر اليوم |

## 10. تدقيق التعديلات الأخيرة وآثارها
سلسلة commits بعد 531a63c...:

1. ff4e529... — إضافة اختيار الوحدة في Quick Market.
2. c03e574... — بناء CSS.
3. f7494df... — ضبط استجابة تخطيط حقل الوحدة.
4. 8a0a285... — إعادة بناء CSS.
5. 0c45474... — إضافة وحدة PO وإزالة رفض العهدة المحلي لصالح التحقق الحي من الخادم.
6. c06f391... — بناء CSS.
7. 5f36edb... — مواءمة ملخص العهدة مع RPC وتحديث حجوزات الفواتير.

- لم تتغير main.html أو core.js.
- السبب الأرجح لرسالة الرفض القديمة: شرط الواجهة السابق كان يوقف الحفظ اعتمادًا على availableByCustody قبل استدعاء Edge/RPC. أزيل هذا الشرط في commit 0c454...
- Logs نافذة 2026-11-15 بين 15:45 و16:15 UTC أظهرت 129 طلبًا إلى Edge Function بحالة HTTP 200؛ لا تسجل هذه الطلبات payload العملية، لذلك لا تثبت إنشاء فاتورة. لم يظهر 4xx أو Postgres error مطابق لخطأ العهدة في هذه النافذة.
- لم يظهر أي طلب save-purchase-order بعد commit 5f36ed... في نافذة السجلات اللاحقة التي فُحصت؛ لذلك لا يوجد إثبات Runtime بعد الإصلاح الأخير.
- الخلاصة: إصلاح الرفض المحلي موجود في المصدر، والتحقق الحي موجود في Production، لكن نجاح الحفظ الفعلي بعد آخر commit ما زال UNVERIFIED.

## 11. الأخطاء والفجوات والحلول

### P1 — فجوة مصدر migrations
**الدليل:** ثلاثة migrations مطبقة في Production غير موجودة في GitHub migration folder.  
**الأثر:** لا يمكن إعادة بناء عقد قاعدة البيانات بصورة موثوقة من المصدر، وخطر تكرار/اختلاف migrations مستقبلًا.  
**الحل المقترح:** إعداد حزمة Source-Parity من تعريفات الكتالوج الحية، مع أسماء/إصدارات/Checksums، ثم مراجعتها واعتمادها قبل إضافة ملفات تاريخية موثقة. لا يعاد تطبيق أي SQL مطبق.

### P1 — حماية فرع main
**الدليل:** GitHub Branch API يعرض protected=false ولا توجد Required Status Checks مفروضة.  
**الأثر:** نجاح/فشل checks لا يمنع دفع تغييرات إلى main.  
**الحل المقترح:** ChangeSet مستقل لحماية الفرع وفرض checks المطلوبة بعد اعتماد المالك. لم يتم تغيير إعدادات المستودع.

### P2 — PO Unit selector لا يعيد الوحدة الأساسية تلقائيًا عند preferred alt غير صالح
**الملف:** companies/company-1/purchasing/buyer.html، الدالة setInvoiceUnitOptions(item,preferredUnit)، HEAD 5f36ed...

**المقطع الحالي المستخرج من المصدر:**
~~~js
var preferred=String(preferredUnit||orderLine&&orderLine.unit||base);
if(alt&&alt!==base&&Number.isFinite(factor)&&factor>0)opts+='<option value="'+buyerEsc(alt)+'">'+buyerEsc(alt)+' ('+factor+' '+buyerEsc(base)+')</option>';
select.innerHTML=opts;
select.value=(preferred===base||preferred===alt)?preferred:base;
if(note)note.textContent=alt&&alt!==base&&factor>0?'كل 1 '+alt+' = '+factor+' '+base:'لا توجد وحدة بديلة معرفة لهذا الصنف';
~~~

**السبب:** شرط اختيار preferred===alt لا يشترط أن تكون الوحدة البديلة صالحة. إذا كانت alt_unit_qty=0 وكان purchase_order_details.unit يساوي alt_unit، فلن يوجد خيار بديل صالح، وقد تصبح قيمة select فارغة في DOM الحقيقي بدل العودة للوحدة الأساسية. لم توجد حاليًا تفاصيل PO تستخدم هذا النمط، لذلك لا يوجد أثر حالي مثبت.

**التعديل المقترح فقط — لم يطبق:**
~~~js
var preferred=String(preferredUnit||orderLine&&orderLine.unit||base);
var validAlt=!!(alt&&alt!==base&&Number.isFinite(factor)&&factor>0);
if(validAlt)opts+='<option value="'+buyerEsc(alt)+'">'+buyerEsc(alt)+' ('+factor+' '+buyerEsc(base)+')</option>';
select.innerHTML=opts;
select.value=(preferred===base||(validAlt&&preferred===alt))?preferred:base;
if(note)note.textContent=validAlt?'كل 1 '+alt+' = '+factor+' '+base:'لا توجد وحدة بديلة معرفة لهذا الصنف';
~~~

**اختبار محلي:** الـharness أعاد قيمة فارغة في النسخة الحالية عندما كان preferred هو alt غير صالح، وأعاد الوحدة الأساسية بعد تطبيق المقطع المقترح. لا يوجد تعديل في GitHub.

### P2 — نموذج وحدات محدود
- لا يمكن تمثيل ثلاثة مستويات تحويل مستقلة للصنف نفسه؛ يوجد base + alt فقط.
- إذا كان المطلوب التجاري حبة/علبة/كرتونة للصنف نفسه، يلزم تصميم UOM متعدد المستويات وجدول تحويلات، وليس إضافة خيارات ثابتة في الواجهة.

### P2 — حد GET_DATA
- Buyer يطلب limit=500، وEdge يفرض rowLimit <= 500 على GET_DATA.
- GET_CUSTODY يستخدم pagination كاملة؛ لا يوجد حد 200 ثابت في جلب سجل العهدة.
- للمشتري الحالي فاتورتان ظاهرتان فقط، فلا أثر حالي. مع تضخم السجل قد تُقتطع الفواتير/التفاصيل التي تدخل في العرض المحلي.
- يبقى RPC هو الحارس المالي الحاسم، لكنه لا يعالج نقص عرض سجل الواجهة.

### P2 — Realtime tables ناقصة
- buyer_custody_returns غير منشور في supabase_realtime وغير موجود في قائمة اشتراك Buyer.
- receiving وreceiving_details غير منشورين وغير مشترك بهما، رغم وجودهما ضمن بعض أهداف invalidation.
- يوجد fallback polling/reconcile كل 15 ثانية، ويؤجل التحديث أثناء ظهور المودال ثم يعيد التحديث بعد إغلاقه.
- لا توجد قياسات latency أو إثبات وصول أحداث فعلية. المطلوب إضافة publication/subscription ضمن ChangeSet معتمد، لا تغييرها الآن.

### P2 — سجل QA قديم
- QA-SR-INV-20260927 Draft مع is_received=true وLEGACY_UNVERIFIED، دون أثر استلام/مخزون/محاسبة مرتبط.
- لا حذف أو تعديل قبل تحديد المنشأ واعتماد المالك.

### P2 — Security/Performance Advisor
- Security Advisor:
  - 24 جدولًا RLS enabled بلا Policies؛ هذا deny-by-default وليس دليل تسريب.
  - View واحدة v_finance_employee_directory موسومة SECURITY DEFINER. لا يوجد anon SELECT؛ view عليها security_barrier=true وتفلتر الشركة والصلاحية المالية/HR أو المستخدم نفسه. لم يثبت تسريب، لكن يلزم مراجعة security_invoker/المنح.
  - 4 دوال SECURITY DEFINER قابلة لـanon حسب Advisor؛ اثنتان Trigger functions ترجع trigger ولا تمثل RPC عاديًا، واثنتان public storefront functions تتطلبان storefront key وتحددان البيانات المعادة. يلزم تنظيف منح trigger بعد مراجعة triggers.
  - 142 دالة SECURITY DEFINER قابلة لـauthenticated؛ لا يجوز إلغاءها جماعيًا. RPCs الخاصة بـBuyer لا تسمح لـanon وتتحقق من الهوية/الشركة/الصلاحية.
  - تحذير Auth: حماية كلمات المرور المسربة غير مفعلة؛ يتطلب إجراء مالك في Auth settings.
- Performance Advisor:
  - 253 unindexed foreign keys، و66 auth_rls_initplan، و118 unused indexes، و20 multiple permissive policies، و8 duplicate indexes.
  - من النطاق: FK غير مفهرس على receiving.purchase_invoice_fk وreceiving_details.purchase_invoice_detail_fk؛ تحذيرات RLS على receiving/items/buyer custody؛ index حجز العهدة لم يُستخدم بعد، وهو متوقع جزئيًا مع حجم فواتير صغير.
  - لم تُضف أو تُحذف أي فهارس أو سياسات.
- Health Advisor: لا ملاحظات.

## 12. الكفاءة التشغيلية وسيناريوهات الأعمال
| السيناريو | ما ثبت | ما لم يثبت |
|---|---|---|
| شراء سوق سريع → Draft | RPC يكتب الفاتورة وتفاصيلها ويتحقق من العهدة | حفظ من المتصفح بعد آخر commit |
| اختيار وحدة بديلة | UI + DB يحفظان معامل التحويل | فاتورة جديدة بوحدة بديلة في QA |
| استلام فعلي | PINV-1002/1003 لهما receiving وPurchaseIn | اختبار إعادة محاولة/تزامن جديد |
| PO invoice | RPC المركزي يتحقق من الوحدة، وposting يطابق المستلم | سيناريو PO كامل من الواجهة |
| سداد المورد | لا يوجد سداد/Journal/Supplier Ledger للفواتير الحالية | دورة سداد كاملة |
| عهدة المشتري | رصيد حي محسوب ومقيد على المستخدم | E2E لمستخدمين متزامنين |

## 13. التخطيط والتنبؤ ومركز القرار الذكي
- لم تُفحص اليوم جودة بيانات الطلب أو دقة Forecast أو Reorder Point أو Safety Stock.
- الحالة: UNKNOWN في هذا التشغيل؛ لا تُمنح درجة ذكاء تشغيلي اعتمادًا على وجود Dashboard فقط.

## 14. المقارنة التنافسية
- لم يُنفذ Benchmark جديد اليوم مع SAP/Dynamics/Odoo/Daftra/Manager.io/Next ERP.
- لا تُصدر دعوى تكافؤ أو تفوق. المقارنة التنافسية تبقى UNKNOWN في نطاق هذا التقرير.

## 15. مصفوفة نضج RAWAEA — تقييم محدود بنطاق الأدلة
| المجال | الدرجة | الثقة | الدليل/الفجوة |
|---|---:|---|---|
| السلامة التقنية والمعمارية | 2/5 | متوسطة | Core/Edge واضحان؛ migration parity وmain protection فجوتان |
| تكامل التطبيقات والبيانات | 2/5 | متوسطة | Buyer→RPC→DB قائم؛ Realtime ناقص لبعض الجداول |
| العمليات التجارية | 2/5 | متوسطة | استلام فعلي مثبت؛ دورة شراء كاملة غير مختبرة |
| الرقابة المالية والمحاسبية | 2/5 | متوسطة | server-side custody gate؛ لا E2E للحفظ/السداد |
| المخزون وسلاسل الإمداد | 2/5 | متوسطة | تحويل وحدة واستهلاك في الاستلام؛ لا اختبار وحدة بديلة جديد |
| التوزيع والعمل الميداني | UNKNOWN | — | لم يفحص اليوم |
| التخطيط والتنبؤ | UNKNOWN | — | لم يفحص اليوم |
| التقارير وBI | UNKNOWN | — | لم يفحص اليوم |
| الأمان والصلاحيات والتدقيق | 2/5 | متوسطة | RLS/RPC مقيدة؛ Advisor warnings وmain غير محمي |
| الأداء والاستقرار والتوسع | UNKNOWN | — | لا قياس Runtime؛ Advisor يقدم مؤشرات لا قياس حمل |
| تجربة المستخدم والإنتاجية | 2/5 | متوسطة | حقول الوحدة موجودة؛ خلل preferred alt غير صالح وغياب E2E |
| الجاهزية التشغيلية والتنافسية | UNKNOWN | — | لا E2E بعد الإصلاح ولا Benchmark حديث |

لا توجد مقارنة اتجاهية مع تقييم سابق لأن معيارًا موحدًا قابلًا للمقارنة لم يثبت في هذه الدورة.

## 16. خريطة النظام الأم والقلب المركزي والعقود
- Parent: companies/company-1/main.html — blob f495867...؛ لم يتغير منذ LVE725.
- Core: companies/company-1/core.js — blob 2b2211...؛ يوفر RW_API وRW_Realtime، ولم يتغير في سلسلة Buyer.
- Buyer: companies/company-1/purchasing/buyer.html — blob a352268...
- Edge: supabase/functions/save-purchase-order/index.ts — blob 7fb263...؛ المنشور Version41 مطابق.
- مصادر بيانات الوحدة: items.unit, items.alt_unit, items.alt_unit_qty, purchase_order_details.unit, purchase_invoice_details.unit/base_unit/unit_conversion_factor.
- مصدر قرار العهدة: buyer_custodies, buyer_custody_advances, buyer_custody_expenses, buyer_custody_returns, buyer_custody_settlements, purchase_invoices.
- لا يوجد دليل على منطق مالي موازٍ داخل Buyer؛ القرار النهائي في RPC المركزي.

## 17. مصفوفة المزامنة
| البيانات | Producer / Consumer | الآلية | ما ثبت |
|---|---|---|---|
| فواتير الشراء وتفاصيلها | Buyer / Parent / Receiving | Realtime + refresh | الجداول الأساسية منشورة ومشترك بها |
| العهد والسلف والمصروفات | Buyer / Finance | Realtime + GET_CUSTODY | الجلب كامل بالصفحات |
| مرتجعات العهدة النقدية | Finance / Buyer | polling fallback | buyer_custody_returns غير منشور وغير مشترك |
| الاستلام | Receiver / Buyer | polling fallback | receiving وreceiving_details غير منشورين |
| Cache | Buyer/Core | invalidate + 15s reconcile | الكود يحدّث التبويب الحالي ويؤجل أثناء المودال |
| Latency | Runtime | غير مقاس | لا ادعاء بمزامنة لحظية مثبتة |

- Core يضبط reconcileMs=15000، ويوقف reconcile عندما تكون الصفحة مخفية، ثم يعيد التحقق عند عودة الظهور.
- Buyer يؤجل إعادة الرسم أثناء المودال، ويراقب إغلاقه لاستئناف التحديث.
- وجود Publication/Listener لا يثبت وصول الحدث؛ لم ينفذ اختبار جهازين أو قياس latency.

## 18. جاهزية المساعد واستلام شعلة التطوير
**READY WITH LIMITATIONS**
- نقطة الاستئناف LVE725 مستعادة.
- CURRENT_STATE والدستور والتقارير ذات الصلة مقروءة.
- Buyer وEdge وRPC وProduction schema/permissions وRealtime publication تم فحصها.
- يمكن استكمال مراجعة المصدر وتحضير ChangeSet جراحي.
- لا توجد جلسة Browser مصادق عليها ولا Staging مثبتة، لذلك حفظ الفاتورة بعد آخر commit وRuntime E2E غير مثبتين.
- لا توجد موافقة محددة في هذا التشغيل لتعديل ملف Buyer أو RLS/Publication أو Branch Protection أو إعدادات Auth.

## 19. الالتزام بالدستور التشغيلي الدائم
- النسخة المقروءة: SHA 3a6b1e220af8509e314e94df76563bbc6f84910d.
- تم تطبيق سياسة 6.3: Draft لا ينشئ أثرًا وحده؛ الاستلام الفعلي هو الذي يفسر حركات PurchaseIn الحالية؛ لا سداد أو قيد للمورد دون دفع مثبت.
- بوابة موافقة المالك: لم ينفذ هذا التشغيل أي تعديل في app/DB/RLS/Edge/Deployment/Branch Settings.
- يوجد اختلاف سياسة QA: نص الدستور 6.4 يسمح في سياقه ببيانات QA محددة، بينما البروتوكول اليومي الحالي §19 يمنع استخدام Production كبيئة QA ويطلب Staging/بيئة معزولة. اتُّبع النص الأحدث والأكثر حماية: لم تُنشأ أي بيانات QA في Production.
- لا تُستخدم موافقة عامة لتجاوز موافقة ChangeSet محدد.

## 20. المخاطر والاعتماديات والقرارات التي تحتاج موافقة المالك
1. **P1:** استعادة مصدر المigrations الثلاثة المطبقة في Production إلى سجل GitHub بطريقة موثقة دون إعادة تطبيقها.
2. **P1:** حماية فرع main وفرض checks المطلوبة.
3. **P2:** إصلاح fallback للوحدة الأساسية في setInvoiceUnitOptions عند preferred alt غير صالح.
4. **P2:** حسم متطلب UOM: وحدتان لكل صنف أم ثلاث مستويات مستقلة.
5. **P2:** إضافة buyer_custody_returns وreceiving وreceiving_details إلى Publication/Subscription بعد مراجعة أثر RLS.
6. **P2:** مراجعة SECURITY DEFINER view ومنح trigger functions، وتفعيل leaked-password protection بقرار مالك.
7. **P2:** معالجة QA-labeled legacy invoice بعد تحديد مصدره وأثره، دون حذف مباشر.
8. **P2:** مراجعة حدود GET_DATA=500 ومؤشرات أداء receiving/custody عند نمو البيانات.

## 21. الخطوة التالية الواحدة ذات الأولوية
**إغلاق فجوة مصدر migrations الثلاثة المطبقة في Production (P1) دون إعادة تنفيذها.**

- النطاق: erp-frontend/supabase/migrations + تعريفات الدوال الحية في Production.
- المطلوب: حزمة Source-Parity تحتوي نص SQL المستخرج من الكتالوج، أسماء وإصدارات migrations، checksums، وdiff واضح بين Production وGitHub.
- لا DDL ولا إعادة تطبيق ولا تغيير بيانات.
- الموافقة المطلوبة: اعتماد المالك لملفات المصدر المستعادة قبل إضافتها إلى سجل migrations.
- معيار القبول: يمكن لمهندس آخر إعادة بناء العقد الحالي من GitHub، وتكون كل Migration مطبقة في Production ممثلة بمصدر موثق دون إعادة تنفيذها.
- بعد ذلك يُستكمل Browser E2E في بيئة معزولة مع اختبار وحدة بديلة وحفظ الفاتورة وعدم الأثر قبل الاستلام.

---

## مراجع مباشرة
- Operational HEAD: https://github.com/papamohammed77-glitch/erp-frontend/commit/5f36edbbc5fb18821076277c04227df3a6cf1ece
- Buyer source: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/purchasing/buyer.html
- Buyer CSS: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/purchasing/buyer.tailwind.css
- Shared Core: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/core.js
- Parent: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html
- Edge source: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/supabase/functions/save-purchase-order/index.ts
- Migrations folder: https://github.com/papamohammed77-glitch/erp-frontend/tree/main/supabase/migrations
- Governance CURRENT_STATE: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CURRENT_STATE.md
- Permanent Constitution: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/%D8%A7%D9%84%D8%AF%D8%B3%D8%AA%D9%88%D8%B1%20%D8%A7%D9%84%D8%AA%D8%B4%D8%BA%D9%8A%D9%84%D9%8A%20%D8%A7%D9%84%D8%AF%D8%A7%D8%A6%D9%85.md
- Previous checkpoint report: Report725 — WAREHOUSE ROLE MISMATCH REVALIDATION — 2026-11-14
