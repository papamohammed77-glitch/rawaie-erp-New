# Report562 — السبب الجذري لظهور كل Delivered في تطبيق المرتجعات
التاريخ: 2026-10-30  
الحالة: **ROOT CAUSE CONFIRMED / PRODUCTION DATA VALID / OWNER PATCH PREPARED / HTML NOT YET APPLIED / NOT CLOSED**

## 1. القرار التنفيذي

**CONFIRMED:** العيب في واجهة تطبيق المرتجعات، وليس في بيانات حالات الرانشيتات أو في قاعدة البيانات. الدالة الحالية App.loadRunsheets() تستعلم عن جميع الرانشيتات Delivered ثم تمررها إلى renderRunsheetGrid() دون تصفية حسب الكمية التي يجب إرجاعها. كما أنها لا تجلب qty_returned في استعلام التفاصيل، ولذلك لا تستطيع حساب المتبقي الصحيح.

المعيار الصحيح لأهلية رانشيت Delivered هو:

~~~text
pending_return_qty = max(qty_loaded - qty_delivered - qty_returned, 0)
~~~

يعرض الرانشيت في «مهام متاحة» فقط عندما يوجد صنف واحد على الأقل لديه pending_return_qty > 0.

**لا تُخفِ مهام Returning النشطة المسندة إلى المستخدم الحالي.** لها قسم مستقل «مهامي النشطة» حتى يستطيع المستخدم استكمال جلسة بدأها. الإصلاح يقصر التصفية على قسم «مهام متاحة» الخاص برانشيتات Delivered، ويجعل البحث متسقًا معه.

## 2. هوية المصدر والتحقق التاريخي

- الدستور التشغيلي الدائم: blob SHA `365a5178810d8da37f55dba64bf422f328a966bd`.
- المستودع التشغيلي: `papamohammed77-glitch/erp-frontend`.
- الفرع الرئيسي HEAD عند التحقيق: `7727e8271085e009f49e7f0661984063ba7196a2`.
- الملف المستهدف `companies/company-1/warehouse/returns.html` على main: blob SHA `c284f88ba0c7d4c0373b66f826f8a3c8c11599b7`, 1,123 سطرًا.
- Cloudflare Production في أحدث مشاهدة للوحة: deployment source commit `9e3fe1342abfc845a24014a3eec6fbe8abef5348`. جلبت الملف نفسه عند هذا الالتزام، وكان blob SHA `c284f88ba0c7d4c0373b66f826f8a3c8c11599b7` مطابقًا تمامًا لملف main الحالي. هذا يثبت تطابق مصدر الملف عند الالتزام المنشور مع المصدر الحالي؛ لا يثبت byte-for-byte ما أرسله Cloudflare للمتصفح.
- التزاما main بعد deployment commit لم يغيرا returns.html؛ تغييرات المقارنة كانت في ملف forensic extract وسطر واحد في main.html. لا يوجد دليل يجعل main.html سبب هذه المشكلة.
- PR #8 ما زال Draft/Open، وفرعه متباعد عن main الحالي: ahead by 2 / behind by 23. يحمل إصلاحًا سابقًا لفلترة القائمة، لكن لا تدمج الفرع كله ولا تنقله wholesale؛ استخرج منه الفكرة فقط وأعد بناء Owner Patch على SHA الحالي. كما أن بحث PR #8 يحتاج قيد إسناد Returning وإعادة Promise تفاصيل البحث.

## 3. السبب الجذري من المصدر الحالي

### App.loadRunsheets() — السطور 179–220

المقطع الحالي المسؤول عن تحميل كل Delivered:

~~~javascript
        var p1 = supabase.from('runsheets').select('id, runsheet_code, run_date, status, driver_id, return_handler_id, run_sheet_details(count)').eq('status', 'Returning').eq('return_handler_id', this.currentUser.id || this.currentUser.email).order('run_date', { ascending: false }).limit(20);
        var p2 = supabase.from('runsheets').select('id, runsheet_code, run_date, status, driver_id, run_sheet_details(count)').eq('status', 'Delivered').order('run_date', { ascending: false }).limit(50);
~~~

ثم السطر 196 يستعلم عن التفاصيل بهذه الحقول فقط:

~~~javascript
            var remainingPromise = rsIds.length > 0 ? supabase.from('run_sheet_details').select('runsheet_id, qty_loaded, qty_delivered').in('runsheet_id', rsIds) : Promise.resolve({ data: [] });
~~~

والحساب الحالي في السطور 208–212:

~~~javascript
                    var loaded = Number(det.qty_loaded) || 0;
                    var delivered = Number(det.qty_delivered) || 0;
                    if (loaded > delivered) {
                        remainingMap[det.runsheet_id] = (remainingMap[det.runsheet_id] || 0) + 1;
                    }
~~~

بعد ذلك، في السطر 215، يُرسل available كما ورد من استعلام الحالة Delivered مباشرة إلى renderRunsheetGrid(myActive, available). لا يوجد أي filter يستبعد الرانشيتات التي لا تملك كمية مرتجعة متبقية.

### واجهة العرض لا تنشئ المشكلة، لكنها تكشفها

- renderRunsheetGrid() عند السطور 246–252 ترسم كل عنصر داخل available.
- _buildCard() عند السطور 257–280 تعرض عدد الأصناف المتبقية من _remainingMap، لكنها لا تقرر أهلية الرانشيت.
- لذلك لا يكفي تعديل البطاقة أو تغيير النص؛ يجب تصفية available قبل تمريرها إلى renderer.

### الفجوة نفسها موجودة في البحث والمعاينة

- onSearchInput() عند السطور 282–296 يبحث في Delivered وReturning دون تحميل تفاصيل الكميات أو اختبار أهلية Delivered.
- renderPreview() عند السطر 378 يحسب qty_loaded - qty_delivered فقط، ولا يخصم qty_returned.
- openReturn() عند السطر 331 يقارن return_handler_id بالـ ID أو البريد، بينما العمود UUID ويخزن users.id. يجب توحيد المقارنة على currentUser.id.

## 4. إثبات Production — البيانات ليست سبب الخلل

مشروع Supabase: SMART ERP / `fiilmooggumokxanwiyx`. استعلام SQL الحالي كان للقراءة فقط:

| الرانشيت | الحالة | مجموعات الأصناف | مجموعات بها متبقٍ موجب | وحدات المرتجع المتبقية |
|---|---|---:|---:|---:|
| RS-1 | Delivered | 5 | 0 | 0 |
| RS-2 | Delivered | 7 | 5 | 5 |

إذن واجهة «مهام متاحة» الصحيحة يجب أن تعرض RS-2 فقط، وألا تعرض RS-1.

المعادلة محسوبة من run_sheet_details باستخدام qty_returned أيضًا. وفحصت تطابق التجميع مع المصدر التشغيلي order_details لرانشيتات Delivered: **12/12 مجموعة صنف/رانشيت متطابقة، 0 اختلافات**. كما أن runsheets.return_handler_id من النوع UUID، وusers.id من النوع UUID. مصدر RW_Auth الحالي ينشئ currentUser.id من profile.id / pubUserId، أي معرّف users العام، لا auth.users.id ولا البريد الإلكتروني.

## 5. Owner Patch A — إصلاح القائمة المتاحة

**الموضع:** استبدل الدالة App.loadRunsheets() كاملة، بدءًا من السطر 179 الحالي وحتى قوس إغلاقها عند السطر 220 الحالي. لا تستبدل renderRunsheetGrid() أو _buildCard().

~~~javascript
    loadRunsheets: function(){
        var self = this;
        RW_UI.showSkeleton('mainContent', 3, 'card');

        var p1 = supabase.from('runsheets')
            .select('id, runsheet_code, run_date, status, driver_id, return_handler_id')
            .eq('status', 'Returning')
            .eq('return_handler_id', this.currentUser.id)
            .order('run_date', { ascending: false })
            .limit(20);

        var p2 = supabase.from('runsheets')
            .select('id, runsheet_code, run_date, status, driver_id')
            .eq('status', 'Delivered')
            .order('run_date', { ascending: false })
            .limit(50);

        Promise.all([p1, p2]).then(function(results) {
            var primaryError = (results[0] && results[0].error) || (results[1] && results[1].error);
            if (primaryError) {
                console.error('[RW_Returns] runsheet list query failed:', primaryError);
                RW_UI.showEmptyState('mainContent', 'تعذر تحميل قائمة المرتجعات. راجع الاتصال والصلاحيات ثم أعد المحاولة.', '⚠️');
                return;
            }

            var myActive = results[0].data || [];
            var available = results[1].data || [];
            self.allRunsheets = myActive.concat(available);

            var driverIds = [], rsIds = [];
            for (var i = 0; i < self.allRunsheets.length; i++) {
                if (self.allRunsheets[i].driver_id && driverIds.indexOf(self.allRunsheets[i].driver_id) === -1) {
                    driverIds.push(self.allRunsheets[i].driver_id);
                }
                if (self.allRunsheets[i].id) rsIds.push(self.allRunsheets[i].id);
            }

            var driverPromise = driverIds.length > 0
                ? supabase.from('users').select('id, name').in('id', driverIds)
                : Promise.resolve({ data: [], error: null });

            var remainingPromise = rsIds.length > 0
                ? supabase.from('run_sheet_details')
                    .select('runsheet_id, qty_loaded, qty_delivered, qty_returned')
                    .in('runsheet_id', rsIds)
                : Promise.resolve({ data: [], error: null });

            return Promise.all([driverPromise, remainingPromise]).then(function(extraResults) {
                var remainingError = extraResults[1] && extraResults[1].error;
                if (remainingError) {
                    console.error('[RW_Returns] remaining quantities query failed:', remainingError);
                    RW_UI.showEmptyState('mainContent', 'تعذر تحميل الكميات المتبقية للمرتجعات. لا تبدأ المرتجع قبل التحقق من الكميات.', '⚠️');
                    return;
                }
                if (extraResults[0] && extraResults[0].error) {
                    console.warn('[RW_Returns] driver names query failed:', extraResults[0].error);
                }

                var userMap = {};
                var users = extraResults[0].data || [];
                for (var ui = 0; ui < users.length; ui++) {
                    userMap[users[ui].id] = users[ui].name;
                }
                self._driverMap = userMap;

                var remainingMap = {};
                var details = extraResults[1].data || [];
                for (var di = 0; di < details.length; di++) {
                    var det = details[di];
                    var loaded = Number(det.qty_loaded) || 0;
                    var delivered = Number(det.qty_delivered) || 0;
                    var returned = Number(det.qty_returned) || 0;

                    if (loaded - delivered - returned > 0) {
                        remainingMap[det.runsheet_id] = (remainingMap[det.runsheet_id] || 0) + 1;
                    }
                }
                self._remainingMap = remainingMap;

                // Keep only Delivered runsheets with at least one positive pending-return item.
                available = available.filter(function(rs) {
                    return (remainingMap[rs.id] || 0) > 0;
                });

                self.renderRunsheetGrid(myActive, available);
            });
        }).catch(function(error) {
            console.error('[RW_Returns] unexpected runsheet load failure:', error);
            RW_UI.showEmptyState('mainContent', 'حدث خطأ غير متوقع أثناء تحميل المرتجعات. راجع Console ثم أعد المحاولة.', '📡');
        });
    },
~~~

**الأثر المقصود:**
- أي Delivered لا يملك صنفًا واحدًا على الأقل به كمية موجبة بعد خصم المسلّم والمرتجع لن يصل إلى renderRunsheetGrid().
- لا يعرض التطبيق نتائج خاطئة عند فشل استعلام الكميات؛ يفشل مغلقًا برسالة خطأ بدل عرض كل Delivered.
- تبقى مهام Returning النشطة للمستخدم الحالي في قسمها المنفصل.
- أزلت fallback إلى البريد في شرط return_handler_id لأن العمود UUID ويخزن users.id.

**قيد قائم يجب عدم إخفائه:** استعلام Delivered يحتفظ بحد 50 المرصود في تصميم الشاشة الحالي. هذا يمنع عرض أكثر من أحدث 50 مرشحًا في هذا القسم؛ قد يخفي رانشيتًا مؤهلًا أقدم من هذه الدفعة إذا تجاوز السجل 50. لا ينتج عن ذلك ظهور رانشيت غير مؤهل، لكنه حدّ اكتمال/توسع يجب تحويله لاحقًا إلى pagination إذا كان عدد الرانشيتات المؤهلة يتجاوز هذا النطاق. في بيانات Production الحالية يوجد رانشيتان فقط.

## 6. Owner Patch B — توحيد البحث مع أهلية القائمة

**الموضع:** استبدل App.onSearchInput() كاملة عند السطور 282–296. أبقِ renderSearchDropdown() الحالية دون تغيير؛ استعلامها سيستمر في جلب run_sheet_details(count) الذي يحتاجه renderer لحساب عدد الأصناف.

~~~javascript
    onSearchInput: function(query){
        var self = this;
        var searchText = String(query || '').trim();
        if (this.searchTimer) clearTimeout(this.searchTimer);

        if (!searchText) {
            this.searchResults = [];
            var dd = RW_UI.byId('searchDropdown');
            if (dd) dd.classList.add('hidden');
            return;
        }

        this.searchTimer = setTimeout(function() {
            supabase.from('runsheets')
                .select('id, runsheet_code, status, run_date, driver_id, return_handler_id, run_sheet_details(count)')
                .in('status', ['Delivered', 'Returning'])
                .ilike('runsheet_code', '%' + searchText + '%')
                .order('run_date', { ascending: false })
                .limit(50)
                .then(function(res) {
                    if (res.error) {
                        console.error('[RW_Returns] runsheet search query failed:', res.error);
                        self.searchResults = [];
                        self.renderSearchDropdown();
                        return;
                    }

                    var rows = res.data || [];
                    var rowIds = rows.map(function(rs) { return rs.id; }).filter(Boolean);
                    if (!rowIds.length) {
                        self.searchResults = [];
                        self.renderSearchDropdown();
                        return;
                    }

                    return supabase.from('run_sheet_details')
                        .select('runsheet_id, qty_loaded, qty_delivered, qty_returned')
                        .in('runsheet_id', rowIds)
                        .then(function(detailsRes) {
                            if (detailsRes.error) {
                                console.error('[RW_Returns] runsheet search details query failed:', detailsRes.error);
                                self.searchResults = [];
                                self.renderSearchDropdown();
                                return;
                            }

                            var pending = {};
                            (detailsRes.data || []).forEach(function(det) {
                                var remaining = (Number(det.qty_loaded) || 0)
                                    - (Number(det.qty_delivered) || 0)
                                    - (Number(det.qty_returned) || 0);
                                if (remaining > 0) pending[det.runsheet_id] = true;
                            });

                            self.searchResults = rows.filter(function(rs) {
                                if (rs.status === 'Delivered') return pending[rs.id] === true;
                                if (rs.status === 'Returning') {
                                    return !!self.currentUser && !!self.currentUser.id
                                        && rs.return_handler_id === self.currentUser.id;
                                }
                                return false;
                            });
                            self.renderSearchDropdown();
                        });
                }).catch(function(error) {
                    console.error('[RW_Returns] unexpected runsheet search failure:', error);
                    self.searchResults = [];
                    self.renderSearchDropdown();
                });
        }, 300);
    },
~~~

لاحظ أن Promise استعلام التفاصيل أُعيدت بـ return حتى تصل حالات الرفض إلى catch الخارجي. كما أن نتائج Returning أصبحت مقيدة بالمسند إليه، لا أي مستخدم آخر.

## 7. Owner Patch C — تطابق المعاينة وهوية المستخدم النشط

1. في App.renderPreview()، السطر الحالي 378:

~~~javascript
            var remaining = (Number(it.qty_loaded) || 0) - (Number(it.qty_delivered) || 0);
~~~

استبدله بـ:

~~~javascript
            var remaining = Math.max(0, (Number(it.qty_loaded) || 0) - (Number(it.qty_delivered) || 0) - (Number(it.qty_returned) || 0));
~~~

2. في App.openReturn()، السطر الحالي 331:

~~~javascript
                var isActive = (rs.status === 'Returning' && (rs.return_handler_id === self.currentUser.id || rs.return_handler_id === self.currentUser.email));
~~~

استبدله بـ:

~~~javascript
                var isActive = (rs.status === 'Returning' && rs.return_handler_id === self.currentUser.id);
~~~

لا تغيّر منطق الجلسة أو حفظ المسودة أو أزرار الإلغاء ضمن هذه المهمة.

## 8. اختبارات القبول وعدم التراجع

| الحالة | النتيجة المطلوبة |
|---|---|
| Delivered، loaded=10، delivered=10، returned=0 | مخفي |
| Delivered، loaded=10، delivered=5، returned=5 | مخفي |
| Delivered، loaded=10، delivered=5، returned=2 | ظاهر؛ المتبقي 3 |
| Delivered، loaded=10، delivered=0، returned=0 | ظاهر؛ المتبقي 10 |
| Delivered، كل أصنافه remaining <= 0 | مخفي |
| Delivered، صنف واحد فقط remaining > 0 | ظاهر |
| Returning ومسند إلى المستخدم الحالي | ظاهر في «مهامي النشطة» |
| Returning ومسند إلى مستخدم آخر | غير ظاهر |
| استعلام تفاصيل الكميات يفشل | لا تعرض Delivered اعتمادًا على بيانات ناقصة؛ اعرض خطأ التحميل |
| البحث عن Delivered غير مؤهل | لا يعرض نتيجة |
| البحث عن Returning غير مسند للمستخدم الحالي | لا يعرض نتيجة |

### التحقق الحالي قبل تطبيق Owner Patch
- RS-1 يجب أن يختفي (0 وحدة متبقية / 0 مجموعات مؤهلة).
- RS-2 يجب أن يظهر (5 وحدات متبقية / 5 مجموعات أصناف مؤهلة).
- اختبار SQL المقارن للمصدر والإسقاط: 12/12 متطابقة، 0 mismatch.
- تم تشغيل node --check على نسختي الدالتين المقترحتين A وB: syntax PASS. هذا تحقق صياغة للمقاطع المقترحة فقط، وليس E2E للتطبيق.
- لم تتغير ملفات تشغيلية أو بيانات Production أو RLS/ACL/RPC/Edge Functions في هذه الجولة.

## 9. حدود الإغلاق والخطوات التالية

**CONFIRMED:** السبب الجذري في returns.html مثبت، وبيانات Production سليمة ومتسقة. ملف المصدر عند commit Cloudflare Production يحمل نفس blob الموجود في main الحالي.

**OWNER ACTION REQUIRED:** تطبيق Owner Patches A–C على الملف الحالي ذي SHA `c284f88ba0c7d4c0373b66f826f8a3c8c11599b7`، لا على فرع PR #8 القديم. بعد التطبيق أعد جلب الملف واحسب SHA جديدًا، ثم نفذ اختبار المتصفح المصادق عليه للتحقق من أن RS-1 اختفى وRS-2 ظهر، وأن البحث والمعاينة يعطيان النتيجة نفسها.

**UNVERIFIED:** لا يمكن إعلان حل Production قبل تطبيق Owner Patch والتحقق من الصفحة المنشورة وسلوك المتصفح. لم أعدّل HTML تشغيليًا بسبب قاعدة Owner-only في الدستور؛ لم أنشئ commit أو merge لهذا الملف.

**STATUS: ROOT CAUSE CONFIRMED / OWNER PATCH READY / PRODUCTION DATA HEALTHY / HTML DEPLOYMENT + AUTHENTICATED E2E PENDING / NOT CLOSED.**
