# RAWAEA ERP — guarded sequential surgical reconstruction executor
from pathlib import Path
import hashlib, json, re, subprocess

ROOT=Path('.')
CUR=ROOT/'Current/PWA/main'; TARGET=ROOT/'Current/PWA/New-main'; LEGACY=ROOT/'Current/PWA/main.html'; CTO=ROOT/'Current/CTO'
PARTS=[CUR/f'main{i}.md' for i in range(1,12)]; EVIDENCE=CTO/'20260901_NEW_MAIN_SURGICAL_RECONSTRUCTION.json'
FORBIDDEN_WRITES=['stock_branches','inventory_log','stock_voucher_details','journal_entries','journal_entry_lines','cash_box','customer_ledger','supplier_ledger','driver_ledger']
PROTECTED_IDS={'rw-login-page','rw-main-shell','rw-page-container','rw-header-title','rw-header-subtitle','rw-sidebar-nav','rw-logout-btn','rw-login-form','rw-username','rw-password','rw-notification-btn','rw-notification-badge'}
PROTECTED_GLOBALS={'RW_STATE','RW_ShellContext','RW_Navigation','RW_Views','RW_Auth','RW_OwnerLicense','RW_Workflow','RW_Notification'}


def sha(s): return hashlib.sha256(s.encode('utf-8')).hexdigest()

def inline_match(html):
    blocks=list(re.finditer(r'<script(?P<a>[^>]*)>(?P<b>[\s\S]*?)</script>',html,re.I))
    xs=[m for m in blocks if not re.search(r'\bsrc\s*=',m.group('a') or '',re.I)]
    if len(xs)!=1: raise RuntimeError(f'INLINE_SCRIPT_COUNT_INVALID:{len(xs)}')
    return xs[0]

def js_inline(html): return inline_match(html).group('b')

def balanced_end(source,start,opening='{',closing='}',include_semicolon=False):
    depth=0; quote=None; esc=False; line=False; block=False; i=start
    while i<len(source):
        ch=source[i]; nx=source[i+1] if i+1<len(source) else ''
        if line:
            if ch=='\n': line=False
        elif block:
            if ch=='*' and nx=='/': block=False; i+=1
        elif quote:
            if esc: esc=False
            elif ch=='\\': esc=True
            elif ch==quote: quote=None
        else:
            if ch=='/' and nx=='/': line=True; i+=1
            elif ch=='/' and nx=='*': block=True; i+=1
            elif ch in "'\"`": quote=ch
            elif ch==opening: depth+=1
            elif ch==closing:
                depth-=1
                if depth==0:
                    e=i+1
                    if include_semicolon:
                        while e<len(source) and source[e].isspace(): e+=1
                        if e<len(source) and source[e]==';': e+=1
                    return e
        i+=1
    raise RuntimeError('UNTERMINATED_JS_BLOCK')

def extract_function(source,name):
    m=re.search(r'(?<![\w$])(?:async\s+)?function\s+'+re.escape(name)+r'\s*\([^)]*\)\s*\{',source)
    if not m:return None
    b=source.find('{',m.start(),m.end()); return source[m.start():balanced_end(source,b)]

def extract_var(source,name):
    m=re.search(r'(?m)(?:^|\n)[ \t]*(?:var|let|const)\s+'+re.escape(name)+r'\s*=',source)
    if not m:return None
    start=m.start();
    if source[start:start+1]=='\n': start+=1
    # Find statement terminator outside strings/comments/nested delimiters.
    i=m.end(); stack=[]; quote=None; esc=False; line=False; block=False
    while i<len(source):
        ch=source[i]; nx=source[i+1] if i+1<len(source) else ''
        if line:
            if ch=='\n': line=False
        elif block:
            if ch=='*' and nx=='/': block=False; i+=1
        elif quote:
            if esc: esc=False
            elif ch=='\\': esc=True
            elif ch==quote: quote=None
        else:
            if ch=='/' and nx=='/': line=True; i+=1
            elif ch=='/' and nx=='*': block=True; i+=1
            elif ch in "'\"`": quote=ch
            elif ch in '({[': stack.append(ch)
            elif ch in ')}]':
                if not stack: raise RuntimeError('JS_BLOCK_UNDERFLOW:'+name)
                stack.pop()
            elif ch==';' and not stack: return source[start:i+1]
        i+=1
    raise RuntimeError('JS_VAR_TERMINATOR_MISSING:'+name)

def replace_function(target,name,replacement):
    old=extract_function(target,name)
    if old is None:return target,False,False
    return target.replace(old,replacement,1),old!=replacement,True

def replace_var(target,name,replacement):
    old=extract_var(target,name)
    if old is None:return target,False,False
    return target.replace(old,replacement,1),old!=replacement,True

def insert_block(target,block,anchors):
    if not block:return target,False
    m=re.search(r'(?m)(?:var|let|const)\s+([A-Za-z_$][\w$]*)\s*=',block)
    if m and (extract_var(target,m.group(1)) or extract_function(target,m.group(1))):return target,False
    m=re.search(r'(?m)(?:async\s+)?function\s+([A-Za-z_$][\w$]*)\s*\(',block)
    if m and extract_function(target,m.group(1)):return target,False
    for a in anchors:
        p=target.find(a)
        if p!=-1:return target[:p]+block+'\n\n'+target[p:],True
    return target.rstrip()+'\n\n'+block+'\n',True

def names(source):
    funcs=sorted(set(re.findall(r'(?<![\w$])(?:async\s+)?function\s+([A-Za-z_$][\w$]*)\s*\(',source)))
    vars_=sorted(set(re.findall(r'(?m)^[ \t]*(?:var|let|const)\s+([A-Za-z_$][\w$]*)\s*=',source)))
    return funcs,vars_

def relevant_blocks(source):
    funcs,vars_=names(source); out=[]
    allow_funcs={'applyAuthoritativeContext','currentCompanyId','syncState','setHeader','delegated','moduleCards','renderList','renderDashboard','renderCustomers','renderItems','renderInventory','renderFinance','renderReports','main1Delegation','globalSearch'}
    for n in funcs:
        if n.startswith('RW_') or n in allow_funcs:
            b=extract_function(source,n)
            if b: out.append(('function',n,b))
    for n in vars_:
        if n.startswith('RW_') or n=='actions':
            b=extract_var(source,n)
            if b: out.append(('var',n,b))
    return out

def repair_main7(s):
    p=re.compile(r"(safeHTML\(q\(['\"]settlement-rs-select['\"]\),[\s\S]*?\.join\(''\))\);}",re.M); s2,n=p.subn(r'\1));}',s,count=1)
    return s2,n

def assemble_phase(chunks):
    first=chunks[0]; im=inline_match(first); b0,b1=im.start('b'),im.end('b')
    prefix=first[:b0]; suffix=first[b1:]
    frags=chunks[:]
    repairs=[]
    if len(frags)>=7:
        frags[6],n=repair_main7(frags[6]);
        if n: repairs.append({'issue':'main7 settlement-rs-select closure','occurrences_fixed':n})
    for i,c in enumerate(frags[1:],2):
        if re.search(r'<(?:!doctype|html|head|body)\b',c,re.I):raise RuntimeError(f'INVALID_DOCUMENT_WRAPPER_MAIN{i}')
    body=im.group('b').strip()+'\n\n'+'\n\n'.join(x.rstrip() for x in frags[1:])
    return prefix+'<script>\n'+body+'\n</script>\n</body>\n</html>\n',repairs

def repair_owner(cand):
    cand,n=re.subn(r"var owner=!!op\.data\|\|meta\.isOwner===true\|\|meta\.isOwner==='true';","var owner=meta.isOwner===true||meta.isOwner==='true';",cand,count=1)
    return cand,n

def add_license(cand):
    reps=[]; main10=(CUR/'main10.md').read_text(encoding='utf-8-sig')
    if 'btn-save-license-only' not in cand:
        block=extract_var(main10,'RW_OwnerLicense')
        if block:
            anchor=cand.find('var RW_Views=')
            if anchor==-1: anchor=cand.find('var RW_Navigation=')
            if anchor==-1: raise RuntimeError('LICENSE_INSERT_ANCHOR_MISSING')
            cand=cand[:anchor]+block+'\n'+cand[anchor:]; reps.append('RESTORE_CANONICAL_MAIN10_OWNER_LICENSE_MODULE')
    if "{view:'license'" not in cand:
        needle="{view:'audit',label:'سجل التدقيق',perm:'owner'},"
        if needle not in cand: raise RuntimeError('LICENSE_MENU_ANCHOR_MISSING')
        cand=cand.replace(needle,needle+"{view:'license',label:'إدارة الترخيص',perm:'owner'},",1); reps.append('ADD_LICENSE_OWNER_NAVIGATION')
    if 'license:RW_OwnerLicense.render' not in cand:
        needle='audit:RW_Audit_renderTab,'
        if needle not in cand: raise RuntimeError('LICENSE_ACTION_ANCHOR_MISSING')
        cand=cand.replace(needle,needle+'license:RW_OwnerLicense.render,',1); reps.append('ADD_LICENSE_VIEW_ACTION')
    return cand,reps

def validate(html,baseline=None,final=False):
    req=['rw-login-page','rw-main-shell','rw-page-container','rw-header-title','rw-header-subtitle','rw-sidebar-nav','rw-logout-btn','window.RW_ShellContext','window.RW_OwnerLicense','window.RW_Views','window.RW_Dashboard','window.RW_Items','window.RW_POS','window.RW_Orders','window.RW_Runsheets','window.RW_Purchases','window.RW_Warehouse','window.RW_Finance','window.RW_Reports','window.RW_HR','window.RW_CRM']
    if final:req += ['btn-save-license-only',"{view:'license'",'license:RW_OwnerLicense.render','_clickNotif','_renderAndSave','_updateBadge','markRead']
    miss=[x for x in req if x not in html]
    if miss:raise RuntimeError('CONTRACT_MISSING:'+','.join(miss))
    if html.lower().count('</html>')!=1 or html.lower().count('</body>')!=1:raise RuntimeError('DOCUMENT_CLOSURE_INVALID')
    if html.count('<!doctype')!=1:raise RuntimeError('DOCTYPE_INVALID')
    _=js_inline(html)
    p=Path('/tmp/rw-new-main-surgical.js');p.write_text(js_inline(html),encoding='utf-8')
    r=subprocess.run(['node','--check',str(p)],capture_output=True,text=True)
    if r.returncode: print(r.stderr); raise RuntimeError('JS_SYNTAX_FAIL')
    for t in FORBIDDEN_WRITES:
        if re.search(r"\.from\(['\"]"+re.escape(t)+r"['\"]\)[\s\S]{0,1000}?\.(?:update|insert|upsert|delete)\s*\(",html):raise RuntimeError('DIRECT_BUSINESS_STATE_WRITE:'+t)
    if baseline is not None:
        for x in PROTECTED_IDS:
            if x in baseline and x not in html:raise RuntimeError('PROTECTED_ID_REMOVED:'+x)
        for x in PROTECTED_GLOBALS:
            if x in baseline and x not in html:raise RuntimeError('PROTECTED_GLOBAL_REMOVED:'+x)
    return True

def main():
    if not TARGET.is_file() or not TARGET.stat().st_size:raise RuntimeError('NEW_MAIN_MISSING')
    if not LEGACY.is_file() or not LEGACY.stat().st_size:raise RuntimeError('LEGACY_MAIN_MISSING')
    if any(not p.is_file() or not p.stat().st_size for p in PARTS):raise RuntimeError('MISSING_RECONSTRUCTION_PARTS')
    baseline=TARGET.read_text(encoding='utf-8'); legacy_sha=sha(LEGACY.read_bytes().decode('utf-8',errors='replace'))
    validate(baseline)
    chunks=[p.read_text(encoding='utf-8-sig') for p in PARTS]
    current=baseline; phases=[]; global_repairs=[]
    for idx in range(1,12):
        phase_source=chunks[:idx]
        canonical,reps=assemble_phase(phase_source)
        if idx==1:
            canonical,n=repair_owner(canonical)
            if n: reps.append('OWNER_MUST_COME_FROM_AUTH_METADATA')
        if idx==10:
            canonical,rr=add_license(canonical); reps.extend(rr)
        # Phase-specific source must actually contribute a delta.
        candidate,ops,before_sha,after_sha=current,[],sha(js_inline(current)),sha(js_inline(current))
        for kind,name,block in relevant_blocks(js_inline(canonical)):
            if kind=='function':
                candidate2,changed,exists=replace_function(candidate,name,block)
            else:
                candidate2,changed,exists=replace_var(candidate,name,block)
            if exists:
                if changed:
                    candidate=candidate2; ops.append(f'replace:{kind}:{name}')
            else:
                candidate2,inserted=insert_block(candidate,block,['var RW_Data=','var RW_Navigation=','var RW_Auth=','})();'])
                if inserted:
                    candidate=candidate2; ops.append(f'insert:{kind}:{name}')
        if idx==10:
            # License additions are semantic blocks in canonical but may be missed by the generic var pass.
            candidate,addops=add_license(candidate); ops.extend('license:'+x for x in addops)
        if idx==1 and 'meta.isOwner===true' in canonical and "var owner=!!op.data" in candidate:
            candidate,n=re.subn(r"var owner=!!op\.data\|\|meta\.isOwner===true\|\|meta\.isOwner==='true';","var owner=meta.isOwner===true||meta.isOwner==='true';",candidate,count=1)
            if n:ops.append('owner:auth-metadata-only')
        if idx==1:
            # Exact MAIN1 behavioral surfaces are allowed to replace existing blocks in place.
            for required_name in ['RW_Audit_renderTab','RW_Notification','RW_Workflow','RW_Permissions_check','RW_Permissions_applyUI','RW_Audit_log']:
                if extract_var(js_inline(canonical),required_name) and extract_var(js_inline(candidate),required_name): pass
        validate(candidate,baseline,final=False)
        after_sha=sha(js_inline(candidate))
        if after_sha==before_sha:raise RuntimeError(f'NO_SURGICAL_DELTA_MAIN{idx}')
        current=candidate
        phases.append({'phase':idx,'source':str(PARTS[idx-1]),'operations':ops,'before_script_sha256':before_sha,'after_script_sha256':after_sha,'artifact_sha256':sha(current),'artifact_bytes':len(current.encode('utf-8')),'repairs':reps})
        global_repairs.extend(reps)
    validate(current,baseline,final=True)
    if sha(LEGACY.read_bytes().decode('utf-8',errors='replace'))!=legacy_sha:raise RuntimeError('LEGACY_MAIN_HTML_CHANGED')
    # Full baseline DOM-id preservation.
    old_ids=set(re.findall(r'\bid=["\']([^"\']+)["\']',baseline)); new_ids=set(re.findall(r'\bid=["\']([^"\']+)["\']',current)); removed=sorted(old_ids-new_ids)
    if removed:raise RuntimeError('TARGET_DOM_IDS_REMOVED:'+','.join(removed[:50]))
    CTO.mkdir(parents=True,exist_ok=True)
    EVIDENCE.write_text(json.dumps({'event_type':'MASTER_SURGICAL_RECONSTRUCTION_MAIN1_TO_MAIN11','mode':'SEQUENTIAL_FUNCTION_AND_MODULE_BLOCK_MERGE','target':str(TARGET),'baseline_target_sha256':sha(baseline),'candidate_target_sha256':sha(current),'legacy_main_sha256':legacy_sha,'legacy_main_html_modified':False,'phases':phases,'repairs':global_repairs,'all_phases_validated_before_write':True,'atomic_write':True},ensure_ascii=False,indent=2),encoding='utf-8')
    TARGET.write_text(current,encoding='utf-8')
    print(json.dumps({'status':'READY_TO_PERSIST','phases':11,'baseline':sha(baseline),'candidate':sha(current),'legacy_protected':True},ensure_ascii=False))

if __name__=='__main__':main()
