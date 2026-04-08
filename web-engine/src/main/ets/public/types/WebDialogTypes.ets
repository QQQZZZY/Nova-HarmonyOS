export enum WebDialogType {
  ALERT,
  CONFIRM,
  PROMPT,
  BEFORE_UNLOAD
}

export class WebDialogRequest {
  type: WebDialogType = WebDialogType.ALERT;
  message: string = '';
  defaultValue: string = '';
  sourceUrl: string = '';
}

export class WebDialogResult {
  confirmed: boolean = false;
  promptValue: string = '';
}
