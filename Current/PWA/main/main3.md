/* RAWAEA ERP — MAIN3 GOVERNED RECONSTRUCTION
   Scope: Customers / Suppliers / Branches / Settings / Users
   Tenant authority: RW_ShellContext.getCompanyId()
   Physical Stock authority: NOT present in this fragment.
*/
(function () {
  'use strict';

  if (!window.RW_ShellContext || typeof window.RW_ShellContext.getCompanyId !== 'function') {
    throw new Error('MAIN3_REQUIRES_RW_SHELL_CONTEXT');
  }

  const $ = (id) => document.getElementById(id);
  const companyId = () => window.RW_ShellContext.getCompanyId();
  const E = (v) => String(v ?? '').replace(/[&<>"']/g, (m) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
  const A = E;
  const val = (id) => ($(id)?.value ?? '').trim();

  function notifyError(err) {
    const text = String(err?.message || err || 'حدث خطأ غير متوقع');
    if (typeof showToast === 'function') showToast(text, 'error');
    else console.error(text);
  }

  async function getToken() {
    const r = await supabase.auth.getSession();
    const token = r?.data?.session?.access_token;
    if (!token) throw new Error('انتهت الجلسة');
    return token;
  }

  async function edgeCall(name, body) {
    const token = await getToken();
    const r = await fetch(RW_SUPABASE_URL + '/functions/v1/' + name, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
      },
      body: JSON.stringify(body || {})
    });
    const j = await r.json().catch(() => ({}));
    if (!r.ok || j.success === false) {
      throw new Error(j.error || j.msg || ('فشل ' + name));
    }
    return j;
  }

  function modal(html, width) {
    Swal.fire({
      html,
      width: width || 900,
      showConfirmButton: false,
      showCancelButton: false,
      customClass: { popup: '!bg-transparent !shadow-none !p-0' }
    });
  }

  function searchRows(rows, query, keys) {
    const q = String(query || '').toLowerCase().trim();
    if (!q) return rows.slice();
    return rows.filter((row) => keys.some((key) => String(row?.[key] ?? '').toLowerCase().includes(q)));
  }

  /* ---------------- Customers ---------------- */
  const RW_Customers = (function () {
    let data = [];
    let sortField = 'customer_code';
    let sortAsc = true;

    const FIELD_SPEC = [
      ['cust-name', 'اسم العميل', 'name', 'text'],
      ['cust-phone', 'الهاتف', 'phone', 'text'],
      ['cust-area', 'المنطقة', 'area', 'text'],
      ['cust-location', 'العنوان', 'location', 'text'],
      ['cust-debt', 'الرصيد', 'debt', 'number'],
      ['cust-contact', 'مسؤول التواصل', 'contact_person', 'text'],
      ['cust-notes', 'ملاحظات', 'notes', 'textarea']
    ];

    async function load() {
      data = await RW_Data.loadCustomers();
      return data;
    }

    function renderTable(rows) {
      const wrapper = $('cust-table-wrapper');
      if (!wrapper) return;
      if (!rows.length) {
        safeHTML(wrapper, '<div class="text-center p-10">لا يوجد عملاء</div>');
        return;
      }

      const cols = [
        ['customer_code','الكود'],
        ['name','الاسم'],
        ['phone','الهاتف'],
        ['area','المنطقة'],
        ['contact_person','مسؤول التواصل'],
        ['visit_day','يوم الزيارة'],
        ['debt','الرصيد']
      ];

      const sorted = rows.slice().sort((a, b) => {
        let av = a?.[sortField] ?? '';
        let bv = b?.[sortField] ?? '';
        if (sortField === 'debt') {
          av = Number(av) || 0;
          bv = Number(bv) || 0;
        } else {
          av = String(av).toLowerCase();
          bv = String(bv).toLowerCase();
        }
        return (av < bv ? -1 : av > bv ? 1 : 0) * (sortAsc ? 1 : -1);
      });

      safeHTML(wrapper,
        '<table class="w-full text-sm"><thead><tr>' +
        cols.map(c => '<th class="p-3 cursor-pointer" data-f="' + A(c[0]) + '" onclick="RW_Customers._sort(this.dataset.f)">' + E(c[1]) + '</th>').join('') +
        '</tr></thead><tbody id="cust-tbody"></tbody></table><div id="cust-tbody-controls"></div>'
      );

      RW_Table.paginate('cust-tbody', sorted, 1, 50, (c) =>
        '<tr class="cursor-pointer hover:bg-gray-50" data-code="' + A(c.customer_code) + '" onclick="RW_Customers._openModal(this.dataset.code)">' +
        '<td class="p-3">' + E(c.customer_code) + '</td>' +
        '<td class="p-3 font-semibold">' + E(c.name) + '</td>' +
        '<td class="p-3">' + E(c.phone) + '</td>' +
        '<td class="p-3">' + E(c.area) + '</td>' +
        '<td class="p-3">' + E(c.contact_person) + '</td>' +
        '<td class="p-3">' + E(c.visit_day) + '</td>' +
        '<td class="p-3 font-bold">' + (Number(c.debt) || 0).toLocaleString() + '</td>' +
        '</tr>'
      );
    }

    function _sort(field) {
      if (sortField === field) sortAsc = !sortAsc;
      else { sortField = field; sortAsc = true; }
      renderTable(data);
    }

    function _openModal(code) {
      const current = code ? data.find(x => x.customer_code === code) : null;
      const edit = !!current;
      const specs = FIELD_SPEC;
      const fields = specs.map((f) =>
        f[3] === 'textarea'
          ? '<textarea id="' + f[0] + '" class="p-2.5 border rounded-lg w-full" placeholder="' + E(f[1]) + '">' + E(current?.[f[2]] ?? '') + '</textarea>'
          : '<input id="' + f[0] + '" type="' + f[3] + '" class="p-2.5 border rounded-lg w-full" placeholder="' + E(f[1]) + '" value="' + A(current?.[f[2]] ?? '') + '">'
      ).join('');

      modal(
        '<div class="p-6" dir="rtl">' +
          '<h3 class="text-xl font-bold mb-4">' + (edit ? 'تعديل العميل' : 'إضافة عميل جديد') + '</h3>' +
          '<div class="grid md:grid-cols-2 gap-3">' + fields + '</div>' +
          '<div class="grid md:grid-cols-3 gap-3 mt-3">' +
            '<select id="cust-type" class="p-2.5 border rounded-lg">' +
              '<option value="عادي">عادي</option><option value="جملة">جملة</option><option value="VIP">VIP</option>' +
            '</select>' +
            '<select id="cust-payment" class="p-2.5 border rounded-lg"><option value="نقدي">نقدي</option><option value="أجل">أجل</option></select>' +
            '<select id="cust-visit" class="p-2.5 border rounded-lg"><option value="">اختر يوم الزيارة</option>' +
              ['السبت','الأحد','الإثنين','الثلاثاء','الأربعاء','الخميس'].map(d => '<option value="' + A(d) + '">' + E(d) + '</option>').join('') +
            '</select>' +
          '</div>' +
          '<div class="flex justify-end gap-3 mt-4 border-t pt-4">' +
            (edit ? '<button id="btn-delete-cust" class="bg-red-600 text-white px-5 py-2 rounded-xl mr-auto">حذف</button>' : '') +
            '<button onclick="Swal.close()" class="border px-5 py-2 rounded-xl">إلغاء</button>' +
            '<button id="btn-save-cust" class="bg-emerald-600 text-white px-6 py-2 rounded-xl">حفظ</button>' +
          '</div>' +
        '</div>'
      );

      if (edit) {
        $('cust-type').value = current.customer_type || 'عادي';
        $('cust-payment').value = current.payment_type || 'نقدي';
        $('cust-visit').value = current.visit_day || '';
      }
      $('btn-save-cust').onclick = () => _handleSave(current, edit);
      if (edit) $('btn-delete-cust').onclick = () => _handleDelete(current);
    }

    async function _handleSave(current, edit) {
      const payload = {
        name: val('cust-name'),
        phone: val('cust-phone'),
        area: val('cust-area'),
        location: val('cust-location'),
        debt: Number(val('cust-debt')) || 0,
        contact_person: val('cust-contact'),
        notes: val('cust-notes'),
        customer_type: val('cust-type'),
        payment_type: val('cust-payment'),
        visit_day: val('cust-visit')
      };
      if (!payload.name) return notifyError('اسم العميل مطلوب');
      showLoader('جاري الحفظ...');
      try {
        const j = await edgeCall('save-customer', {
          customer: payload,
          isEdit: !!edit,
          customer_code: current?.customer_code || null
        });
        hideLoader();
        if (window.RW_Audit_log) RW_Audit_log(edit ? 'update' : 'create', 'customers', j.customer_code || current?.customer_code || '', edit ? current : null, payload);
        Swal.close();
        showToast(edit ? 'تم التعديل' : 'تمت الإضافة', 'success');
        renderTable(await load());
      } catch (e) { hideLoader(); notifyError(e); }
    }

    async function _handleDelete(current) {
      const confirm = await Swal.fire({title:'تأكيد الحذف',text:'حذف هذا العميل؟',icon:'warning',showCancelButton:true,confirmButtonText:'حذف',cancelButtonText:'إلغاء'});
      if (!confirm.isConfirmed) return;
      showLoader('جاري الحذف...');
      try {
        await edgeCall('delete-customer', {customer_code: current.customer_code});
        hideLoader();
        Swal.close();
        showToast('تم الحذف','success');
        renderTable(await load());
      } catch (e) { hideLoader(); notifyError(e); }
    }

    async function render() {
      const container = $('rw-page-container');
      if (!container) return;
      safeText($('rw-header-title'),'العملاء');
      safeHTML(container,
        '<div class="p-4"><div class="flex justify-between mb-4"><h2 class="text-xl font-bold">العملاء</h2><button id="btn-add-cust" class="bg-emerald-600 text-white px-4 py-2 rounded-xl">+ عميل جديد</button></div>' +
        '<input id="cust-search" class="w-full p-3 border rounded-xl mb-4" placeholder="بحث..."><div id="cust-table-wrapper"></div></div>'
      );
      renderTable(await load());
      $('cust-search').oninput = () => renderTable(searchRows(data, $('cust-search').value, ['name','customer_code','phone']));
      $('btn-add-cust').onclick = () => _openModal(null);
    }

    return {render,_sort,_openModal,_handleSave,_handleDelete};
  })();
  window.RW_Customers = RW_Customers;

  /* ---------------- Suppliers ---------------- */
  const RW_Suppliers = (function () {
    let data = [];
    let sortField = 'supplier_code';
    let sortAsc = true;
    const SPEC = [
      ['supp-name','اسم المورد','name','text'],
      ['supp-phone','الهاتف','phone','text'],
      ['supp-area','المنطقة','area','text'],
      ['supp-address','العنوان','address','text'],
      ['supp-contact','جهة الاتصال','contact_person','text'],
      ['supp-rep','مسؤول المشتريات','purchase_rep','text'],
      ['supp-balance','الرصيد','accounts_payable','number'],
      ['supp-notes','ملاحظات','notes','textarea']
    ];

    async function load() {
      const r = await supabase.from('suppliers').select('*').eq('company_id', companyId()).order('supplier_code');
      if (r.error) throw r.error;
      data = r.data || [];
      return data;
    }

    function renderTable(rows) {
      const wrapper = $('supp-table-wrapper');
      if (!wrapper) return;
      if (!rows.length) return safeHTML(wrapper,'<div class="text-center p-10">لا يوجد موردين</div>');
      const cols = [['supplier_code','الكود'],['name','الاسم'],['phone','الهاتف'],['area','المنطقة'],['contact_person','جهة الاتصال'],['accounts_payable','الرصيد']];
      safeHTML(wrapper,'<table class="w-full text-sm"><thead><tr>' +
        cols.map(c => '<th class="p-3" data-f="' + A(c[0]) + '" onclick="RW_Suppliers._sort(this.dataset.f)">' + E(c[1]) + '</th>').join('') +
        '</tr></thead><tbody id="supp-tbody"></tbody></table><div id="supp-tbody-controls"></div>');
      const sorted = rows.slice().sort((a,b) => {
        let x = sortField === 'accounts_payable' ? Number(a[sortField]) || 0 : String(a[sortField] || '').toLowerCase();
        let y = sortField === 'accounts_payable' ? Number(b[sortField]) || 0 : String(b[sortField] || '').toLowerCase();
        return (x < y ? -1 : x > y ? 1 : 0) * (sortAsc ? 1 : -1);
      });
      RW_Table.paginate('supp-tbody', sorted, 1, 50, s =>
        '<tr class="cursor-pointer" data-code="' + A(s.supplier_code) + '" onclick="RW_Suppliers._openModal(this.dataset.code)">' +
        '<td class="p-3">' + E(s.supplier_code) + '</td><td class="p-3">' + E(s.name) + '</td><td class="p-3">' + E(s.phone) + '</td><td class="p-3">' + E(s.area) + '</td><td class="p-3">' + E(s.contact_person) + '</td><td class="p-3">' + (Number(s.accounts_payable) || 0).toLocaleString() + '</td></tr>'
      );
    }

    function _sort(field) {
      if (sortField === field) sortAsc = !sortAsc;
      else {sortField = field; sortAsc = true;}
      renderTable(data);
    }

    function openForm(current) {
      const edit = !!current;
      const inputs = SPEC.map(f =>
        f[3] === 'textarea'
          ? '<textarea id="' + f[0] + '" class="p-2.5 border rounded-lg w-full" placeholder="' + E(f[1]) + '">' + E(current?.[f[2]] ?? '') + '</textarea>'
          : '<input id="' + f[0] + '" type="' + f[3] + '" class="p-2.5 border rounded-lg w-full" placeholder="' + E(f[1]) + '" value="' + A(current?.[f[2]] ?? '') + '">'
      ).join('');
      modal('<div class="p-6" dir="rtl"><h3 class="text-xl font-bold mb-4">' + (edit?'تعديل المورد':'إضافة مورد جديد') + '</h3>' +
        '<div class="grid md:grid-cols-2 gap-3">' + inputs + '</div>' +
        '<div class="grid md:grid-cols-2 gap-3 mt-3"><select id="supp-type" class="p-2.5 border rounded-lg"><option value="مورد عام">مورد عام</option><option value="مصنع">مصنع</option><option value="مورد خارجي">مورد خارجي</option></select>' +
        '<select id="supp-payment" class="p-2.5 border rounded-lg"><option value="نقدي">نقدي</option><option value="أجل">أجل</option></select></div>' +
        '<div class="flex justify-end gap-3 mt-4 border-t pt-4">' + (edit?'<button id="btn-delete-supp" class="bg-red-600 text-white px-5 py-2 rounded-xl mr-auto">حذف</button>':'') +
        '<button onclick="Swal.close()" class="border px-5 py-2 rounded-xl">إلغاء</button><button id="btn-save-supp" class="bg-orange-600 text-white px-6 py-2 rounded-xl">حفظ</button></div></div>');
      if (edit) {
        $('supp-type').value = current.supplier_type || 'مورد عام';
        $('supp-payment').value = current.payment_type || 'نقدي';
      }
      $('btn-save-supp').onclick = () => _handleSave(current, edit);
      if (edit) $('btn-delete-supp').onclick = () => _handleDelete(current);
    }

    function _openModal(code) { openForm(code ? data.find(x => x.supplier_code === code) : null); }

    async function _handleSave(current, edit) {
      const payload = {
        name: val('supp-name'), phone: val('supp-phone'), area: val('supp-area'),
        address: val('supp-address'), contact_person: val('supp-contact'),
        purchase_rep: val('supp-rep'), accounts_payable: Number(val('supp-balance')) || 0,
        notes: val('supp-notes'), supplier_type: val('supp-type'), payment_type: val('supp-payment')
      };
      if (!payload.name) return notifyError('اسم المورد مطلوب');
      showLoader('جاري الحفظ...');
      try {
        const j = await edgeCall('save-supplier', {supplier:payload,isEdit:!!edit,supplier_code:current?.supplier_code||null});
        hideLoader();
        if (window.RW_Audit_log) RW_Audit_log(edit?'update':'create','suppliers',j.supplier_code||current?.supplier_code||'',edit?current:null,payload);
        Swal.close(); showToast(edit?'تم التعديل':'تمت الإضافة','success'); renderTable(await load());
      } catch(e){hideLoader();notifyError(e);}
    }

    async function _handleDelete(current) {
      const confirm = await Swal.fire({title:'تأكيد الحذف',text:'حذف هذا المورد؟',icon:'warning',showCancelButton:true,confirmButtonText:'حذف',cancelButtonText:'إلغاء'});
      if (!confirm.isConfirmed) return;
      showLoader('جاري الحذف...');
      try { await edgeCall('delete-supplier',{supplier_code:current.supplier_code}); hideLoader(); Swal.close(); showToast('تم الحذف','success'); renderTable(await load()); }
      catch(e){hideLoader();notifyError(e);}
    }

    async function render() {
      const c = $('rw-page-container'); if(!c) return;
      safeText($('rw-header-title'),'الموردين');
      safeHTML(c,'<div class="p-4"><div class="flex justify-between mb-4"><h2 class="text-xl font-bold">الموردين</h2><button id="btn-add-supp" class="bg-orange-600 text-white px-4 py-2 rounded-xl">+ مورد جديد</button></div><input id="supp-search" class="w-full p-3 border rounded-xl mb-4" placeholder="بحث..."><div id="supp-table-wrapper"></div></div>');
      renderTable(await load());
      $('supp-search').oninput=()=>renderTable(searchRows(data,$('supp-search').value,['name','supplier_code','phone']));
      $('btn-add-supp').onclick=()=>_openModal(null);
    }

    return {render,_sort,_openModal,_handleSave,_handleDelete};
  })();
  window.RW_Suppliers = RW_Suppliers;

  /* ---------------- Branches ---------------- */
  const RW_Branches = (function () {
    let data=[];
    async function load(){data=await RW_Data.loadBranches();return data;}
    function renderTable(rows){
      const w=$('branch-table-wrapper'); if(!w)return;
      if(!rows.length)return safeHTML(w,'<div class="text-center p-10">لا توجد فروع</div>');
      safeHTML(w,'<table class="w-full text-sm"><thead><tr><th class="p-3">الكود</th><th class="p-3">الاسم</th><th class="p-3">الموقع</th><th class="p-3">المدير</th><th class="p-3">الهاتف</th><th class="p-3">الحالة</th></tr></thead><tbody>'+
        rows.map(b=>'<tr class="cursor-pointer" data-code="'+A(b.branch_code)+'" onclick="RW_Branches._openModal(this.dataset.code)"><td class="p-3">'+E(b.branch_code)+'</td><td class="p-3">'+E(b.name)+'</td><td class="p-3">'+E(b.location)+'</td><td class="p-3">'+E(b.manager)+'</td><td class="p-3">'+E(b.phone)+'</td><td class="p-3">'+(b.is_active?'🟢':'🔴')+'</td></tr>').join('')+
        '</tbody></table>');
    }
    async function _openModal(code){
      const b=code?data.find(x=>x.branch_code===code):null, edit=!!b;
      modal('<div class="p-6" dir="rtl"><h3 class="text-xl font-bold mb-4">'+(edit?'تعديل الفرع':'إضافة فرع جديد')+'</h3>'+ 
        '<div class="grid md:grid-cols-2 gap-3">'+
        '<input id="branch-name" class="p-2.5 border rounded-lg" placeholder="اسم الفرع *" value="'+A(b?.name||'')+'">'+
        '<input id="branch-location" class="p-2.5 border rounded-lg" placeholder="الموقع / العنوان" value="'+A(b?.location||'')+'">'+
        '<input id="branch-manager" class="p-2.5 border rounded-lg" placeholder="المدير المسؤول" value="'+A(b?.manager||'')+'">'+
        '<input id="branch-phone" class="p-2.5 border rounded-lg" placeholder="رقم الهاتف" value="'+A(b?.phone||'')+'">'+
        '<select id="branch-status" class="p-2.5 border rounded-lg"><option value="active">نشط</option><option value="inactive">غير نشط</option></select></div>'+
        '<div class="flex justify-end gap-3 mt-4 border-t pt-4">'+(edit?'<button id="btn-delete-branch" class="bg-red-600 text-white px-5 py-2 rounded-xl mr-auto">حذف</button>':'')+
        '<button onclick="Swal.close()" class="border px-5 py-2 rounded-xl">إلغاء</button><button id="btn-save-branch" class="bg-indigo-600 text-white px-6 py-2 rounded-xl">حفظ</button></div></div>',800);
      if(edit)$('branch-status').value=b.is_active?'active':'inactive';
      $('btn-save-branch').onclick=async()=>{
        const payload={name:val('branch-name'),location:val('branch-location'),manager:val('branch-manager'),phone:val('branch-phone'),is_active:val('branch-status')==='active'};
        if(!payload.name)return notifyError('اسم الفرع مطلوب');
        showLoader('جاري الحفظ...');try{await edgeCall('save-branch',{branch:payload,isEdit:edit,branch_code:b?.branch_code||null});hideLoader();Swal.close();showToast(edit?'تم التعديل':'تمت الإضافة','success');renderTable(await load())}catch(e){hideLoader();notifyError(e);}
      };
      if(edit)$('btn-delete-branch').onclick=async()=>{
        const confirm=await Swal.fire({title:'تأكيد الحذف',text:'حذف هذا الفرع؟',icon:'warning',showCancelButton:true,confirmButtonText:'حذف',cancelButtonText:'إلغاء'});
        if(!confirm.isConfirmed)return;showLoader('جاري الحذف...');try{await edgeCall('delete-branch',{branch_code:b.branch_code});hideLoader();Swal.close();showToast('تم الحذف','success');renderTable(await load())}catch(e){hideLoader();notifyError(e);}
      };
    }
    async function render(){
      const c=$('rw-page-container');if(!c)return;safeText($('rw-header-title'),'المخازن والفروع');
      safeHTML(c,'<div class="p-4"><div class="flex justify-between mb-4"><h2 class="text-xl font-bold">الفروع والمخازن</h2><button id="btn-add-branch" class="bg-indigo-600 text-white px-4 py-2 rounded-xl">+ إضافة فرع</button></div><input id="branch-search" class="w-full p-3 border rounded-xl mb-4" placeholder="بحث..."><div id="branch-table-wrapper"></div></div>');
      renderTable(await load());$('branch-search').oninput=()=>renderTable(searchRows(data,$('branch-search').value,['name','branch_code','location']));$('btn-add-branch').onclick=()=>_openModal(null);
    }
    return {render,_openModal};
  })();
  window.RW_Branches=RW_Branches;

  /* ---------------- Settings ---------------- */
  const RW_Settings=(function(){
    let current={};
    async function load(){
      const r=await supabase.from('app_settings').select('*').eq('company_id',companyId()).order('created_at',{ascending:true}).order('id',{ascending:true}).limit(1).maybeSingle();
      if(r.error)throw r.error; current=r.data||{}; return current;
    }
    async function render(){
      const c=$('rw-page-container');if(!c)return;safeText($('rw-header-title'),'إعدادات النظام');showLoader('جاري تحميل الإعدادات...');
      try{
        const s=await load();
        safeHTML(c,'<div class="p-4 max-w-3xl mx-auto space-y-6">'+
          '<div class="bg-white rounded-2xl shadow-sm border p-6"><h2 class="text-xl font-bold mb-6">إعدادات الفاتورة والرسوم</h2>'+ 
          '<div class="grid md:grid-cols-2 gap-4">'+
          '<input id="settings-delivery-fee" type="number" class="p-2.5 border rounded-lg" placeholder="رسوم التوصيل" value="'+A(s.delivery_fee??0)+'">'+
          '<input id="settings-min-invoice" type="number" class="p-2.5 border rounded-lg" placeholder="الحد الأدنى للفاتورة" value="'+A(s.min_invoice_amount??0)+'">'+
          '<input id="settings-tax-rate" type="number" step="0.01" class="p-2.5 border rounded-lg" placeholder="نسبة الضريبة" value="'+A(s.tax_rate??0)+'">'+
          '<select id="settings-currency" class="p-2.5 border rounded-lg">'+['SAR','EGP','AED','KWD','QAR','BHD','OMR','USD'].map(x=>'<option value="'+A(x)+'"'+(s.currency===x?' selected':'')+'>'+E(x)+'</option>').join('')+'</select>'+
          '<input id="settings-company-name" class="p-2.5 border rounded-lg md:col-span-2" placeholder="اسم الشركة" value="'+A(s.company_name||'')+'">'+
          '<div class="md:col-span-2"><label class="block text-sm font-bold mb-2">شعار الشركة</label><div class="flex items-center gap-4"><div class="w-20 h-20 rounded-xl border flex items-center justify-center overflow-hidden"><img id="settings-logo-preview" class="max-w-full max-h-full object-contain" src="'+A(s.company_logo||'')+'"></div><input id="settings-logo-file" type="file" accept="image/*"></div></div>'+ 
          '</div><button id="btn-save-invoice-settings" class="mt-4 bg-blue-600 text-white px-6 py-2.5 rounded-xl">حفظ الإعدادات</button></div>'+ 
          '<div class="bg-white rounded-2xl shadow-sm border p-6"><h2 class="text-xl font-bold mb-6">الفوترة الإلكترونية</h2>'+ 
          '<input id="settings-vat-number" class="w-full p-2.5 border rounded-lg mb-3" placeholder="الرقم الضريبي" value="'+A(s.vat_number||'')+'">'+ 
          '<input id="settings-registered-name" class="w-full p-2.5 border rounded-lg mb-3" placeholder="الاسم التجاري" value="'+A(s.registered_name||'')+'">'+ 
          '<textarea id="settings-business-address" class="w-full p-2.5 border rounded-lg" placeholder="العنوان">'+E(s.business_address||'')+'</textarea>'+ 
          '<button id="btn-save-zatca-settings" class="mt-3 bg-emerald-600 text-white px-6 py-2 rounded-xl">حفظ الفوترة</button></div></div>');
        $('settings-logo-file').onchange=(ev)=>{const f=ev.target.files?.[0];if(!f)return;const fr=new FileReader();fr.onload=e=>$('settings-logo-preview').src=e.target.result;fr.readAsDataURL(f);};
        $('btn-save-invoice-settings').onclick=()=>save({delivery_fee:+val('settings-delivery-fee')||0,min_invoice_amount:+val('settings-min-invoice')||0,tax_rate:+val('settings-tax-rate')||0,currency:val('settings-currency'),company_name:val('settings-company-name'),company_logo:current.company_logo||''});
        $('btn-save-zatca-settings').onclick=()=>save({vat_number:val('settings-vat-number'),registered_name:val('settings-registered-name'),business_address:val('settings-business-address')});
      }catch(e){notifyError(e)}finally{hideLoader()}
    }
    async function save(payload){
      showLoader('جاري الحفظ...');
      try{
        const f=$('settings-logo-file')?.files?.[0];
        if(f){const up=await supabase.storage.from('product-images').upload('logos/'+Date.now()+'-'+f.name,f,{upsert:true});if(up.error)throw up.error;payload.company_logo=supabase.storage.from('product-images').getPublicUrl(up.data.path).data.publicUrl;}
        await edgeCall('save-settings',payload);hideLoader();showToast('تم حفظ الإعدادات','success');current=Object.assign({},current,payload);
      }catch(e){hideLoader();notifyError(e)}
    }
    return {render};
  })();
  window.RW_Settings=RW_Settings;

  /* ---------------- Users / Permissions / Customer Assignments ---------------- */
  const RW_Users=(function(){
    let employees=[],roles=[],branches=[];
    let currentEmployeeEmail=null;
    const permissionList=[
      ['pos','نقطة البيع'],['telesales','التلي سيلز'],['orders','الأوردرات'],['van-sales','فان سيلز'],
      ['sales_supervisor','مشرف المبيعات'],['warehouse_supervisor','مشرف المخازن'],['warehouse','عمال المخازن'],
      ['delivery','مندوب التوصيل'],['delivery_supervisor','مشرف التوصيل'],['purchases','المشتريات'],['purchases_supervisor','مشرف المشتريات'],
      ['finance','المحاسب'],['online-store','المتجر الإلكتروني'],['sales_manager','مدير المبيعات'],['warehouse_manager','مدير المخازن'],
      ['finance_manager','المدير المالي'],['general_manager','المدير العام'],['hr','الموارد البشرية'],['dash','لوحة التحكم'],
      ['items','الأصناف والمخزون'],['customers','العملاء'],['suppliers','الموردين'],['branches','الفروع والمخازن'],['runsheets','الرانشيتات'],
      ['receiving','الاستلام'],['picking','التحضير'],['loading','التحميل'],['return','المرتجعات'],['unloading','التفريغ'],
      ['vouchers','الأذونات'],['transfer','تحويل مخزني'],['direct-sale','صرف سيارة'],['direct-return','مرتجع سيارة'],['supplier-return','مرتجع مورد'],
      ['vehicle-count','جرد سيارة'],['branch-count','جرد فرع'],['general-count','جرد عام'],['reports','التقارير'],['users','المستخدمين'],
      ['roles','الأدوار'],['settings','الإعدادات'],['settlement','إغلاق اليومية']
    ];

    const listify=(v)=>{
      if(Array.isArray(v))return v.map(String);
      if(typeof v==='string'){try{const x=JSON.parse(v);if(Array.isArray(x))return x.map(String)}catch(_){ } return v.split(',').map(x=>x.trim()).filter(Boolean);}
      return [];
    };

    async function load(){
      const cid=companyId();
      const [u,r,b]=await Promise.all([
        supabase.from('users').select('*').eq('company_id',cid).order('name'),
        supabase.from('roles').select('*').eq('company_id',cid).order('role_name'),
        RW_Data.loadBranches()
      ]);
      if(u.error)throw u.error;
      employees=u.data||[];
      roles=r.error?[]:(r.data||[]);
      branches=b||[];
    }

    function renderTable(){
      const w=$('emp-table-wrapper');if(!w)return;
      const q=String($('emp-search')?.value||'').toLowerCase().trim();
      let rows=employees.filter(e=>!(e.role==='مالك'||e.role==='Owner'||e.is_owner===true));
      if(q)rows=rows.filter(e=>String(e.name||'').toLowerCase().includes(q)||String(e.email||'').toLowerCase().includes(q)||String(e.phone||'').toLowerCase().includes(q));
      safeHTML(w,rows.length?
        '<table class="w-full text-sm"><thead><tr><th class="p-3">الاسم</th><th class="p-3">البريد</th><th class="p-3">الدور</th><th class="p-3">الحالة</th><th class="p-3">الهاتف</th><th class="p-3">الفروع</th></tr></thead><tbody>'+
        rows.map(e=>'<tr class="cursor-pointer" data-email="'+A(e.email)+'" onclick="RW_Users._openModal(this.dataset.email)"><td class="p-3">'+E(e.name)+'</td><td class="p-3">'+E(e.email)+'</td><td class="p-3">'+E(e.role)+'</td><td class="p-3">'+(e.status==='Active'?'🟢':'🔴')+'</td><td class="p-3">'+E(e.phone)+'</td><td class="p-3">'+E(listify(e.allowed_branch_ids).join(', ')||'*')+'</td></tr>').join('')+
        '</tbody></table>':'<div class="text-center p-10">لا يوجد مستخدمون</div>');
    }

    function employee(email){return employees.find(e=>e.email===email)||null;}

    async function loadAssignments(){
      const e=employee(currentEmployeeEmail);if(!e)return;
      const r=await supabase.from('customer_assignments').select('customer_id,customers!inner(customer_code,name,area,phone,company_id)').eq('user_id',e.id).eq('is_active',true).eq('customers.company_id',companyId());
      if(r.error)throw r.error;
      window._assignedCustomerIds=(r.data||[]).map(x=>x.customer_id);
      safeHTML($('assigned-customers-list'),(r.data||[]).map(a=>'<div class="flex justify-between p-2 border-b"><span>'+E(a.customers.name)+' <small>'+E(a.customers.customer_code)+'</small></span><button data-id="'+A(a.customer_id)+'" onclick="RW_Users._removeAssignedCustomer(this.dataset.id)">✕ إزالة</button></div>').join('')||'<div class="text-center p-3">لا يوجد عملاء معينون</div>');
    }

    function _switchEmpTab(tab){
      ['basic','perms','field','assignments'].forEach(k=>{$('emp-panel-'+k)?.classList.add('hidden');$('tab-'+k)?.classList.remove('border-blue-600','text-blue-600')});
      $('emp-panel-'+tab)?.classList.remove('hidden');$('tab-'+tab)?.classList.add('border-blue-600','text-blue-600');
      if(tab==='assignments')loadAssignments().catch(notifyError);
    }

    async function _searchAssignmentCustomers(q){
      const w=$('assignment-results');if(!w)return;
      const query=String(q||'').toLowerCase().trim();
      if(query.length<2)return safeHTML(w,'<div class="text-center p-2">اكتب حرفين على الأقل</div>');
      const base=(RW_STATE.data.customers||[]).filter(c=>String(c.company_id||companyId())===String(companyId()));
      const rows=searchRows(base,query,['name','customer_code','phone']).slice(0,20);
      safeHTML(w,rows.map(c=>'<div class="flex justify-between p-2 border-b"><span>'+E(c.name)+' <small>'+E(c.customer_code)+'</small></span><button data-id="'+A(c.id)+'" onclick="RW_Users._toggleAssignmentCustomer(this.dataset.id,this)">إضافة</button></div>').join('')||'<div>لا توجد نتائج</div>');
    }

    async function _toggleAssignmentCustomer(id,btn){
      const e=employee(currentEmployeeEmail);if(!e)return notifyError('المستخدم غير موجود');
      const c=(RW_STATE.data.customers||[]).find(x=>String(x.id)===String(id)&&String(x.company_id||companyId())===String(companyId()));if(!c)return notifyError('العميل غير موجود ضمن الشركة الحالية');
      const assigned=window._assignedCustomerIds||[];
      if(!assigned.includes(id)){
        const r=await supabase.from('customer_assignments').upsert({user_id:e.id,customer_id:id,assigned_by:RW_STATE.app?.userId||null,is_active:true},{onConflict:'user_id,customer_id'});
        if(r.error)throw r.error;
        assigned.push(id);
      }else{
        const r=await supabase.from('customer_assignments').update({is_active:false}).eq('user_id',e.id).eq('customer_id',id);
        if(r.error)throw r.error;
        assigned.splice(assigned.indexOf(id),1);
      }
      window._assignedCustomerIds=assigned;
      if(btn)btn.textContent=assigned.includes(id)?'✓ مضاف':'إضافة';
      await loadAssignments();
    }

    async function _removeAssignedCustomer(id){
      const e=employee(currentEmployeeEmail);if(!e)return;
      const r=await supabase.from('customer_assignments').update({is_active:false}).eq('user_id',e.id).eq('customer_id',id);
      if(r.error)throw r.error;
      await loadAssignments();
    }

    async function _handleSave(){
      const edit=!!currentEmployeeEmail;
      const payload={
        name:val('emp-name'),email:val('emp-email'),phone:val('emp-phone'),
        password:val('emp-password')||null,role:val('emp-role'),status:val('emp-status'),
        expiry_date:val('emp-expiry'),allowed_branch_ids:[...($('emp-branches')?.selectedOptions||[])].map(x=>x.value),
        permissions:[...document.querySelectorAll('.emp-custom-perm:checked')].map(x=>x.value),
        allow_all_customers:!!$('emp-allow-all-customers')?.checked,
        restrict_to_visit_day:!!$('emp-restrict-visit-day')?.checked,
        device_id:val('emp-device-id')
      };
      if(!payload.name||!payload.email)return notifyError('الاسم والبريد مطلوبان');
      if(!edit&&!payload.password)return notifyError('كلمة المرور مطلوبة');
      showLoader('جاري الحفظ...');
      try{await edgeCall('save-employee',{employee:payload,isEdit:edit,originalEmail:currentEmployeeEmail||''});hideLoader();Swal.close();showToast(edit?'تم التعديل':'تمت الإضافة','success');currentEmployeeEmail=null;await load();renderTable();}
      catch(e){hideLoader();notifyError(e);}
    }

    async function _handleDelete(){
      const e=employee(currentEmployeeEmail);if(!e)return;
      const confirm=await Swal.fire({title:'تأكيد الحذف',text:'حذف هذا الموظف؟',icon:'warning',showCancelButton:true,confirmButtonText:'حذف',cancelButtonText:'إلغاء'});
      if(!confirm.isConfirmed)return;showLoader('جاري الحذف...');
      try{await edgeCall('delete-employee',{email:e.email});hideLoader();Swal.close();showToast('تم الحذف','success');currentEmployeeEmail=null;await load();renderTable();}
      catch(e2){hideLoader();notifyError(e2);}
    }

    function _openModal(email){
      currentEmployeeEmail=email||null;
      const e=email?employee(email):null, edit=!!e, perms=listify(e?.permissions), allowed=listify(e?.allowed_branch_ids);
      const roleOptions=roles.map(r=>'<option value="'+A(r.role_name)+'"'+(e?.role===r.role_name?' selected':'')+'>'+E(r.role_name)+'</option>').join('')||'<option value="">اختر دورًا</option>';
      const branchOptions=branches.map(b=>{const code=String(b.branch_code||b.id||'');return'<option value="'+A(code)+'"'+(allowed.includes(code)?' selected':'')+'>'+E(b.name||b.branch_name||code)+' ('+E(code)+')</option>';}).join('');
      const permsHtml=permissionList.map(p=>'<label class="text-xs"><input type="checkbox" class="emp-custom-perm" value="'+A(p[0])+'"'+(perms.includes(p[0])?' checked':'')+'> '+E(p[1])+'</label>').join('');

      modal('<div class="p-6" dir="rtl"><h3 class="text-xl font-bold mb-4">'+(edit?'تعديل مستخدم':'إضافة مستخدم جديد')+'</h3>'+ 
        '<div class="flex border-b mb-4"><button id="tab-basic" onclick="RW_Users._switchEmpTab(\'basic\')" class="px-3 py-2 border-b-2 border-blue-600 text-blue-600">البيانات</button><button id="tab-perms" onclick="RW_Users._switchEmpTab(\'perms\')" class="px-3 py-2">الصلاحيات</button><button id="tab-field" onclick="RW_Users._switchEmpTab(\'field\')" class="px-3 py-2">الميدان</button>'+(edit?'<button id="tab-assignments" onclick="RW_Users._switchEmpTab(\'assignments\')" class="px-3 py-2">العملاء</button>':'')+'</div>'+ 
        '<div id="emp-panel-basic"><div class="grid md:grid-cols-2 gap-3"><input id="emp-name" class="p-2.5 border rounded-lg" placeholder="الاسم *" value="'+A(e?.name||'')+'"><input id="emp-email" type="email" class="p-2.5 border rounded-lg" placeholder="البريد *" value="'+A(e?.email||'')+'"><input id="emp-phone" class="p-2.5 border rounded-lg" placeholder="الهاتف" value="'+A(e?.phone||'')+'"><input id="emp-password" type="password" class="p-2.5 border rounded-lg" placeholder="'+(edit?'اتركه فارغًا':'كلمة المرور *')+'"><select id="emp-role" class="p-2.5 border rounded-lg">'+roleOptions+'</select><select id="emp-status" class="p-2.5 border rounded-lg"><option value="Active"'+(!edit||e.status==='Active'?' selected':'')+'>نشط</option><option value="Inactive"'+(edit&&e.status==='Inactive'?' selected':'')+'>غير نشط</option></select><input id="emp-expiry" type="date" class="p-2.5 border rounded-lg" value="'+A(e?.expiry_date||'')+'"><select id="emp-branches" multiple class="p-2.5 border rounded-lg" style="min-height:100px">'+branchOptions+'</select></div></div>'+ 
        '<div id="emp-panel-perms" class="hidden"><label><input id="emp-custom-perms-toggle" type="checkbox"'+(perms.length?' checked':'')+'> صلاحيات مخصصة</label><div id="emp-custom-perms-section" class="'+(perms.length?'':'hidden ')+'grid grid-cols-2 md:grid-cols-4 gap-2 mt-3">'+permsHtml+'</div></div>'+ 
        '<div id="emp-panel-field" class="hidden space-y-3"><label><input id="emp-allow-all-customers" type="checkbox"'+(e?.allow_all_customers?' checked':'')+'> السماح بكل العملاء</label><label><input id="emp-restrict-visit-day" type="checkbox"'+(!edit||e?.restrict_to_visit_day!==false?' checked':'')+'> تقييد بيوم الزيارة</label><input id="emp-device-id" class="p-2.5 border rounded-lg w-full" placeholder="Device ID" value="'+A(e?.device_id||'')+'"></div>'+ 
        (edit?'<div id="emp-panel-assignments" class="hidden"><input id="assignment-search" class="w-full p-2.5 border rounded-lg" placeholder="بحث عن عميل"><div id="assignment-results" class="border mt-2 p-2"></div><div id="assigned-customers-list" class="border mt-3 p-2">جاري التحميل...</div></div>':'')+
        '<div class="flex justify-end gap-3 mt-5 border-t pt-4">'+(edit?'<button id="btn-delete-emp" class="bg-red-600 text-white px-5 py-2 rounded-xl mr-auto">حذف</button>':'')+'<button onclick="Swal.close()" class="border px-5 py-2 rounded-xl">إلغاء</button><button id="btn-save-emp" class="bg-indigo-600 text-white px-6 py-2 rounded-xl">حفظ</button></div></div>',950);

      $('emp-custom-perms-toggle').onchange=()=>{$('emp-custom-perms-section').classList.toggle('hidden')};
      $('assignment-search')?.addEventListener('input',e2=>_searchAssignmentCustomers(e2.target.value));
      $('btn-save-emp').onclick=_handleSave;
      if(edit){$('btn-delete-emp').onclick=_handleDelete;loadAssignments().catch(notifyError);}
    }

    async function render(){
      const c=$('rw-page-container');if(!c)return;safeText($('rw-header-title'),'المستخدمين والصلاحيات');
      safeHTML(c,'<div class="p-4"><div class="flex justify-between mb-4"><h2 class="text-xl font-bold">إدارة المستخدمين والصلاحيات</h2><button id="btn-add-emp" class="bg-indigo-600 text-white px-4 py-2 rounded-xl">+ إضافة مستخدم</button></div><input id="emp-search" class="w-full p-3 border rounded-xl mb-4" placeholder="بحث..."><div id="emp-table-wrapper"></div></div>');
      await load();renderTable();$('emp-search').oninput=renderTable;$('btn-add-emp').onclick=()=>_openModal(null);
    }

    return {render,_openModal,_switchEmpTab,_searchAssignmentCustomers,_toggleAssignmentCustomer,_removeAssignedCustomer,_handleSave,_handleDelete};
  })();
  window.RW_Users=RW_Users;

  window.MAIN3_GOVERNED_RECONSTRUCTED='v5';
})();
