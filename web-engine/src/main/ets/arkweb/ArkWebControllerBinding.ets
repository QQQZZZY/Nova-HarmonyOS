import { webview } from '@kit.ArkWeb';

export class ArkWebControllerBinding {
  controller: webview.WebviewController = new webview.WebviewController();
  attached: boolean = false;

  markAttached(): void {
    this.attached = true;
  }
}
