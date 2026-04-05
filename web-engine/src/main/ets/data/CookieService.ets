import { webview } from '@kit.ArkWeb';

export class CookieService {
  getCookies(url: string, isPrivate: boolean): string {
    return webview.WebCookieManager.fetchCookieSync(url, isPrivate);
  }

  setCookie(url: string, value: string, isPrivate: boolean): void {
    webview.WebCookieManager.configCookieSync(url, value, isPrivate);
    webview.WebCookieManager.saveCookieSync();
  }
}
