import { webview } from '@kit.ArkWeb';

export class CookieService {
  getCookies(url: string, isPrivate: boolean): string {
    try {
      return webview.WebCookieManager.fetchCookieSync(url, isPrivate);
    } catch (_error) {
      return '';
    }
  }

  setCookie(url: string, value: string, isPrivate: boolean): void {
    try {
      webview.WebCookieManager.configCookieSync(url, value, isPrivate);
      webview.WebCookieManager.saveCookieSync();
    } catch (_error) {
    }
  }
}
