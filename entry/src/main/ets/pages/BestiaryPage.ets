import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { DataLoader } from '../utils/DataLoader';
import { Theme } from '../utils/Theme';
import { BestiaryData, StarGroup, StarEntry, GuanMing } from '../model/BestiaryModels';

/**
 * 二十八宿图鉴
 * 四象分组浏览 + 单宿详情（天上星名、形性、合食畏、泊宫课名）。
 * 数据：rawfile/bestiary.json（整理自《禽星易见》逐宿详解）；
 * 神兽图：resources/base/media/*.svg（规则/二十八星宿图）。
 */
@Entry
@Component
struct BestiaryPage {
  @State data: BestiaryData | null = null;
  @State loadError: string = '';
  @State selected: StarEntry | null = null;
  @StorageProp('statusBarPx') statusBarPx: number = 0;
  @StorageProp('navBarPx') navBarPx: number = 0;
  private dataLoader: DataLoader | null = null;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.dataLoader = new DataLoader(context);
    this.dataLoader.loadJson<BestiaryData>('bestiary.json').then((d: BestiaryData) => {
      this.data = d;
    }).catch((err: Error) => {
      console.error('[BestiaryPage] load failed:', err.message);
      this.loadError = '图鉴加载失败：' + err.message;
    });
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航
        Row({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor([$r('app.color.ink_primary')])
            .onClick(() => {
              router.back();
            })
          Text('二十八宿图鉴')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ink_primary'))
        }
        .width('100%')
        .padding({ left: 12, right: 16, top: px2vp(this.statusBarPx) + 12, bottom: 12 })
        .backgroundColor($r('app.color.card_bg'))

        if (this.loadError !== '') {
          Text(this.loadError)
            .fontSize(14)
            .fontColor($r('app.color.cinnabar'))
            .margin({ top: 120 })
        } else if (this.data === null) {
          Column({ space: 12 }) {
            LoadingProgress()
              .width(44)
              .height(44)
              .color($r('app.color.cinnabar'))
            Text('展卷中…')
              .fontSize(13)
              .fontColor($r('app.color.ink_secondary'))
          }
          .width('100%')
          .margin({ top: 120 })
        } else {
          Scroll() {
            Column({ space: 16 }) {
              Text('天上二十八宿，配作二十八种神兽。各有司掌、性情、所合所畏、泊宫课名。')
                .fontSize(12)
                .fontColor($r('app.color.ink_secondary'))
                .lineHeight(20)
                .width('100%')

              ForEach(this.data.groups, (group: StarGroup) => {
                this.GroupSection(group)
              }, (group: StarGroup) => group.name)

              Text('形性泊宫，据《禽星易见》逐宿详解整理；明禽暗禽据《演禽通纂》。')
                .fontSize(10)
                .fontColor($r('app.color.ink_secondary'))
                .width('100%')
                .margin({ top: 4, bottom: px2vp(this.navBarPx) + 12 })
            }
            .padding(16)
            .width('100%')
          }
          .scrollBar(BarState.Off)
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.paper_bg'))

      // 宿详情浮层
      if (this.selected !== null) {
        this.DetailLayer(this.selected)
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 四象分组 */
  @Builder
  GroupSection(group: StarGroup) {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Text(group.name)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.cinnabar'))
        Text(group.verse)
          .fontSize(12)
          .fontColor($r('app.color.ink_secondary'))
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(group.stars, (star: StarEntry) => {
          this.StarCell(star)
        }, (star: StarEntry) => star.star)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  /** 宿小卡（四列） */
  @Builder
  StarCell(star: StarEntry) {
    Column({ space: 4 }) {
      Image(Theme.starImage(star.star))
        .width(72)
        .height(72)
        .objectFit(ImageFit.Contain)
      Text(star.fullName)
        .fontSize(11)
        .fontColor($r('app.color.ink_primary'))
        .maxLines(1)
    }
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 10, bottom: 10 })
    .margin({ right: 8, bottom: 8 })
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .width('25%')
    .onClick(() => {
      this.selected = star;
    })
  }

  /** 宿详情浮层 */
  @Builder
  DetailLayer(star: StarEntry) {
    Column() {
      Scroll() {
        Column({ space: 14 }) {
          Row() {
            Blank()
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(22)
              .fontColor([$r('app.color.ink_secondary')])
              .onClick(() => {
                this.selected = null;
              })
          }
          .width('100%')

          Image(Theme.starImage(star.star))
            .width(180)
            .height(180)
            .objectFit(ImageFit.Contain)

          Text(star.fullName)
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ink_primary'))

          Row({ space: 6 }) {
            this.Tag(star.element + '宿', Theme.elemColor(star.element))
            this.Tag(star.active, $r('app.color.ink_secondary'))
            if (star.note !== '') {
              this.Tag(star.note, $r('app.color.cinnabar'))
            }
          }

          Text(star.desc)
            .fontSize(14)
            .fontColor($r('app.color.ink_primary'))
            .lineHeight(26)
            .width('100%')

          Divider().color($r('app.color.divider'))

          this.InfoRow('天上星名', `${star.heavenName} · ${star.starCount}`)
          this.InfoRow('元宫', `${star.palace}宫`)
          this.InfoRow('将星', star.jiang)
          this.InfoRow('合', star.he)
          this.InfoRow('食（吞啖）', star.shi)
          this.InfoRow('畏', star.wei)

          if (star.guanming.length > 0) {
            Text('泊宫课名')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.ink_primary'))
              .width('100%')
            Column({ space: 6 }) {
              ForEach(star.guanming, (gm: GuanMing) => {
                Text(`泊${gm.palace} · 「${gm.name}」`)
                  .fontSize(13)
                  .fontColor($r('app.color.ink_primary'))
                  .backgroundColor($r('app.color.chip_bg'))
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .borderRadius(8)
              }, (gm: GuanMing) => gm.palace + gm.name)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
        }
        .padding({ left: 20, right: 20, top: px2vp(this.statusBarPx) + 20, bottom: px2vp(this.navBarPx) + 20 })
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.paper_bg'))
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  InfoRow(label: string, value: string) {
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
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  Tag(text: string, color: ResourceColor) {
    Text(text)
      .fontSize(11)
      .fontColor(color)
      .backgroundColor($r('app.color.chip_bg'))
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .borderRadius(6)
  }
}
