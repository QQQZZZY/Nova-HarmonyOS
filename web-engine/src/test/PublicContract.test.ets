import { describe, it, expect } from '@ohos/hypium';
import {
  createArkWebEngine,
  WebDataClearOptions,
  WebEngineCapabilities,
  WebFileChooserResult,
  WebLoadOptions,
  WebMessage,
  WebNavigationDecision,
  WebNavigationState,
  WebPageMetadata,
  WebPermissionDecision,
  WebPopupDecision,
  WebScriptRegistration,
  WebDialogResult,
  WebSessionOptions,
  type ScriptValue,
  type WebBridgeMessage,
  type WebDataManager,
  type WebDialogRequest,
  type WebDownloadDecision,
  type WebDownloadEvent,
  type WebDownloadRequest,
  type WebEngineHealthEvent,
  type WebFileChooserRequest,
  type WebNavigationRequest,
  type WebPermissionRequest,
  type WebPopupRequest,
  type WebSession,
  type WebSessionError,
  type WebSessionObserver,
  type WebSessionRequestHandler,
  type WebSessionState
} from '../../Index';

class ContractObserver implements WebSessionObserver {
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

class ContractRequestHandler implements WebSessionRequestHandler {
  async onNavigationRequest(session: WebSession, request: WebNavigationRequest): Promise<WebNavigationDecision> {
    void session;
    void request;
    return WebNavigationDecision.ALLOW;
  }

  async onPermissionRequest(session: WebSession, request: WebPermissionRequest): Promise<WebPermissionDecision> {
    void session;
    void request;
    return WebPermissionDecision.DENY;
  }

  async onDialogRequest(session: WebSession, request: WebDialogRequest): Promise<WebDialogResult> {
    void session;
    void request;
    return new WebDialogResult();
  }

  async onPopupRequest(session: WebSession, request: WebPopupRequest): Promise<WebPopupDecision> {
    void session;
    void request;
    return WebPopupDecision.REJECT;
  }

  async onFileChooserRequest(session: WebSession, request: WebFileChooserRequest): Promise<WebFileChooserResult> {
    void session;
    void request;
    return new WebFileChooserResult();
  }

  async onDownloadRequest(session: WebSession, request: WebDownloadRequest): Promise<WebDownloadDecision> {
    void session;
    void request;
    return { type: 0, destinationUri: '' } as WebDownloadDecision;
  }
}

export default function publicContractTest() {
  describe('PublicContract', () => {
    it('should expose stable value types for navigation metadata and script registration', 0, () => {
      const navigation = new WebNavigationState();
      const metadata = new WebPageMetadata();
      const registration = new WebScriptRegistration();
      const capabilities = new WebEngineCapabilities();
      const engine = createArkWebEngine();
      const sessionOptions = new WebSessionOptions();
      const clearOptions = new WebDataClearOptions();
      const loadOptions = new WebLoadOptions();
      const message = new WebMessage();
      const session = engine.createSession(sessionOptions);
      const observer: WebSessionObserver = new ContractObserver();
      const requestHandler: WebSessionRequestHandler = new ContractRequestHandler();
      const dataManager: WebDataManager = engine.getDataManager();
      const clearDataPromise: Promise<void> = engine.clearData(clearOptions);
      const dataManagerClearPromise: Promise<void> = dataManager.clear(clearOptions);
      const loadWithoutOptionsPromise: Promise<void> = session.loadUrl('https://example.com');
      const loadPromise: Promise<void> = session.loadUrl('https://example.com', loadOptions);
      const reloadPromise: Promise<void> = session.reload();
      const stopPromise: Promise<void> = session.stop();
      const postMessagePromise: Promise<void> = session.postMessage(message);
      const scriptResult: Promise<ScriptValue> = session.evaluateJavaScript('1 + 1');
      const setUserAgentPromise: Promise<void> = session.setCustomUserAgent(null);
      const navigationState: WebNavigationState = session.getNavigationState();
      const pageMetadata: WebPageMetadata = session.getMetadata();

      session.bindObserver(observer);
      session.bindObserver(null);
      session.bindRequestHandler(requestHandler);
      session.bindRequestHandler(null);

      expect(navigation.canGoBack).assertFalse();
      expect(navigation.canGoForward).assertFalse();
      expect(metadata.title).assertEqual('');
      expect(metadata.url).assertEqual('');
      expect(registration.id).assertEqual('');
      expect(registration.name).assertEqual('');
      expect(registration.sessionScoped).assertTrue();
      expect(capabilities.supportsMultipleSessions).assertTrue();
      expect(navigationState.canGoBack).assertFalse();
      expect(pageMetadata.title).assertEqual('');
      expect(typeof dataManager.clear).assertEqual('function');
      expect(typeof session.stop).assertEqual('function');
      expect(typeof session.postMessage).assertEqual('function');
      void clearDataPromise;
      void dataManagerClearPromise;
      void loadWithoutOptionsPromise;
      void loadPromise;
      void reloadPromise;
      void stopPromise;
      void postMessagePromise;
      void scriptResult;
      void setUserAgentPromise;
    });
  });
}
