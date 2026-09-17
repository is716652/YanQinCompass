# 批量 SVG -> PNG（Edge headless，透明背景 512x512）
import os
import subprocess

BASE = r'D:\nutstore\HarmonyOS\GuoXue_Research\YanQinCompass'
SVG_DIR = os.path.join(BASE, '规则', '二十八星宿图')
OUT_DIR = os.path.join(BASE, 'entry', 'src', 'main', 'resources', 'base', 'media')
EDGE = r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'

ANIMAL = {'角': '蛟', '亢': '龙', '氐': '貉', '房': '兔', '心': '狐', '尾': '虎', '箕': '豹',
          '斗': '獬', '牛': '牛', '女': '蝠', '虚': '鼠', '危': '燕', '室': '猪', '壁': '貐',
          '奎': '狼', '娄': '狗', '胃': '雉', '昴': '鸡', '毕': '乌', '觜': '猴', '参': '猿',
          '井': '犴', '鬼': '羊', '柳': '獐', '星': '马', '张': '鹿', '翼': '蛇', '轸': '蚓'}
WX = {'角': '木', '亢': '金', '氐': '土', '房': '日', '心': '月', '尾': '火', '箕': '水',
      '斗': '木', '牛': '金', '女': '土', '虚': '日', '危': '月', '室': '火', '壁': '水',
      '奎': '木', '娄': '金', '胃': '土', '昴': '日', '毕': '月', '觜': '火', '参': '水',
      '井': '木', '鬼': '金', '柳': '土', '星': '日', '张': '月', '翼': '火', '轸': '水'}
PINYIN = {'角': 'jiaomujiao', '亢': 'kangjinlong', '氐': 'ditumo', '房': 'fangritu',
          '心': 'xinyuehu', '尾': 'weihuhu', '箕': 'jishuibao', '斗': 'doumuxie',
          '牛': 'niujinniu', '女': 'nvutfu', '虚': 'xurishu', '危': 'weiyueyan',
          '室': 'shihuoju', '壁': 'bishuiyu', '奎': 'kuimulang', '娄': 'loujingou',
          '胃': 'weitudi', '昴': 'maoriji', '毕': 'biyuewu', '觜': 'zihuohou',
          '参': 'shenshuiyuan', '井': 'jingmuan', '鬼': 'guijinyang', '柳': 'liutuzhang',
          '星': 'xingrima', '张': 'zhangyuelu', '翼': 'yihuoshe', '轸': 'zhenshuiyin'}

ok = fail = 0
for cn, py in PINYIN.items():
    full = cn + WX[cn] + ANIMAL[cn]
    src = os.path.join(SVG_DIR, full + '.svg')
    dst = os.path.join(OUT_DIR, py + '.png')
    if not os.path.exists(src):
        print('MISS', src)
        fail += 1
        continue
    url = 'file:///' + src.replace('\\', '/')
    try:
        subprocess.run([EDGE, '--headless=new', '--disable-gpu',
                        '--default-background-color=00000000',
                        '--screenshot=' + dst, '--window-size=512,512', url],
                       capture_output=True, timeout=30)
        if os.path.exists(dst) and os.path.getsize(dst) > 1000:
            ok += 1
        else:
            print('FAIL', full)
            fail += 1
    except Exception as e:
        print('FAIL', full, e)
        fail += 1
print(f'转换完成: {ok} 成功, {fail} 失败')
