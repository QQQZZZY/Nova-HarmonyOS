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
  private readonly stateStore: SessionStateStore;
  private readonly observers: EventDispatcher<WebSessionObserver> = new EventDispatcher<WebSessionObserver>();
  private readonly capabilities: WebSessionCapabilities = createDefaultSessionCapabilities();
  private readonly binding: ArkWebControllerBinding = new ArkWebControllerBinding();
  private requestHandler: WebSessionRequestHandler | null = null;
  private initialUrl: string | null = null;

  constructor(private readonly options: WebSessionOptions) {
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
  }

  async reload(ignoreCache: boolean): Promise<void> {
    void ignoreCache;
  }

  stopLoading(): void {
  }

  async goBack(): Promise<void> {
  }

  async goForward(): Promise<void> {
  }

  async evaluateJavaScript(script: string): Promise<string | null> {
    void script;
    return null;
  }

  async setCustomUserAgent(userAgent: string): Promise<void> {
    void userAgent;
  }

  async setBridgeConfig(config: WebBridgeConfig): Promise<void> {
    void config;
  }

  close(): void {
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
      this.binding.controller.loadUrl(this.initialUrl);
    }
  }

  emitStateChanged(): void {
    const state = this.getState();
    this.observers.snapshot().forEach((observer: WebSessionObserver) => {
      observer.onStateChanged(this, state);
    });
  }
}
