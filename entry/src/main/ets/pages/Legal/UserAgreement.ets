import { router } from '@kit.ArkUI';

@Entry
@Component
struct UserAgreementPage {
  @StorageProp('statusBarPx') statusBarPx: number = 0;
  @StorageProp('navBarPx') navBarPx: number = 0;

  @Builder
  H(text: string) {
    Text(text)
      .fontSize(15)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.ink_primary'))
      .margin({ top: 14, bottom: 4 })
      .width('100%')
  }

  @Builder
  P(text: string) {
    Text(text)
      .fontSize(13)
      .fontColor($r('app.color.ink_primary'))
      .lineHeight(22)
      .width('100%')
  }

  build() {
    Column() {
      // 顶部栏
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_primary')])
          .onClick(() => {
            router.back();
          })
        Text('用户协议')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_primary'))
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: px2vp(this.statusBarPx) + 12, bottom: 12 })
      .backgroundColor($r('app.color.card_bg'))

      Scroll() {
        Column() {
          Text('演禽通纂APP 用户协议')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ink_primary'))
            .margin({ bottom: 10 })
            .width('100%')

          this.H('总则')
          this.P('演禽通纂APP由独立开发者（以下简称"我们"）提供。本协议是你（以下简称"用户"）与我们之间就使用本软件与服务达成的约定。你开始使用或继续使用，视为已阅读并同意本协议。当前版本无需注册账号即可使用全部功能。')

          this.H('服务内容')
          this.P('本应用是基于古籍《演禽通纂》《禽星易见》等文献整理制作的传统术数排盘与阅读工具，核心功能包括：演禽命盘排演、二十八宿图鉴、古籍阅读、剧情化案例研习（鉴形剧本）。我们可能根据产品迭代对功能进行调整或优化，并以版本更新说明的方式予以告知。')

          this.H('内容性质与免责（重要）')
          this.P('本应用全部内容——包括排盘结果、禽星断语、泊宫课名、剧情演绎与图鉴解说——均源自明清古籍的整理、校对与白话转述，属于传统文化研究与民俗知识展示范畴。此类内容不具备科学实证效力，不构成医疗、心理健康、投资理财、婚恋家庭、法律事务或其他任何现实决策的建议或依据。')
          this.P('请理性看待本应用内容，切勿沉迷或迷信。因依赖本应用内容作出现实决策所产生的一切后果，由用户自行承担。如您或您的家人正经历身心困扰，请及时寻求专业医疗或心理援助，而非求助于任何术数内容。')

          this.H('用户行为规范')
          this.P('你承诺遵守法律法规与社会公德，不得：\n· 利用本应用从事封建迷信活动或传播违法、侵权内容；\n· 以本应用名义从事收费预测、看相算命等经营活动；\n· 以任何方式干扰、破坏软件正常运行（含爬虫、攻击、绕过安全机制等）；\n· 未经许可对软件或相关内容进行复制、改作、分发、商业化利用。')

          this.H('知识产权')
          this.P('古籍原文属公有领域文献；本应用中的校注整理成果、白话解读文案、神兽插画、剧本演绎、界面设计及软件代码的相关权利归我们所有。除法律允许或经我们书面授权外，用户仅可在个人、非商业目的范围内使用。')

          this.H('隐私保护')
          Row() {
            Text('我们重视你的隐私保护，当前版本不收集个人信息，出生日期仅用于本地演算；具体做法请参阅', )
              .fontSize(13)
              .fontColor($r('app.color.ink_primary'))
              .lineHeight(22)
              .layoutWeight(1)
            Text('《隐私政策》')
              .fontSize(13)
              .fontColor($r('app.color.cinnabar'))
              .onClick(() => {
                router.pushUrl({ url: 'pages/Legal/PrivacyPolicy' });
              })
          }
          .width('100%')
          .margin({ top: 2 })

          this.H('免责声明与责任限制')
          this.P('本软件按"现状"和"可用性"提供，我们不对排盘结果的准确性、适用性、持续性作出保证。因使用或无法使用本软件而造成的间接或附带损失，我们不承担责任。对第三方链接或服务的内容与安全性，我们不作担保。')

          this.H('变更与终止')
          this.P('我们可能适时更新本协议，并在版本更新或页面提示中说明。若你不同意变更，可停止使用；继续使用视为接受更新后的条款。我们可在必要时对服务进行暂停或终止，并依法履行告知义务。')

          this.H('联系方式')
          Column() {
            Text('如对本《用户协议》或相关事宜有任何问题，请通过')
              .fontSize(13)
              .fontColor($r('app.color.ink_primary'))
              .lineHeight(22)
            Text('is716652@qq.com')
              .fontSize(13)
              .fontColor($r('app.color.cinnabar'))
            Text('与我们联系')
              .fontSize(13)
              .fontColor($r('app.color.ink_primary'))
              .lineHeight(22)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .padding({ left: 16, right: 16, bottom: px2vp(this.navBarPx) + 16 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.On)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.paper_bg'))
  }
}
