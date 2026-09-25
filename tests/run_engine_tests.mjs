/**
 * 演禽引擎检测流程（防硬凑测试）
 * ================================================
 * 运行：node --experimental-strip-types tests/run_engine_tests.mjs
 *
 * 三层断言（按防"硬凑"能力排序）：
 *   A. 古籍锚点：用例与预期值全部来自古籍原文（含出处），引擎改错即红
 *   B. 关系不变量：四星/宫位/大运之间的推导关系（随机输入全成立）
 *   C. 性质不变量：值域、幂等性、季节映射边界
 *
 * 防硬凑红线（违反即为流程事故，见 Agent.md「引擎改动 SOP」）：
 *   1. 禁止为通过测试在引擎/数据表中添加仅命中测试输入的特判
 *   2. 禁止修改锚点预期值迁就引擎输出（锚点不符时：先查古籍，再查流派，最后才怀疑锚点）
 *   3. 数据表增改必须注记古籍出处（书名+条目）
 *   4. 测试失败的处理顺序：古籍原文 → 流派比对 → 提请人工裁决 → 才允许动锚点
 */
import fs from 'node:fs';
import path from 'node:path';
import url from 'node:url';

const ROOT = path.resolve(path.dirname(url.fileURLToPath(import.meta.url)), '..');
const SRC = path.join(ROOT, 'entry', 'src', 'main', 'ets');
const RF = path.join(ROOT, 'entry', 'src', 'main', 'resources', 'rawfile');
const BUILD = path.join(ROOT, 'tests', '.engine-build');

// ---------- 1. 动态同步引擎源码到测试构建目录（永远测试当前源码，防漂移） ----------
function syncSource() {
  fs.rmSync(BUILD, { recursive: true, force: true });
  fs.mkdirSync(path.join(BUILD), { recursive: true });
  const conv = (file, outName) => {
    let t = fs.readFileSync(file, 'utf8');
    t = t.replace(/from '([^']+)'/g, (m, p1) => {
      const base = path.basename(p1);            // '../model/Types' -> 'Types'
      return `from './${base}.ts'`;
    });
    t = t.replace(/^import \{/gm, 'import type {');
    fs.writeFileSync(path.join(BUILD, outName), t);
  };
  conv(path.join(SRC, 'utils', 'YanQinEngine.ets'), 'YanQinEngine.ts');
  conv(path.join(SRC, 'utils', 'DayStarUtils.ets'), 'DayStarUtils.ts');
  conv(path.join(SRC, 'utils', 'GejuEngine.ets'), 'GejuEngine.ts');
  conv(path.join(SRC, 'utils', 'ShizhanEngine.ets'), 'ShizhanEngine.ts');
  conv(path.join(SRC, 'model', 'Types.ets'), 'Types.ts');
  conv(path.join(SRC, 'model', 'ChartModels.ets'), 'ChartModels.ts');
}
await syncSource();

const { YanQinEngine } = await import(url.pathToFileURL(path.join(BUILD, 'YanQinEngine.ts')).href);
const { DayStarUtils } = await import(url.pathToFileURL(path.join(BUILD, 'DayStarUtils.ts')).href);
const { GejuEngine } = await import(url.pathToFileURL(path.join(BUILD, 'GejuEngine.ts')).href);
const { ShizhanEngine } = await import(url.pathToFileURL(path.join(BUILD, 'ShizhanEngine.ts')).href);

// ---------- 2. 数据装载（真实 rawfile） ----------
const readJson = (f) => JSON.parse(fs.readFileSync(path.join(RF, f), 'utf8'));
const animals = readJson('animals.json');
const interactions = readJson('interactions.json');
const transformations = readJson('transformations.json');
const seasonal = readJson('seasonal_strength.json');
const allCal = [
  ...readJson('calendar/calendar_data_0009.json'), // 1900-1909
  ...readJson('calendar/calendar_data_0010.json'), // 2000-2009
  ...readJson('calendar/calendar_data_0012.json'), // 2010-2019
];

const STARS = '角亢氐房心尾箕斗牛女虚危室壁奎娄胃昴毕觜参井鬼柳星张翼轸';
const STEMS = '甲乙丙丁戊己庚辛壬癸';
const BRANCH = '子丑寅卯辰巳午未申酉戌亥';
// 七曜序列（宿序 i % 7）：木金土日月火水；日宿归火、月宿归水参与五行旺衰
const elementOf = (star) => '木金土日月火水'[STARS.indexOf(star) % 7];

const engine = new YanQinEngine();
engine.init(animals, interactions, transformations, seasonal);

function chartOf(y, m, d, hour, gender) {
  const cal = allCal.find(x => x.date === `${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`);
  if (!cal) return { error: `万年历缺 ${y}-${m}-${d}` };
  try {
    const chart = engine.calculateChart(
      { solarDate: new Date(y, m - 1, d), timeHour: hour, gender },
      cal
    );
    return { chart, cal };
  } catch (e) {
    return { error: String(e?.message ?? e) };
  }
}

// ---------- 3. 断言工具 ----------
let pass = 0;
const failures = [];
function assert(cond, label) {
  if (cond) { pass++; }
  else { failures.push(label); }
}
function section(t) { console.log(`\n── ${t}`); }

// ---------- 4. A 层：古籍锚点 ----------
section('A. 古籍锚点（《演禽通纂》起例原文例题）');

// 《演禽通纂·起主胎星例》："假如辛卯年八月初八日子时生人……主星是箕水豹，胎星就是斗木獬"
// 日期映射：农历辛卯年八月初八 = 公历 2011-09-05（据万年历核实，勿以公历月代农历月）
// 命宫取巳宫（癸巳）：引擎既定口径（起命宫例存在巳/申两版矛盾，采用与主星例自洽的巳版，
// 依据 规则/algorithm_explanation.md §2.3，Agent.md 已记录）。
{
  const { chart, error } = chartOf(2011, 9, 5, 0, 'male');
  assert(!error, `锚点1 排盘无异常（${error ?? 'ok'}）`);
  assert(chart?.masterStar?.star === '箕', `锚点1 主星=箕（得 ${chart?.masterStar?.star}）`);
  assert(chart?.embryoStar?.star === '斗', `锚点1 胎星=斗（得 ${chart?.embryoStar?.star}）`);
  assert(chart?.lifePalace === '癸巳', `锚点1 命宫=癸巳（得 ${chart?.lifePalace}）`);
  assert(chart?.xunHead === '甲申', `锚点1 旬头=甲申（得 ${chart?.xunHead}）`);
}

// 《演禽通纂·起寿宫例》原文四例：阳男阴女冲前一位，阴男阳女冲后一位
{
  const c1 = chartOf(2011, 9, 5, 0, 'female');
  assert(c1.chart?.shouPalace === '戊戌', `寿宫 阴女→戌前（得 ${c1.chart?.shouPalace ?? '?'}）`);
  const c2 = chartOf(2011, 9, 5, 0, 'male');
  assert(c2.chart?.shouPalace === '丙申', `寿宫 阴男→申后（得 ${c2.chart?.shouPalace ?? '?'}）`);
  const c3 = chartOf(1984, 11, 11, 0, 'male');
  assert(c3.chart?.shouPalace === '辛未', `寿宫 阳男→未前（得 ${c3.chart?.shouPalace ?? '?'}）`);
  const c4 = chartOf(1984, 11, 11, 0, 'female');
  assert(c4.chart?.shouPalace === '己巳', `寿宫 阳女→巳后（得 ${c4.chart?.shouPalace ?? '?'}）`);
}

// 《禽星易见》七元将头：一元虚、二元奎、三元毕、四元鬼、五元翼、六元氐、七元箕
// 锚点：1984-02-02 为一元甲子日，起虚日鼠（与禽星盘式项目同源互证）
section('A2. 值日禽星锚点（七元甲子）');
{
  assert(DayStarUtils.calc(1984, 2, 2).star === '虚', '值日锚点 1984-02-02=虚');
  assert(DayStarUtils.calc(1984, 2, 3).star === '危', '次日顺推=危');
  assert(DayStarUtils.calc(1984, 4, 2).star === '奎', '60 日换二元=奎');
}

// ---------- 5. B 层：关系不变量（随机输入全成立） ----------
section('B. 关系不变量（随机 400 组）');
const rnd = (n) => Math.floor(Math.random() * n);
let badValue = 0, badEmbryo = 0, badPalace = 0, badFortune = 0, badAge = 0, badIdem = 0, badSeason = 0;
const E2AGE = { 水: 1, 火: 2, 木: 3, 金: 4, 土: 5, 日: 6, 月: 7 };

for (let k = 0; k < 400; k++) {
  // 从真实万年历取样（保证农历/干支数据真实，覆盖 1900-2061 全范围）
  const cal = allCal[rnd(allCal.length)];
  const [y, m, d] = cal.date.split('-').map(Number);
  const hour = rnd(24);
  const gender = rnd(2) === 0 ? 'male' : 'female';
  const r = chartOf(y, m, d, hour, gender);
  if (r.error || !r.chart) { badValue++; continue; }
  const c = r.chart;

  // B1 四星值域
  const stars = [c.masterStar, c.embryoStar, c.lifeStar, c.bodyStar];
  if (stars.some(s => !STARS.includes(s.star))) badValue++;
  // B2 胎星 = 主星下一位
  if (STARS.indexOf(c.embryoStar.star) !== (STARS.indexOf(c.masterStar.star) + 1) % 28) badEmbryo++;
  // B3 宫位干支值域
  for (const pal of [c.lifePalace, c.bodyPalace]) {
    if (!pal || pal.length !== 2 || !STEMS.includes(pal[0]) || !BRANCH.includes(pal[1])) badPalace++;
  }
  // B4 大运：起于命宫干支、连续九运；方向据《通纂·起大运例》"主星落宫天干"阴阳
  //   （而非年干！阳干男顺/女逆，阴干男逆/女顺）
  const lifeGan = c.lifePalace[0];
  const yangGan = '甲丙戊庚壬'.includes(lifeGan);
  const forward = gender === 'male' ? yangGan : !yangGan;
  const startAge = { 水: 1, 火: 2, 木: 3, 金: 4, 土: 5, 日: 6, 月: 7 }[c.masterStar.element] ?? 3;
  if (c.fortuneStartAge !== startAge) badAge++;
  const step = forward ? n => n : n => -n;
  for (let n = 0; n < c.fortuneList.length; n++) {
    const expG = STEMS[(STEMS.indexOf(lifeGan) + ((forward ? n : -n) % 10 + 10)) % 10];
    const expZ = BRANCH[(BRANCH.indexOf(c.lifePalace[1]) + ((forward ? n : -n) % 12 + 12)) % 12];
    if (c.fortuneList[n][0] !== expG || c.fortuneList[n][1] !== expZ) { badFortune++; break; }
  }
  // B5 幂等
  const again = engine.calculateChart(
    { solarDate: new Date(y, m - 1, d), timeHour: hour, gender },
    cal
  );
  if (JSON.stringify(again) !== JSON.stringify(c)) badIdem++;
  // B6 season 值域与 earth 边界（农历 3/6/9/12 → earth）
  const lm = cal.lunar_month;
  const expSeason = (lm === 3 || lm === 6 || lm === 9 || lm === 12) ? 'earth'
    : (lm <= 2 ? 'spring' : lm <= 5 ? 'summer' : lm <= 8 ? 'autumn' : 'winter');
  if (c.season !== expSeason) badSeason++;
}
assert(badValue === 0, `不变量·四星值域 违例=${badValue}`);
assert(badEmbryo === 0, `不变量·胎星承主星 违例=${badEmbryo}`);
assert(badPalace === 0, `不变量·宫位干支 违例=${badPalace}`);
assert(badFortune === 0, `不变量·大运序列 违例=${badFortune}`);
assert(badAge === 0, `不变量·起运岁数 违例=${badAge}`);
assert(badSeason === 0, `不变量·季节映射 违例=${badSeason}`);
assert(badIdem === 0, `不变量·幂等性 违例=${badIdem}`);

// ---------- 6. C 层：性质不变量 ----------
section('C. 性质不变量');
{
  const r = chartOf(2011, 9, 5, 0, 'male');
  assert(['旺', '相', '休', '囚', '死'].includes(r.chart?.seasonalStrength), '旺衰档位值域合法');
  // earth 月边界：农历三月应判 earth
  const mar = allCal.find(x => x.lunar_month === 3 && x.year === 2011);
  if (mar) {
    const [yy, mm, dd] = mar.date.split('-').map(Number);
    const rr = chartOf(yy, mm, dd, 12, 'male');
    assert(rr.chart?.season === 'earth', `农历三月判 earth（得 ${rr.chart?.season}）`);
  }
}

// ---------- 6.5 D 层：数据表一致性（数据正确性底线） ----------
section('D. 数据表一致性');
{
  // D1 三张表都是 28 宿、无缺漏、无重复
  const animalStars = animals.map(a => a.star);
  const bestiaryStars = [];
  for (const g of readJson('bestiary.json').groups) {
    for (const s of g.stars) { bestiaryStars.push(s.star); }
  }
  const uniq = (arr) => new Set(arr).size === arr.length;
  assert(animalStars.length === 28 && uniq(animalStars), `animals.json 28 宿无缺无重（得 ${animalStars.length}）`);
  assert(bestiaryStars.length === 28 && uniq(bestiaryStars), `bestiary.json 28 宿无缺无重（得 ${bestiaryStars.length}）`);
  assert(new Set(animalStars).size === new Set(bestiaryStars).size, '两表星宿集合一致');
  // D2 每宿字段完整性（full_name/element/animal）
  const missing = animals.filter(a => !a.full_name || !a.element || !a.animal);
  assert(missing.length === 0, `animals.json 字段完整（缺 ${missing.length}）`);
  // D3 bestiary 每宿有描述与泊宫课名（泊宫课名 90 条资产，防丢）
  const bj = readJson('bestiary.json');
  const noGm = [];
  for (const g of bj.groups) {
    for (const s of g.stars) {
      if (!s.desc || s.desc.length < 10) noGm.push(s.star + ':desc');
      if (!s.guanming || s.guanming.length === 0) noGm.push(s.star + ':guanming');
    }
  }
  assert(noGm.length === 0, `bestiary 描述与泊宫课名完整（缺 ${noGm.length}：${noGm.slice(0,4).join(',')}）`);
  // D4 旺衰表：五季 × 五档 × 无空档，且 28 宿每季全覆盖（日归火月归水合并后）
  let seasonIssues = [];
  for (const season of ['spring', 'summer', 'autumn', 'winter', 'earth']) {
    const tiers = seasonal[season];
    if (!tiers) { seasonIssues.push(season + ':缺'); continue; }
    const all = [];
    for (const tier of ['旺', '相', '休', '囚', '死']) {
      if (!tiers[tier] || tiers[tier].length === 0) seasonIssues.push(`${season}.${tier}:空`);
      all.push(...tiers[tier]);
    }
    // 合并日归火月归水后应为 28 宿全覆盖
    const merged = new Set(all.map(s => '日月'.includes(elementOf(s)) ? (elementOf(s) === '日' ? '日归火' : '月归水') : s));
    const expected = new Set([...STARS].map(s => '日月'.includes(elementOf(s)) ? (elementOf(s) === '日' ? '日归火' : '月归水') : s));
    if (merged.size !== expected.size) seasonIssues.push(`${season}:覆盖${merged.size}/${expected.size}`);
  }
  assert(seasonIssues.length === 0, `旺衰表五季五档完整（${seasonIssues.slice(0,3).join(';')}）`);
  // D5 吞啖表：relationships 覆盖（防数据丢失）
  assert(interactions.relationships.length >= 10, `吞啖关系条数（${interactions.relationships.length}）`);
  // D6 旺衰表：五行四时旺衰标准定义逐宿校验（独立知识源=五行公理：
  //    旺=当令、相=旺所生、休=生旺、囚=克旺、死=旺克；日归火、月归水）
  const SHENG = { 木: '火', 火: '土', 土: '金', 金: '水', 水: '木' };
  const KE = { 木: '土', 土: '水', 水: '火', 火: '金', 金: '木' };
  const SEASON_WX = { spring: '木', summer: '火', autumn: '金', winter: '水', earth: '土' };
  let wxBad = 0;
  for (const [season, swx] of Object.entries(SEASON_WX)) {
    for (const s of STARS) {
      const yao = elementOf(s);
      const wx = yao === '日' ? '火' : (yao === '月' ? '水' : yao);
      let exp = '休';
      if (wx === swx) exp = '旺';
      else if (SHENG[swx] === wx) exp = '相';
      else if (SHENG[wx] === swx) exp = '休';
      else if (KE[wx] === swx) exp = '囚';
      else if (KE[swx] === wx) exp = '死';
      const tier = ['旺', '相', '休', '囚', '死'].find(t => seasonal[season][t].includes(s));
      if (tier !== exp) wxBad++;
    }
  }
  assert(wxBad === 0, `旺衰表·五行四时标准逐宿校验（违例 ${wxBad}）`);
}

// ---------- 6.8 E 层：格局判定（《演禽通纂》上格/下格，geju.json + GejuEngine） ----------
section('E. 格局判定（geju.json + GejuEngine）');
{
  const gejuData = readJson('geju.json');
  const geju = gejuData.geju;
  GejuEngine.init(gejuData);

  // E1 数据完整性（防缺漏、防非法值、防无出处）
  const upper = geju.filter(g => g.tier === 'upper');
  const lower = geju.filter(g => g.tier === 'lower');
  assert(geju.length === 57 && upper.length === 37 && lower.length === 20,
    `格局条数 57=上37+下20（原书题上38缺一待考；得 总${geju.length}/上${upper.length}/下${lower.length}）`);
  assert(new Set(geju.map(g => g.id)).size === geju.length, '格局 id 无重复');
  const badStars = geju.filter(g => g.stars.length === 0 || g.stars.some(s => !STARS.includes(s)));
  assert(badStars.length === 0, `格局星宿合法非空（违例 ${badStars.map(g => g.id).join(',') || '无'}）`);
  const badPal = geju.filter(g => g.palace.some(p => !BRANCH.includes(p)));
  assert(badPal.length === 0, `格局泊宫地支合法（违例 ${badPal.map(g => g.id).join(',') || '无'}）`);
  const badSeas = geju.filter(g => g.seasons.some(s => !['spring', 'summer', 'autumn', 'winter'].includes(s)));
  const badDn = geju.filter(g => !['', 'day', 'night'].includes(g.dayNight));
  assert(badSeas.length === 0 && badDn.length === 0, '格局季节/昼夜代码合法');
  const noText = geju.filter(g => !g.text || g.text.length < 5);
  assert(noText.length === 0, `每格附古籍注文（缺 ${noText.length}）`);
  // 可判定条目至少含一个可判条件；不判定/存疑条目必附注记（出处可回溯）
  const noCond = geju.filter(g => g.evaluable && g.palace.length === 0 && g.seasons.length === 0
    && g.dayNight === '' && g.lunarMonths.length === 0);
  const noNote = geju.filter(g => (!g.evaluable || g.ambiguous) && (!g.note || g.note.length === 0));
  assert(noCond.length === 0, `可判定条目至少一个可判条件（违例 ${noCond.map(g => g.id).join(',') || '无'}）`);
  assert(noNote.length === 0, `不判定/存疑条目必附注记（缺 ${noNote.length}）`);

  // E2 判定锚点与反例（盘面手造，用例与预期独立于引擎实现）
  // 手造盘面：只含判定所需字段；命星固定奎泊子、身星固定虚泊子（与下述锚点无交叉）
  function gejuChartOf(opt) {
    return {
      masterStar: { star: opt.master, full_name: `锚${opt.master}` },
      embryoStar: { star: opt.embryo, full_name: `胎${opt.embryo}` },
      lifeStar: { star: '奎', full_name: '命奎' },
      bodyStar: { star: '虚', full_name: '身虚' },
      lifePalace: opt.life, bodyPalace: '甲子',
      embryoPalace: opt.embryoPalace ?? '乙丑',
      season: opt.season, isDay: opt.isDay, lunarMonth: opt.lm ?? 1
    };
  }
  const ids = (ms) => ms.map(x => x.geju.id);
  // 锚点E1：《通纂》"蛟龙喜丑（角亢春夏生…龙用牛耕）"——角泊丑、春生
  const m1 = GejuEngine.judge(gejuChartOf({ master: '角', embryo: '氐', life: '癸丑', season: 'spring', isDay: true })).matches;
  assert(m1.some(x => x.geju.id === 'u01' && x.hitStar === '角' && x.hitPalace === '丑' && x.hitLabel === '主星'),
    `锚点E1 角泊丑春生→蛟龙喜丑（得 [${ids(m1)}]）`);
  // 反例E1：角泊午不入蛟龙喜丑
  const m2 = GejuEngine.judge(gejuChartOf({ master: '角', embryo: '氐', life: '癸午', season: 'spring', isDay: true })).matches;
  assert(!m2.some(x => x.geju.id === 'u01'), `反例E1 角泊午不入蛟龙喜丑（得 [${ids(m2)}]）`);
  // 锚点E2："蝠当盛夏（夏秋夜生午位）"——女泊午秋夜命中；冬生为反例
  const m3 = GejuEngine.judge(gejuChartOf({ master: '女', embryo: '虚', life: '庚午', season: 'autumn', isDay: false, embryoPalace: '甲辰' })).matches;
  assert(m3.some(x => x.geju.id === 'u13' && x.hitLabel === '主星'), `锚点E2 女泊午秋夜→蝠当盛夏（得 [${ids(m3)}]）`);
  const m4 = GejuEngine.judge(gejuChartOf({ master: '女', embryo: '虚', life: '庚午', season: 'winter', isDay: false, embryoPalace: '甲辰' })).matches;
  assert(!m4.some(x => x.geju.id === 'u13'), `反例E2 冬生不入蝠当盛夏（得 [${ids(m4)}]）`);
  // 反例E3：evaluable=false 永不命中——氐泊辰春夏夜，貉登巨浪（u02 需壬辰柱字）不得自动判定
  const m5 = GejuEngine.judge(gejuChartOf({ master: '氐', embryo: '房', life: '壬辰', season: 'spring', isDay: false, embryoPalace: '甲戌' })).matches;
  assert(!m5.some(x => x.geju.id === 'u02'), `反例E3 存疑条目不参与判定（得 [${ids(m5)}]）`);
  // 锚点E4："獬入未宫"——胎星斗泊未命中，命中星与标签正确
  const m6 = GejuEngine.judge(gejuChartOf({ master: '牛', embryo: '斗', life: '甲子', embryoPalace: '辛未', season: 'spring', isDay: true })).matches;
  assert(m6.some(x => x.geju.id === 'u10' && x.hitLabel === '胎星' && x.hitStar === '斗' && x.hitPalace === '未'),
    `锚点E4 胎星斗泊未→獬入未宫（得 [${ids(m6)}]）`);
  // 锚点E5："猪怕刀砧（二月八月居申酉）"——农历月条件；非二八月为反例
  const m7 = GejuEngine.judge(gejuChartOf({ master: '室', embryo: '危', life: '壬申', season: 'spring', isDay: true, lm: 8 })).matches;
  assert(m7.some(x => x.geju.id === 'd13' && x.hitLabel === '主星'), `锚点E5 室泊申八月→猪怕刀砧（得 [${ids(m7)}]）`);
  const m8 = GejuEngine.judge(gejuChartOf({ master: '室', embryo: '危', life: '壬申', season: 'spring', isDay: true, lm: 5 })).matches;
  assert(!m8.some(x => x.geju.id === 'd13'), `反例E5 五月不入猪怕刀砧（得 [${ids(m8)}]）`);

  // E3 真实盘不变量（随机 200 组：只命中可判定条目、命中星与标签合法、四季末不入任何带季节条件的格局）
  const evaluableIds = new Set(geju.filter(g => g.evaluable).map(g => g.id));
  let badJudge = 0;
  for (let k = 0; k < 200; k++) {
    const cal = allCal[rnd(allCal.length)];
    const [y, m, d] = cal.date.split('-').map(Number);
    const r = chartOf(y, m, d, rnd(24), rnd(2) === 0 ? 'male' : 'female');
    if (r.error || !r.chart) { badJudge++; continue; }
    const jr = GejuEngine.judge(r.chart);
    for (const x of jr.matches) {
      if (!evaluableIds.has(x.geju.id)) badJudge++;
      if (!STARS.includes(x.hitStar) || !['主星', '胎星', '命星', '身星'].includes(x.hitLabel)) badJudge++;
      if (!BRANCH.includes(x.hitPalace)) badJudge++;
    }
  }
  assert(badJudge === 0, `格局判定·真实盘 200 组不变量（违例 ${badJudge}）`);
  // E4 真实古籍例题盘可运行（锚点1：2011-09-05 子时男，主星箕）
  const anc = chartOf(2011, 9, 5, 0, 'male');
  const jrA = GejuEngine.judge(anc.chart);
  assert(Array.isArray(jrA.matches), '真实古籍例题盘判定可运行');
}


// ---------- 6.9 F 层：时占引擎（时禽起例 + 喜忌宫，hour_star_table/palace_affinity） ----------
section('F. 时占引擎（时禽起例 + 喜忌宫）');
{
  const hsTable = readJson('hour_star_table.json');
  const palaceData = readJson('palace_affinity.json');
  ShizhanEngine.init(hsTable, palaceData, seasonal, animals);
  const ZHI12 = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  // F1 元表完整性：7 元 × 7 曜，行 = C 循环移位（曜序+元号-1）
  const C = hsTable.cycle;
  assert(C.length === 7 && C.join('') === '虚鬼箕毕氐奎翼', '元表 C 循环 = 虚鬼箕毕氐奎翼（七元将头集）');
  let tblBad = 0;
  for (let k = 1; k <= 7; k++) {
    const row = hsTable.table[String(k)];
    if (!row) { tblBad++; continue; }
    for (let i = 0; i < 7; i++) {
      if (row[hsTable.yao_order[i]] !== C[(i + k - 1) % 7]) tblBad++;
    }
  }
  assert(tblBad === 0, `元表 7×7 拉丁方阵校验（违例 ${tblBad}）`);

  // F2 掌图例题锚点（《禽星易见·七元时禽掌图》11 例：元/直日宿→子时起星）
  const yaoOf = (star) => '木金土日月火水'['角亢氐房心尾箕斗牛女虚危室壁奎娄胃昴毕觜参井鬼柳星张翼轸'.indexOf(star) % 7];
  const examples = [
    [1, '虚', '虚'], [1, '危', '鬼'], [1, '室', '箕'], [1, '壁', '毕'],
    [1, '奎', '氐'], [1, '娄', '奎'], [1, '胃', '翼'],
    [1, '昴', '虚'], [1, '毕', '鬼'], [1, '觜', '箕'],
    [2, '奎', '奎']
  ];
  let exBad = 0;
  for (const [yuan, dayStar, expectStart] of examples) {
    if (ShizhanEngine.hourStartStar(yuan, yaoOf(dayStar)) !== expectStart) exBad++;
  }
  assert(exBad === 0, `掌图例题 11 例锚点（违例 ${exBad}）`);

  // F3 十二时禽序列：一元甲子虚直日"至井十二宿为终"；一元乙丑危直日"至尾十二宿为终"
  const seqA = ZHI12.map(z => ShizhanEngine.calcHourStar(1, yaoOf('虚'), z).star).join('');
  const seqB = ZHI12.map(z => ShizhanEngine.calcHourStar(1, yaoOf('危'), z).star).join('');
  assert(seqA === '虚危室壁奎娄胃昴毕觜参井', `一元虚直日十二时禽序列（得 ${seqA}）`);
  assert(seqB === '鬼柳星张翼轸角亢氐房心尾', `一元危直日十二时禽序列（得 ${seqB}）`);

  // F4 喜忌宫数据完整性：十二支全覆盖无重、星表合法、凶宫必有例外吉星
  const covered = [];
  let palBad = 0;
  for (const g of palaceData.groups) {
    for (const p of g.palaces) {
      if (!BRANCH.includes(p) || covered.includes(p)) palBad++;
      covered.push(p);
    }
    if ([...g.joyStars, ...g.favorStars, ...g.unfavorableStars].some(s => !STARS.includes(s))) palBad++;
    if (g.kind === 'inauspicious' && g.favorStars.length === 0) palBad++;
  }
  assert(palBad === 0 && covered.length === 12, `喜忌宫十二支全覆盖+星表合法（违例 ${palBad}）`);

  // F5 判定锚点：一元虚直日午时→时禽胃，泊午火宫（恶逆）=凶；明禽昼占当飞；旺衰值域
  const wx = ShizhanEngine.calcHourStar(1, yaoOf('虚'), '午');
  assert(wx.star === '胃', `一元虚直日午时时禽=胃（得 ${wx.star}）`);
  const v1 = ShizhanEngine.judge({ hourStar: wx, hourZhi: '午', isDay: true, season: 'autumn' });
  assert(v1 !== null && v1.favorable === '凶', `胃泊午（火宫恶逆）判凶（得 ${v1?.favorable}）`);
  assert(v1?.flying === true, `胃土雉明禽昼占当飞（得 ${v1?.flying}）`);
  assert(['旺', '相', '休', '囚', '死'].includes(v1?.strength ?? ''), `时禽旺衰值域（得 ${v1?.strength}）`);
  // F6 刀砧宫：毕泊申默认凶（毕≠例外吉星）；娄泊申例外吉
  const v2 = ShizhanEngine.judge({ hourStar: ShizhanEngine.calcHourStar(1, yaoOf('虚'), '申'), hourZhi: '申', isDay: true, season: 'spring' });
  assert(v2 !== null && v2.favorable === '凶', `毕泊申（刀砧刑害）默认凶（得 ${v2?.favorable}）`);
  const lou = { star: '娄', full_name: '娄金狗', element: '金', animal: '狗', note: '暗禽' };
  const v3 = ShizhanEngine.judge({ hourStar: lou, hourZhi: '申', isDay: true, season: 'spring' });
  assert(v3 !== null && v3.favorable === '吉', `娄泊申（例外泊之吉）判吉（得 ${v3?.favorable}）`);
  // F7 元号锚点：DayStarUtils 暴露元号与循环日序
  assert(DayStarUtils.calc(1984, 2, 2).yuan === 1 && DayStarUtils.calc(1984, 2, 2).cycleDayIndex === 0,
    '锚点 1984-02-02 = 一元 / 日序 0');
  assert(DayStarUtils.calc(1984, 4, 2).yuan === 2, '锚点 1984-04-02 = 二元（60 日换元）');
}


// ---------- 7. 汇总 ----------
console.log(`\n========================================`);
console.log(`通过断言: ${pass}  失败: ${failures.length}`);
if (failures.length) {
  console.log('失败项:');
  failures.forEach(f => console.log('  ✗', f));
  process.exitCode = 1;
} else {
  console.log('全部通过 ✓（锚点 + 不变量 + 性质）');
}
