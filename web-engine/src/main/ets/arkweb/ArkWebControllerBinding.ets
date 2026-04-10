import { webview } from '@kit.ArkWeb';

export class ArkWebControllerBinding {
  readonly controller: webview.WebviewController = new webview.WebviewController();
  private attached: boolean = false;

  observeAttachStateChange(listener: (attached: boolean) => void): void {
    this.controller.on('controllerAttachStateChange', (state: webview.ControllerAttachState) => {
      const attached = state === webview.ControllerAttachState.ATTACHED;
      this.attached = attached;
      listener(attached);
    });
  }

  markAttached(): void {
    this.attached = true;
  }

  markDetached(): void {
    this.attached = false;
  }

  isAttached(): boolean {
    try {
      return this.controller.getAttachState() === webview.ControllerAttachState.ATTACHED;
    } catch (_error) {
      return this.attached;
    }
  }

  getCurrentUrl(): string | null {
    try {
      return this.controller.getUrl();
    } catch (_error) {
      return null;
    }
  }

  getTitle(): string {
    try {
      return this.controller.getTitle();
    } catch (_error) {
      return '';
    }
  }

  canGoBack(): boolean {
    try {
      return this.controller.accessBackward();
    } catch (_error) {
      return false;
    }
  }

  canGoForward(): boolean {
    try {
      return this.controller.accessForward();
    } catch (_error) {
      return false;
    }
  }
}
