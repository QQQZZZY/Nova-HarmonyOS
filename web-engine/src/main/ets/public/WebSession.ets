import { WebSessionState } from './types/WebSessionState';
import { WebSessionCapabilities } from './types/WebCapabilities';
import { WebBridgeConfig } from './types/WebBridgeTypes';
import { WebNavigationState } from './types/WebNavigationState';
import { WebPageMetadata } from './types/WebPageMetadata';
import { WebLoadOptions, WebMessage, ScriptValue, WebScriptRegistration } from './types/WebScriptTypes';
import type { WebSessionObserver } from './WebSessionObserver';
import type { WebSessionRequestHandler } from './WebSessionRequestHandler';

export interface WebSession {
  getId(): string;
  getState(): WebSessionState;
  getNavigationState(): WebNavigationState;
  getMetadata(): WebPageMetadata;
  getCapabilities(): WebSessionCapabilities;
  bindObserver(observer: WebSessionObserver | null): void;
  bindRequestHandler(handler: WebSessionRequestHandler | null): void;
  loadUrl(url: string, options?: WebLoadOptions): Promise<void>;
  reload(ignoreCache?: boolean): Promise<void>;
  stop(): Promise<void>;
  postMessage(message: WebMessage): Promise<void>;
  evaluateJavaScript(script: string): Promise<ScriptValue>;
  installBridge(config: WebBridgeConfig): Promise<WebScriptRegistration>;
  uninstallBridge(registration: WebScriptRegistration): Promise<void>;
  showFindInPage(searchText?: string): Promise<void>;
  saveState(): Promise<ArrayBuffer | null>;
  restoreState(state: ArrayBuffer): Promise<void>;
  setCustomUserAgent(userAgent: string | null): Promise<void>;
  setBridgeConfig(config: WebBridgeConfig): Promise<void>;
  goBack(): Promise<void>;
  goForward(): Promise<void>;
  close(): void;
}
