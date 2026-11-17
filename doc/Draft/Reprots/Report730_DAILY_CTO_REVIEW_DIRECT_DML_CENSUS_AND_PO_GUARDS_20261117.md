# RAWAEA ERP — المراجعة التشغيلية اليومية / CTO

## LVE-2026-11-17-730 — إكمال حصر Direct-DML وإعادة التحقق من دورة PR/PO/Invoice

- التاريخ: 2026-11-17 — 22:07 Africa/Cairo
- الحالة العامة: READY WITH LIMITATIONS
- حالة أي تغيير Production: BLOCKED إلى حين اعتماد Change Set محدد من المالك
- نقطة الاستئناف: LVE-2026-11-16-729
- هذا التقرير يثبت الفحص والنتائج فقط؛ لم تُنفذ أي كتابة أو DDL/DML أو نشر أو اختبار QA على Production.

### مصادر النسخ التي تمت مراجعتها

| المصدر | النسخة/المرجع |
|---|---|
| CURRENT_STATE.md | main — blob a3151edfd45e68a4edf0b62c323954e3055ebc82 — 2,466 سطر |
| الدستور التشغيلي الدائم | main — blob 3a6b1e220af8509e314e94df76563bbc6f84910d — 310 سطر |
| مستودع التشغيل | papamohammed77-glitch/erp-frontend — main HEAD ebb2a01d07c8dc1460bd4f577962a7b8c26be920 |
| آخر Commit تشغيلي | 2026-11-16T17:06:05Z — fix(buyer): show only approved POs with no warehouse receipt |
| ملفات المصدر الرئيسية | main.html 1af4430e34bb5434327cb24a3dca50b538188f42؛ core.js 2b2211a3f95049042e27a7b2ecbab3640a584942؛ buyer.html db1d311966a676dd2c7210895afefef5b5d2a954؛ purchasing/supervisor.html 916636b89f6e376b437a9328087b02de82c2610d |
| Edge Function | save-purchase-order — Git blob 22971afed19c1f23cc0038bb62e56c251202f05e — Production version 44 |
| Supabase Production | SMART ERP — fiilmooggumokxanwiyx |
| آخر Migration | 20261116144311 — receiving_rls_context_and_fk_index_opt_20261116 — إجمالي 795 migration |

المستودع التشغيلي على main غير محمي Branch Protection. الـCommit الأخير غيّر buyer.html فقط (+10/-4)، ولا يوجد Commit تشغيلي أحدث من LVE729. فحوص GitHub Actions الخمسة الظاهرة للـHEAD اكتملت بنجاح، لكن ذلك لا يثبت نشر Cloudflare أو صحة Runtime.

---

## 1. نقطة البداية — LAST VERIFIED EVENT / Checkpoint

- LAST VERIFIED EVENT السابق: LVE-2026-11-16-729 — مراجعة Direct-DML وتوسيع بوابات إنشاء فاتورة PO.
- آخر Checkpoint: main HEAD = ebb2a01d07c8dc1460bd4f577962a7b8c26be920.
- الهدف الجاري: إكمال مسح مستهلكي Direct-DML قبل طلب اعتماد CS-PRPO-729-A، وإعادة مطابقة دورة PO/Invoice بين Parent وBuyer وEdge وProduction.
- آخر إغلاق مثبت ذي صلة: LVE727 أثبت فصل إنشاء مسودة الفاتورة عن أثر الاستلام، وأثبت أن PINV-1004 لا يرحّل المخزون مرة ثانية عند الترحيل المالي.
- الأعمال المفتوحة: صلاحيات الكتابة على جداول المشتريات؛ default ACL العام؛ أهلية PO لإنشاء الفاتورة على الخادم؛ مسار PO المباشر القديم في Parent؛ حالات PR/RFQ/Quotation؛ تكرار سجل PO Created؛ فرق 20 EGP في حساب الموردين.
- ما ينتظر المالك: اعتماد Change Set محدد لأي REVOKE/تعديل Production، وحسم سياسة PO المباشر، وهوية القسم/الفرع وصاحب اعتماد PR، وتسوية فرق 20 EGP.
- ما أنجزه المساعد اليوم: حصر 70 ملف HTML/JS/TS/MJS/JSX/TSX في مستودع التشغيل، وفحص ACL/RLS/RPCs والبيانات الحية وسجلات Supabase المتاحة.
- لا يوجد Staging مثبت، ولا جلسة Browser مصادق عليها متاحة لهذا التشغيل.

## 2. CONFIRMED — الحقائق المثبتة

### 2.1 GitHub / Source

1. HEAD الحالي يطابق نقطة الاستئناف LVE729؛ لا توجد تغييرات تشغيلية أحدث.
2. آخر Commit غيّر buyer.html فقط. لا يوجد تغيير في main.html أو core.js أو save-purchase-order منذ LVE729.
3. تم جلب وفحص 70 ملفًا تشغيليًا/خادميًا/اختباريًا من شجرة المستودع. شمل ذلك main.html وcore.js وbuyer.html وpurchasing/supervisor.html وبقية تطبيقات الشركة وملفات Edge Functions وملفات الاختبار.
4. لم يظهر استدعاء PostgREST مباشر من نوع insert/update/upsert/delete على الجداول الاثني عشر محل فحص Direct-DML. توجد قراءات مباشرة، أما الكتابة المكتشفة فتذهب إلى Edge/RPC. هذا حصر لمستهلكي الجداول المحددة، وليس شهادة بأن كل وظائف التطبيقات اختُبرت.
5. الـEdge Function save-purchase-order في Production version 44 تطابق ملف GitHub الحالي byte-for-byte. verify_jwt مفعّل. لا توجد نسخة Edge مختلفة عن المصدر في هذه الوظيفة.

### 2.2 Supabase Production / RLS / Grants

1. المشروع Active، PostgreSQL 17.6.1.121.
2. عدد public base tables الحالي 190؛ RLS مفعّل على 190/190؛ FORCE RLS على 11؛ توجد سياسات على 166 جدولًا، و24 جدولًا مفعّلًا عليه RLS دون Policy (default deny).
3. عدد الجداول الأساسية التي يملك عليها anon صلاحيات DML فعالة: 78. وعددها لـauthenticated: 81. لا يوجد ضمن هذا العدد جدول DML-granted بلا RLS.
4. الجداول الاثنا عشر التالية تمنح anon وauthenticated صلاحيات كتابة مباشرة، وسياساتها من نوع FOR ALL على مستوى الشركة فقط:
   - purchase_requests
   - purchase_request_details
   - purchase_rfqs
   - purchase_rfq_details
   - purchase_rfq_suppliers
   - purchase_quotations
   - purchase_quotation_details
   - purchase_document_links
   - purchase_status_history
   - purchase_settings
   - purchase_payments
   - purchase_payment_allocations
5. سياسة الشركة تستخدم app_private.current_user_company_id()؛ والدالة تعيد company_id للمستخدم المصادق عليه من public.users ما لم تكن حالته Inactive. لا تتحقق السياسة من purchases أو finance أو دور مقدم الطلب أو القسم أو أن الكتابة عبر RPC مركزي. لذلك يستطيع أي مستخدم authenticated نشط في الشركة اجتياز شرط الشركة، إذا امتلك GRANT، دون أن تكون له صلاحية شراء.
6. صلاحيات الجداول تشمل INSERT/UPDATE/DELETE وREFERENCES وTRIGGER وSELECT، كما تكشف ACLs في PostgreSQL 17 عن MAINTAIN على جداول من النطاق. لا يظهر TRUNCATE ممنوحًا لـanon/authenticated في ACL الحالي.
7. purchase_orders وpurchase_order_details لا تمنحان authenticated صلاحيات DML مباشرة؛ صلاحياتهما للمستخدم العادي قراءة فقط.
8. purchase_status_history لا يحتوي Trigger يمنع UPDATE/DELETE ولا قيد Append-only؛ قيوده الحالية PK وcompany_id FK فقط.
9. purchase_document_links لا يحتوي FK على source_id أو target_id؛ الموجود FK على company_id وقيد Unique مركب فقط. لذلك لا يثبت FK أن المستند المصدر والهدف موجودان.
10. purchase_settings قابل للكتابة مباشرة من أي authenticated داخل الشركة وفق ACL/RLS الحالي، بما في ذلك إعداد require_receiving_before_invoice.
11. pg_default_acl ما زال يمنح صلاحيات واسعة على الجداول والتسلسلات والدوال الجديدة إلى anon/authenticated تحت مالكي الإنشاء postgres وsupabase_admin. هذا خطر مستقبلي عام مستقل عن الجداول الاثني عشر.
12. الدوال التي تكتب في الجداول المستهدفة عبر المسارات المركزية SECURITY DEFINER. دالة purchase_company_status_history() نفسها SECURITY INVOKER وتُستدعى بواسطة Triggers على PR/RFQ/Quotation/PO/Payments. يجب إبقاء هذا الاعتماد ضمن اختبارات قبول أي REVOKE.
13. ACL تنفيذ RPCs الحالي:
    - authenticated يستطيع تنفيذ purchase_create_po_atomic وpurchase_approve_po_atomic وpurchase_create_po_invoice_atomic وpurchase_update_po_invoice_atomic وpurchase_get_dashboard وpurchase_post_buyer_invoice_atomic.
    - هذه الدوال تفحص المصادقة/الشركة/الصلاحيات بدرجات مختلفة؛ purchase_approve_po_atomic لا يمنع المنشئ من اعتماد أمره بنفسه.
    - purchase_create_request_atomic وpurchase_submit_request_atomic وpurchase_approve_request_atomic وpurchase_reject_request_atomic وpurchase_create_rfq_atomic وpurchase_convert_quotation_to_po_atomic وpurchase_post_invoice_atomic وpurchase_post_payment_atomic وpurchase_post_return_atomic مقيدة حاليًا بـservice_role في ACL.
    - purchase_get_dashboard يتحقق من auth.uid ونطاق الشركة والصلاحية قبل إرجاع البيانات.
14. الدوال المتاحة للمستخدم المصادق مباشرة لا تلغي خطر Direct-DML على الجداول؛ لكنها تبيّن أن بعض مسارات الكتابة المركزية لها بوابات داخلية، بينما GRANT المباشر يسمح بتجاوزها.

### 2.3 بيانات PR/PO/Invoice الحالية

| الكيان | العدد/الحالة الحالية |
|---|---:|
| purchase_requests | 1 — Approved |
| purchase_rfqs | 0 |
| purchase_quotations | 1 — Converted |
| purchase_orders | 4: Approved=1, Draft=2, Received=1 |
| purchase_document_links | 5 |
| purchase_status_history | 22 |
| purchase_invoices | 7: Draft=5, Posted=2 |
| receiving | 7 |
| receiving_details | 10 |
| inventory_log | 86 |
| journal_entries | 21 |
| supplier_ledger | 3 |
| purchase_payments | 0 |
| purchase_payment_allocations | 0 |

- require_request_approval = true.
- require_receiving_before_invoice = false.
- Parent selector الحالي يعيد 4 POs؛ Buyer لا يجد أي PO جديد مؤهل حاليًا لأن الـPO المعتمد الوحيد لديه qty_received أكبر من صفر.
- PINV-1004: Draft، QUICK_MARKET، RECEIVED، UNSETTLED، paid_amount=0، إجمالي 2,240 EGP.
- PINV-1005: Draft، QUICK_MARKET، RECEIVED، UNSETTLED، paid_amount=0، إجمالي 100 EGP.
- PINV-1004 له مستند استلام واحد بكمية 5 كراتين = 120 وحدة أساسية. PINV-1005 له استلامان جزئيان 1 و4 كراتين، بإجمالي 5. قيود PurchaseIn الثلاثة الأخيرة في inventory_log تطابق هذه الكميات؛ لم يظهر تكرار حركة لنفس عملية الاستلام.
- لا توجد قيود journal_entries أو supplier_ledger مرتبطة بـPINV-1004 أو PINV-1005، وكلاهما paid_amount=0. لا يوجد سجل purchase_payments أو allocation لهما. لم يُعَد فحص cash_box/treasury المرجعي لهاتين الفاتورتين في هذا التشغيل، فلا أعمم عدم الأثر النقدي خارج الأدلة المذكورة.
- مقارنة LVE727: inventory_log ارتفع من 83 إلى 86؛ الزيادة الثلاثية تقابل مستندات الاستلام المذكورة، ولا تُعد اختبار QA.

### 2.4 التسوية المحاسبية

- حساب الموردين GL account 211: صافي دائن 4,690 EGP.
- دفتر الموردين subledger: صافي دائن 4,670 EGP.
- الفرق الحالي: 20 EGP، وما زال مفتوحًا.
- لا توجد حركة مرتبطة بـPINV-1004 أو PINV-1005 تفسر الفرق.
- لم يُجر أي تعديل على القيود أو دفتر الموردين.

### 2.5 Edge / Parent / Buyer contracts

1. Edge save-purchase-order version 44 يتطلب body.operation وbody.payload. عند غياب operation يرفض بـ«عملية المشتريات مطلوبة».
2. عمليات Parent الحديثة عبر RW_PurchaseGold.api ترسل operation/payload/operation_id وIdempotency-Key. تمت مطابقة 15 عملية Parent مع قائمة Edge المدعومة؛ كلها موجودة.
3. استثناء Parent هو المسار القديم RW_Purchases.savePO: يرسل {orderHeader, itemsList} مباشرة إلى save-purchase-order، دون operation/payload. هذا المسار ما زال ظاهرًا وقابلًا للوصول عبر view='purchase-pos'، ويعرض زر «أمر شراء مباشر».
4. Cart الخاص بالمسار القديم يستخدم code/price/qty/unit؛ أما RPC purchase_create_po_atomic فيستقبل عناصر بعقد item_code/qty/unit_price. لذلك لا يكفي تغيير envelope؛ يجب تحويل شكل البنود وإرسال operation_id ثابت.
5. Parent createInvoice يستخدم CREATE_INVOICE، وEdge يدعمه عبر purchase_create_invoice_atomic_v2. Parent postInvoice يستخدم POST_INVOICE، وEdge يدعمه عبر purchase_post_buyer_invoice_atomic. لا يوجد هنا اسم عملية غير مدعوم؛ الخلل في تصنيف المصدر وأهلية PO، لا في اسم العملية.
6. purchase_create_invoice_atomic لا يكتب purchase_source، وعمود purchase_source افتراضيًا LEGACY_UNCLASSIFIED. لا يوجد Trigger يصحح التصنيف عند وجود purchase_order_id. بينما purchase_post_buyer_invoice_atomic يرفض QUICK_MARKET حتى اعتماد استلام Receiver، ويرفض أي مصدر ليس PURCHASE_ORDER. لذلك فاتورة Parent العامة قد تُنشأ Draft ثم لا تقبل الترحيل إذا ظلت LEGACY_UNCLASSIFIED، حتى لو رُبطت بـPO.
7. Buyer يستخدم CREATE_PO_INVOICE والدالة المخصصة purchase_create_po_invoice_atomic، ويضع purchase_source='PURCHASE_ORDER'. لكن الدالة المخصصة لا تفرض حاليًا حالة PO Approved أو عدم وجود qty_received أو تطابق بنود الفاتورة مع بنود PO عند الإنشاء.
8. purchase_create_invoice_atomic لا يمنع إنشاء Draft مرتبطة بـPO غير مؤهل لأن require_receiving_before_invoice=false؛ كما أن purchase_create_po_invoice_atomic يرفض Cancelled فقط ولا يفرض no-receipt/Approved.
9. purchase_post_buyer_invoice_atomic يفرض المصادقة وتطابق actor والصلاحيات purchases+finance، ويشترط دليل الاستلام للـPO؛ كما يرفض ترحيل QUICK_MARKET قبل استلام Receiver. هذا يحمي الترحيل المالي لكنه لا يصلح أهلية الإنشاء وتصنيف Parent.

## 3. UNKNOWN — ما لا تسمح الأدلة الحالية بحسمه

- هل تم نشر HEAD الحالي إلى Cloudflare Pages؟ لم يمكن جلب Artifact المنشور أو إثبات build lineage.
- هل طلب Parent القديم savePO يصل فعلًا إلى Edge في جلسة مستخدم، وما رسالة Runtime التي تظهر؟ لم يوجد Browser E2E مصادق عليه.
- هل وصلت Realtime events إلى Buyer/Supervisor عند تغيير PR/PO؟ لا يوجد قياس latency أو reconnect أو cross-user delivery.
- هل جميع حسابات الموظفين لها تعيين قسم/فرع HR صالح؟ لم تُجرَ مراجعة HR كاملة اليوم.
- هل يجب أن يكون Direct PO استثناءً موثقًا أم يُمنع لصالح PR→RFQ→Quotation→PO؟ قرار المالك مطلوب.
- هل فرق 20 EGP ناتج عن قيد QA cleanup محدد أم تسوية قديمة؟ مصدره التاريخي معروف من Report727، لكن قرار المعالجة المحاسبية لم يصدر.
- لا توجد أدلة كافية اليوم لتقييم دقة أي Forecast أو نموذج تنبؤ أو كفاءة توزيع ميداني.

## 4. CONFLICT — التعارضات

1. Report729 ذكر أن 81 public base tables لديها RLS. القراءة الحالية المستقلة لـpg_class وpg_tables وinformation_schema.tables تُظهر 190/190 public base tables مع RLS، و166 جدولًا لديها Policies، و24 جدولًا بلا Policy (default deny)، و11 FORCE RLS. أعداد الجداول ذات DML grants بقيت 78 anon و81 authenticated. هذا تعارض عددي بين تقرير 729 والكتالوج الحالي؛ يُعتمد الكتالوج الحي، ولا يُعدّل التقرير التاريخي.
2. توقيت إنشاء PO-20260930 ظل تاريخيًا مختلفًا بين LVE728 وLVE729. لم يُستخدم هذا التوقيت اليوم لإثبات علاقة PR/PO؛ يجب اعتماد صف Production الحالي عند إعادة فتح التحقيق.
3. Parent وBuyer يختلفان في أهلية PO لإنشاء الفاتورة: Buyer يفرض Approved + تفاصيل + صفر استلام، بينما Parent يعرض Draft/Confirmed/Approved/Partially Received/Received. هذا تعارض حالي مثبت بين المصدرين.

## 5. UNVERIFIED — نتائج لم تُختبر مباشرة

- لم يُختبر أي DML على الجداول الاثني عشر، ولم تُنفذ محاولة استغلال أو تعديل سجل تدقيق في Production.
- لم يُنفذ REVOKE أو ALTER DEFAULT PRIVILEGES أو تعديل Policy أو RPC.
- لم يُنفذ أي اختبار E2E أو إنشاء Fixture أو عملية QA على Production.
- لم تُختبر واجهة Cloudflare المنشورة؛ URL غير متاح عبر مصدر الفحص الحالي.
- لم يُثبت تشغيل عملية شراء فعلية في Browser اليوم.
- لا يُعد نجاح GitHub Actions دليلًا على Deployment أو Runtime.

## 6. مصفوفة التحقق

| الطبقة | الحالة | الدليل/الحد |
|---|---|---|
| GitHub / Source | CONFIRMED | HEAD وDiff و70 ملف كود؛ آخر Commit Buyer فقط |
| Supabase Production | CONFIRMED | Project Active، 795 migrations، schema/RLS/ACL/RPC/data read-only |
| Deployed Artifact | UNVERIFIED | Cloudflare URL غير قابل للجلب؛ لا deployment metadata |
| Runtime / E2E | UNVERIFIED جزئيًا | 24 edge log entry خلال 24 ساعة؛ لا purchase route أو E2E |
| Business-Data Effects | CONFIRMED ضمن النطاق | استلام PINV-1004/1005 وحركات PurchaseIn المطابقة؛ لا journal/supplier posting لهما |
| Staging | UNKNOWN / غير متاح | لا Staging مثبت؛ ولا Production QA وفق التوجيه الأحدث |

## 7. ما تم فعليًا

1. استعادة CURRENT_STATE والدستور من main وقراءة آخر نقطة الاستئناف والمواد الحاكمة.
2. مراجعة Reports 569 و571 و599 و633 و680 و727 و728 و729، مع تتبع سلسلة PR/PO/Invoice والقرارات التاريخية.
3. فحص HEAD وCommit diff وGitHub Actions وBranch protection.
4. حصر 70 ملف كود حاليًا بحثًا عن Direct-DML على الجداول الاثني عشر. لم يظهر مستهلك مباشر للكتابة؛ وهذا يزيل Blocker الحصر الذي كان مفتوحًا في LVE729، ولا يمنح إذنًا بالتعديل.
5. مطابقة Edge save-purchase-order version 44 مع GitHub source.
6. فحص Production: migrations، RLS، Policies، ACLs، default ACL، Triggers، RPC signatures/EXECUTE، بيانات PR/PO/Invoice، وحركة المخزون والقيود المرتبطة.
7. مراجعة سجلات Supabase خلال 2026-11-16T20:07:24Z إلى 2026-11-17T20:07:24Z. ظهرت 24 edge log entry؛ منها WebSocket Realtime status 101 مرتين، وطلبات بدء تطبيق/بيانات رئيسية ناجحة. لم يظهر مسار save-purchase-order أو PostgREST write إلى جداول المشتريات في هذه النافذة. هذا لا يثبت عدم استخدام التطبيق خارج نافذة السجلات.
8. لم تُنفذ أي كتابة أو تغيير أو نشر.

## 8. ما لم يتم ولماذا

- لم تُسحب صلاحيات DML؛ يلزم Change Set محدد وموافقة المالك، رغم اكتمال الحصر.
- لم تُعدّل main.html أو Buyer أو Supervisor أو Edge؛ الدستور يوجب أن يطبق المالك تعديلات الملفات التشغيلية بنفسه.
- لم تُعدّل Supabase؛ التغيير يؤثر على Production ويتطلب موافقة صريحة على SQL ونطاقه وتراجعه.
- لم يُنفذ Browser E2E أو اختبار Realtime؛ لا توجد جلسة Browser مصادق عليها ولا بيئة QA معزولة معتمدة في هذا التشغيل، والتوجيه الأحدث يمنع إنشاء/تنفيذ QA على بيانات Production.
- لم تُعالج 20 EGP؛ لا يجوز تعديل GL أو supplier_ledger مباشرة أو إنشاء قيد تسوية دون اعتماد محاسبي ومسار عكس موثق.

## 9. صحة النظام والتطبيقات التشغيلية والتغطية

| النطاق | فُحص اليوم | ما ثبت | ما لم يُفحص |
|---|---|---|---|
| Parent main.html | نعم — مصدر/عقود مشتريات | مسار Parent الحديث مدعوم؛ Direct PO القديم غير متوافق | DOM/Browser/Deployment |
| core.js | نعم — مصدر/Direct-DML scan | لا Direct-DML على الجداول الاثني عشر في الملف | جميع وحدات Core Runtime |
| Buyer | نعم — مصدر/عقود PO Invoice | فلتر PO الجديد صحيح على مستوى المصدر | E2E وإنشاء/ترحيل حقيقي |
| Purchasing Supervisor | نعم — مصدر | قراءات ومزامنة رؤوس؛ لا إثبات توصيل Realtime | DOM وcross-user events |
| Edge save-purchase-order | نعم — مصدر + نسخة Production | version 44 مطابق؛ عمليات حديثة مدعومة | invocation runtime في سيناريو شراء |
| Receiver / Warehouse / Delivery / Office / Sales | مسح مصدر ضمن 70 ملفًا | لم يظهر Direct-DML على الجداول الاثني عشر | لم تُعد اختبارات الوظائف التشغيلية كاملة |
| PWA / Service Worker / Cloudflare | لا فحص Runtime كامل | لا تغيير مصدر منذ آخر Checkpoint | cache/build/activation/runtime |

لا يعلن هذا التقرير سلامة جميع التطبيقات أو اكتمال مراجعتها الوظيفية؛ نطاق اليوم هو الحماية والعقود ودورة المشتريات.

## 10. تدقيق التعديلات الأخيرة وآثارها الجانبية

- Commit ebb2a01 غيّر buyer.html فقط: Approved PO + zero warehouse receipt eligibility.
- هذا الإصلاح حسن Buyer UI، لكنه لم يوحّد Parent selector ولم يضف guard خادمي مكافئًا.
- Parent main.html وcore.js وsave-purchase-order لم تتغير منذ LVE729.
- Edge version 44 مطابق للمصدر الحالي.
- لا يوجد دليل Deployment للـCommit، لذلك حالة النشر UNKNOWN.
- لا يوجد دليل على أثر مالي/مخزني غير مقصود من هذا الـCommit؛ لم تُنفذ عملية شراء أو اختبار Runtime اليوم.

## 11. الأخطاء والفجوات والسبب الجذري

### P0 — Direct-DML على مستندات المشتريات وسجل التدقيق

السبب الجذري: GRANT الكتابة المباشرة + Policy FOR ALL على مستوى الشركة فقط. يستطيع authenticated نشط داخل الشركة نظريًا إدراج/تعديل/حذف سجلات PR/RFQ/Quotation/Links/History/Settings/Payments/Allocations دون المرور بصلاحية purchases أو RPC المركزي.

الأثر:
- تعديل حالات PR/RFQ/Quotation وتفاصيلها.
- العبث بسجل الحالة نفسه.
- إنشاء/حذف روابط مستندات دون تحقق FK على المصدر والهدف.
- تغيير إعدادات المشتريات، ومنها require_receiving_before_invoice.
- إنشاء أو تعديل سجلات دفعات/تخصيصات مضللة، وإن لم يثبت ذلك وحده حركة Cash/GL.
- تجاوز قواعد الموافقة ومنع التكرار والتحقق المركزي.

الحالة: ROOT CAUSE CONFIRMED — OWNER APPROVAL REQUIRED. لا يوجد DML exploit test في Production.

### P0 — default ACL عام للمستقبل

صلاحيات default ACL على الجداول والتسلسلات والدوال الجديدة تمنح anon/authenticated صلاحيات أوسع من اللازم. حتى بعد إغلاق الجداول الاثني عشر، قد تعود المشكلة في جداول/دوال مستقبلية. يحتاج Change Set مستقلًا بعد حصر مستهلكي بقية وحدات النظام؛ لا يُغيّر اليوم.

### P1 — Parent Direct PO يستخدم عقدًا قديمًا

- main.html line 32593 يوجّه view='purchase-pos' إلى RW_Purchases.renderPOS().
- main.html line 13551 يعرض زر «أمر شراء مباشر».
- main.html line 12189: RW_Purchases.savePO يرسل {orderHeader, itemsList} إلى save-purchase-order.
- Edge line 22 يشترط operation؛ وEdge line 139 يقرأ CREATE_PO من payload.
- Cart يستخدم code/price بينما RPC يتوقع item_code/unit_price.
- لا يوجد operation_id ثابت في المسار القديم.

الإصلاح المقترح: إذا اعتمد المالك استمرار Direct PO، يربط المسار بـoperation='CREATE_PO' وpayload الصحيح، ويحوّل cart إلى item_code/qty/unit_price، ويرسل operation_id/Idempotency-Key ثابتًا، مع فرع/موعد/شروط دفع فقط إذا كانت من حقول موثوقة. إذا قرر المالك منع PO المباشر، يعطّل المسار بدل إصلاحه.

### P1 — اختلاف أهلية PO بين Parent وBuyer وغياب Server Guard

- Parent main.html line 13673 يجلب Draft/Confirmed/Approved/Partially Received/Received.
- Buyer buyer.html line 1118 يشترط للفاتورة الجديدة PO Approved وله تفاصيل ولا توجد أي qty_received > 0؛ ويحتفظ فقط بمرجع PO الحالي لمسودة موجودة.
- Production الحالي: Parent selector=4؛ Buyer new invoice eligible=0.
- purchase_create_po_invoice_atomic يرفض Cancelled فقط ولا يفرض Approved أو عدم الاستلام أو مطابقة بنود PO.
- purchase_create_invoice_atomic يسمح بالإنشاء عندما require_receiving_before_invoice=false، وهو الإعداد الحالي.
- purchase_update_po_invoice_atomic يتحقق من حالة الفاتورة نفسها، ولا يفرض عدم وجود استلام على PO.
- الترحيل اللاحق purchase_post_buyer_invoice_atomic يفرض الاستلام الفعلي للـPO، لذلك الخلل في إنشاء/تعديل Draft وليس إثبات ترحيل مالي غير صحيح اليوم.

الإصلاح المقترح: Server guard داخل الدوال المركزية، وتوحيد Parent/Buyer helper، مع استثناء واضح لمسودة موجودة مرتبطة بالـPO نفسه فقط.

### P1 — Parent Invoice source classification

- Parent يستخدم CREATE_INVOICE → purchase_create_invoice_atomic_v2 → purchase_create_invoice_atomic.
- purchase_create_invoice_atomic لا يكتب purchase_source؛ والـdefault هو LEGACY_UNCLASSIFIED، ولا يوجد Trigger يصححه عند وجود purchase_order_id.
- Parent POST_INVOICE يمر إلى purchase_post_buyer_invoice_atomic الذي يشترط PURCHASE_ORDER ويرفض QUICK_MARKET قبل Receiver ويرفض المصادر غير المصنفة PURCHASE_ORDER.
- لذلك قد تنشأ فاتورة Parent Draft مرتبطة بـPO لكنها تظل LEGACY_UNCLASSIFIED ولا تقبل الترحيل عبر المسار نفسه.
- واجهة Parent تسمح أيضًا بخيار «بدون أمر شراء»، لكن هذا لا ينبغي أن يتحول إلى فاتورة عامة قابلة للترحيل دون دورة Quick Market/عهدة/استلام المعتمدة.

الإصلاح المقترح: توجيه PO-linked invoice إلى CREATE_PO_INVOICE وتصنيفها PURCHASE_ORDER مع Server guard؛ وحصر no-PO في مسار Quick Market المعتمد أو تعطيل الخيار في Parent. لا تغيّر التصنيف على مستندات قديمة Posted.

### P1 — خلل حالة PR/RFQ/Quotation/PO

- purchase_create_rfq_atomic يقبل PR Approved أو Draft، ثم يغير PR إلى Converted عند إنشاء RFQ.
- purchase_convert_quotation_to_po_atomic يقبل Submitted أو Accepted، ويملأ accepted_by/accepted_at تلقائيًا عند التحويل.
- purchase_reject_request_atomic لا يقبل PendingApproval رغم وجود حالة/زر رفض في الواجهة.
- purchase_approve_po_atomic يقبل purchases أو purchases_supervisor ولا يمنع منشئ PO من اعتماد أمره.
- لا توجد هوية مستقلة ثابتة للقسم/الفرع/مقدم PR وفق الحالة التاريخية؛ يلزم إعادة فحص HR schema قبل تغييرها.

### P1 — تكرار سجل PO Created

Trigger trg_purchase_orders_status_history يسجل INSERT/UPDATE على purchase_orders. كما أن purchase_create_po_atomic يكتب حدث Created يدويًا. Production يظهر لكل من PO-20260928 وPO-20260930 حدثين متزامنين بنوعين مختلفين: purchase_orders وPurchaseOrder. يلزم حذف مصدر التسجيل المكرر من RPC أو توحيد المصدر بعد اعتماد Change Set.

### P1 — فرق 20 EGP في الموردين

GL account 211 = 4,690 EGP net credit؛ supplier subledger = 4,670 EGP net credit. الفرق 20 EGP ما زال قائمًا. لا تعديل مباشر ولا قيد تسوية اليوم.

### P2 — Realtime / Supervisor / تجربة المستخدم

المصدر يحتوي اشتراكات وتحديثات، لكن لا يوجد دليل اليوم على وصول الحدث أو إعادة الاشتراك بعد انقطاع أو تحديث التفاصيل في Supervisor. لا تصف المزامنة بأنها لحظية قبل قياس Runtime.

## 12. الكفاءة التشغيلية والميدانية

- PR→RFQ→Quotation→PO موجود تصميمًا وكودًا، لكن دورة الاعتماد غير محكمة بسبب حالات Draft/Submitted والتحويل المبكر.
- PO→Receiving→Invoice posting موجود في Production، لكن Parent/Buyer لا يتبعان أهلية موحدة عند إنشاء Draft.
- Quick Market: PINV-1004 وPINV-1005 يثبتان أن مستند الاستلام الفعلي ولّد حركات PurchaseIn مطابقة، بينما بقيت الفاتورتان Draft وغير مسددتين ودون supplier/journal posting. هذا دليل بيانات على فصل الاستلام عن السداد، وليس E2E ميدانيًا.
- لا يوجد اليوم اختبار ميداني لمندوب/سائق/فرع أو قياس زمن دورة أو نسبة نقص/فاقد.

## 13. التخطيط والتنبؤ ومركز القرار الذكي

UNKNOWN في هذا التشغيل. لم تُقَس دقة توقع طلب أو نفاد أو نقطة إعادة طلب أو أداء مورد مقابل actuals. وجود تقارير أو لوحات لا يثبت Forecasting.

## 14. المقارنة التنافسية

- Report633 التاريخي يضع سياقًا وظيفيًا مع SAP وDynamics 365 وOdoo وManager.io وDaftra وNeXT، لكنه لا يمثل تحديثًا رسميًا لميزات المنتجات بتاريخ اليوم.
- لم تُجرَ اليوم مراجعة رسمية جديدة لمصادر المنافسين؛ لا يُعلن تكافؤ RAWAEA أو جاهزيتها العالمية.
- الفجوة الأوضح حاليًا في النطاق المفحوص: صلاحيات مستندات المشتريات، source provenance، فصل إنشاء/اعتماد/استلام/سداد، واتساق Parent/Buyer/Server.

## 15. مصفوفة نضج RAWAEA — تقدير محافظ لهذا النطاق

الدرجات أدناه تعكس أدلة المصدر وProduction فقط؛ النضج الميداني يبقى UNKNOWN حيث لم يوجد E2E.

| المجال | الدرجة | الثقة | الدليل المختصر |
|---|---:|---|---|
| السلامة التقنية والمعمارية | 2/5 | متوسطة | Edge/RPC مركزي موجود؛ Direct-DML وdefault ACL مفتوحان |
| تكامل التطبيقات والبيانات | 2/5 | متوسطة | Parent/Buyer/Edge عقود متقاربة مع فجوات PO/Invoice |
| العمليات التجارية | 2/5 | متوسطة | PR/RFQ/PO/Receiving موجودة لكن state machine غير محكمة |
| الرقابة المالية والمحاسبية | 2/5 | متوسطة | posting مركزي، لكن 20 EGP وsource classification |
| المخزون وسلاسل الإمداد | 2/5 | متوسطة | استلامات فعلية مطابقة؛ لا E2E كامل |
| التوزيع والعمل الميداني | UNKNOWN | منخفضة | لم يُفحص اليوم |
| التخطيط والتنبؤ | UNKNOWN | منخفضة | لا قياس Forecast |
| التقارير وBI | UNKNOWN | منخفضة | لم تُراجع دقة المؤشرات |
| الأمان والصلاحيات والتدقيق | 1/5 | مرتفعة في تشخيص الفجوة | DML grants وdefault ACL وسجل تدقيق قابل للتعديل |
| الأداء والاستقرار والتوسع | UNKNOWN | منخفضة | لا قياس Runtime/Load |
| تجربة المستخدم والإنتاجية | 2/5 | متوسطة | مسارات UI موجودة لكن Parent/Buyer غير متطابقين |
| الجاهزية التشغيلية والتنافسية | 1/5 | متوسطة | لا نشر/E2E مثبت مع P0 مفتوح |

لا توجد مقارنة اتجاهية مع التقييم السابق لأن نطاق القياس ليس مطابقًا بالكامل.

## 16. خريطة النظام الأم والقلب المركزي والعقود ذات الصلة

- Parent: companies/company-1/main.html؛ يحتوي RW_Purchases وRW_PurchaseGold ومسارات العرض والتوجيه.
- Core: companies/company-1/core.js؛ خدمات مشتركة مثل RW_DB/RW_API/RW_Realtime، ولم يُعدّل.
- Buyer: companies/company-1/purchasing/buyer.html؛ يستخدم Edge operations مثل CREATE_PO_INVOICE وUPDATE_PO_INVOICE وCREATE_QUICK_MARKET_INVOICE.
- Supervisor: companies/company-1/purchasing/supervisor.html؛ يقرأ المستندات ويحتاج إعادة اختبار اشتراكات التفاصيل.
- Edge: supabase/functions/save-purchase-order/index.ts؛ يحدد operation/payload ويستدعي RPCs.
- Database: purchase_requests/RFQs/quotations/PO/invoices/receiving/status history/document links/payments.
- مصدر الحقيقة للكتابة: RPCs المركزية/Edge؛ GRANT المباشر الحالي يسمح بمسار موازٍ غير معتمد، وهو P0.
- لم تُفحص جميع Routers/Boot/PWA/كل وحدات Core وظيفيًا اليوم؛ الخريطة هنا تخص مسار المشتريات محل التدقيق.

## 17. مصفوفة المزامنة وRealtime

| المسار | ما ثبت من المصدر | ما لم يثبت |
|---|---|---|
| Buyer purchase data | Realtime channel + refresh/reconcile | event delivery، reconnect، latency |
| Supervisor | اشتراك رؤوس مستندات | details/document_links/history updates |
| Parent | reads عبر Supabase وعمليات عبر Edge | cross-user refresh في DOM |
| Supabase Realtime | WebSocket upgrade 101 مرتان في log window | وصول change payload للمستهلك |
| Cache/PWA | ملفات SW موجودة في المصدر | artifact/cache invalidation الفعلي |

لا يوجد قياس latency موثق؛ لذلك لا يُعلن أن المزامنة لحظية.

## 18. جاهزية المساعد وAI Agent — استلام شعلة التطوير

READY WITH LIMITATIONS:
- نقطة الاستئناف واستعادة التاريخ والمصادر الحية واضحة.
- direct-DML census اكتمل للنطاق البرمجي الحالي.
- يمكن إعداد SQL Change Set واختبارات القبول دون لمس Production.
- لا يمكن تنفيذ REVOKE أو تعديل Parent/Buyer/Edge أو إعلان E2E دون موافقة المالك والأدوات/الجلسة المناسبة.
- ملفات المصدر التشغيلية يطبقها المالك بنفسه وفق الدستور.
- أي تعديل Production يحتاج Change Set محدد وموافقة صريحة؛ الموافقة العامة على المهمة لا تكفي.

## 19. الالتزام بالدستور التشغيلي الدائم

- تمت قراءة CURRENT_STATE.md والدستور من main، مع مراجعة المواد 6.3 و6.4 و7–14.
- تم تطبيق §7: لا تعديل مباشر لـmain/apps؛ إعداد إصلاح جراحي فقط.
- تم تطبيق §8–12: مصدر حالي، سبب مثبت، أثر واعتماديات، وعدم إعلان E2E.
- تم تطبيق §6.3: Draft لا ينشئ مخزونًا أو مالًا؛ الاستلام الفعلي منفصل عن الترحيل والسداد.
- §6.4 التاريخي يسمح Fixtures QA مؤقتة على Production بشروط؛ لكن التوجيه الأحدث في مهمة اليوم والقسم 19 يمنع Production QA. لذلك لم تُنشأ Fixtures ولم تُنفذ عمليات اختبار.
- لم يُنفذ أي DDL/DML أو تغيير صلاحيات أو نشر أو حذف أو تعديل مستندات حقيقية.

## 20. المخاطر والاعتماديات والقرارات التي تحتاج موافقة المالك

1. اعتماد REVOKE غير-SELECT على الجداول الاثني عشر مع إبقاء القراءة.
2. قرار مستقل حول default ACL العام على الجداول/التسلسلات/الدوال المستقبلية؛ تأثيره يشمل وحدات أخرى.
3. قرار Direct PO: إصلاح المسار القديم أو تعطيله لصالح PR/RFQ/Quotation.
4. اعتماد عقد إنشاء فاتورة PO في Parent وBuyer، وتصنيف LEGACY_UNCLASSIFIED.
5. اعتماد قواعد القسم/الفرع/مقدم PR وصلاحية الاعتماد وفصل المنشئ عن المعتمد.
6. اعتماد معالجة فرق 20 EGP بعد تحديد القيد الأصلي ومسار التسوية/العكس.
7. اعتماد إزالة الإدخال اليدوي المكرر في purchase_create_po_atomic مع الإبقاء على Trigger واحد لسجل الحالة.

## 21. الخطوة التالية الواحدة ذات الأولوية

**CS-PRPO-730-A — إغلاق صلاحيات Direct-DML الحالية على الجداول الاثني عشر، بعد اعتماد المالك للنص التالي.**

السبب: اكتمل الآن مسح 70 ملف كود ولم يظهر مستهلك مباشر للكتابة على هذه الجداول؛ لذلك زال مانع الحصر الذي منع تجهيز Change Set في LVE729. ما زالت موافقة المالك مطلوبة قبل التنفيذ.

النطاق المقترح فقط:
    REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN
    ON TABLE
      public.purchase_requests,
      public.purchase_request_details,
      public.purchase_rfqs,
      public.purchase_rfq_details,
      public.purchase_rfq_suppliers,
      public.purchase_quotations,
      public.purchase_quotation_details,
      public.purchase_document_links,
      public.purchase_status_history,
      public.purchase_settings,
      public.purchase_payments,
      public.purchase_payment_allocations
    FROM anon, authenticated;

هذا النص يحافظ على SELECT الحالي ولا يغير صلاحيات postgres أو service_role أو RPCs. لا يغير Policies ولا default ACL العام في هذه الخطوة. لا يُنفذ قبل اعتماد المالك.

معايير القبول بعد الموافقة والتنفيذ:
- has_table_privilege(authenticated, table, SELECT)=true لكل الجداول المطلوبة.
- has_table_privilege(authenticated, table, INSERT/UPDATE/DELETE/TRUNCATE/MAINTAIN)=false.
- عدم وجود DML مباشر من anon/authenticated على هذه الجداول.
- بقاء service_role وSECURITY DEFINER RPCs قادرة على تنفيذ مساراتها.
- قراءة Buyer/Parent/Supervisor تستمر وفق RLS.
- عدم تغيير أي سجل أعمال أو مخزون أو خزينة أو قيد أو Audit history.
- لا يُجرى E2E على Production دون تفويض منفصل وخطة عدم أثر؛ التحقق الأولي يكون catalog/ACL read-only، ثم اختبار مناسب فقط بعد اعتماد صريح.

Rollback محدد: إعادة الصلاحيات غير-SELECT السابقة إلى anon/authenticated على الجداول الاثني عشر فقط إذا ثبت كسر قراءة/كتابة معتمد، مع إبقاء جميع سجلات الأعمال وعدم حذف أي أثر. لا يتضمن rollback منح TRUNCATE لأنه لم يكن ممنوحًا لهذين الدورين في ACL الحالي.

بعد إغلاق CS-PRPO-730-A، تكون الأولوية التالية لتوحيد Parent/Buyer/Server invoice eligibility وتصنيف PURCHASE_ORDER، ثم إصلاح/تعطيل Direct PO القديم بقرار المالك. لا تُنفذ هذه الأعمال ضمن هذا Change Set.

### مراجع مباشرة

- CURRENT_STATE: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CURRENT_STATE.md
- الدستور: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/الدستور%20التشغيلي%20الدائم.md
- Report727: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report727_PURCHASE_RECEIPT_IDEMPOTENCY_AND_PARENT_INVOICE_STATE_CLOSURE_20261116.md
- Report728: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report728_DAILY_CTO_REVIEW_PR_PO_LIFECYCLE_20261116.md
- Report729: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report729_DAILY_CTO_REVIEW_PROCUREMENT_SERVER_GUARDS_AND_RLS_EXPANSION_20261116.md
- Parent main: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html
- Buyer: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/purchasing/buyer.html
- Purchasing Supervisor: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/purchasing/supervisor.html
- Edge save-purchase-order: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/supabase/functions/save-purchase-order/index.ts

النهاية — LVE-2026-11-17-730
