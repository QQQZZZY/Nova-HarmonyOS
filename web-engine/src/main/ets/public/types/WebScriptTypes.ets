export class WebScriptRegistration {
  id: string = '';
  name: string = '';
  sessionScoped: boolean = true;
}

export class WebLoadOptions {
  additionalHttpHeaders: Array<WebLoadHeader> = [];
}

export class WebLoadHeader {
  name: string = '';
  value: string = '';
}

export class WebMessage {
  channel: string = '';
  payload: string = '';
}

export type ScriptValue = string | null;
