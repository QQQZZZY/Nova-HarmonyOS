import { WebBridgeDefinition, WebBridgePermissionRule } from '../public/types/WebBridgeTypes';

class BridgePermissionEntry {
  scheme: string = '';
  host: string = '';
  port: string = '';
  path: string = '';
}

class BridgeMethodPermissionEntry {
  methodName: string = '';
  urlPermissionList: Array<BridgePermissionEntry> = [];
}

class JavaScriptProxyPermission {
  urlPermissionList: Array<BridgePermissionEntry> = [];
  methodList: Array<BridgeMethodPermissionEntry> = [];
}

class BridgePermissionEnvelope {
  javascriptProxyPermission: JavaScriptProxyPermission = new JavaScriptProxyPermission();
}

function toPermissionEntry(rule: WebBridgePermissionRule): BridgePermissionEntry {
  const entry = new BridgePermissionEntry();
  entry.scheme = rule.scheme;
  entry.host = rule.host;
  entry.port = rule.port;
  entry.path = rule.path;
  return entry;
}

export function buildBridgePermissionJson(definition: WebBridgeDefinition): string {
  const envelope = new BridgePermissionEnvelope();
  envelope.javascriptProxyPermission.urlPermissionList = definition.objectRules.map(toPermissionEntry);
  envelope.javascriptProxyPermission.methodList = definition.methods.map((method) => {
    const methodEntry = new BridgeMethodPermissionEntry();
    methodEntry.methodName = method.name;
    methodEntry.urlPermissionList = method.rules.map(toPermissionEntry);
    return methodEntry;
  });
  return JSON.stringify(envelope);
}
