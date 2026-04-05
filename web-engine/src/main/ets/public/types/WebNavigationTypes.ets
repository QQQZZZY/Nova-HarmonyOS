export enum WebNavigationDecision {
  ALLOW,
  CANCEL
}

export class WebNavigationRequest {
  url: string = '';
  isMainFrame: boolean = true;
  method: string = 'GET';
}
