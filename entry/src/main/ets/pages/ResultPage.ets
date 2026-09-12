import { router } from '@kit.ArkUI';
import { YanQinEngine } from '../utils/YanQinEngine';
import { DataLoader } from '../utils/DataLoader';
import { ChartSummary } from '../utils/ChartSummary';
import { Theme } from '../utils/Theme';
import { YanQinChart } from '../model/ChartModels';
import { Animal } from '../model/Types';
import { common } from '@kit.AbilityKit';

const SEASON_NAMES: Record<string, string> = {
  "spring": "春", "summer": "夏", "autumn": "秋", "winter": "冬", "earth": "四季末"
};

@Entry
@Component
struct ResultPage {
  @State chart: YanQinChart | null = null;
  @State errorMessage: string = '';
  @State proExpanded: boolean = false;
  @State isLoading: boolean = true;
  @StorageProp('statusBarPx') statusBarPx: number = 0;
  @StorageProp('navBarPx') navBarPx: number = 0;
  private engine: YanQinEngine = new YanQinEngine();
  private birthYear: number = new Date().getFullYear();

  aboutToAppear(): void {
    // 短暂延迟：让转场动画优先完成（数据经 InputPage 预热已缓存，加载近瞬时）
    setTimeout(() => {
      this.loadData();
    }, 120);
  }

  private loadData(): void {
    // 解析路由参数（防御式：参数缺失/异常时给出错误提示而非无限加载）
    let timestamp = -1;
    let hour = 12;
    let genderNum = 0;
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params !== null && params !== undefined) {
        timestamp = params['timestamp'] as number;
        hour = params['hour'] as number;
        genderNum = params['gender'] as number;
      }
    } catch (err) {
      console.error('[ResultPage] parse params failed:', err);
    }
    console.info(`[ResultPage] params: timestamp=${timestamp} hour=${hour} gender=${genderNum}`);
    if (timestamp === undefined || timestamp === null || Number.isNaN(timestamp) || timestamp <= 0) {
      this.errorMessage = '未获取到出生日期参数，请从输入页重新进入';
      this.isLoading = false;
      return;
    }
    const gender: 'male' | 'female' = genderNum === 1 ? 'female' : 'male';

    const date = new Date(timestamp);
    this.birthYear = date.getFullYear();

    const context = getContext(this) as common.UIAbilityContext;
    const dataLoader = new DataLoader(context);

    dataLoader.loadAllData().then(data => {
      this.engine.init(
        data.animals,
        data.interactions,
        data.transformations,
        data.seasonalStrength
      );

      return dataLoader.loadCalendarDay(
        date.getFullYear(),
        date.getMonth() + 1,
        date.getDate()
      ).then(calendarDay => {
        this.chart = this.engine.calculateChart({
          solarDate: date,
          timeHour: hour,
          gender: gender
        }, calendarDay);
        this.isLoading = false;
        console.info(`[ResultPage] chart set: master=${this.chart.masterStar.full_name} interactions=${this.chart.interactions.length}`);
      });
    }).catch((err: Error) => {
      console.error("Failed to load data:", err);
      this.errorMessage = "数据加载失败: " + err.message;
      this.isLoading = false;
    });
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
        Text('命盘详解')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_primary'))
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: px2vp(this.statusBarPx) + 12, bottom: 12 })
      .backgroundColor($r('app.color.card_bg'))

      if (this.isLoading) {
        Column({ space: 12 }) {
          LoadingProgress()
            .width(44)
            .height(44)
            .color($r('app.color.cinnabar'))
          Text('排盘推演中…')
            .fontSize(13)
            .fontColor($r('app.color.ink_secondary'))
        }
        .width('100%')
        .margin({ top: 120 })
      } else if (this.errorMessage !== '') {
        Column({ space: 16 }) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor($r('app.color.cinnabar'))
            .textAlign(TextAlign.Center)
          Button('重试')
            .backgroundColor($r('app.color.cinnabar'))
            .onClick(() => {
              this.isLoading = true;
              this.errorMessage = '';
              this.loadData();
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 120 })
      } else if (this.chart !== null) {
        this.MainContent(this.chart)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.paper_bg'))
  }

  /** 结果主体（chart 非空后才进入） */
  @Builder
  MainContent(chart: YanQinChart) {
    Scroll() {
      Column({ space: 14 }) {
        this.SummaryCard(chart)
        this.StarsCard(chart)
        this.FortuneCard(chart)
        this.FlowYearCard(chart)
        this.InteractionCard(chart)
        this.HuaDaoCard(chart)
        this.ProCard(chart)

        Text('本应用基于古籍《演禽通纂》三校本整理，仅供传统文化研究参考。')
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
    .width('100%')
    .height('100%')
  }

  /** 顶部总评卡：主星大字 + 昼夜/旺衰徽标 + 一句话总评 */
  @Builder
  SummaryCard(chart: YanQinChart) {
    Column({ space: 12 }) {
      Row({ space: 16 }) {
        // 神兽图（二十八星宿图鉴 SVG，圆形牌饰自带边框）
        Image(Theme.starImage(chart.masterStar.star))
          .width(88)
          .height(88)
          .objectFit(ImageFit.Contain)

        Column({ space: 6 }) {
          Text(`主星 · ${chart.masterStar.element}宿`)
            .fontSize(12)
            .fontColor($r('app.color.ink_secondary'))
          Text(chart.masterStar.full_name)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ink_primary'))
          Row({ space: 6 }) {
            if (chart.isDay !== undefined) {
              this.Badge(chart.isDay ? '昼生' : '夜生')
            }
            if (chart.season !== undefined) {
              this.Badge(`${chart.season === 'earth' ? '四季末' : (SEASON_NAMES[chart.season] ?? '') + '季'} · ${chart.seasonalStrength}`)
            }
            this.Badge(`泊 ${chart.lifePalace} 宫`)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Divider().color($r('app.color.divider'))

      Text(ChartSummary.build(chart))
        .fontSize(14)
        .fontColor($r('app.color.ink_primary'))
        .lineHeight(24)
        .width('100%')
    }
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 本命四星（主星已在上卡，此处列胎/命/身） */
  @Builder
  StarsCard(chart: YanQinChart) {
    Column({ space: 12 }) {
      Text('本命四星')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.ink_primary'))
        .width('100%')

      Row({ space: 10 }) {
        this.MiniStar('胎星', chart.embryoStar)
        this.MiniStar('命星', chart.lifeStar)
        this.MiniStar('身星', chart.bodyStar)
      }
      .width('100%')

      Text('胎星承主星而立；命星自胎星合宿安于命宫；身星自命星合宿安于身宫。')
        .fontSize(11)
        .fontColor($r('app.color.ink_secondary'))
        .width('100%')
    }
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 大运：自主星落宫起，十年一运 */
  @Builder
  FortuneCard(chart: YanQinChart) {
    Column({ space: 10 }) {
      Row() {
        Text('大运')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink_primary'))
        Blank()
        if (chart.fortuneStartAge !== undefined) {
          Text(`${chart.fortuneStartAge} 岁起运 · 十年一运`)
            .fontSize(11)
            .fontColor($r('app.color.ink_secondary'))
        }
      }
      .width('100%')

      if (chart.fortuneList !== undefined && chart.fortuneStartAge !== undefined) {
        Grid() {
          ForEach(chart.fortuneList, (gz: string, idx: number) => {
            GridItem() {
              Column({ space: 2 }) {
                Text(`${this.fortuneAge(chart, idx)}岁`)
                  .fontSize(10)
                  .fontColor($r('app.color.ink_secondary'))
                Text(gz)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.currentFortuneIndex(chart) === idx ? $r('app.color.cinnabar') : $r('app.color.ink_primary'))
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
              .height('100%')
              .backgroundColor(this.currentFortuneIndex(chart) === idx ? $r('app.color.cinnabar_soft') : $r('app.color.chip_bg'))
              .borderRadius(10)
            }
          }, (gz: string) => gz)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsTemplate('1fr 1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .height(180)
        .width('100%')

        Text('大运自主星落宫（命宫）起，阳男阴女顺行、阴男阳女逆行，每十年换一宫。')
          .fontSize(11)
          .fontColor($r('app.color.ink_secondary'))
          .width('100%')
      }
    }
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 第 idx 迨的起运岁数 */
  private fortuneAge(chart: YanQinChart, idx: number): number {
    const start = chart.fortuneStartAge;
    if (start === undefined) {
      return 0;
    }
    return start + idx * 10;
  }

  /** 当前虚岁所在大运的下标（越界回落首/末运） */
  private currentFortuneIndex(chart: YanQinChart): number {
    if (chart.fortuneStartAge === undefined || chart.fortuneList === undefined) {
      return -1;
    }
    const virtualAge = new Date().getFullYear() - this.birthYear + 1;
    const idx = Math.floor((virtualAge - chart.fortuneStartAge) / 10);
    if (idx < 0) {
      return 0;
    }
    if (idx >= chart.fortuneList.length) {
      return chart.fortuneList.length - 1;
    }
    return idx;
  }

  /** 流年星 */
  @Builder
  FlowYearCard(chart: YanQinChart) {
    Column({ space: 10 }) {
      Text('流年')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.ink_primary'))
        .width('100%')

      Row({ space: 14 }) {
        this.MiniStar('流年星', chart.currentYearStar ?? chart.embryoStar)
        Column({ space: 4 }) {
          Text(`虚岁 ${new Date().getFullYear() - this.birthYear + 1} 岁`)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.ink_primary'))
          Text('以胎星起一岁，顺数至本年')
            .fontSize(11)
            .fontColor($r('app.color.ink_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 吉凶吞啖 */
  @Builder
  InteractionCard(chart: YanQinChart) {
    Column({ space: 10 }) {
      Text('吉凶吞啖')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.ink_primary'))
        .width('100%')

      if (chart.interactions.length > 0) {
        List({ space: 8 }) {
          ForEach(chart.interactions, (item: string) => {
            ListItem() {
              Row({ space: 8 }) {
                Text('●')
                  .fontSize(14)
                  .fontColor(item.includes('吉') ? $r('app.color.elem_wood') : $r('app.color.cinnabar'))
                Text(item)
                  .fontSize(13)
                  .fontColor($r('app.color.ink_primary'))
              }
              .width('100%')
            }
          }, (item: string) => item)
        }
        .width('100%')
      } else {
        Text('当前诸星关系平和')
          .fontSize(13)
          .fontColor($r('app.color.ink_secondary'))
      }

      Text('我克他为吉，克我为凶；据吞啖诀并参季节昼夜修正。')
        .fontSize(11)
        .fontColor($r('app.color.ink_secondary'))
        .width('100%')
    }
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 环境化道 */
  @Builder
  HuaDaoCard(chart: YanQinChart) {
    Column({ space: 10 }) {
      Text('环境化道')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.ink_primary'))
        .width('100%')

      if (chart.huaDao.length > 0) {
        Column({ space: 6 }) {
          ForEach(chart.huaDao, (item: string) => {
            Text(item)
              .fontSize(12)
              .fontColor($r('app.color.ink_primary'))
              .backgroundColor($r('app.color.chip_bg'))
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .borderRadius(8)
          }, (item: string) => item)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      } else {
        Text('暂无特殊化道环境')
          .fontSize(13)
          .fontColor($r('app.color.ink_secondary'))
      }

      Text('化道为四柱干支所处环境意象，据《演禽通纂》六十甲子总取化道。')
        .fontSize(11)
        .fontColor($r('app.color.ink_secondary'))
        .width('100%')
    }
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 专业信息（默认折叠：旬头、宫位等过程数据） */
  @Builder
  ProCard(chart: YanQinChart) {
    Column({ space: 10 }) {
      Row() {
        Text('专业信息')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink_primary'))
        Blank()
        Text(this.proExpanded ? '收起' : '展开')
          .fontSize(12)
          .fontColor($r('app.color.cinnabar'))
      }
      .width('100%')
      .onClick(() => {
        this.proExpanded = !this.proExpanded;
      })

      if (this.proExpanded) {
        Divider().color($r('app.color.divider'))
        this.ProRow('命宫', `${chart.lifePalace}（主星泊此宫）`)
        this.ProRow('胎宫', chart.embryoPalace ?? '—')
        this.ProRow('身宫', chart.bodyPalace)
        this.ProRow('寿宫', chart.shouPalace ?? '—')
        this.ProRow('寿星', chart.shouStar !== undefined ? `${chart.shouStar.full_name}（泊寿宫）` : '—')
        this.ProRow('旬头', `${chart.xunHead} · ${chart.xunStar.full_name}`)
        this.ProRow('旬头星起法', '按三元旬头表取旬头星，数生日归子，顺数至命宫')
      }
    }
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ProRow(label: string, value: string) {
    Row({ space: 12 }) {
      Text(label)
        .fontSize(13)
        .fontColor($r('app.color.ink_secondary'))
        .width(84)
      Text(value)
        .fontSize(13)
        .fontColor($r('app.color.ink_primary'))
        .layoutWeight(1)
    }
    .width('100%')
  }

  /** 小星卡（胎/命/身/流年） */
  @Builder
  MiniStar(label: string, star: Animal) {
    Column({ space: 3 }) {
      Text(label)
        .fontSize(11)
        .fontColor($r('app.color.ink_secondary'))
      Image(Theme.starImage(star.star))
        .width(56)
        .height(56)
        .objectFit(ImageFit.Contain)
      Text(star.full_name)
        .fontSize(10)
        .fontColor($r('app.color.ink_primary'))
        .maxLines(1)
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(112)
    .backgroundColor($r('app.color.chip_bg'))
    .borderRadius(12)
  }

  /** 信息徽标（昼生/夜生、季节旺衰） */
  @Builder
  Badge(text: string) {
    Text(text)
      .fontSize(11)
      .fontColor($r('app.color.cinnabar'))
      .backgroundColor($r('app.color.cinnabar_soft'))
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .borderRadius(6)
  }
}
