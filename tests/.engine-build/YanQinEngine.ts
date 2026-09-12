import type { Animal, InteractionRule, TransformationData, InteractionsData, CalendarDay } from './Types.ts';
import type { YanQinChart, UserInput } from './ChartModels.ts';

/**
 * 演禽排盘引擎（古法）
 *
 * 算法依据（《演禽通纂》原文 + 规则/algorithm_explanation.md）：
 * - 起旬头：生年干支倒推十干至甲，得旬头（甲子/甲寅/甲辰/甲午/甲申/甲戌），按三元（上中下）查旬头星
 * - 起主星：从旬头星下一位起数生日宿数，所得星宿安于子宫（归子），再从子宫顺数至命宫，即主星
 * - 胎星：主星下一位
 * - 命宫：子上起正月逆数至生月，从该位起子时顺数至生时
 * - 命星：胎星之合宿（六合）从子宫顺数至命宫
 * - 身宫：(月数x2+日数)从子宫逆数
 * - 身星：命星之合宿从子宫顺数至身宫
 * - 流年星：以胎星作一岁，顺数至当前虚岁
 * - 男女除补：男命数星遇"牛金牛"不数，女命遇"女土蝠"不数（终点恰好是牛/女则不除；闰月不除，因数据无闰月字段暂略）
 *
 * 注：原文"起命星例"（安命丙申宫）与"起主胎星例"（到巳为住）的命宫存在版本差异，
 * 此处采用与主星例自洽、且 algorithm_explanation.md §2.3 明文记载的命宫公式。
 */
export class YanQinEngine {
  private animals: Animal[] = [];
  private interactions: InteractionsData | null = null;
  private transformations: TransformationData | null = null;
  // 四档旺衰表：season -> (tier -> 星宿简称列表)，据《禽星辑要》15.5 整理
  private seasonalStrength: Record<string, Record<string, string[]>> | null = null;

  // 二十八宿顺序 (按角木蛟开始)
  private readonly starsOrder = [
    "角", "亢", "氐", "房", "心", "尾", "箕", // 东方青龙
    "斗", "牛", "女", "虚", "危", "室", "壁", // 北方玄武
    "奎", "娄", "胃", "昴", "毕", "觜", "参", // 西方白虎
    "井", "鬼", "柳", "星", "张", "翼", "轸"  // 南方朱雀
  ];

  // 十天干
  private readonly heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"];
  // 十二地支
  private readonly earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"];

  // 合宿表（六合，双向）：角昴亢胃氐娄，奎房心壁斗虚，箕危尾室牛女，觜翼参张柳鬼，毕轸井星
  private readonly harmonyMap: Record<string, string> = {
    "角": "昴", "昴": "角", "亢": "胃", "胃": "亢", "氐": "娄", "娄": "氐",
    "奎": "房", "房": "奎", "心": "壁", "壁": "心", "斗": "虚", "虚": "斗",
    "箕": "危", "危": "箕", "尾": "室", "室": "尾", "牛": "女", "女": "牛",
    "觜": "翼", "翼": "觜", "参": "张", "张": "参", "柳": "鬼", "鬼": "柳",
    "毕": "轸", "轸": "毕", "井": "星", "星": "井"
  };

  // 旬头星表：旬头地支序号 -> [上元, 中元, 下元]（星宿简称）
  private readonly xunStarMap: Record<number, string[]> = {
    0: ["箕", "鬼", "角"],   // 甲子
    2: ["氐", "毕", "星"],   // 甲寅
    4: ["参", "斗", "奎"],   // 甲辰
    6: ["虚", "张", "房"],   // 甲午
    8: ["轸", "娄", "井"],   // 甲申
    10: ["昴", "心", "危"]   // 甲戌
  };

  constructor() {}

  /**
   * 初始化数据
   * @param animals 禽星数据
   * @param interactions 吞啖数据
   * @param transformations 化道数据
   * @param seasonalStrength 四时生旺数据
   */
  public init(animals: Animal[], interactions: InteractionsData, transformations: TransformationData, seasonalStrength: Record<string, Record<string, string[]>>) {
    this.animals = animals;
    this.interactions = interactions;
    this.transformations = transformations;
    this.seasonalStrength = seasonalStrength;
  }

  /**
   * 核心排盘函数（古法）
   * @param input 用户输入
   * @param calendarDay 万年历当日数据
   */
  public calculateChart(input: UserInput, calendarDay: CalendarDay): YanQinChart {
    const lunarMonth = calendarDay.lunar_month;
    const lunarDay = calendarDay.lunar_day;
    const lunarYear = calendarDay.lunar_year;
    const skipStar = input.gender === 'male' ? '牛' : '女';

    // 1. 起旬头：年干支倒推十干至甲，定旬头地支；按三元查旬头星
    const yearGan = calendarDay.year_gan;
    const yearZhi = calendarDay.year_zhi;
    const ganIdx = this.heavenlyStems.indexOf(yearGan);
    const zhiIdx = this.earthlyBranches.indexOf(yearZhi);
    const xunZhiIdx = (((zhiIdx - ganIdx) % 12) + 12) % 12;
    const xunHead = '甲' + this.earthlyBranches[xunZhiIdx];
    const yuan = this.getYuan(lunarYear);
    const xunStarName = this.xunStarMap[xunZhiIdx][yuan];
    const xunStar = this.getAnimalByName(xunStarName);

    // 2. 命宫：子上起正月，逆数至生月；从该位起子时，顺数至生时
    const timeBranch = Math.floor((input.timeHour + 1) / 2) % 12; // 子=0, 丑=1...
    const mingGong = (((0 - (lunarMonth - 1) + timeBranch) % 12) + 12) % 12;

    // 3. 起主星：从旬头星下一位起数生日宿数 -> 归子位 -> 顺数至命宫（子=0，故命宫位需数 mingGong+1 个）
    const xunStarIdx = this.starsOrder.indexOf(xunStarName);
    const guiZiIdx = this.countStars(xunStarIdx, lunarDay, skipStar);
    const masterIdx = this.countStars(guiZiIdx - 1, mingGong + 1, skipStar);
    const masterStar = this.getAnimalByName(this.starsOrder[masterIdx]);

    // 4. 胎星 = 主星下一位（不除牛女）
    const embryoIdx = (masterIdx + 1) % 28;
    const embryoStar = this.getAnimalByName(this.starsOrder[embryoIdx]);

    // 5. 命星：胎星合宿从子宫顺数至命宫
    const lifeStar = this.getStarByHarmony(embryoStar.star, mingGong, skipStar);

    // 6. 身宫：(月数x2+日数) 从子宫逆数；身星：命星合宿从子宫顺数至身宫
    const shenCount = lunarMonth * 2 + lunarDay;
    const shenGong = (((0 - (shenCount - 1)) % 12) + 12) % 12;
    const bodyStar = this.getStarByHarmony(lifeStar.star, shenGong, skipStar);

    // 6.5 标准命盘布局补全（规则/演禽命盘标准布局.md）
    // 胎宫（起主胎宫例）：年支起正月顺数至生月→顺数至生日→顺数至生时
    const taiStep1 = (zhiIdx + lunarMonth - 1) % 12;
    const taiStep2 = (taiStep1 + lunarDay - 1) % 12;
    const taiGongIdx = (taiStep2 + timeBranch) % 12;
    const embryoPalace = this.getPalaceGanZhi(yearGan, taiGongIdx);
    // 寿宫（起寿宫例）：年支对冲，阳男阴女取冲前一位，阴男阳女取冲后一位
    const male = input.gender === 'male';
    const yangYear = "甲丙戊庚壬".includes(yearGan);
    const chong = (zhiIdx + 6) % 12;
    const shouGongIdx = (yangYear === male) ? (chong + 1) % 12 : (chong + 11) % 12;
    const shouPalace = this.getPalaceGanZhi(yearGan, shouGongIdx);
    // 寿星（起寿星例）：命星起子顺数至寿宫（命身寿数星不除牛女）
    const lifeStarIdx = this.starsOrder.indexOf(lifeStar.star);
    const shouStarIdx = this.countStars(lifeStarIdx - 1, shouGongIdx + 1, null);
    const shouStar = this.getAnimalByName(this.starsOrder[shouStarIdx]);
    // 大运（起大运例）：自主星落宫（命宫）起，起运岁数水1火2木3金4土5日6月7，
    // 主星落宫天干阳年男顺/阴年男逆，女反之；每十年一运
    const ageMap: Record<string, number> = { "水": 1, "火": 2, "木": 3, "金": 4, "土": 5, "日": 6, "月": 7 };
    const fortuneStartAge = ageMap[masterStar.element] ?? 3;
    const lifeGan = this.getPalaceGanZhi(yearGan, mingGong)[0];
    const isYangGan = "甲丙戊庚壬".includes(lifeGan);
    const forward = male ? isYangGan : !isYangGan;
    const lifeGanIdx = this.heavenlyStems.indexOf(lifeGan);
    const fortuneList: string[] = [];
    for (let n = 0; n < 9; n++) {
      const off = forward ? n : -n;
      const g = ((lifeGanIdx + off) % 10 + 10) % 10;
      const z = ((mingGong + off) % 12 + 12) % 12;
      fortuneList.push(this.heavenlyStems[g] + this.earthlyBranches[z]);
    }

    // 7. 流年星：以胎星作一岁，顺数至当前虚岁（不除牛女）
    const currentYear = new Date().getFullYear();
    const virtualAge = currentYear - input.solarDate.getFullYear() + 1;
    const currentYearIdx = (embryoIdx + (virtualAge - 1)) % 28;
    const currentYearStar = this.getAnimalByName(this.starsOrder[currentYearIdx]);

    // 8. 化道环境（年/月/日/时四柱）
    const huaDaoList = this.buildHuaDao(calendarDay, timeBranch);

    // 9. 吞啖关系（主胎、主流年、胎流年）+ 季节/昼夜修正
    const interactionList: string[] = [];
    const isDay = input.timeHour >= 5 && input.timeHour < 18;
    const rel1 = this.checkInteraction(masterStar, embryoStar, lunarMonth, isDay);
    if (rel1) {
      interactionList.push(`主胎关系: ${rel1}`);
    }
    const rel2 = this.checkInteraction(masterStar, currentYearStar, lunarMonth, isDay);
    if (rel2) {
      interactionList.push(`主星vs流年: ${rel2}`);
    }
    const rel3 = this.checkInteraction(embryoStar, currentYearStar, lunarMonth, isDay);
    if (rel3) {
      interactionList.push(`胎星vs流年: ${rel3}`);
    }
    const verse = this.checkVerse(masterStar, currentYearStar);
    if (verse) {
      interactionList.push(`吞啖歌: ${verse}`);
    }

    // 10. 四时生旺
    const season = this.getSeason(lunarMonth);
    const seasonalStatus = this.getSeasonalStrength(masterStar.star, season);

    return {
      masterStar,
      embryoStar,
      lifeStar,
      bodyStar,
      lifePalace: this.getPalaceGanZhi(yearGan, mingGong),
      bodyPalace: this.getPalaceGanZhi(yearGan, shenGong),
      xunHead,
      xunStar,
      currentYearStar,
      embryoPalace,
      shouPalace,
      shouStar,
      fortuneStartAge,
      fortuneList,
      huaDao: huaDaoList,
      interactions: interactionList,
      seasonalStrength: seasonalStatus,
      season,
      isDay
    };
  }

  // --- Helpers ---

  /** 三元判定：1864 起每 180 年一轮，0-59 上元，60-119 中元，120-179 下元 */
  private getYuan(lunarYear: number): number {
    let idx = (lunarYear - 1864) % 180;
    if (idx < 0) {
      idx += 180;
    }
    if (idx < 60) {
      return 0;
    }
    if (idx < 120) {
      return 1;
    }
    return 2;
  }

  /**
   * 数星：从 startIndex 的下一位起数 count 个星宿（不含起点本身）。
   * 若 skipStar 非空且被经过（非终点）则跳过不计；终点恰好是 skipStar 时照常计入。
   */
  private countStars(startIndex: number, count: number, skipStar: string | null): number {
    let idx = startIndex;
    let counted = 0;
    while (counted < count) {
      idx = (idx + 1) % 28;
      const star = this.starsOrder[idx];
      if (skipStar !== null && star === skipStar && counted < count - 1) {
        continue;
      }
      counted++;
    }
    return idx;
  }

  /** 起命星/身星：某星之合宿安子宫，顺数 palaceIndex 位（子=0，故需数 palaceIndex+1 个） */
  private getStarByHarmony(starName: string, palaceIndex: number, skipStar: string | null): Animal {
    const harmony = this.harmonyMap[starName] ?? starName;
    const harmonyIdx = this.starsOrder.indexOf(harmony);
    const targetIdx = this.countStars(harmonyIdx - 1, palaceIndex + 1, skipStar);
    return this.getAnimalByName(this.starsOrder[targetIdx]);
  }

  /** 宫位干支：五虎遁（年干定正月干，命/身宫按地支月序推干） */
  private getPalaceGanZhi(yearGan: string, branchIndex: number): string {
    // 五虎遁：甲己丙作首，乙庚戊为头，丙辛庚寅起，丁壬壬寅位，戊癸甲寅求
    const startMap: Record<string, number> = {
      "甲": 2, "己": 2, "乙": 4, "庚": 4, "丙": 6, "辛": 6, "丁": 8, "壬": 8, "戊": 0, "癸": 0
    };
    const start = startMap[yearGan] ?? 2;
    const monthPos = ((branchIndex - 2) % 12 + 12) % 12; // 寅=0月...丑=11月
    const gan = this.heavenlyStems[(start + monthPos) % 10];
    return gan + this.earthlyBranches[branchIndex];
  }

  /** 时干：五鼠遁（日干起子时干） */
  private getHourGan(dayGan: string, timeBranch: number): string {
    const startMap: Record<string, number> = {
      "甲": 0, "己": 0, "乙": 2, "庚": 2, "丙": 4, "辛": 4, "丁": 6, "壬": 6, "戊": 8, "癸": 8
    };
    const start = startMap[dayGan] ?? 0;
    return this.heavenlyStems[(start + timeBranch) % 10];
  }

  /** 化道：年/月/日/时四柱干支查六十甲子环境意象 */
  private buildHuaDao(calendarDay: CalendarDay, timeBranch: number): string[] {
    const result: string[] = [];
    if (!this.transformations) {
      return result;
    }
    const hourGan = this.getHourGan(calendarDay.day_gan, timeBranch);
    const pillars: string[][] = [
      [`年柱`, calendarDay.year_gan + calendarDay.year_zhi],
      [`月柱`, calendarDay.month_gan + calendarDay.month_zhi],
      [`日柱`, calendarDay.day_gan + calendarDay.day_zhi],
      [`时柱`, hourGan + this.earthlyBranches[timeBranch]]
    ];
    for (const pillar of pillars) {
      const envs = this.transformations.jiazi_map[pillar[1]];
      if (envs && envs.length > 0) {
        result.push(`${pillar[0]}[${pillar[1]}]: ${envs.join('、')}`);
      }
    }
    return result;
  }

  /** 季节（按农历月）：1-2 春，3 四季末，4-5 夏，6 四季末，7-8 秋，9 四季末，10-11 冬，12 四季末 */
  private getSeason(lunarMonth: number): string {
    if (lunarMonth === 3 || lunarMonth === 6 || lunarMonth === 9 || lunarMonth === 12) {
      return "earth";
    }
    if (lunarMonth <= 2) {
      return "spring";
    }
    if (lunarMonth <= 5) {
      return "summer";
    }
    if (lunarMonth <= 8) {
      return "autumn";
    }
    if (lunarMonth <= 11) {
      return "winter";
    }
    return "spring";
  }

  /** 四档旺衰：旺=当令、相=我生、休=生我、囚=我克、死=克我（《禽星辑要》15.5） */
  private getSeasonalStrength(starName: string, season: string): string {
    if (this.seasonalStrength && this.seasonalStrength[season]) {
      const tiers = this.seasonalStrength[season];
      const tierNames: string[] = ["旺", "相", "休", "囚", "死"];
      for (const tier of tierNames) {
        const list = tiers[tier];
        if (list && list.includes(starName)) {
          return tier;
        }
      }
    }
    return "休";
  }

  private getAnimalByName(name: string): Animal {
    return this.animals.find(a => a.star === name || a.full_name === name) || {
      star: name, full_name: name + "未知", element: "未知", animal: "未知"
    };
  }

  /**
   * 吞啖判定（含季节/昼夜修正）
   * 命中修正词且当前情况满足时，追加修正标注；"减半"类修正附加"·减半"提示。
   */
  private checkInteraction(a: Animal, b: Animal, lunarMonth: number, isDay: boolean): string | null {
    if (!this.interactions) {
      return null;
    }

    // 查找 a 是否吃 b
    const ruleA = this.interactions.relationships.find(r => this.starInRule(r, a));
    if (ruleA && ruleA.eats.some(prey => this.animalMatches(prey, b))) {
      const mod = this.applyNoteModifier(ruleA.note ?? '', lunarMonth, isDay);
      return `${a.star} 克 ${b.star} (吉${mod})`;
    }

    // 查找 b 是否吃 a
    const ruleB = this.interactions.relationships.find(r => this.starInRule(r, b));
    if (ruleB && ruleB.eats.some(prey => this.animalMatches(prey, a))) {
      const mod = this.applyNoteModifier(ruleB.note ?? '', lunarMonth, isDay);
      return `${b.star} 克 ${a.star} (凶${mod})`;
    }

    // 查找 a 是否怕 b（fears 为该动物被克制/害怕的对象，即 b 克 a）
    if (ruleA && ruleA.fears.some(prey => this.animalMatches(prey, b))) {
      const mod = this.applyNoteModifier(ruleA.note ?? '', lunarMonth, isDay);
      return `${b.star} 克 ${a.star} (凶${mod})`;
    }

    // 查找 b 是否怕 a（即 a 克 b）
    if (ruleB && ruleB.fears.some(prey => this.animalMatches(prey, a))) {
      const mod = this.applyNoteModifier(ruleB.note ?? '', lunarMonth, isDay);
      return `${a.star} 克 ${b.star} (吉${mod})`;
    }

    return null;
  }

  /** 规则主体（如"子天鼠"）是否匹配该禽星：按星简称/动物名/全称子串匹配 */
  private starInRule(rule: InteractionRule, animal: Animal): boolean {
    return rule.star.includes(animal.star) || rule.star.includes(animal.animal) || rule.star.includes(animal.full_name);
  }

  /** 捕食对象是否匹配该禽星 */
  private animalMatches(key: string, animal: Animal): boolean {
    return key.includes(animal.star) || key.includes(animal.animal) || key.includes(animal.full_name);
  }

  /** 吞啖歌诀补充规则 */
  private checkVerse(a: Animal, b: Animal): string | null {
    if (!this.interactions) {
      return null;
    }
    for (const rule of this.interactions.verse_rules) {
      if (rule.predator.some(p => this.animalMatches(p, a)) && rule.prey.some(p => this.animalMatches(p, b))) {
        return `${a.star} 克 ${b.star} (吉·歌诀)`;
      }
      if (rule.predator.some(p => this.animalMatches(p, b)) && rule.prey.some(p => this.animalMatches(p, a))) {
        return `${b.star} 克 ${a.star} (凶·歌诀)`;
      }
    }
    return null;
  }

  /**
   * 应用吞啖规则 note 中的季节/昼夜修正标注。
   * 修正词与当前情况（农历月、昼夜）均命中时才标注。
   */
  private applyNoteModifier(note: string, lunarMonth: number, isDay: boolean): string {
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
    if (note.includes('正、九月') && (lunarMonth === 1 || lunarMonth === 9)) {
      mods.push('正九月有灾');
    }
    if (note.includes('凶星不忌')) {
      mods.push('凶星不忌');
    }
    return mods.length > 0 ? '·' + mods.join('·') : '';
  }
}
