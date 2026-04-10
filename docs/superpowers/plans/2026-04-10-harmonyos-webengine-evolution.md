# HarmonyOS WebEngine Evolution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将当前 HarmonyOS `web-engine` 从 V1 过渡实现演进为可长期支撑浏览器能力的稳定引擎底座，优先吸收 ArkWeb 官方语义，并允许早期 breaking change。

**Architecture:** 先重置 public contract，再依次收敛 session 生命周期、资源与安全表面、脚本与 bridge 基础设施，最后补浏览器关键增强能力。所有高风险行为优先采用 ArkWeb 官方 API，HarmonyOS `WebEngine` 只负责稳定抽象边界与类型模型。

**Tech Stack:** ArkTS, ArkUI, ArkWeb (`@kit.ArkWeb`), Hypium, HAR module (`web-engine`), hvigor

---

## File Structure Map

### Existing files to preserve and evolve

- `web-engine/Index.ets` — HAR export surface
- `web-engine/src/main/ets/public/WebEngine.ets` — engine public contract
- `web-engine/src/main/ets/public/WebSession.ets` — session public contract
- `web-engine/src/main/ets/public/WebSessionHost.ets` — ArkUI render host
- `web-engine/src/main/ets/public/WebSessionObserver.ets` — observer contract
- `web-engine/src/main/ets/public/WebSessionRequestHandler.ets` — host decision contract
- `web-engine/src/main/ets/arkweb/ArkWebEngine.ets` — ArkWeb-backed engine implementation
- `web-engine/src/main/ets/arkweb/ArkWebSession.ets` — ArkWeb-backed session implementation
- `web-engine/src/main/ets/data/WebDataService.ets` — current data clear helpers
- `web-engine/src/test/List.test.ets` — module test suite entry
- `scripts/test-web-engine.sh` — standard verification entry

### New files expected in this plan

- `web-engine/src/main/ets/public/WebDataManager.ets` — public data/resource management boundary
- `web-engine/src/main/ets/public/types/WebPageMetadata.ets` — page title/url/metadata value model
- `web-engine/src/main/ets/public/types/WebNavigationState.ets` — navigation state value model
- `web-engine/src/main/ets/public/types/WebScriptTypes.ets` — script and bridge registration models
- `web-engine/src/main/ets/internal/SessionRegistry.ets` — engine-owned active session registry
- `web-engine/src/main/ets/arkweb/ArkWebDataManager.ets` — ArkWeb-backed resource manager
- `web-engine/src/main/ets/arkweb/ArkWebLifecycleAdapter.ets` — attach/active/navigation state synchronization
- `web-engine/src/main/ets/arkweb/ArkWebBridgeRuntime.ets` — script/bridge runtime orchestration
- `web-engine/src/test/PublicContract.test.ets` — public contract baseline tests
- `web-engine/src/test/ArkWebSessionLifecycle.test.ets` — lifecycle and state synchronization tests
- `web-engine/src/test/ArkWebDataManager.test.ets` — official resource surface tests
- `web-engine/src/test/ArkWebBridgeRuntime.test.ets` — bridge lifecycle tests
- `web-engine/src/test/ArkWebSessionExtensions.test.ets` — extension capability tests

The plan below assumes these files stay focused. Do not collapse multiple responsibilities back into `ArkWebSession.ets` or `WebSessionHost.ets`.

### Task 1: Freeze the New Additive Public Contract

**Files:**
- Create: `web-engine/src/test/PublicContract.test.ets`
- Create: `web-engine/src/main/ets/public/WebDataManager.ets`
- Create: `web-engine/src/main/ets/public/types/WebPageMetadata.ets`
- Create: `web-engine/src/main/ets/public/types/WebNavigationState.ets`
- Create: `web-engine/src/main/ets/public/types/WebScriptTypes.ets`
- Modify: `web-engine/src/main/ets/public/WebEngine.ets`
- Modify: `web-engine/src/main/ets/public/WebSession.ets`
- Modify: `web-engine/src/main/ets/public/WebSessionObserver.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebEngine.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebSession.ets`
- Modify: `web-engine/Index.ets`
- Modify: `web-engine/src/test/List.test.ets`

- [ ] **Step 1: Write the failing public-contract baseline test**

```ts
import { describe, it, expect } from '@ohos/hypium';
import { WebEngineCapabilities } from '../main/ets/public/types/WebCapabilities';
import { WebNavigationState } from '../main/ets/public/types/WebNavigationState';
import { WebPageMetadata } from '../main/ets/public/types/WebPageMetadata';
import { WebScriptRegistration } from '../main/ets/public/types/WebScriptTypes';

export default function publicContractTest() {
  describe('PublicContract', () => {
    it('should expose stable value types for navigation metadata and script registration', 0, () => {
      const navigation = new WebNavigationState();
      const metadata = new WebPageMetadata();
      const registration = new WebScriptRegistration();
      const capabilities = new WebEngineCapabilities();

      expect(navigation.canGoBack).assertFalse();
      expect(metadata.title).assertEqual('');
      expect(registration.name).assertEqual('');
      expect(capabilities.supportsMultipleSessions).assertTrue();
    });
  });
}
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run: `hvigorw test -p module=webengine -p scope=PublicContract`  
Expected: FAIL with missing file or missing exported type errors for the new public types.

- [ ] **Step 3: Add the new public value types and resource boundary**

```ts
export class WebNavigationState {
  canGoBack: boolean = false;
  canGoForward: boolean = false;
}

export class WebPageMetadata {
  title: string = '';
  url: string = '';
}

export class WebScriptRegistration {
  id: string = '';
  name: string = '';
  sessionScoped: boolean = true;
}
```

- [ ] **Step 4: Add the new contract hooks without removing every legacy runtime entry point yet**

```ts
export interface WebEngine {
  getCapabilities(): WebEngineCapabilities;
  getDataManager(): WebDataManager;
  createSession(options: WebSessionOptions): WebSession;
  clearData(options: WebDataClearOptions): Promise<void>;
  notifyAppForeground(): void;
  notifyAppBackground(): void;
  close(): void;
}
```

```ts
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
  // Keep compatibility aliases during the migration window.
  addObserver(observer: WebSessionObserver): void;
  removeObserver(observer: WebSessionObserver): void;
  setRequestHandler(handler: WebSessionRequestHandler | null): void;
  prepareInitialNavigation(url: string): void;
  stopLoading(): void;
  goBack(): Promise<void>;
  goForward(): Promise<void>;
  postMessage(message: WebMessage): Promise<void>;
  evaluateJavaScript(script: string): Promise<ScriptValue>;
  setCustomUserAgent(userAgent: string | null): Promise<void>;
  setBridgeConfig(config: WebBridgeConfig): Promise<void>;
  close(): void;
}
```

Task 1 is intentionally additive. Introduce the new `WebDataManager`, `WebNavigationState`, `WebPageMetadata`, and `WebScriptTypes` boundaries, make the new engine/session hooks part of the required public contract, and stop exporting concrete ArkWeb implementation classes from the HAR root. Preserve temporary compatibility aliases on `WebSession` and `WebEngine.clearData()` so existing callers remain buildable while Tasks 2-5 migrate onto the new names and signatures. The final legacy cleanup moves to Task 7.

- [ ] **Step 5: Export the new public files from the HAR root**

```ts
export * from './src/main/ets/public/WebDataManager';
export * from './src/main/ets/public/types/WebPageMetadata';
export * from './src/main/ets/public/types/WebNavigationState';
export * from './src/main/ets/public/types/WebScriptTypes';
```

- [ ] **Step 6: Register the new test in the suite**

```ts
import publicContractTest from './PublicContract.test';

export default function testsuite() {
  publicContractTest();
}
```

- [ ] **Step 7: Run the focused test to verify it passes**

Run: `hvigorw test -p module=webengine -p scope=PublicContract`  
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add web-engine/Index.ets \
  web-engine/src/main/ets/public \
  web-engine/src/main/ets/arkweb/ArkWebEngine.ets \
  web-engine/src/main/ets/arkweb/ArkWebSession.ets \
  web-engine/src/test/PublicContract.test.ets \
  web-engine/src/test/List.test.ets
git commit -m "feat: 重置 web-engine 公共契约边界"
```

### Task 2: Build the Session Registry and Lifecycle Core

**Files:**
- Create: `web-engine/src/main/ets/internal/SessionRegistry.ets`
- Create: `web-engine/src/main/ets/arkweb/ArkWebLifecycleAdapter.ets`
- Create: `web-engine/src/test/ArkWebSessionLifecycle.test.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebEngine.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebSession.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebControllerBinding.ets`
- Modify: `web-engine/src/main/ets/public/WebSessionHost.ets`
- Modify: `web-engine/src/main/ets/internal/SessionStateStore.ets`
- Modify: `web-engine/src/test/List.test.ets`

- [ ] **Step 1: Write the failing lifecycle test**

```ts
import { describe, it, expect } from '@ohos/hypium';
import { SessionStateStore } from '../main/ets/internal/SessionStateStore';
import { applyControllerLifecycleSnapshot } from '../main/ets/arkweb/ArkWebLifecycleAdapter';

export default function arkWebSessionLifecycleTest() {
  describe('ArkWebSessionLifecycle', () => {
    it('should synchronize attach visibility and navigation state from one lifecycle snapshot', 0, () => {
      const store = new SessionStateStore(false);

      applyControllerLifecycleSnapshot(store, {
        attached: true,
        visible: true,
        loading: true,
        currentUrl: 'https://example.com',
        title: 'Example',
        canGoBack: false,
        canGoForward: true
      });

      const state = store.getState();
      expect(state.isAttached).assertTrue();
      expect(state.isVisible).assertTrue();
      expect(state.currentUrl).assertEqual('https://example.com');
      expect(state.title).assertEqual('Example');
      expect(state.canGoForward).assertTrue();
    });
  });
}
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run: `hvigorw test -p module=webengine -p scope=ArkWebSessionLifecycle`  
Expected: FAIL because `ArkWebLifecycleAdapter` and the snapshot helper do not exist yet.

- [ ] **Step 3: Create a focused lifecycle adapter**

```ts
export interface ControllerLifecycleSnapshot {
  attached: boolean;
  visible: boolean;
  loading: boolean;
  currentUrl: string;
  title: string;
  canGoBack: boolean;
  canGoForward: boolean;
}
```

```ts
export function applyControllerLifecycleSnapshot(
  store: SessionStateStore,
  snapshot: ControllerLifecycleSnapshot
): void {
  store.update((draft) => {
    draft.isAttached = snapshot.attached;
    draft.isVisible = snapshot.visible;
    draft.isLoading = snapshot.loading;
    draft.currentUrl = snapshot.currentUrl;
    draft.title = snapshot.title;
    draft.canGoBack = snapshot.canGoBack;
    draft.canGoForward = snapshot.canGoForward;
  });
}
```

- [ ] **Step 4: Introduce a session registry owned by the engine**

```ts
export class SessionRegistry {
  private sessions: Array<WebSession> = [];

  register(session: WebSession): void {
    this.sessions.push(session);
  }

  unregister(sessionId: string): void {
    this.sessions = this.sessions.filter((session) => session.getId() !== sessionId);
  }

  snapshot(): Array<WebSession> {
    return this.sessions.slice();
  }
}
```

- [ ] **Step 5: Route app foreground and background events through the registry**

```ts
notifyAppForeground(): void {
  this.registry.snapshot().forEach((session) => {
    (session as ArkWebSession).handleForeground();
  });
}
```

- [ ] **Step 6: Move lifecycle synchronization out of `WebSessionHost` glue**

```ts
.onLoadFinished(() => {
  const session = this.getArkSession();
  session.handleLoadFinished();
})
```

- [ ] **Step 7: Register the new test and run it**

Run: `hvigorw test -p module=webengine -p scope=ArkWebSessionLifecycle`  
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add web-engine/src/main/ets/internal/SessionRegistry.ets \
  web-engine/src/main/ets/arkweb/ArkWebLifecycleAdapter.ets \
  web-engine/src/main/ets/arkweb/ArkWebEngine.ets \
  web-engine/src/main/ets/arkweb/ArkWebSession.ets \
  web-engine/src/main/ets/arkweb/ArkWebControllerBinding.ets \
  web-engine/src/main/ets/public/WebSessionHost.ets \
  web-engine/src/main/ets/internal/SessionStateStore.ets \
  web-engine/src/test/ArkWebSessionLifecycle.test.ets \
  web-engine/src/test/List.test.ets
git commit -m "feat: 收敛 arkweb 生命周期与会话注册表"
```

### Task 3: Replace `WebDataService` With a Real Public Data Manager

**Files:**
- Create: `web-engine/src/main/ets/arkweb/ArkWebDataManager.ets`
- Create: `web-engine/src/test/ArkWebDataManager.test.ets`
- Modify: `web-engine/src/main/ets/public/WebDataManager.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebEngine.ets`
- Modify: `web-engine/src/main/ets/data/WebDataService.ets`
- Modify: `web-engine/src/main/ets/data/CookieService.ets`
- Modify: `web-engine/src/main/ets/data/UserAgentService.ets`
- Modify: `web-engine/src/test/List.test.ets`

- [ ] **Step 1: Write the failing data-manager test**

```ts
import { describe, it, expect } from '@ohos/hypium';
import { WebDataClearOptions, WebDataScope } from '../main/ets/public/types/WebDataTypes';
import { mapOfficialDataActions } from '../main/ets/arkweb/ArkWebDataManager';

export default function arkWebDataManagerTest() {
  describe('ArkWebDataManager', () => {
    it('should map clear options to official ArkWeb resource operations', 0, () => {
      const options = new WebDataClearOptions();
      options.clearCookies = true;
      options.clearMemoryCache = true;
      options.clearDiskCache = true;
      options.clearSslState = true;
      options.clearClientAuthState = true;
      options.target = WebDataScope.BOTH;

      const plan = mapOfficialDataActions(options);
      expect(plan.clearCookies).assertTrue();
      expect(plan.clearCache).assertTrue();
      expect(plan.clearSslState).assertTrue();
      expect(plan.clearClientAuthState).assertTrue();
      expect(plan.bothModes).assertTrue();
    });
  });
}
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run: `hvigorw test -p module=webengine -p scope=ArkWebDataManager`  
Expected: FAIL because `ArkWebDataManager` and `mapOfficialDataActions` are missing.

- [ ] **Step 3: Define the public data-manager boundary**

```ts
export interface WebDataManager {
  clear(options: WebDataClearOptions): Promise<void>;
  getCookies(url: string, isPrivate: boolean): string;
  setCookie(url: string, value: string, isPrivate: boolean): void;
  setAppCustomUserAgent(userAgent: string): void;
  setUserAgentForHosts(userAgent: string, hosts: Array<string>): void;
}
```

- [ ] **Step 4: Create an ArkWeb-backed implementation that prefers official APIs**

```ts
await this.dataManager.clear(options);
webview.WebviewController.removeAllCache(clearRom);
controller.clearSslCache();
controller.clearClientAuthenticationCache();
```

- [ ] **Step 5: Update `ArkWebEngine` to expose `getDataManager()` and stop owning ad-hoc data helpers directly**

```ts
getDataManager(): WebDataManager {
  return this.dataManager;
}
```

- [ ] **Step 6: Register the new test and run both old and new data tests**

Run: `hvigorw test -p module=webengine -p scope=ArkWebDataManager`  
Expected: PASS

Run: `hvigorw test -p module=webengine -p scope=WebDataServicePlan`  
Expected: PASS or be intentionally replaced by the new test suite if `WebDataService` is deleted.

- [ ] **Step 7: Commit**

```bash
git add web-engine/src/main/ets/public/WebDataManager.ets \
  web-engine/src/main/ets/arkweb/ArkWebDataManager.ets \
  web-engine/src/main/ets/arkweb/ArkWebEngine.ets \
  web-engine/src/main/ets/data/WebDataService.ets \
  web-engine/src/main/ets/data/CookieService.ets \
  web-engine/src/main/ets/data/UserAgentService.ets \
  web-engine/src/test/ArkWebDataManager.test.ets \
  web-engine/src/test/List.test.ets
git commit -m "feat: 引入官方语义优先的数据管理层"
```

### Task 4: Unify Permission, Popup, File Chooser, and Download Host Decisions

**Files:**
- Modify: `web-engine/src/main/ets/public/WebSessionRequestHandler.ets`
- Modify: `web-engine/src/main/ets/public/WebSessionObserver.ets`
- Modify: `web-engine/src/main/ets/public/types/WebDownloadTypes.ets`
- Modify: `web-engine/src/main/ets/public/types/WebPermissionTypes.ets`
- Modify: `web-engine/src/main/ets/public/types/WebPopupTypes.ets`
- Modify: `web-engine/src/main/ets/public/types/WebFileChooserTypes.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebPermissionAdapter.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebPopupAdapter.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebFileSelectorAdapter.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebDownloadAdapter.ets`
- Create: `web-engine/src/test/ArkWebRequestSurface.test.ets`
- Modify: `web-engine/src/test/List.test.ets`

- [ ] **Step 1: Write the failing request-surface test**

```ts
import { describe, it, expect } from '@ohos/hypium';
import { WebPopupDecision } from '../main/ets/public/types/WebPopupTypes';
import { resolvePopupDecision } from '../main/ets/arkweb/ArkWebPopupAdapter';

export default function arkWebRequestSurfaceTest() {
  describe('ArkWebRequestSurface', () => {
    it('should reject popup requests when no session-aware handler is present', 0, async () => {
      const decision = await resolvePopupDecision(null, 'https://example.com', 'https://source.com', true, null);
      expect(decision).assertEqual(WebPopupDecision.REJECT);
    });
  });
}
```

- [ ] **Step 2: Run the focused test to verify it fails for contract-shape reasons**

Run: `hvigorw test -p module=webengine -p scope=ArkWebRequestSurface`  
Expected: FAIL because the public request/observer surface does not yet reflect the unified host-decision model.

- [ ] **Step 3: Normalize request-handler responsibilities**

```ts
export interface WebSessionRequestHandler {
  onNavigationRequest(session: WebSession, request: WebNavigationRequest): Promise<WebNavigationDecision>;
  onPermissionRequest(session: WebSession, request: WebPermissionRequest): Promise<WebPermissionDecision>;
  onDialogRequest(session: WebSession, request: WebDialogRequest): Promise<WebDialogResult>;
  onPopupRequest(session: WebSession, request: WebPopupRequest): Promise<WebPopupDecision>;
  onFileChooserRequest(session: WebSession, request: WebFileChooserRequest): Promise<WebFileChooserResult>;
  onDownloadRequest(session: WebSession, request: WebDownloadRequest): Promise<WebDownloadDecision>;
}
```

- [ ] **Step 4: Normalize observer responsibilities for runtime notifications**

```ts
export interface WebSessionObserver {
  onStateChanged(session: WebSession, state: WebSessionState): void;
  onDownloadEvent(session: WebSession, event: WebDownloadEvent): void;
  onSessionError(session: WebSession, error: WebSessionError): void;
}
```

- [ ] **Step 5: Update the ArkWeb adapters to route all host decisions through the same model**

```ts
if (handler === null) {
  return WebPermissionDecision.DENY;
}
return await handler.onPermissionRequest(session, request);
```

- [ ] **Step 6: Register the new test and run it**

Run: `hvigorw test -p module=webengine -p scope=ArkWebRequestSurface`  
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add web-engine/src/main/ets/public/WebSessionRequestHandler.ets \
  web-engine/src/main/ets/public/WebSessionObserver.ets \
  web-engine/src/main/ets/public/types/WebDownloadTypes.ets \
  web-engine/src/main/ets/public/types/WebPermissionTypes.ets \
  web-engine/src/main/ets/public/types/WebPopupTypes.ets \
  web-engine/src/main/ets/public/types/WebFileChooserTypes.ets \
  web-engine/src/main/ets/arkweb/ArkWebPermissionAdapter.ets \
  web-engine/src/main/ets/arkweb/ArkWebPopupAdapter.ets \
  web-engine/src/main/ets/arkweb/ArkWebFileSelectorAdapter.ets \
  web-engine/src/main/ets/arkweb/ArkWebDownloadAdapter.ets \
  web-engine/src/test/ArkWebRequestSurface.test.ets \
  web-engine/src/test/List.test.ets
git commit -m "feat: 统一宿主决策与运行时事件表面"
```

### Task 5: Build the ArkWeb Script and Bridge Runtime

**Files:**
- Create: `web-engine/src/main/ets/arkweb/ArkWebBridgeRuntime.ets`
- Create: `web-engine/src/test/ArkWebBridgeRuntime.test.ets`
- Modify: `web-engine/src/main/ets/public/types/WebScriptTypes.ets`
- Modify: `web-engine/src/main/ets/public/WebSession.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebJsBridgeAdapter.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebSession.ets`
- Modify: `web-engine/src/test/List.test.ets`

- [ ] **Step 1: Write the failing bridge-runtime test**

```ts
import { describe, it, expect } from '@ohos/hypium';
import { WebScriptRegistration } from '../main/ets/public/types/WebScriptTypes';
import { ArkWebBridgeRuntime } from '../main/ets/arkweb/ArkWebBridgeRuntime';

export default function arkWebBridgeRuntimeTest() {
  describe('ArkWebBridgeRuntime', () => {
    it('should return a stable registration when a session-scoped bridge is installed', 0, () => {
      const runtime = new ArkWebBridgeRuntime();
      const registration: WebScriptRegistration = runtime.createRegistration('historyBridge', true);
      expect(registration.name).assertEqual('historyBridge');
      expect(registration.sessionScoped).assertTrue();
    });
  });
}
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run: `hvigorw test -p module=webengine -p scope=ArkWebBridgeRuntime`  
Expected: FAIL because the bridge runtime and registration helper do not exist.

- [ ] **Step 3: Extend the session contract with script and bridge lifecycle methods**

```ts
installBridge(config: WebBridgeConfig): Promise<WebScriptRegistration>;
uninstallBridge(registration: WebScriptRegistration): Promise<void>;
evaluateJavaScript(script: string): Promise<string | null>;
```

- [ ] **Step 4: Introduce a dedicated runtime object instead of keeping bridge lifecycle inside `ArkWebSession`**

```ts
export class ArkWebBridgeRuntime {
  createRegistration(name: string, sessionScoped: boolean): WebScriptRegistration {
    const registration = new WebScriptRegistration();
    registration.id = name + '-registration';
    registration.name = name;
    registration.sessionScoped = sessionScoped;
    return registration;
  }
}
```

- [ ] **Step 5: Route `registerJavaScriptProxy()` and `deleteJavaScriptRegister()` through the runtime**

```ts
const registration = this.runtime.createRegistration(definition.name, true);
controller.registerJavaScriptProxy(bridgeObject, definition.name, syncMethods, asyncMethods, permission);
return registration;
```

- [ ] **Step 6: Register the new test and run it**

Run: `hvigorw test -p module=webengine -p scope=ArkWebBridgeRuntime`  
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add web-engine/src/main/ets/public/types/WebScriptTypes.ets \
  web-engine/src/main/ets/public/WebSession.ets \
  web-engine/src/main/ets/arkweb/ArkWebBridgeRuntime.ets \
  web-engine/src/main/ets/arkweb/ArkWebJsBridgeAdapter.ets \
  web-engine/src/main/ets/arkweb/ArkWebSession.ets \
  web-engine/src/test/ArkWebBridgeRuntime.test.ets \
  web-engine/src/test/List.test.ets
git commit -m "feat: 建立 arkweb 脚本与 bridge 运行时"
```

### Task 6: Add Browser-Critical Extensions Without Reopening the Core Contract

**Files:**
- Create: `web-engine/src/test/ArkWebSessionExtensions.test.ets`
- Modify: `web-engine/src/main/ets/public/WebSession.ets`
- Modify: `web-engine/src/main/ets/public/types/WebCapabilities.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebSession.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebEngine.ets`
- Modify: `web-engine/src/test/List.test.ets`

- [ ] **Step 1: Write the failing extension test**

```ts
import { describe, it, expect } from '@ohos/hypium';
import { WebSessionCapabilities } from '../main/ets/public/types/WebCapabilities';

export default function arkWebSessionExtensionsTest() {
  describe('ArkWebSessionExtensions', () => {
    it('should expose extension capability flags without changing the core session contract again', 0, () => {
      const capabilities = new WebSessionCapabilities();
      expect(capabilities.supportsFindInPage).assertFalse();
      expect(capabilities.supportsStateRestore).assertFalse();
    });
  });
}
```

- [ ] **Step 2: Run the focused test to verify it fails if new extension flags are missing**

Run: `hvigorw test -p module=webengine -p scope=ArkWebSessionExtensions`  
Expected: FAIL if the extension capability surface is not explicit enough for the planned browser-critical features.

- [ ] **Step 3: Add extension-oriented capability and placeholder APIs**

```ts
export interface WebSession {
  showFindInPage(searchText?: string): Promise<void>;
  saveState(): Promise<ArrayBuffer | null>;
  restoreState(state: ArrayBuffer): Promise<void>;
}
```

```ts
export class WebSessionCapabilities {
  supportsStateRestore: boolean = false;
  supportsFindInPage: boolean = false;
}
```

- [ ] **Step 4: Implement no-op or official-API-backed placeholders without reopening earlier boundaries**

```ts
async showFindInPage(searchText?: string): Promise<void> {
  void searchText;
}
```

- [ ] **Step 5: Register the new test and run it**

Run: `hvigorw test -p module=webengine -p scope=ArkWebSessionExtensions`  
Expected: PASS

- [ ] **Step 6: Run the full web-engine suite**

Run: `bash scripts/test-web-engine.sh`  
Expected: PASS with all web-engine tests green.

- [ ] **Step 7: Commit**

```bash
git add web-engine/src/main/ets/public/WebSession.ets \
  web-engine/src/main/ets/public/types/WebCapabilities.ets \
  web-engine/src/main/ets/arkweb/ArkWebSession.ets \
  web-engine/src/main/ets/arkweb/ArkWebEngine.ets \
  web-engine/src/test/ArkWebSessionExtensions.test.ets \
  web-engine/src/test/List.test.ets
git commit -m "feat: 增加浏览器关键扩展能力占位"
```

### Task 7: Remove Legacy Session Surface and Align the Demo

**Files:**
- Modify: `web-engine/src/main/ets/public/WebSession.ets`
- Modify: `web-engine/src/main/ets/public/WebSessionObserver.ets`
- Modify: `web-engine/src/main/ets/public/WebSessionRequestHandler.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebSession.ets`
- Modify: `web-engine/src/test/PublicContract.test.ets`
- Modify: `web-engine/src/test/List.test.ets`
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Test: `scripts/test-web-engine.sh`

- [ ] **Step 1: Remove the legacy `WebSession` APIs from the public contract**

```ts
export interface WebSession {
  getId(): string;
  getState(): WebSessionState;
  getNavigationState(): WebNavigationState;
  getMetadata(): WebPageMetadata;
  close(): void;
}
```

- [ ] **Step 2: Run module verification and confirm downstream consumers still depend on the legacy surface**

Run: `hvigorw test -p module=webengine`  
Expected: PASS for the module itself, but app/demo integration should still fail until it stops referencing removed legacy contract members.

- [ ] **Step 3: Move the demo and remaining runtime wiring onto the replacement surfaces introduced in Tasks 2-5**

```ts
const dataManager = demoEngine.getDataManager();
void dataManager;
```

- [ ] **Step 4: Run the app module build or test entry to verify the demo is now aligned**

Run: `bash scripts/test-web-engine.sh`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add web-engine/src/main/ets/public/WebSession.ets \
  web-engine/src/main/ets/public/WebSessionObserver.ets \
  web-engine/src/main/ets/public/WebSessionRequestHandler.ets \
  web-engine/src/main/ets/arkweb/ArkWebSession.ets \
  web-engine/src/test/PublicContract.test.ets \
  web-engine/src/test/List.test.ets \
  entry/src/main/ets/entryability/EntryAbility.ets \
  entry/src/main/ets/pages/Index.ets
git commit -m "refactor: 清理 legacy session 表面并对齐 demo"
```

## Final Verification

- [ ] Run: `bash scripts/test-web-engine.sh`
Expected: PASS

- [ ] Run: `git diff --stat`
Expected: Only the planned `web-engine`, demo-host, and documentation files changed.

- [ ] Run: `git log --oneline -n 7`
Expected: Shows one focused commit per task group in the order above.

## Notes for Execution

- Treat Task 1 as additive contract stabilization, not the removal point for every legacy `WebSession` method.
- Remove legacy `WebSession` surface only after Tasks 2-5 have provided replacement runtime surfaces.
- Do not reintroduce direct `ArkWebSession` casts in app-layer code after Task 1.
- If ArkWeb official semantics differ from the current V1 helper behavior, update the helper behavior immediately rather than layering compatibility shims by default.
- If a later task requires changing a file already stabilized by an earlier task, stop and verify whether the contract boundary is still correct before editing.
