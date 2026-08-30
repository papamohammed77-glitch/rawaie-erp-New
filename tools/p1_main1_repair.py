from pathlib import Path
import re
import subprocess
import tempfile

PATH = Path('Current/PWA/main/main1.md')
MARKER = 'RAWAEA_P1_FORENSIC_CLOSED:v18'

s = PATH.read_text(encoding='utf-8')
if MARKER in s:
    print('MAIN1_ALREADY_CLOSED')
    raise SystemExit(0)


def replace_once(old: str, new: str, label: str) -> None:
    global s
    count = s.count(old)
    if count != 1:
        raise SystemExit(f'{label}_COUNT={count}')
    s = s.replace(old, new, 1)

replace_once(
    'window.RW_STATE = RW_STATE;',
    """window.RW_STATE = RW_STATE;

// RAWAEA GOVERNED TENANT CONTEXT
var RW_ShellContext=(function(){
    var companyId=null,userId=null,resolving=null;
    function applyUserIdentity(row,authUser){
        companyId=row.company_id||null;
        userId=row.id||null;
        RW_STATE.app.companyId=companyId;
        RW_STATE.app.userId=userId;
        if(RW_STATE.app.currentUser){
            RW_STATE.app.currentUser.id=userId;
            RW_STATE.app.currentUser.authId=(authUser&&authUser.id)||RW_STATE.app.currentUser.authId||null;
            RW_STATE.app.currentUser.companyId=companyId;
            if(row.name)RW_STATE.app.currentUser.name=row.name;
            if(row.role)RW_STATE.app.currentUser.role=row.role;
            RW_STATE.app.currentUser.isOwner=RW_STATE.app.currentUser.isOwner===true;
        }
        var dbPerms=Array.isArray(row.permissions)?row.permissions.slice():[];
        RW_STATE.permissions=(RW_STATE.app.currentUser&&RW_STATE.app.currentUser.isOwner===true)?['*']:dbPerms;
        return companyId;
    }
    function resolve(){
        if(companyId)return Promise.resolve(companyId);
        if(resolving)return resolving;
        if(!RW_SUPABASE_CLIENT)return Promise.reject(new Error('SUPABASE_CLIENT_UNAVAILABLE'));
        resolving=RW_SUPABASE_CLIENT.auth.getUser().then(function(r){
            if(r.error||!r.data||!r.data.user||!r.data.user.id)throw new Error('AUTH_ID_UNAVAILABLE');
            return r.data.user;
        }).then(function(authUser){
            return RW_SUPABASE_CLIENT.from('users').select('id,company_id,name,role,status,permissions').eq('auth_id',authUser.id).eq('status','Active').maybeSingle().then(function(r){
                if(r.error||!r.data||!r.data.company_id)throw new Error('TENANT_CONTEXT_UNAVAILABLE');
                return applyUserIdentity(r.data,authUser);
            });
        }).finally(function(){resolving=null;});
        return resolving;
    }
    function getCompanyId(){if(!companyId)throw new Error('TENANT_CONTEXT_UNAVAILABLE');return companyId;}
    return {resolve:resolve,getCompanyId:getCompanyId,hasCompany:function(){return !!companyId;}};
})();
window.RW_ShellContext=RW_ShellContext;""",
    'TENANT_CONTEXT'
)

replace_once(
    "email: user.email,\n                role: meta.role || 'مدير النظام',\n                isOwner: meta.isOwner === true || meta.isOwner === 'true'\n            };\n",
    "email: user.email,\n                authId: user.id,\n                companyId: null,\n                role: meta.role || 'مدير النظام',\n                isOwner: meta.isOwner === true || meta.isOwner === 'true'\n            };\n",
    'AUTH_USER'
)
replace_once(
    "RW_STATE.permissions = meta.permissions || ['*'];",
    "RW_STATE.permissions = (RW_STATE.app.currentUser && RW_STATE.app.currentUser.isOwner === true) ? ['*'] : (Array.isArray(meta.permissions) ? meta.permissions.slice() : []);",
    'OWNER_PERMISSIONS'
)

replace_once('enterSystem: function() {', 'enterSystem: async function() {', 'ENTER_ASYNC')
replace_once(
    'self.enterSystem();',
    "self.enterSystem().catch(function(e){ console.error('ENTER_SYSTEM_FAILED',e); });",
    'ENTER_CALL'
)
replace_once(
    'enterSystem: async function() {\n    hideLoader();',
    """enterSystem: async function() {
    try {
        await RW_ShellContext.resolve();
    } catch(e) {
        console.error('TENANT_CONTEXT_FAILED', e);
        this.forceEnterFallback();
        return;
    }
    hideLoader();""",
    'ENTER_RESOLVE'
)

replace_once(
    ".from('app_settings')\n            .select('*')\n            .limit(1)",
    ".from('app_settings')\n            .select('*')\n            .eq('company_id',RW_ShellContext.getCompanyId())\n            .limit(1)",
    'APP_SETTINGS'
)

for table, needle, replacement in (
    ('suppliers', "supabase.from('suppliers').select('*').then(function(r)", "supabase.from('suppliers').select('*').eq('company_id',RW_ShellContext.getCompanyId()).then(function(r)"),
    ('items', "return supabase.from('items').select('*').then(function(res)", "return supabase.from('items').select('*').eq('company_id',RW_ShellContext.getCompanyId()).then(function(res)"),
    ('customers', "return supabase.from('customers').select('*').then(function(res)", "return supabase.from('customers').select('*').eq('company_id',RW_ShellContext.getCompanyId()).then(function(res)"),
    ('branches', "return supabase.from('branches').select('*').then(function(res)", "return supabase.from('branches').select('*').eq('company_id',RW_ShellContext.getCompanyId()).then(function(res)"),
):
    replace_once(needle, replacement, f'BOOTSTRAP_{table.upper()}')

fallback_pattern = re.compile(r"forceEnterFallback:\s*function\(\)\s*\{.*?\n\s*\},\s*logout:\s*function", re.S)
fallback_replacement = """forceEnterFallback: function() {
        hideLoader();
        try {
            RW_STATE.app.authenticated = false;
            byId('rw-main-shell').style.display = 'none';
            byId('rw-login-page').style.display = 'flex';
            showToast('تعذر تحديد سياق الشركة الآمن. لم يتم تشغيل النظام.', 'error');
        } catch(e) {
            console.error('FAIL_CLOSED_TENANT_CONTEXT', e);
        }
    }, logout: function"""
s, fallback_count = fallback_pattern.subn(fallback_replacement, s, count=1)
if fallback_count != 1:
    raise SystemExit(f'FAIL_CLOSED_COUNT={fallback_count}')

# P1 shell must not contain any independent Physical Stock / inventory-log writer.
if re.search(r"supabase\.from\(['\"]stock_branches['\"]\)[^;]{0,1600}\.(?:update|insert|upsert|delete)\(", s, re.S):
    raise SystemExit('DIRECT_STOCK_WRITER')
if re.search(r"supabase\.from\(['\"]inventory_log['\"]\)[^;]{0,900}\.insert\(", s, re.S):
    raise SystemExit('DIRECT_INVENTORY_LOG_WRITER')

# Complete JS syntax check for this split part.
code = '\n'.join(re.findall(r'<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>', s, re.S | re.I))
js = Path(tempfile.gettempdir()) / 'rawaea-main1-p1.js'
js.write_text(code, encoding='utf-8')
subprocess.run(['node', '--check', str(js)], check=True)

PATH.write_text(s.rstrip() + '\n<!-- ' + MARKER + ' -->\n', encoding='utf-8')
subprocess.run(['git', 'diff', '--check'], check=True)
print(f'REPAIRED_BYTES={PATH.stat().st_size}')
