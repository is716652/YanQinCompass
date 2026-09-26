import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Purchases } from '../utils/Purchases';
import { iap } from '@kit.IAPKit';

/**
 * 时占完整功能 · 付费墙（非消耗型买断 premium_unlock）
 * 一次购买永久解锁；沙盒环境购买为模拟支付。
 */
@Entry
@Component
struct PaywallPage {
  @State product: iap.Product | null = null;
  @State priceText: string = '';
  @State loading: boolean = true;
  @State purchasing: boolean = false;
  @State resultText: string = '';
  @State resultOk: boolean = false;
  @State owned: boolean = false;
  @StorageProp('statusBarPx') statusBarPx: number = 0;
  @StorageProp('navBarPx') navBarPx: number = 0;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    Purchases.init(context);
    this.loadData();
  }

  private async loadData(): Promise<void> {
    const owned = await Purchases.refreshOwned();
    this.owned = owned;
    const p = await Purchases.queryProduct();
    if (p !== null) {
      this.product = p;
      this.priceText = p.localPrice ?? p.price ?? '';
    } else {
      // 商品未配置/环境未就绪：降级文案（沙盒联调前常见）
      this.priceText = '';
    }
    this.loading = false;
  }

  private async onBuy(): Promise<void> {
    this.purchasing = true;
    this.resultText = '';
    const ok = await Purchases.purchase();
    this.purchasing = false;
    if (ok) {
      const verified = await Purchases.verifyAfterPurchase();
      this.owned = verified || true;
      this.resultOk = true;
      this.resultText = verified
        ? '✅ 购买成功，完整时占已解锁。'
        : '✅ 购买已提交，已解锁（凭证将在下次启动时与云侧复核）。';
    } else {
      this.resultOk = false;
      this.resultText = '购买未完成（可稍后重试，或点「恢复购买」同步本账号已购）。';
    }
  }

  private async onRestore(): Promise<void> {
    this.purchasing = true;
    this.resultText = '';
    const owned = await Purchases.refreshOwned();
    this.purchasing = false;
    this.owned = owned;
    this.resultOk = owned;
    this.resultText = owned
      ? '✅ 已同步本账号的购买记录，完整时占已解锁。'
      : '本华为账号暂无购买记录。';
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_primary')])
          .onClick(() => {
            router.back();
          })
        Text('解锁完整时占')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_primary'))
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: px2vp(this.statusBarPx) + 12, bottom: 12 })
      .backgroundColor($r('app.color.card_bg'))

      Scroll() {
        Column({ space: 16 }) {
          Image($r('app.media.startIcon'))
            .width(88)
            .height(88)
            .margin({ top: 24 })

          Text('演禽时占 · 完整功能')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ink_primary'))

          Column({ space: 10 }) {
            this.Benefit('一次购买，永久解锁', '非消耗型买断，不做订阅，后续新增功能免费更新')
            this.Benefit('不限次起盘', '每日免费额度（3 次）升级为不限次问事择时')
            this.Benefit('彼我吞啖断', '时禽与本命主星的吞啖关系详断（即将上线，买断即含）')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(16)

          if (this.loading) {
            LoadingProgress()
              .width(36)
              .height(36)
              .color($r('app.color.cinnabar'))
          } else if (this.owned) {
            Column({ space: 10 }) {
              Text('✅ 已解锁')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.cinnabar'))
              Text('本华为账号已拥有完整时占，无需重复购买。')
                .fontSize(13)
                .fontColor($r('app.color.ink_secondary'))
              Button('回到时占')
                .width('100%')
                .height(46)
                .fontSize(16)
                .backgroundColor($r('app.color.cinnabar'))
                .fontColor(Color.White)
                .onClick(() => {
                  router.back();
                })
            }
            .width('100%')
          } else {
            Button(this.purchasing ? '正在拉起支付…' : (this.priceText !== '' ? `¥ 买断解锁  ${this.priceText}` : '¥ 买断解锁'))
              .width('100%')
              .height(50)
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .backgroundColor($r('app.color.cinnabar'))
              .fontColor(Color.White)
              .enabled(!this.purchasing)
              .onClick(() => {
                this.onBuy();
              })
            Button('恢复购买')
              .width('100%')
              .height(44)
              .fontSize(14)
              .backgroundColor($r('app.color.chip_bg'))
              .fontColor($r('app.color.ink_primary'))
              .enabled(!this.purchasing)
              .onClick(() => {
                this.onRestore();
              })
          }

          if (this.resultText !== '') {
            Text(this.resultText)
              .fontSize(13)
              .fontColor(this.resultOk ? $r('app.color.cinnabar') : $r('app.color.ink_secondary'))
              .width('100%')
          }

          Text('付费功能为传统文化研习内容；购买通过华为应用内支付完成，可在华为帐号订单管理中查询。')
            .fontSize(10)
            .fontColor($r('app.color.ink_secondary'))
            .lineHeight(16)
            .width('100%')
            .margin({ bottom: px2vp(this.navBarPx) + 16 })
        }
        .padding({ left: 20, right: 20, top: 8 })
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
  }

  @Builder
  Benefit(title: string, desc: string) {
    Row({ space: 10 }) {
      Text('✓')
        .fontSize(16)
        .fontColor($r('app.color.cinnabar'))
      Column({ space: 2 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink_primary'))
        Text(desc)
          .fontSize(12)
          .fontColor($r('app.color.ink_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
  }
}
