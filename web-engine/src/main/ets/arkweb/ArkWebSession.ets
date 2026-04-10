import { util } from '@kit.ArkTS';
import { SessionStateStore } from '../internal/SessionStateStore';
import { EventDispatcher } from '../internal/EventDispatcher';
import { createDefaultSessionCapabilities, WebSessionCapabilities } from '../public/types/WebCapabilities';
import { WebBridgeConfig } from '../public/types/WebBridgeTypes';
import { WebSessionOptions } from '../public/types/WebSessionOptions';
import { WebSessionState } from '../public/types/WebSessionState';
import { WebNavigationState } from '../public/types/WebNavigationState';
import { WebPageMetadata } from '../public/types/WebPageMetadata';
import { WebLoadOptions, WebMessage, ScriptValue, WebScriptRegistration } from '../public/types/WebScriptTypes';
import type { WebSessionObserver } from '../public/WebSessionObserver';
import type { WebSessionRequestHandler } from '../public/WebSessionRequestHandler';
import type { WebSession } from '../public/WebSession';
import { ArkWebBridgeRuntime } from './ArkWebBridgeRuntime';
import { ArkWebControllerBinding } from './ArkWebControllerBinding';
import { ArkWebJsBridgeAdapter } from './ArkWebJsBridgeAdapter';
import { applyControllerLifecycleSnapshot } from './ArkWebLifecycleAdapter';

interface SessionLifecyclePatch {
  attached?: boolean;
  visible?: boolean;
  loading?: boolean;
  currentUrl?: string | null;
  lastCommittedUrl?: string | null;
  title?: string;
  canGoBack?: boolean;
  canGoForward?: boolean;
  progress?: number;
}

class EmptyBridgeObject {
}

export class ArkWebSession implements WebSession {
  private readonly id: string = util.generateRandomUUID();
  private readonly options: WebSessionOptions;
  private readonly stateStore: SessionStateStore;
  private readonly observers: EventDispatcher<WebSessionObserver> = new EventDispatcher<WebSessionObserver>();
  private readonly capabilities: WebSessionCapabilities = createDefaultSessionCapabilities();
  private readonly binding: ArkWebControllerBinding = new ArkWebControllerBinding();
  private readonly bridgeRuntime: ArkWebBridgeRuntime = new ArkWebBridgeRuntime();
  private readonly bridgeAdapter: ArkWebJsBridgeAdapter = new ArkWebJsBridgeAdapter(this.bridgeRuntime);
  private readonly bridgeObject: EmptyBridgeObject = new EmptyBridgeObject();
  private readonly onClose?: (sessionId: string) => void;
  private requestHandler: WebSessionRequestHandler | null = null;
  private boundObserver: WebSessionObserver | null = null;
  private initialUrl: string | null = null;
  private bridgeConfig: WebBridgeConfig = new WebBridgeConfig();

  constructor(options: WebSessionOptions, onClose?: (sessionId: string) => void) {
    this.options = options;
    this.stateStore = new SessionStateStore(options.isPrivate);
    this.initialUrl = options.initialUrl;
    this.onClose = onClose;
    this.binding.observeAttachStateChange((attached: boolean) => {
      if (attached) {
        this.handleAttached();
        return;
      }
      this.handleDetached();
    });
  }

  getId(): string {
    return this.id;
  }

  getState(): WebSessionState {
    return this.stateStore.getState();
  }

  getNavigationState(): WebNavigationState {
    const state = this.stateStore.getState();
    const navigationState = new WebNavigationState();
    navigationState.canGoBack = state.canGoBack;
    navigationState.canGoForward = state.canGoForward;
    return navigationState;
  }

  getMetadata(): WebPageMetadata {
    const state = this.stateStore.getState();
    const metadata = new WebPageMetadata();
    metadata.title = state.title;
    metadata.url = state.currentUrl ?? '';
    return metadata;
  }

  getCapabilities(): WebSessionCapabilities {
    return this.capabilities;
  }

  bindObserver(observer: WebSessionObserver | null): void {
    if (this.boundObserver !== null) {
      this.removeObserver(this.boundObserver);
    }
    this.boundObserver = observer;
    if (observer !== null) {
      this.addObserver(observer);
    }
  }

  bindRequestHandler(handler: WebSessionRequestHandler | null): void {
    this.requestHandler = handler;
  }

  addObserver(observer: WebSessionObserver): void {
    this.observers.add(observer);
  }

  removeObserver(observer: WebSessionObserver): void {
    this.observers.remove(observer);
  }

  setRequestHandler(handler: WebSessionRequestHandler | null): void {
    this.bindRequestHandler(handler);
  }

  prepareInitialNavigation(url: string): void {
    this.initialUrl = url;
  }

  async loadUrl(url: string, options?: WebLoadOptions): Promise<void> {
    void options;
    this.initialUrl = this.isControllerAttached() ? null : url;
    this.getStateStore().update((draft) => {
      draft.currentUrl = url;
      draft.isLoading = true;
      draft.progress = 0;
    });
    if (this.isControllerAttached()) {
      try {
        this.binding.controller.loadUrl(url);
      } catch (_error) {
      }
    }
    this.emitStateChanged();
  }

  async reload(ignoreCache?: boolean): Promise<void> {
    if (this.isControllerAttached()) {
      try {
        if (ignoreCache) {
          this.binding.controller.removeCache(true);
        }
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
    if (this.isControllerAttached()) {
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

  async stop(): Promise<void> {
    this.stopLoading();
  }

  async goBack(): Promise<void> {
    if (this.isControllerAttached()) {
      try {
        if (this.binding.controller.accessBackward()) {
          this.binding.controller.backward();
        }
      } catch (_error) {
      }
    }
  }

  async goForward(): Promise<void> {
    if (this.isControllerAttached()) {
      try {
        if (this.binding.controller.accessForward()) {
          this.binding.controller.forward();
        }
      } catch (_error) {
      }
    }
  }

  async postMessage(message: WebMessage): Promise<void> {
    void message;
  }

  async evaluateJavaScript(script: string): Promise<ScriptValue> {
    if (!this.isControllerAttached()) {
      return null;
    }
    try {
      return await this.binding.controller.runJavaScript(script);
    } catch (_error) {
      return null;
    }
  }

  async installBridge(config: WebBridgeConfig): Promise<WebScriptRegistration> {
    this.bridgeConfig = config;
    if (!this.isControllerAttached()) {
      return this.createBridgeRegistration(config);
    }

    const registrations = this.bridgeAdapter.apply(this.binding.controller, this.bridgeObject, config);
    if (registrations.length > 0) {
      return registrations[0];
    }
    return this.createBridgeRegistration(config);
  }

  async uninstallBridge(registration: WebScriptRegistration): Promise<void> {
    if (!this.isControllerAttached()) {
      return;
    }
    this.bridgeAdapter.remove(this.binding.controller, registration);
  }

  async showFindInPage(searchText?: string): Promise<void> {
    void searchText;
  }

  async saveState(): Promise<ArrayBuffer | null> {
    return null;
  }

  async restoreState(state: ArrayBuffer): Promise<void> {
    void state;
  }

  async setCustomUserAgent(userAgent: string | null): Promise<void> {
    if (this.isControllerAttached()) {
      try {
        this.binding.controller.setCustomUserAgent(userAgent ?? '');
      } catch (_error) {
      }
    }
  }

  async setBridgeConfig(config: WebBridgeConfig): Promise<void> {
    await this.installBridge(config);
  }

  close(): void {
    this.initialUrl = null;
    if (this.isControllerAttached()) {
      this.bridgeAdapter.clear(this.binding.controller);
    }
    this.binding.markDetached();
    this.handleDetached();
    if (this.onClose !== undefined) {
      this.onClose(this.id);
    }
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
    this.binding.markAttached();
    this.applyLifecycleState({
      attached: true,
      visible: true
    });
    this.emitStateChanged();
    const pendingUrl = this.initialUrl;
    this.initialUrl = null;
    if (pendingUrl !== null && pendingUrl.length > 0) {
      try {
        this.binding.controller.loadUrl(pendingUrl);
      } catch (_error) {
      }
    }
    if (this.bridgeConfig.definitions.length > 0) {
      void this.installBridge(this.bridgeConfig);
    }
  }

  handleDetached(): void {
    this.binding.markDetached();
    this.applyLifecycleState({
      attached: false,
      visible: false,
      loading: false,
      canGoBack: false,
      canGoForward: false
    });
    this.emitStateChanged();
  }

  handleForeground(): void {
    if (this.isControllerAttached()) {
      try {
        this.binding.controller.onActive();
      } catch (_error) {
      }
    }
    this.applyLifecycleState({
      visible: this.isControllerAttached()
    });
    this.emitStateChanged();
  }

  handleBackground(): void {
    if (this.isControllerAttached()) {
      try {
        this.binding.controller.onInactive();
      } catch (_error) {
      }
    }
    this.applyLifecycleState({
      visible: false
    });
    this.emitStateChanged();
  }

  clearSslState(): void {
    if (!this.isControllerAttached()) {
      return;
    }
    try {
      this.binding.controller.clearSslCache();
    } catch (_error) {
    }
  }

  clearClientAuthState(): void {
    if (!this.isControllerAttached()) {
      return;
    }
    try {
      this.binding.controller.clearClientAuthenticationCache();
    } catch (_error) {
    }
  }

  syncStateFromController(): void {
    if (!this.isControllerAttached()) {
      return;
    }
    this.applyLifecycleState({});
  }

  private isControllerAttached(): boolean {
    return this.binding.isAttached();
  }

  handleLoadStarted(): void {
    this.applyLifecycleState({
      loading: true,
      progress: 0
    });
    this.emitStateChanged();
  }

  handleNavigationCommitted(url: string): void {
    this.applyLifecycleState({
      currentUrl: url,
      lastCommittedUrl: url
    });
    this.emitStateChanged();
  }

  handleLoadFinished(): void {
    this.applyLifecycleState({
      loading: false,
      progress: 100
    });
    this.emitStateChanged();
  }

  private applyLifecycleState(snapshot: SessionLifecyclePatch): void {
    const state = this.getState();
    const attached = snapshot.attached ?? this.isControllerAttached();
    let currentUrl = snapshot.currentUrl;
    let title = snapshot.title ?? state.title;
    let canGoBack = snapshot.canGoBack ?? state.canGoBack;
    let canGoForward = snapshot.canGoForward ?? state.canGoForward;

    if (attached) {
      try {
        if (currentUrl === undefined) {
          currentUrl = this.binding.getCurrentUrl();
        }
        if (snapshot.title === undefined) {
          title = this.binding.getTitle();
        }
        if (snapshot.canGoBack === undefined) {
          canGoBack = this.binding.canGoBack();
        }
        if (snapshot.canGoForward === undefined) {
          canGoForward = this.binding.canGoForward();
        }
      } catch (_error) {
      }
    }

    applyControllerLifecycleSnapshot(this.stateStore, {
      attached: attached,
      visible: snapshot.visible ?? (attached ? state.isVisible : false),
      loading: snapshot.loading ?? state.isLoading,
      currentUrl: currentUrl,
      lastCommittedUrl: snapshot.lastCommittedUrl,
      title: title,
      canGoBack: canGoBack,
      canGoForward: canGoForward,
      progress: snapshot.progress
    });
  }

  emitStateChanged(): void {
    const state = this.getState();
    this.observers.snapshot().forEach((observer: WebSessionObserver) => {
      observer.onStateChanged(this, state);
    });
  }

  private createBridgeRegistration(config: WebBridgeConfig): WebScriptRegistration {
    const name = config.definitions.length > 0 ? config.definitions[0].name : 'bridge';
    return this.bridgeRuntime.createRegistration(name, true);
  }
}
