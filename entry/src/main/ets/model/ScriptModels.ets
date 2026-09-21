/** 剧本（鉴形案）数据模型 */

/** 盘面卡片（剧本给定的既有盘面，非实时排盘） */
export interface ScriptBoardCard {
  id: string;       // 卡片标识（master/dayun/...）
  label: string;    // 卡片名（主星/大运/...）
  name: string;     // 主体（井木犴/戊戌/...）
  sub: string;      // 附注（宫位化道等）
  element: string;  // 七曜/五行（用于功能色）
}

/** 眼位线索（需玩家在盘面上点中的关键点） */
export interface ScriptClue {
  id: string;       // 眼位 id
  boardId: string;  // 对应盘面卡片 id
  brief: string;    // 疑点清单上的简语（未发现时可见）
  hint: string;     // 沉思提示（问句，不直接给答案）
  story: string;    // 点中后的剧情文案
}

/** 结局分层 */
export interface ScriptEnding {
  title: string;
  text: string[];
}

/** 一桩完整剧本案 */
export interface ScriptCase {
  caseId: string;
  title: string;
  chapterLabel: string;
  source: string;
  dossier: string[];
  board: ScriptBoardCard[];
  clues: ScriptClue[];
  confusions: Record<string, string>;   // 干扰卡点击 → 困惑文案
  endings: Record<string, ScriptEnding>; // perfect / partial / failed
}

/** 卷宗架上的案件条目（scripts/index.json，选案清单） */
export interface CaseMeta {
  id: string;           // 案件标识
  file: string;         // rawfile 下剧本 JSON 路径
  title: string;        // 案名
  era: string;          // 时代 · 人物
}

/** 案件清单 */
export interface CaseIndex {
  cases: CaseMeta[];
}
