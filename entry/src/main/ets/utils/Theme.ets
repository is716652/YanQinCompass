/**
 * 设计基调令牌：宣纸底 + 墨色文字 + 朱砂点缀 + 七曜功能色。
 * 颜色资源定义于 resources/base/element/color.json（浅色）与
 * resources/dark/element/color.json（深色），本类做七曜→色资源、星宿→神兽图的映射。
 */
export class Theme {
  private static readonly elemRes: Record<string, Resource> = {
    "木": $r('app.color.elem_wood'),
    "火": $r('app.color.elem_fire'),
    "土": $r('app.color.elem_earth'),
    "金": $r('app.color.elem_metal'),
    "水": $r('app.color.elem_water'),
    "日": $r('app.color.elem_sun'),
    "月": $r('app.color.elem_moon')
  };

  // 二十八宿神兽图（resources/base/media/*.svg，源自 规则/二十八星宿图，资源名为拼音）
  private static readonly starImageRes: Record<string, Resource> = {
    "角": $r('app.media.jiaomujiao'), "亢": $r('app.media.kangjinlong'),
    "氐": $r('app.media.ditumo'), "房": $r('app.media.fangritu'),
    "心": $r('app.media.xinyuehu'), "尾": $r('app.media.weihuhu'),
    "箕": $r('app.media.jishuibao'), "斗": $r('app.media.doumuxie'),
    "牛": $r('app.media.niujinniu'), "女": $r('app.media.nvutfu'),
    "虚": $r('app.media.xurishu'), "危": $r('app.media.weiyueyan'),
    "室": $r('app.media.shihuoju'), "壁": $r('app.media.bishuiyu'),
    "奎": $r('app.media.kuimulang'), "娄": $r('app.media.loujingou'),
    "胃": $r('app.media.weitudi'), "昴": $r('app.media.maoriji'),
    "毕": $r('app.media.biyuewu'), "觜": $r('app.media.zihuohou'),
    "参": $r('app.media.shenshuiyuan'), "井": $r('app.media.jingmuan'),
    "鬼": $r('app.media.guijinyang'), "柳": $r('app.media.liutuzhang'),
    "星": $r('app.media.xingrima'), "张": $r('app.media.zhangyuelu'),
    "翼": $r('app.media.yihuoshe'), "轸": $r('app.media.zhenshuiyin')
  };

  /** 七曜（木金土日月火水）→ 功能色资源；未匹配时回落墨色次级 */
  static elemColor(element: string): Resource {
    const res: Resource = Theme.elemRes[element];
    return res ?? $r('app.color.ink_secondary');
  }

  /** 星宿简称 → 神兽图资源；未匹配返回空 Resource 不可用，调用方需先保证 star 合法 */
  static starImage(star: string): Resource {
    return Theme.starImageRes[star];
  }
}
