import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';

/** 时占高级功能商品 ID（AGC 商品管理中配置的非消耗型商品） */
const PREMIUM_PRODUCT_ID = 'premium_unlock';

/**
 * 时占权益管理（单机买断模式）
 *
 * - 已购判定：iap.queryPurchases 查华为账号云侧已购记录（每次启动/进入时占时查询），
 *   本地仅做 AppStorage 缓存减少调用；不做服务端验签（单机应用无自有服务器，
 *   云侧记录本身即凭证，伪造需账号级购买记录，残余风险可接受——取舍见 Agent.md）。
 * - 未购用户保留每日 3 次免费起盘（转化钩子）。
 * - 沙盒环境（协议未激活时）购买为模拟支付，切生产后同一代码自动真实扣款。
 */
export class Purchases {
  private static context: common.UIAbilityContext | null = null;
  private static cachedOwned: boolean | null = null;

  public static init(context: common.UIAbilityContext): void {
    Purchases.context = context;
  }

  /** 是否已解锁（先取缓存；needFresh=true 强制查云侧） */
  public static isPremium(): boolean {
    if (Purchases.cachedOwned !== null) {
      return Purchases.cachedOwned;
    }
    return AppStorage.get<boolean>('shizhanPremium') ?? false;
  }

  /** 查询华为账号已购记录，刷新本地缓存 */
  public static async refreshOwned(): Promise<boolean> {
    const ctx = Purchases.context;
    if (ctx === null) {
      return Purchases.isPremium();
    }
    try {
      await iap.queryEnvironmentStatus(ctx);   // 环境不可用（未开通/未登录）→ 走免费额度
      const param: iap.QueryPurchasesParameter = {
        productType: iap.ProductType.NONCONSUMABLE,
        queryType: iap.PurchaseQueryType.ALL
      };
      const result = await iap.queryPurchases(ctx, param);
      let owned = false;
      for (const signed of result.purchaseDataList) {
        try {
          const data = JSON.parse(signed) as InAppPurchaseData;
          if (data.productId === PREMIUM_PRODUCT_ID) {
            owned = true;
            break;
          }
        } catch (e) {
          // 单条解析失败不影响其余
        }
      }
      Purchases.cachedOwned = owned;
      AppStorage.setOrCreate<boolean>('shizhanPremium', owned);
      return owned;
    } catch (err) {
      const e = err as Error;
      console.warn('[Purchases] queryPurchases failed (按未购处理):', e.message);
      // 查询失败≠未购：保留既有缓存值，避免网络抖动把已购用户降级
      return Purchases.isPremium();
    }
  }

  /** 查询商品信息（付费墙展示价格），失败返回 null（付费墙降级显示固定文案） */
  public static async queryProduct(): Promise<iap.Product | null> {
    const ctx = Purchases.context;
    if (ctx === null) {
      return null;
    }
    try {
      const products = await iap.queryProducts(ctx, [PREMIUM_PRODUCT_ID]);
      return products.length > 0 ? products[0] : null;
    } catch (err) {
      const e = err as Error;
      console.warn('[Purchases] queryProducts failed:', e.message);
      return null;
    }
  }

  /** 发起购买；返回是否成功解锁（用户取消/失败返回 false，文案由调用方给） */
  public static async purchase(): Promise<boolean> {
    const ctx = Purchases.context;
    if (ctx === null) {
      return false;
    }
    const parameter: iap.PurchaseParameter = {
      productId: PREMIUM_PRODUCT_ID,
      productType: iap.ProductType.NONCONSUMABLE
    };
    try {
      const result = await iap.createPurchase(ctx, parameter);
      try {
        const data = JSON.parse(result.purchaseData) as InAppPurchaseData;
        if (data.productId === PREMIUM_PRODUCT_ID) {
          Purchases.cachedOwned = true;
          AppStorage.setOrCreate<boolean>('shizhanPremium', true);
          return true;
        }
        return false;
      } catch (e) {
        console.error('[Purchases] purchaseData 解析失败:', e);
        return false;
      }
    } catch (err) {
      const e = err as Error;
      console.warn('[Purchases] purchase failed:', e.message);
      return false;
    }
  }

  /** 解锁状态变化由系统回调（非本类事件流）；供购买后立即复核 */
  public static async verifyAfterPurchase(): Promise<boolean> {
    return await Purchases.refreshOwned();
  }

  /** 测试辅助：清除本地缓存（不影响云侧真实已购） */
  public static resetCacheForTest(): void {
    Purchases.cachedOwned = null;
  }
}

/** 购买数据（purchaseData JSON 解析后所需字段；完整定义见 IAP 文档） */
interface InAppPurchaseData {
  productId: string;
  productType?: number;
  purchaseToken?: string;
  purchaseTime?: number;
}
