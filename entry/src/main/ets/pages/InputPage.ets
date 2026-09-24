import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { DataLoader } from '../utils/DataLoader';
import { LunarFormatter } from '../utils/LunarFormatter';
import { DayStarUtils, DayStarResult } from '../utils/DayStarUtils';
import { DailyTheater } from '../utils/DailyTheater';
import { Theme } from '../utils/Theme';
import { BestiaryData, StarEntry } from '../model/BestiaryModels';
import { TransformationData } from '../model/Types';
import { CalendarDay } from '../model/Types';

interface ShichenOption {
  name: string;   // 时辰名（子丑寅…）
  range: string;  // 对应钟点区间
  hour: number;   // 传给引擎的代表小时（取时辰中较早整点，与引擎昼夜判定一致）
  isDay: boolean; // 代表小时是否昼间（5-18 点为昼）
}

@Entry
@Component
struct InputPage {
  @State solarDate: Date = new Date();
  @State shichenIndex: number = 6; // 默认午时
  @State gender: number = 0;       // 0: 男, 1: 女
  @State previewDay: CalendarDay | null = null;
  @State previewLoading: boolean = false;
  @State previewFailed: boolean = false;
  // 值日禽星（随选定日期变化）
  @State daily: DayStarResult | null = null;
  @State dailyHuaDaoText: string = '';
  @State theaterText: string = '';
  @StorageProp('statusBarPx') statusBarPx: number = 0;
  @StorageProp('navBarPx') navBarPx: number = 0;
  private bestiaryMap: Record<string, StarEntry> = {};
  private tfData: TransformationData | null = null;
  private previewSeq: number = 0;
  private dataLoader: DataLoader | null = null;

  // 十二时辰表；代表小时取各时辰起始整点（子时取 0 点早子时）
  private readonly shichenList: ShichenOption[] = [
    { name: '子', range: '23-01', hour: 0, isDay: false },
    { name: '丑', range: '01-03', hour: 1, isDay: false },
    { name: '寅', range: '03-05', hour: 3, isDay: false },
    { name: '卯', range: '05-07', hour: 5, isDay: true },
    { name: '辰', range: '07-09', hour: 7, isDay: true },
    { name: '巳', range: '09-11', hour: 9, isDay: true },
    { name: '午', range: '11-13', hour: 11, isDay: true },
    { name: '未', range: '13-15', hour: 13, isDay: true },
    { name: '申', range: '15-17', hour: 15, isDay: true },
    { name: '酉', range: '17-19', hour: 17, isDay: true },
    { name: '戌', range: '19-21', hour: 19, isDay: false },
    { name: '亥', range: '21-23', hour: 21, isDay: false }
  ];

  aboutToAppear(): void {
    this.ensureLoader();
    this.refreshPreview();
    this.loadDailySupport();
  }

  private ensureLoader(): void {
    if (this.dataLoader === null) {
      const context = getContext(this) as common.UIAbilityContext;
      this.dataLoader = new DataLoader(context);
    }
  }

  /** 异步加载值日星支撑数据（图鉴映射 + 日柱化道表），完成后刷新卡片 */
  private loadDailySupport(): void {
    const loader = this.dataLoader;
    if (loader === null) {
      return;
    }
    // 预热全部规则数据（结果页复用缓存，排盘页秒开）
    loader.loadAllData().catch((err: Error) => {
      console.error('[InputPage] preload allData failed:', err.message);
    });
    loader.loadJson<BestiaryData>('bestiary.json').then((d: BestiaryData) => {
      for (const g of d.groups) {
        for (const s of g.stars) {
          this.bestiaryMap[s.star] = s;
        }
      }
      this.updateDaily();
    }).catch((err: Error) => {
      console.error('[InputPage] bestiary load failed:', err.message);
    });
    loader.loadJson<TransformationData>('transformations.json').then((t: TransformationData) => {
      this.tfData = t;
      this.updateDaily();
    }).catch((err: Error) => {
      console.error('[InputPage] transformations load failed:', err.message);
    });
  }

  /** 依据当前选定日期刷新值日禽星卡 */
  private updateDaily(): void {
    const day = this.previewDay;
    if (day === null) {
      return;
    }
    this.daily = DayStarUtils.calc(day.year, day.month, day.day);
    let hua: string = '';
    const tf = this.tfData;
    if (tf !== null) {
      const envs = tf.jiazi_map[day.day_gan + day.day_zhi];
      if (envs !== undefined && envs.length > 0) {
        hua = envs.join('、');
      }
    }
    this.dailyHuaDaoText = hua;
    // 每日占断：泊宫课名 + 化道意象
    const entry = this.bestiaryMap[this.daily.star];
    this.theaterText = DailyTheater.build(
      this.daily.fullName, day.day_zhi,
      entry?.guanming,
      hua !== '' ? hua.split('、') : []
    );
  }

  /** 选定日期后即时回显农历与干支（万年历本地查询） */
  private refreshPreview(): void {
    this.ensureLoader();
    const seq = ++this.previewSeq;
    const year = this.solarDate.getFullYear();
    const month = this.solarDate.getMonth() + 1;
    const day = this.solarDate.getDate();
    this.previewLoading = true;
    this.previewFailed = false;
    const loader = this.dataLoader;
    if (loader === null) {
      return;
    }
    loader.loadCalendarDay(year, month, day).then((day2: CalendarDay) => {
      if (seq !== this.previewSeq) {
        return;
      }
      this.previewDay = day2;
      this.previewLoading = false;
      this.updateDaily();
    }).catch((err: Error) => {
      console.error('Preview calendar load failed:', err.message);
      if (seq !== this.previewSeq) {
        return;
      }
      this.previewDay = null;
      this.previewLoading = false;
      this.previewFailed = true;
    });
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          // 头部
          Column({ space: 6 }) {
            Image($r('app.media.yanqin_tong_logo_classical'))
              .height(76)
              .width(76)
              .objectFit(ImageFit.Contain)
            Text('演禽通纂')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.ink_primary'))
            Text('古籍排盘 · 传统文化研究')
              .fontSize(12)
              .fontColor($r('app.color.ink_secondary'))
          }
          .width('100%')
          .margin({ top: px2vp(this.statusBarPx) + 16 })

          // 值日禽星卡（随选定日期变化）
          if (this.daily !== null) {
            this.DailyStarCard()
          }

          // 卡片一：出生日期
          Column({ space: 8 }) {
            Row() {
              Text('出生日期')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.ink_primary'))
              Blank()
              Text('公历')
                .fontSize(12)
                .fontColor($r('app.color.ink_secondary'))
            }
            .width('100%')

            DatePicker({
              start: new Date('1900-1-1'),
              end: new Date('2061-12-31'),
              selected: this.solarDate
            })
              .height(110)
              .width('100%')
              .onChange((value: DatePickerResult) => {
                if (value.year !== undefined && value.month !== undefined && value.day !== undefined) {
                  this.solarDate = new Date(value.year, value.month, value.day);
                  this.refreshPreview();
                }
              })

            Divider().color($r('app.color.divider'))

            if (this.previewLoading) {
              Text('历法推算中…')
                .fontSize(12)
                .fontColor($r('app.color.ink_secondary'))
            } else if (this.previewFailed) {
              Text('该日期暂无历法数据')
                .fontSize(12)
                .fontColor($r('app.color.ink_secondary'))
            } else if (this.previewDay !== null) {
              Text(this.previewLunarText())
                .fontSize(13)
                .fontColor($r('app.color.ink_primary'))
              Text(this.previewGanZhiText())
                .fontSize(12)
                .fontColor($r('app.color.cinnabar'))
            }
          }
          .cardStyle()

          // 卡片二：出生时辰（十二时辰制）
          Column({ space: 10 }) {
            Row() {
              Text('出生时辰')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.ink_primary'))
              Blank()
              Text('十二时辰制')
                .fontSize(12)
                .fontColor($r('app.color.ink_secondary'))
            }
            .width('100%')

            Grid() {
              ForEach(this.shichenList, (opt: ShichenOption, index: number) => {
                GridItem() {
                  this.ShichenChip(opt, index)
                }
              }, (opt: ShichenOption) => opt.name)
            }
            .columnsTemplate('1fr 1fr 1fr 1fr')
            .rowsGap(8)
            .columnsGap(8)
            .height(210)
            .width('100%')

            Text(this.shichenDetail())
              .fontSize(12)
              .fontColor($r('app.color.ink_secondary'))
          }
          .cardStyle()

          // 卡片三：性别
          Column({ space: 10 }) {
            Text('性别')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.ink_primary'))
              .width('100%')

            Row({ space: 12 }) {
              this.GenderCard('男', 0)
              this.GenderCard('女', 1)
            }
            .width('100%')

            Text('演禽数星时男避牛金牛、女避女土蝠，性别影响排盘结果')
              .fontSize(11)
              .fontColor($r('app.color.ink_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
          .cardStyle()

          // 排盘按钮
          Button('开始排盘')
            .width('100%')
            .height(48)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.cinnabar'))
            .fontColor(Color.White)
            .margin({ top: 8 })
            .onClick(() => {
              const opt = this.shichenList[this.shichenIndex];
              router.pushUrl({
                url: 'pages/ResultPage',
                params: {
                  timestamp: this.solarDate.getTime(),
                  hour: opt.hour,
                  gender: this.gender
                }
              }).catch((err: Error) => {
                console.error('Failed to push url:', err.message);
              });
            })

          // 鉴形剧本入口
          Button('星官研习 · 鉴形断案')
            .width('100%')
            .height(44)
            .fontSize(14)
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.chip_bg'))
            .fontColor($r('app.color.cinnabar'))
            .onClick(() => {
              router.pushUrl({
                url: 'pages/ScriptPage'
              }).catch((err: Error) => {
                console.error('Failed to push url:', err.message);
              });
            })

          // 演禽时占入口
          Button('演禽时占 · 问事择时')
            .width('100%')
            .height(44)
            .fontSize(14)
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.chip_bg'))
            .fontColor($r('app.color.cinnabar'))
            .onClick(() => {
              router.pushUrl({
                url: 'pages/ShizhanPage'
              }).catch((err: Error) => {
                console.error('Failed to push url:', err.message);
              });
            })

          // 二十八宿图鉴入口
          Button('二十八宿图鉴')
            .width('100%')
            .height(44)
            .fontSize(14)
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.chip_bg'))
            .fontColor($r('app.color.cinnabar'))
            .onClick(() => {
              router.pushUrl({
                url: 'pages/BestiaryPage'
              }).catch((err: Error) => {
                console.error('Failed to push url:', err.message);
              });
            })

          // 算法口径说明入口
          Button('算法口径说明')
            .width('100%')
            .height(44)
            .fontSize(14)
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.chip_bg'))
            .fontColor($r('app.color.cinnabar'))
            .onClick(() => {
              router.pushUrl({
                url: 'pages/AlgorithmNotesPage'
              }).catch((err: Error) => {
                console.error('Failed to push url:', err.message);
              });
            })

          // 古籍阅读入口
          Button('古籍阅读 · 演禽通纂 / 禽星易见')
            .width('100%')
            .height(44)
            .fontSize(14)
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.chip_bg'))
            .fontColor($r('app.color.cinnabar'))
            .onClick(() => {
              router.pushUrl({
                url: 'pages/ClassicReaderPage'
              }).catch((err: Error) => {
                console.error('Failed to push url:', err.message);
              });
            })

          // 合规免责声明（协议查看：AGC 应用资料页 + 平台隐私托管弹窗）
          Text('本应用基于古籍《演禽通纂》三校本整理，仅供传统文化研究参考。')
            .fontSize(11)
            .fontColor($r('app.color.ink_secondary'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ bottom: px2vp(this.navBarPx) + 24 })
            .margin({ top: 4 })
        }
        .padding({ left: 20, right: 20 })
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.paper_bg'))
  }

  /** 值日禽星卡：选定日期的七元值日星 + 日柱化道 */
  @Builder
  DailyStarCard() {
    Row({ space: 14 }) {
      if (this.daily !== null) {
        Image(Theme.starImage(this.daily.star))
          .width(64)
          .height(64)
          .objectFit(ImageFit.Contain)

        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(this.dailyTitle())
              .fontSize(13)
              .fontColor($r('app.color.cinnabar'))
            Blank()
            Text(`${this.daily.yuanName}${this.daily.jiangIndex}将`)
              .fontSize(10)
              .fontColor($r('app.color.ink_secondary'))
          }
          .width('100%')

          Text(this.daily.fullName)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.elemColor(this.daily.element))

          Text(this.dailyFootText())
            .fontSize(11)
            .fontColor($r('app.color.ink_secondary'))
            .maxLines(2)
            .lineHeight(17)

          if (this.theaterText !== '') {
            Text(this.theaterText)
              .fontSize(12)
              .fontColor($r('app.color.ink_primary'))
              .lineHeight(20)
              .width('100%')
              .margin({ top: 6 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding(14)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
  }

  /** 卡标题：选定日期是否今日 */
  private dailyTitle(): string {
    const day = this.previewDay;
    if (day === null) {
      return '值日禽星';
    }
    const now = new Date();
    const isToday = day.year === now.getFullYear() && day.month === now.getMonth() + 1 && day.day === now.getDate();
    if (isToday) {
      return '今日值日禽星';
    }
    return `值日禽星 · ${day.month}月${day.day}日`;
  }

  /** 卡脚注：日柱干支与化道意象 */
  private dailyFootText(): string {
    const day = this.previewDay;
    if (day === null) {
      return '';
    }
    const gz = `日柱 ${day.day_gan}${day.day_zhi}`;
    if (this.dailyHuaDaoText !== '') {
      return `${gz} · 化道：${this.dailyHuaDaoText}`;
    }
    return gz;
  }

  /** 选中时辰的说明行 */
  private shichenDetail(): string {
    const opt = this.shichenList[this.shichenIndex];
    const dayNight = opt.isDay ? '昼生' : '夜生';
    return `${opt.name}时 ${opt.range} 时 · ${dayNight}（昼夜影响明禽暗禽旺衰）`;
  }

  /** 农历回显文案（previewDay 非空时调用） */
  private previewLunarText(): string {
    const day = this.previewDay;
    if (day === null) {
      return '';
    }
    return `农历 ${day.lunar_year} ${day.zodiac}年 ${LunarFormatter.monthDay(day.lunar_month, day.lunar_day)}`;
  }

  /** 干支回显文案（previewDay 非空时调用） */
  private previewGanZhiText(): string {
    const day = this.previewDay;
    if (day === null) {
      return '';
    }
    return `${day.year_gan}${day.year_zhi}年 · 日柱 ${day.day_gan}${day.day_zhi}`;
  }

  @Builder
  ShichenChip(opt: ShichenOption, index: number) {
    Column({ space: 2 }) {
      Text(opt.name)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.shichenIndex === index ? Color.White : $r('app.color.ink_primary'))
      Text(opt.range)
        .fontSize(9)
        .fontColor(this.shichenIndex === index ? Color.White : $r('app.color.ink_secondary'))
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(64)
    .borderRadius(10)
    .backgroundColor(this.shichenIndex === index ? $r('app.color.cinnabar') : $r('app.color.chip_bg'))
    .onClick(() => {
      this.shichenIndex = index;
    })
  }

  @Builder
  GenderCard(label: string, value: number) {
    Text(label)
      .fontSize(18)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.gender === value ? Color.White : $r('app.color.ink_primary'))
      .textAlign(TextAlign.Center)
      .height(46)
      .layoutWeight(1)
      .borderRadius(12)
      .backgroundColor(this.gender === value ? $r('app.color.cinnabar') : $r('app.color.chip_bg'))
      .onClick(() => {
        this.gender = value;
      })
  }
}

// 卡片统一样式
@Styles
function cardStyle() {
  .padding(16)
  .backgroundColor($r('app.color.card_bg'))
  .borderRadius(16)
  .width('100%')
}
