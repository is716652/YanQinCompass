import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

/**
 * 法务协议状态管理：记录用户是否已同意《用户协议》与《隐私政策》。
 * 仅本地存储（鸿蒙 Preferences），不涉及任何网络。
 */
export class LegalManager {
  private static readonly STORE: string = 'legal_store';
  private static readonly KEY: string = 'legal_agreed';

  /** 是否已同意（首次启动为 false，用于触发授权弹窗） */
  static async hasAgreed(context: common.UIAbilityContext): Promise<boolean> {
    const pref = await preferences.getPreferences(context, LegalManager.STORE);
    const val = pref.getSync(LegalManager.KEY, false) as boolean;
    return val;
  }

  /** 记录"同意并继续" */
  static async setAgreed(context: common.UIAbilityContext): Promise<void> {
    const pref = await preferences.getPreferences(context, LegalManager.STORE);
    await pref.put(LegalManager.KEY, true);
    await pref.flush();
  }
}
