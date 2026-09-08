import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { Animal, InteractionsData, TransformationData, CalendarDay } from '../model/Types';

export interface AllData {
  animals: Animal[];
  interactions: InteractionsData;
  transformations: TransformationData;
  seasonalStrength: Record<string, string[]>;
}

export class DataLoader {
  private context: common.UIAbilityContext;
  // 万年历文件解析缓存（单文件约 1.6MB，避免选日期滚动时反复解析同一文件）
  private static calendarCache: Map<string, CalendarDay[]> = new Map();

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  /**
   * 读取 RawFile 中的 JSON 文件
   * @param filename 文件名 (如 "animals.json")
   */
  async loadJson<T>(filename: string): Promise<T> {
    try {
      console.info(`[DataLoader] Start loading ${filename}`);
      const resourceManager = this.context.resourceManager;
      const fileData = await resourceManager.getRawFileContent(filename);
      console.info(`[DataLoader] Loaded ${filename}, size: ${fileData.length}`);
      
      const textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      const jsonString = textDecoder.decodeWithStream(fileData);
      // console.info(`[DataLoader] JSON string preview: ${jsonString.substring(0, 100)}`);
      
      const result = JSON.parse(jsonString) as T;
      console.info(`[DataLoader] Parsed ${filename} successfully`);
      return result;
    } catch (error) {
      console.error(`[DataLoader] Failed to load ${filename}:`, error);
      throw new Error(`Failed to load ${filename}: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 加载指定公历日期的万年历数据
   * @param year 公历年（1900-2061）
   * @param month 公历月（1-12）
   * @param day 公历日（1-31）
   */
  async loadCalendarDay(year: number, month: number, day: number): Promise<CalendarDay> {
    // 文件编号：calendar_data_0001.json 覆盖 1900-1909，每 10 年一个文件，0017 覆盖 2060-2061
    let index = Math.floor((year - 1900) / 10) + 1;
    if (index < 1) {
      index = 1;
    }
    if (index > 17) {
      index = 17;
    }
    const padded = index.toString().padStart(4, '0');
    const filename = `calendar/calendar_data_${padded}.json`;
    const cached = DataLoader.calendarCache.get(filename);
    let days: CalendarDay[];
    if (cached !== undefined) {
      days = cached;
    } else {
      days = await this.loadJson<CalendarDay[]>(filename);
      DataLoader.calendarCache.set(filename, days);
    }
    const target = `${year}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`;
    const found = days.find(d => d.date === target);
    if (!found) {
      throw new Error(`万年历无此日期: ${target}`);
    }
    return found;
  }

  /**
   * 加载所有核心数据
   */
  async loadAllData(): Promise<AllData> {
    const animals = await this.loadJson<Animal[]>('animals.json');
    const interactions = await this.loadJson<InteractionsData>('interactions.json');
    const transformations = await this.loadJson<TransformationData>('transformations.json');
    const seasonalStrength = await this.loadJson<Record<string, string[]>>('seasonal_strength.json');
    
    return {
      animals,
      interactions,
      transformations,
      seasonalStrength
    };
  }
}
