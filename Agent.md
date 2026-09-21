# Agent.md — 项目记忆文件

> 本文档用于记录项目关键信息与开发约定，供 AI 代理与协作者快速了解项目状态。
> 每次重大修改后应更新"修改记录"章节。

## 项目概述

**演禽通纂（YanQinCompass）**：基于《演禽通纂》（明代演禽术数古籍）的鸿蒙手机应用。
根据生辰公历日期推算演禽命盘——主星/胎星/命星/身星、命宫/身宫、化道环境、吞啖吉凶、四时旺衰。

- bundleName：**cn.is716652.yanqin**（2026-09-06 起；原 cn.is716652.zhongliuren 与六壬项目冲突已弃用，
  调试签名已重新生成）
- 应用名（桌面/商店）：**演禽通纂**（AppScope app_name 与 entry EntryAbility_label 两处一致）
- 技术栈：HarmonyOS NEXT（API 6.0.0/20），ArkTS + ArkUI 声明式，无第三方依赖
- 设备类型：phone
- 日期支持范围：1900-01-01 ~ 2061-12-31（万年历数据）

## 构建与运行

构建工具链统一使用 `D:\HarmonyOS\command-line-tools-6.1.1-release`（hvigor 6.24.4 / SDK 6.1.1 / API 24）。
签名/上架的完整命令与双产品配置说明见下方「签名与上架（2026-09-07 定稿）」一节——
**装机调试用 `-p product=default -p buildMode=debug`，上架打包用 `-p product=release -p buildMode=release` 两步命令，切勿混用。**

> SDK 版本注意：当前 targetSdkVersion/compatibleSdkVersion 为 6.0.0(20)，仅可安装于 HarmonyOS 6.0+ 设备；
> 若想覆盖 5.0 设备需将 compatibleSdkVersion 降级到 5.0.x（如 5.0.5(17)）并做全量回归（引擎未用高版本专属 API，理论可行，需实测）。

- 页面流：`Splash`（星空动效，点击进入）→ `InputPage`（值日禽星卡+选日期/时辰/性别）→ `ResultPage`（排盘结果）；另有 `ScriptPage`（鉴形剧本）、`BestiaryPage`（图鉴）、`ClassicReaderPage`（古籍阅读）、`pages/Legal/`（隐私政策与用户协议）
- `pages/Index.ets` 是遗留的 Hello World 模板页，未在 `main_pages.json` 使用，勿删可不管

## 代码结构

```
AppScope/                          # 应用级配置（app.json5）
entry/src/main/ets/
├── entryability/EntryAbility.ets  # 入口，加载 Splash
├── pages/
│   ├── Splash.ets                 # 启动页
│   ├── InputPage.ets              # 输入表单（DatePicker + 时辰 + 性别单选）
│   ├── ResultPage.ets             # 结果页：加载数据→排盘→卡片展示
│   └── Index.ets                  # 遗留模板页（未使用）
├── model/
│   ├── Types.ets                  # 数据类型：CalendarDay / Animal / InteractionRule / TransformationData...
│   └── ChartModels.ets            # YanQinChart（排盘结果）/ UserInput
└── utils/
    ├── DataLoader.ets             # rawfile JSON 加载 + 万年历按日查询（含文件级缓存）
    ├── YanQinEngine.ets           # ★ 核心排盘引擎（古法）
    ├── Theme.ets                  # 七曜→功能色映射（设计令牌在 base/dark color.json）
    ├── LunarFormatter.ets         # 农历月日中文文案（八月初八、冬月廿三）
    └── ChartSummary.ets           # 排盘结果 → 白话总评
entry/src/main/resources/rawfile/
├── calendar/calendar_data_0001~0017.json  # 万年历 1900-2061（每10年一文件，共约27MB）
├── animals.json                   # 二十八宿→动物映射（含明禽/暗禽 note）
├── interactions.json              # 吞啖关系（relationships + verse_rules 歌诀）
├── transformations.json           # 六十甲子/天干/地支化道环境意象
├── seasonal_strength.json         # 四时（春夏秋冬）旺星表
└── json数据文件解读.md             # 数据文件说明
规则/                               # 古籍原文与规则解释（算法依据）
├── 演禽通纂.md                     # 古籍三校本全文（1253 行）
├── algorithm_explanation.md       # ★ 排盘算法详解（旬头/三元/命宫/合宿等）
├── animals_explanation.md         # 三十六禽体系
├── huadao_explanation.md          # 化道规则
└── tundan_explanation.md          # 吞啖规则
```

## ★ 核心排盘算法（已实现，依据 演禽通纂.md + algorithm_explanation.md）

输入：公历日期 + 时辰(0-23) + 性别；万年历数据提供农历月日与干支。

1. **起旬头**：生年干支（万年历 `year_gan/year_zhi`，农历年）倒推天干至甲，得旬头地支
   `xunZhiIdx = ((年支序号 - 年干序号) mod 12)`，旬头 = 甲 + 该地支（甲子/甲寅/甲辰/甲午/甲申/甲戌）
2. **三元定旬头星**：1864 起 180 年一轮（0-59 上元 / 60-119 中元 / 120-179 下元），查表：
   | 旬头 | 上元 | 中元 | 下元 |
   |---|---|---|---|
   | 甲子 | 箕水豹 | 鬼金羊 | 角木蛟 |
   | 甲寅 | 氐土狢 | 毕月乌 | 星日马 |
   | 甲辰 | 参水猿 | 斗木獬 | 奎木狼 |
   | 甲午 | 虚日鼠 | 张月鹿 | 房日兔 |
   | 甲申 | 轸水蚓 | 娄金狗 | 井木犴 |
   | 甲戌 | 昴日鸡 | 心月狐 | 危月燕 |
3. **起主星**：旬头星**下一位**起数"农历生日"个星宿 → 所得星宿安于子宫（归子）→ 从子宫顺数至命宫（子=0，需数 `命宫序号+1` 个）
4. **胎星** = 主星下一位
5. **命宫**：子上起正月逆数至生月，从该位起子时顺数至生时
   `mingGong = ((0 - (农历月-1) + 时辰地支序号) mod 12)`；干支用**五虎遁**（年干定正月干）
6. **命星** = 胎星之合宿（六合表）安子宫，顺数至命宫；**身星** = 命星之合宿安子宫，顺数至身宫
7. **身宫**：`(农历月×2 + 农历日)` 从子宫逆数（落位 `((0-(身数-1)) mod 12)`）
8. **流年星**：以胎星作一岁，顺数至当前虚岁（`当年-出生年+1`）
9. **化道**：年/月/日/时四柱干支查 `transformations.json.jiazi_map`（时柱干用**五鼠遁**）
10. **吞啖**：主胎 / 主星vs流年 / 胎星vs流年 三组，`eats` 与 `fears` 双向判定 + 歌诀规则；`note` 修正标注（见下）
11. **四时生旺**：主星在当季旺星列表 → "旺"，否则"休"

**关键修正规则**：
- **男女除补**：男命数星遇"牛金牛"跳过，女命遇"女土蝠"跳过；**落宫恰好是牛/女则不除**（闰月不除未实现，万年历数据无闰月字段）
- **合宿表（六合，14 对双向）**：角昴、亢胃、氐娄、奎房、心壁、斗虚、箕危、尾室、牛女、觜翼、参张、柳鬼、毕轸、井星
- **吞啖修正词**（命中才标注）：`夜生不忌`(夜生) / `春夏减半`(农历1-6月) / `秋冬不忌`(7-12月) / `冬不忌`(10-12月) / `四孟减半`(1/4/7/10月) / `正九月有灾`(1/9月) / `凶星不忌`
- 昼夜判定：`5 <= 时 < 18` 为昼

**算法验证锚点**（原文例：辛卯年八月初八日子时男，下元）：
主星=箕水豹、胎星=斗木獬、命宫干支=癸巳——引擎输出与之完全一致。
注意：原文"起命星例"（安命丙申宫）与"起主胎星例"（到巳为住）命宫存在版本矛盾，
**当前采用与主星例自洽的命宫公式**（algorithm_explanation.md §2.3）。

## 万年历数据要点

- `year_gan/year_zhi` = **农历年干支**（正月初一切换，非立春）；`lunar_year/month/day` 为农历
- `month_gan/month_zhi` 按**节气月**（立春/惊蛰…）
- 文件选择：`index = floor((year-1900)/10)+1`，0017 覆盖 2060-2061；`DataLoader.loadCalendarDay()` 已封装
- 单个文件约 1.6MB，加载后线性 `find` 日期匹配（3652 条/文件，可接受）

## 七元甲子值日锚点（已考订，2026-09-06）

**锚点：1984-02-02 为一元甲子日，起虚日鼠**；420 日一循环（7元×60日），每元四将各管 15 日。
七元将头：一元虚、二元奎、三元毕、四元鬼、五元翼、六元氐、七元箕；四将次序同《禽星易见》歌诀
（一元虚张室轸/二奎亢胃房/三毕尾参斗/四鬼女星危/五翼壁角娄/六氐昴心觜/七箕井牛柳）。
来源：姐妹项目 `CelestialBeastsAuspiciousTiming`（禽星盘式）的 `YanqinConfig.ets calculateDayStar`，
其 `yanqin_star_rules.json` base_date 注释明确"1984年2月2日为一元甲子日，起虚日鼠"，
七元将头经逐项比对与《禽星易见》完全一致。每日禽星（值日星）算法可直接采用此锚点。

## 签名与上架（2026-09-08 更新：驳回修复——删除自定义隐私弹窗，等待重新提审）

- **审核驳回（2026-09-07）**：首提人工审核驳回，意见"应用出现两个隐私弹窗"——账号已接入华为「标准化隐私声明托管服务」（系统自动弹平台标准隐私弹窗），应用内 Splash 又弹自定义授权弹窗 → 双弹窗。审核环境 HarmonyOS 6.1.0 / API 24。
- **修复（按审核建议）**：删除 Splash 自定义授权弹窗（LegalConsentDialog）与LegalManager 同意标记检查；保留 Splash 底部《用户协议》《隐私政策》链接行、InputPage 页脚链接、Legal 两页面。LegalManager.ets 文件保留但已无引用。
- **重新提审包**：`build/outputs/release/YanQinCompass-release-signed.app`（09-08 22:01 v1.0.1 候选：驳回修复【删自定义弹窗】+ 无障碍/导航条适配 + 旺衰四档引擎。装机复验：排盘正常、四档显示"秋季·囚"、无弹窗）。注意：旺衰四档 JSON 与引擎必须同步改（曾因只改数据未改引擎导致排盘报"数据加载失败"的中间态包）。
- **上架产物**：`build/outputs/release/YanQinCompass-release-signed.app`（product=release 构建，已通过 AGC 包校验）。

- **当前状态（2026-09-07）**：v1.0.0 已提交 AGC 人工审核，审核中。首提曾因"一句话简介/应用介绍/版本特性内容重复"被表单拦截，重写三段文案去重后提交成功（一句话=定义句；介绍=场景钩子「翻开手机，你就是钦天监的星官」+「」分节体例；特性=更新日志口吻，三段零重复）。
- **上架产物**：`build/outputs/release/YanQinCompass-release-signed.app`（product=release 构建，
  已通过 AGC 包校验）。
  已通过 AGC 包校验进入自检）。
- **上架标准命令（两步，顺序固定）**：
  ```bash
  hvigorw assembleHap --mode module -p product=release -p buildMode=release --no-daemon  # 先触发 SignHap
  hvigorw assembleApp  --mode module -p product=release -p buildMode=release --no-daemon  # 再打 .app
  ```
- **双产品配置**（build-profile.json5，2026-09-07）：product=default（调试签名，hdc 装机）、
  product=release（发布签名，上架）；applyToProducts 已含两者。
- **993/991 完整根因（重要教训，已实证）**：
  1. **AGC 校验的是 .app 的「App 级签名块」中嵌入的 Profile**——hvigor assembleApp 会对 .app
     整体签名，签名材料取自 product.signingConfig。命令行打包不会因 buildMode=release 自动切换，
     default 产品的 App 级签名嵌的是调试 Profile → AGC 993（与发布材料文件无关，换材料无效）
  2. **App Pack 有结构与签名校验，不能手工 zip 组装**——手工组装的 .app 无 App 级签名 → AGC 991
     （即便内嵌的 HAP 是正确发布签名的也没用）
  3. SignHap（HAP 级签名）任务会 UP-TO-DATE 跳过；且 .app 内 HAP 可以为未签名 HAP
     （AGC 不看 HAP 级签名块，看 App 级的）——因此"HAP 是否签名"不是 993 的判据
- **修复后正确姿势**：一切以 -p product=release 构建打包；产物 -signed.app（App 级签名）
  上传，-unsigned.app 忽略。验证方法：-signed.app 应比 -unsigned.app 大 10~20KB（App 签名块），
  且两者 HAP 字节可以不同（assembleApp 会重新打包）。
- **历史因素（已随重新申请消除）**：首批发布 Profile 绑定证书（FCB5…）与签名 .cer（DF21… 链）
  错配也曾叠加；重新申请后 Profile 签发证书 = 签名 .cer 叶子（8394AB89…）= p12 私钥，官方
  verify-profile 通过。
- **工具备忘**：hap-sign-tool.jar verify-profile -inFile x.p7b -outFile r.json 可离线校验 Profile。
  勿用"在 HAP 二进制搜 p7b 明文"验证签名——App 签名块内 Profile 为 DER 编码不含 JSON 明文，
  会误判（曾因此把正确的包误认为未签名）。p7b 两种格式（PEM 式/DER+JSON 明文式），JSON 式
  证书字段名 distribution-certificate。
## 上架材料（上架材料/ 目录，2026-09-06 定稿）

- **商店图标_1024.png**：1024×1024 PNG（星盘印章+宣纸底）
- **商店截图/**：成品 9 张 1080×1920 PNG（由 原始/ 用户手截图按 9:16 居中裁剪、
  重排叙事顺序：启动星空→命盘→图鉴→输入→时辰→剧本→宿详情→古籍目录→正文）；
  原始/ 子目录保留用户原图
- **商店文案.md**：简介短版（70字）/长版（430字）/关键词/逐张截图说明/字段备忘；
  全文无"算命、占卜、预测、改运"敏感词，符合星座类目审核口径
- **APPCerts/**：发布证书材料（p12 / cer / csr / 发布 Profile p7b）
- **提审包**：`build/outputs/default/YanQinCompass-default-signed.app`
- AGC 类目：应用/生活服务/星座；开放能力全不选
- 题记修正：《禽星易见》整理稿与 app 内阅读器副本已去除"坚果云"字样（底本来源仅保留
  `02术数-146部/...` 目录路径）

## 修改记录

### 2026-09-21：自审门禁上线 + 选案清单数据分离（本次）

- **自审门禁（防硬凑写死的技术门禁）**：`.git/hooks/pre-commit`——每次 `git commit` 前自动跑
  `node --experimental-strip-types tests/run_engine_tests.mjs`（28 断言：古籍锚点 / 关系不变量 400 组 /
  性质 / 数据一致性），不过即拒绝提交。纯文档改动可 `YANQIN_SKIP_GATE=1 git commit ...` 临时跳过。
  门禁基线 2026-09-21 实测全绿。
- **三层分离纪律成文（用户 2026-09-21 定）**：新功能必须"数据（rawfile JSON，逐条注记古籍出处）/
  算法（utils 纯函数引擎）/页面（只调用引擎）"分离；新增数据先有出处再入库；测试先行（锚点用例来自
  独立知识源）；禁止为过测试特判输入。已补入「编码约定」。
- **ScriptPage 选案清单数据分离**：案件清单从页面内硬编码数组改为 `rawfile/scripts/index.json`
  （CaseMeta/CaseIndex 模型入 ScriptModels.ets，aboutToAppear 加载）——新增剧本案只改数据不改页面。
  openCase 补 loadError 重置；选案视图补加载中/错误态。编译通过（21s），真机回归待设备连接。
- 1.0.3 现状：每日占断（InputPage）/ 第二案宋太祖 / 口径页代码均就绪，versionCode 1000003；
  **release .app 尚未打包**，待真机回归（选案→两案通关、口径页、每日占断）后打包。

### 2026-09-06：古籍阅读器（免费层收官件）（本次）

- **数据**：`rawfile/classics/yanqin_tongzuan.md`（《演禽通纂》三校本 92KB）、
  `qinxing_yijian.md`（《禽星易见》四库本 52KB）——免费层内容量主力。
- **解析**：`utils/ClassicsLoader.ets`——按行解析 markdown（`##`/`###` 为章，表格行/空行略去，
  去粗体标记、引用块转正文、列表转·）；书架元数据（SHELF）内含两本。
- **页面**：`pages/ClassicReaderPage.ets`——目录视图（双书卡切换 + 章节列表）↔ 正文视图
  （标题+段落滚动阅读，A-/A+ 字号调节 14-24 且 AppStorage 持久化，底部上一章/下一章+进度）。
- **入口**：InputPage"古籍阅读 · 演禽通纂 / 禽星易见"；main_pages.json 已注册。
- **验证**：编译通过；真机验证因 USB 断开待补（装机后重点看：两书切换、章节解析完整性、字号记忆）。
- 至此免费层三件套齐：图鉴 ✓ 每日禽星 ✓ 古籍阅读器 ✓。

### 2026-09-06：启动页星空动效（方案二：宿名环+今日值日星）

- `Splash.ets` 升级为动态星空：**二十八宿名环**（28 宿名按圆周 40% 半径排布、暖金色低透明、
  `animateTo` 150 秒/圈无限线性旋转，360°=0° 无缝衔接）+ **环心今日值日星**（DayStarUtils 计算
  当日值宿，神兽图 136px 带阴影，2 秒延迟浮现动画——每天启动页都不同）+ 十颗交错闪烁星点。
- 关键实现点：装饰层全部 `hitTestBehavior(HitTestMode.None)` 保证"点击任意处进入"不受影响；
  环与值日星用 `position('50%/33%')+markAnchor` 同一定位点保证同心；底部链接行用
  `position+markAnchor` 固定底部（Stack 子组件对齐行为与预期不符时，position 定位最可靠）。
- **验证**：真机截图——宿名环环绕正确（顺时针自角起）、环心神兽与"今日值日·轸水蚓"同心浮现、
  底部链接归位。深浅模式无碍（Splash 固定深蓝夜空背景，装饰用固定暖金色）。
- ArkTS 坑同前：内联对象类型禁止（ringPos 返回值用 RingPos 接口）。

### 2026-09-06：应用图标（分层规范）+ 发布信息定稿

- **发布四项**：包名 `cn.is716652.yanqin`（原 zhongliuren 与六壬冲突，已改并重签调试证书）、
  应用名"演禽通纂"（AppScope app_name + entry EntryAbility_label 两处统一）、
  支持设备 phone、支持语言简体中文。AGC 开放能力：全部不选（纯本地应用，与隐私政策一致）。
- **图标**（按鸿蒙分层规范 + AGC 商店规范）：
  - 前景层 `foreground.png` 1024×1024：星盘印章 logo 白底转透明（235 阈值+边缘渐变），
    主体圆径约 66% 居中安全区
  - 背景层 `background.png` 1024×1024：宣纸米白 #FAF5E9（与前景白边融合），未裁圆角
  - 商店图标：`上架材料/商店图标_1024.png`（1024 PNG 584KB <3MB），合成效果与包内分层一致
  - `startIcon.png` 同步换为合成图 256
- 注意：logo 源文件 1843×1843 无透明通道；_bm dump 确认新 bundle 图标资源注册正常。
  侧载后桌面图标刷新可能滞后（重启设备出现），不影响上架。

### 2026-09-06：每日禽星（值日禽星卡）

- `utils/DayStarUtils.ets`：七元甲子值日禽星算法（锚点 1984-02-02 一元甲子起虚，420日周期、
  每元四将各15日、将星顺数当日值宿），与姐妹项目禽星盘式同源同锚点，输出可互相对照。
- `InputPage` 顶部新增"值日禽星卡"：神兽图 + 今日值日星全名（七曜色）+ 元/将标注 +
  日柱干支与化道意象（随选定日期联动——改日期即查任意日的值日星，今日显示"今日值日禽星"）。
- 支撑数据：bestiary.json（图鉴映射）、transformations.json（日柱化道），均轻量异步加载。
- **验证**：Node 已知点（锚点/次日/15日换将/60日换元）全对；真机 2026-09-06 显示
  "轸水蚓 · 一元2将 · 日柱癸未 · 化道：月窟、枯井、败林"，与 Node 基准一致。
- 注意：锚点 1984-02-02 的历书日干支为丙寅（非甲子），七元禽星为独立相位循环
  （"禽星甲子"不逐日对齐历书甲子），两 app 同锚点保证输出一致；如日后考订出其他流派相位，
  只改 DayStarUtils 一处。

### 2026-09-06：法务合规页 + 首启授权弹窗

- **法务页适配**：`pages/Legal/PrivacyPolicy.ets`、`UserAgreement.ets`（自六壬项目拷贝）重写适配——
  去除不存在的 `utils/Navigation` 依赖改用 `router`；配色令牌化（宣纸/墨/朱砂）；
  内容演禽化：APP 名改"演禽通纂"，隐私政策特别注明**出生日期仅本地演算不上传**，
  用户协议新增"内容性质与免责"条款（内容源自古籍整理、仅供传统文化研究参考、不构成现实决策依据、
  请勿迷信——命理类应用过审关键条款）与"禁止以本应用名义从事收费预测活动"行为规范。
- **首次启动授权弹窗**：`Splash.ets` 内 `@CustomDialog`——不可点外部关闭；要点摘要 +
  两协议链接 + "不同意并退出（terminateSelf）/同意并继续"。
  同意状态存本地 Preferences（`utils/LegalManager.ets`，key=legal_agreed）。
  触发：aboutToAppear 未同意自动弹 + 点 Splash 进入前复查（不可绕过）。
- **入口**：Splash 底部"《用户协议》《隐私政策》"半透明链接行（Stack 兄弟分支不穿透，
  无需 stopPropagation——ArkTS ClickEvent 也确无该方法）；InputPage 页脚免责声明下加同款链接行。
- **路由**：main_pages.json 注册 `pages/Legal/PrivacyPolicy`、`pages/Legal/UserAgreement`。
- **验证**：真机全流程——首启自动弹 ✓、弹窗内跳隐私政策页 ✓、同意并继续 ✓、点 Splash 进入 ✓、
  重启不再弹 ✓。
- **上架提醒**：协议日期 2026/09/06；AGC 商店资质里若要求隐私政策 URL，可后续挂网盘/静态页
  指向同内容。

### 2026-09-05：二十八宿图鉴页

- **数据**：`rawfile/bestiary.json`——28 宿按四象分组（东青龙/北玄武/西白虎/南朱雀），每宿含：
  天上星名、星数、分野、形性描述、昼禽/夜禽（《易见》日禽十六夜禽十二）、明禽/暗禽（《通纂》）、
  将星、元宫、合、食（吞啖）、畏、泊宫课名（约 90 条）。整理自《禽星易见》逐宿详解。
- **模型**：`model/BestiaryModels.ets`（BestiaryData/StarGroup/StarEntry/GuanMing）。
- **页面**：`pages/BestiaryPage.ets`——四象分组浏览（神兽卡 Flex wrap）+ 单宿详情浮层
  （大图 + 徽标 + 形性 + 合食畏属性表 + 泊宫课名）。入口：InputPage"二十八宿图鉴"按钮。
- **验证**：真机通过——分组卡渲染、参水猿详情（水宿/昼禽/申宫/三元甲午将星/泊寅猿啼夜月等）
  全部正常；深色模式下米黄卷轴神兽图与墨色底对比效果好。
- ArkTS 坑同前：ForEach 内联对象类型禁止，须用具名接口（GuanMing）。

### 2026-09-05：二十八星宿神兽图接入

- 素材：`规则/二十八星宿图/*.svg`（用户手绘设计，600×600，朱砂边框+米黄卷轴+工笔淡墨+楷书题款）
  → 拷贝为 `resources/base/media/{拼音}.svg`（鸿蒙资源名限小写字母数字，映射表见 `Theme.starImageRes`）。
- `Theme.ets`：新增 `starImage(star)` 星宿简称→图资源映射（28 条）。
- `ResultPage`：主星卡 84px 文字圆 → 88px 神兽图；MiniStar（胎/命/身/流年）动物字 → 56px 神兽图。
- `ScriptPage`：剧本盘面主星卡（id==='master'）加 64px 神兽图+名字。
- **渲染验证**：真机深色模式 SVG 正常（渐变/圆形牌饰/形象清晰）；`feTurbulence` 纸张噪点滤镜
  若被鸿蒙 SVG 渲染器忽略仅损失纹理不影响主体；楷体题款在低端字体环境会回退系统字体。
  若后续需要绝对保真，可批量转 PNG（Edge headless 或 cairosvg）替换，资源名不变。
- 后续可扩展：二十八宿图鉴页、剧本结局"图鉴解锁"、每日小剧场头图。

### 2026-09-05：标准命盘布局补全（星宫绑定+大运+寿宫寿星）

- **查证**：新增 `规则/演禽命盘标准布局.md`——《通纂》起例完整盘面要素清单（四柱/命宫/主星泊宫/
  胎宫胎星/命身星/寿宫寿星/大运/小限/流年月日时星/十二宫禽）+ 现代实践旁证（徐伟刚：禽盘开发
  首要难题即"主星主宫胎星胎宫"星宫成对）。结论：**有标准布局，app 此前缺星宫绑定**。
- **引擎**（YanQinEngine）：新增胎宫（年支起正月顺数生月→生日→生时，五虎遁取干）、
  寿宫（年支对冲，阳男阴女取冲前一位/阴男阳女取冲后一位）、寿星（命星起子数至寿宫，不除牛女）、
  大运序列（自主星落宫起，起运岁数水1火2木3金4土5日6月7，阳男阴女顺/阴男阳女逆，十年一运，出9运）。
- **模型**（ChartModels）：embryoPalace/shouPalace/shouStar/fortuneStartAge/fortuneList。
- **结果页**（ResultPage）：主星卡加"泊 X 宫"徽标（星宫绑定）；新增"大运"卡（3列九宫格，
  当前虚岁所在运朱砂高亮）；专业信息区补胎宫/寿宫/寿星行。
- **验证**：真机 2026-09-05 午时男（丙午年七月廿四）：主星危月燕泊庚子宫、月宿7岁起运顺行
  7庚子→87戊申、胎宫己亥、身宫己亥、寿宫辛丑、寿星箕水豹——全部与手算/Node 基准一致。
  项羽案剧本"泊乙未宫"考订链（见古籍搞文档）与此口径吻合。
- **待办更新**：十二宫禽（起十二命宫禽的加盘规则需专文考订）、小限、流月/日/时星仍为后续。

### 2026-09-05：《禽星易见》入库 + 鉴形第一案（剧本功能）

**1. 古籍入库**
- 新增 `规则/禽星易见-明-池本理.md`：四库本全文整理（约1.8万字），含七元将头、七元二十八将、
  时禽起例表（7×7曜）、番禽到将法、喜忌宫、锁泊、得地变化、二十八宿逐宿详解（元/合/食/畏/泊宫课名）、
  十五类占法。与《演禽通纂》互补：**通纂=命理演禽，易见=禽遁时占**；吞啖数据两书可互校
  （如"犴畏心毕虚柳"为项羽案学理依据）。整理凡例与"算法关联"附注见文内。
- 藏书排查结论：`02术数-146部` 内禽星专书仅两部（通纂+易见）；张果星宗/星命总括属七政四余非禽星。
- 七元日禽值日的**公历锚点本书未载，实现前须以权威通书值宿表校准**（见易见md文末附注）。

**2. 鉴形第一案（剧本玩法试水）**
设计依据：`规则/古籍搞/禽星剧本化创意-鉴形计划.md`（六壬剧本创意的禽星移植版）。
- `rawfile/scripts/case_xiangyu.json`：项羽案数据（卷宗5段、盘面6卡、眼位4个、干扰卡困惑文案、
  三层结局）。眼位全部出自《演禽通纂·鉴形赋》原注（主星泊乙未/戊戌玉坑/心月狐伏侧/氐狢丙申）。
- `model/ScriptModels.ets`：ScriptCase/ScriptBoardCard/ScriptClue/ScriptEnding 类型。
- `pages/ScriptPage.ets`：三阶段页面——卷宗呈现→观盘找眼位（点错无惩罚出"困惑"文案、
  沉思按钮出问句提示、疑点清单点亮进度）→合盘定论（神断/疑虑/天机隐三层结局+古籍原批解锁）。
- 入口：InputPage 排盘按钮下方"星官研习 · 鉴形第一案"；`main_pages.json` 已注册。
- 剧本引擎设计为通用结构（案/盘/眼位/结局 JSON schema），六壬《鉴形》卷可复用只换素材。

**注意**：剧本页盘面为剧本内嵌给定数据（古籍案例盘固定），不走 `YanQinEngine` 实时排盘。
**验证**：hdc+uitest 真机全流程通过——卷宗/起盘/干扰卡困惑（标题"摇头"）/沉思提示/四眼位
灵光一现/神断结局（4/4）/重开后天机隐（0/4）。踩坑记录：Grid 多行动态行数时 `GridItem
height('100%')` 会把行高撑爆，必须配 `rowsTemplate('1fr 1fr 1fr')` 固定行。

### 2026-09-05：结果页无限转圈修复

- **根因**：`ResultPage` 的 `isLoading`/`errorMessage` 原为普通 private 字段（非 `@State`）。ArkUI if/else 分支条件只追踪状态变量依赖，`if (this.isLoading)` 对框架不可见——数据加载完成后转圈分支永不卸载。该隐患自初版即存在，此前仅做过 Node 侧验证未上真机。
- **修复**：`isLoading` 升级为 `@State`；`loadData()` 参数解析改防御式（缺参时显示错误提示而非卡死），并补 `params`/`chart set` 运行日志。
- **验证**：hdc + uitest 真机全流程（Splash→输入→排盘）出盘正常；引擎在 Node（`--experimental-strip-types` + 真实 JSON）1ms 出图，排除算法问题。
- **调试方法备忘**：`hdc shell hilog -x` 抓 JSAPP 日志；`hdc shell uitest dumpLayout` + `uiInput click/swipe` 可无头操控真机回归。

### 2026-09-05：版式重设计 v2

**设计基调**：宣纸底 + 墨色文字 + 朱砂点缀 + 七曜功能色；颜色全部资源化（`base/element/color.json` 浅色 + `dark/element/color.json` 深色），界面跟随系统深色模式。不再在页面里硬编码十六进制色值。

| 文件 | 改动 |
|---|---|
| `resources/base|dark/element/color.json` | 新增 15 个设计令牌（paper_bg/card_bg/chip_bg/ink_*/divider/cinnabar/cinnabar_soft/elem_wood~elem_moon） |
| `utils/Theme.ets`（新） | 七曜（木金土日月火水）→ 功能色资源映射 |
| `utils/LunarFormatter.ets`（新） | 农历月日 → 中文文案 |
| `utils/ChartSummary.ets`（新） | 排盘结果 → 白话总评（明暗禽断语柔和化，依据"日值夜则凶，夜值日则贱"） |
| `utils/DataLoader.ets` | 万年历文件级静态缓存（选日期滚动不再重复解析 1.6MB JSON） |
| `model/ChartModels.ets` | `YanQinChart` 新增 `season`/`isDay` 字段 |
| `utils/YanQinEngine.ets` | 排盘结果填充 `season`/`isDay`（无算法变化，锚点例不受影响） |
| `pages/InputPage.ets` | 24 小时滚轮 → **十二时辰宫格**（标注钟点区间，选中态朱砂高亮，显示昼/夜生提示）；选日期**即时回显农历+年柱/日柱干支**；性别改选择卡；页脚免责声明 |
| `pages/ResultPage.ets` | 层级倒转：**主星大卡（五行色圆底+昼夜/季节徽标+白话总评）置顶**；胎/命/身三星小卡+推导说明；流年卡（虚岁）；吞啖/化道卡片化并注明出处；旬头/命宫/身宫收进"专业信息"折叠区；返回键由 startIcon 占位改为 `SymbolGlyph(sys.symbol.chevron_left)`；页脚免责声明 |

**行为变化**：纯表现层 + 数据加载优化，排盘算法未动。

**遗留**：Splash 仍为整图点击进入（可加"点击进入"提示）；八字/紫微类竞品常见的分享图、图鉴、古籍阅读器未做（见商业化分析）。

### 2026-09-05：构建工具链路径更新

- 构建命令统一改用 `D:\HarmonyOS\command-line-tools-6.1.1-release\bin\hvigorw.bat`（原 `D:\HarmonyOS\command-line-tools`），debug 构建验证 `BUILD SUCCESSFUL`（仅存量弃用 API 警告）
- 新增 release 构建命令（上架应用市场用），并记录 SDK 版本与 5.0 设备兼容性注意事项

### 2026-08-14：万年历接入 + 古法排盘 + 吞啖季节修正（本次）

**改动文件**：
| 文件 | 改动 |
|---|---|
| `utils/DataLoader.ets` | 新增 `loadCalendarDay(year, month, day)`：按年份选文件、按日期查当日农历/干支 |
| `utils/YanQinEngine.ets` | 全面重写：废弃"2024-01-01 基准取模"的占位算法，实现古法（旬头/三元/归子/合宿/五虎遁/五鼠遁）；吞啖增加 `fears` 方向与季节昼夜修正；化道扩展四柱；参数类型改为强类型 `CalendarDay` |
| `model/ChartModels.ets` | `YanQinChart` 增加 `xunHead`（旬头干支）、`xunStar`（旬头星）字段 |
| `pages/ResultPage.ets` | 删除 `mockCalendarDay`，改用真实万年历数据；gender 从路由参数透传（原硬编码 male，导致男女除补不生效）；星盘卡片展示旬头/命宫/身宫/旺衰/流年星（Grid 改 3 列） |

**行为变化**：
- 排盘结果此前基于假数据（固定正月十五/甲子年），现基于真实出生日期的农历与干支
- 主/胎/命/身星按古法推算，不再依赖不可靠的日期取模
- 吞啖结果可标注季节/昼夜修正（如"吉·春夏减半"、"凶·夜生不忌"）

**验证**：
- 编译：`BUILD SUCCESSFUL`（仅原有弃用 API 警告：pushUrl/getParams/getContext/back/decodeWithStream/fill）
- 逻辑：Node 脚本对原文例（辛卯年八月初八日子时男）验证通过；真实数据 2011-08-08 端到端输出自洽

## 已知限制 / 待办（按优先级）

- [ ] 闰月"男女皆不除牛女"未实现（万年历 JSON 无闰月标记字段，需生成带闰月的数据或解析推断）
- [x] 原文命宫版本矛盾（巳 vs 申）→ 2026-09 口径研究定稿取巳版，见 `规则/口径研究.md`
- [ ] `interactions.json` 的 `star` 字段（子天鼠/丑金龙…）与二十八宿为部分映射，`includes` 匹配个别组合可能漏判
- [x] 四时生旺已升级四档（旺/相/休/囚/死，seasonal_strength.json + getSeasonalStrength）
- [x] 起大运已实现（startAge 七曜数 + 命宫干阴阳×性别定顺逆）
- [x] 寿宫寿星已实现
- [x] 引擎测试已建：`tests/run_engine_tests.mjs` 28 断言 + pre-commit 门禁（2026-09-21）
- [ ] 弃用 API（router/onChange/getContext 等）未清理，SDK 26 的 `Circle.fill` 需 apiAvailable 保护
- [ ] **格局判定（上格38/下格20）**：古籍结构化 `geju.json`（逐条出处）→ `GejuEngine.ets` 纯函数 →
      测试锚点 → 命盘"入格"徽标（1.0.3 增量或 1.0.4 主内容，按三层分离纪律开发）
- [ ] 1.0.3 真机回归（选案→两案通关 / 口径页 / 每日占断）→ release .app 打包 → 提审
- [ ] 软著登记（材料基于源码与古籍整理文档，建议尽早）

## 编码约定

- **自审门禁（2026-09-21 起）**：git commit 前自动跑引擎测试（`.git/hooks/pre-commit`），不过不提交；
  数据表增改必须注记古籍出处；**禁止为过测试特判输入**（锚点用例必须来自独立知识源）
- **三层分离**：数据放 `rawfile/*.json`（逐条出处）、算法放 utils 纯函数引擎、页面只调用引擎渲染，
  禁止页面内硬编码业务数据（剧本案件清单等清单型数据同样走 JSON）
- 所有注释、字符串文案使用中文
- ArkTS 严格类型：禁止 `any`、`Record<string, Object>` 随意属性访问；引擎接口用 `Types.ets` 中定义的类型
- 新增规则数据优先放 `rawfile/*.json`（附说明文档），算法放 `YanQinEngine.ets`，避免硬编码
- 修改排盘算法前必读 `规则/演禽通纂.md` 对应原文与 `规则/algorithm_explanation.md`，并在改动处注明依据
