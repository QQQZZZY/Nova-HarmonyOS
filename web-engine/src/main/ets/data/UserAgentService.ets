import { webview } from '@kit.ArkWeb';

export class UserAgentService {
  setAppCustomUserAgent(userAgent: string): void {
    webview.WebviewController.setAppCustomUserAgent(userAgent);
  }

  setUserAgentForHosts(userAgent: string, hosts: Array<string>): void {
    webview.WebviewController.setUserAgentForHosts(userAgent, hosts);
  }
}
