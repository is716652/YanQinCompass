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

## 一、上格条数考：题载三十八，实得 ${upper.length}（已考定，三方互证）

- **整理本**（\`规则/演禽通纂.md\`）：逐条清点 ${upper.length} 条；
- **ctext 中国哲学书电子化计划**：行号 235（蛟龙喜丑）至 271（翼乾随龙）恰 ${upper.length} 条，位序与本表逐条一致；
- **维基文库四库本**（经本地代理抓取全览页全文核对）：上格 ${upper.length} 条、下格 20 条，条目名与位序逐一对应，末条同为「翼乾随龙」下接「贫贱下格」；
- **结论**：题数「三十八」为底本流传之误，三个独立来源互证，**非转录遗漏，不补凑**。

## 二、判定口径（v1）

1. **四星泊宫绑定**：主星泊命宫、胎星泊胎宫、命星泊命宫、身星泊身宫（与本应用命盘"泊 X 宫"徽标同口径）。
2. **全局条件**：季节（春/夏/秋/冬；四季末不属于任何格局条目）、昼夜（5-18 点为昼）、农历月。
3. **不自动判定 ${notEval.length} 条**（evaluable=false）：注文含柱中干支字要件（如"得乙巳""壬辰是也"）或原文所指存疑（如"江湖""己未"），仅展示原文——**宁可漏判，不可误判**。
4. **含诠释 ${evalAmb.length} 条**（ambiguous=true，可判定）：如"田野"取丑宫、"兔上"取卯位，依据见注记，考据结论见下节第 4 条。
5. 命中语义：一条格局只报一次（主→胎→命→身星优先）；上格、下格各自独立成立，可同时命中多条。

## 三、考据结论（AI 验证定案，2026-09-21，维基文库全文终验）

1. **上格缺条**：已考定——三方互证底本流传即缺，无需补。见第一节。
2. **校勘四处全部获维基文库异文印证**：「蛟**入**汤中」（维基文库径作「蛟入湯中」）、「遇庚辛二**字**」（同）、「**与**牛战」（作「與牛𢧐」）、「戊**字**大凶」（同）。
3. **「角元」**：诸电子本均作「元」——「元」为「亢」之形讹，属义校（角木蛟、亢金龙皆龙属，方合「龙用牛耕」）；本表 stars 按「角亢」收录，note 记录原貌。
4. **新发现歧异 u23**：「鹰犬居驰」注文维基文库作「得**巳**未为鹰」、整理本作「**己**未」——与下格「燕飞井上：得**己**未畏鹰」对勘当从「己未」，已记入该条 note；仍因宿属不明暂不自动判定。
5. **u21 卯/午矛盾为底本固有**：维基文库同样格名「居卯」注文「午位」，证实存疑处理正确。
6. **诠释类 ${evalAmb.length} 条**：与《通纂》内部用法一致——寅=山林虎穴（卷上 L691「牛泊山林，秋冬夜生，运行丙寅」）、丑=牛田、卯=兔位等，篇内语料支撑，各条 note 注明。
7. **四星参与判定**：《通纂》断例 L697「项羽主星井木犴，泊乙未宫」（主星泊宫论命）、L616「胎禽泊此宫分，其人贫必彻骨」（胎星泊宫独立论吉凶）；格局表未明限主星，主/胎泊宫既皆入断，四星参与为合理推广。
8. **v2 候选**：柱字要件落地（需四柱干支数据）、「江湖」等存疑条目考订、u23 鹰犬宿属考。

## 四、待人工确认（仅此一项）

- 判定语义：**四星（主/胎/命/身）都参与格局判定**——考据依据见第三节第 7 条；若想更保守（仅主星），改 GejuEngine.judge 的 bindings 一处即可。

## 五、全量对照表

### 福禄上格（${upper.length} 条：可判定 ${upper.filter(g => g.evaluable).length} / 仅展示 ${upper.filter(g => !g.evaluable).length}）

${tableHead}
${tableSep}
${upper.map(row).join('\n')}

### 贫贱下格（${lower.length} 条：可判定 ${lower.filter(g => g.evaluable).length} / 仅展示 ${lower.filter(g => !g.evaluable).length}）

${tableHead}
${tableSep}
${lower.map(row).join('\n')}

## 六、统计

| 项 | 数 |
|---|---|
| 总条数 | ${geju.length} |
| 上格 / 下格 | ${upper.length} / ${lower.length} |
| 可判定（自动） | ${evalAmb.length + evalNoAmb.length} |
| 其中含诠释（重点核验） | ${evalAmb.length} |
| 仅展示（不自动判定） | ${notEval.length} |

## 七、改动流程

1. 改 \`rawfile/geju.json\`（每条必带 text 原文；新增存疑必带 note）；
2. 重跑 \`node tests/gen_geju_doc.mjs\` 重新生成本文件；
3. 跑 \`node --experimental-strip-types tests/run_engine_tests.mjs\`（E 层含条数守卫：上37/下20，改动条数须同步改断言并说明理由）；
4. git 提交（pre-commit 门禁自动全量重跑）。
`;

fs.writeFileSync(OUT, md, 'utf8');
console.log(`已生成 ${OUT}（总 ${geju.length} 条）`);
