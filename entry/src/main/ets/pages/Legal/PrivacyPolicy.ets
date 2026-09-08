import { router } from '@kit.ArkUI';

@Entry
@Component
struct PrivacyPolicyPage {
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
        Text('隐私政策')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_primary'))
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: px2vp(this.statusBarPx) + 12, bottom: 12 })
      .backgroundColor($r('app.color.card_bg'))

      Scroll() {
        Column() {
          Text('演禽通纂（HarmonyOS）APP 隐私政策')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ink_primary'))
            .margin({ bottom: 6 })
            .width('100%')

          Text('更新日期：2026/09/06　　生效日期：2026/09/06')
            .fontSize(11)
            .fontColor($r('app.color.ink_secondary'))
            .margin({ bottom: 10 })
            .width('100%')

          this.H('导言')
          this.P('演禽通纂APP（以下简称"本应用"）是一款由独立开发者（以下简称"我们"）提供的古籍整理与传统术数排盘工具，基于《演禽通纂》《禽星易见》等古籍整理制作。我们非常重视您的隐私。本《隐私政策》向您说明，在使用本应用时，我们如何收集、使用、储存和分享信息，以及您享有的相关权利。请您仔细阅读，在需要时按照本政策作出适当选择。')
          this.P('您使用或继续使用本应用，即表示您已阅读并理解本《隐私政策》。当前版本不收集您的任何个人信息。')
          Column() {
            Text('如对本《隐私政策》或相关事宜有任何问题，请通过')
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
          .margin({ bottom: 8 })
          .alignItems(HorizontalAlign.Start)

          this.H('1. 我们收集的信息')
          this.P('当前版本不收集您的个人信息或设备标识符（如设备ID、MAC地址、OAID/IMEI/IMSI 等），不采集SD卡数据、安装列表或传感器数据，无需注册账号即可使用全部功能。')
          this.P('特别说明：您在排盘时输入的出生日期与时辰，仅在您的设备本地用于演算，不上传、不存储于任何服务器；该输入在应用运行期间存在于内存中，卸载应用后即不复存在。')
          this.P('为保障基本体验，本应用仅在本地记录您是否已同意本政策与《用户协议》的标记。如未来发生任何收集变更，将另行弹窗告知并征得您的同意。')

          this.H('权限调用说明及明示用途')
          this.P('当前版本仅使用基本显示与导航能力，不调用任何涉及个人隐私的敏感权限。若未来确需启用，我们将单独弹窗说明并征得您的明确同意。')

          this.H('静默及后台运行中的信息收集说明')
          this.P('静默或后台运行时，本应用不进行任何信息收集，也不进行广告相关评估数据采集。')

          this.H('第三方SDK接入情况')
          this.P('当前版本未接入任何第三方SDK，仅使用HarmonyOS官方API。')

          this.H('2. 信息的存储')
          this.P('2.1 信息存储的方式和期限\n· 当前版本不收集个人信息；应用仅在本地保存"已同意协议"标记等少量设置数据，不包含个人身份信息。')
          this.P('2.2 信息存储的地域\n· 当前版本不进行个人信息的跨境传输或存储。')

          this.H('3. 信息安全')
          this.P('本应用为纯本地计算工具，排盘演算与内容展示均在您的设备上完成，不涉及网络传输个人信息。我们仍建议您妥善保管设备，避免他人未经许可查阅您的使用记录。')

          this.H('4. 我们如何使用信息')
          this.P('当前版本不收集您的个人信息；如未来需要收集，将用于提供与您选择的服务相关的明确目的，并在收集前告知并征得您的同意。')

          this.H('5. 信息共享')
          this.P('当前版本不主动共享或转让您的个人信息至第三方，且未接入广告或统计类第三方SDK。若未来需要共享，我们将事先征得您的明示同意。')
          this.P('另外，根据相关法律法规及国家标准，以下情形中，我们可能会共享、转让、公开披露个人信息无需事先征得您的授权同意：\n· 与国家安全、国防安全直接相关的；\n· 与公共安全、公共卫生、重大公共利益直接相关的；\n· 与犯罪侦查、起诉、审判和判决执行等直接相关的；\n· 出于维护个人信息主体或其他个人的生命、财产等重大合法权益但又很难得到本人同意的；\n· 个人信息主体自行向社会公众公开个人信息的；\n· 从合法公开披露的信息中收集个人信息的，如合法的新闻报道、政府信息公开等渠道。')

          this.H('6. 您的权利')
          this.P('如未来收集个人信息，我们将提供查询、更正、删除、撤回同意等权利通道，并在产品内提供明确入口。您也可通过本《隐私政策》提供的联系方式与我们沟通。')

          this.H('7. 变更')
          this.P('我们可能适时修订本《隐私政策》的条款。当变更发生时，我们会在版本更新时向您提示新的《隐私政策》，并说明生效日期。若您继续使用本应用，即表示您同意我们按照更新后的《隐私政策》处理您的个人信息。')

          this.H('8. 未成年人保护')
          this.P('我们鼓励父母或监护人指导未满十八周岁的未成年人使用本应用，并建议未成年人在提交个人信息之前寻求父母或监护人的同意和指导。本应用内容属传统文化研究范畴，未成年人应在监护人引导下理性使用。')
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
