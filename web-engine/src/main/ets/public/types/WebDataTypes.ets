export enum WebDataScope {
  CURRENT_MODE,
  PRIVATE_ONLY,
  NORMAL_ONLY,
  BOTH
}

export class WebDataClearOptions {
  clearCookies: boolean = false;
  clearWebStorage: boolean = false;
  clearMemoryCache: boolean = false;
  clearDiskCache: boolean = false;
  clearSslState: boolean = false;
  clearClientAuthState: boolean = false;
  target: WebDataScope = WebDataScope.CURRENT_MODE;
}
