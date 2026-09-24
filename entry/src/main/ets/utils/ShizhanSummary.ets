import { Animal } from '../model/Types';
import { ShizhanVerdict } from './ShizhanEngine';

const SEASON_NAMES: Record<string, string> = {
  "spring": "春", "summer": "夏", "autumn": "秋", "winter": "冬", "earth": "四季末"
};

/**
 * 时占白话断语组装（表达层）——判定要素全部来自 ShizhanEngine，此处只做组织表达。
 */
export class ShizhanSummary {
  static build(star: Animal, zhi: string, v: ShizhanVerdict, season: string): string {
    const parts: string[] = [];
    parts.push(`时禽${star.full_name}泊${zhi}宫，入「${v.palaceName}」，宫性${v.favorable}。`);
    parts.push(`${v.flyingText}。`);
    const seasonLabel = season === 'earth' ? '四季末' : (SEASON_NAMES[season] ?? '') + '季';
    parts.push(`${seasonLabel}时禽处「${v.strength}」。`);
    if (v.favorable === '吉') {
      parts.push('用事得地，可乘时而动。');
    } else if (v.favorable === '凶') {
      parts.push('宫性相逆，宜守不宜进。');
    } else {
      parts.push('宫性平和，事可徐图。');
    }
    return parts.join('');
  }
}
