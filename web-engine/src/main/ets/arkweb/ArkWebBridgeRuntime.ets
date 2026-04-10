import { WebScriptRegistration } from '../public/types/WebScriptTypes';

export class ArkWebBridgeRuntime {
  createRegistration(name: string, sessionScoped: boolean): WebScriptRegistration {
    const registration = new WebScriptRegistration();
    registration.id = `${name}-registration`;
    registration.name = name;
    registration.sessionScoped = sessionScoped;
    return registration;
  }
}
