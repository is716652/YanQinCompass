/**
 * 格局判定数据 → 核验文档生成器
 * 从 rawfile/geju.json 自动生成 规则/格局判定-数据整理.md
 * 运行：node tests/gen_geju_doc.mjs（改 geju.json 后必须重跑，文档永不手改表格）
 */
import fs from 'node:fs';
import path from 'node:path';
import url from 'node:url';

const ROOT = path.resolve(path.dirname(url.fileURLToPath(import.meta.url)), '..');
const DATA = path.join(ROOT, 'entry', 'src', 'main', 'resources', 'rawfile', 'geju.json');
const OUT = path.join(ROOT, '规则', '格局判定-数据整理.md');

const SEASON_CN = { spring: '春', summer: '夏', autumn: '秋', winter: '冬' };

const data = JSON.parse(fs.readFileSync(DATA, 'utf8'));
const geju = data.geju;
const upper = geju.filter(g => g.tier === 'upper');
const lower = geju.filter(g => g.tier === 'lower');
const evalAmb = geju.filter(g => g.evaluable && g.ambiguous);
const evalNoAmb = geju.filter(g => g.evaluable && !g.ambiguous);
const notEval = geju.filter(g => !g.evaluable);

function condCell(g) {
  const parts = [];
  if (g.seasons.length > 0) parts.push(g.seasons.map(s => SEASON_CN[s] ?? s).join('/'));
  if (g.dayNight === 'night') parts.push('夜生');
  if (g.dayNight === 'day') parts.push('昼生');
  if (g.lunarMonths.length > 0) parts.push(g.lunarMonths.join('/') + '月');
  return parts.length > 0 ? parts.join(' · ') : '—';
}

function row(g) {
  const gz = g.gzChars.length > 0 ? g.gzChars.join('、') : '—';
  const judge = g.evaluable ? '可判定' : '不判定';
  const note = g.note.length > 0 ? `〈${g.note}〉` : '';
  return `| ${g.id} | ${g.name}${g.nameAlt ? `（原作${g.nameAlt}）` : ''} | ${g.stars.join('、')} | ${g.palace.length > 0 ? g.palace.join('/') : '不限'} | ${condCell(g)} | ${gz} | ${judge} | ${g.text}${note} |`;
}

const tableHead = '| id | 格局 | 星宿 | 泊宫 | 条件 | 柱字要件 | 判定 | 古籍注文（〈〉内为注记） |';
const tableSep = '|---|---|---|---|---|---|---|---|';

const md = `# 格局判定 · 数据整理与核验

> 本文件由 \`tests/gen_geju_doc.mjs\` 从 \`rawfile/geju.json\` 自动生成——**勿手改表格**，改数据后重跑脚本。
> 数据源：《演禽通纂》卷上"福禄上格三十八格 / 贫贱下格二十格"（\`规则/演禽通纂.md\` L367-426，整理本，【】内为校勘记）。
> 引擎：\`utils/GejuEngine.ets\`（纯函数）；门禁：\`tests/run_engine_tests.mjs\` E 层断言。

## 一、重要发现：上格实得 ${upper.length} 条（原书题三十八）

- 整理本逐条清点，上格仅 ${upper.length} 条；缺 1 条待考（传抄脱漏或另本可补）。
- 纪律：**不得为凑数硬造第 38 条**。待核对其他版本后再定，引擎与文档均按实得 ${upper.length} 条口径。

## 二、判定口径（v1）

1. **四星泊宫绑定**：主星泊命宫、胎星泊胎宫、命星泊命宫、身星泊身宫（与本应用命盘"泊 X 宫"徽标同口径）。
2. **全局条件**：季节（春/夏/秋/冬；四季末不属于任何格局条目）、昼夜（5-18 点为昼）、农历月。
3. **不自动判定 ${notEval.length} 条**（evaluable=false）：注文含柱中干支字要件（如"得乙巳""壬辰是也"）或原文所指存疑（如"江湖""己未"），仅展示原文——**宁可漏判，不可误判**。
4. **含诠释 ${evalAmb.length} 条**（ambiguous=true，可判定）：如"田野"取丑宫、"兔上"取卯位，依据见注记，**为重点核验对象**。
5. 命中语义：一条格局只报一次（主→胎→命→身星优先）；上格、下格各自独立成立，可同时命中多条。

## 三、待人工核验要点

1. 上格缺 1 条：是否有他本可补？
2. 校勘四处：蛟人→蛟**入**、孛→**字**、兴→**与**、戊宇→戊**字**，是否认可？
3. "角元春夏生"之"元"疑为"亢"（u01 注记）。
4. 诠释类判定 ${evalAmb.length} 条（下表 ambiguous 列）：诠释是否符合你对原文的理解？
5. 判定语义本身：四星都参与（而非仅主星）是否符合演禽本旨？
6. 不自动判定的 ${notEval.length} 条中，是否有可在 v2 落地为可判定的（如"江湖"考订为壬癸亥子）？

## 四、全量对照表

### 福禄上格（${upper.length} 条：可判定 ${upper.filter(g => g.evaluable).length} / 仅展示 ${upper.filter(g => !g.evaluable).length}）

${tableHead}
${tableSep}
${upper.map(row).join('\n')}

### 贫贱下格（${lower.length} 条：可判定 ${lower.filter(g => g.evaluable).length} / 仅展示 ${lower.filter(g => !g.evaluable).length}）

${tableHead}
${tableSep}
${lower.map(row).join('\n')}

## 五、统计

| 项 | 数 |
|---|---|
| 总条数 | ${geju.length} |
| 上格 / 下格 | ${upper.length} / ${lower.length} |
| 可判定（自动） | ${evalAmb.length + evalNoAmb.length} |
| 其中含诠释（重点核验） | ${evalAmb.length} |
| 仅展示（不自动判定） | ${notEval.length} |

## 六、改动流程

1. 改 \`rawfile/geju.json\`（每条必带 text 原文；新增存疑必带 note）；
2. 重跑 \`node tests/gen_geju_doc.mjs\` 重新生成本文件；
3. 跑 \`node --experimental-strip-types tests/run_engine_tests.mjs\`（E 层含条数守卫：上37/下20，改动条数须同步改断言并说明理由）；
4. git 提交（pre-commit 门禁自动全量重跑）。
`;

fs.writeFileSync(OUT, md, 'utf8');
console.log(`已生成 ${OUT}（总 ${geju.length} 条）`);
