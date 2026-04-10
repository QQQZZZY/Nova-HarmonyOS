import {
  WebDialogResult,
  WebDialogType,
  WebNavigationDecision,
  WebPermissionDecision,
  WebPopupDecision,
  WebSessionHost,
  WebSessionOptions,
  WebFileChooserResult,
  type WebDialogRequest,
  type WebDownloadDecision,
  type WebDownloadRequest,
  type WebFileChooserRequest,
  type WebPermissionRequest,
  type WebPopupRequest,
  type WebSession,
  type WebSessionObserver,
  type WebSessionRequestHandler,
  type WebNavigationRequest,
  type WebDownloadEvent,
  type WebSessionError,
  type WebSessionState
} from 'web-engine';
import { appWebEngine } from '../entryability/EntryAbility';

class DemoObserver implements WebSessionObserver {
  onStateChanged(session: WebSession, state: WebSessionState): void {
    void session;
    void state;
  }

  onDownloadEvent(session: WebSession, event: WebDownloadEvent): void {
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

const demoEngine = appWebEngine;
const demoObserver = new DemoObserver();
const demoRequestHandler = new DemoRequestHandler();
const dataManager = demoEngine.getDataManager();
void dataManager;

function createDemoSession(): WebSession {
  const options = new WebSessionOptions();
  options.initialUrl = 'https://www.example.com';
  const session = demoEngine.createSession(options);
  session.bindObserver(demoObserver);
  session.bindRequestHandler(demoRequestHandler);
  return session;
}

@Entry
@Component
struct Index {
  private readonly session: WebSession = createDemoSession();

  build() {
    Column() {
      WebSessionHost({ session: this.session })
    }
    .height('100%')
    .width('100%')
  }
}
