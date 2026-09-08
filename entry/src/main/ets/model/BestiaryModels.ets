/** 二十八宿图鉴数据模型（数据源 rawfile/bestiary.json，整理自《禽星易见》逐宿详解） */

/** 泊宫课名（如 午→龙奔枯井） */
export interface GuanMing {
  palace: string;
  name: string;
}

/** 单宿条目 */
export interface StarEntry {
  star: string;        // 宿简称（角/亢/…，亦为神兽图资源键）
  fullName: string;    // 全名（角木蛟）
  element: string;     // 七曜（木金土日月火水）
  animal: string;      // 神兽（蛟/龙/…）
  heavenName: string;  // 天上星名（华盖星…）
  starCount: string;   // 星数（二星…）
  active: string;      // 昼禽/夜禽（《禽星易见》：日禽十六昼动，夜禽十二夜行）
  note: string;        // 明禽/暗禽（《演禽通纂》标注，可能为空）
  jiang: string;       // 将星所属元
  palace: string;      // 元宫（地支）
  he: string;          // 合
  shi: string;         // 食（吞啖）
  wei: string;         // 畏
  desc: string;        // 形性描述（据《禽星易见》整理）
  guanming: GuanMing[]; // 泊宫课名
}

/** 四象分组（东方青龙七宿等） */
export interface StarGroup {
  name: string;
  verse: string;
  stars: StarEntry[];
}

/** 图鉴整体数据 */
export interface BestiaryData {
  groups: StarGroup[];
}
