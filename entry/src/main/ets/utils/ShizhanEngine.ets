import { Animal, InteractionRule, InteractionsData } from '../model/Types';

const STAR_ORDER: string[] = [
  "角", "亢", "氐", "房", "心", "尾", "箕",
  "斗", "牛", "女", "虚", "危", "室", "壁",
  "奎", "娄", "胃", "昴", "毕", "觜", "参",
  "井", "鬼", "柳", "星", "张", "翼", "轸"
];
const ZHI_ORDER: string[] = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"];

/** 七元时禽元表（hour_star_table.json，《禽星易见·七元时禽总括》） */
export interface HourStarTable {
  source: string;
  cycle: string[];
  yao_order: string[];
  rule: string;
  table: Record<string, Record<string, string>>;   // 元号"1"-"7" -> 曜 -> 子时起星
  note: string;
}

/** 禽星喜忌宫分组（palace_affinity.json，《禽星易见·禽星喜忌宫》） */
export interface PalaceGroup {
  palaces: string[];
  name: string;
  kind: string;              // auspicious 吉 / neutral 平 / inauspicious 凶
  joyStars: string[];
  favorStars: string[];
  unfavorableStars: string[];
  text: string;
  note?: string;
}

export interface PalaceAffinityData {
  source: string;
  semantics: string;
  groups: PalaceGroup[];
}

/** 彼我吞啖判定结果 */
export interface InteractionVerdict {
  favorable: string;   // 吉（时禽克彼）/ 凶（彼克时禽）/ 平（无吞啖关系）
  text: string;        // 白话描述
  origin: string;      // 判定来源（吞啖表 / 歌诀）
}

/** 时占判定输入 */
export interface ShizhanInput {
  hourStar: Animal;   // 时禽（calcHourStar 起盘所得）
  hourZhi: string;    // 占时地支（时禽泊宫）
  isDay: boolean;     // 昼/夜
  season: string;     // spring/summer/autumn/winter/earth
}

/** 时占判定结果 */
export interface ShizhanVerdict {
  palaceName: string;      // 宫名（江湖水宫 等）
  favorable: string;       // 吉 / 平 / 凶（此禽泊此宫）
  palaceText: string;      // 古籍原文
  palaceNote: string;      // 存疑注记（无则空串）
  flying: boolean;         // true=飞（得用）false=伏（失用）
  flyingText: string;
  strength: string;        // 旺/相/休/囚/死
}

/**
 * 深度时占引擎（《禽星易见》体系，v1）
 *
 * 纯函数：数据 init 注入，页面只渲染结果——数据/算法/页面三层分离。
 * 考据与分歧注记见 规则/时占口径研究.md。
 */
export class ShizhanEngine {
  private static table: HourStarTable | null = null;
  private static palaceData: PalaceAffinityData | null = null;
  private static seasonal: Record<string, Record<string, string[]>> | null = null;
  private static animals: Animal[] = [];
  private static interactions: InteractionsData | null = null;

  public static init(table: HourStarTable, palace: PalaceAffinityData,
                     seasonal: Record<string, Record<string, string[]>>, animals: Animal[],
                     interactions?: InteractionsData): void {
    ShizhanEngine.table = table;
    ShizhanEngine.palaceData = palace;
    ShizhanEngine.seasonal = seasonal;
    ShizhanEngine.animals = animals;
    ShizhanEngine.interactions = interactions ?? null;
  }

  private static getAnimal(star: string): Animal {
    const found = ShizhanEngine.animals.find(a => a.star === star);
    if (found) {
      return found;
    }
    const a: Animal = { star: star, full_name: star, element: "未知", animal: star };
    return a;
  }

  /** 子时起星：元号(1-7) + 值日宿七曜 → 元表查得起星 */
  public static hourStartStar(yuan: number, dayYao: string): string {
    const t = ShizhanEngine.table;
    if (t === null) {
      return "";
    }
    const row = t.table[String(yuan)];
    if (!row) {
      return "";
    }
    return row[dayYao] ?? "";
  }

  /** 时禽起盘：元号 + 值日宿七曜 + 占时地支 → 时禽（自子时起星顺数至占时） */
  public static calcHourStar(yuan: number, dayYao: string, hourZhi: string): Animal {
    const start = ShizhanEngine.hourStartStar(yuan, dayYao);
    const startIdx = STAR_ORDER.indexOf(start);
    const hourIdx = ZHI_ORDER.indexOf(hourZhi);
    if (startIdx < 0 || hourIdx < 0) {
      return ShizhanEngine.getAnimal("");
    }
    return ShizhanEngine.getAnimal(STAR_ORDER[(startIdx + hourIdx) % 28]);
  }

  /** 泊宫吉凶判定（喜忌宫） */
  public static judgePalace(star: string, hourZhi: string): ShizhanVerdict | null {
    const pd = ShizhanEngine.palaceData;
    if (pd === null) {
      return null;
    }
    const g = pd.groups.find(gr => gr.palaces.includes(hourZhi));
    if (!g) {
      return null;
    }
    let favorable: string;
    if (g.unfavorableStars.includes(star)) {
      favorable = "凶";
    } else if (g.joyStars.includes(star) || g.favorStars.includes(star)) {
      favorable = "吉";
    } else if (g.kind === "inauspicious") {
      favorable = "凶";
    } else if (g.kind === "auspicious") {
      favorable = "平";
    } else {
      favorable = "平";
    }
    const v: ShizhanVerdict = {
      palaceName: g.name,
      favorable: favorable,
      palaceText: g.text,
      palaceNote: g.note ?? "",
      flying: false,
      flyingText: "",
      strength: ""
    };
    return v;
  }

  /** 时占总判定 */
  public static judge(input: ShizhanInput): ShizhanVerdict | null {
    const v = ShizhanEngine.judgePalace(input.hourStar.star, input.hourZhi);
    if (v === null) {
      return null;
    }
    // 飞伏：毕月乌昼夜皆宜；其余按明禽（日禽）昼飞夜伏、暗禽（夜禽）反是
    let flying: boolean;
    if (input.hourStar.star === "毕") {
      flying = true;
    } else if (input.hourStar.note === "明禽") {
      flying = input.isDay;
    } else if (input.hourStar.note === "暗禽") {
      flying = !input.isDay;
    } else {
      flying = input.isDay;
    }
    v.flying = flying;
    v.flyingText = flying ? "得时而飞，主事体显达易成" : "失时而伏，主事体隐藏迟滞";
    // 旺衰：时禽按宿名查四档旺衰表（与主星同源 seasonal_strength.json）
    let strength = "";
    const se = ShizhanEngine.seasonal;
    if (se && se[input.season]) {
      const tierNames: string[] = ["旺", "相", "休", "囚", "死"];
      for (const tier of tierNames) {
        const list = se[input.season][tier];
        if (list && list.includes(input.hourStar.star)) {
          strength = tier;
          break;
        }
      }
    }
    v.strength = strength === "" ? "休" : strength;
    return v;
  }

  /**
   * 彼我吞啖（简断）：时禽 vs 彼星（问事当日值日禽，或用户本命主星）。
   * 口径：《禽星易见》"常将日禽寻时禽……看与将星上下相合"、"时禽克日禽主快"——
   * 时禽克彼为吉（我制彼，事可成），彼克时禽为凶；无吞啖关系为平。
   * 逻辑与 YanQinEngine.checkInteraction 同源（吞啖表+歌诀+季节昼夜修正）。
   */
  public static judgeInteraction(hourStar: Animal, otherStar: Animal,
                                 lunarMonth: number, isDay: boolean): InteractionVerdict | null {
    const it = ShizhanEngine.interactions;
    if (it === null) {
      return null;
    }
    const ruleA = it.relationships.find(r => ShizhanEngine.starInRule(r, hourStar));
    const ruleB = it.relationships.find(r => ShizhanEngine.starInRule(r, otherStar));
    // 时禽吃彼
    if (ruleA && ruleA.eats.some(prey => ShizhanEngine.animalMatches(prey, otherStar))) {
      const mod = ShizhanEngine.modifier(ruleA.note ?? '', lunarMonth, isDay);
      const v: InteractionVerdict = {
        favorable: '吉',
        text: `时禽${hourStar.star}制${otherStar.star}，我强彼弱${mod !== '' ? '（' + mod + '）' : ''}，所求可成。`,
        origin: '吞啖表'
      };
      return v;
    }
    // 彼吃时禽
    if (ruleB && ruleB.eats.some(prey => ShizhanEngine.animalMatches(prey, hourStar))) {
      const mod = ShizhanEngine.modifier(ruleB.note ?? '', lunarMonth, isDay);
      const v: InteractionVerdict = {
        favorable: '凶',
        text: `${otherStar.star}制时禽${hourStar.star}，彼强我弱${mod !== '' ? '（' + mod + '）' : ''}，事宜缓图。`,
        origin: '吞啖表'
      };
      return v;
    }
    // 时禽惧彼
    if (ruleA && ruleA.fears.some(prey => ShizhanEngine.animalMatches(prey, otherStar))) {
      const mod = ShizhanEngine.modifier(ruleA.note ?? '', lunarMonth, isDay);
      const v: InteractionVerdict = {
        favorable: '凶',
        text: `时禽${hourStar.star}畏${otherStar.star}${mod !== '' ? '（' + mod + '）' : ''}，其势不利，勿强出头。`,
        origin: '吞啖表'
      };
      return v;
    }
    // 彼惧时禽
    if (ruleB && ruleB.fears.some(prey => ShizhanEngine.animalMatches(prey, hourStar))) {
      const mod = ShizhanEngine.modifier(ruleB.note ?? '', lunarMonth, isDay);
      const v: InteractionVerdict = {
        favorable: '吉',
        text: `${otherStar.star}畏时禽${hourStar.star}，我势得位${mod !== '' ? '（' + mod + '）' : ''}，主动在我。`,
        origin: '吞啖表'
      };
      return v;
    }
    // 歌诀补充
    for (const rule of it.verse_rules) {
      if (rule.predator.some(p => ShizhanEngine.animalMatches(p, hourStar))
        && rule.prey.some(p => ShizhanEngine.animalMatches(p, otherStar))) {
        const v: InteractionVerdict = {
          favorable: '吉',
          text: `时禽${hourStar.star}制${otherStar.star}（歌诀），所求可成。`,
          origin: '歌诀'
        };
        return v;
      }
      if (rule.predator.some(p => ShizhanEngine.animalMatches(p, otherStar))
        && rule.prey.some(p => ShizhanEngine.animalMatches(p, hourStar))) {
        const v: InteractionVerdict = {
          favorable: '凶',
          text: `${otherStar.star}制时禽${hourStar.star}（歌诀），事宜缓图。`,
          origin: '歌诀'
        };
        return v;
      }
    }
    const none: InteractionVerdict = {
      favorable: '平',
      text: '时禽与彼无吞啖之涉，各安其位。',
      origin: ''
    };
    return none;
  }

  private static starInRule(rule: InteractionRule, animal: Animal): boolean {
    return rule.star.includes(animal.star) || rule.star.includes(animal.animal)
      || rule.star.includes(animal.full_name);
  }

  private static animalMatches(key: string, animal: Animal): boolean {
    return key.includes(animal.star) || key.includes(animal.animal)
      || key.includes(animal.full_name);
  }

  /** 季节/昼夜修正词（与 YanQinEngine.applyNoteModifier 同源） */
  private static modifier(note: string, lunarMonth: number, isDay: boolean): string {
    const mods: string[] = [];
    if (note.includes('夜生不忌') && !isDay) {
      mods.push('夜生不忌');
    }
    if (note.includes('春夏减半') && lunarMonth >= 1 && lunarMonth <= 6) {
      mods.push('春夏减半');
    }
    if (note.includes('秋冬不忌') && lunarMonth >= 7 && lunarMonth <= 12) {
      mods.push('秋冬不忌');
    }
    if (note.includes('冬不忌') && lunarMonth >= 10 && lunarMonth <= 12) {
      mods.push('冬不忌');
    }
    if (note.includes('四孟') && (lunarMonth === 1 || lunarMonth === 4 || lunarMonth === 7 || lunarMonth === 10)) {
      mods.push('四孟减半');
    }
    return mods.join('·');
  }
}
