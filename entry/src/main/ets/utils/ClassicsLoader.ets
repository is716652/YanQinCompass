import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';

/** 古籍章节 */
export interface ClassicChapter {
  title: string;
  paragraphs: string[];
}

/** 古籍全书（含解析结果） */
export interface ClassicBook {
  file: string;
  title: string;
  author: string;
  desc: string;
  chapters: ClassicChapter[];
}

/** 书目元数据（阅读器书架） */
export interface ClassicBookMeta {
  file: string;
  title: string;
  author: string;
  desc: string;
}

/** 行内清理：去除 markdown 粗体标记与引用符号 */
function cleanLine(s: string): string {
  let t = s.replace(/\*\*/g, '');
  if (t.startsWith('> ')) {
    t = t.slice(2);
  } else if (t.startsWith('>')) {
    t = t.slice(1);
  }
  if (t.startsWith('- ')) {
    t = '· ' + t.slice(2);
  }
  return t.trim();
}

export class ClassicsLoader {
  /** 书架：两本已入库古籍 */
  static readonly SHELF: ClassicBookMeta[] = [
    {
      file: 'classics/yanqin_tongzuan.md',
      title: '演禽通纂',
      author: '明·佚名（三校本）',
      desc: '命理演禽宗卷：起例、吞啖、化道、大名论十三篇、鉴形赋、古人得失诸赋。'
    },
    {
      file: 'classics/qinxing_yijian.md',
      title: '禽星易见',
      author: '明·池本理（四库本）',
      desc: '禽遁时占宗卷：演禽赋、七元甲子、翻禽倒将、逐宿详解、十五类占法。'
    }
  ];

  /** 加载并解析一本书（### 与 ## 均为章，表格与空行略去） */
  static async load(context: common.UIAbilityContext, meta: ClassicBookMeta): Promise<ClassicBook> {
    const resourceManager = context.resourceManager;
    const fileData = await resourceManager.getRawFileContent(meta.file);
    const decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
    const text = decoder.decodeWithStream(fileData);

    const chapters: ClassicChapter[] = [];
    let current: ClassicChapter | null = null;
    const lines = text.split('\n');
    for (const raw of lines) {
      const line = raw.trim();
      if (line === '' || line.startsWith('|') || line === '---') {
        continue;
      }
      if (line.startsWith('### ')) {
        current = { title: cleanLine(line.slice(4)), paragraphs: [] };
        chapters.push(current);
        continue;
      }
      if (line.startsWith('## ')) {
        current = { title: cleanLine(line.slice(3)), paragraphs: [] };
        chapters.push(current);
        continue;
      }
      if (line.startsWith('# ')) {
        continue; // 书名大标题，书目卡已展示
      }
      const para = cleanLine(line);
      if (para === '') {
        continue;
      }
      if (current === null) {
        current = { title: '题记', paragraphs: [] };
        chapters.push(current);
      }
      current.paragraphs.push(para);
    }

    const book: ClassicBook = {
      file: meta.file,
      title: meta.title,
      author: meta.author,
      desc: meta.desc,
      chapters: chapters
    };
    return book;
  }
}
