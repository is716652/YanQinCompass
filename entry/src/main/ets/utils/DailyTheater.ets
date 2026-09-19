import { StarEntry } from '../model/BestiaryModels';

/** 泊宫课名条目 */
interface GuanmingEntry {
  palace: string;
  name: string;
}

/**
 * 每日禽星占断文案生成器
 *
 * 输入：值日星（28 宿简称）+ 日柱地支 + 图鉴泊宫课名 + 化道意象
 * 输出：一段占断文案（泊宫课名 + 化道意象）
 *
 * 断语素材：泊宫课名出自《禽星易见》逐宿详解（如箕泊子"镜挂妆台"、
 * 参泊寅"猿啼夜月"），化道意象出自《演禽通纂》六十甲子总取化道。
 */
export class DailyTheater {
  /** 生成占断文案（泊宫课名与化道意象拼合，无则给中性句） */
  static build(starFull: string, dayZhi: string,
               guanming: GuanmingEntry[] | undefined, huaDao: string[]): string {
    const parts: string[] = [];

    const gm = guanming !== undefined
      ? guanming.find((g) => g.palace === dayZhi)
      : undefined;
    if (gm !== undefined) {
      parts.push(`泊${dayZhi}入「${gm.name}」之宫`);
    }

    if (huaDao.length > 0) {
      parts.push(`化道现：${huaDao.slice(0, 3).join('、')}`);
    }

    if (parts.length === 0) {
      return `今日值日·${starFull}，盘中星象平顺。`;
    }
    return parts.join('；') + '。';
  }
}
