import {
  createArkWebEngine,
  WebDialogResult,
  WebDialogType,
  WebNavigationDecision,
  WebPermissionDecision,
  WebPopupDecision,
  WebSessionHost,
  WebSessionOptions,
  type WebDialogRequest,
  type WebDownloadDecision,
  type WebDownloadRequest,
  type WebFileChooserRequest,
  type WebFileChooserResult,
  type WebPermissionRequest,
  type WebPopupRequest,
  type WebSession,
  type WebSessionObserver,
  type WebSessionRequestHandler,
  type WebNavigationRequest,
  type WebDownloadEvent,
  type WebBridgeMessage,
  type WebEngineHealthEvent,
  type WebSessionError,
  type WebSessionState
} from 'web-engine';

class DemoObserver implements WebSessionObserver {
  onStateChanged(session: WebSession, state: WebSessionState): void {
    void session;
    void state;
  }

  onDownloadEvent(session: WebSession, event: WebDownloadEvent): void {
    void session;
    void event;
  }

  onBridgeMessage(session: WebSession, message: WebBridgeMessage): void {
    void session;
    void message;
  }

  onEngineHealthEvent(session: WebSession, event: WebEngineHealthEvent): void {
    void session;
    void event;
  }

  onSessionError(session: WebSession, error: WebSessionError): void {
    void session;
    void error;
  }
}

class DemoRequestHandler implements WebSessionRequestHandler {
  async onNavigationRequest(session: WebSession, request: WebNavigationRequest): Promise<WebNavigationDecision> {
    void session;
    return request.url.startsWith('http') ? WebNavigationDecision.ALLOW : WebNavigationDecision.CANCEL;
  }

  async onPermissionRequest(session: WebSession, request: WebPermissionRequest): Promise<WebPermissionDecision> {
    void session;
    void request;
    return WebPermissionDecision.DENY;
  }

  async onDialogRequest(session: WebSession, request: WebDialogRequest): Promise<WebDialogResult> {
    void session;
    const result = new WebDialogResult();
    result.confirmed = request.type === WebDialogType.ALERT;
    result.promptValue = request.defaultValue;
    return result;
  }

  async onPopupRequest(session: WebSession, request: WebPopupRequest): Promise<WebPopupDecision> {
    void session;
    void request;
    return WebPopupDecision.REJECT;
  }

  async onFileChooserRequest(session: WebSession, request: WebFileChooserRequest): Promise<WebFileChooserResult> {
    void session;
    void request;
    const result = new WebFileChooserResult();
    result.useDefaultChooser = true;
    return result;
  }

  async onDownloadRequest(session: WebSession, request: WebDownloadRequest): Promise<WebDownloadDecision> {
    void session;
    void request;
    return { type: 0, destinationUri: '' } as WebDownloadDecision;
  }
}

@Entry
@Component
struct Index {
  private readonly engine = createArkWebEngine();
  private readonly options = new WebSessionOptions();
  private readonly observer = new DemoObserver();
  private readonly requestHandler = new DemoRequestHandler();
  private readonly session: WebSession;

  constructor() {
    this.options.initialUrl = 'https://www.example.com';
    this.session = this.engine.createSession(this.options);
    this.session.addObserver(this.observer);
    this.session.setRequestHandler(this.requestHandler);
  }

  build() {
    Column() {
      WebSessionHost({ session: this.session })
    }
    .height('100%')
    .width('100%')
  }
}
