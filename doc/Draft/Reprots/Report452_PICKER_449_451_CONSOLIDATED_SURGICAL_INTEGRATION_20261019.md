# Report452 — دمج تقارير Picker 449–451: حزمة التعديل الجراحي الموحدة

**التاريخ:** 2026-10-19  
**النطاق الوحيد:** تكامل تطبيق المحضّر مع دورة حياة الرانشيت، عقد Inventory المركزي، وصلاحيات Production.  
**الملفات التشغيلية المحمية:** لم يتم تعديل companies/company-1/warehouse/picker.html أو companies/company-1/main.html.  
**نوع التسليم:** حزمة Owner Surgical Change Set موحدة، وليست ادعاء إغلاق تشغيلي.

---

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** التحضير يحدد الكميات الفعلية المحضّرة لكل صنف، ويجب أن يسبق التحميل. لا يحرّك المخزون فعليًا ولا يسجل حركة مخزون تجارية.
- **Architecture Understanding:** واجهة Picker مستهلك للـEdge Function؛ Edge مصادق عليه يستدعي Core RPC بامتيازات service_role؛ Core يحجز المخزون عبر reserve_stock ويحدّث order_details؛ جدول run_sheet_details إسقاط مشتق تتم مزامنته بواسطة trigger.
- **Database Understanding:** Production يؤكد أن run_sheet_details محمي بـRLS ولا يملك authenticated صلاحية UPDATE عليه. authenticated يستطيع القراءة، بينما التحديث الرسمي يتم عبر مسار الخادم.
- **Historical Understanding:** Original/PWA التاريخي في rawaie-erp-New ونسخة rawaie-erp-review محفوظتان كمرجع؛ لم يُستبدل التاريخ بملخص سابق. مصدر الواجهة الحالي هو erp-frontend/companies/company-1/warehouse/picker.html.
- **Production Understanding:** أعيد جلب Edge Functions وقاعدة البيانات والسجلات في 2026-10-19. الإصدارات الحالية هي start-picking v35، complete-picking v18، cancel-picking v5، reopen-picking v9؛ جميعها verify_jwt=true.
- **Current Understanding:** ملف Picker الحالي SHA c7ad267d852d415b680aed7716833eea9bcffdf6، 925 سطرًا. لا يزال يحتوي الكتابة المباشرة المعيبة إلى run_sheet_details، ولا يحتوي على حفظ محلي فعلي للمسودة أو operation_id في طلب الإكمال.
- **Execution Confidence:** مرتفع في تشخيص الكود والعقد الحي؛ غير كافٍ لإعلان إغلاق Runtime لأن تعديلات الواجهة ما زالت غير مطبقة في مصدر التشغيل ولم يثبت تطابق Cloudflare مع المصدر.

### الحقائق والحدود

**Confirmed Facts**
1. المصدر الحالي لم يتغير عن SHA المذكور في تقارير 449–451.
2. السطر الذي يكتب مباشرة إلى run_sheet_details موجود فعليًا.
3. Production لا يمنح authenticated UPDATE على run_sheet_details؛ ولا يجوز إضافة هذا المنح.
4. Production Core يوفّر complete_runsheet_picking بخمس معاملات، بينها p_operation_id uuid، ويمنح EXECUTE لـservice_role فقط.
5. Production Edge complete-picking v18 يقبل operation_id أو Idempotency-Key ويمرره إلى Core.
6. محتوى ملفات Current الأربع يطابق محتوى Production المنشور حرفيًا، كل وظيفة على حدة. Git blob SHA وezbr_sha256 معرفان مختلفان ولا يجوز مساواتهما.
7. السجلات الحية أظهرت OPTIONS 200 ثم GET 200 لقراءة run_sheet_details من الموقع المنشور rawaea-erp.pages.dev عند 2026-10-19T17:14:26Z.

**Unknown / Unverified**
- لم يثبت تطابق HTML الذي يقدمه Cloudflare بايتًا ببايت مع مصدر Git.
- لم ينفذ HTTP E2E للإكمال مع حساب مصادق عليه وFixture معزول.
- لم يطبق المالك بعد حزمة HTML الموحدة، ولذلك لا يمكن اختبار أثرها Runtime أو إعلان إغلاقها.

**Conflicts resolved**
- عدم وجود UPDATE على run_sheet_details ليس نقص صلاحيات؛ بل حماية صحيحة لجدول Projection.
- لا يلزم تعديل Production Schema أو ACL أو Edge لهذا النقص في Consumer؛ واجهة Picker هي التي لم تكن ترسل operation_id ولم تكن تحفظ المسودة.
- لم تُستخدم الرانشيتات المفتوحة الفعلية كبيانات اختبار، ولم تُنشأ أو تُحذف بيانات أعمال في Production.

---

## 2. المصادر التي تمت مطابقتها

| المصدر | النتيجة |
|---|---|
| erp-frontend/companies/company-1/warehouse/picker.html | Current source؛ SHA c7ad267d852d415b680aed7716833eea9bcffdf6؛ 925 سطرًا |
| rawaie-erp-New/Original/PWA/warehouse/picker.html | Historical baseline؛ SHA 7626ba320021a607854bf219f4bacd81fc3d1d92؛ 623 سطرًا |
| rawaie-erp-review/PWA/warehouse/picker.html | تمت استعادته ومقارنته كتاريخ مرجعي |
| Report449 | SHA 6d0e25ac2f2242ba305ef90139a735ae3c82fd2a |
| Report450 | SHA a1a1aa1d82a27b83f867c9609534aee9a2d61ce3 |
| Report451 | SHA 6c3c9d7207115973423967cfab06e869780110a7 |
| Current/start-picking | Git blob 14188f5d60d70cc4ec214cd27145398979e06403؛ مطابق لمصدر Production |
| Current/complete-picking | Git blob be06ac006adc146df46adc893e18105d95c0e9a3؛ مطابق لمصدر Production |
| Current/cancel-picking | Git blob 69005b8c8b73baad5d54a9af9e155d45b621014f؛ مطابق لمصدر Production |
| Current/reopen-picking | Git blob fe7d6f77f1f34ba141f47d6af6e33ac5e8443ac2؛ مطابق لمصدر Production |

أحدث commit مطابق لملف Picker تم التحقق منه: 8fa8354a347753b63be624f919cc2db0f11c8c23، بعنوان Refactor openRunsheet function for dropdown handling، ووالده 703342f4fadb046388bcdeb826b4911167c96b67. آخر تعديل ذي صلة أدخل company scoping وربط هوية المستخدم عبر public.users.auth_id؛ يجب الحفاظ على هذا السلوك وعدم إعادة بناء التطبيق من الصفر.

---

## 3. دورة الحياة وعقد الأعمال

1. App.init يثبت المستخدم وسياق الشركة وهوية public.users.
2. renderPendingTab يقرأ الرانشيتات المسموح بها للمستخدم والشركة.
3. startPicking يستدعي Edge start-picking المصادق عليه، الذي يتحقق من هوية المستخدم والشركة والصلاحيات ويبدأ دورة التحضير.
4. openRunsheet يقرأ الرانشيت وتفاصيله؛ عند حالة Picking المملوكة للمستخدم ينشئ جلسة محلية من البيانات الفعلية.
5. editPickedItem يغيّر كميات التحضير وملاحظات النقص في جلسة الواجهة. لا يجوز له الكتابة مباشرة إلى Projection.
6. completePicking يرسل الحمولة إلى Edge complete-picking؛ Core يتحقق من الرانشيت والشركة والصنف والكميات، ثم يستدعي reserve_stock ويحدّث order_details.qty_picked وحالة الرانشيت إلى Picked.
7. trigger sync_run_sheet_details يعيد بناء Projection من order_details.
8. cancel-picking يلغي دورة التحضير وفق عقد الخادم؛ reopen-picking يعيد فتح دورة التحضير المكتملة وفق صلاحياتها؛ لا ينبغي لواجهة المستخدم أن تتجاوز هاتين الوظيفتين بكتابة مباشرة.
9. التحميل اللاحق هو مرحلة حركة المخزون المادية المنفصلة؛ التحضير Reservation وليس Physical Movement، ولذلك لا يستدعي post_stock_movement.

### LOSS / GAIN / RESPONSIBILITY MATRIX

| المسؤولية | الحالة | القرار |
|---|---|---|
| Company isolation | RETAINED | الحفاظ على company_id في القراءات والتحقق الخادمي |
| User identity / warehouse role | HARDENED | الحفاظ على فحوص Edge المنشورة |
| قراءة الرانشيتات | HARDENED | عرض خطأ واضح بدل إظهار قائمة فارغة عند فشل PostgREST |
| قراءة تفاصيل الرانشيت | HARDENED | عدم تحويل خطأ القراءة إلى تفاصيل فارغة |
| تعديل الكميات محليًا | RETAINED | يبقى في self.session.items |
| الكتابة المباشرة إلى run_sheet_details | INTENTIONALLY REMOVED | Projection مشتق وليس وجهة كتابة من PWA |
| حفظ المسودة على الجهاز | ADDED | استخدام Dexie store الحالي session دون إنشاء قاعدة جديدة |
| إكمال التحضير | HARDENED | operation_id ثابت لإعادة المحاولة الآمنة |
| الحجز | RETAINED | reserve_stock داخل Core |
| الحركة المادية | INTENTIONALLY OUT OF SCOPE | لا حركة مخزون أثناء التحضير |
| main.html | RETAINED / PROTECTED | لا تعديل من المساعد |
| Production ACL / Schema | RETAINED | لا تغيير بلا Defect حي يبرره |

---

## 4. حزمة التعديل الجراحي الموحدة — ينفذها المالك فقط

**القاعدة:** قبل التطبيق، أعد جلب الملف وتأكد أن SHA ما زال c7ad267d852d415b680aed7716833eea9bcffdf6. إذا تغير SHA، أعد مطابقة محددات البحث ولا تلصق التعديلات اعتمادًا على أرقام أسطر قديمة. لا تعدّل main.html، ولا تستبدل الملف كاملًا، ولا تمنح authenticated صلاحية UPDATE على run_sheet_details.

### PATCH 452-A — حذف الكتابة غير المصرح بها إلى Projection

- **الملف:** companies/company-1/warehouse/picker.html
- **الدالة:** App.editPickedItem(index)
- **محدد البحث الحرفي:**
    supabase.from('run_sheet_details').update({ qty_picked: r.value.qty }).eq('runsheet_id', self.session.runsheet_id || null).eq('item_code', it.item_code).then(function(){});
- **الإجراء:** احذف هذا السطر وحده. لا تضف أي كتابة بديلة إلى قاعدة البيانات.
- **السبب:** هذا التحديث لا يملك صلاحية authenticated، كما أن run_sheet_details Projection مشتق من order_details بواسطة trigger. الحفظ النهائي مسؤولية complete-picking/Core فقط.

### PATCH 452-B — معالجة أخطاء قائمة الرانشيتات

- **الدالة:** App.renderPendingTab()
- **محدد البحث:** داخل .then(function(results){ ابحث عن الكتلة التالية:
    var myRunsheets = results[0].data || [];
    var openRunsheets = results[1].data || [];

    self.allRunsheets = myRunsheets.concat(openRunsheets);
    self.renderRunsheetLists(myRunsheets, openRunsheets);
- **الإجراء:** استبدل الكتلة السابقة كاملة بما يلي:
    if (results[0].error || results[1].error) {
        console.error('Picker runsheets load error:', {
            mine: results[0].error || null,
            available: results[1].error || null
        });
        safeHTML(
            byId('mainContent'),
            '<div class="text-center py-20 text-red-400">تعذر تحميل الرانشيتات. حدّث الصفحة أو راجع صلاحياتك واتصالك.</div>'
        );
        return;
    }

    var myRunsheets = results[0].data || [];
    var openRunsheets = results[1].data || [];

    self.allRunsheets = myRunsheets.concat(openRunsheets);
    self.renderRunsheetLists(myRunsheets, openRunsheets);
- **الأثر:** فشل القراءة يصبح خطأً ظاهرًا وليس «لا توجد مهام».

### PATCH 452-C — معالجة أخطاء فتح الرانشيت والتفاصيل

- **الدالة:** App.openRunsheet(code)
- **الموضع الأول:** داخل .then(function(rsRes){ وقبل if(!rsRes.data) مباشرة. أضف:
    if (rsRes.error) {
        console.error('Picker runsheet read error:', rsRes.error);
        toast('تعذر قراءة الرانشيت. تحقق من الاتصال والصلاحيات.', 'error');
        self.renderPendingTab();
        return;
    }
- **الموضع الثاني:** داخل .then(function(detRes){ وقبل var items = detRes.data || []; مباشرة. أضف:
    if (detRes.error) {
        console.error('Picker runsheet details read error:', detRes.error);
        toast('تعذر تحميل أصناف الرانشيت.', 'error');
        self.renderPendingTab();
        return;
    }
- لا تستبدل الدالة كلها، ولا تغير استعلامات company_id أو دورة الحالات.

### PATCH 452-D — حفظ واستعادة مسودة التحضير عبر Dexie

- **الدالة:** App.openRunsheet(code)
- **المحدد:** داخل الفرع الحالي:
    if(rs.status === 'Picking' && rs.picker_id === self.pubUserId)
- بعد الحلقة التي تملأ self.session.items وقبل self.renderActiveSession(); return;، استبدل هذين السطرين فقط:
    self.renderActiveSession();
    return;
- بالكتلة التالية:
    db.session.get(code).then(function(savedSession){
        var sameSession = savedSession &&
            savedSession.runsheet_id === rs.id &&
            savedSession.start_time === self.session.start_time &&
            Array.isArray(savedSession.items);

        if (sameSession) {
            if (typeof savedSession.operation_id === 'string' &&
                /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(savedSession.operation_id)) {
                self.session.operation_id = savedSession.operation_id;
            }

            for (var i = 0; i < self.session.items.length; i++) {
                var currentItem = self.session.items[i];
                for (var j = 0; j < savedSession.items.length; j++) {
                    var savedItem = savedSession.items[j];
                    if (savedItem.item_code === currentItem.item_code) {
                        var savedQty = Number(savedItem.qty_picked);
                        if (isFinite(savedQty) && savedQty >= 0 && savedQty <= currentItem.qty_ordered) {
                            currentItem.qty_picked = savedQty;
                        }
                        currentItem.notes = typeof savedItem.notes === 'string' ? savedItem.notes : '';
                        break;
                    }
                }
            }
        }

        return db.session.put(self.session);
    }).then(function(){
        self.renderActiveSession();
    }).catch(function(err){
        console.error('Picker draft restore/save error:', err);
        self.renderActiveSession();
    });
    return;
- **السبب:** Dexie موجود بالفعل، ومخزن session مفتاحه runsheet_code، لكنه لا يحفظ الجلسة الحالية. شرط runsheet_id + start_time يمنع استعادة مسودة دورة قديمة إلى دورة تحضير جديدة.
- **حدود الميزة:** المسودة محلية على الجهاز فقط؛ ليست مسودة مشتركة بين الأجهزة ولا بديلًا عن الحفظ النهائي في Core.

### PATCH 452-E — حفظ كل تعديل محلي وعدم إعادة استخدام مفتاح عملية لحمولة مختلفة

- **الدالة:** App.editPickedItem(index)
- **محدد البحث:** داخل if(r.isConfirmed){ ابحث عن الأسطر الثلاثة التالية:
    self.session.items[index].qty_picked = r.value.qty;
    self.session.items[index].notes = r.value.notes;
    supabase.from('run_sheet_details').update({ qty_picked: r.value.qty }).eq('runsheet_id', self.session.runsheet_id || null).eq('item_code', it.item_code).then(function(){});
- **استبدل الأسطر الثلاثة فقط بالكتلة التالية:**
    if (self.session.items[index].qty_picked !== r.value.qty ||
        self.session.items[index].notes !== r.value.notes) {
        self.session.operation_id = null;
    }
    self.session.items[index].qty_picked = r.value.qty;
    self.session.items[index].notes = r.value.notes;
    db.session.put(self.session).catch(function(err){
        console.error('Picker draft persistence error:', err);
        toast('تعذر حفظ مسودة التحضير على هذا الجهاز', 'error');
    });
- اترك self.renderActiveSession(); الموجود بعد الكتلة كما هو.
- **الأثر:** يحفظ التعديل محليًا ويُبطل مفتاح العملية السابق عند تغيير الكمية أو الملاحظات. لا يوجد أي UPDATE مباشر إلى قاعدة البيانات.

### PATCH 452-F — إرسال operation_id ثابت إلى complete-picking

#### F1 — إنشاء مفتاح ثابت

- **الدالة:** App.completePicking()
- **محدد البحث:** أول سطر في الدالة:
    var self = this; if(!this.session) return; if(!navigator.onLine){ toast('أنت غير متصل', 'warning'); return; }
- **استبدله كاملًا بـ:**
    var self = this; if(!this.session) return; if(!navigator.onLine){ toast('أنت غير متصل', 'warning'); return; }
    if (!this.session.operation_id) {
        if (!window.crypto || typeof window.crypto.randomUUID !== 'function') {
            toast('المتصفح لا يدعم إنشاء مفتاح العملية. حدّث المتصفح ثم أعد المحاولة.', 'error');
            return;
        }
        this.session.operation_id = window.crypto.randomUUID();
    }
    var operationId = this.session.operation_id;

#### F2 — حفظ المفتاح قبل إرسال HTTP

- **محدد البحث:** داخل .then(function(result){ عند تأكيد المستخدم، ابحث عن:
    supabase.auth.getSession().then(function(sessionRes){
- **استبدله بـ:**
    db.session.put(self.session).then(function(){
        return supabase.auth.getSession();
    }).then(function(sessionRes){
- إذا فشل حفظ المسودة فلن يُرسل الطلب دون المفتاح المحفوظ.

#### F3 — إضافة Idempotency-Key إلى HTTP

- داخل استدعاء fetch إلى /functions/v1/complete-picking، أضف إلى headers:
    'Idempotency-Key': operationId
- أبقِ Content-Type وAuthorization كما هما.

#### F4 — إضافة operation_id إلى جسم الطلب

- **محدد البحث:**
    body: JSON.stringify({ runsheet_code: self.session.runsheet_code, items: items })
- **استبدله بـ:**
    body: JSON.stringify({
        runsheet_code: self.session.runsheet_code,
        items: items,
        operation_id: operationId
    })

**عقد إعادة المحاولة:** إذا فشل الاتصال أو ضاعت الاستجابة بعد تنفيذ العملية، يعاد إرسال نفس الحمولة بنفس operation_id. إذا تغيرت الكمية أو الملاحظات، يُنشأ مفتاح جديد عند الإكمال التالي. لا تُنشئ مفتاحًا جديدًا لمجرد إعادة محاولة الحمولة نفسها.

---

## 5. لماذا لا يتطلب هذا الإصلاح تغيير Production؟

- start-picking v35 — verify_jwt=true — ezbr_sha256 fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a.
- complete-picking v18 — verify_jwt=true — ezbr_sha256 14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537.
- cancel-picking v5 — verify_jwt=true — ezbr_sha256 218052d71120eeab9f83aff045a14e24173dd15f3dafdb4e91978e7dd7bbda01.
- reopen-picking v9 — verify_jwt=true — ezbr_sha256 ca69477e935cb78b7f9cebe13940e589c58adcf891ee16e26cc15354c735b3ae.

تمت مقارنة المحتوى الفعلي المنشور مع Current source للوظائف الأربع؛ المطابقة الحرفية مؤكدة. لم أساوِ Git blob SHA بـezbr_sha256.

نتيجة SQL الحية عند 2026-10-19 19:21 UTC:
- complete_runsheet_picking بخمس معاملات، يتضمن p_operation_id، متاح لـservice_role فقط.
- overload القديم بأربع معاملات لا يملك EXECUTE لـanon أو authenticated أو service_role. لا حاجة إلى حذفه ضمن هذه المهمة.
- reserve_stock محمي من anon/authenticated ومتاح لـservice_role.
- run_sheet_details وorder_details عليهما RLS؛ authenticated SELECT=true وUPDATE=false.
- trigger trg_sync_run_sheet_details يعمل على INSERT/UPDATE/DELETE في order_details ويستدعي sync_run_sheet_details().
- لم يتم تعديل Schema أو ACL أو Edge Functions أو بيانات أعمال Production؛ الأدلة لا تبرر تعديلًا خادميًا جديدًا لهذه الحزمة.

---

## 6. خطة الاختبار بعد تطبيق المالك

لا تستخدم رانشيتًا حقيقيًا قيد العمل ولا تنشئ بيانات تجريبية في Production دون Fixture معزول مثبت وقابل للتنظيف.

1. **Static:** إعادة جلب الملف بعد التعديل؛ تحقق من عدم وجود سطر UPDATE إلى run_sheet_details، ومن وجود حراس أخطاء القراءة، وdb.session.put/get، وoperation_id.
2. **Syntax:** استخراج JavaScript وتشغيل فحص syntax كامل؛ لا يكفي فتح الصفحة دون خطأ مرئي.
3. **Draft persistence:** ابدأ تحضيرًا معزولًا، عدّل كميتين وملاحظة، أعد تحميل الصفحة، وتأكد من استعادة نفس الكميات فقط إذا تطابق runsheet_id وpicker_start.
4. **Normal completion:** تأكد من أن طلب complete-picking يرسل operation_id نفسه في الجسم وIdempotency-Key.
5. **Retry:** أعد نفس الحمولة ونفس المفتاح بعد محاكاة فقد الاستجابة؛ يجب ألا يتكرر الحجز.
6. **Payload changed:** غيّر كمية أو ملاحظة، وتأكد أن الإكمال التالي يستخدم operation_id جديدًا.
7. **Projection:** تحقق من أن order_details يتغير عبر Core وأن trigger يحدّث run_sheet_details؛ لا تستخدم PATCH/UPDATE من PWA.
8. **Lifecycle:** اختبر cancel-picking وreopen-picking مع حالات مصرح بها، وتأكد من عدم إفساد دورة التحضير.
9. **Company / role isolation:** حساب مصرح له داخل شركته ينجح، وحساب غير مصرح أو من شركة أخرى يُرفض.
10. **Production served parity:** افحص HTML الذي يقدمه Cloudflare بعد النشر، ولا تساوِ Git مع served artifact دون دليل.
11. **Baseline:** احصر أي Fixture، نظفه، ثم تحقق من عدم بقاء أثر تجريبي. لا تلمس الرانشيتات المفتوحة الموجودة حاليًا.

---

## 7. سجل التنفيذ والحوكمة

- تمت مراجعة Current source وOriginal/Historical ومقارنة تقارير 449 و450 و451 مع Production الحالي.
- تم تجميع التغييرات في ستة Patches مترابطة، مع إزالة التكرار وعدم إعادة كتابة الدوال أو الملف كاملًا.
- لم يُعدل main.html ولا ملف Picker التشغيلي بواسطة المساعد، التزامًا بتقسيم المسؤوليات المعتمد.
- لم يتم إجراء تغيير Production غير لازم، ولم تُنشأ أو تُحذف بيانات تجريبية، ولم يُمنح authenticated صلاحية إضافية.
- السجل الحي أظهر قراءة ناجحة للـProjection فقط؛ لا يُعد ذلك إثباتًا لاكتمال HTTP E2E.
- يجب على المالك تطبيق الحزمة على SHA الصحيح، ثم إعادة جلب الملف ومراجعة كل Patch بعد التطبيق. إذا كان التنفيذ قد تغير منذ هذا التقرير، فلا يعاد تطبيق Patch موجود بالفعل.

### SELF-AUDIT FINAL

**What I Proved**
- SHA المصدر الحالي وعدد أسطره ومحددات التعديل ما زالت مطابقة.
- النسخة التاريخية موجودة وتمت مقارنة دورها مع Current.
- Production Edge versions وverify_jwt وezbr_sha256 للوظائف الأربع.
- التطابق الحرفي بين Edge Production وCurrent source.
- Core/RPC signature وACL، وحماية run_sheet_details، وtrigger الذي يبني الـProjection.
- أن PWA الحالي لا يرسل operation_id ولا يستخدم Dexie لحفظ المسودة، وأنه ما زال يحتوي الكتابة المباشرة المعيبة.

**What I Did Not Prove**
- أن المالك طبق التعديلات.
- أن Cloudflare يخدم النسخة المعدلة.
- نجاح HTTP E2E أو browser E2E بعد التعديل.
- استعادة baseline بعد Fixture؛ لم يُنشأ Fixture ولم تُمس بيانات الأعمال.

**What I Fixed**
- لا تغيير على HTML أو main.html أو Production في هذه الدورة؛ قدمت حزمة جراحية موحدة من 449–451 دون تكرار.
- لا تغيير Production كان مطلوبًا أو مبررًا بالأدلة الحالية.

**What I Initially Missed**
- أن Core يدعم idempotency لكن Picker لا يرسل operation_id.
- أن مخزن Dexie session موجود لكن لا يُستخدم لاستعادة المسودة.
- أن تجاهل أخطاء PostgREST قد يجعل خطأ القراءة يبدو كأنه قائمة فارغة.

**What Could Still Be Wrong**
- قد يختلف المصدر قبل التطبيق إذا دفع المالك تعديلًا جديدًا؛ يجب إعادة التحقق من SHA.
- لا تزال parity بين Git وCloudflare وE2E غير مثبتة.
- يجب اختبار استعادة المسودة ومفتاح العملية في المتصفح قبل الإغلاق.

**Final Confidence:** مرتفع في التشخيص وProduction/Core parity؛ غير كافٍ لإغلاق Runtime قبل تطبيق المالك واختبارات E2E.

**Final Closure Status:** OWNER SURGICAL PATCHES READY / PRODUCTION CORE-EDGE VERIFIED / NO NEW PRODUCTION CHANGE REQUIRED / SERVED PARITY + HTTP E2E OPEN / NOT CLOSED.
