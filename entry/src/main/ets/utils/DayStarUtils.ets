/**
 * 七元甲子值日禽星算法（《禽星易见》体系）
 *
 * 锚点：1984-02-02 为一元甲子日，起虚日鼠（与姐妹项目禽星盘式同源，七元将头
 * 已逐项比对《禽星易见》一致）。420 日一循环（7 元 × 60 日），每元四将各管 15 日，
 * 将星起顺数至第几宿即当日值宿。
 */
const STAR_ORDER: string[] = [
  "角", "亢", "氐", "房", "心", "尾", "箕",
  "斗", "牛", "女", "虚", "危", "室", "壁",
  "奎", "娄", "胃", "昴", "毕", "觜", "参",
  "井", "鬼", "柳", "星", "张", "翼", "轸"
];
const STAR_FULL: string[] = [
  "角木蛟", "亢金龙", "氐土狢", "房日兔", "心月狐", "尾火虎", "箕水豹",
  "斗木獬", "牛金牛", "女土蝠", "虚日鼠", "危月燕", "室火猪", "壁水貐",
  "奎木狼", "娄金狗", "胃土雉", "昴日鸡", "毕月乌", "觜火猴", "参水猿",
  "井木犴", "鬼金羊", "柳土獐", "星日马", "张月鹿", "翼火蛇", "轸水蚓"
];
const STAR_ELEMENT: string[] = [
  "木", "金", "土", "日", "月", "火", "水",
  "木", "金", "土", "日", "月", "火", "水",
  "木", "金", "土", "日", "月", "火", "水",
  "木", "金", "土", "日", "月", "火", "水"
];
const YUAN_NAMES: string[] = ["一元", "二元", "三元", "四元", "五元", "六元", "七元"];
// 七元四将（每将管十五日），据《禽星易见》七元二十八将歌
const GENERALS: string[][] = [
  ["虚", "张", "室", "轸"],
  ["奎", "亢", "胃", "房"],
  ["毕", "尾", "参", "斗"],
  ["鬼", "女", "星", "危"],
  ["翼", "壁", "角", "娄"],
  ["氐", "昴", "心", "觜"],
  ["箕", "井", "牛", "柳"]
];

export interface DayStarResult {
  star: string;       // 值日宿简称
  fullName: string;   // 全名
  element: string;    // 七曜
  yuanName: string;   // 元名（一元…七元）
  yuan: number;       // 元号（1-7，时禽起例用）
  cycleDayIndex: number; // 420 日循环内日序（0-419）
  jiangIndex: number; // 第几将（1-4）
  jiangStar: string;  // 将星简称
}

export class DayStarUtils {
  /** 计算公历某日的值日禽星 */
  static calc(year: number, month: number, day: number): DayStarResult {
    const base = new Date(1984, 1, 2); // 1984-02-02 一元甲子日起虚
    const target = new Date(year, month - 1, day);
    const diffDays = Math.floor((target.getTime() - base.getTime()) / 86400000);
    const pos = ((diffDays % 420) + 420) % 420;
    const yuanIdx = Math.floor(pos / 60);
    const jiangIdx = Math.floor((pos % 60) / 15);
    const dayInJiang = pos % 15;
    const jiangStar = GENERALS[yuanIdx][jiangIdx];
    const idx = (STAR_ORDER.indexOf(jiangStar) + dayInJiang) % 28;
    return {
      star: STAR_ORDER[idx],
      fullName: STAR_FULL[idx],
      element: STAR_ELEMENT[idx],
      yuanName: YUAN_NAMES[yuanIdx],
      yuan: yuanIdx + 1,
      cycleDayIndex: pos,
      jiangIndex: jiangIdx + 1,
      jiangStar: jiangStar
    };
  }
}
