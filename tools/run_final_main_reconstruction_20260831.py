from pathlib import Path
import hashlib
import re
import subprocess
import tempfile
from html.parser import HTMLParser

MAIN=Path('Current/PWA/New-main'); CUR=Path('Current/PWA/main')
PARTS=[CUR/f'main{i}.md' for i in range(1,12)]
AUTH='/* RAWAEA MAIN2 AUTHORITATIVE MODULE */'; COMPAT='/* RAWAEA MAIN2 COMPATIBILITY */'
VERSION="window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';"; GOVERNED='// MAIN2_GOVERNED_CLOSED:v1'
CANONICAL_SW="navigator.serviceWorker.register('./sw.js',{scope:'./'})"; INLINE_RE=re.compile(r'<script(?![^>]*\bsrc\s*=)[^>]*>',re.I)
P1_FORENSIC_MARKER=re.compile(r'(?m)^\s*<!--\s*RAWAEA_P1_FORENSIC_CLOSED:[^>]*-->\s*$',re.I); HTML_COMMENT_TAIL=re.compile(r'<!--(?:[\s\S]*?)-->\s*$',re.I)

def normalize_main1(raw):
    raw=raw.lstrip('\ufeff'); raw=re.sub(r'(?m)^\s*const RW_Auth\s*=\s*','var RW_Auth = ',raw,count=1); raw=re.sub(r'(?m)^\s*const RW_Navigation\s*=\s*','var RW_Navigation = ',raw,count=1)
    opens=list(INLINE_RE.finditer(raw))
    if not opens: raise RuntimeError('MAIN1_INLINE_RUNTIME_OPENER_MISSING')
    app_open=opens[-1]; prefix=raw[:app_open.start()]; body=raw[app_open.start():]; body=P1_FORENSIC_MARKER.sub('',body); body=HTML_COMMENT_TAIL.sub('',body)
    return prefix+body.rstrip()

def normalize_fragment(raw,idx):
    raw=raw.lstrip('\ufeff')
    if idx==2:
        start=raw.find('    function _openCategoryModal(){'); end=raw.find('    function _addCategory',start)
        if start<0 or end<0 or end<=start: raise RuntimeError('MAIN2_CATEGORY_FUNCTION_BOUNDARY_MISSING')
        replacement='''    function _openCategoryModal(){
        supabase.from('categories').select('id, category_name').eq('company_id',_rwCompanyId()).order('category_name').then(function(res){
            var categories=res.data||[];
            var html='<div class="text-right" dir="rtl"><h3 class="font-bold text-lg mb-3">🗂️ إدارة التصنيفات</h3>';
            if(categories.length===0)html+='<div class="text-center py-6 text-gray-400">لا توجد تصنيفات</div>';else{html+='<div class="max-h-48 overflow-y-auto mb-4 space-y-1">';for(var i=0;i<categories.length;i++){var catId=categories[i].id,catName=categories[i].category_name||'';html+='<button type="button" data-rw-category-edit="'+_esc(String(catId))+'" data-rw-category-name="'+_esc(catName)+'" class="w-full flex justify-between items-center p-2 bg-gray-50 rounded-lg cursor-pointer hover:bg-indigo-50 text-right"><span class="font-bold text-sm">'+_esc(catName)+'</span></button>';}html+='</div>';}
            html+='<div class="flex gap-2 mt-3"><input type="text" id="new-category-name" class="flex-1 p-2.5 border rounded-lg text-sm" placeholder="اسم التصنيف الجديد"><button type="button" data-rw-category-add="1" class="bg-indigo-600 text-white px-4 py-2 rounded-lg font-bold text-sm whitespace-nowrap">إضافة</button></div></div>';
            Swal.fire({title:'',html:html,width:'500px',showCloseButton:true,showConfirmButton:false,customClass:{popup:'!rounded-3xl'}});var popup=Swal.getPopup();if(!popup)return;
            var editButtons=popup.querySelectorAll('[data-rw-category-edit]');for(var e=0;e<editButtons.length;e++){(function(btn){btn.addEventListener('click',function(){RW_Items._editCategory(btn.getAttribute('data-rw-category-edit'),btn.getAttribute('data-rw-category-name')||'');});})(editButtons[e]);}var addButton=popup.querySelector('[data-rw-category-add]');if(addButton)addButton.addEventListener('click',function(){RW_Items._addCategory();});
        });
    }
'''
        raw=raw[:start]+replacement+raw[end:]
    if idx==7:
        defect=".join(''));}"; count=raw.count(defect)
        if count!=1: raise RuntimeError('MAIN7_EXPECTED_SETTLEMENT_SYNTAX_DEFECT_COUNT:'+str(count))
        raw=raw.replace(defect,".join('')));}",1)
    return raw.rstrip()

def extract_main1_application_js(chunk):
    opens=list(INLINE_RE.finditer(chunk))
    if not opens: raise RuntimeError('MAIN1_INLINE_RUNTIME_MISSING')
    app_open=opens[-1]; close=chunk.rfind('</script>'); end=close if close>=app_open.end() else len(chunk)
    return chunk[app_open.end():end]

def p163(s):
    if s.count(COMPAT)>1: raise RuntimeError('P163_COMPAT_DUPLICATE')
    if COMPAT in s:
        a=s.index(COMPAT); b=s.find(AUTH,a+len(COMPAT))
        if b<0: raise RuntimeError('P163_AUTH_AFTER_COMPAT_MISSING')
        s=s[:a]+s[b:]
    if AUTH not in s:
        m=re.search(r'(?m)^\s*var\s+RW_Dashboard\s*=\s*',s)
        if not m: raise RuntimeError('MAIN2_DASHBOARD_ANCHOR_MISSING')
        s=s[:m.start()]+AUTH+'\n'+s[m.start():]
    if s.count(AUTH)!=1: raise RuntimeError('P163_AUTH_COUNT:'+str(s.count(AUTH)))
    s=re.sub(r'window\.RW_Dashboard\s*=\s*\{\s*render\s*:\s*renderDashboard\s*\}\s*;?','',s,count=1); s=re.sub(r'window\.RW_Items\s*=\s*\{\s*render\s*:\s*renderItems\s*\}\s*;?','',s,count=1); s=re.sub(r'window\.RW_Items\s*=\s*RW_Items\s*;','window.RW_Items=RW_Items;',s,count=1); s=s.replace(VERSION,'').replace(GOVERNED,'')
    if s.count('window.RW_Items=RW_Items;')!=1: raise RuntimeError('P163_ITEMS_OWNER_COUNT')
    owner=s.index('window.RW_Items=RW_Items;')+len('window.RW_Items=RW_Items;'); return s[:owner]+'\n'+VERSION+'\n'+GOVERNED+s[owner:]

def inject_canonical_sw(s):
    legacy=re.compile(r"if\s*\(\s*['\"]serviceWorker['\"]\s*in\s*navigator\s*\)\s*navigator\.serviceWorker\.register\(\s*['\"]\./sw\.js['\"]\s*,\s*\{\s*scope\s*:\s*['\"]\./['\"]\s*\}\s*\)\s*\.catch\(\s*function\(e\)\s*\{\s*console\.warn\(\s*['\"]SERVICE_WORKER['\"]\s*,\s*e\s*\)\s*\}\s*\)\s*;?",re.I); s=legacy.sub('',s)
    bare=re.compile(r"navigator\.serviceWorker\.register\(\s*['\"]\./sw\.js['\"]\s*,\s*\{\s*scope\s*:\s*['\"]\./['\"]\s*\}\s*\)\s*;?",re.I); s=bare.sub('',s)
    if 'navigator.serviceWorker.register' in s: raise RuntimeError('UNEXPECTED_SERVICE_WORKER_REGISTRATION_FORM')
    body=s.lower().rfind('</body>')
    if body<0: raise RuntimeError('BODY_CLOSE_MISSING')
    tag="<script>if('serviceWorker' in navigator){navigator.serviceWorker.register('./sw.js',{scope:'./'}).catch(function(e){console.warn('SERVICE_WORKER',e)})}</script>\n"; return s[:body]+tag+s[body:]

class StructureParser(HTMLParser):
    def __init__(self): super().__init__(convert_charrefs=False); self.starts=[]; self.ends=[]
    def handle_starttag(self,tag,attrs): self.starts.append(tag.lower())
    def handle_startendtag(self,tag,attrs): self.starts.append(tag.lower())
    def handle_endtag(self,tag): self.ends.append(tag.lower())

def validate_fragments(parts):
    if not parts or not parts[0].lstrip().lower().startswith('<!doctype html>'): raise RuntimeError('MAIN1_HTML_SHELL_MISSING')
    if not INLINE_RE.search(parts[0]): raise RuntimeError('MAIN1_OPEN_SCRIPT_BOUNDARY_MISSING')
    return [{'part':i,'bytes':len(p.encode()),'lines':p.count('\n')+1} for i,p in enumerate(parts,1)]

def full_syntax_gate(parts):
    # P163 closes the intentionally-open compatibility IIFE between Main2 and authoritative Main2.
    js=extract_main1_application_js(parts[0])+'\n\n'+'\n\n'.join(parts[1:])+'\n'
    a=js.find(COMPAT); b=js.find(AUTH,a+len(COMPAT)) if a>=0 else -1
    if a<0 or b<0: raise RuntimeError('P163_TEMP_BOUNDARY_MARKERS_MISSING')
    if '})();' not in js[a:b]: js=js[:b]+'\n})();\n'+js[b:]
    probe=Path(tempfile.gettempdir())/'rawaea-full-runtime.js'; probe.write_text(js,encoding='utf-8'); r=subprocess.run(['node','--check',str(probe)],capture_output=True,text=True)
    if r.returncode: raise RuntimeError('FULL_ASSEMBLY_JS_FAIL\n'+r.stderr)
    return {'through':11,'bytes':len(js.encode()),'status':'PASS'}

def _app_js(s):
    apps=[m.group(1) for m in re.finditer(r'<script(?![^>]*\bsrc\s*=)[^>]*>([\s\S]*?)</script>',s,re.I) if 'serviceWorker.register' not in m.group(1)]
    if len(apps)!=1: raise RuntimeError('APPLICATION_INLINE_SCRIPT_COUNT:'+str(len(apps)))
    return apps[0]

def validate(s):
    start=s.lstrip().lower(); required=['window.RW_Auth','window.RW_Navigation','window.RW_Views','window.RW_OwnerLicense','var RW_Dashboard','var RW_Items','window.RW_Items=RW_Items;','RW_SUPABASE_CLIENT','MAIN3']; missing=[x for x in required if x not in s]
    if missing: raise RuntimeError('CURRENT_CONTRACT_MISSING:'+repr(missing))
    parser=StructureParser(); parser.feed(s); parser.close(); ah=parser.starts.count('html'); eh=parser.ends.count('html'); ab=parser.starts.count('body'); eb=parser.ends.count('body'); ass=parser.starts.count('script'); ess=parser.ends.count('script'); ast=parser.starts.count('style'); est=parser.ends.count('style')
    gates={'doctype_start':start.startswith('<!doctype html>'),'one_html_root':ah==1 and eh==1,'one_body_root':ab==1 and eb==1,'script_balance':ass==ess,'style_balance':ast==est,'auth_one':s.count(AUTH)==1,'version_one':s.count(VERSION)==1,'governed_one':s.count(GOVERNED)==1,'compat_absent':COMPAT not in s,'dash_alias_absent':not re.search(r'window\.RW_Dashboard\s*=\s*\{\s*render\s*:\s*renderDashboard\s*\}',s),'items_alias_absent':not re.search(r'window\.RW_Items\s*=\s*\{\s*render\s*:\s*renderItems\s*\}',s),'dash_owner_one':len(re.findall(r'(?m)^\s*var\s+RW_Dashboard\s*=\s*',s))==1,'items_owner_one':len(re.findall(r'(?m)^\s*var\s+RW_Items\s*=\s*',s))==1,'items_export_one':s.count('window.RW_Items=RW_Items;')==1,'canonical_sw_one':s.count(CANONICAL_SW)==1,'rpc_present':'.rpc(' in s,'edge_present':'/functions/v1/' in s}; bad=[k for k,v in gates.items() if not v]
    if bad: raise RuntimeError(f'P163_GOLD_GATE_FAIL:{bad} structural html={ah}/{eh} body={ab}/{eb} script={ass}/{ess} style={ast}/{est}')
    app=_app_js(s); path=Path(tempfile.gettempdir())/'rawaea-new-main.js'; path.write_text(app,encoding='utf-8'); r=subprocess.run(['node','--check',str(path)],capture_output=True,text=True)
    if r.returncode: print(r.stderr); raise RuntimeError('FINAL_JS_SYNTAX_FAIL')
    return gates

def main():
    parts=[]
    for idx,p in enumerate(PARTS,1):
        if not p.is_file() or not p.stat().st_size: raise RuntimeError('MISSING_PART:'+str(idx))
        raw=p.read_text(encoding='utf-8-sig'); parts.append(normalize_main1(raw) if idx==1 else normalize_fragment(raw,idx))
    phase_report=validate_fragments(parts); full_syntax=full_syntax_gate(parts)
    candidate=parts[0]+'\n\n'+'\n\n'.join(parts[1:])+'\n\n</script>\n</body>\n</html>\n'; candidate=p163(candidate); candidate=inject_canonical_sw(candidate); gates=validate(candidate)
    tmp=MAIN.with_suffix('.tmp'); tmp.write_text(candidate,encoding='utf-8'); tmp.replace(MAIN)
    print({'status':'NEW_MAIN_GOLD_DIAMOND_READY','target':str(MAIN),'sha256':hashlib.sha256(candidate.encode()).hexdigest(),'bytes':len(candidate.encode()),'gates':gates,'phase_report':phase_report,'full_syntax':full_syntax})

if __name__=='__main__': main()
