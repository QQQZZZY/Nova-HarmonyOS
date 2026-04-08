import { WebEngineCapabilities } from './types/WebCapabilities';
import { WebSessionOptions } from './types/WebSessionOptions';
import { WebDataClearOptions } from './types/WebDataTypes';
import type { WebSession } from './WebSession';

export interface WebEngine {
  getCapabilities(): WebEngineCapabilities;
  createSession(options: WebSessionOptions): WebSession;
  notifyAppForeground(): void;
  notifyAppBackground(): void;
  clearData(options: WebDataClearOptions): Promise<void>;
  close(): void;
}
