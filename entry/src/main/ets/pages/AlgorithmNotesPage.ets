import { router } from '@kit.ArkUI';

/** 口径条目（算法决策的流派分歧与取舍） */
interface NoteItem {
  title: string;
  choice: string;
  detail: string;
}

const NOTES: NoteItem[] = [
  {
    title: '命宫推法',
    choice: '取巳宫（与主胎宫例自洽）',
    detail: '《演禽通纂》"起主胎星例"推得命宫在巳，而"起命宫例"一段却有卯/申两说（疑传抄脱文）。本应用取与主胎宫例自洽的巳版：主星泊巳即泊胎宫，体系闭环。'
  },
  {
    title: '心月狐入庙',
    choice: '卯宫（《禽星易见》）',
    detail: '《禽星易见》心宿"元：卯宫"；《禽星辑要》入庙表定"子"（狐眠水窟）。狐属太阴水星，子为水地亦有理。两说并列，本应用泊宫与图鉴从《易见》。'
  },
  {
    title: '值日禽星锚点',
    choice: '1984-02-02 一元甲子起虚',
    detail: '七元甲子（420 日循环）为禽星体系自循环纪日，与历书干支甲子不逐日对齐。不同通书或存数日相位差，每日值日星于流派交界日可能不同。'
  },
  {
    title: '四季末土旺',
    choice: '农历三/六/九/十二月整月近似',
    detail: '《禽星辑要》以"每季末 18 天"按节气精确划分；本应用以农历月为输入粒度，取整月近似并如实标注。'
  },
  {
    title: '闰月除补',
    choice: '按平月处理（未实现特例）',
    detail: '《演禽通纂》："其年有闰月，男女皆不除牛、女。"本应用万年历数据暂无闰月标记，闰月出生者按平月排盘，后续数据补齐后实现。'
  },
  {
    title: '昼夜禽分类',
    choice: '日禽十六、夜禽十二（《禽星易见》）',
    detail: '房日兔虽名"日兔"归夜禽（兔性夜出），危月燕归日禽（燕昼飞）——以习性不以名号；毕月乌昼夜皆宜（主监察）。'
  },
  {
    title: '大运方向与起运岁数',
    choice: '主星落宫天干定顺逆；水1火2木3金4土5日6月7 岁起运',
    detail: '《演禽通纂·起大运例》原文：主星落宫天干甲丙戊庚壬，男顺女逆；乙丁己辛癸，男逆女顺。注意以命宫天干论，不以年干。'
  },
  {
    title: '格局判定口径',
    choice: '四星泊宫绑定判定；柱字要件与存疑格局不自动判定',
    detail: '《演禽通纂》福禄上格原书题三十八，整理本、ctext 电子本、维基文库四库本三方互证均实得37条（底本流传之缺，不补凑）、贫贱下格20条。四星泊宫皆参与判定：主星泊命宫、胎星泊胎宫、命星泊命宫、身星泊身宫（《通纂》断例："胎禽泊此宫分，其人贫必彻骨"、"项羽主星井木犴，泊乙未宫"——主胎泊宫均独立论吉凶）。含柱中干支字要件（如"得乙巳""壬辰是也"）或原文所指存疑（如"江湖""己未"）的19条仅展示原文不自动判定。逐条考据见 规则/格局判定-数据整理.md。'
  }
];

const SOURCES: string = '依据：《演禽通纂》三校本、《禽星易见》四库本、《禽星辑要》整理稿。'
  + '分歧如实并列，主口径以《演禽通纂》为本。';

@Entry
@Component
struct AlgorithmNotesPage {
  @StorageProp('statusBarPx') statusBarPx: number = 0;
  @StorageProp('navBarPx') navBarPx: number = 0;

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
        Text('算法口径说明')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_primary'))
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: px2vp(this.statusBarPx) + 12, bottom: 12 })
      .backgroundColor($r('app.color.card_bg'))

      Scroll() {
        Column({ space: 14 }) {
          Text('本应用的每一项算法决策均有古籍依据；存在流派分歧之处，如实并列并注明取舍。'
            + '以下八项为主要的口径决策。')
            .fontSize(12)
            .fontColor($r('app.color.ink_secondary'))
            .lineHeight(20)
            .width('100%')

          ForEach(NOTES, (item: NoteItem) => {
            Column({ space: 8 }) {
              Text(item.title)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.ink_primary'))
              Text('取舍：' + item.choice)
                .fontSize(13)
                .fontColor($r('app.color.cinnabar'))
                .width('100%')
              Text(item.detail)
                .fontSize(13)
                .fontColor($r('app.color.ink_primary'))
                .lineHeight(22)
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(16)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(14)
            .width('100%')
          }, (item: NoteItem) => item.title)

          Text(SOURCES)
            .fontSize(11)
            .fontColor($r('app.color.ink_secondary'))
            .lineHeight(18)
            .width('100%')
            .padding({ bottom: px2vp(this.navBarPx) + 16 })
        }
        .padding(16)
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.paper_bg'))
  }
}
