# 氐土狢.svg 单独转换（狢为异体字）
import os
import subprocess

BASE = r'D:\nutstore\HarmonyOS\GuoXue_Research\YanQinCompass'
svg_dir = os.path.join(BASE, '规则', '二十八星宿图')
out_dir = os.path.join(BASE, 'entry', 'src', 'main', 'resources', 'base', 'media')
edge = r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'

src = None
for f in os.listdir(svg_dir):
    if f.startswith('氐土'):
        src = os.path.join(svg_dir, f)
if src is None:
    raise SystemExit('未找到氐土SVG')

dst = os.path.join(out_dir, 'ditumo.png')
url = 'file:///' + src.replace(os.sep, '/')
subprocess.run([edge, '--headless=new', '--disable-gpu', '--default-background-color=00000000',
                '--screenshot=' + dst, '--window-size=512,512', url], capture_output=True, timeout=30)
print('ditumo.png:', os.path.getsize(dst), 'bytes')
