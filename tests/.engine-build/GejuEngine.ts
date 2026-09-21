import type { YanQinChart } from './ChartModels.ts';
import type { Animal } from './Types.ts';

/** 格局条目（geju.json；逐条整理、出处与存疑标记见 规则/格局判定-数据整理.md） */
export interface GejuEntry {
  id: string;             // 格局 id（u01-u37 / d01-d20）
  name: string;           // 格局名（校勘后正名）
  nameAlt?: string;       // 校勘前原名（如有）
  tier: string;           // upper 上格 / lower 下格
  stars: string[];        // 涉及星宿简称（任一星命中即查）
  palace: string[];       // 泊宫地支（空 = 不限）
  seasons: string[];      // spring/summer/autumn/winter（空 = 不限；四季末不属于任何格局）
  dayNight: string;       // day / night（空 = 不限）
  lunarMonths: number[];  // 农历月（空 = 不限）
  gzChars: string[];      // 柱中干支字要件（不参与自动判定，仅展示）
  verdict: string;        // 白话断语（整理概括，以 text 原文为准）
  text: string;           // 古籍注文原文（含整理本校勘记）
  evaluable: boolean;     // 是否参与自动判定（false = 含柱字要件或所指存疑，仅展示）
  ambiguous: boolean;     // 结构化含诠释（依据见 note）
  note: string;           // 校勘 / 存疑 / 诠释说明
}

/** geju.json 顶层结构 */
export interface GejuData {
  source: string;
  sourceFile: string;
  counts: string;
  semantics: string;
  review: string;
  geju: GejuEntry[];
}

/** 一次命中：哪颗星、泊何宫、入何格 */
export interface GejuMatch {
  geju: GejuEntry;
  hitLabel: string;       // 主星 / 胎星 / 命星 / 身星
  hitStar: string;        // 宿简称
  hitStarFull: string;    // 宿全称
  hitPalace: string;      // 泊宫地支
}

/** 判定结果 */
export interface GejuResult {
  matches: GejuMatch[];
}

/** 四星与泊宫地支的绑定 */
interface StarBinding {
  label: string;
  star: Animal;
  palace: string;
}

const ZHI: string = '子丑寅卯辰巳午未申酉戌亥';

/** 干支串取末位地支（如 癸巳→巳）；非法串返回空 */
function lastZhi(ganzhi: string): string {
  if (ganzhi.length === 0) {
    return '';
  }
  const z: string = ganzhi.charAt(ganzhi.length - 1);
  return ZHI.includes(z) ? z : '';
}

/**
 * 格局判定引擎（《演禽通纂》福禄上格 / 贫贱下格）
 *
 * 纯函数判定：数据经 init 注入（geju.json），盘面由调用方传入，
 * 页面只渲染结果，不掺判定逻辑——数据 / 算法 / 页面三层分离。
 *
 * 判定语义（见 geju.json semantics 与 规则/格局判定-数据整理.md）：
 * 四星各按本应用星宫绑定取泊宫地支（主星泊命宫、胎星泊胎宫、命星泊命宫、身星泊身宫），
 * 逐条比对 evaluable=true 的格局：星宿 ∈ stars 且泊宫 ∈ palace（不限则跳过），
 * 再核季节 / 昼夜 / 农历月全局条件。命中后该格不再查其余星（主→胎→命→身优先）。
 */
export class GejuEngine {
  private static entries: GejuEntry[] = [];

  public static init(data: GejuData): void {
    GejuEngine.entries = data.geju;
  }

  /** 判定一盘 */
  public static judge(chart: YanQinChart): GejuResult {
    const bindings: StarBinding[] = [
      { label: '主星', star: chart.masterStar, palace: lastZhi(chart.lifePalace) },
      {
        label: '胎星',
        star: chart.embryoStar,
        palace: chart.embryoPalace !== undefined ? lastZhi(chart.embryoPalace) : ''
      },
      { label: '命星', star: chart.lifeStar, palace: lastZhi(chart.lifePalace) },
      { label: '身星', star: chart.bodyStar, palace: lastZhi(chart.bodyPalace) }
    ];
    const matches: GejuMatch[] = [];
    for (const e of GejuEngine.entries) {
      if (!e.evaluable) {
        continue;   // 含柱字要件 / 存疑条目：只展示不判定
      }
      for (const b of bindings) {
        if (b.palace === '') {
          continue;
        }
        if (!e.stars.includes(b.star.star)) {
          continue;
        }
        if (e.palace.length > 0 && !e.palace.includes(b.palace)) {
          continue;
        }
        if (e.seasons.length > 0
          && (chart.season === undefined || !e.seasons.includes(chart.season))) {
          continue;
        }
        if (e.dayNight !== ''
          && (chart.isDay === undefined || (e.dayNight === 'day') !== chart.isDay)) {
          continue;
        }
        if (e.lunarMonths.length > 0
          && (chart.lunarMonth === undefined || !e.lunarMonths.includes(chart.lunarMonth))) {
          continue;
        }
        matches.push({
          geju: e,
          hitLabel: b.label,
          hitStar: b.star.star,
          hitStarFull: b.star.full_name,
          hitPalace: b.palace
        });
        break;   // 此格已命中，不再查其余星
      }
    }
    const result: GejuResult = { matches: matches };
    return result;
  }
}
