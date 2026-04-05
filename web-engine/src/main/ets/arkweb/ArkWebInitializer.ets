import { webview } from '@kit.ArkWeb';

let initialized: boolean = false;

export function ensureArkWebInitialized(): void {
  if (initialized) {
    return;
  }
  webview.WebviewController.initializeWebEngine();
  initialized = true;
}
