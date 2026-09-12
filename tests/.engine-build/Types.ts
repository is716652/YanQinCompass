export interface CalendarDay {
  date: string;         // 公历日期（YYYY-MM-DD）
  year: number;         // 公历年
  month: number;        // 公历月
  day: number;          // 公历日
  lunar_year: number;   // 农历年
  lunar_month: number;  // 农历月
  lunar_day: number;    // 农历日
  zodiac: string;       // 生肖
  year_gan: string;     // 年干
  year_zhi: string;     // 年支
  month_gan: string;    // 月干
  month_zhi: string;    // 月支
  day_gan: string;      // 日干
  day_zhi: string;      // 日支
  week_day: number;     // 星期几（0=周一，6=周日）
  week_name: string;    // 星期名称
  is_holiday: number;   // 是否节假日（0=否，1=是）
  holiday_name: string; // 节假日名称
  solar_term: string;   // 节气
  festivals: string;    // 节日
}

export interface Animal {
  star: string;         // 星宿简称（如“角”）
  full_name: string;    // 星宿全称（如“角木蛟”）
  element: string;      // 七曜属性（木金土日月火水）
  animal: string;       // 对应的核心动物
  variations?: string[]; // 变体或别名
  note?: string;        // 特殊备注（如“明禽”、“暗禽”）
}

export interface InteractionRule {
  star: string;         // 代表星宿或动物名
  eats: string[];       // 该动物可以克制（吞食）的对象列表
  fears: string[];      // 该动物被克制（害怕）的对象列表
  source_text: string;  // 原文依据
  note?: string;        // 包含季节、昼夜等特殊修正条件
}

export interface VerseRule {
  predator: string[];   // 捕食者
  prey: string[];       // 被捕食者
}

export interface InteractionsData {
  relationships: InteractionRule[];
  verse_rules: VerseRule[];
}

export interface TransformationData {
  jiazi_map: Record<string, string[]>; // 六十甲子具体的环境意象
  stem_map: Record<string, string[]>;  // 十天干的通用意象
  branch_map: Record<string, string[]>; // 十二地支的通用意象
}
