import type { Animal } from './Types.ts';

// 演禽排盘结果模型
export interface YanQinChart {
  masterStar: Animal;     // 主星
  embryoStar: Animal;     // 胎星
  lifeStar: Animal;       // 命星
  bodyStar: Animal;       // 身星
  lifePalace: string;     // 命宫 (干支)
  bodyPalace: string;     // 身宫 (干支)
  xunHead: string;        // 旬头 (干支，如 "甲申")
  xunStar: Animal;        // 旬头星
  // 星宫绑定与限运（标准命盘布局，见 规则/演禽命盘标准布局.md）
  embryoPalace?: string;      // 胎宫干支（主胎宫例：年支起正月顺数）
  shouPalace?: string;        // 寿宫干支
  shouStar?: Animal;          // 寿星
  fortuneStartAge?: number;   // 起运岁数（水1火2木3金4土5日6月7）
  fortuneList?: string[];     // 大运干支序列（第n运起岁 = startAge + (n-1)*10）
  // 流运信息
  currentYearStar?: Animal; // 流年星
  currentDayStar?: Animal;  // 流日星
  season?: string;          // 出生季节（spring/summer/autumn/winter，按农历月）
  isDay?: boolean;          // 昼生/夜生（5-18 点为昼，与引擎昼夜判定一致）
  lunarMonth?: number;      // 农历月（1-12；格局判定的"二八月/三月"类条件用）
  // 综合分析
  huaDao: string[];       // 化道环境 (如 ["虎入焚山", "龙入大海"])
  interactions: string[]; // 吞啖关系描述 (如 ["主星克流年星(吉)", "流年星克胎星(凶)"])
  seasonalStrength: string; // 四时生旺状态 (如 "旺", "相", "休", "囚")
}

// 用户输入模型
export interface UserInput {
  solarDate: Date;        // 公历出生日期
  timeHour: number;       // 出生时辰 (0-23)
  gender: 'male' | 'female'; // 性别
  name?: string;          // 姓名 (可选)
}
