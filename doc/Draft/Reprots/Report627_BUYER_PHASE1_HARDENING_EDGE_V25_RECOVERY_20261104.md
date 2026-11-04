# تقرير 627 — استعادة Edge v25 وتجهيز Buyer Phase 1 Hardening
**التاريخ:** 4 نوفمبر 2026 — Africa/Cairo  
**نقطة البداية:** LVE626 / Report626  
**النطاق:** Buyer Phase 1 Hardening فقط؛ Receiver مؤجل كما تقرر؛ لا تعديل في النظام الأم أو Core.

## 1. الحكم التنفيذي

تمت إعادة استعادة الأدلة من المصادر الحية، وقراءة Report614_NEW_P.md والدستور التشغيلي الدائم كاملين، ثم فحص تقرير المراجع Report625 ومطابقة ما ورد فيه مع الحالة الحالية.

**الحكم:** المخاطر الأساسية التي ذكرها المراجع مؤكدة. أُنجزت خطوة مهمة كانت ناقصة: استعادة نسخة Edge المنشورة v25 حرفيًا وأرشفتها، ثم إنشاء مسودات تغيير مبنية على تعريفات الدوال الحية في Production ومصدر Buyer الحالي. هذه المسودات ليست نشرًا ولا تطبيقًا على Production.

**الحالة:** EDGE v25 SNAPSHOT RESTORED / BUYER HARDENING DRAFTS PREPARED / PRODUCTION APPROVAL GATE OPEN / RECEIVER DEFERRED.

## 2. إعادة قراءة البروتوكول

- Report614_NEW_P.md: النسخة الحية SHA `15caa4c08e40cf92a8bb626bbed8f66cf8b37bd7`.
- الدستور التشغيلي الدائم: SHA `d2afa896514b1cb6abd247d2af7a862251ce0604`.
- CURRENT_STATE عند بداية هذه الدورة: LVE626، SHA `8d4a948bc908e46b86b5dc3af82f4b6dcb771bdc`.
- تم تطبيق بوابة §6.2 و§6.3: اعتماد السياسة المالية والمخزنية لا يمثل تفويضًا مفتوحًا لتغيير Production أو الكود التشغيلي؛ يلزم عرض النص المحدد وأثره واختباره وخطة الرجوع ثم موافقة صريحة.
- لا يجوز تعديل تطبيق Buyer أو Edge التشغيلي أو Production مباشرة. يُجهّز التغيير الجراحي الدقيق ليطبقه المالك بعد اعتماده. أما فحوص Supabase فهي قراءة فقط.

## 3. فحص تقرير المراجع Report625

| ادعاء المراجع | نتيجة إعادة التحقق |
|---|---|
| Buyer HEAD bf0833c وCSS فقط | متوافق مع LVE626؛ لم يُرصد ما يغير الحكم |
| migrations Buyer 01–09 موجودة | متوافق مع LVE626 |
| Edge v25 يختلف عن Git | **CONFIRMED مجددًا**؛ انظر القسم 4 |
| تسوية العهدة لا تفحص حجوزات Quick Market | **CONFIRMED** في تعريف RPC الحي |
| مسار DELETE_DRAFT_INVOICE العام لا يفرض ملكية المشتري | **CONFIRMED** في Edge v25؛ مسار Buyer الجديد يستخدم wrappers منفصلة |
| RPC الحيازة لا يفرض evidence_path | **CONFIRMED**؛ العمود nullable والـRPC يقبل NULL |
| فشل التحقق بعد RPC قد يحذف ملف إثبات لعملية نجحت | **CONFIRMED** في catch الحالي بBuyer |
| RLS الفواتير أوسع من «فواتيري» | متوافق مع LVE626؛ يلزم إغلاقه بعد مصفوفة مستهلكي الجدولين |
| DML مباشر على purchase_returns/details | متوافق مع LVE626؛ لا يُسحب قبل consumer map |
| Receiver لا يدعم Quick Market | متوافق؛ يبقى مؤجلًا ولا تعديل عليه الآن |

## 4. استعادة Edge v25 — إنجاز مكتمل

تم جلب النسخة الحية مباشرة من Supabase:
- الوظيفة: `save-purchase-order`
- الحالة: ACTIVE
- الإصدار: 25
- `verify_jwt=true`
- SHA-256: `793ba5412a27813aa715da4078971a150d592dd03b53833148b9e99a37b5be62`
- حجم `index.ts`: 30,017 بايت.

تم أرشفة النص الحي حرفيًا في مستودع الحوكمة:
- `Current/CTO/EdgeSnapshots/20261104/save-purchase-order_v25/index.ts`
- commit: `8654dea3e0d93008d74f66b9f0a6fe5c695f2bc0`
- blob: `632f207143574a6b26145aa01cc8abc0c283d12b`
- تمت إعادة قراءة الأرشيف ومقارنته نصيًا مع النسخة الحية؛ التطابق **BYTE-FOR-BYTE = CONFIRMED**.

المصدر الموجود في مستودع التشغيل `supabase/functions/save-purchase-order/index.ts` blob `bc038be8c60a3d593f604c7b2ae445e807bacf57` حجمه 23,077 بايت ولا يطابق v25 الحي. لذلك **يُمنع نشر ملف Git الحالي فوق Production**. الأرشيف في مستودع الحوكمة ليس استعادة تشغيلية إلى مسار النشر؛ هو حفظ موثق للمصدر الحي قبل أي مزامنة تشغيلية لاحقة.

## 5. ChangeSet الجراحي المُجهز

### 5.1 Edge v25 — مسودة مبنية على النص الحي

الملف:
`Current/CTO/ChangeSets/20261104/save-purchase-order_v25_PHASE1_HARDENING_REVIEW_DRAFT.ts`

- commit: `9779f48d373fe543ffe2c31e96d9d6bf118c9c09`
- الحجم: 31,294 بايت.
- الأصل: نسخة v25 الحية، وليس ملف Git الأقدم.

التعديلات المحدودة داخل المسودة:
1. `getSystemCurrency()`: إزالة fallback الصامت إلى EGP؛ إذا لم يوجد إعداد عملة صالح يتوقف إنشاء المستند الجديد برسالة `SYSTEM_CURRENCY_INVALID`. تمت إضافة ترتيب ثانوي بـ`id` بعد `created_at` لتحديد سجل الإعداد بصورة حتمية.
2. فرع `DELETE_DRAFT_INVOICE`: قبل استدعاء الكاتب المركزي يتحقق من وجود الفاتورة ضمن الشركة ومن أن مصدرها `PURCHASE_ORDER` أو `LEGACY_UNCLASSIFIED`، ثم يتحقق من ملكية المشتري/منشئ Legacy (أو المالك)، ويرفض وجود أي حدث في `buyer_goods_custody_events`. لا يحذف Quick Market عبر المسار العام؛ يظل له wrapper المخصص.

لم تُحذف العملية العامة أو يُفترض عدم وجود مستهلكين لها؛ تم إبقاؤها مع حارس مصدر وملكية وأحداث لتجنب كسر مستهلك غير محصور. يجب استكمال مسح المستهلكين قبل اعتماد أي تغيير في عقدها.

### 5.2 SQL — مسودات استبدال الدوال الحية

الملف:
`Current/CTO/ChangeSets/20261104/01_buyer_phase1_hardening_REVIEW_DRAFT.sql`

- آخر commit: `4682d3f74213b09767e3faec8997220ef35ff1c2`
- يحتوي تعريفات كاملة مستخرجة من Production للتوقيعات الحالية، مع التعديلات التالية فقط:
  1. `buyer_custody_settle_atomic`: عدّ فواتير Quick Market المرتبطة بالعهدة ذات مصدر `EMPLOYEE_CUSTODY` والحالات المالية المفتوحة `UNSETTLED/PENDING_FINANCE/AP_OPEN/PARTIALLY_SETTLED` مع حالات المستند `Draft/Posted/PartiallyPaid`. إذا وجد أي حجز مفتوح ترفض التسوية ذريًا برسالة `CUSTODY_QUICK_MARKET_RESERVATIONS_OPEN`.
  2. `buyer_goods_custody_register_handover_atomic`: رفض المسار عند غياب `p_evidence_path`، والتحقق من بنية المسار `company/user/buyer-goods/invoice/...` ومن وجود الـobject في bucket `employee-documents` قبل إدخال حدث الحيازة.
  3. `purchase_delete_draft_invoice_atomic`: حارس دفاعي إضافي يمنع حذف فاتورة لها أي حدث حيازة بضاعة.

لم تُنفذ هذه التعريفات على Production. لا تُشغّل قبل مراجعة كامل الملف، مطابقة dependencies، compile على قاعدة مطابقة، واعتماد المالك.

### 5.3 Buyer — تصحيح نتيجة RPC المجهولة

الملف:
`Current/CTO/ChangeSets/20261104/02_buyer_evidence_unknown_outcome_REVIEW.patch.md`

- commit: `55846d16bce195198408da9767d15c4c966543cc`
- المصدر: Buyer blob `d9ffb1084a538b7f7baf48391d3048ac5e96bffa`، المقطع الفعلي حول الأسطر 1057–1065.

المسودة تميز بين:
- **CONFIRMED COMMITTED:** الحدث موجود؛ لا حذف للملف.
- **CONFIRMED NOT COMMITTED:** نجح استعلام التحقق وأثبت غياب الحدث؛ يمكن حذف الملف اليتيم.
- **UNKNOWN:** فشل التحقق؛ لا يحذف الملف، ويطلب من المستخدم المطابقة قبل إعادة المحاولة.

هذه المسودة لا تغير الملف التشغيلي.

## 6. فحص Storage والإثبات

- bucket `employee-documents` موجود وPrivate.
- Buyer يرفع إثبات المورد تحت `company_id/user_id/buyer-goods/invoice_id/...`.
- RPC الحالي لا يفرض وجود الملف ولا يطابق مساره.
- لا توجد سياسة Storage باسم مخصص لـ`buyer-goods` في القائمة الحالية؛ توجد سياسات عامة للوثائق وسياسات مخصصة لمسار `buyer-custody`.
- يلزم قبل التنفيذ حسم سياسة INSERT/SELECT/DELETE الخاصة بمسار buyer-goods، والتحقق من helpers المستخدمة في السياسات العامة، دون توسيع صلاحيات bucket أو جعله Public. توثيق Supabase يؤكد أن الرفع في bucket خاص يخضع لسياسات RLS على `storage.objects`: https://supabase.com/docs/guides/storage/security/access-control

## 7. ما بقي مفتوحًا قبل اعتماد الحزمة

1. **مصفوفة مستهلكي DELETE_DRAFT_INVOICE:** نتائج GitHub code search الحالية لم تُظهر نتائج؛ هذا لا يثبت انعدام المستهلكين. يلزم جرد كامل لمسارات الواجهات وEdge وRPCs قبل إزالة العملية أو تغيير عقدها.
2. **RLS فواتير الشراء:** تصميم سياسة مشترٍ/مالية/مالك مع اختبار جميع المستهلكين، خصوصًا Receiver والتقارير والمالية، لا مجرد تضييق company-wide.
3. **DML المرتجعات:** حصر كل المستهلكين وRPCs ثم إزالة DML المباشر المحدد؛ لا blanket revoke.
4. **Storage buyer-goods:** سياسة ضيقة تعتمد company/user/invoice prefix ودور المستخدم، واختبارات الرفع والقراءة والحذف.
5. **Buyer UI:** تطبيق المقطع المجهز، إضافة Realtime للدفتر، عرض الإثبات بأمان، وتحسين الرفع/التحقق. هذه تغييرات تطبيق تشغيلي يطبقها المالك.
6. **E2E:** لا توجد جلسة مصادق عليها أو بيئة Staging مثبتة؛ لم يُختبر مسار متصفح كامل.
7. **Cloudflare:** نشر HEAD الحالي bf0833c ما زال UNVERIFIED؛ لا إعلان نجاح نشر.

## 8. خطة القبول والتراجع

### اختبارات القبول المطلوبة بعد الاعتماد وفي بيئة معزولة مطابقة
- عهدة بها QMP Draft غير مستلمة: رفض التسوية، دون إنشاء سند نقدية أو قيد أو تغيير حالة العهدة.
- عهدة لا تحتوي QMP مفتوحة: تظل تسويتها التقليدية تعمل كما كانت.
- فاتورة مشتري A يحاول حذفها مشتري B: رفض من Edge/RPC.
- المالك/المالية وفق الدور المعتمد: السلوك المصرح فقط.
- فاتورة لها حدث حيازة: رفض الحذف حتى لو كانت Draft.
- حدث حيازة دون evidence_path: رفض RPC.
- مسار إثبات لمستخدم/شركة/فاتورة أخرى: رفض RPC.
- object غير موجود: رفض RPC.
- object موجود بمسار صحيح: إدخال الحدث مرة واحدة.
- نجاح RPC مع انقطاع استجابة التحقق: لا حذف للملف.
- إعادة العملية بنفس operation_id: duplicate دون حدث إضافي.
- إثبات Draft/handover لا يغير stock_branches أو inventory_log أو supplier_ledger أو journal_entries أو treasury.
- التحقق من سياسة Storage: المستخدم يرفع ويقرأ ملفه فقط، والمالية حسب الدور؛ لا وصول إلى ملفات موظف آخر.

### التراجع
- لا حذف لأحداث حيازة أو مستندات أو ملفات مستخدمة.
- SQL rollback يكون بإعادة تعريفات الدوال السابقة المحفوظة من Production قبل التغيير، لا بإسقاط migrations أو حذف الجداول.
- Edge rollback يكون بإعادة نشر النسخة الحية v25 المؤرشفة byte-for-byte، لا نسخة Git القديمة.
- Buyer rollback يكون بإعادة المقطع الأصلي وحده إذا ظهرت مشكلة، مع إبقاء ملفات الإثبات التي حالتها UNKNOWN للمطابقة.
- لا تعديل على بيانات Posted القديمة أو SAR التاريخية.
- لا استخدام لبيانات Production كبيانات اختبار.

## 9. سجل التنفيذ الفعلي في هذه الدورة

**تم:**
- قراءة البروتوكول والحالة والتقارير الحاكمة.
- استعادة Edge v25 وأرشفته والتحقق من التطابق النصي.
- استخراج التعريفات الحية لدوال التسوية والحذف والحيازة من Production.
- إنشاء مسودات Edge وSQL وBuyer وحفظها في مستودع الحوكمة.
- فحص bucket وسياسات Storage.

**لم يتم:**
- لا كتابة أو تعديل في المستودع التشغيلي.
- لا DDL/DML أو تغيير RPC/Trigger/RLS/GRANT/Storage/Realtime في Production.
- لا Edge deploy ولا Cloudflare deploy.
- لا تعديل Receiver.
- لا إنشاء أو حذف بيانات اختبار.

**سبب عدم التنفيذ:** §6.2 و§6.3 من الدستور التشغيلي يفرضان موافقة صريحة بعد عرض النص المحدد كاملًا. لا يجوز اعتبار الطلب العام موافقة على نص SQL أو Edge غير معروض. تم إنجاز كل ما يمكن تحضيره والتحقق منه دون تجاوز هذه البوابة.

## 10. نقطة الاستئناف

بعد اعتماد النصوص المحددة:
1. مراجعة SQL draft واختباره على بيئة مطابقة مع compile وrollback.
2. استكمال Storage policies وconsumer map وRLS invoice matrix.
3. تطبيق Buyer patch بواسطة المالك.
4. مزامنة Edge v25 إلى مسار التشغيل بعد مراجعة diff النهائي، ثم نشر النسخة المعتمدة فقط.
5. E2E مصادق عليه، ومقارنة النشر مع commit.
6. تحديث الحالة وإغلاق P1 فقط بعد ثبوت اختبارات الأثر وعدم الأثر.

**الحالة النهائية:** BUYER HARDENING CHANGESET PREPARED / NOT APPLIED / OWNER APPROVAL REQUIRED / RECEIVER DEFERRED.
