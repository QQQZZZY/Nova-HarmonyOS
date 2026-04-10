import { WebEngine } from '../public/WebEngine';
import { WebSessionOptions } from '../public/types/WebSessionOptions';
import { WebEngineCapabilities } from '../public/types/WebCapabilities';
import { WebDataClearOptions } from '../public/types/WebDataTypes';
import { WebDataManager } from '../public/WebDataManager';
import { SessionRegistry } from '../internal/SessionRegistry';
import { ensureArkWebInitialized } from './ArkWebInitializer';
import type { WebSession } from '../public/WebSession';
import { ArkWebDataManager } from './ArkWebDataManager';
import { ArkWebSession } from './ArkWebSession';

class ArkWebEngine implements WebEngine {
  private readonly capabilities: WebEngineCapabilities = new WebEngineCapabilities();
  private readonly registry: SessionRegistry = new SessionRegistry();
  private readonly dataManager: WebDataManager;

  constructor() {
    ensureArkWebInitialized();
    this.dataManager = new ArkWebDataManager(() => this.registry.snapshot());
  }

  getCapabilities(): WebEngineCapabilities {
    return this.capabilities;
  }

  createSession(options: WebSessionOptions): WebSession {
    const session = new ArkWebSession(options, (sessionId: string) => {
      this.unregisterSession(sessionId);
    });
    this.registry.register(session);
    return session;
  }

  getDataManager(): WebDataManager {
    return this.dataManager;
  }

  notifyAppForeground(): void {
    this.registry.snapshot().forEach((session) => {
      session.handleForeground();
    });
  }

  notifyAppBackground(): void {
    this.registry.snapshot().forEach((session) => {
      session.handleBackground();
    });
  }

  async clearData(options: WebDataClearOptions): Promise<void> {
    await this.dataManager.clear(options);
  }

  close(): void {
    this.registry.snapshot().forEach((session) => {
      session.close();
    });
    this.registry.clear();
  }

  private unregisterSession(sessionId: string): void {
    this.registry.unregister(sessionId);
  }
}

export function createArkWebEngine(): WebEngine {
  return new ArkWebEngine();
}
