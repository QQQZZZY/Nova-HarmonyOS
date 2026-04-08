export class WebBridgePermissionRule {
  scheme: string = '';
  host: string = '';
  port: string = '';
  path: string = '';
}

export class WebBridgeMethod {
  name: string = '';
  sync: boolean = true;
  rules: Array<WebBridgePermissionRule> = [];
}

export class WebBridgeDefinition {
  name: string = '';
  methods: Array<WebBridgeMethod> = [];
  objectRules: Array<WebBridgePermissionRule> = [];
}

export class WebBridgeConfig {
  definitions: Array<WebBridgeDefinition> = [];
}

export class WebBridgeMessage {
  channel: string = '';
  name: string = '';
  payload: string = '';
  sourceUrl: string = '';
  frameUrl: string = '';
}
