/*
 * RAWAEA ERP — MAIN11 OWNER CORRECTION R2
 * Date: 2026-09-12
 * Source of Truth: Current/PWA/main2/main11.md
 * Current source SHA verified directly from Git: c4c954e9610c60182358a42665195d05cd3c3405
 *
 * OWNER ONLY: apply the exact surgical replacement below to main11.md.
 */

const MAIN11_OWNER_CORRECTION_R2_20260912 = {
  file: 'Current/PWA/main2/main11.md',
  source_sha: 'c4c954e9610c60182358a42665195d05cd3c3405',
  correction: {
    id: 'M11-03',
    line: '256',
    element: 'async function _setLeaveStatus(id,status,emp) { ... }',
    delete_instruction: 'في Current/PWA/main2/main11.md ابحث عن السطر 256 الذي يبدأ حرفيًا بـ async function _setLeaveStatus(id,status,emp) { . احذف الدالة كاملة من هذا السطر حتى القوس } الذي يسبق مباشرة السطر الكامل: async function _uploadDocument(emp) { . لا تحذف السطر async function _uploadDocument(emp) {.',
    replacement: `    async function _setLeaveStatus(id,status,emp) {
        var res=await supabase.rpc('hr_set_leave_status',{
            p_leave_request_id:id,
            p_status:status,
            p_notes:null
        });
        if(res.error){showToast('فشل تحديث الإجازة: '+res.error.message,'error');return;}
        showToast(status==='approved'?'تم اعتماد الإجازة':'تم رفض الإجازة','success');
        _openModal(emp.id);
    }`
  },
  reason: 'تحويل اعتماد/رفض الإجازة من UPDATE مباشر يتحكم فيه المتصفح إلى RPC مخصص يستمد Company Context والفاعل المعتمد من Session ويمنع تغيير طلب غير pending.'
};
