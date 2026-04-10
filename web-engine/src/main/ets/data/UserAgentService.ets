import { webview } from '@kit.ArkWeb';

export class UserAgentService {
  setAppCustomUserAgent(userAgent: string): void {
    try {
      webview.WebviewController.setAppCustomUserAgent(userAgent);
    } catch (_error) {
    }
  }

  setUserAgentForHosts(userAgent: string, hosts: Array<string>): void {
    try {
      webview.WebviewController.setUserAgentForHosts(userAgent, hosts);
    } catch (_error) {
    }
  }
}
