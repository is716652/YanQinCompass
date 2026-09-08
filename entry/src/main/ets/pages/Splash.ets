import { router } from '@kit.ArkUI';
import { DayStarUtils, DayStarResult } from '../utils/DayStarUtils';
import { Theme } from '../utils/Theme';

/**
 * 启动页：星空动效 + 今日值日星。
 * 隐私合规：已接入华为「标准化隐私声明托管服务」（系统自动弹平台标准隐私弹窗），
 * 应用内不再自行构建隐私弹窗（避免双弹窗，见 AGC 审核意见）；协议入口保留为页面链接。
 */
const RING_NAMES: string[] = [
  "角", "亢", "氐", "房", "心", "尾", "箕",
  "斗", "牛", "女", "虚", "危", "室", "壁",
  "奎", "娄", "胃", "昴", "毕", "觜", "参",
  "井", "鬼", "柳", "星", "张", "翼", "轸"
];

// 宿名环上位置（vp 绝对坐标，与窗口尺寸解耦）
interface RingPos {
  x: number;
  y: number;
}

// 点缀星（百分比坐标）
const TWINKLES: number[][] = [
  [12, 9], [28, 5], [47, 3], [68, 7], [86, 11], [18, 22], [78, 20], [55, 13], [35, 16], [90, 30]
];

@Entry
@Component
struct Splash {
  @State ringAngle: number = 0;       // 星宿名环旋转角
  @State twinkle: boolean = false;    // 星光闪烁驱动
  @State showDaily: boolean = false;  // 今日值日星浮现
  @State dailyStar: DayStarResult | null = null;
  @StorageProp('navBarPx') navBarPx: number = 0;

  aboutToAppear(): void {
    const now = new Date();
    this.dailyStar = DayStarUtils.calc(now.getFullYear(), now.getMonth() + 1, now.getDate());

    // 星宿名环：约 150 秒一圈，360 度与 0 度视觉重合，无限循环无缝
    animateTo({ duration: 150000, iterations: -1, curve: Curve.Linear }, () => {
      this.ringAngle = 360;
    });
    // 点缀星交错闪烁（各星 duration 随下标错开）
    animateTo({ duration: 1700, iterations: -1, playMode: PlayMode.Alternate, curve: Curve.EaseInOut }, () => {
      this.twinkle = true;
    });
    // 今日值日星延迟浮现
    setTimeout(() => {
      animateTo({ duration: 2000, curve: Curve.EaseInOut }, () => {
        this.showDaily = true;
      });
    }, 500);
  }

  build() {
    Stack() {
      // 背景：星夜山水（点击任意处进入）
      Image($r('app.media.yanqin_tong_background_vertical'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/InputPage'
          }, router.RouterMode.Single).catch((err: Error) => {
            console.error('Failed to push url:', err.message);
          });
        })

      // 点缀星（触摸穿透）
      this.TwinkleLayer()

      // 二十八宿名环（触摸穿透，缓慢旋转）
      this.RingLayer()

      // 今日值日星（环心浮现，触摸穿透）
      this.DailyStarLayer()

      // 底部协议链接（可点击）
      Row({ space: 20 }) {
        Text('《用户协议》')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.85)')
          .onClick(() => {
            router.pushUrl({ url: 'pages/Legal/UserAgreement' }).catch((err: Error) => {
              console.error('Failed to push url:', err.message);
            });
          })
        Text('《隐私政策》')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.85)')
          .onClick(() => {
            router.pushUrl({ url: 'pages/Legal/PrivacyPolicy' }).catch((err: Error) => {
              console.error('Failed to push url:', err.message);
            });
          })
        Blank()
        Text('点击任意处进入')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.55)')
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: px2vp(this.navBarPx) + 18 })
      .position({ x: 0, y: '100%' })
      .markAnchor({ x: 0, y: '100%' })
    }
    .width('100%')
    .height('100%')
  }

  /** 点缀星层 */
  @Builder
  TwinkleLayer() {
    Stack() {
      ForEach(TWINKLES, (t: number[], i: number) => {
        Circle({ width: 4, height: 4 })
          .fill('rgba(240,225,180,0.9)')
          .position({ x: t[0] + '%', y: t[1] + '%' })
          .opacity(this.twinkle ? 0.15 : (0.35 + 0.3 * (i % 3)))
          .animation({
            duration: 1200 + (i % 4) * 450,
            iterations: -1,
            playMode: PlayMode.Alternate,
            curve: Curve.EaseInOut
          })
      }, (t: number[]) => t[0].toString() + '_' + t[1].toString())
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }

  /** 二十八宿名环：按圆周排布，整环缓转（vp 定位，环心=屏心上方 110vp） */
  @Builder
  RingLayer() {
    Stack() {
      ForEach(RING_NAMES, (name: string, i: number) => {
        Text(name)
          .fontSize(17)
          .fontColor('rgba(216,178,90,0.6)')
          .position(this.ringPos(i))
          .markAnchor({ x: '50%', y: '50%' })
      }, (name: string) => name)
    }
    .width(320)
    .height(320)
    .rotate({ angle: this.ringAngle })
    .hitTestBehavior(HitTestMode.None)
    .offset({ x: 0, y: -110 })
  }

  /** 今日值日星：环心浮现（与宿名环同一中心） */
  @Builder
  DailyStarLayer() {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 10 }) {
        if (this.dailyStar !== null) {
          Image(Theme.starImage(this.dailyStar.star))
            .width(136)
            .height(136)
            .objectFit(ImageFit.Contain)
            .shadow({ radius: 24, color: 'rgba(0,0,0,0.45)', offsetY: 6 })
          Text(`今日值日 · ${this.dailyStar.fullName}`)
            .fontSize(15)
            .fontColor('rgba(216,178,90,0.9)')
        }
      }
      .alignItems(HorizontalAlign.Center)
      .offset({ x: 0, y: -110 })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
    .opacity(this.showDaily ? 1 : 0)
    .scale({ x: this.showDaily ? 1 : 0.86, y: this.showDaily ? 1 : 0.86 })
  }

  /** 宿名在环上的 vp 坐标（容器 320×320，半径 128） */
  private ringPos(i: number): RingPos {
    const theta = (i * 2 * Math.PI) / 28 - Math.PI / 2;
    const r = 128;
    const pos: RingPos = {
      x: 160 + r * Math.cos(theta),
      y: 160 + r * Math.sin(theta)
    };
    return pos;
  }
}
