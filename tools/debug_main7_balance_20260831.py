from pathlib import Path

s=Path('Current/PWA/main/main7.md').read_text(encoding='utf-8-sig')
broken=".join(''));}\n  async function _onSettlementRsChange()"
fixed=".join('')));}\n  async function _onSettlementRsChange()"
if broken not in s:
    raise SystemExit('EXPECTED_MAIN7_SETTLEMENT_PATTERN_NOT_FOUND')
s=s.replace(broken,fixed,1)

stack=[]; i=0; line=1; col=0; in_str=None; esc=False; in_line=False; in_block=False
pairs={')':'(',']':'[','}':'{'}; opens=set(pairs.values())
while i<len(s):
    ch=s[i]; nxt=s[i+1] if i+1<len(s) else ''
    col+=1
    if ch=='\n': line+=1; col=0; in_line=False; i+=1; continue
    if in_line: i+=1; continue
    if in_block:
        if ch=='*' and nxt=='/': in_block=False; i+=2; col+=1; continue
        i+=1; continue
    if in_str:
        if esc: esc=False
        elif ch=='\\': esc=True
        elif ch==in_str: in_str=None
        i+=1; continue
    if ch in ('"',"'",'`'): in_str=ch; i+=1; continue
    if ch=='/' and nxt=='/': in_line=True; i+=2; col+=1; continue
    if ch=='/' and nxt=='*': in_block=True; i+=2; col+=1; continue
    if ch in opens: stack.append((ch,line,col,i))
    elif ch in pairs:
        if not stack or stack[-1][0]!=pairs[ch]:
            print('FIRST_MISMATCH',line,col,i,'got',ch,'top',stack[-1] if stack else None)
            print(s[max(0,i-700):i+700])
            raise SystemExit(2)
        stack.pop()
    i+=1
print('BALANCE_STACK_REMAINDER',len(stack))
if stack: print(stack[-20:])
