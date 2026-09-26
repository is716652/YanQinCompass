import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { DataLoader } from '../utils/DataLoader';
import { Theme } from '../utils/Theme';
import { Animal } from '../model/Types';
import { DayStarResult, DayStarUtils } from '../utils/DayStarUtils';
import { HourStarTable, PalaceAffinityData, ShizhanEngine, ShizhanVerdict } from '../utils/ShizhanEngine';
import { ShizhanSummary } from '../utils/ShizhanSummary';
import { CalendarDay } from '../model/Types';
import { Purchases } from '../utils/Purchases';

/** 十二时辰（rep = 昼夜判定代表小时，与引擎 5-18 昼口径一致） */
interface ShichenItem {
  zhi: string;
  label: string;
  rep: number;
}

const SHICHEN: ShichenItem[] = [
  { zhi: '子', label: '23-01', rep: 0 },
  { zhi: '丑', label: '01-03', rep: 2 },
  { zhi: '寅', label: '03-05', rep: 4 },
  { zhi: '卯', label: '05-07', rep: 6 },
  { zhi: '辰', label: '07-09', rep: 8 },
  { zhi: '巳', label: '09-11', rep: 10 },
  { zhi: '午', label: '11-13', rep: 12 },
  { zhi: '未', label: '13-15', rep: 14 },
  { zhi: '申', label: '15-17', rep: 16 },
  { zhi: '酉', label: '17-19', rep: 18 },
  { zhi: '戌', label: '19-21', rep: 20 },
  { zhi: '亥', label: '21-23', rep: 22 }
];

const FREE_LIMIT = 3;   // 每日免费起盘次数（IAP 集成前的转化钩子，超出显示锁定卡）

/**
 * 演禽时占 · 问事择时（《禽星易见》七元时禽法）
 * 起盘 = 当日元号 + 值日宿七曜 → 子时起星顺数至占时；判定 = ShizhanEngine（数据/算法/页面三层分离）。
 */
@Entry
@Component
struct ShizhanPage {
  @State loaded: boolean = false;
  @State errorMessage: string = '';
  @State shichenIndex: number = 0;
  @State resultStar: Animal | null = null;
  @State resultZhi: string = '';
  @State result: ShizhanVerdict | null = null;
  @State summary: string = '';
  @State freeLeft: number = FREE_LIMIT;
  @State limitHit: boolean = false;
  @State premium: boolean = false;
  @StorageProp('statusBarPx') statusBarPx: number = 0;
  @StorageProp('navBarPx') navBarPx: number = 0;
  private dayRes: DayStarResult | null = null;
  private season: string = 'spring';
  private lunarText: string = '';

  aboutToAppear(): void {
    const d = new Date();
    this.shichenIndex = ShizhanPage.nowShichen(d.getHours());
    this.freeLeft = FREE_LIMIT - ShizhanPage.usedToday();
    const context = getContext(this) as common.UIAbilityContext;
    Purchases.init(context);
    Purchases.refreshOwned().then((owned: boolean) => {
      this.premium = owned;
    });
    const loader = new DataLoader(context);
    this.loadData(loader, d);
  }

  private async loadData(loader: DataLoader, d: Date): Promise<void> {
    try {
      const table = await loader.loadJson<HourStarTable>('hour_star_table.json');
      const palace = await loader.loadJson<PalaceAffinityData>('palace_affinity.json');
      const seasonal = await loader.loadJson<Record<string, Record<string, string[]>>>('seasonal_strength.json');
      const animals = await loader.loadJson<Animal[]>('animals.json');
      const cal = await loader.loadCalendarDay(d.getFullYear(), d.getMonth() + 1, d.getDate());
      ShizhanEngine.init(table, palace, seasonal, animals);
      this.dayRes = DayStarUtils.calc(d.getFullYear(), d.getMonth() + 1, d.getDate());
      this.lunarText = `农历${cal.lunar_month}月${cal.lunar_day}日 · ${cal.day_gan}${cal.day_zhi}日`;
      // 季节按农历月（与引擎/检测 B6 同口径：3/6/9/12 月为四季末）
      const lm = cal.lunar_month;
      this.season = lm === 3 || lm === 6 || lm === 9 || lm === 12 ? 'earth'
        : lm <= 2 ? 'spring' : lm <= 5 ? 'summer' : lm <= 8 ? 'autumn' : 'winter';
      this.loaded = true;
    } catch (err) {
      const e = err as Error;
      console.error('[ShizhanPage] load failed:', e.message);
      this.errorMessage = '数据加载失败：' + e.message;
    }
  }

  private static nowShichen(hour: number): number {
    // 23-0 点属子时
    const idx = hour >= 23 ? 0 : Math.floor((hour + 1) / 2);
    return Math.min(Math.max(idx, 0), 11);
  }

  private static usedToday(): number {
    const d = new Date();
    const key = `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
    if (AppStorage.get<string>('shizhanFreeDate') !== key) {
      return 0;
    }
    return AppStorage.get<number>('shizhanFreeCount') ?? 0;
  }

  private onDivine(): void {
    if (!this.loaded || this.dayRes === null) {
      return;
    }
    if (!this.premium && this.freeLeft <= 0) {
      this.limitHit = true;
      return;
    }
    const sc = SHICHEN[this.shichenIndex];
    const dayRes = this.dayRes;
    const star = ShizhanEngine.calcHourStar(dayRes.yuan, dayRes.element, sc.zhi);
    const v = ShizhanEngine.judge({
      hourStar: star,
      hourZhi: sc.zhi,
      isDay: sc.rep >= 5 && sc.rep < 18,
      season: this.season
    });
    if (v === null) {
      this.errorMessage = '起盘异常，请重试';
      return;
    }
    this.resultStar = star;
    this.resultZhi = sc.zhi;
    this.result = v;
    this.summary = ShizhanSummary.build(star, sc.zhi, v, this.season);
    this.limitHit = false;
    if (!this.premium) {
      const d = new Date();
      AppStorage.setOrCreate<string>('shizhanFreeDate', `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`);
      AppStorage.setOrCreate<number>('shizhanFreeCount', ShizhanPage.usedToday() + 1);
      this.freeLeft = FREE_LIMIT - ShizhanPage.usedToday();
    }
  }

  build() {
    Column() {
      // 顶部导航
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_primary')])
          .onClick(() => {
            router.back();
          })
        Text('演禽时占')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_primary'))
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: px2vp(this.statusBarPx) + 12, bottom: 12 })
      .backgroundColor($r('app.color.card_bg'))

      if (this.errorMessage !== '') {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor($r('app.color.cinnabar'))
          .margin({ top: 120 })
      } else if (!this.loaded) {
        Column({ space: 12 }) {
          LoadingProgress()
            .width(44)
            .height(44)
            .color($r('app.color.cinnabar'))
          Text('起盘备纸…')
            .fontSize(13)
            .fontColor($r('app.color.ink_secondary'))
        }
        .width('100%')
        .margin({ top: 120 })
      } else {
        this.MainContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.paper_bg'))
  }

  @Builder
  MainContent() {
    Scroll() {
      Column({ space: 14 }) {
        // 说明与今日起盘依据
        Column({ space: 8 }) {
          Text('以问事之时起盘：时禽泊何宫、飞伏旺衰如何，即断此事之时机。')
            .fontSize(13)
            .fontColor($r('app.color.ink_primary'))
            .lineHeight(22)
          Text(this.dayRes !== null
            ? `今日值日 ${this.dayRes.fullName} · ${this.dayRes.yuanName}（起例据《禽星易见》七元时禽法） · ${this.lunarText}`
            : '')
            .fontSize(11)
            .fontColor($r('app.color.ink_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(14)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(14)

        // 十二时辰选择
        Column({ space: 10 }) {
          Text('占事时辰')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.ink_primary'))
            .width('100%')
          Grid() {
            ForEach(SHICHEN, (sc: ShichenItem, idx: number) => {
              GridItem() {
                Column({ space: 2 }) {
                  Text(sc.zhi)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.shichenIndex === idx ? Color.White : $r('app.color.ink_primary'))
                  Text(sc.label)
                    .fontSize(10)
                    .fontColor(this.shichenIndex === idx ? Color.White : $r('app.color.ink_secondary'))
                }
                .justifyContent(FlexAlign.Center)
                .width('100%')
                .height(64)
                .backgroundColor(this.shichenIndex === idx ? $r('app.color.cinnabar') : $r('app.color.chip_bg'))
                .borderRadius(12)
                .onClick(() => {
                  this.shichenIndex = idx;
                  this.result = null;   // 换时辰后旧盘不再展示
                  this.limitHit = false;
                })
              }
            }, (sc: ShichenItem) => sc.zhi)
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .rowsTemplate('1fr 1fr 1fr')
          .columnsGap(8)
          .rowsGap(8)
          .height(220)
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(16)

        // 起盘按钮
        Button(this.premium ? ' ⟡ 起盘断此时' : (this.freeLeft > 0 ? ' ⟡ 起盘断此时' : '今日免费盘数已用完'))
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .type(ButtonType.Capsule)
          .backgroundColor((this.premium || this.freeLeft > 0) ? $r('app.color.cinnabar') : $r('app.color.ink_secondary'))
          .fontColor(Color.White)
          .onClick(() => {
            this.onDivine();
          })
        Text(this.premium ? '已解锁完整时占 · 不限次起盘' : `今日剩余免费盘数 ${this.freeLeft}/${FREE_LIMIT} · 完整时占功能即将开放`)
          .fontSize(10)
          .fontColor($r('app.color.ink_secondary'))
          .width('100%')

        // 结果 / 锁定提示
        if (this.limitHit) {
          Column({ space: 10 }) {
            Text('⏳ 今日免费盘数已用完')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.ink_primary'))
            Text('明日再来，或解锁完整时占（不限次起盘）。')
              .fontSize(13)
              .fontColor($r('app.color.ink_secondary'))
            Button('解锁完整时占')
              .width('100%')
              .height(46)
              .fontSize(16)
              .backgroundColor($r('app.color.cinnabar'))
              .fontColor(Color.White)
              .onClick(() => {
                router.pushUrl({ url: 'pages/PaywallPage' }).catch((err: Error) => {
                  console.error('Failed to push url:', err.message);
                });
              })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(16)
        } else if (this.result !== null && this.resultStar !== null) {
          this.ResultCard(this.resultStar, this.resultZhi, this.result)
        }

        Text('本应用基于古籍《禽星易见》七元时禽法整理，仅供传统文化研究参考。')
          .fontSize(11)
          .fontColor($r('app.color.ink_secondary'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 4, bottom: px2vp(this.navBarPx) + 16 })
      }
      .padding(16)
      .width('100%')
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
  }

  /** 时占结果卡（与格局卡同版式：断语在上、原文小字在下） */
  @Builder
  ResultCard(star: Animal, zhi: string, v: ShizhanVerdict) {
    Column({ space: 12 }) {
      Text('时占')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.ink_primary'))
        .width('100%')

      Row({ space: 14 }) {
        Image(Theme.starImage(star.star))
          .width(72)
          .height(72)
          .objectFit(ImageFit.Contain)
        Column({ space: 6 }) {
          Row({ space: 6 }) {
            Text(v.favorable === '吉' ? '宫吉' : (v.favorable === '凶' ? '宫逆' : '宫平'))
              .fontSize(11)
              .fontColor(Color.White)
              .backgroundColor(v.favorable === '吉' ? $r('app.color.cinnabar')
                : (v.favorable === '凶' ? $r('app.color.ink_secondary') : $r('app.color.divider')))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(4)
            this.MiniBadge(v.flying ? '飞' : '伏')
            this.MiniBadge(v.strength !== '' ? v.strength : '—')
          }
          Text(`${star.full_name} 泊 ${zhi} 宫`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ink_primary'))
          Text(v.palaceName)
            .fontSize(11)
            .fontColor($r('app.color.ink_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Divider().color($r('app.color.divider'))

      Text(this.summary)
        .fontSize(14)
        .fontColor($r('app.color.ink_primary'))
        .lineHeight(24)
        .width('100%')

      Text(`原文：${v.palaceText}`)
        .fontSize(11)
        .fontColor($r('app.color.ink_secondary'))
        .lineHeight(17)
        .width('100%')

      if (v.palaceNote !== '') {
        Text(`注：${v.palaceNote}`)
          .fontSize(10)
          .fontColor($r('app.color.ink_secondary'))
          .lineHeight(16)
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
  }

  @Builder
  MiniBadge(text: string) {
    Text(text)
      .fontSize(11)
      .fontColor($r('app.color.ink_primary'))
      .backgroundColor($r('app.color.chip_bg'))
      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      .borderRadius(4)
  }
}
