import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { DataLoader } from '../utils/DataLoader';
import { Theme } from '../utils/Theme';
import { ScriptCase, ScriptBoardCard, ScriptClue } from '../model/ScriptModels';

/** 案例清单条目 */
interface CaseMeta {
  file: string;
  title: string;
  era: string;
}

/**
 * 鉴形 · 剧本案页面
 *
 * 交互流程（依据 规则/古籍搞/禽星剧本化创意-鉴形计划.md）：
 * 卷宗呈现（白话案宗，古籍原断不显示）→ 起盘（剧本给定盘面卡片）
 * → 拼图解盘（点击盘面找"眼位"，点错无惩罚只出"困惑"文案，沉思按钮给问句提示）
 * → 结局分层（集齐眼位=神断/部分=疑虑/极少=天机隐），解锁古籍原批。
 */
@Entry
@Component
struct ScriptPage {
  @State caseData: ScriptCase | null = null;
  @State loadError: string = '';
  @State stage: number = -1;         // -1 案例选择 / 0 卷宗 / 1 观盘 / 2 结局
  @State caseIdx: number = 0;
  @State foundIds: string[] = [];    // 已发现的眼位 id
  // 案例清单（新增案例：rawfile/scripts/ 加数据文件后在此登记）
  private readonly caseList: CaseMeta[] = [
    { file: 'scripts/case_xiangyu.json', title: '第一案 · 西楚霸王', era: '秦末汉初 · 项羽' },
    { file: 'scripts/case_songtaizu.json', title: '第二案 · 宋太祖', era: '五代北宋 · 赵匡胤' }
  ];
  @State storyText: string | null = null;  // 眼位剧情浮层
  @State toastText: string | null = null;  // 困惑/沉思提示浮层
  @State toastTitle: string = '沉思';       // 提示浮层标题
  @StorageProp('statusBarPx') statusBarPx: number = 0;
  @StorageProp('navBarPx') navBarPx: number = 0;
  private dataLoader: DataLoader | null = null;

  /** 打开指定案例（加载 JSON 并进入卷宗） */
  private openCase(idx: number): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.dataLoader = new DataLoader(context);
    this.caseIdx = idx;
    const meta = this.caseList[idx];
    this.dataLoader.loadJson<ScriptCase>(meta.file).then((cs: ScriptCase) => {
      this.caseData = cs;
      this.foundIds = [];
      this.stage = 0;
    }).catch((err: Error) => {
      console.error('[ScriptPage] load case failed:', err.message);
      this.loadError = '剧本加载失败：' + err.message;
    });
  }

  build() {
    Stack() {
      Column() {
        if (this.stage === -1) {
          this.CaseSelectView()
        } else if (this.loadError !== '') {
          Text(this.loadError)
            .fontSize(14)
            .fontColor($r('app.color.cinnabar'))
            .margin({ top: 120 })
        } else if (this.caseData === null) {
          Column({ space: 12 }) {
            LoadingProgress()
              .width(44)
              .height(44)
              .color($r('app.color.cinnabar'))
            Text('开启卷宗…')
              .fontSize(13)
              .fontColor($r('app.color.ink_secondary'))
          }
          .width('100%')
          .margin({ top: 120 })
        } else if (this.stage === 0) {
          this.DossierStage()
        } else if (this.stage === 1) {
          this.BoardStage()
        } else {
          this.EndingStage()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.paper_bg'))

      // 浮层（剧情 / 困惑 / 沉思提示）
      if (this.storyText !== null) {
        this.PopupLayer('灵光一现', this.storyText, () => {
          this.storyText = null;
        })
      } else if (this.toastText !== null) {
        this.PopupLayer(this.toastTitle, this.toastText, () => {
          this.toastText = null;
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 阶段一：卷宗呈现 */
  @Builder
  DossierStage() {
    Scroll() {
      Column({ space: 14 }) {
        Row({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor([$r('app.color.ink_primary')])
            .onClick(() => {
              this.stage = -1;
            })
          Text(this.caseData !== null ? this.caseData.chapterLabel : '')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.ink_secondary'))
        }
        .width('100%')
        .margin({ top: px2vp(this.statusBarPx) + 8 })

        Text(this.caseData !== null ? this.caseData.title : '')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_primary'))

        Divider().color($r('app.color.divider'))

        Column({ space: 12 }) {
          ForEach(this.caseData !== null ? this.caseData.dossier : [], (line: string) => {
            Text(line)
              .fontSize(15)
              .fontColor($r('app.color.ink_primary'))
              .lineHeight(28)
              .width('100%')
          }, (line: string) => line)
        }
        .alignItems(HorizontalAlign.Start)
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(16)
        .width('100%')

        Button('起盘窥天')
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .backgroundColor($r('app.color.cinnabar'))
          .fontColor(Color.White)
          .onClick(() => {
            this.stage = 1;
          })

          Text(this.caseData !== null ? `案出 ${this.caseData.source}` : '')
            .fontSize(11)
            .fontColor($r('app.color.ink_secondary'))
            .width('100%')
            .margin({ bottom: px2vp(this.navBarPx) + 12 })
        }
        .padding({ top: 16, left: 16, right: 16 })
      .width('100%')
    }
    .scrollBar(BarState.Off)
    .width('100%')
    .height('100%')
  }

  /** 阶段二：解盘（盘面找眼位） */
  @Builder
  BoardStage() {
    Column() {
      // 顶栏
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_primary')])
          .onClick(() => {
            this.stage = 0;
          })
        Text('观盘')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_primary'))
        Blank()
        Text(`已察眼位 ${this.foundIds.length} / ${this.caseData !== null ? this.caseData.clues.length : 0}`)
          .fontSize(13)
          .fontColor($r('app.color.cinnabar'))
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: px2vp(this.statusBarPx) + 12, bottom: 12 })

      Scroll() {
        Column({ space: 14 }) {
          // 盘面卡片
          Grid() {
            ForEach(this.caseData !== null ? this.caseData.board : [], (card: ScriptBoardCard) => {
              GridItem() {
                this.BoardCard(card)
              }
            }, (card: ScriptBoardCard) => card.id)
          }
          .columnsTemplate('1fr 1fr')
          .rowsTemplate('1fr 1fr 1fr')
          .columnsGap(10)
          .rowsGap(10)
          .height(620)
          .width('100%')

          // 疑点清单
          Column({ space: 8 }) {
            Text('疑点清单')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.ink_primary'))
            ForEach(this.caseData !== null ? this.caseData.clues : [], (clue: ScriptClue) => {
              Row({ space: 8 }) {
                Text(this.foundIds.indexOf(clue.id) >= 0 ? '✓' : '□')
                  .fontSize(16)
                  .fontColor(this.foundIds.indexOf(clue.id) >= 0 ? $r('app.color.cinnabar') : $r('app.color.ink_secondary'))
                Text(clue.brief)
                  .fontSize(13)
                  .fontColor(this.foundIds.indexOf(clue.id) >= 0 ? $r('app.color.ink_primary') : $r('app.color.ink_secondary'))
              }
              .width('100%')
            }, (clue: ScriptClue) => clue.id)
          }
          .alignItems(HorizontalAlign.Start)
          .padding(14)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(14)
          .width('100%')

          // 操作按钮
          Row({ space: 10 }) {
            Button('沉思')
              .layoutWeight(1)
              .height(44)
              .fontSize(15)
              .backgroundColor($r('app.color.chip_bg'))
              .fontColor($r('app.color.ink_primary'))
              .onClick(() => {
                this.onMeditate();
              })
            Button('合盘定论')
              .layoutWeight(1)
              .height(44)
              .fontSize(15)
              .backgroundColor($r('app.color.cinnabar'))
              .fontColor(Color.White)
              .onClick(() => {
                this.stage = 2;
              })
          }
          .width('100%')

          Text('盘上六格是项王命运的六个侧面，其中四处藏着败亡的关键。逐格点开查看，寻齐后合盘定论；卡住时点『沉思』索要提示。')
            .fontSize(11)
            .fontColor($r('app.color.ink_secondary'))
            .lineHeight(18)
            .width('100%')
            .margin({ bottom: px2vp(this.navBarPx) + 12 })
        }
        .padding({ left: 16, right: 16 })
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  /** 阶段三：结局 */
  @Builder
  EndingStage() {
    Scroll() {
      Column({ space: 14 }) {
          Row({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor([$r('app.color.ink_primary')])
            .onClick(() => {
              this.stage = 1;
            })
          Text('案结')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ink_primary'))
        }
        .width('100%')
        .margin({ top: px2vp(this.statusBarPx) + 8 })

        Column({ space: 12 }) {
          ForEach(this.currentEndingText(), (line: string) => {
            Text(line)
              .fontSize(15)
              .fontColor($r('app.color.ink_primary'))
              .lineHeight(28)
              .width('100%')
          }, (line: string, idx: number) => `${idx}`)
        }
        .alignItems(HorizontalAlign.Start)
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(16)
        .width('100%')

        Text(`本案察得眼位 ${this.foundIds.length} 处`)
          .fontSize(12)
          .fontColor($r('app.color.ink_secondary'))
          .width('100%')

        Row({ space: 10 }) {
          Button('重开此案')
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .backgroundColor($r('app.color.chip_bg'))
            .fontColor($r('app.color.ink_primary'))
            .onClick(() => {
              this.foundIds = [];
              this.stage = 0;
            })
          Button('离开卷宗')
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .backgroundColor($r('app.color.cinnabar'))
            .fontColor(Color.White)
            .onClick(() => {
              router.back();
            })
        }
        .width('100%')
        .margin({ bottom: px2vp(this.navBarPx) + 12 })
      }
      .padding(16)
      .width('100%')
    }
    .scrollBar(BarState.Off)
    .width('100%')
    .height('100%')
  }

  /** 盘面卡片 */
  @Builder
  BoardCard(card: ScriptBoardCard) {
    Column({ space: 3 }) {
      Text(card.label)
        .fontSize(11)
        .fontColor($r('app.color.ink_secondary'))
      if (card.id === 'master') {
        Image(Theme.starImage('井'))
          .width(64)
          .height(64)
          .objectFit(ImageFit.Contain)
        Text(card.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_primary'))
      } else {
        Text(card.name)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.elemColor(card.element))
      }
      Text(card.sub)
        .fontSize(10)
        .fontColor($r('app.color.ink_secondary'))
        .maxLines(2)
        .textAlign(TextAlign.Center)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor(this.foundIds.indexOf(card.id) >= 0 ? $r('app.color.cinnabar_soft') : $r('app.color.card_bg'))
    .borderRadius(14)
    .border({
      width: this.foundIds.indexOf(card.id) >= 0 ? 1.5 : 0.5,
      color: this.foundIds.indexOf(card.id) >= 0 ? $r('app.color.cinnabar') : $r('app.color.divider')
    })
    .onClick(() => {
      this.onCardTap(card);
    })
  }

  /** 案例选择（鉴形研习首页，Flex 卡片——与图鉴页同款已验证结构） */
  @Builder
  CaseSelectView() {
    Column() {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_primary')])
          .onClick(() => {
            router.back();
          })
        Text('鉴形研习')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_primary'))
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: px2vp(this.statusBarPx) + 12, bottom: 12 })
      .backgroundColor($r('app.color.card_bg'))

      Column({ space: 14 }) {
        Text('以剧本形式演绎古籍断案：读卷宗、寻眼位、断成败——与千年前的古籍神断对勘。')
          .fontSize(12)
          .fontColor($r('app.color.ink_secondary'))
          .lineHeight(20)
          .width('100%')

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.caseList, (meta: CaseMeta, idx: number) => {
            Column({ space: 6 }) {
              Text(meta.title)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.ink_primary'))
              Text(meta.era)
                .fontSize(12)
                .fontColor($r('app.color.ink_secondary'))
              Row({ space: 6 }) {
                Text('研习')
                  .fontSize(11)
                  .fontColor($r('app.color.cinnabar'))
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(20)
                  .fontColor([$r('app.color.cinnabar')])
              }
            }
            .alignItems(HorizontalAlign.Start)
            .width('46%')
            .padding(14)
            .margin({ right: 12, bottom: 12 })
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(14)
            .onClick(() => {
              console.info('[ScriptPage] card clicked idx=' + idx);
              this.openCase(idx);
            })
          }, (meta: CaseMeta) => meta.file)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: px2vp(this.navBarPx) })
    .backgroundColor($r('app.color.paper_bg'))
    .alignItems(HorizontalAlign.Start)
  }

  /** 浮层（遮罩 + 卡片 + 继续按钮） */
  @Builder
  PopupLayer(title: string, text: string, onClose: () => void) {
    Column() {
      Column({ space: 12 }) {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.cinnabar'))
        Text(text)
          .fontSize(14)
          .fontColor($r('app.color.ink_primary'))
          .lineHeight(25)
        Button('继续')
          .width('60%')
          .height(40)
          .backgroundColor($r('app.color.cinnabar'))
          .fontColor(Color.White)
          .onClick(() => {
            onClose();
          })
      }
      .alignItems(HorizontalAlign.Start)
      .padding(20)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)
      .width('88%')
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(20,16,10,0.55)')
    .onClick(() => {
      onClose();
    })
  }

  // --- 逻辑 ---

  /** 点击盘面卡片：眼位则触发剧情，干扰卡则出困惑文案 */
  private onCardTap(card: ScriptBoardCard): void {
    const cs = this.caseData;
    if (cs === null) {
      return;
    }
    const clue = cs.clues.find((c) => c.boardId === card.id);
    if (clue !== undefined) {
      if (this.foundIds.indexOf(clue.id) < 0) {
        this.foundIds.push(clue.id);
      }
      this.toastText = null;
      this.storyText = clue.story;
    } else {
      const conf: string = cs.confusions[card.id];
      this.toastTitle = '摇头';
      this.toastText = conf !== undefined && conf !== ''
        ? conf
        : '你端详片刻，此处星象平顺，与劫数无涉。你摇了摇头，再观他处。';
    }
  }

  /** 沉思：给一条未发现眼位的问句提示 */
  private onMeditate(): void {
    const cs = this.caseData;
    if (cs === null) {
      return;
    }
    let pending: string | null = null;
    for (const clue of cs.clues) {
      if (this.foundIds.indexOf(clue.id) < 0) {
        pending = clue.hint;
        break;
      }
    }
    if (pending === null) {
      this.toastTitle = '沉思';
      this.toastText = '疑点已尽，玄机皆明。合盘定论吧。';
    } else {
      this.toastTitle = '沉思';
      this.toastText = `沉思片刻——${pending}`;
    }
  }

  /** 结局分层：集齐=神断 / 过半=疑虑 / 其余=天机隐 */
  private currentEndingText(): string[] {
    const cs = this.caseData;
    if (cs === null) {
      return [];
    }
    const total = cs.clues.length;
    const found = this.foundIds.length;
    const key = found >= total ? 'perfect' : (found * 2 >= total ? 'partial' : 'failed');
    const ending = cs.endings[key];
    if (ending === undefined) {
      return [];
    }
    return [ending.title].concat(ending.text);
  }
}
