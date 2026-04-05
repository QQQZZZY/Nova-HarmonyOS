import { WebSessionState } from './types/WebSessionState';
import { WebSessionCapabilities } from './types/WebCapabilities';
import { WebBridgeConfig } from './types/WebBridgeTypes';
import type { WebSessionObserver } from './WebSessionObserver';
import type { WebSessionRequestHandler } from './WebSessionRequestHandler';

export interface WebSession {
  getId(): string;
  getState(): WebSessionState;
  getCapabilities(): WebSessionCapabilities;
  addObserver(observer: WebSessionObserver): void;
  removeObserver(observer: WebSessionObserver): void;
  setRequestHandler(handler: WebSessionRequestHandler | null): void;
  prepareInitialNavigation(url: string): void;
  loadUrl(url: string): Promise<void>;
  reload(ignoreCache: boolean): Promise<void>;
  stopLoading(): void;
  goBack(): Promise<void>;
  goForward(): Promise<void>;
  evaluateJavaScript(script: string): Promise<string | null>;
  setCustomUserAgent(userAgent: string): Promise<void>;
  setBridgeConfig(config: WebBridgeConfig): Promise<void>;
  close(): void;
}
