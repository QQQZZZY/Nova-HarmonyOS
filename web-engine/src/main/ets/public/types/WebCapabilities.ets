export class WebEngineCapabilities {
  supportsMultipleSessions: boolean = true;
  supportsGlobalUserAgentOverride: boolean = true;
  supportsHostUserAgentOverride: boolean = true;
}

export class WebSessionCapabilities {
  supportsJavaScriptBridge: boolean = true;
  supportsFileChooser: boolean = true;
  supportsDownloadControl: boolean = true;
  supportsDownloadResume: boolean = true;
  supportsStateRestore: boolean = false;
  supportsFindInPage: boolean = false;
}

export function createDefaultSessionCapabilities(): WebSessionCapabilities {
  return new WebSessionCapabilities();
}
