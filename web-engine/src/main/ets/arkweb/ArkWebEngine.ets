import { WebEngine } from '../public/WebEngine';
import { WebSessionOptions } from '../public/types/WebSessionOptions';
import { WebEngineCapabilities } from '../public/types/WebCapabilities';
import { WebDataClearOptions } from '../public/types/WebDataTypes';
import { ensureArkWebInitialized } from './ArkWebInitializer';
import { WebDataService } from '../data/WebDataService';
import type { WebSession } from '../public/WebSession';

export class ArkWebEngine implements WebEngine {
  private readonly capabilities: WebEngineCapabilities = new WebEngineCapabilities();
  private readonly dataService: WebDataService = new WebDataService();

  constructor() {
    ensureArkWebInitialized();
  }

  getCapabilities(): WebEngineCapabilities {
    return this.capabilities;
  }

  createSession(options: WebSessionOptions): WebSession {
    throw new Error(`Session creation not implemented yet for initialUrl=${options.initialUrl ?? ''}`);
  }

  notifyAppForeground(): void {
  }

  notifyAppBackground(): void {
  }

  async clearData(options: WebDataClearOptions): Promise<void> {
    this.dataService.clear(options);
  }

  close(): void {
  }
}

export function createArkWebEngine(): WebEngine {
  return new ArkWebEngine();
}
