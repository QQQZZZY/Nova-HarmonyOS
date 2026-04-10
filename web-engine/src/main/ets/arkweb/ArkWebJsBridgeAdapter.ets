import { webview } from '@kit.ArkWeb';
import { WebBridgeConfig } from '../public/types/WebBridgeTypes';
import { WebScriptRegistration } from '../public/types/WebScriptTypes';
import { buildBridgePermissionJson } from '../policy/BridgePolicy';
import { ArkWebBridgeRuntime } from './ArkWebBridgeRuntime';

export class ArkWebJsBridgeAdapter {
  private readonly runtime: ArkWebBridgeRuntime;
  private registeredNames: Array<string> = [];

  constructor(runtime: ArkWebBridgeRuntime = new ArkWebBridgeRuntime()) {
    this.runtime = runtime;
  }

  apply(controller: webview.WebviewController, bridgeObject: object, config: WebBridgeConfig): Array<WebScriptRegistration> {
    this.clear(controller);
    const registrations: Array<WebScriptRegistration> = [];
    config.definitions.forEach((definition) => {
      const syncMethods = definition.methods.filter((method) => method.sync).map((method) => method.name);
      const asyncMethods = definition.methods.filter((method) => !method.sync).map((method) => method.name);
      try {
        controller.registerJavaScriptProxy(
          bridgeObject,
          definition.name,
          syncMethods,
          asyncMethods,
          buildBridgePermissionJson(definition)
        );
        this.registeredNames.push(definition.name);
        registrations.push(this.runtime.createRegistration(definition.name, true));
      } catch (_error) {
      }
    });
    return registrations;
  }

  remove(controller: webview.WebviewController, registration: WebScriptRegistration): void {
    try {
      controller.deleteJavaScriptRegister(registration.name);
    } catch (_error) {
    }
    this.registeredNames = this.registeredNames.filter((name) => name !== registration.name);
  }

  clear(controller: webview.WebviewController): void {
    this.registeredNames.forEach((name) => {
      try {
        controller.deleteJavaScriptRegister(name);
      } catch (_error) {
      }
    });
    this.registeredNames = [];
  }
}
