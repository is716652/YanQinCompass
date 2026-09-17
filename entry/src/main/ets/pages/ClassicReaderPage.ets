import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { ClassicsLoader, ClassicBook, ClassicBookMeta, ClassicChapter } from '../utils/ClassicsLoader';

/**
 * 古籍阅读器：书架 → 章节目录 → 正文阅读（字号可调、上下章切换）。
 * 数据：rawfile/classics/*.md（《演禽通纂》三校本、《禽星易见》四库本）。
 */
@Entry
@Component
struct ClassicReaderPage {
  @State bookIdx: number = 0;
  @State book: ClassicBook | null = null;
  @State loading: boolean = false;
  @State loadError: string = '';
  @State reading: boolean = false;      // false=目录视图 true=正文视图
  @State chapterIdx: number = 0;
  @State fontSize: number = 17;
  @StorageProp('statusBarPx') statusBarPx: number = 0;
  @StorageProp('navBarPx') navBarPx: number = 0;
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  aboutToAppear(): void {
    const saved = AppStorage.get<number>('readerFontSize');
    if (saved !== undefined && saved >= 14 && saved <= 24) {
      this.fontSize = saved;
    }
    this.openBook(0);
  }

  private openBook(idx: number): void {
    const meta: ClassicBookMeta = ClassicsLoader.SHELF[idx];
    this.bookIdx = idx;
    this.book = null;
    this.loading = true;
    this.loadError = '';
    this.reading = false;
    ClassicsLoader.load(this.context, meta).then((b: ClassicBook) => {
      this.book = b;
      this.loading = false;
    }).catch((err: Error) => {
      console.error('[ClassicReader] load failed:', err.message);
      this.loadError = '加载失败：' + err.message;
      this.loading = false;
    });
  }

  private saveFont(): void {
    AppStorage.setOrCreate('readerFontSize', this.fontSize);
  }

  build() {
    Column() {
      // 顶部导航
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_primary')])
          .onClick(() => {
            if (this.reading) {
              this.reading = false;
            } else {
              router.back();
            }
          })
        Text(this.reading ? this.currentChapterTitle() : '古籍阅读')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_primary'))
          .maxLines(1)
          .layoutWeight(1)
        if (this.reading) {
          Row({ space: 10 }) {
            Text('A-')
              .fontSize(14)
              .fontColor($r('app.color.cinnabar'))
              .onClick(() => {
                if (this.fontSize > 14) {
                  this.fontSize -= 1;
                  this.saveFont();
                }
              })
            Text('A+')
              .fontSize(17)
              .fontColor($r('app.color.cinnabar'))
              .onClick(() => {
                if (this.fontSize < 24) {
                  this.fontSize += 1;
                  this.saveFont();
                }
              })
          }
        }
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: px2vp(this.statusBarPx) + 12, bottom: 12 })
      .backgroundColor($r('app.color.card_bg'))

      if (this.loadError !== '') {
        Text(this.loadError)
          .fontSize(14)
          .fontColor($r('app.color.cinnabar'))
          .margin({ top: 120 })
      } else if (this.loading) {
        Column({ space: 12 }) {
          LoadingProgress()
            .width(44)
            .height(44)
            .color($r('app.color.cinnabar'))
          Text('启卷中…')
            .fontSize(13)
            .fontColor($r('app.color.ink_secondary'))
        }
        .width('100%')
        .margin({ top: 120 })
      } else if (this.reading) {
        this.ReadingView()
      } else {
        this.CatalogView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.paper_bg'))
  }

  /** 目录视图：书架固定 + 章节列表独立滚动（去 Scroll 嵌套，保证滚到底完整可见） */
  @Builder
  CatalogView() {
    Column() {
      Scroll() {
        Column({ space: 14 }) {
          // 书架
          Row({ space: 12 }) {
            ForEach(ClassicsLoader.SHELF, (meta: ClassicBookMeta, idx: number) => {
              Column({ space: 4 }) {
                Text(meta.title)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.bookIdx === idx ? $r('app.color.cinnabar') : $r('app.color.ink_primary'))
                Text(meta.author)
                  .fontSize(10)
                  .fontColor($r('app.color.ink_secondary'))
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .padding(14)
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(14)
              .border({
                width: this.bookIdx === idx ? 1.5 : 0.5,
                color: this.bookIdx === idx ? $r('app.color.cinnabar') : $r('app.color.divider')
              })
              .onClick(() => {
                if (this.bookIdx !== idx) {
                  this.openBook(idx);
                }
              })
            }, (meta: ClassicBookMeta) => meta.file)
          }
          .width('100%')

          if (this.book !== null) {
            Text(this.book.desc)
              .fontSize(12)
              .fontColor($r('app.color.ink_secondary'))
              .lineHeight(19)
              .width('100%')
          }
        }
        .padding(16)
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')

      Divider().color($r('app.color.divider')).margin({ left: 16, right: 16 })

      if (this.book !== null) {
        List({ space: 6 }) {
          ForEach(this.book.chapters, (ch: ClassicChapter, idx: number) => {
            ListItem() {
              Row({ space: 10 }) {
                Text(`${idx + 1}`)
                  .fontSize(11)
                  .fontColor($r('app.color.ink_secondary'))
                  .width(26)
                  .textAlign(TextAlign.End)
                Text(ch.title)
                  .fontSize(14)
                  .fontColor($r('app.color.ink_primary'))
                  .maxLines(1)
                  .layoutWeight(1)
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(22)
                  .fontColor([$r('app.color.ink_secondary')])
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 13, bottom: 13 })
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(10)
              .onClick(() => {
                this.chapterIdx = idx;
                this.reading = true;
              })
            }
          }, (ch: ClassicChapter, idx: number) => `${idx}_${ch.title}`)
        }
        .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: px2vp(this.navBarPx) + 8 })
      } else {
        Column({ space: 12 }) {
          LoadingProgress()
            .width(44)
            .height(44)
            .color($r('app.color.cinnabar'))
          Text('启卷中…')
            .fontSize(13)
            .fontColor($r('app.color.ink_secondary'))
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 正文视图 */
  /** 正文视图 */
  @Builder
  ReadingView() {
    Column() {
      Scroll() {
        Column({ space: 14 }) {
          if (this.book !== null && this.chapterIdx < this.book.chapters.length) {
            Text(this.book.chapters[this.chapterIdx].title)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.ink_primary'))
              .width('100%')

            ForEach(this.book.chapters[this.chapterIdx].paragraphs, (p: string) => {
              Text(p)
                .fontSize(this.fontSize)
                .fontColor($r('app.color.ink_primary'))
                .lineHeight(this.fontSize * 1.8)
                .width('100%')
            }, (p: string, idx: number) => `${idx}_${p.length}`)
          }
        }
        .padding(18)
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .layoutWeight(1)

      // 底部：上一章 / 下一章
      Row({ space: 12 }) {
        Button('上一章')
          .layoutWeight(1)
          .height(42)
          .fontSize(14)
          .backgroundColor($r('app.color.chip_bg'))
          .fontColor($r('app.color.ink_primary'))
          .enabled(this.chapterIdx > 0)
          .onClick(() => {
            if (this.chapterIdx > 0) {
              this.chapterIdx -= 1;
            }
          })
        Text(`${this.chapterIdx + 1} / ${this.book !== null ? this.book.chapters.length : 0}`)
          .fontSize(12)
          .fontColor($r('app.color.ink_secondary'))
        Button('下一章')
          .layoutWeight(1)
          .height(42)
          .fontSize(14)
          .backgroundColor($r('app.color.chip_bg'))
          .fontColor($r('app.color.ink_primary'))
          .enabled(this.book !== null && this.chapterIdx < this.book.chapters.length - 1)
          .onClick(() => {
            if (this.book !== null && this.chapterIdx < this.book.chapters.length - 1) {
              this.chapterIdx += 1;
            }
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: px2vp(this.navBarPx) + 16 })
    }
    .width('100%')
    .height('100%')
  }

  private currentChapterTitle(): string {
    if (this.book !== null && this.chapterIdx < this.book.chapters.length) {
      return this.book.chapters[this.chapterIdx].title;
    }
    return '正文';
  }
}
