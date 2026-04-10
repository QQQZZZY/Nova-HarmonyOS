import { WebEngineCapabilities } from './types/WebCapabilities';
import { WebDataClearOptions } from './types/WebDataTypes';
import { WebSessionOptions } from './types/WebSessionOptions';
import type { WebDataManager } from './WebDataManager';
import type { WebSession } from './WebSession';

export interface WebEngine {
  getCapabilities(): WebEngineCapabilities;
  createSession(options: WebSessionOptions): WebSession;
  getDataManager(): WebDataManager;
  clearData(options: WebDataClearOptions): Promise<void>;
  notifyAppForeground(): void;
  notifyAppBackground(): void;
  close(): void;
}
