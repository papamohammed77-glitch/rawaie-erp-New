# تقرير التنفيذ والتحقق — Report571 — تطوير تطبيق مسئول المشتريات وربط عقوده الإنتاجية

**التاريخ:** 2026-11-01 — Africa/Cairo  
**الحالة:** تنفيذ فعلي جزئي مثبت / دورة PR إلى الاستلام اجتازت اختبار SQL معزول / واجهة المتصفح والنشر غير مثبتين / فجوات أعمال معلنة ولم تُخفَ

## 1. نقطة الانطلاق والحوكمة

تمت قراءة CURRENT_STATE وLAST VERIFIED EVENT، ثم مراجعة:
- Report545_GOVERNANCE_AUDIT_AND_DELIVERY_OWNER_PATCH_RESET_20261029.md.
- تقرير ملخص مراجعة التقارير 400–500 وما وثقه Report545 عن فهرسة 114 تقريرًا، مع الحفاظ على حد الدليل: لا ندعي إعادة قراءة نصوص التقارير الـ114 كلها واحدًا واحدًا.
- Report569_BUYER_PURCHASING_WORKFLOW_FORENSIC_AUDIT_20261031.md.
- Report570_BUYER_DIRECT_EDIT_GATE_AND_CURRENT_CONTRACT_RECONCILIATION_20261101.md.
- مصادر Buyer وCore وعقد Edge، ومخطط Supabase Production وتعريفات RPC وTriggers وACL وسجل الهجرات.

تم قبول تفويض المالك الصريح بتعديل Buyer مباشرة. لم يتم تعديل main.html أو core.js أو أي تطبيق تشغيلي منفصل آخر. التقارير السابقة استُخدمت لتحديد ما يجب التحقق منه، لا كدليل بديل عن Git/Production الحاليين.

## 2. لقطة الحقيقة بعد التنفيذ

### GitHub — المصدر التشغيلي
- Repository: papamohammed77-glitch/erp-frontend
- Branch: main
- آخر HEAD تحقق: c886554765af5b473513ab4d8ca25ce01145ce56
- Buyer: companies/company-1/purchasing/buyer.html
- Buyer blob SHA: 8da37a94b24c86d4bba65fab81273263e6306eae
- Buyer: 51,892 bytes / 519 lines.
- Buyer commit الأخير الذي غيّر الملف: 284f280ce24bdd2f8e726fa6b5a73f9935c9c4d4.
- Edge source: supabase/functions/save-purchase-order/index.ts
- Edge source blob: 95dd0098b447536633366e87223ddbc5cb7dc1ef.

### Supabase Production
- Project: SMART ERP / fiilmooggumokxanwiyx.
- Existing Edge Function save-purchase-order: **v11 ACTIVE**, verify_jwt=true.
- Production Edge SHA-256: c5e0dd68dd3bf42cd8271fd3a9672d9a09c512df7036e4553d464e527e9615aa.
- Exact byte comparison between deployed Edge v11 and Git source: MATCH.
- Applied purchasing migrations: 9، listed in section 4.

### Production business-data snapshot after rollback tests
| Entity | Count |
|---|---:|
| purchase_requests | 0 |
| purchase_rfqs | 0 |
| purchase_quotations | 0 |
| purchase_orders | 1 |
| purchase_invoices | 3 |
| purchase_payments | 0 |
| purchase_returns | 0 |
| purchase_status_history | 5 |

Counts match the Report569 baseline. QA residue query returned zero for temporary PR/RFQ/quotation/PO/invoice/supplier/receiving/audit rows.

## 3. Buyer HTML — bounded implementation

تم استبدال كتلتين محددتين فقط:
1. كتلة Navigation القديمة ذات ثلاثة تبويبات.
2. كتلة Controller التي تبدأ عند var db = new Dexie('RW_Buyer') وتنتهي قبل RW_SW.register('../sw.js').

تم الحفاظ على HTML shell وCSS وحقول تسجيل الدخول وRW_Auth وRW_API وRW_Realtime وService Worker registration والـshared Core كما هي. لا يوجد استعلام supabase.from(...) مباشر في Buyer بعد التعديل؛ عمليات القراءة والكتابة تمر من عقد Edge.

### التبويبات الستة

| التبويب | ما تم ربطه | الحدود المتبقية |
|---|---|---|
| اليوم | ملخص مركزي، أربع كروت للمطلوب، تفاصيل النواقص الحرجة، مؤشرات PR/PO/الفواتير، تنبيه واضح للعقود الناقصة، شراء عاجل ينشئ Draft invoice | موعد PO المتوقع غير مخزن؛ لذلك لا يُحسب التأخير. الزيارات والعهدة غير موجودتين كعقدين إنتاجيين |
| الموردون | قائمة وبحث، إضافة/تعديل عبر SAVE_SUPPLIER، تفاصيل المورد، رصيد الحساب، آخر أوامر الشراء، آخر أسعار الفواتير المتاحة، اتصال/واتساب/خرائط | لا email ولا تصنيف A/B/C ولا تقييم ولا supplier visits/ratings |
| طلبات PR | قائمة وبحث، تفاصيل الأصناف، Timeline، Submit/Approve/Reject، إنشاء وإرسال RFQ للموردين | لا department_id؛ كميات الاستلام لا تُخمن من PR details، بل تبقى مرتبطة بسلسلة PO/Receiver |
| أوامر PO | قائمة وبحث برقم/تاريخ/مورد/حالة، تفاصيل الأصناف والمستلم والمتبقي، Timeline، تحويل quotation مقبول إلى PO | لا إنشاء PO يدوي، ولا SEND_PO/APPROVE_PO/تحرير PO في عقد Edge الحالي |
| عهدتي | تبويب ظاهر يوضح سبب عدم التفعيل | لا يوجد buyer_custody/employee_advance مستقل؛ لم يُستخدم treasury أو cash_box كبديل مضلل |
| حسابي | ملف وصلاحيات فعالة، تقارير المشتريات، إعدادات دورة المشتريات، تسجيل الخروج | لا تسويات شخصية قبل بناء عقد العهدة |

### شراء عاجل مباشر
تم ربط المودال بعملية CREATE_INVOICE لإنشاء فاتورة شراء Draft، مع المورد والفرع ورقم فاتورة المورد والأصناف والكميات والأسعار والعملة الافتراضية.

المودال يصرّح للمستخدم أن المسودة لا ترحل المخزون أو الحسابات. لا ينفذ POST_INVOICE تلقائيًا. لم أضع زر كاميرا/OCR أو اختيار طريقة دفع غير مدعوم بعقد فعلي. لا يزال ربط الاستلام المباشر بدون PO، والتقاط صورة الفاتورة واستخراجها، وطريقة الدفع في هذا المسار، عملًا مفتوحًا.

### حدود قراءة القوائم
Edge GET_DATA يعيد حتى 500 سجل لكل قراءة حاليًا. أضيفت ملاحظة صريحة في الواجهة عن هذا الحد. البحث الحالي محلي داخل السجلات المعادة؛ pagination والبحث الخادمي لازمان قبل اعتبار القوائم مكتملة على أحجام بيانات كبيرة.

## 4. تغييرات Production — تسع migrations

1. 20261031222956_buyer_purchase_contract_scope_and_dashboard_guard_20261101
   - company_id guard على item lookups في PR وInvoice.
   - حماية purchase_get_dashboard من anon/public، وربط الاستدعاء المباشر للمستخدم المصادق بشركته وصلاحية purchases/finance أو owner؛ service_role يبقى صالحًا لاستدعاء Edge.

2. 20261031223023_buyer_supplier_effective_permission_guard_20261101
   - توحيد تفويض save_supplier_atomic ليقبل purchases/suppliers من users.permissions أو roles.permissions أو role_permissions، بدل تجاهل الصلاحيات الفعالة الآتية من role_permissions.

3. 20261031223430_buyer_pr_submit_actor_audit_alignment_20261101
   - إزالة اعتماد سجل PR على أعمدة changed_by/changed_at غير الموجودة.
   - تمرير actor الفعلي للـstatus trigger عبر transaction-local setting.

4. 20261031223530_buyer_pr_status_and_lifecycle_contract_repair_20261101
   - إضافة Submitted إلى purchase_requests_status_check.
   - السماح باعتماد Submitted PR.
   - إزالة INSERT التاريخ المكرر وغير الصحيح من reject_request.
   - ضبط actor عند submit/approve/reject/PR→RFQ conversion.

5. 20261031223657_buyer_po_status_history_and_receiver_actor_20261101
   - إضافة Trigger لتاريخ حالة purchase_orders.
   - حفظ هوية موظف الاستلام الفعلية عند تحديث حالة PO من receive_purchase_atomic.

6. 20261031223719_buyer_rfq_quotation_tenant_and_audit_actor_20261101
   - company_id guard على item lookup في quotation.
   - تصحيح actor history عند إنشاء/إرسال RFQ وقبول/تحويل quotation.

7. 20261031223811_buyer_purchase_document_creation_actor_context_20261101
   - ضبط actor قبل إنشاء RFQ/quotation/PO، وليس بعد إنشاء المستند.

8. 20261031223843_buyer_receiving_audit_action_contract_20261101
   - إضافة receive إلى القيم المسموحة في audit_log_action_check؛ لم يتم تعطيل audit log أو تغيير فعل الاستلام إلى فعل عام.

9. 20261031224236_buyer_effective_permission_wildcard_alignment_20261101
   - مواءمة صلاحية wildcard * في dashboard وsave_supplier_atomic مع effective profile.

كل migration لها ملف SQL محفوظ في operational repo تحت supabase/migrations/ بالاسم والإصدار المطابقين لسجل Supabase.

## 5. Edge v11 — العقد المركزي والصلاحيات

تم تحديث Edge Function القائمة؛ لم يتم إنشاء Edge Function جديدة.

- يتحقق من المستخدم المصادق ويستدعي get_my_effective_profile بسياق JWT المستخدم، ثم يتحقق من auth_id وcompany_id.
- يطبق صلاحيات خادمية: purchases/suppliers/finance/reports/settings، ويفرض purchases + finance على POST_INVOICE وPOST_PAYMENT وPOST_RETURN.
- يدعم wildcard * وowner.
- أضيف SAVE_SUPPLIER لاستدعاء save_supplier_atomic عبر service_role بعد التحقق من صلاحية المستخدم.
- GET_DATA للموردين يتطلب purchases أو suppliers؛ وstock_branches يتطلب purchases أو warehouse.
- أضيفت الجداول اللازمة للقراءة، ومنها purchase_settings وpurchase_status_history وpurchase_attachments وpurchase_document_links وstock_branches.
- جداول التفاصيل التي لا تحتوي company_id لا تُقرأ بفلتر company_id وهمي؛ يتم أولًا جلب IDs للمستندات الأم المقيدة بالشركة، ثم قراءة التفاصيل بواسطة foreign key: PR/RFQ/quotation/PO/invoice/return details، وRFQ suppliers، وstock_branches عبر branches.
- Git source وProduction v11 متطابقان byte-for-byte.

**اختبار محدودية التفويض:** تم اختبار SQL مباشرة لحجب anon عن purchase_get_dashboard مع بقاء service_role قادرًا على القراءة. لم يتم تنفيذ HTTP negative/positive test فعلي للـEdge بحسابات مختلفة؛ لذلك لا ندعي اكتمال مصفوفة الصلاحيات في المتصفح.

## 6. اختبارات التنفيذ الفعلية

### PASS — PR lifecycle
اختبار داخل كتلة SQL rollback-only:
- Draft → Submitted → Approved → Converted.
- إنشاء RFQ من PR.
- حدث واحد فقط في purchase_status_history لكل انتقال.
- actor الصحيح محفوظ لكل انتقال.
- لا أعمدة تاريخ غير موجودة ولا تكرار INSERT يدوي.

### PASS — PR rejection
- Submit ثم Reject.
- الحالة Rejected.
- سجل واحد للانتقال وهوية الرافض الصحيحة.
- كل البيانات الاختبارية أُلغيت.

### PASS — PO / Receiver E2E على مستوى SQL
داخل subtransaction أُلغيت بالكامل بعد التحقق:
- PR → RFQ → Send RFQ → Quotation → Accept → Convert to PO → Receive.
- تم التحقق من actor الصحيح عند إنشاء وإرسال RFQ والـquotation وقبولها وتحويلها وإنشاء PO واستلامه.
- حالة PO انتقلت إلى Received.
- stock_branches.qty زاد بالكمية المستلمة +1 داخل الاختبار.
- audit_log قبل action=receive.
- تم التحقق من PO status history.
- بعد الاختبار، rollback أعاد المخزون وكل سجلات الاستلام/الحسابات إلى ما قبل الاختبار.

### PASS — Direct purchase invoice
- إنشاء فاتورة شراء Draft بدون PO.
- تحقق إجمالي الفاتورة.
- لا تغيير في stock_branches ولا إنشاء journal entry قبل الترحيل.
- تم rollback لكل السجلات التجريبية.

### PASS — Supplier RPC
- استدعاء save_supplier_atomic بمستخدم فعّال يملك صلاحية purchases/suppliers.
- إنشاء مورد مقيد بالشركة.
- الاختبار rollback-only؛ لا مورد تجريبي متبقٍ.

### PASS — Dashboard security
- استدعاء anon تم رفضه بـPURCHASE_AUTH_REQUIRED.
- استدعاء service_role ظل قادرًا على جلب dashboard.

### PASS — Static checks
- Inline JavaScript في Buyer اجتاز V8 syntax parsing.
- التبويبات الستة موجودة.
- كل أسماء العمليات المستخدمة في Buyer موجودة في Edge v11.
- لا legacy orderHeader/itemsList payload.
- لا supabase.from(...) مباشر داخل Buyer.
- Edge v11 deployed source مطابق لملف Git.

### QA cleanup
الاستعلام النهائي أكد صفر سجلات اختبارية متبقية في PR/RFQ/quotation/PO/invoice/supplier/receiving/audit_log. أعداد سجلات Production الأساسية بقيت مطابقة للقطة Report569.

## 7. فجوات Business Contracts التي لم تُغلق بعد

هذه فجوات حقيقية، لا يجوز تغطيتها بزر أو حقل واجهة:

1. **PO:** لا expected_delivery_date ولا payment_terms ولا approved_by ولا sent_at؛ ولا CREATE_PO/SEND_PO/APPROVE_PO في Edge الحالي. المسار المتاح هو تحويل quotation مقبول إلى PO Draft.
2. **الموردون:** جدول suppliers لا يحتوي email أو A/B/C grade أو rating. لا توجد جداول supplier_visits/supplier_ratings في المخطط الذي تم فحصه.
3. **العهدة:** لا يوجد buyer_custody/employee_advance مستقل بوارد وصرف ورصيد وتسوية واعتماد ومرفقات. treasury/cash_box ليسا بديلًا.
4. **الدفع:** purchase_post_payment_atomic لا يستقبل payment_method رغم وجود purchase_payments.payment_method؛ default الحالي Cash.
5. **الشراء العاجل:** فاتورة Draft متاحة، لكن ربط الاستلام المباشر بدون PO وتسجيل وسيلة الدفع والتقاط صورة/OCR لم يُبنَ بعد.
6. **PR:** department_id غير موجود، ولا received_qty/remaining_qty على PR detail. لا يتم عرض أرقام استلام مخترعة.
7. **التوسع:** GET_DATA حده 500 سجل ولا توجد pagination/search server-side بعد.
8. **الرقابة الموحدة:** التقارير الحالية موجودة، لكن لوحة Today لا تستطيع إثبات زيارات اليوم أو العهدة أو PO overdue قبل بناء العقود المذكورة.

## 8. CONFIRMED / UNKNOWN / UNVERIFIED

### CONFIRMED
- Buyer source updated in operational Git.
- Edge v11 ACTIVE and source byte-matches Git.
- Nine Production migrations applied and versioned in operational repo.
- PR submit/approve/reject/RFQ, quotation/PO conversion, receiver stock effect, audit history, direct invoice Draft, supplier RPC, and dashboard anon guard passed isolated rollback tests.
- No QA records remain; production business-data counts match baseline.

### UNKNOWN
- المستخدمون/الأدوار الفعلية التي ينبغي أن تملك اعتماد PR أو ترحيل PO؛ permission key مخصص للاعتماد لم يُعتمد كعقد أعمال مستقل.
- قناة إرسال PO الفعلية: بريد/واتساب/نشر داخلي.
- مواصفات دورة عهدة المشتري ومطابقة التسوية مع الحسابات.
- خدمة OCR ومكان حفظ صور الزيارات والفواتير.

### UNVERIFIED
- Cloudflare served Buyer HTML/build commit/cache identity.
- Authenticated Browser E2E على حساب مسئول مشتريات فعلي.
- HTTP negative/positive Edge permission tests باستخدام حسابات متعددة.
- Realtime delivery للـPR/RFQ/PO في متصفح حي؛ الحالي يحتفظ باشتراك purchase_orders الموجود.
- اختبار cross-company فعلي لشركتين؛ لا يُستنتج من static company guards.
- مقارنة منافسين خارجية SAP/Dynamics/Odoo في هذه الدورة.

## 9. سجل التغيير

| الطبقة | التغيير |
|---|---|
| Buyer HTML | تم التعديل في Git فقط |
| save-purchase-order | تم نشر v11 وتوثيق المصدر في Git |
| Supabase Production | 9 migrations / function guards / triggers / ACL / audit constraint |
| main.html | لم يُعدل |
| core.js | لم يُعدل |
| التطبيقات المنفصلة الأخرى | لم تُعدل |
| بيانات الأعمال / المخزون / الحسابات | لا توجد تغييرات دائمة؛ كل اختبارات الكتابة rollback-only |
| Cloudflare | لم يتم نشر أو التحقق من artifact |
| Browser | لم ينفذ E2E حي |

## 10. NEXT SINGLE PRIORITY

إكمال العقود الناقصة ذات الأثر المالي والتشغيلي بالترتيب: PO expected delivery/terms/approval/send، ثم direct receiving/payment method، ثم supplier visits/rating، ثم buyer custody/settlement. لا يُنشأ أي جدول أو حالة جديدة قبل تحديد دورة العمل والـactor والصلاحيات والأثر المحاسبي والمخزني وعمليات العكس.

**الحالة:** BUYER SIX-TAB FOUNDATION IMPLEMENTED / PR→RFQ→PO→RECEIVER SQL E2E PASS (ROLLBACK) / EDGE v11 ACTIVE / BUSINESS CONTRACT GAPS OPEN / CLOUDFLARE + BROWSER E2E UNVERIFIED / NOT CLOSED.
