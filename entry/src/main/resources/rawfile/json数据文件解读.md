# 演禽通 - JSON数据文件解读

## 项目概述



## 项目结构

```
ZHONGLUREN/
├── AppScope/                          # 应用级配置
│   ├── resources/base/
│   │   ├── element/string.json        # 应用名称：演禽通
│   │   └── media/yanqin_tong_logo_classical.png # 应用图标
│   └── app.json5
├── entry/
│   └── resources/
│       ├── base/media/
│       │   └── hetu_luoshu_logo.png   # Logo图片
│       └── rawfile/
│           ├── calendar/              # 万年历数据（17个JSON）
│           ├── animals.json           # 三十六禽数据
│           ├── interactions.json      # 吞啖关系数据
│           ├── transformations.json   # 化道环境数据
│           └── seasonal_strength.json # 四时生旺数据
└── hvigor/                            # 构建配置
```


## 1. 万年历数据

### 数据范围
- **时间跨度**：1900年 - 2061年（162年）
- **文件数量**：17个JSON文件
- **存储路径**：`entry/src/main/resources/rawfile/calendar/`
- **单文件大小**：约 1.6MB（最后一个文件约 167KB，仅含2年数据）

### 文件命名规则
| 文件名 | 年份范围 |
|--------|----------|
| calendar_data_0001.json | 1900-1909 |
| calendar_data_0002.json | 1910-1919 |
| ... | ... |
| calendar_data_0017.json | 2060-2061 |

### 文件选择逻辑

根据用户输入的公历年份，计算对应的文件编号：

```typescript
function getFileIndex(year: number): string {
  const index = Math.floor((year - 1900) / 10) + 1;
  return index.toString().padStart(4, '0');
}
```

### 数据结构

每条记录代表一天的完整信息：

```json
{
  "date": "2060-02-04",
  "year": 2060,
  "month": 2,
  "day": 4,
  "lunar_year": 2060,
  "lunar_month": 1,
  "lunar_day": 3,
  "zodiac": "龙",
  "year_gan": "庚",
  "year_zhi": "辰",
  "month_gan": "戊",
  "month_zhi": "寅",
  "day_gan": "丁",
  "day_zhi": "未",
  "week_day": 2,
  "week_name": "星期三",
  "is_holiday": 0,
  "holiday_name": "",
  "solar_term": "立春",
  "festivals": ""
}
```

---

## 2. 三十六禽体系 (Animals)

### 数据源
- **文件路径**: `entry/src/main/resources/rawfile/animals.json`
- **规则文档**: `规则/animals_explanation.md`

### 核心内容
建立了“二十八星宿”与“三十六种动物”的完整映射关系，是演禽术数的基础数据。

### 数据结构
```json
[
  {
    "star": "角",           // 星宿简称
    "full_name": "角木蛟",  // 星宿全称
    "element": "木",        // 七曜属性（木金土日月火水）
    "animal": "蛟",         // 核心动物
    "variations": ["蛇父"], // 变体/别名
    "note": ""             // 备注（如“明禽”、“暗禽”）
  },
  ...
]
```

### 关键字段说明
- **element**: 决定了禽星的基本生克属性。
- **note**: 标记“明禽”或“暗禽”，用于结合昼夜时间判断禽星强弱（日值夜则凶，夜值日则贱）。

---

## 3. 化道环境 (Transformations)

### 数据源
- **文件路径**: `entry/src/main/resources/rawfile/transformations.json`
- **规则文档**: `规则/huadao_explanation.md`

### 核心内容
描述了禽星所处的**环境状态**（化道）。基于六十甲子、天干、地支来模拟自然环境（如山林、江河、刀砧），用于判断禽星是“得地”（吉）还是“受制”（凶）。

### 数据结构
```json
{
  "jiazi_map": {
    "甲子": ["水草", "鼠穴", ...], // 六十甲子具体意象
    "丙寅": ["焚山", "火窑", ...]
  },
  "stem_map": {
    "甲": ["山林"],               // 天干通用意象
    ...
  },
  "branch_map": {
    "寅": ["山林", "平林"],       // 地支通用意象
    ...
  }
}
```

### 应用逻辑
系统需根据计算出的流年/流月/流日干支，从表中检索对应的环境描述，再结合禽星习性判断吉凶。
> 例：虎（禽星）入丙寅（焚山），虽得寅木之利，但遭丙火焚烧，主凶。

---

## 4. 吞啖关系 (Interactions)

### 数据源
- **文件路径**: `entry/src/main/resources/rawfile/interactions.json`
- **规则文档**: `规则/tundan_explanation.md`

### 核心内容
演禽术数的核心吉凶判断逻辑——**“吞啖”**（即捕食关系）。基于自然界食物链法则，定义了星宿之间的克制关系。

### 数据结构
```json
{
  "relationships": [
    {
      "star": "子天鼠",             // 主体星宿
      "eats": ["蝠", "燕", ...],    // 可吞食（克制）的对象 -> 吉
      "fears": ["蛇", "猫", ...],   // 被吞食（畏惧）的对象 -> 凶
      "source_text": "子天鼠...",   // 原文依据
      "note": "凶星不忌"            // 特殊修正条件
    },
    ...
  ],
  "verse_rules": [ ... ]            // 基于口诀的补充规则
}
```

### 判定规则
1.  **强克弱（吉）**：主星 `eats` 流年星。
2.  **弱被强克（凶）**：主星 `fears` 流年星（即流年星 `eats` 主星）。
3.  **特殊修正**：需结合 `note` 中的条件（如“春夏减半”、“夜生不忌”）进行最终判定。

---

## 5. 四时生旺与排盘算法 (New)

### 数据源
- **文件路径**: `entry/src/main/resources/rawfile/seasonal_strength.json`
- **规则文档**: `规则/algorithm_explanation.md`

### 核心内容
补充了星宿在四季的旺衰规则，以及演禽核心排盘算法（起主星、胎星、命宫、身宫等）。

### 数据结构 (Seasonal Strength)
```json
{
  "spring": ["角", "亢", "轸", ...], // 春季旺星
  "summer": ["房", "柳", "张", ...], // 夏季旺星
  "autumn": ["尾", "井", "参", ...], // 秋季旺星
  "winter": ["奎", "娄", "毕", ...]  // 冬季旺星
}
```

### 排盘逻辑
详细算法见 `algorithm_explanation.md`，涵盖了从生辰八字推导整个星盘的数学模型。
