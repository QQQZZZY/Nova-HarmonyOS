import { webview } from '@kit.ArkWeb';
import { WebDataClearOptions, WebDataScope } from '../public/types/WebDataTypes';

export class WebDataClearPlan {
  clearCookies: boolean = false;
  clearWebStorage: boolean = false;
  clearCache: boolean = false;
  clearRom: boolean = false;
  clearSslState: boolean = false;
  clearClientAuthState: boolean = false;
  privateMode: boolean = false;
  bothModes: boolean = false;
}

export function mapDataClearPlan(options: WebDataClearOptions): WebDataClearPlan {
  const plan = new WebDataClearPlan();
  plan.clearCookies = options.clearCookies;
  plan.clearWebStorage = options.clearWebStorage;
  plan.clearCache = options.clearMemoryCache || options.clearDiskCache;
  plan.clearRom = options.clearDiskCache;
  plan.clearSslState = options.clearSslState;
  plan.clearClientAuthState = options.clearClientAuthState;
  plan.privateMode = options.target === WebDataScope.PRIVATE_ONLY;
  plan.bothModes = options.target === WebDataScope.BOTH;
  return plan;
}

export class WebDataService {
  clear(options: WebDataClearOptions, clearCacheAction: ((clearRom: boolean) => void) | null = null): void {
    const plan = mapDataClearPlan(options);
    if (plan.clearCookies) {
      if (plan.bothModes) {
        webview.WebCookieManager.clearAllCookiesSync(true);
        webview.WebCookieManager.clearAllCookiesSync(false);
      } else {
        webview.WebCookieManager.clearAllCookiesSync(plan.privateMode);
      }
    }
    if (plan.clearWebStorage) {
      if (plan.bothModes) {
        webview.WebStorage.deleteAllData(true);
        webview.WebStorage.deleteAllData(false);
      } else {
        webview.WebStorage.deleteAllData(plan.privateMode);
      }
    }
    if (plan.clearCache && clearCacheAction !== null) {
      clearCacheAction(plan.clearRom);
    }
  }
}
