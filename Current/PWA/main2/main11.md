// ============================================================
// RW_HR – الموارد البشرية (HR) - الوحدة المتقدمة
// ============================================================
var RW_HR = (function() {
    'use strict';

    var hrData = [];

    function _esc(s) {
        return String(s == null ? '' : s)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');
    }

    function _escAttr(s) {
        return _esc(s)
            .replace(/\"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function _fmtNum(n) {
        return Number(n || 0).toLocaleString('ar-EG');
    }

    function _companyId() {
        if (typeof _rwCompanyId === 'function') return _rwCompanyId();
        if (typeof RW_STATE !== 'undefined' && RW_STATE) {
            if (RW_STATE.app && RW_STATE.app.companyId) return RW_STATE.app.companyId;
            if (RW_STATE.app && RW_STATE.app.company && RW_STATE.app.company.id) return RW_STATE.app.company.id;
            if (RW_STATE.user && RW_STATE.user.companyId) return RW_STATE.user.companyId;
        }
        return null;
    }

    async function _loadEmployees() {
        var res = await supabase.rpc('hr_list_employees');
        if (res.error) throw res.error;
        hrData = res.data || [];
        return hrData;
    }

    function _employeeCard(emp) {
        var profileSalary = Number(emp.basic_salary || 0) +
            Number(emp.housing_allowance || 0) +
            Number(emp.transport_allowance || 0) +
            Number(emp.other_allowance || 0) -
            Number(emp.default_deduction || 0);
        return '<div class="bg-white rounded-2xl shadow-sm border p-5 hover:shadow-md transition cursor-pointer" data-hr-employee-id="' + _escAttr(emp.id) + '">' +
            '<div class="flex items-center gap-4 mb-4">' +
                '<div class="w-14 h-14 rounded-2xl bg-indigo-500 flex items-center justify-center text-white text-xl font-black">' + _esc((emp.name || '?').charAt(0)) + '</div>' +
                '<div class="min-w-0"><h3 class="font-black text-base text-gray-800 truncate">' + _esc(emp.name) + '</h3><p class="text-xs text-gray-500 truncate">' + _esc(emp.job_title || emp.role || 'موظف') + '</p></div>' +
            '</div>' +
            '<div class="space-y-2 text-sm">' +
                '<div class="flex justify-between"><span class="text-gray-500">البريد</span><span class="font-bold text-gray-700">' + _esc(emp.email) + '</span></div>' +
                '<div class="flex justify-between"><span class="text-gray-500">الهاتف</span><span class="font-bold text-gray-700">' + _esc(emp.phone || '-') + '</span></div>' +
                '<div class="flex justify-between"><span class="text-gray-500">الحالة</span><span class="px-2 py-0.5 rounded-full text-xs font-bold ' + (emp.status === 'Active' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700') + '">' + _esc(emp.status === 'Active' ? 'نشط' : 'غير نشط') + '</span></div>' +
                '<div class="flex justify-between"><span class="text-gray-500">صافي التعويض</span><span class="font-black text-indigo-600">' + _fmtNum(profileSalary) + ' EGP</span></div>' +
            '</div>' +
        '</div>';
    }

    async function render() {
        var container = byId('rw-page-container');
        if (!container) return;
        safeText(byId('rw-header-title'), 'الموارد البشرية');
        safeText(byId('rw-header-subtitle'), 'ملفات الموظفين والتعويضات والحضور والإجازات والمستندات');

        if (!_companyId()) {
            safeHTML(container, '<div class="rw-card p-8 text-center"><div class="text-5xl mb-3">⚠️</div><h3 class="font-black text-xl">تعذر تحديد سياق الشركة</h3></div>');
            return;
        }

        showLoader('جاري تحميل بيانات الموارد البشرية...');
        try {
            await _loadEmployees();
        } catch (error) {
            console.error('RW_HR.loadEmployees', error);
            hideLoader();
            safeHTML(container, '<div class="rw-card p-8 text-center"><div class="text-5xl mb-3">⚠️</div><h3 class="font-black text-xl">تعذر تحميل بيانات الموظفين</h3><p class="text-gray-500 mt-2">' + _esc(error.message || 'خطأ غير معروف') + '</p></div>');
            return;
        }
        hideLoader();

        var activeEmployees = hrData.filter(function(emp) {
            return !(emp.role === 'مالك' || emp.role === 'Owner');
        });

        var html = '<div class="p-4 space-y-5">';
        html += '<div class="grid grid-cols-1 md:grid-cols-4 gap-4">';
        html += '<div class="bg-white rounded-2xl border p-5"><div class="text-xs text-gray-500">إجمالي الموظفين</div><div class="text-3xl font-black text-indigo-600 mt-2">' + activeEmployees.length + '</div></div>';
        html += '<div class="bg-white rounded-2xl border p-5"><div class="text-xs text-gray-500">الموظفون النشطون</div><div class="text-3xl font-black text-green-600 mt-2">' + activeEmployees.filter(function(e){return e.status==='Active';}).length + '</div></div>';
        html += '<div class="bg-white rounded-2xl border p-5"><div class="text-xs text-gray-500">إجمالي التعويضات الشهرية</div><div class="text-3xl font-black text-blue-600 mt-2">' + _fmtNum(activeEmployees.reduce(function(sum,e){return sum + Number(e.basic_salary||0)+Number(e.housing_allowance||0)+Number(e.transport_allowance||0)+Number(e.other_allowance||0)-Number(e.default_deduction||0);},0)) + '</div></div>';
        html += '<div class="bg-white rounded-2xl border p-5"><div class="text-xs text-gray-500">ملفات موظفين بدون بطاقة</div><div class="text-3xl font-black text-amber-600 mt-2">' + activeEmployees.filter(function(e){return !e.profile_id;}).length + '</div></div>';
        html += '</div>';

        html += '<div class="flex flex-col md:flex-row gap-3">';
        html += '<input id="hr-search" class="flex-1 p-3 bg-white border rounded-xl" placeholder="بحث بالاسم أو البريد أو الرقم الوظيفي">';
        html += '<button id="hr-refresh" class="px-5 py-3 bg-indigo-600 text-white rounded-xl font-bold">تحديث</button>';
        html += '</div>';

        html += '<div id="hr-cards-container" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">';
        html += activeEmployees.map(_employeeCard).join('');
        html += '</div>';
        html += '<div id="hr-empty" class="hidden text-center py-10 text-gray-500">لا توجد نتائج مطابقة.</div>';
        html += '</div>';
        safeHTML(container, html);

        var search = byId('hr-search');
        if (search) {
            search.addEventListener('input', function() {
                var q = search.value.trim().toLowerCase();
                var cards = byId('hr-cards-container').querySelectorAll('[data-hr-employee-id]');
                var visible = 0;
                for (var i = 0; i < cards.length; i++) {
                    var empId = cards[i].getAttribute('data-hr-employee-id');
                    var emp = hrData.filter(function(e){return e.id === empId;})[0];
                    var hay = ((emp.name||'')+' '+(emp.email||'')+' '+(emp.employee_number||'')+' '+(emp.job_title||'')).toLowerCase();
                    cards[i].style.display = !q || hay.indexOf(q) !== -1 ? '' : 'none';
                    if (cards[i].style.display !== 'none') visible++;
                }
                byId('hr-empty').classList.toggle('hidden', visible !== 0);
            });
        }
        var refresh = byId('hr-refresh');
        if (refresh) refresh.addEventListener('click', function(){ render(); });
        var cardNodes = container.querySelectorAll('[data-hr-employee-id]');
        for (var c = 0; c < cardNodes.length; c++) {
            cardNodes[c].addEventListener('click', function(){
                var id = this.getAttribute('data-hr-employee-id');
                _openModal(id);
            });
        }
    }

    async function _loadDocuments(employeeId) {
        var res = await supabase.from('employee_documents')
            .select('id,document_type,storage_path,document_name,mime_type,expires_at,status,notes,created_at')
            .eq('employee_id', employeeId)
            .eq('company_id', _companyId())
            .order('created_at', {ascending:false});
        if (res.error) throw res.error;
        return res.data || [];
    }

    async function _loadAttendance(employeeId) {
        var res = await supabase.from('employee_attendance')
            .select('id,attendance_date,status,check_in,check_out,notes')
            .eq('employee_id', employeeId)
            .eq('company_id', _companyId())
            .order('attendance_date',{ascending:false})
            .limit(14);
        if (res.error) throw res.error;
        return res.data || [];
    }

    async function _loadLeaves(employeeId) {
        var res = await supabase.from('employee_leave_requests')
            .select('id,leave_type,start_date,end_date,reason,status,requested_by,approved_by,approved_at,notes')
            .eq('employee_id', employeeId)
            .eq('company_id', _companyId())
            .order('start_date',{ascending:false})
            .limit(20);
        if (res.error) throw res.error;
        return res.data || [];
    }

    async function _openModal(employeeId) {
        var emp = hrData.filter(function(e){ return e.id === employeeId; })[0];
        if (!emp) { showToast('الموظف غير موجود', 'error'); return; }

        showLoader('جاري تحميل ملف الموظف...');
        try {
            var docs = await _loadDocuments(employeeId);
            var attendance = await _loadAttendance(employeeId);
            var leaves = await _loadLeaves(employeeId);
            hideLoader();

            var html = '<div class="text-right space-y-5" data-hr-modal="1">';
            html += '<div class="bg-indigo-50 rounded-2xl p-5"><div class="flex justify-between gap-4"><div><h3 class="font-black text-xl">' + _esc(emp.name) + '</h3><p class="text-sm text-gray-500">' + _esc(emp.job_title || emp.role || 'موظف') + '</p></div><div class="text-left"><div class="text-xs text-gray-500">الرقم الوظيفي</div><div class="font-black">' + _esc(emp.employee_number || emp.employee_id || '-') + '</div></div></div></div>';

            html += '<div class="bg-white border rounded-2xl p-5"><h4 class="font-black mb-4">البيانات والوظيفة</h4><div class="grid grid-cols-2 gap-4 text-sm">';
            html += '<div><span class="text-gray-500">البريد</span><div class="font-bold">' + _esc(emp.email) + '</div></div>';
            html += '<div><span class="text-gray-500">الهاتف</span><div class="font-bold">' + _esc(emp.phone || '-') + '</div></div>';
            html += '<div><span class="text-gray-500">القسم</span><div class="font-bold">' + _esc(emp.department || '-') + '</div></div>';
            html += '<div><span class="text-gray-500">المسمى</span><div class="font-bold">' + _esc(emp.job_title || '-') + '</div></div>';
            html += '<div><span class="text-gray-500">تاريخ الالتحاق</span><div class="font-bold">' + _esc(emp.hire_date || '-') + '</div></div>';
            html += '<div><span class="text-gray-500">نوع التوظيف</span><div class="font-bold">' + _esc(emp.employment_type || '-') + '</div></div>';
            html += '</div><div class="flex justify-end mt-4"><button id="hr-edit-profile" class="px-5 py-2 bg-indigo-600 text-white rounded-xl font-bold">تعديل الملف</button></div></div>';

            var totalComp = Number(emp.basic_salary||0)+Number(emp.housing_allowance||0)+Number(emp.transport_allowance||0)+Number(emp.other_allowance||0)-Number(emp.default_deduction||0);
            html += '<div class="bg-white border rounded-2xl p-5"><h4 class="font-black mb-4">التعويضات المسجلة فعليًا</h4><div class="grid grid-cols-2 md:grid-cols-5 gap-3 text-sm">';
            html += '<div class="bg-gray-50 rounded-xl p-3"><div class="text-gray-500 text-xs">أساسي</div><div class="font-black">'+_fmtNum(emp.basic_salary)+' EGP</div></div>';
            html += '<div class="bg-gray-50 rounded-xl p-3"><div class="text-gray-500 text-xs">سكن</div><div class="font-black">'+_fmtNum(emp.housing_allowance)+' EGP</div></div>';
            html += '<div class="bg-gray-50 rounded-xl p-3"><div class="text-gray-500 text-xs">نقل</div><div class="font-black">'+_fmtNum(emp.transport_allowance)+' EGP</div></div>';
            html += '<div class="bg-gray-50 rounded-xl p-3"><div class="text-gray-500 text-xs">بدلات أخرى</div><div class="font-black">'+_fmtNum(emp.other_allowance)+' EGP</div></div>';
            html += '<div class="bg-indigo-50 rounded-xl p-3"><div class="text-indigo-600 text-xs">الصافي المسجل</div><div class="font-black text-indigo-700">'+_fmtNum(totalComp)+' EGP</div></div>';
            html += '</div></div>';

            html += '<div class="bg-white border rounded-2xl p-5"><div class="flex justify-between items-center mb-4"><h4 class="font-black">الحضور والانصراف</h4><button id="hr-add-attendance" class="px-4 py-2 bg-emerald-600 text-white rounded-xl font-bold text-sm">تسجيل يوم</button></div>';
            html += '<div class="overflow-x-auto"><table class="w-full text-sm"><thead><tr class="text-gray-500"><th class="p-2">التاريخ</th><th class="p-2">الحالة</th><th class="p-2">دخول</th><th class="p-2">خروج</th><th class="p-2">ملاحظات</th></tr></thead><tbody>';
            html += attendance.map(function(a){return '<tr class="border-t"><td class="p-2">'+_esc(a.attendance_date)+'</td><td class="p-2 font-bold">'+_esc(a.status)+'</td><td class="p-2">'+_esc(a.check_in||'-')+'</td><td class="p-2">'+_esc(a.check_out||'-')+'</td><td class="p-2">'+_esc(a.notes||'-')+'</td></tr>';}).join('');
            html += '</tbody></table></div></div>';

            html += '<div class="bg-white border rounded-2xl p-5"><div class="flex justify-between items-center mb-4"><h4 class="font-black">الإجازات</h4><button id="hr-add-leave" class="px-4 py-2 bg-amber-600 text-white rounded-xl font-bold text-sm">طلب إجازة</button></div>';
            html += leaves.map(function(l){var actions=l.status==='pending' ? '<button data-leave-approve="'+_escAttr(l.id)+'" class="px-3 py-1 bg-green-100 text-green-700 rounded-lg text-xs font-bold">اعتماد</button> <button data-leave-reject="'+_escAttr(l.id)+'" class="px-3 py-1 bg-red-100 text-red-700 rounded-lg text-xs font-bold">رفض</button>' : ''; return '<div class="border-t py-3"><div class="flex justify-between"><div><b>'+_esc(l.leave_type)+'</b> — '+_esc(l.start_date)+' إلى '+_esc(l.end_date)+'</div><span class="font-bold">'+_esc(l.status)+'</span></div><div class="text-xs text-gray-500 mt-1">'+_esc(l.reason||'-')+'</div><div class="mt-2">'+actions+'</div></div>';}).join('');
            if (!leaves.length) html += '<div class="text-center py-4 text-gray-400">لا توجد طلبات إجازة</div>';
            html += '</div>';

            html += '<div class="bg-white border rounded-2xl p-5"><div class="flex justify-between items-center mb-4"><h4 class="font-black">المستندات</h4><button id="hr-upload-doc" class="px-4 py-2 bg-blue-600 text-white rounded-xl font-bold text-sm">رفع مستند</button></div>';
            html += '<div class="space-y-2">';
            for (var d=0; d<docs.length; d++) {
                html += '<div class="flex items-center justify-between border rounded-xl p-3"><div><div class="font-bold">'+_esc(docs[d].document_name||docs[d].document_type)+'</div><div class="text-xs text-gray-500">'+_esc(docs[d].document_type)+' — '+_esc(docs[d].expires_at||'بدون انتهاء')+'</div></div><button data-doc-id="'+_escAttr(docs[d].id)+'" data-doc-path="'+_escAttr(docs[d].storage_path||'')+'" class="px-3 py-1 bg-gray-100 rounded-lg text-xs font-bold">فتح</button></div>';
            }
            if (!docs.length) html += '<div class="text-center py-4 text-gray-400">لا توجد مستندات</div>';
            html += '</div></div>';
            html += '</div>';

            Swal.fire({title:'ملف الموظف: '+_esc(emp.name),html:html,width:'980px',showCloseButton:true,showConfirmButton:false,didOpen:function(){
                var editBtn=byId('hr-edit-profile'); if(editBtn) editBtn.addEventListener('click',function(){_editProfile(emp);});
                var attBtn=byId('hr-add-attendance'); if(attBtn) attBtn.addEventListener('click',function(){_addAttendance(emp);});
                var leaveBtn=byId('hr-add-leave'); if(leaveBtn) leaveBtn.addEventListener('click',function(){_addLeave(emp);});
                var uploadBtn=byId('hr-upload-doc'); if(uploadBtn) uploadBtn.addEventListener('click',function(){_uploadDocument(emp);});
                var approveNodes=document.querySelectorAll('[data-leave-approve]'); for(var ai=0;ai<approveNodes.length;ai++) approveNodes[ai].addEventListener('click',function(){_setLeaveStatus(this.getAttribute('data-leave-approve'),'approved',emp);});
                var rejectNodes=document.querySelectorAll('[data-leave-reject]'); for(var ri=0;ri<rejectNodes.length;ri++) rejectNodes[ri].addEventListener('click',function(){_setLeaveStatus(this.getAttribute('data-leave-reject'),'rejected',emp);});
                var docNodes=document.querySelectorAll('[data-doc-path]'); for(var di=0;di<docNodes.length;di++) docNodes[di].addEventListener('click',function(){_openDocument(this.getAttribute('data-doc-path'));});
            }});
        } catch(error) {
            hideLoader();
            showToast('تعذر تحميل ملف الموظف: '+(error.message||'خطأ غير معروف'),'error');
        }
    }

    async function _editProfile(emp) {
        var html='<div class="text-right space-y-3">'+
            '<input id="hr-p-number" class="w-full p-2 border rounded" placeholder="الرقم الوظيفي" value="'+_escAttr(emp.employee_number||emp.employee_id||'')+'">'+
            '<input id="hr-p-department" class="w-full p-2 border rounded" placeholder="القسم" value="'+_escAttr(emp.department||'')+'">'+
            '<input id="hr-p-title" class="w-full p-2 border rounded" placeholder="المسمى الوظيفي" value="'+_escAttr(emp.job_title||emp.role||'')+'">'+
            '<input id="hr-p-hire-date" type="date" class="w-full p-2 border rounded" value="'+_escAttr(emp.hire_date||'')+'">'+
            '<input id="hr-p-type" class="w-full p-2 border rounded" placeholder="نوع التوظيف" value="'+_escAttr(emp.employment_type||'')+'">'+
            '<div class="grid grid-cols-2 gap-2"><input id="hr-p-basic" type="number" min="0" class="p-2 border rounded" placeholder="الأساسي" value="'+Number(emp.basic_salary||0)+'"><input id="hr-p-housing" type="number" min="0" class="p-2 border rounded" placeholder="بدل السكن" value="'+Number(emp.housing_allowance||0)+'"><input id="hr-p-transport" type="number" min="0" class="p-2 border rounded" placeholder="بدل النقل" value="'+Number(emp.transport_allowance||0)+'"><input id="hr-p-other" type="number" min="0" class="p-2 border rounded" placeholder="بدلات أخرى" value="'+Number(emp.other_allowance||0)+'"><input id="hr-p-deduct" type="number" min="0" class="p-2 border rounded" placeholder="خصم ثابت" value="'+Number(emp.default_deduction||0)+'"></div>'+
            '<textarea id="hr-p-notes" class="w-full p-2 border rounded" placeholder="ملاحظات">'+_esc(emp.profile_notes||'')+'</textarea></div>';
        Swal.fire({title:'تعديل ملف الموظف',html:html,showCancelButton:true,confirmButtonText:'حفظ',cancelButtonText:'إلغاء',preConfirm:function(){return supabase.rpc('hr_upsert_employee_profile',{p_employee_id:emp.id,p_employee_number:byId('hr-p-number').value.trim()||null,p_department:byId('hr-p-department').value.trim()||null,p_job_title:byId('hr-p-title').value.trim()||null,p_hire_date:byId('hr-p-hire-date').value||null,p_employment_type:byId('hr-p-type').value.trim()||null,p_basic_salary:Number(byId('hr-p-basic').value||0),p_housing_allowance:Number(byId('hr-p-housing').value||0),p_transport_allowance:Number(byId('hr-p-transport').value||0),p_other_allowance:Number(byId('hr-p-other').value||0),p_default_deduction:Number(byId('hr-p-deduct').value||0),p_status:(emp.profile_status||'active'),p_notes:byId('hr-p-notes').value.trim()||null}).then(function(res){if(res.error) throw res.error; return res.data;});}}).then(function(res){if(res.isConfirmed){showToast('تم حفظ ملف الموظف','success');Swal.close();render();}}).catch(function(e){showToast('فشل حفظ الملف: '+(e.message||'خطأ غير معروف'),'error');});
    }

    async function _addAttendance(emp) {
        var html='<div class="text-right space-y-3"><input id="hr-att-date" type="date" class="w-full p-2 border rounded" value="'+new Date().toISOString().slice(0,10)+'"><select id="hr-att-status" class="w-full p-2 border rounded"><option value="present">حاضر</option><option value="late">متأخر</option><option value="absent">غائب</option><option value="leave">إجازة</option><option value="holiday">عطلة</option></select><input id="hr-att-in" type="datetime-local" class="w-full p-2 border rounded"><input id="hr-att-out" type="datetime-local" class="w-full p-2 border rounded"><textarea id="hr-att-notes" class="w-full p-2 border rounded" placeholder="ملاحظات"></textarea></div>';
        Swal.fire({title:'تسجيل حضور/انصراف',html:html,showCancelButton:true,confirmButtonText:'حفظ',cancelButtonText:'إلغاء',preConfirm:function(){var toISO=function(id){var v=byId(id).value;return v?new Date(v).toISOString():null;};return supabase.rpc('hr_save_attendance',{p_employee_id:emp.id,p_attendance_date:byId('hr-att-date').value,p_status:byId('hr-att-status').value,p_check_in:toISO('hr-att-in'),p_check_out:toISO('hr-att-out'),p_notes:byId('hr-att-notes').value.trim()||null}).then(function(res){if(res.error)throw res.error;return res.data;});}}).then(function(res){if(res.isConfirmed){showToast('تم حفظ الحضور','success');Swal.close();_openModal(emp.id);}}).catch(function(e){showToast('فشل حفظ الحضور: '+(e.message||'خطأ غير معروف'),'error');});
    }

    async function _addLeave(emp) {
        var html='<div class="text-right space-y-3"><input id="hr-leave-type" class="w-full p-2 border rounded" placeholder="نوع الإجازة"><div class="grid grid-cols-2 gap-2"><input id="hr-leave-start" type="date" class="p-2 border rounded"><input id="hr-leave-end" type="date" class="p-2 border rounded"></div><textarea id="hr-leave-reason" class="w-full p-2 border rounded" placeholder="السبب"></textarea></div>';
        Swal.fire({title:'طلب إجازة',html:html,showCancelButton:true,confirmButtonText:'إرسال',cancelButtonText:'إلغاء',preConfirm:function(){return supabase.rpc('hr_create_leave_request',{p_employee_id:emp.id,p_leave_type:byId('hr-leave-type').value.trim(),p_start_date:byId('hr-leave-start').value,p_end_date:byId('hr-leave-end').value,p_reason:byId('hr-leave-reason').value.trim()||null}).then(function(res){if(res.error)throw res.error;return res.data;});}}).then(function(res){if(res.isConfirmed){showToast('تم إنشاء طلب الإجازة','success');Swal.close();_openModal(emp.id);}}).catch(function(e){showToast('فشل إنشاء الإجازة: '+(e.message||'خطأ غير معروف'),'error');});
    }

    async function _setLeaveStatus(id,status,emp) {
        var currentUser=(RW_STATE&&RW_STATE.app&&RW_STATE.app.currentUser)||{};
        var res=await supabase.from('employee_leave_requests').update({status:status,approved_by:currentUser.email||'',approved_at:new Date().toISOString()}).eq('id',id).eq('company_id',_companyId());
        if(res.error){showToast('فشل تحديث الإجازة: '+res.error.message,'error');return;}
        showToast(status==='approved'?'تم اعتماد الإجازة':'تم رفض الإجازة','success');
        _openModal(emp.id);
    }

    async function _uploadDocument(emp) {
        var html='<div class="text-right space-y-3"><select id="hr-doc-type" class="w-full p-2 border rounded"><option value="identity">صورة الهوية</option><option value="contract">عقد العمل</option><option value="other">مستند آخر</option></select><input id="hr-doc-expiry" type="date" class="w-full p-2 border rounded"><input id="hr-doc-file" type="file" class="w-full p-2 border rounded"><textarea id="hr-doc-notes" class="w-full p-2 border rounded" placeholder="ملاحظات"></textarea></div>';
        Swal.fire({title:'رفع مستند الموظف',html:html,showCancelButton:true,confirmButtonText:'رفع',cancelButtonText:'إلغاء',preConfirm:async function(){var file=byId('hr-doc-file').files[0];if(!file)throw new Error('اختر ملفًا أولاً');var company=_companyId();var safeName=file.name.replace(/[^a-zA-Z0-9._-]+/g,'_');var path=company+'/'+emp.id+'/'+Date.now()+'_'+safeName;var up=await supabase.storage.from('employee-documents').upload(path,file,{upsert:false,contentType:file.type||'application/octet-stream'});if(up.error)throw up.error;var ins=await supabase.from('employee_documents').insert({company_id:company,employee_id:emp.id,document_type:byId('hr-doc-type').value,storage_path:path,document_name:file.name,mime_type:file.type||null,expires_at:byId('hr-doc-expiry').value||null,status:'active',notes:byId('hr-doc-notes').value.trim()||null,created_by:(RW_STATE&&RW_STATE.app&&RW_STATE.app.currentUser&&RW_STATE.app.currentUser.email)||''});if(ins.error){await supabase.storage.from('employee-documents').remove([path]);throw ins.error;}return true;}}).then(function(res){if(res.isConfirmed){showToast('تم رفع المستند','success');Swal.close();_openModal(emp.id);}}).catch(function(e){showToast('فشل رفع المستند: '+(e.message||'خطأ غير معروف'),'error');});
    }

    async function _openDocument(path) {
        if (!path) { showToast('مسار المستند غير موجود','error'); return; }
        var res=await supabase.storage.from('employee-documents').createSignedUrl(path,300);
        if(res.error){showToast('تعذر فتح المستند: '+res.error.message,'error');return;}
        window.open(res.data.signedUrl,'_blank','noopener');
    }

    return { render: render, _openModal: _openModal };
})();
window.RW_HR = RW_HR;
// ============================================================
// RW_CRM – إدارة علاقات العملاء (CRM)
// ============================================================
var RW_CRM = (function() {
    'use strict';

    var customersData = [];

    function _esc(s) {
        return String(s == null ? '' : s)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');
    }

    function _escAttr(s) {
        return _esc(s)
            .replace(/\"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function _fmtNum(n) {
        return Number(n || 0).toLocaleString('ar-EG');
    }

    function _companyId() {
        if (typeof _rwCompanyId === 'function') return _rwCompanyId();
        if (typeof RW_STATE !== 'undefined' && RW_STATE) {
            if (RW_STATE.app && RW_STATE.app.companyId) return RW_STATE.app.companyId;
            if (RW_STATE.app && RW_STATE.app.company && RW_STATE.app.company.id) return RW_STATE.app.company.id;
            if (RW_STATE.user && RW_STATE.user.companyId) return RW_STATE.user.companyId;
        }
        return null;
    }

    async function _loadCustomers() {
        var res = await supabase.from('customers')
            .select('id,customer_code,name,phone,area,debt,is_active')
            .eq('company_id', _companyId())
            .order('name',{ascending:true});
        if (res.error) throw res.error;
        customersData = res.data || [];
        return customersData;
    }

    function _table(customers) {
        if (!customers.length) return '<div class="text-center py-10 text-gray-500">لا يوجد عملاء</div>';
        var html='<div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-gray-50"><tr><th class="p-3 text-right">العميل</th><th class="p-3 text-right">الهاتف</th><th class="p-3 text-right">المنطقة</th><th class="p-3 text-center">الرصيد</th><th class="p-3 text-center">الإجراء</th></tr></thead><tbody>';
        for(var i=0;i<customers.length;i++){
            var c=customers[i];
            html+='<tr class="border-b hover:bg-gray-50" data-crm-customer="'+_escAttr(c.customer_code)+'">'+
                '<td class="p-3"><div class="font-bold">'+_esc(c.name)+'</div><div class="text-xs text-gray-400">'+_esc(c.customer_code)+'</div></td>'+
                '<td class="p-3">'+_esc(c.phone||'-')+'</td>'+
                '<td class="p-3">'+_esc(c.area||'-')+'</td>'+
                '<td class="p-3 text-center font-black '+(Number(c.debt)>0?'text-red-600':'text-green-600')+'">'+_fmtNum(c.debt)+' EGP</td>'+
                '<td class="p-3 text-center"><button data-crm-open="'+_escAttr(c.customer_code)+'" class="px-4 py-2 bg-indigo-100 text-indigo-700 rounded-lg font-bold">متابعة</button></td>'+
            '</tr>';
        }
        return html+'</tbody></table></div>';
    }

    async function render() {
        var container=byId('rw-page-container'); if(!container) return;
        safeText(byId('rw-header-title'),'إدارة علاقات العملاء (CRM)');
        safeText(byId('rw-header-subtitle'),'سجل الاتصالات والمتابعات والإجراءات القادمة للعملاء');
        if(!_companyId()){safeHTML(container,'<div class="rw-card p-8 text-center"><div class="text-5xl mb-3">⚠️</div><h3 class="font-black text-xl">سياق الشركة غير محدد</h3></div>');return;}
        showLoader('جاري تحميل العملاء...');
        try{await _loadCustomers();}catch(e){hideLoader();safeHTML(container,'<div class="rw-card p-8 text-center"><h3 class="font-black text-xl">تعذر تحميل العملاء</h3><p class="text-gray-500 mt-2">'+_esc(e.message||'خطأ غير معروف')+'</p></div>');return;}
        hideLoader();

        var html='<div class="p-4 space-y-5">';
        html+='<div class="grid grid-cols-1 md:grid-cols-4 gap-4">';
        html+='<div class="bg-white rounded-2xl border p-5"><div class="text-xs text-gray-500">إجمالي العملاء</div><div class="text-3xl font-black text-indigo-600 mt-2">'+customersData.length+'</div></div>';
        html+='<div class="bg-white rounded-2xl border p-5"><div class="text-xs text-gray-500">عملاء نشطون</div><div class="text-3xl font-black text-green-600 mt-2">'+customersData.filter(function(c){return c.is_active!==false;}).length+'</div></div>';
        html+='<div class="bg-white rounded-2xl border p-5"><div class="text-xs text-gray-500">إجمالي الذمم</div><div class="text-3xl font-black text-red-600 mt-2">'+_fmtNum(customersData.reduce(function(s,c){return s+Number(c.debt||0);},0))+' EGP</div></div>';
        html+='<div class="bg-white rounded-2xl border p-5"><div class="text-xs text-gray-500">تحتاج متابعة</div><div id="crm-open-count" class="text-3xl font-black text-amber-600 mt-2">—</div></div>';
        html+='</div>';
        html+='<div class="flex flex-col md:flex-row gap-3"><input id="crm-search" class="flex-1 p-3 bg-white border rounded-xl" placeholder="بحث بالاسم أو الكود أو الهاتف"><button id="crm-refresh" class="px-5 py-3 bg-indigo-600 text-white rounded-xl font-bold">تحديث</button></div>';
        html+='<div id="crm-customers-list" class="bg-white rounded-2xl border overflow-hidden">'+_table(customersData)+'</div></div>';
        safeHTML(container,html);

        var search=byId('crm-search');
        if(search) search.addEventListener('input',function(){var q=search.value.trim().toLowerCase();var filtered=customersData.filter(function(c){return !q||((c.name||'')+' '+(c.customer_code||'')+' '+(c.phone||'')).toLowerCase().indexOf(q)!==-1;});safeHTML(byId('crm-customers-list'),_table(filtered));_bindCustomerButtons();});
        var refresh=byId('crm-refresh'); if(refresh) refresh.addEventListener('click',render);
        _bindCustomerButtons();
        _loadOpenCount();
    }

    function _bindCustomerButtons(){
        var buttons=document.querySelectorAll('[data-crm-open]');
        for(var i=0;i<buttons.length;i++) buttons[i].addEventListener('click',function(){_openFollowupModal(this.getAttribute('data-crm-open'));});
    }

    async function _loadOpenCount(){
        var res=await supabase.from('customer_followups').select('id',{count:'exact',head:true}).eq('company_id',_companyId()).in('status',['Open','معلقة']);
        var el=byId('crm-open-count'); if(el) el.textContent=res.error?'—':String(res.count||0);
    }

    async function _openFollowupModal(customerCode){
        var cust=customersData.filter(function(c){return c.customer_code===customerCode;})[0];
        if(!cust){showToast('العميل غير موجود','error');return;}
        showLoader('جاري تحميل سجل المتابعة...');
        var res=await supabase.from('customer_followups').select('id,followup_date,followup_type,subject,notes,assigned_to,status,created_by,created_at,completed_at').eq('company_id',_companyId()).eq('customer_id',customerCode).order('followup_date',{ascending:false}).order('created_at',{ascending:false});
        hideLoader();
        if(res.error){showToast('فشل تحميل المتابعة: '+res.error.message,'error');return;}
        var followups=res.data||[];
        var html='<div class="text-right space-y-5">';
        html+='<div class="bg-indigo-50 rounded-2xl p-5"><div class="flex justify-between"><div><h3 class="font-black text-xl">'+_esc(cust.name)+'</h3><p class="text-sm text-gray-500">'+_esc(cust.customer_code)+'</p></div><div class="text-left font-black">'+_fmtNum(cust.debt)+' EGP</div></div><div class="flex gap-2 mt-3"><a href="tel:'+_escAttr(cust.phone||'')+'" class="px-4 py-2 bg-green-600 text-white rounded-xl text-xs font-bold">اتصال</a><a href="https://wa.me/'+_escAttr(String(cust.phone||'').replace(/\D/g,''))+'" target="_blank" rel="noopener" class="px-4 py-2 bg-emerald-600 text-white rounded-xl text-xs font-bold">واتساب</a></div></div>';
        html+='<div class="bg-white border rounded-2xl p-5"><h4 class="font-black mb-4">إضافة متابعة</h4><div class="grid grid-cols-1 md:grid-cols-4 gap-3"><input id="crm-date" type="date" class="p-2 border rounded" value="'+new Date().toISOString().slice(0,10)+'"><select id="crm-type" class="p-2 border rounded"><option value="Call">هاتف</option><option value="WhatsApp">واتساب</option><option value="Visit">زيارة</option><option value="Email">بريد</option><option value="Other">أخرى</option></select><select id="crm-status" class="p-2 border rounded"><option value="Open">مفتوحة</option><option value="completed">مكتملة</option><option value="cancelled">ملغاة</option></select><input id="crm-assigned" class="p-2 border rounded" placeholder="مسؤول المتابعة"></div><input id="crm-subject" class="w-full mt-3 p-2 border rounded" placeholder="موضوع المتابعة"><textarea id="crm-notes" class="w-full mt-3 p-2 border rounded" rows="3" placeholder="ملاحظات وتفاصيل الإجراء"></textarea><div class="flex justify-end mt-3"><button id="crm-save-followup" class="px-6 py-2 bg-indigo-600 text-white rounded-xl font-bold">حفظ المتابعة</button></div></div>';
        html+='<div class="bg-white border rounded-2xl p-5"><h4 class="font-black mb-3">السجل</h4>';
        if(!followups.length) html+='<div class="text-center py-6 text-gray-400">لا توجد متابعات سابقة</div>';
        for(var i=0;i<followups.length;i++){var f=followups[i];html+='<div class="border-t py-3"><div class="flex justify-between"><div><b>'+_esc(f.subject||f.followup_type||'متابعة')+'</b><div class="text-xs text-gray-500">'+_esc(f.followup_date)+' — '+_esc(f.assigned_to||'-')+'</div></div><span class="px-2 py-1 rounded-full text-xs font-bold '+(f.status==='completed'?'bg-green-100 text-green-700':f.status==='cancelled'?'bg-red-100 text-red-700':'bg-yellow-100 text-yellow-700')+'">'+_esc(f.status)+'</span></div><p class="text-sm mt-2">'+_esc(f.notes||'-')+'</p></div>';}
        html+='</div></div>';
        Swal.fire({title:'متابعة العميل: '+_esc(cust.name),html:html,width:'900px',showCloseButton:true,showConfirmButton:false,didOpen:function(){var save=byId('crm-save-followup');if(save)save.addEventListener('click',async function(){var current=(RW_STATE&&RW_STATE.app&&RW_STATE.app.currentUser)||{};var payload={customerCode:customerCode};var r=await supabase.rpc('crm_save_customer_followup',{p_customer_code:customerCode,p_followup_date:byId('crm-date').value,p_followup_type:byId('crm-type').value,p_status:byId('crm-status').value,p_subject:byId('crm-subject').value.trim()||null,p_notes:byId('crm-notes').value.trim()||null,p_assigned_to:byId('crm-assigned').value.trim()||current.email||null});if(r.error){showToast('فشل الحفظ: '+r.error.message,'error');return;}showToast('تم حفظ المتابعة','success');Swal.close();_openFollowupModal(customerCode);});}});
    }

    return {render:render,_openFollowupModal:_openFollowupModal};
})();
window.RW_CRM = RW_CRM;
// ============================================================
// EVENTS & BOOT
// ============================================================
function bindEvents() {
    try {
        var loginForm = byId('rw-login-form');
        if (loginForm) { loginForm.addEventListener('submit', function(e) { e.preventDefault(); RW_Auth.login(byId('rw-username').value, byId('rw-password').value); }); }
        var logoutBtn = byId('rw-logout-btn');
        if (logoutBtn) { logoutBtn.addEventListener('click', function() { RW_Auth.logout(); }); }
        var mobileBtn = byId('rw-mobile-menu-btn');
        if (mobileBtn) { mobileBtn.addEventListener('click', function() { var sidebar = byId('rw-sidebar'); if (sidebar) sidebar.classList.toggle('active'); }); }
        var collapseBtn = byId('rw-collapse-btn');
        if (collapseBtn) { collapseBtn.addEventListener('click', function() { RW_Navigation.toggleSidebar(); }); }
    } catch(e) { console.error(e); }
}

function boot() {
    try {
        console.log('RAWAEA ERP BOOTING...');
        bindEvents();
        
        // ✅ التحقق من وجود جلسة سابقة
        supabase.auth.getSession().then(function(res) {
            if (res.data && res.data.session) {
                console.log('✅ Session restored');
                var user = res.data.session.user;
                var meta = user.user_metadata || {};
                
                RW_STATE.app.authenticated = true;
                RW_STATE.app.currentUser = {
                    name: meta.name || user.email,
                    email: user.email,
                    role: meta.role || 'مدير النظام',
                    isOwner: meta.isOwner === true || meta.isOwner === 'true'
                };
                RW_STATE.permissions = meta.permissions || ['*'];
                RW_STATE.app.company = {
                    name: meta.companyName || 'الروائع ERP',
                    logo: meta.companyLogo || 'ر'
                };
                
                RW_Auth.enterSystem();
            }
        }).catch(function() {
            console.log('No session found');
        });
        
        RW_STATE.app.initialized = true;
        try { if (localStorage.getItem('rw_sidebar_collapsed') === '1') { setTimeout(function() { RW_Navigation.toggleSidebar(); }, 300); } } catch(e) {}
        console.log('SYSTEM READY');
    } catch(e) {
        console.error(e);
        document.body.innerHTML = '<div style="min-height:100vh;display:flex;align-items:center;justify-content:center;flex-direction:column;font-family:Cairo;"><h1>RAWAEA ERP</h1><p>BOOT ERROR</p></div>';
    }
}
document.addEventListener('DOMContentLoaded', boot);
window.resetPassword = function() {
    var email = byId('rw-username').value.trim();
    if (!email) {
        showToast('يرجى إدخال بريدك الإلكتروني أولاً في حقل اسم المستخدم', 'warning');
        return;
    }
    showLoader('جاري إرسال رابط إعادة التعيين...');
    supabase.auth.resetPasswordForEmail(email).then(function(res) {
        hideLoader();
        if (res.error) {
            showToast('فشل الإرسال: ' + res.error.message, 'error');
        } else {
            showToast('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني. راجع صندوق الوارد.', 'success');
        }
    }).catch(function(e) {
        hideLoader();
        showToast('فشل الاتصال', 'error');
    });
};
function generateQRInvoiceBase64(sellerName, vatNumber, invoiceDate, totalAmount, vatAmount) {
    var text = '';
    text += (sellerName || '') + '\n';
    text += (vatNumber || '') + '\n';
    text += (invoiceDate || '') + '\n';
    text += (totalAmount || '') + '\n';
    text += (vatAmount || '');

    var utf8Bytes = [];
    for (var i = 0; i < text.length; i++) {
        var charCode = text.charCodeAt(i);
        if (charCode < 0x80) {
            utf8Bytes.push(charCode);
        } else if (charCode < 0x800) {
            utf8Bytes.push(0xc0 | (charCode >> 6));
            utf8Bytes.push(0x80 | (charCode & 0x3f));
        } else if (charCode < 0xd800 || charCode >= 0xe000) {
            utf8Bytes.push(0xe0 | (charCode >> 12));
            utf8Bytes.push(0x80 | ((charCode >> 6) & 0x3f));
            utf8Bytes.push(0x80 | (charCode & 0x3f));
        } else {
            i++;
            charCode = 0x10000 + (((charCode & 0x3ff) << 10) | (text.charCodeAt(i) & 0x3ff));
            utf8Bytes.push(0xf0 | (charCode >> 18));
            utf8Bytes.push(0x80 | ((charCode >> 12) & 0x3f));
            utf8Bytes.push(0x80 | ((charCode >> 6) & 0x3f));
            utf8Bytes.push(0x80 | (charCode & 0x3f));
        }
    }
    var binary = '';
    for (var j = 0; j < utf8Bytes.length; j++) {
        binary += String.fromCharCode(utf8Bytes[j]);
    }
    return btoa(binary);
}
document.addEventListener('click', function(e) {
    var target = e.target;
    while (target && target !== document.body) {
        var email = target.getAttribute && target.getAttribute('data-email');
        if (email) {
            var wrapper = byId('emp-table-wrapper');
            if (wrapper && wrapper.contains(target)) {
                RW_Users._openModal(email);
                return;
            }
        }
        target = target.parentNode;
    }
});
})();
</script>
</body>
</html>
