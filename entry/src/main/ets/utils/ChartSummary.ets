import { YanQinChart } from '../model/ChartModels';

const SEASON_NAMES: Record<string, string> = {
  "spring": "春", "summer": "夏", "autumn": "秋", "winter": "冬", "earth": "四季末"
};

/**
 * 排盘结果 → 白话总评（结果页顶部一段话）。
 * 仅做已有结论的组织表达，不引入新的推断；明暗禽断语出自《演禽通纂·星禽好乐篇》
 * "日值夜则凶，夜值日则贱"的柔和化表述。
 */
export class ChartSummary {
  static build(chart: YanQinChart): string {
    const parts: string[] = [];
    const main = chart.masterStar;

    let head = `本命主星为${main.full_name}（${main.element}宿）`;
    if (chart.isDay !== undefined) {
      head += chart.isDay ? "，生于昼间" : "，生于夜间";
    }
    parts.push(head + "。");

    if (chart.isDay !== undefined && main.note === "明禽") {
      parts.push(chart.isDay ? "明禽昼生，正得其所，光华可达。" : "明禽夜生，光华暂掩，宜静待时机。");
    } else if (chart.isDay !== undefined && main.note === "暗禽") {
      parts.push(chart.isDay ? "暗禽昼生，锋芒内敛，宜沉潜蓄势。" : "暗禽夜生，正得其所，谋定而后动。");
    }

    const seasonName: string = chart.season !== undefined ? (SEASON_NAMES[chart.season] ?? "") : "";
    if (seasonName !== "") {
      const tierDesc: Record<string, string> = {
        "旺": "当令而旺，得时得势",
        "相": "次旺得助",
        "休": "暂处休地",
        "囚": "受制囚地，宜守不宜进",
        "死": "失时陷死地，宜静待时机"
      };
      const label = chart.season === "earth" ? "四季末" : `${seasonName}季`;
      const desc = tierDesc[chart.seasonalStrength] ?? "状态平平";
      parts.push(`${label}主星${desc}。`);
    }

    let lucky = 0;
    let fierce = 0;
    for (const item of chart.interactions) {
      if (item.includes("吉")) {
        lucky++;
      }
      if (item.includes("凶")) {
        fierce++;
      }
    }
    if (lucky > 0 && lucky >= fierce) {
      parts.push("诸星吞啖以吉为主，主得势得助。");
    } else if (fierce > lucky) {
      parts.push("吞啖之中克我者众，行事宜谨慎守成。");
    } else {
      parts.push("诸星相安，吞啖不显。");
    }
    return parts.join("");
  }
}
