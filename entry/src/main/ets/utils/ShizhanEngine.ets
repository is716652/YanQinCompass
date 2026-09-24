import { Animal } from '../model/Types';

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

  public static init(table: HourStarTable, palace: PalaceAffinityData,
                     seasonal: Record<string, Record<string, string[]>>, animals: Animal[]): void {
    ShizhanEngine.table = table;
    ShizhanEngine.palaceData = palace;
    ShizhanEngine.seasonal = seasonal;
    ShizhanEngine.animals = animals;
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
}
