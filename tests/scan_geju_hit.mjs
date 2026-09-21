/**
 * 扫描真实日历找格局命中日期（真机回归演示用）
 * 运行：node --experimental-strip-types tests/scan_geju_hit.mjs [起始年] [终止年]
 */
import fs from 'node:fs';
import path from 'node:path';
import url from 'node:url';

const ROOT = path.resolve(path.dirname(url.fileURLToPath(import.meta.url)), '..');
const SRC = path.join(ROOT, 'entry', 'src', 'main', 'ets');
const RF = path.join(ROOT, 'entry', 'src', 'main', 'resources', 'rawfile');
const BUILD = path.join(ROOT, 'tests', '.engine-build');

function syncSource() {
  fs.rmSync(BUILD, { recursive: true, force: true });
  fs.mkdirSync(BUILD, { recursive: true });
  const conv = (file, outName) => {
    let t = fs.readFileSync(file, 'utf8');
    t = t.replace(/from '([^']+)'/g, (m, p1) => `from './${path.basename(p1)}.ts'`);
    t = t.replace(/^import \{/gm, 'import type {');
    fs.writeFileSync(path.join(BUILD, outName), t);
  };
  conv(path.join(SRC, 'utils', 'YanQinEngine.ets'), 'YanQinEngine.ts');
  conv(path.join(SRC, 'utils', 'GejuEngine.ets'), 'GejuEngine.ts');
  conv(path.join(SRC, 'model', 'Types.ets'), 'Types.ts');
  conv(path.join(SRC, 'model', 'ChartModels.ets'), 'ChartModels.ts');
}
syncSource();

const { YanQinEngine } = await import(url.pathToFileURL(path.join(BUILD, 'YanQinEngine.ts')).href);
const { GejuEngine } = await import(url.pathToFileURL(path.join(BUILD, 'GejuEngine.ts')).href);

const readJson = (f) => JSON.parse(fs.readFileSync(path.join(RF, f), 'utf8'));
const y0 = Number(process.argv[2] ?? 2026);
const y1 = Number(process.argv[3] ?? 2026);
const allCal = [];
for (let i = 1; i <= 17; i++) {
  const f = `calendar/calendar_data_${String(i).padStart(4, '0')}.json`;
  const p = path.join(RF, f);
  if (fs.existsSync(p)) { allCal.push(...readJson(f)); }
}
const byDate = new Map(allCal.map(c => [c.date, c]));
const engine = new YanQinEngine();
engine.init(readJson('animals.json'), readJson('interactions.json'), readJson('transformations.json'), readJson('seasonal_strength.json'));
GejuEngine.init(readJson('geju.json'));

const hits = [];
for (const cal of allCal) {
  const [y, m, d] = cal.date.split('-').map(Number);
  if (y < y0 || y > y1) { continue; }
  for (const hour of [0, 12]) {
    for (const gender of ['male', 'female']) {
      try {
        const chart = engine.calculateChart({ solarDate: new Date(y, m - 1, d), timeHour: hour, gender }, cal);
        const r = GejuEngine.judge(chart);
        if (r.matches.length > 0) {
          hits.push({ date: cal.date, hour, gender, n: r.matches.length,
            list: r.matches.map(x => `${x.geju.tier === 'upper' ? '上' : '下'}·${x.geju.name}(${x.hitLabel}${x.hitStarFull}泊${x.hitPalace})`).join('，') });
        }
      } catch (e) { /* 跳过异常组合 */ }
    }
  }
}
console.log(`命中 ${hits.length} 个组合（${y0}-${y1}）`);
hits.slice(0, 20).forEach(h => console.log(`${h.date} ${String(h.hour).padStart(2, '0')}时 ${h.gender === 'male' ? '男' : '女'}：${h.list}`));
