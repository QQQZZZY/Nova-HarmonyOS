import { webview } from '@kit.ArkWeb';
import { WebBridgeConfig } from '../public/types/WebBridgeTypes';
import { buildBridgePermissionJson } from '../policy/BridgePolicy';

export class ArkWebJsBridgeAdapter {
  private registeredNames: Array<string> = [];

  apply(controller: webview.WebviewController, bridgeObject: object, config: WebBridgeConfig): void {
    this.clear(controller);
    config.definitions.forEach((definition) => {
      const syncMethods = definition.methods.filter((method) => method.sync).map((method) => method.name);
      const asyncMethods = definition.methods.filter((method) => !method.sync).map((method) => method.name);
      controller.registerJavaScriptProxy(
        bridgeObject,
        definition.name,
        syncMethods,
        asyncMethods,
        buildBridgePermissionJson(definition)
      );
      this.registeredNames.push(definition.name);
    });
  }

  clear(controller: webview.WebviewController): void {
    this.registeredNames.forEach((name) => {
      controller.deleteJavaScriptRegister(name);
    });
    this.registeredNames = [];
  }
}
