# تقرير 189 — Loyalty Transaction Engine + Sales Targets — Current Forensic Closure

**التاريخ:** 15 سبتمبر 2026

## 1. تنبيه حاكم

تم التعامل مع `companies/company-1/main.html` في المستودع `papamohammed77-glitch/erp-frontend` باعتباره **Source of Truth الوحيد للنظام الأم**.

التقارير السابقة، ومنها Report172 وReport188، استخدمت كأدلة تاريخية ومؤشرات بحث فقط، ولم تُعامل كحالة حالية.

الحالة الحالية المعتمدة هي:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`.

## 2. قراءة النظام الأم

المصدر الحالي:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

HEAD:
`13425725f48c7decba3403ee631d8e0f2d757b0f`

Parent:
`05ebb2d67b29dfe26ad77b6f314942c502e0dd8f`

Blob:
`5267f261f2febcbafeafdce0bb9da89a4a6bc894`

الملف الحالي تم قراءته chunk-by-chunk حتى EOF، وآخر جزء ينتهي بـ `</html>` عند السطر 40857.

لم يتم تعديل `main.html` في Git بواسطة المساعد، تطبيقًا لفصل المسؤوليات: تعديل النظام الأم مسؤولية المالك.

## 3. نتيجة التحقيق في Sales Targets

Production يحتوي فعليًا على:

- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

والـRPCs:

- `sales_target_engine_gateway`
- `sales_target_engine_atomic`
- `sales_target_dashboard_atomic`

والـMother UI الحالي يحتوي بالفعل على `RW_SalesTargetsMain`، وتشمل وظائف الإنشاء والتعديل والاعتماد والإغلاق والمعاينة والترحيل والعكس والنسخ وتفعيل/إيقاف التخصيصات، مع Realtime.

كما أن `sales_target_assignments` يسمح فعليًا بتغيير `target_amount`, `target_qty`, `target_gross_profit`, `weight`, `active` لكل خطة وتخصيص.

**النتيجة:** لا توجد جراحة مطلوبة في Sales Targets الحالية لإثبات أنها "ثابتة"؛ العقد الديناميكي موجود بالفعل. لا يجوز إعادة إصلاحه بلا Defect حالي.

الحالة الحالية للبيانات: لا توجد خطط مستهدفة محفوظة حاليًا (`0`)، وهذا Data State وليس غياب Capability.

## 4. Loyalty — Production Reality

Production يحتوي على:

- `loyalty_programs`
- `loyalty_rewards`
- `loyalty_accounts`
- `loyalty_transactions`

والـlegacy `customers.loyalty_points` لا يحتوي حاليًا على قيم غير صفرية في Production.

`loyalty_engine_atomic(uuid,text,text,jsonb,text)` موجود ويعمل كـSecurity Definer، وPhysical/User access محمي من direct browser table writes.

تم التحقق من أن الحساب الحقيقي هو `loyalty_accounts + loyalty_transactions`، بينما `customers.loyalty_points` Compatibility Cache.

## 5. Loyalty Security Repair — Production

تم تنفيذ:

- إزالة direct `anon/authenticated` grants عن Loyalty tables.
- إزالة policy القديمة `Enable all for authenticated users` من `loyalty_points`.
- إبقاء التنفيذ الجوهري للـRPC عبر `service_role`.
- الحفاظ على Audit Triggers الموجودة على Loyalty tables.

تم التحقق بعد الإصلاح أن `loyalty_points` لا يحتوي أي policy direct access.

## 6. Loyalty Transaction Permission Repair — Production

تم توسيع صلاحية عمليات `EARN_ORDER` و`SYNC_ORDER` لتسمح بقنوات البيع الفعلية الحالية:

`pos`, `telesales`, `orders`, `van-sales`, بالإضافة إلى المديرين/المشرفين والـOwner.

لم يتم توسيع صلاحيات `ADJUST/EXPIRE/REVERSE`؛ ظلت مقصورة على `*` و`general_manager`.

## 7. حادثة تنفيذية أثناء هذه الجلسة

أثناء تعديل صلاحية Loyalty حدث خطأ مؤقت نتج عنه استبدال تعريف `loyalty_engine_atomic` بشكل ناقص.

تم اكتشاف ذلك فورًا عبر Production read-back، ولم يُسمح باستمرار المسار بهذه الحالة.

تمت إعادة تعريف الدالة بالكامل من آخر تعريف Production موثق، ثم تم التحقق من:

- التوقيع الصحيح.
- `SECURITY DEFINER`.
- وجود جميع العمليات.
- وجود `RETURN` النهائي وعدم تحولها إلى Stub.
- `service_role` فقط كصلاحية تنفيذ.

ثم تم إجراء إعادة قراءة للتعريف بطول فعلي يقارب 25K character، confirming that the complete engine was restored.

هذه الحادثة مسجلة عمدًا وليست مخفية.

## 8. Loyalty Read Surface

تم إنشاء `loyalty_dashboard_atomic` لفترة قصيرة كـread aggregation layer، ثم تم **حذفه قبل نهاية الجلسة** لعدم ترك Backend capability غير مستخدمة وغير مربوطة بـEdge consumer.

القاعدة التي تم تطبيقها:
`Unused capability = future drift`.

وبالتالي لا يوجد RPC غير مستخدم مطلوب للواجهة الحالية.

## 9. Current Production Counts

بعد التنفيذ:

`loyalty_programs = 0`
`loyalty_rewards = 0`
`loyalty_accounts = 0`
`loyalty_transactions = 0`
`sales_target_plans = 0`
`sales_target_assignments = 0`
`sales_target_runs = 0`

لم يتم الاحتفاظ بأي Test Data تشغيلية جديدة.

## 10. Current Mother UI Gap — Proven

البحث الكامل في Current Source أعاد:

- `loyalty` = غير موجود قبل الجراحة.
- `loyalty_points` = غير موجود.
- Sales Targets موجودة فعليًا.

إذًا الـOpen gap الحقيقي هو **Mother UI Loyalty Integration**، وليس إعادة بناء Sales Targets.

## 11. Exact Current Anchors for Owner Surgical Patch

### A — Sales navigation

**Current source line:** 1144 تقريبًا؛ السطر الكامل الحالي هو:

```text
{ icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'quotes', label: 'عروض الأسعار' },{ view: 'price-lists', label: 'قوائم الأسعار' },{ view: 'promotions', label: 'العروض والخصومات' }, { view: 'sales-targets', label: 'أهداف المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] }, { view: 'runsheets', label: 'الرانشيتات' }, { view: 'sales-returns', label: 'إدارة مرتجعات المبيعات' }] },
```

ابحث عن النص الكامل أعلاه، ثم استبدل **هذا السطر الكامل فقط** بـ:

```javascript
{ icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'quotes', label: 'عروض الأسعار' },{ view: 'price-lists', label: 'قوائم الأسعار' },{ view: 'promotions', label: 'العروض والخصومات' }, { view: 'sales-targets', label: 'أهداف المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] }, { view: 'loyalty', label: 'الولاء والمكافآت', perm: ['sales_manager','sales_supervisor','general_manager','reports','customers','pos','telesales','orders','van-sales'] }, { view: 'runsheets', label: 'الرانشيتات' }, { view: 'sales-returns', label: 'إدارة مرتجعات المبيعات' }] },
```

### B — Permission map

Current `RW_Views.render` permission map is at approximately lines 38932–38974.

ابحث عن السطرين الكاملين:

```text
'finance': 'finance',
'reports-dashboard': 'reports',
```

احذف **السطر الأول فقط** ثم أضف قبله:

```javascript
'loyalty': 'customers',
```

لتصبح المجموعة:

```javascript
'finance': 'finance',
'loyalty': 'customers',
'reports-dashboard': 'reports',
```

### C — Routing

**Current source line 39071 تقريبًا.**

ابحث عن السطر الكامل:

```javascript
if (view === 'sales-targets') { RW_SalesTargetsMain.render(); return; }
```

وأضف **فوقه مباشرة**:

```javascript
if (view === 'loyalty') { RW_LoyaltyMain.render(); return; }
```

النتيجة:

```javascript
if (view === 'sales-returns') { RW_SalesReturnsManagement.render(); return; }
if (view === 'loyalty') { RW_LoyaltyMain.render(); return; }
if (view === 'sales-targets') { RW_SalesTargetsMain.render(); return; }
```

### D — Complete Loyalty UI module

**Current source anchor:** السطر `window.RW_SalesTargetsMain = RW_SalesTargetsMain;` عند السطر 1986.

ابحث عن **السطر الكامل**:

```javascript
window.RW_SalesTargetsMain = RW_SalesTargetsMain;
```

أضف **فوقه مباشرة** الكتلة الكاملة التالية، ولا تحذف `RW_SalesTargetsMain` نفسه:

```javascript
var RW_LoyaltyMain = (function(){
    var endpoint = function(){ return RW_SUPABASE_URL + '/functions/v1/loyalty-engine'; };
    var channel = null;
    var selectedCustomer = null;
    var currentPrograms = [];
    var currentRewards = [];

    function esc(v){
        return String(v == null ? '' : v).replace(/[&<>\"']/g,function(c){
            return {'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',"'":'&#39;'}[c];
        });
    }
    function fmt(v){ return Number(v || 0).toLocaleString('ar-EG'); }
    function uid(){ return window.crypto && crypto.randomUUID ? crypto.randomUUID() : String(Date.now())+'-'+Math.random(); }
    function perms(){ return RW_STATE && Array.isArray(RW_STATE.permissions) ? RW_STATE.permissions : []; }
    function has(p){ return perms().indexOf('*') >= 0 || perms().indexOf(p) >= 0; }
    function canConfig(){ return has('sales_manager') || has('general_manager') || has('*'); }
    function canTxn(){ return has('sales_manager') || has('sales_supervisor') || has('general_manager') || has('pos') || has('telesales') || has('orders') || has('van-sales') || has('*'); }
    function canRead(){ return canTxn() || has('reports') || has('customers'); }

    async function call(operation,payload,operationId){
        var ses = await supabase.auth.getSession();
        var token = ses && ses.data && ses.data.session ? ses.data.session.access_token : null;
        if(!token) throw new Error('انتهت الجلسة');
        var body = { operation: operation, payload: payload || {} };
        if(operationId) body.operation_id = operationId;
        var res = await fetch(endpoint(),{
            method:'POST',
            headers:{'Content-Type':'application/json','Authorization':'Bearer '+token},
            body:JSON.stringify(body)
        });
        var j = await res.json().catch(function(){return {};});
        if(!res.ok || !j || j.success === false) throw new Error((j && (j.msg || j.error)) || 'فشل تنفيذ عملية الولاء');
        return j;
    }

    async function loadPrograms(){
        var j = await call('LIST_PROGRAMS',{});
        currentPrograms = j.programs || [];
        return currentPrograms;
    }
    async function loadRewards(programId){
        var j = await call('LIST_REWARDS',{program_id:programId || null});
        currentRewards = j.rewards || [];
        return currentRewards;
    }
    async function loadCustomer(customerId){
        selectedCustomer = customerId || null;
        if(!selectedCustomer) return {account:null,transactions:[]};
        return await call('GET_ACCOUNT',{customer_id:selectedCustomer});
    }
    async function loadTransactions(customerId){
        if(!customerId) return {account:null,transactions:[]};
        return await call('LIST_TRANSACTIONS',{customer_id:customerId});
    }

    function render(){
        if(!canRead()){
            safeHTML(byId('rw-page-container'),'<div class="rw-card text-center py-16"><div class="text-5xl mb-4">🔒</div><h2 class="font-black text-xl">غير مصرح</h2><p class="text-gray-500 mt-2">ليس لديك صلاحية الوصول إلى الولاء</p></div>');
            return;
        }
        var c = byId('rw-page-container'); if(!c) return;
        safeHTML(c,''+ 
          '<div class="space-y-6">'+
          '<div class="rw-card">'+
            '<div class="flex flex-wrap items-center justify-between gap-3 mb-5">'+
              '<div><h2 class="rw-card-title"><i class="fa-solid fa-gift ml-2 text-indigo-600"></i>الولاء والمكافآت</h2><p class="text-sm text-gray-500 mt-1">إدارة البرنامج، المكافآت، وأرصدة العملاء من نفس محرك المعاملات.</p></div>'+
              (canConfig()?'<button class="rw-btn-primary" onclick="RW_LoyaltyMain.newProgram()"><i class="fa-solid fa-plus ml-1"></i> برنامج جديد</button>':'')+
            '</div>'+
            '<div id="rw-loyalty-program-summary"></div>'+
          '</div>'+
          '<div class="rw-card">'+
            '<div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4">'+
              '<select id="rw-loyalty-customer" class="border rounded-xl p-3 font-bold"><option value="">اختر العميل</option></select>'+
              '<button class="px-4 py-3 rounded-xl bg-slate-100 font-black" onclick="RW_LoyaltyMain.openCustomer()">عرض الحساب</button>'+
              (canTxn()?'<button class="px-4 py-3 rounded-xl bg-emerald-50 text-emerald-700 font-black" onclick="RW_LoyaltyMain.earnSelected()">إضافة نقاط من الطلب</button>':'')+
            '</div>'+
            '<div id="rw-loyalty-customer-panel"></div>'+
          '</div>'+
          '<div class="rw-card" id="rw-loyalty-config-panel"></div>'+
          '</div>');
        loadPrograms().then(function(){ renderProgramSummary(); }).catch(function(e){ showToast(e.message,'error'); });
        loadCustomerOptions();
        renderConfig();
        subscribeRealtime();
    }

    function loadCustomerOptions(){
        var s = byId('rw-loyalty-customer'); if(!s) return;
        var list = RW_STATE.data.customers || [];
        var html = '<option value="">اختر العميل</option>';
        for(var i=0;i<list.length;i++){
            var x=list[i]||{};
            html += '<option value="'+esc(x.id)+'">'+esc(x.customer_code||'')+' — '+esc(x.name||x.customer_name||x.customer_code||'')+'</option>';
        }
        safeHTML(s,html);
    }

    function renderProgramSummary(){
        var out = byId('rw-loyalty-program-summary'); if(!out) return;
        var active = currentPrograms.find(function(x){return x.status==='Active';});
        var html = '<div class="grid grid-cols-1 md:grid-cols-4 gap-3">';
        html += '<div class="p-4 rounded-2xl bg-slate-50"><div class="text-xs text-gray-500">البرنامج</div><div class="font-black mt-1">'+esc(active ? active.name : 'لا يوجد برنامج نشط')+'</div></div>';
        html += '<div class="p-4 rounded-2xl bg-slate-50"><div class="text-xs text-gray-500">عدد البرامج</div><div class="font-black mt-1">'+fmt(currentPrograms.length)+'</div></div>';
        html += '<div class="p-4 rounded-2xl bg-slate-50"><div class="text-xs text-gray-500">نسبة الكسب</div><div class="font-black mt-1">'+(active ? fmt(active.earn_points)+' نقطة / '+fmt(active.earn_amount)+' جنيه':'—')+'</div></div>';
        html += '<div class="p-4 rounded-2xl bg-slate-50"><div class="text-xs text-gray-500">الحد الأدنى للاستبدال</div><div class="font-black mt-1">'+(active ? fmt(active.minimum_redeem_points)+' نقطة':'—')+'</div></div>';
        html += '</div>';
        if(!active) html += '<div class="mt-4 p-4 rounded-2xl bg-amber-50 text-amber-800 font-bold">لا يوجد برنامج Active حاليًا. المحرك جاهز، لكن البرنامج التجاري يجب اعتماده من الإدارة قبل بدء الكسب والاستبدال.</div>';
        if(currentPrograms.length){
            html += '<div class="mt-4 overflow-x-auto"><table class="w-full text-sm"><thead><tr class="border-b"><th class="text-right p-2">الكود</th><th class="text-right p-2">الاسم</th><th class="text-right p-2">الحالة</th><th class="text-right p-2">الأولوية</th></tr></thead><tbody>';
            for(var i=0;i<currentPrograms.length;i++){
                var p=currentPrograms[i]; html += '<tr class="border-b"><td class="p-2">'+esc(p.program_code)+'</td><td class="p-2 font-bold">'+esc(p.name)+'</td><td class="p-2">'+esc(p.status)+'</td><td class="p-2">'+fmt(p.priority)+'</td></tr>';
            }
            html += '</tbody></table></div>';
        }
        safeHTML(out,html);
    }

    function renderConfig(){
        var out=byId('rw-loyalty-config-panel'); if(!out) return;
        if(!canConfig()){ safeHTML(out,''); return; }
        safeHTML(out,'<div class="flex items-center justify-between mb-4"><h3 class="font-black text-lg">إعدادات المكافآت</h3><button class="text-indigo-600 font-bold" onclick="RW_LoyaltyMain.newReward()">إضافة مكافأة</button></div><div id="rw-loyalty-rewards-grid" class="grid grid-cols-1 md:grid-cols-2 gap-3"><div class="text-gray-400">جاري التحميل...</div></div>');
        var active=currentPrograms.find(function(x){return x.status==='Active';});
        if(active) loadRewards(active.id).then(renderRewards).catch(function(e){showToast(e.message,'error');});
    }
    function renderRewards(){
        var out=byId('rw-loyalty-rewards-grid'); if(!out) return;
        if(!currentRewards.length){safeHTML(out,'<div class="col-span-full text-gray-400 p-4 bg-slate-50 rounded-xl">لا توجد مكافآت في البرنامج النشط.</div>');return;}
        var html='';
        for(var i=0;i<currentRewards.length;i++){
            var r=currentRewards[i];
            html += '<div class="p-4 border rounded-2xl"><div class="flex justify-between gap-3"><div><div class="font-black">'+esc(r.name)+'</div><div class="text-xs text-gray-500 mt-1">'+esc(r.reward_code)+' — '+esc(r.reward_type)+'</div></div><span class="font-black">'+fmt(r.points_cost)+' نقطة</span></div><div class="text-sm mt-3">قيمة المكافأة: <b>'+fmt(r.reward_value)+'</b> | '+(r.active?'نشطة':'موقوفة')+'</div></div>';
        }
        safeHTML(out,html);
    }

    async function openCustomer(){
        var s=byId('rw-loyalty-customer'); if(!s || !s.value){showToast('اختر العميل أولًا','warning');return;}
        selectedCustomer=s.value; showLoader('جاري تحميل حساب الولاء...');
        try{ var j=await loadCustomer(selectedCustomer); var tx=await loadTransactions(selectedCustomer); renderCustomerPanel(j.account,tx.transactions||[]); }
        catch(e){showToast(e.message,'error');}finally{hideLoader();}
    }
    function renderCustomerPanel(account,txs){
        var out=byId('rw-loyalty-customer-panel');if(!out)return;
        if(!account){safeHTML(out,'<div class="p-5 bg-slate-50 rounded-2xl text-gray-500">لا يوجد حساب ولاء للعميل حتى الآن. سيُنشأ تلقائيًا عند أول معاملة صالحة.</div>');return;}
        var html='<div class="grid grid-cols-1 md:grid-cols-4 gap-3 mb-4">';
        html+='<div class="p-4 rounded-2xl bg-indigo-50"><div class="text-xs">الرصيد</div><div class="text-2xl font-black">'+fmt(account.points_balance)+'</div></div>';
        html+='<div class="p-4 rounded-2xl bg-emerald-50"><div class="text-xs">إجمالي المكتسب</div><div class="text-2xl font-black">'+fmt(account.lifetime_earned)+'</div></div>';
        html+='<div class="p-4 rounded-2xl bg-amber-50"><div class="text-xs">إجمالي المستبدل</div><div class="text-2xl font-black">'+fmt(account.lifetime_redeemed)+'</div></div>';
        html+='<div class="p-4 rounded-2xl bg-slate-50"><div class="text-xs">الحالة</div><div class="text-2xl font-black">'+esc(account.status)+'</div></div></div>';
        if(canTxn()) html+='<div class="flex flex-wrap gap-2 mb-4"><button class="px-4 py-2 rounded-xl bg-indigo-600 text-white font-bold" onclick="RW_LoyaltyMain.adjustSelected(10)">إضافة 10 نقاط</button><button class="px-4 py-2 rounded-xl bg-rose-50 text-rose-700 font-bold" onclick="RW_LoyaltyMain.adjustSelected(-10)">خصم 10 نقاط</button></div>';
        html+='<div class="overflow-x-auto"><table class="w-full text-sm"><thead><tr class="border-b"><th class="text-right p-2">التاريخ</th><th class="text-right p-2">النوع</th><th class="text-right p-2">التغيير</th><th class="text-right p-2">قبل</th><th class="text-right p-2">بعد</th><th class="text-right p-2">المرجع</th></tr></thead><tbody>';
        for(var i=0;i<txs.length;i++){var t=txs[i];html+='<tr class="border-b"><td class="p-2">'+esc(t.created_at?new Date(t.created_at).toLocaleString('ar-EG'):'')+'</td><td class="p-2">'+esc(t.transaction_type)+'</td><td class="p-2 font-bold">'+fmt(t.points_delta)+'</td><td class="p-2">'+fmt(t.balance_before)+'</td><td class="p-2">'+fmt(t.balance_after)+'</td><td class="p-2">'+esc(t.reference_id||'')+'</td></tr>';}
        html+='</tbody></table></div>';
        safeHTML(out,html);
    }

    async function newProgram(){
        if(!canConfig()) throw new Error('ليس لديك صلاحية إدارة البرامج');
        var result=await Swal.fire({title:'برنامج ولاء جديد',html:'<input id="ly-code" class="swal2-input" placeholder="كود البرنامج"><input id="ly-name" class="swal2-input" placeholder="اسم البرنامج"><input id="ly-earn-amount" type="number" min="0.01" class="swal2-input" placeholder="كل كم جنيه؟" value="10"><input id="ly-earn-points" type="number" min="1" class="swal2-input" placeholder="عدد النقاط" value="1"><input id="ly-min" type="number" min="1" class="swal2-input" placeholder="الحد الأدنى للاستبدال" value="100"><input id="ly-expiry" type="number" min="1" class="swal2-input" placeholder="أيام الانتهاء (اختياري)">',showCancelButton:true,confirmButtonText:'حفظ',cancelButtonText:'إلغاء',preConfirm:function(){var code=String(document.getElementById('ly-code').value||'').trim();var name=String(document.getElementById('ly-name').value||'').trim();if(!code||!name)return Swal.showValidationMessage('الكود والاسم مطلوبان');return {program_code:code,name:name,status:'Draft',priority:100,earn_amount:Number(document.getElementById('ly-earn-amount').value||10),earn_points:Number(document.getElementById('ly-earn-points').value||1),minimum_redeem_points:Number(document.getElementById('ly-min').value||100),expiry_days:String(document.getElementById('ly-expiry').value||'').trim()};}});
        if(!result.isConfirmed)return;showLoader('جاري حفظ البرنامج...');try{await call('SAVE_PROGRAM',result.value,uid());await loadPrograms();renderProgramSummary();renderConfig();showToast('تم حفظ البرنامج','success');}catch(e){showToast(e.message,'error');}finally{hideLoader();}
    }

    async function newReward(){
        if(!canConfig()) throw new Error('ليس لديك صلاحية إدارة المكافآت');
        var active=currentPrograms.find(function(x){return x.status==='Active';});if(!active)throw new Error('اعتمد برنامجًا نشطًا أولًا');
        var result=await Swal.fire({title:'مكافأة جديدة',html:'<input id="ly-r-code" class="swal2-input" placeholder="كود المكافأة"><input id="ly-r-name" class="swal2-input" placeholder="اسم المكافأة"><input id="ly-r-points" type="number" min="1" class="swal2-input" placeholder="تكلفة النقاط" value="100"><input id="ly-r-value" type="number" min="0" class="swal2-input" placeholder="قيمة المكافأة" value="1">',showCancelButton:true,confirmButtonText:'حفظ',cancelButtonText:'إلغاء',preConfirm:function(){var code=String(document.getElementById('ly-r-code').value||'').trim();var name=String(document.getElementById('ly-r-name').value||'').trim();if(!code||!name)return Swal.showValidationMessage('الكود والاسم مطلوبان');return {program_id:active.id,reward_code:code,name:name,reward_type:'discount',points_cost:Number(document.getElementById('ly-r-points').value||0),reward_value:Number(document.getElementById('ly-r-value').value||0),active:true};}});
        if(!result.isConfirmed)return;showLoader('جاري حفظ المكافأة...');try{await call('SAVE_REWARD',result.value,uid());await loadRewards(active.id);renderRewards();showToast('تم حفظ المكافأة','success');}catch(e){showToast(e.message,'error');}finally{hideLoader();}
    }

    async function adjustSelected(points){
        if(!canTxn() || !selectedCustomer)return;
        showLoader('جاري تعديل النقاط...');try{await call('ADJUST',{customer_id:selectedCustomer,points:points,reason:'تعديل يدوي من النظام الأم',reference_type:'LOYALTY_UI',reference_id:'MANUAL'},uid());await openCustomer();}catch(e){showToast(e.message,'error');}finally{hideLoader();}
    }
    async function earnSelected(){
        showToast('الكسب التلقائي مرتبط بالعملية المفوترة عبر Engine. هذه الشاشة لا تنشئ Earn يدويًا بلا Order ID.','info');
    }
    function subscribeRealtime(){
        if(channel){try{supabase.removeChannel(channel);}catch(e){}}
        channel=supabase.channel('rw-loyalty-main').on('postgres_changes',{event:'*',schema:'public',table:'loyalty_programs'},function(p){if(p.new&&p.new.company_id!==RW_STATE.app.company.id)return;render();}).on('postgres_changes',{event:'*',schema:'public',table:'loyalty_rewards'},function(p){if(p.new&&p.new.company_id!==RW_STATE.app.company.id)return;render();}).on('postgres_changes',{event:'*',schema:'public',table:'loyalty_accounts'},function(p){if(p.new&&p.new.company_id!==RW_STATE.app.company.id)return; if(selectedCustomer) openCustomer(); }).on('postgres_changes',{event:'*',schema:'public',table:'loyalty_transactions'},function(p){if(p.new&&p.new.company_id!==RW_STATE.app.company.id)return; if(selectedCustomer) openCustomer(); }).subscribe();
    }

    return {render:render,newProgram:newProgram,newReward:newReward,openCustomer:openCustomer,adjustSelected:adjustSelected,earnSelected:earnSelected};
})();
window.RW_LoyaltyMain = RW_LoyaltyMain;
```

## 12. لماذا لا توجد جراحة Sales Targets

الـSales Target UI الحالي عنده بالفعل `savePlan`, `selectPlan`, `approvePlan`, `cancelPlan`, `closePlan`, `clonePlan`, `saveAssignment`, `setAssignmentActive`, `postRun`, `approveRun`, `reverseRun`، والـRealtime، لذلك إعادة بناء الوحدة ستكون Regression وليست Completion.

المطلوب في هذه الجلسة هو جعل Loyalty مكتملة في نفس Main؛ لا إعادة لمس ما ثبت أنه صحيح.

## 13. Production Verification

تم التحقق من:

- `loyalty_engine_atomic` ما زال كاملًا وليس Stub.
- `SECURITY DEFINER = true`.
- `service_role` فقط لديه EXECUTE.
- direct loyalty table access للـanon/authenticated مغلق.
- legacy `loyalty_points` direct policy مغلقة.
- لا توجد Loyalty test rows متبقية.
- لا توجد Sales Target test rows متبقية.

## 14. ما لم يتم ادعاؤه

لا توجد في هذه البيئة قدرة على تشغيل متصفح المستخدم نفسه أو إثبات incognito Browser Console/Network E2E للنسخة التي سيعدلها المالك بعد الدمج.

لذلك:

`Browser E2E = OPEN`

وليس `PASS`.

كذلك لم يتم تعديل `main.html` مباشرة في Git لأن ذلك ممنوع حسب توزيع المسؤوليات.

## 15. FINAL SELF-AUDIT

### ما ثبت

- Current HEAD وparent والـblob الحاليون.
- قراءة المصدر الحالي حتى EOF.
- وجود Sales Target dynamic capability.
- وجود Loyalty transaction engine فعلي في Production.
- عدم وجود Loyalty UI في current mother.
- Production security hardening تم تطبيقه.
- Engine تم استرجاعه والتحقق من اكتماله بعد حادثة التنفيذ.
- لا توجد بيانات اختبار تشغيلية متبقية.

### ما تم إصلاحه

- Loyalty direct access.
- Loyalty transaction permissions لقنوات البيع.
- إزالة Dashboard RPC غير المستخدم حتى لا يخلق drift.
- إنشاء `forensic_main_assembly.yml` pointing to the actual published mother.

### ما لم يثبت

- Browser Console/Network بعد دمج المالك للجراحة.
- Invoice-to-Loyalty automatic E2E في browser live path.
- Return-to-Loyalty reversal business rule؛ لم تُخترع قاعدة جديدة لأن engine الحالي يمنع negative balance.

## 16. نقطة الاستكمال للمساعد القادم

1. أعد Refresh لكل Current sources ولا تثق بهذا التقرير كحالة.
2. اقرأ `CURRENT_STATE.md` ثم طابق HEAD/parent/blob وProduction/deployments.
3. أعد فتح `companies/company-1/main.html` الحالي وتحقق من نفس anchors؛ لا تستخدم أرقام هذا التقرير إن تغير الـblob.
4. نفّذ فقط جراحات Loyalty A/B/C/D على النسخة الحالية للمالك.
5. بعد دمج المالك شغّل Browser E2E ثم Console/Network وراقب `loyalty-engine` وProduction DB.
6. بعد نجاح Browser E2E اربط `EARN_ORDER` داخل دورة الفاتورة الرسمية باستخدام نفس `operation_id` الموجود في `orders.operation_id`؛ لا تستخدم Earn يدويًا من شاشة Loyalty بدون Order ID.
7. بالنسبة للمرتجعات، لا تخصم نقاطًا تلقائيًا إلا بعد إثبات Business Rule يمنع negative balance أو يعرّف سياسة debt/rollback رسمية.
8. لا تعيد إصلاح Sales Targets ما لم يظهر Defect حالي مثبت في Production.

## 17. STATUS

```text
Sales Targets dynamic capability       = PRODUCTION VERIFIED / NO NEW PATCH REQUIRED
Loyalty Transaction Engine             = PRODUCTION VERIFIED / HARDENED
Loyalty Mother UI                      = OWNER SURGICAL PATCH READY
Browser E2E                             = OPEN
Invoice Loyalty integration             = OPEN
Return Loyalty reversal policy          = OPEN BY BUSINESS CONTRACT
Global Gold/Diamond Main completion     = NOT CLAIMED
```

## 18. Required owner answer

بعد أن يطبق المالك الجراحة الأربع على `main.html` ويعيد نشر النسخة، لا نحتاج إعادة بناء أي أجزاء Historical؛ نبدأ مباشرة من Browser E2E على الـpublished mother فقط.
