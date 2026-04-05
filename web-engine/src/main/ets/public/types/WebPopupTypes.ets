export enum WebPopupDecision {
  OPEN_IN_FOREGROUND_TAB,
  OPEN_IN_BACKGROUND_TAB,
  REJECT
}

export class WebPopupRequest {
  targetUrl: string = '';
  sourceUrl: string = '';
  isUserGesture: boolean = false;
}
