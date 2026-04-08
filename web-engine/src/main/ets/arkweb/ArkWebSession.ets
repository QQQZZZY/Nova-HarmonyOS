import { util } from '@kit.ArkTS';
import { SessionStateStore } from '../internal/SessionStateStore';
import { EventDispatcher } from '../internal/EventDispatcher';
import { createDefaultSessionCapabilities, WebSessionCapabilities } from '../public/types/WebCapabilities';
import { WebBridgeConfig } from '../public/types/WebBridgeTypes';
import { WebSessionOptions } from '../public/types/WebSessionOptions';
import { WebSessionState } from '../public/types/WebSessionState';
import type { WebSessionObserver } from '../public/WebSessionObserver';
import type { WebSessionRequestHandler } from '../public/WebSessionRequestHandler';
import type { WebSession } from '../public/WebSession';
import { ArkWebControllerBinding } from './ArkWebControllerBinding';

export class ArkWebSession implements WebSession {
  private readonly id: string = util.generateRandomUUID();
  private readonly options: WebSessionOptions;
  private readonly stateStore: SessionStateStore;
  private readonly observers: EventDispatcher<WebSessionObserver> = new EventDispatcher<WebSessionObserver>();
  private readonly capabilities: WebSessionCapabilities = createDefaultSessionCapabilities();
  private readonly binding: ArkWebControllerBinding = new ArkWebControllerBinding();
  private requestHandler: WebSessionRequestHandler | null = null;
  private initialUrl: string | null = null;
  private bridgeConfig: WebBridgeConfig = new WebBridgeConfig();

  constructor(options: WebSessionOptions) {
    this.options = options;
    this.stateStore = new SessionStateStore(options.isPrivate);
    this.initialUrl = options.initialUrl;
  }

  getId(): string {
    return this.id;
  }

  getState(): WebSessionState {
    return this.stateStore.getState();
  }

  getCapabilities(): WebSessionCapabilities {
    return this.capabilities;
  }

  addObserver(observer: WebSessionObserver): void {
    this.observers.add(observer);
  }

  removeObserver(observer: WebSessionObserver): void {
    this.observers.remove(observer);
  }

  setRequestHandler(handler: WebSessionRequestHandler | null): void {
    this.requestHandler = handler;
  }

  prepareInitialNavigation(url: string): void {
    this.initialUrl = url;
  }

  async loadUrl(url: string): Promise<void> {
    this.initialUrl = url;
    this.getStateStore().update((draft) => {
      draft.currentUrl = url;
      draft.isLoading = true;
      draft.progress = 0;
    });
    if (this.binding.attached) {
      try {
        this.binding.controller.loadUrl(url);
      } catch (_error) {
      }
    }
    this.emitStateChanged();
  }

  async reload(ignoreCache: boolean): Promise<void> {
    void ignoreCache;
    if (this.binding.attached) {
      try {
        this.binding.controller.refresh();
      } catch (_error) {
      }
    }
    this.getStateStore().update((draft) => {
      draft.isLoading = true;
      draft.progress = 0;
    });
    this.emitStateChanged();
  }

  stopLoading(): void {
    if (this.binding.attached) {
      try {
        this.binding.controller.stop();
      } catch (_error) {
      }
    }
    this.getStateStore().update((draft) => {
      draft.isLoading = false;
    });
    this.emitStateChanged();
  }

  async goBack(): Promise<void> {
    if (this.binding.attached) {
      try {
        this.binding.controller.backward();
      } catch (_error) {
      }
    }
  }

  async goForward(): Promise<void> {
    if (this.binding.attached) {
      try {
        this.binding.controller.forward();
      } catch (_error) {
      }
    }
  }

  async evaluateJavaScript(script: string): Promise<string | null> {
    if (!this.binding.attached) {
      return null;
    }
    try {
      return this.binding.controller.runJavaScript(script);
    } catch (_error) {
      return null;
    }
  }

  async setCustomUserAgent(userAgent: string): Promise<void> {
    if (this.binding.attached) {
      try {
        this.binding.controller.setCustomUserAgent(userAgent);
      } catch (_error) {
      }
    }
  }

  async setBridgeConfig(config: WebBridgeConfig): Promise<void> {
    this.bridgeConfig = config;
  }

  close(): void {
    this.getStateStore().update((draft) => {
      draft.isAttached = false;
      draft.isVisible = false;
      draft.isLoading = false;
    });
    this.emitStateChanged();
  }

  getBinding(): ArkWebControllerBinding {
    return this.binding;
  }

  getInitialUrl(): string | null {
    return this.initialUrl;
  }

  getStateStore(): SessionStateStore {
    return this.stateStore;
  }

  getRequestHandler(): WebSessionRequestHandler | null {
    return this.requestHandler;
  }

  handleAttached(): void {
    this.getStateStore().update((draft) => {
      draft.isAttached = true;
      draft.isVisible = true;
    });
    this.emitStateChanged();
    if (this.initialUrl !== null && this.initialUrl.length > 0) {
      try {
        this.binding.controller.loadUrl(this.initialUrl);
      } catch (_error) {
      }
    }
  }

  emitStateChanged(): void {
    const state = this.getState();
    this.observers.snapshot().forEach((observer: WebSessionObserver) => {
      observer.onStateChanged(this, state);
    });
  }
}
