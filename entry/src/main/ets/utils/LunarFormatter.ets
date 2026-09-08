/**
 * 农历月日 → 中文文案（如 八月初八、冬月廿三）。
 * 仅用于界面展示，不参与算法。
 */
export class LunarFormatter {
  private static readonly monthNames: string[] =
    ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"];
  private static readonly digitNames: string[] =
    ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"];

  static monthName(month: number): string {
    if (month >= 1 && month <= 12) {
      return `${LunarFormatter.monthNames[month - 1]}月`;
    }
    return `${month}月`;
  }

  static dayName(day: number): string {
    if (day < 1 || day > 30) {
      return `${day}日`;
    }
    if (day <= 10) {
      return `初${LunarFormatter.digitNames[day - 1]}`;
    }
    if (day <= 19) {
      return `十${LunarFormatter.digitNames[day - 11]}`;
    }
    if (day === 20) {
      return "二十";
    }
    if (day <= 29) {
      return `廿${LunarFormatter.digitNames[day - 21]}`;
    }
    return "三十";
  }

  /** 拼合月日，如 "八月初八" */
  static monthDay(month: number, day: number): string {
    return `${LunarFormatter.monthName(month)}${LunarFormatter.dayName(day)}`;
  }
}
