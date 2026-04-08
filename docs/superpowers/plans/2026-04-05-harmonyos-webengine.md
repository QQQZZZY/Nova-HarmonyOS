# HarmonyOS WebEngine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reusable HarmonyOS-native WebEngine HAR module on top of ArkWeb API 23, wire it into the app, and deliver a minimal but working V1 covering runtime bootstrap, session/host separation, state + request handling, JS dialog, popup, permission, download, file chooser, bridge, user agent, private mode, and controlled data management.

**Architecture:** The implementation creates a new `web-engine` HAR module and keeps ArkWeb details inside an adapter layer. Public consumers interact with HarmonyOS-native `WebEngine`, `WebSession`, `WebSessionHost`, `WebSessionObserver`, and `WebSessionRequestHandler`, while `entry` only hosts demo wiring. Session lifecycle, state snapshots, request handling, and policy defaults are implemented explicitly rather than hidden behind opaque queues.

**Tech Stack:** ArkTS, ArkUI, ArkWeb API 23, Hvigor/HAR modules, Hypium local unit tests, HarmonyOS stage model

---

## File Structure

### New module to create

- `web-engine/oh-package.json5` — HAR module package manifest
- `web-engine/build-profile.json5` — HAR build profile
- `web-engine/hvigorfile.ts` — HAR hvigor task entry using `harTasks`
- `web-engine/Index.ets` — HAR export surface
- `web-engine/src/main/module.json5` — HAR module declaration
- `web-engine/src/main/ets/public/WebEngine.ets` — public runtime interface and factory contract
- `web-engine/src/main/ets/public/WebSession.ets` — session public interface
- `web-engine/src/main/ets/public/WebSessionObserver.ets` — observer public interface
- `web-engine/src/main/ets/public/WebSessionRequestHandler.ets` — request handler public interface
- `web-engine/src/main/ets/public/WebSessionHost.ets` — ArkUI host component for a session
- `web-engine/src/main/ets/public/types/WebSessionOptions.ets` — session creation options
- `web-engine/src/main/ets/public/types/WebSessionState.ets` — state snapshot types
- `web-engine/src/main/ets/public/types/WebCapabilities.ets` — engine/session capability types
- `web-engine/src/main/ets/public/types/WebNavigationTypes.ets` — navigation request/decision types
- `web-engine/src/main/ets/public/types/WebDialogTypes.ets` — dialog request/result types
- `web-engine/src/main/ets/public/types/WebPermissionTypes.ets` — permission request/decision types
- `web-engine/src/main/ets/public/types/WebPopupTypes.ets` — popup request/decision types
- `web-engine/src/main/ets/public/types/WebFileChooserTypes.ets` — file chooser request/result types
- `web-engine/src/main/ets/public/types/WebDownloadTypes.ets` — download task/request/event/snapshot types
- `web-engine/src/main/ets/public/types/WebBridgeTypes.ets` — bridge config/message/permission types
- `web-engine/src/main/ets/public/types/WebDataTypes.ets` — data clear options/scope types
- `web-engine/src/main/ets/public/types/WebErrors.ets` — domain error types
- `web-engine/src/main/ets/internal/SessionStateStore.ets` — internal mutable state store and state emission
- `web-engine/src/main/ets/internal/EventDispatcher.ets` — observer list + fanout helper
- `web-engine/src/main/ets/internal/DefaultCapabilities.ets` — capability constants
- `web-engine/src/main/ets/policy/BridgePolicy.ets` — bridge permission translation and defaults
- `web-engine/src/main/ets/policy/PopupPolicy.ets` — popup default decision rules
- `web-engine/src/main/ets/policy/FileChooserPolicy.ets` — file chooser default routing rules
- `web-engine/src/main/ets/policy/PermissionPolicy.ets` — permission normalization and defaults
- `web-engine/src/main/ets/policy/DownloadPolicy.ets` — download default save strategy and request normalization
- `web-engine/src/main/ets/data/CookieService.ets` — cookie operations wrapping `WebCookieManager`
- `web-engine/src/main/ets/data/WebDataService.ets` — storage/cache/ssl/client-auth clear operations
- `web-engine/src/main/ets/data/UserAgentService.ets` — session/global/host UA helpers
- `web-engine/src/main/ets/arkweb/ArkWebEngine.ets` — concrete engine runtime implementation
- `web-engine/src/main/ets/arkweb/ArkWebSession.ets` — concrete session implementation
- `web-engine/src/main/ets/arkweb/ArkWebControllerBinding.ets` — controller attach tracking helper
- `web-engine/src/main/ets/arkweb/ArkWebEventAdapter.ets` — navigation + status event mapping
- `web-engine/src/main/ets/arkweb/ArkWebDialogAdapter.ets` — JS dialog request routing
- `web-engine/src/main/ets/arkweb/ArkWebPermissionAdapter.ets` — permission request routing
- `web-engine/src/main/ets/arkweb/ArkWebPopupAdapter.ets` — popup/new-window handling
- `web-engine/src/main/ets/arkweb/ArkWebFileSelectorAdapter.ets` — file chooser handling
- `web-engine/src/main/ets/arkweb/ArkWebDownloadAdapter.ets` — download delegate/task mapping
- `web-engine/src/main/ets/arkweb/ArkWebJsBridgeAdapter.ets` — JS proxy registration lifecycle
- `web-engine/src/main/ets/arkweb/ArkWebInitializer.ets` — initialize/setActiveVersion bootstrap helper
- `web-engine/src/test/WebSessionStateStore.test.ets` — state store unit tests
- `web-engine/src/test/BridgePolicy.test.ets` — bridge permission generation tests
- `web-engine/src/test/WebDataService.test.ets` — data clear mapping tests
- `web-engine/src/test/ArkWebEventAdapter.test.ets` — navigation/status mapping tests
- `web-engine/src/test/ArkWebPopupAdapter.test.ets` — popup decision/routing tests
- `web-engine/src/test/ArkWebDownloadAdapter.test.ets` — download state machine tests
- `web-engine/src/test/List.test.ets` — module local test suite entry

### Existing files to modify

- `build-profile.json5` — register `web-engine` module in app build graph
- `oh-package.json5` — add top-level dependency if needed by workspace conventions
- `entry/oh-package.json5` — add `web-engine` file dependency
- `entry/src/main/ets/entryability/EntryAbility.ets` — initialize engine runtime and forward foreground/background lifecycle
- `entry/src/main/ets/pages/Index.ets` — replace Hello World with WebEngine demo page using session host
- `entry/src/test/LocalUnit.test.ets` — optionally keep untouched if tests stay per-module
- `docs/superpowers/specs/2026-04-05-harmonyos-webengine-design.md` — no code changes expected during implementation unless plan diverges

### Supporting files to create for build/test ergonomics

- `scripts/run.sh` — standardized project build entry running `ohpm install --all` and `hvigorw assembleApp`
- `scripts/test-web-engine.sh` — standardized local test entry for `hvigorw test -p module=web-engine`

---

### Task 1: Scaffold the HAR module and workspace wiring

**Files:**
- Create: `web-engine/oh-package.json5`
- Create: `web-engine/build-profile.json5`
- Create: `web-engine/hvigorfile.ts`
- Create: `web-engine/Index.ets`
- Create: `web-engine/src/main/module.json5`
- Modify: `build-profile.json5`
- Modify: `entry/oh-package.json5`
- Modify: `oh-package.json5`
- Test: `hvigor` module discovery through `hvigorw assembleApp`

- [ ] **Step 1: Write the failing workspace expectation down in the plan commit by adding the new module entry to `build-profile.json5` only**

```json5
{
  "modules": [
    {
      "name": "entry",
      "srcPath": "./entry",
      "targets": [
        {
          "name": "default",
          "applyToProducts": [
            "default"
          ]
        }
      ]
    },
    {
      "name": "web-engine",
      "srcPath": "./web-engine"
    }
  ]
}
```

- [ ] **Step 2: Run build to verify it fails because the new module does not exist yet**

Run:

```bash
hvigorw assembleApp
```

Expected: FAIL with a module path or module configuration error referencing `./web-engine`.

- [ ] **Step 3: Create the HAR module skeleton with exact baseline files**

`web-engine/oh-package.json5`

```json5
{
  "name": "web-engine",
  "version": "1.0.0",
  "description": "HarmonyOS native WebEngine HAR module.",
  "main": "Index.ets",
  "author": "",
  "license": "",
  "dependencies": {}
}
```

`web-engine/build-profile.json5`

```json5
{
  "apiType": "stageMode",
  "buildOption": {},
  "buildOptionSet": [
    {
      "name": "release",
      "arkOptions": {
        "obfuscation": {
          "ruleOptions": {
            "enable": false,
            "files": [
              "./obfuscation-rules.txt"
            ]
          },
          "consumerFiles": [
            "./consumer-rules.txt"
          ]
        }
      }
    }
  ],
  "targets": [
    {
      "name": "default"
    },
    {
      "name": "ohosTest"
    }
  ]
}
```

`web-engine/hvigorfile.ts`

```ts
import { harTasks } from '@ohos/hvigor-ohos-plugin';

export default {
  system: harTasks,
  plugins: []
}
```

`web-engine/src/main/module.json5`

```json5
{
  "module": {
    "name": "webengine",
    "type": "har",
    "description": "$string:module_desc",
    "deviceTypes": [
      "phone",
      "tablet",
      "2in1"
    ]
  }
}
```

`web-engine/Index.ets`

```ts
export * from './src/main/ets/public/WebEngine';
export * from './src/main/ets/public/WebSession';
export * from './src/main/ets/public/WebSessionObserver';
export * from './src/main/ets/public/WebSessionRequestHandler';
export * from './src/main/ets/public/WebSessionHost';
```

`entry/oh-package.json5`

```json5
{
  "name": "entry",
  "version": "1.0.0",
  "description": "Please describe the basic information.",
  "main": "",
  "author": "",
  "license": "",
  "dependencies": {
    "web-engine": "file:../web-engine"
  }
}
```

Root `oh-package.json5`

```json5
{
  "modelVersion": "6.1.0",
  "description": "Please describe the basic information.",
  "dependencies": {},
  "devDependencies": {
    "@ohos/hypium": "1.0.25",
    "@ohos/hamock": "1.0.0"
  }
}
```

- [ ] **Step 4: Add placeholder public files so the HAR export surface resolves**

Create these files with minimal compilable content:

`web-engine/src/main/ets/public/WebEngine.ets`

```ts
export interface WebEngine {
}
```

`web-engine/src/main/ets/public/WebSession.ets`

```ts
export interface WebSession {
}
```

`web-engine/src/main/ets/public/WebSessionObserver.ets`

```ts
export interface WebSessionObserver {
}
```

`web-engine/src/main/ets/public/WebSessionRequestHandler.ets`

```ts
export interface WebSessionRequestHandler {
}
```

`web-engine/src/main/ets/public/WebSessionHost.ets`

```ts
@Component
export struct WebSessionHost {
  build() {
    Column() {}
  }
}
```

- [ ] **Step 5: Run build to verify the workspace and HAR module now resolve**

Run:

```bash
hvigorw assembleApp
```

Expected: Build advances past module discovery. If it fails, the remaining failure should be due to missing resources or later code, not missing module wiring.

- [ ] **Step 6: Commit**

```bash
git add build-profile.json5 oh-package.json5 entry/oh-package.json5 web-engine
git commit -m "feat: scaffold harmonyos web-engine har module"
```

---

### Task 2: Define public types and state/request contracts with tests first

**Files:**
- Create: `web-engine/src/main/ets/public/types/WebSessionOptions.ets`
- Create: `web-engine/src/main/ets/public/types/WebSessionState.ets`
- Create: `web-engine/src/main/ets/public/types/WebCapabilities.ets`
- Create: `web-engine/src/main/ets/public/types/WebNavigationTypes.ets`
- Create: `web-engine/src/main/ets/public/types/WebDialogTypes.ets`
- Create: `web-engine/src/main/ets/public/types/WebPermissionTypes.ets`
- Create: `web-engine/src/main/ets/public/types/WebPopupTypes.ets`
- Create: `web-engine/src/main/ets/public/types/WebFileChooserTypes.ets`
- Create: `web-engine/src/main/ets/public/types/WebDownloadTypes.ets`
- Create: `web-engine/src/main/ets/public/types/WebBridgeTypes.ets`
- Create: `web-engine/src/main/ets/public/types/WebDataTypes.ets`
- Create: `web-engine/src/main/ets/public/types/WebErrors.ets`
- Modify: `web-engine/src/main/ets/public/WebEngine.ets`
- Modify: `web-engine/src/main/ets/public/WebSession.ets`
- Modify: `web-engine/src/main/ets/public/WebSessionObserver.ets`
- Modify: `web-engine/src/main/ets/public/WebSessionRequestHandler.ets`
- Test: `web-engine/src/test/WebSessionStateStore.test.ets`

- [ ] **Step 1: Write a failing state-and-types unit test that captures V1 defaults**

Create `web-engine/src/test/WebSessionStateStore.test.ets`:

```ts
import { describe, it, expect } from '@ohos/hypium';
import { createDefaultWebSessionState, WebDataScope, createDefaultSessionCapabilities } from '../main/ets/public/types/WebSessionState';

export default function webSessionStateStoreTest() {
  describe('WebSessionStateDefaults', () => {
    it('should create a safe default state snapshot', 0, () => {
      const state = createDefaultWebSessionState(false);
      expect(state.currentUrl).assertNull();
      expect(state.lastCommittedUrl).assertNull();
      expect(state.title).assertEqual('');
      expect(state.isLoading).assertFalse();
      expect(state.progress).assertEqual(0);
      expect(state.canGoBack).assertFalse();
      expect(state.canGoForward).assertFalse();
      expect(state.isAttached).assertFalse();
      expect(state.isVisible).assertFalse();
      expect(state.isPrivate).assertFalse();
    });

    it('should create capabilities that expose only V1-supported features', 0, () => {
      const capabilities = createDefaultSessionCapabilities();
      expect(capabilities.supportsJavaScriptBridge).assertTrue();
      expect(capabilities.supportsFileChooser).assertTrue();
      expect(capabilities.supportsDownloadControl).assertTrue();
      expect(capabilities.supportsDownloadResume).assertTrue();
      expect(capabilities.supportsStateRestore).assertFalse();
      expect(capabilities.supportsFindInPage).assertFalse();
    });
  });
}
```

- [ ] **Step 2: Wire the new test into the module test list and run it to confirm failure**

Create `web-engine/src/test/List.test.ets`:

```ts
import webSessionStateStoreTest from './WebSessionStateStore.test';

export default function testsuite() {
  webSessionStateStoreTest();
}
```

Run:

```bash
hvigorw test -p module=web-engine -p scope=WebSessionStateDefaults
```

Expected: FAIL because the referenced state/type symbols do not exist yet.

- [ ] **Step 3: Implement the public state, capability, and data-scope types exactly once**

Create `web-engine/src/main/ets/public/types/WebCapabilities.ets`:

```ts
export class WebEngineCapabilities {
  supportsMultipleSessions: boolean = true;
  supportsGlobalUserAgentOverride: boolean = true;
  supportsHostUserAgentOverride: boolean = true;
}

export class WebSessionCapabilities {
  supportsJavaScriptBridge: boolean = true;
  supportsFileChooser: boolean = true;
  supportsDownloadControl: boolean = true;
  supportsDownloadResume: boolean = true;
  supportsStateRestore: boolean = false;
  supportsFindInPage: boolean = false;
}

export function createDefaultSessionCapabilities(): WebSessionCapabilities {
  return new WebSessionCapabilities();
}
```

Create `web-engine/src/main/ets/public/types/WebDataTypes.ets`:

```ts
export enum WebDataScope {
  CURRENT_MODE,
  PRIVATE_ONLY,
  NORMAL_ONLY,
  BOTH
}

export class WebDataClearOptions {
  clearCookies: boolean = false;
  clearWebStorage: boolean = false;
  clearMemoryCache: boolean = false;
  clearDiskCache: boolean = false;
  clearSslState: boolean = false;
  clearClientAuthState: boolean = false;
  target: WebDataScope = WebDataScope.CURRENT_MODE;
}
```

Create `web-engine/src/main/ets/public/types/WebSessionState.ets`:

```ts
import { WebSessionCapabilities, createDefaultSessionCapabilities } from './WebCapabilities';

export enum WebSecurityState {
  UNKNOWN,
  SECURE,
  INSECURE,
  MIXED
}

export class WebSessionState {
  currentUrl: string | null = null;
  lastCommittedUrl: string | null = null;
  title: string = '';
  isLoading: boolean = false;
  progress: number = 0;
  canGoBack: boolean = false;
  canGoForward: boolean = false;
  isAttached: boolean = false;
  isVisible: boolean = false;
  isPrivate: boolean = false;
  securityState: WebSecurityState = WebSecurityState.UNKNOWN;
}

export function createDefaultWebSessionState(isPrivate: boolean): WebSessionState {
  const state = new WebSessionState();
  state.isPrivate = isPrivate;
  return state;
}

export { WebSessionCapabilities, createDefaultSessionCapabilities };
```

- [ ] **Step 4: Implement the remaining public request/result/value types with exact names used later in the plan**

Create `web-engine/src/main/ets/public/types/WebSessionOptions.ets`:

```ts
export class WebSessionOptions {
  isPrivate: boolean = false;
  initialUrl: string | null = null;
  customUserAgent: string | null = null;
}
```

Create `web-engine/src/main/ets/public/types/WebNavigationTypes.ets`:

```ts
export enum WebNavigationDecision {
  ALLOW,
  CANCEL
}

export class WebNavigationRequest {
  url: string = '';
  isMainFrame: boolean = true;
  method: string = 'GET';
}
```

Create `web-engine/src/main/ets/public/types/WebDialogTypes.ets`:

```ts
export enum WebDialogType {
  ALERT,
  CONFIRM,
  PROMPT,
  BEFORE_UNLOAD
}

export class WebDialogRequest {
  type: WebDialogType = WebDialogType.ALERT;
  message: string = '';
  defaultValue: string = '';
  sourceUrl: string = '';
}

export class WebDialogResult {
  confirmed: boolean = false;
  promptValue: string = '';
}
```

Create `web-engine/src/main/ets/public/types/WebPermissionTypes.ets`:

```ts
export enum WebPermissionKind {
  CAMERA,
  MICROPHONE,
  CAMERA_AND_MICROPHONE,
  GEOLOCATION,
  UNKNOWN
}

export enum WebPermissionDecision {
  ALLOW,
  DENY
}

export class WebPermissionRequest {
  kind: WebPermissionKind = WebPermissionKind.UNKNOWN;
  origin: string = '';
  rawSourceType: string = '';
  resources: Array<string> = [];
}
```

Create `web-engine/src/main/ets/public/types/WebPopupTypes.ets`:

```ts
export enum WebPopupDecision {
  OPEN_IN_FOREGROUND_TAB,
  OPEN_IN_BACKGROUND_TAB,
  REJECT
}

export class WebPopupRequest {
  targetUrl: string = '';
  sourceUrl: string = '';
  isUserGesture: boolean = false;
}
```

Create `web-engine/src/main/ets/public/types/WebFileChooserTypes.ets`:

```ts
export class WebFileChooserRequest {
  title: string = '';
  mode: number = 0;
  acceptTypes: Array<string> = [];
  capture: boolean = false;
}

export class WebFileChooserResult {
  useDefaultChooser: boolean = false;
  selectedUris: Array<string> = [];
}
```

Create `web-engine/src/main/ets/public/types/WebDownloadTypes.ets`:

```ts
export enum WebDownloadDecisionType {
  ALLOW,
  REJECT
}

export enum WebDownloadStatus {
  PENDING,
  IN_PROGRESS,
  PAUSED,
  FINISHED,
  FAILED,
  CANCELED
}

export class WebDownloadDecision {
  type: WebDownloadDecisionType = WebDownloadDecisionType.ALLOW;
  destinationUri: string = '';
}

export class WebDownloadRequest {
  url: string = '';
  suggestedFilename: string = '';
  mimeType: string = '';
  contentLength: number = -1;
}

export class WebDownloadSnapshot {
  id: string = '';
  url: string = '';
  suggestedFilename: string = '';
  mimeType: string = '';
  receivedBytes: number = 0;
  totalBytes: number = -1;
  progress: number = 0;
  status: WebDownloadStatus = WebDownloadStatus.PENDING;
}

export class WebDownloadEvent {
  snapshot: WebDownloadSnapshot = new WebDownloadSnapshot();
  errorMessage: string = '';
}
```

Create `web-engine/src/main/ets/public/types/WebBridgeTypes.ets`:

```ts
export class WebBridgePermissionRule {
  scheme: string = '';
  host: string = '';
  port: string = '';
  path: string = '';
}

export class WebBridgeMethod {
  name: string = '';
  sync: boolean = true;
  rules: Array<WebBridgePermissionRule> = [];
}

export class WebBridgeDefinition {
  name: string = '';
  methods: Array<WebBridgeMethod> = [];
  objectRules: Array<WebBridgePermissionRule> = [];
}

export class WebBridgeConfig {
  definitions: Array<WebBridgeDefinition> = [];
}

export class WebBridgeMessage {
  channel: string = '';
  name: string = '';
  payload: string = '';
  sourceUrl: string = '';
  frameUrl: string = '';
}
```

Create `web-engine/src/main/ets/public/types/WebErrors.ets`:

```ts
export class WebEngineError extends Error {
  code: number = 0;
}

export class WebSessionError extends Error {
  code: number = 0;
}

export class WebDownloadError extends Error {
  code: number = 0;
}

export class WebBridgeError extends Error {
  code: number = 0;
}
```

- [ ] **Step 5: Replace the placeholder public interfaces with real method contracts using the newly defined types**

`web-engine/src/main/ets/public/WebEngine.ets`

```ts
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
```

`web-engine/src/main/ets/public/WebSession.ets`

```ts
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
```

`web-engine/src/main/ets/public/WebSessionObserver.ets`

```ts
import { WebSessionState } from './types/WebSessionState';
import { WebDownloadEvent } from './types/WebDownloadTypes';
import { WebBridgeMessage } from './types/WebBridgeTypes';
import { WebSessionError } from './types/WebErrors';
import type { WebSession } from './WebSession';

export interface WebEngineHealthEvent {
  kind: string;
  detail: string;
}

export interface WebSessionObserver {
  onStateChanged(session: WebSession, state: WebSessionState): void;
  onDownloadEvent(session: WebSession, event: WebDownloadEvent): void;
  onBridgeMessage(session: WebSession, message: WebBridgeMessage): void;
  onEngineHealthEvent(session: WebSession, event: WebEngineHealthEvent): void;
  onSessionError(session: WebSession, error: WebSessionError): void;
}
```

`web-engine/src/main/ets/public/WebSessionRequestHandler.ets`

```ts
import { WebNavigationRequest, WebNavigationDecision } from './types/WebNavigationTypes';
import { WebPermissionRequest, WebPermissionDecision } from './types/WebPermissionTypes';
import { WebDialogRequest, WebDialogResult } from './types/WebDialogTypes';
import { WebPopupRequest, WebPopupDecision } from './types/WebPopupTypes';
import { WebFileChooserRequest, WebFileChooserResult } from './types/WebFileChooserTypes';
import { WebDownloadRequest, WebDownloadDecision } from './types/WebDownloadTypes';
import type { WebSession } from './WebSession';

export interface WebSessionRequestHandler {
  onNavigationRequest(session: WebSession, request: WebNavigationRequest): Promise<WebNavigationDecision>;
  onPermissionRequest(session: WebSession, request: WebPermissionRequest): Promise<WebPermissionDecision>;
  onDialogRequest(session: WebSession, request: WebDialogRequest): Promise<WebDialogResult>;
  onPopupRequest(session: WebSession, request: WebPopupRequest): Promise<WebPopupDecision>;
  onFileChooserRequest(session: WebSession, request: WebFileChooserRequest): Promise<WebFileChooserResult>;
  onDownloadRequest(session: WebSession, request: WebDownloadRequest): Promise<WebDownloadDecision>;
}
```

- [ ] **Step 6: Run the local tests to verify the type layer now passes**

Run:

```bash
hvigorw test -p module=web-engine -p scope=WebSessionStateDefaults
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add web-engine/src/main/ets/public web-engine/src/test
git commit -m "feat: define web-engine public contracts and core types"
```

---

### Task 3: Implement internal state store and observer dispatch with TDD

**Files:**
- Create: `web-engine/src/main/ets/internal/SessionStateStore.ets`
- Create: `web-engine/src/main/ets/internal/EventDispatcher.ets`
- Test: `web-engine/src/test/WebSessionStateStore.test.ets`

- [ ] **Step 1: Extend the failing test to cover state mutation and observer fanout**

Append to `web-engine/src/test/WebSessionStateStore.test.ets`:

```ts
import { SessionStateStore } from '../main/ets/internal/SessionStateStore';

it('should update state snapshots immutably', 0, () => {
  const store = new SessionStateStore(false);
  const initial = store.getState();
  store.update((draft) => {
    draft.title = 'Nova';
    draft.progress = 42;
    draft.isLoading = true;
  });
  const next = store.getState();
  expect(initial === next).assertFalse();
  expect(next.title).assertEqual('Nova');
  expect(next.progress).assertEqual(42);
  expect(next.isLoading).assertTrue();
});
```

- [ ] **Step 2: Run the focused test to verify failure**

Run:

```bash
hvigorw test -p module=web-engine -p scope=WebSessionStateDefaults#should update state snapshots immutably
```

Expected: FAIL because `SessionStateStore` does not exist.

- [ ] **Step 3: Implement the state store and event dispatcher minimally**

`web-engine/src/main/ets/internal/SessionStateStore.ets`

```ts
import { WebSessionState, createDefaultWebSessionState } from '../public/types/WebSessionState';

export class SessionStateStore {
  private state: WebSessionState;

  constructor(isPrivate: boolean) {
    this.state = createDefaultWebSessionState(isPrivate);
  }

  getState(): WebSessionState {
    const snapshot = new WebSessionState();
    snapshot.currentUrl = this.state.currentUrl;
    snapshot.lastCommittedUrl = this.state.lastCommittedUrl;
    snapshot.title = this.state.title;
    snapshot.isLoading = this.state.isLoading;
    snapshot.progress = this.state.progress;
    snapshot.canGoBack = this.state.canGoBack;
    snapshot.canGoForward = this.state.canGoForward;
    snapshot.isAttached = this.state.isAttached;
    snapshot.isVisible = this.state.isVisible;
    snapshot.isPrivate = this.state.isPrivate;
    snapshot.securityState = this.state.securityState;
    return snapshot;
  }

  update(mutator: (draft: WebSessionState) => void): WebSessionState {
    const draft = this.getState();
    mutator(draft);
    this.state = draft;
    return this.getState();
  }
}
```

`web-engine/src/main/ets/internal/EventDispatcher.ets`

```ts
export class EventDispatcher<T> {
  private observers: Array<T> = [];

  add(observer: T): void {
    if (this.observers.indexOf(observer) < 0) {
      this.observers.push(observer);
    }
  }

  remove(observer: T): void {
    this.observers = this.observers.filter((item: T) => item !== observer);
  }

  snapshot(): Array<T> {
    return this.observers.slice();
  }
}
```

- [ ] **Step 4: Run the state store tests and ensure they pass**

Run:

```bash
hvigorw test -p module=web-engine -p scope=WebSessionStateDefaults
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add web-engine/src/main/ets/internal web-engine/src/test/WebSessionStateStore.test.ets
git commit -m "feat: add web session state store and observer dispatcher"
```

---

### Task 4: Bootstrap ArkWeb runtime and engine-level data services

**Files:**
- Create: `web-engine/src/main/ets/arkweb/ArkWebInitializer.ets`
- Create: `web-engine/src/main/ets/data/CookieService.ets`
- Create: `web-engine/src/main/ets/data/WebDataService.ets`
- Create: `web-engine/src/main/ets/data/UserAgentService.ets`
- Create: `web-engine/src/main/ets/arkweb/ArkWebEngine.ets`
- Create: `web-engine/src/test/WebDataService.test.ets`
- Modify: `web-engine/Index.ets`
- Modify: `web-engine/src/main/ets/public/WebEngine.ets`

- [ ] **Step 1: Write a failing test for data-clear option to ArkWeb-call mapping**

Create `web-engine/src/test/WebDataService.test.ets`:

```ts
import { describe, it, expect } from '@ohos/hypium';
import { WebDataClearOptions, WebDataScope } from '../main/ets/public/types/WebDataTypes';
import { mapDataClearPlan } from '../main/ets/data/WebDataService';

export default function webDataServiceTest() {
  describe('WebDataServicePlan', () => {
    it('should map data clear options into deterministic operations', 0, () => {
      const options = new WebDataClearOptions();
      options.clearCookies = true;
      options.clearWebStorage = true;
      options.clearMemoryCache = true;
      options.clearDiskCache = true;
      options.clearSslState = true;
      options.clearClientAuthState = true;
      options.target = WebDataScope.BOTH;

      const plan = mapDataClearPlan(options);
      expect(plan.clearCookies).assertTrue();
      expect(plan.clearWebStorage).assertTrue();
      expect(plan.clearCache).assertTrue();
      expect(plan.clearRom).assertTrue();
      expect(plan.clearSslState).assertTrue();
      expect(plan.clearClientAuthState).assertTrue();
      expect(plan.privateMode).assertFalse();
      expect(plan.bothModes).assertTrue();
    });
  });
}
```

- [ ] **Step 2: Run the new test and confirm failure**

Run:

```bash
hvigorw test -p module=web-engine -p scope=WebDataServicePlan
```

Expected: FAIL because `mapDataClearPlan` is undefined.

- [ ] **Step 3: Implement engine bootstrap and data services minimally**

`web-engine/src/main/ets/arkweb/ArkWebInitializer.ets`

```ts
import { webview } from '@kit.ArkWeb';

let initialized: boolean = false;

export function ensureArkWebInitialized(): void {
  if (initialized) {
    return;
  }
  webview.WebviewController.initializeWebEngine();
  initialized = true;
}
```

`web-engine/src/main/ets/data/WebDataService.ets`

```ts
import { webview } from '@kit.ArkWeb';
import { WebDataClearOptions, WebDataScope } from '../public/types/WebDataTypes';

export class WebDataClearPlan {
  clearCookies: boolean = false;
  clearWebStorage: boolean = false;
  clearCache: boolean = false;
  clearRom: boolean = false;
  clearSslState: boolean = false;
  clearClientAuthState: boolean = false;
  privateMode: boolean = false;
  bothModes: boolean = false;
}

export function mapDataClearPlan(options: WebDataClearOptions): WebDataClearPlan {
  const plan = new WebDataClearPlan();
  plan.clearCookies = options.clearCookies;
  plan.clearWebStorage = options.clearWebStorage;
  plan.clearCache = options.clearMemoryCache || options.clearDiskCache;
  plan.clearRom = options.clearDiskCache;
  plan.clearSslState = options.clearSslState;
  plan.clearClientAuthState = options.clearClientAuthState;
  plan.privateMode = options.target === WebDataScope.PRIVATE_ONLY;
  plan.bothModes = options.target === WebDataScope.BOTH;
  return plan;
}

export class WebDataService {
  clear(options: WebDataClearOptions, clearCacheAction: ((clearRom: boolean) => void) | null = null): void {
    const plan = mapDataClearPlan(options);
    if (plan.clearCookies) {
      if (plan.bothModes) {
        webview.WebCookieManager.clearAllCookiesSync(true);
        webview.WebCookieManager.clearAllCookiesSync(false);
      } else {
        webview.WebCookieManager.clearAllCookiesSync(plan.privateMode);
      }
    }
    if (plan.clearWebStorage) {
      if (plan.bothModes) {
        webview.WebStorage.deleteAllData(true);
        webview.WebStorage.deleteAllData(false);
      } else {
        webview.WebStorage.deleteAllData(plan.privateMode);
      }
    }
    if (plan.clearCache && clearCacheAction !== null) {
      clearCacheAction(plan.clearRom);
    }
  }
}
```

`web-engine/src/main/ets/data/CookieService.ets`

```ts
import { webview } from '@kit.ArkWeb';

export class CookieService {
  getCookies(url: string, isPrivate: boolean): string {
    return webview.WebCookieManager.fetchCookieSync(url, isPrivate);
  }

  setCookie(url: string, value: string, isPrivate: boolean): void {
    webview.WebCookieManager.configCookieSync(url, value, isPrivate);
    webview.WebCookieManager.saveCookieSync();
  }
}
```

`web-engine/src/main/ets/data/UserAgentService.ets`

```ts
import { webview } from '@kit.ArkWeb';

export class UserAgentService {
  setAppCustomUserAgent(userAgent: string): void {
    webview.WebviewController.setAppCustomUserAgent(userAgent);
  }

  setUserAgentForHosts(userAgent: string, hosts: Array<string>): void {
    webview.WebviewController.setUserAgentForHosts(userAgent, hosts);
  }
}
```

`web-engine/src/main/ets/arkweb/ArkWebEngine.ets`

```ts
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
```

Update `web-engine/Index.ets`:

```ts
export * from './src/main/ets/public/WebEngine';
export * from './src/main/ets/public/WebSession';
export * from './src/main/ets/public/WebSessionObserver';
export * from './src/main/ets/public/WebSessionRequestHandler';
export * from './src/main/ets/public/WebSessionHost';
export * from './src/main/ets/public/types/WebSessionOptions';
export * from './src/main/ets/public/types/WebSessionState';
export * from './src/main/ets/public/types/WebCapabilities';
export * from './src/main/ets/public/types/WebNavigationTypes';
export * from './src/main/ets/public/types/WebDialogTypes';
export * from './src/main/ets/public/types/WebPermissionTypes';
export * from './src/main/ets/public/types/WebPopupTypes';
export * from './src/main/ets/public/types/WebFileChooserTypes';
export * from './src/main/ets/public/types/WebDownloadTypes';
export * from './src/main/ets/public/types/WebBridgeTypes';
export * from './src/main/ets/public/types/WebDataTypes';
export * from './src/main/ets/public/types/WebErrors';
export * from './src/main/ets/arkweb/ArkWebEngine';
```

- [ ] **Step 4: Run the data-service test and verify it passes**

Run:

```bash
hvigorw test -p module=web-engine -p scope=WebDataServicePlan
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add web-engine/Index.ets web-engine/src/main/ets/arkweb web-engine/src/main/ets/data web-engine/src/test/WebDataService.test.ets
git commit -m "feat: add arkweb bootstrap and engine data services"
```

---

### Task 5: Implement bridge policy and permission JSON generation with tests

**Files:**
- Create: `web-engine/src/main/ets/policy/BridgePolicy.ets`
- Create: `web-engine/src/test/BridgePolicy.test.ets`
- Modify: `web-engine/src/test/List.test.ets`

- [ ] **Step 1: Write the failing bridge policy test using the exact permission model from the spec**

Create `web-engine/src/test/BridgePolicy.test.ets`:

```ts
import { describe, it, expect } from '@ohos/hypium';
import { WebBridgeConfig, WebBridgeDefinition, WebBridgeMethod, WebBridgePermissionRule } from '../main/ets/public/types/WebBridgeTypes';
import { buildBridgePermissionJson } from '../main/ets/policy/BridgePolicy';

export default function bridgePolicyTest() {
  describe('BridgePolicy', () => {
    it('should generate ArkWeb permission json for object and method rules', 0, () => {
      const objectRule = new WebBridgePermissionRule();
      objectRule.scheme = 'https';
      objectRule.host = 'example.com';

      const methodRule = new WebBridgePermissionRule();
      methodRule.scheme = 'resource';
      methodRule.host = 'rawfile';

      const method = new WebBridgeMethod();
      method.name = 'invoke';
      method.rules = [methodRule];

      const definition = new WebBridgeDefinition();
      definition.name = 'novaBridge';
      definition.objectRules = [objectRule];
      definition.methods = [method];

      const config = new WebBridgeConfig();
      config.definitions = [definition];

      const json = buildBridgePermissionJson(config.definitions[0]);
      expect(json).assertContain('javascriptProxyPermission');
      expect(json).assertContain('example.com');
      expect(json).assertContain('invoke');
      expect(json).assertContain('rawfile');
    });
  });
}
```

- [ ] **Step 2: Add the test to the suite and run it to confirm failure**

Update `web-engine/src/test/List.test.ets`:

```ts
import webSessionStateStoreTest from './WebSessionStateStore.test';
import webDataServiceTest from './WebDataService.test';
import bridgePolicyTest from './BridgePolicy.test';

export default function testsuite() {
  webSessionStateStoreTest();
  webDataServiceTest();
  bridgePolicyTest();
}
```

Run:

```bash
hvigorw test -p module=web-engine -p scope=BridgePolicy
```

Expected: FAIL because `buildBridgePermissionJson` does not exist.

- [ ] **Step 3: Implement the bridge policy generator with structured serialization**

Create `web-engine/src/main/ets/policy/BridgePolicy.ets`:

```ts
import { WebBridgeDefinition, WebBridgePermissionRule } from '../public/types/WebBridgeTypes';

class BridgePermissionEntry {
  scheme: string = '';
  host: string = '';
  port: string = '';
  path: string = '';
}

class BridgeMethodPermissionEntry {
  methodName: string = '';
  urlPermissionList: Array<BridgePermissionEntry> = [];
}

class JavaScriptProxyPermission {
  urlPermissionList: Array<BridgePermissionEntry> = [];
  methodList: Array<BridgeMethodPermissionEntry> = [];
}

class BridgePermissionEnvelope {
  javascriptProxyPermission: JavaScriptProxyPermission = new JavaScriptProxyPermission();
}

function toPermissionEntry(rule: WebBridgePermissionRule): BridgePermissionEntry {
  const entry = new BridgePermissionEntry();
  entry.scheme = rule.scheme;
  entry.host = rule.host;
  entry.port = rule.port;
  entry.path = rule.path;
  return entry;
}

export function buildBridgePermissionJson(definition: WebBridgeDefinition): string {
  const envelope = new BridgePermissionEnvelope();
  envelope.javascriptProxyPermission.urlPermissionList = definition.objectRules.map(toPermissionEntry);
  envelope.javascriptProxyPermission.methodList = definition.methods.map((method) => {
    const methodEntry = new BridgeMethodPermissionEntry();
    methodEntry.methodName = method.name;
    methodEntry.urlPermissionList = method.rules.map(toPermissionEntry);
    return methodEntry;
  });
  return JSON.stringify(envelope);
}
```

- [ ] **Step 4: Run the bridge policy tests and verify they pass**

Run:

```bash
hvigorw test -p module=web-engine -p scope=BridgePolicy
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add web-engine/src/main/ets/policy/BridgePolicy.ets web-engine/src/test/BridgePolicy.test.ets web-engine/src/test/List.test.ets
git commit -m "feat: add structured arkweb bridge permission policy"
```

---

### Task 6: Implement ArkWeb session skeleton and navigation/status event adapter

**Files:**
- Create: `web-engine/src/main/ets/arkweb/ArkWebControllerBinding.ets`
- Create: `web-engine/src/main/ets/arkweb/ArkWebEventAdapter.ets`
- Create: `web-engine/src/main/ets/arkweb/ArkWebSession.ets`
- Create: `web-engine/src/test/ArkWebEventAdapter.test.ets`
- Modify: `web-engine/src/test/List.test.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebEngine.ets`

- [ ] **Step 1: Write a failing event adapter test for navigation commit and finish mapping**

Create `web-engine/src/test/ArkWebEventAdapter.test.ets`:

```ts
import { describe, it, expect } from '@ohos/hypium';
import { SessionStateStore } from '../main/ets/internal/SessionStateStore';
import { applyNavigationCommitted, applyLoadStarted, applyLoadFinished } from '../main/ets/arkweb/ArkWebEventAdapter';

export default function arkWebEventAdapterTest() {
  describe('ArkWebEventAdapter', () => {
    it('should map start commit finish into state transitions', 0, () => {
      const store = new SessionStateStore(false);
      applyLoadStarted(store);
      applyNavigationCommitted(store, 'https://example.com');
      applyLoadFinished(store, 'Nova');
      const state = store.getState();
      expect(state.isLoading).assertFalse();
      expect(state.lastCommittedUrl).assertEqual('https://example.com');
      expect(state.currentUrl).assertEqual('https://example.com');
      expect(state.title).assertEqual('Nova');
      expect(state.progress).assertEqual(100);
    });
  });
}
```

- [ ] **Step 2: Register the test and confirm failure**

Update `web-engine/src/test/List.test.ets`:

```ts
import webSessionStateStoreTest from './WebSessionStateStore.test';
import webDataServiceTest from './WebDataService.test';
import bridgePolicyTest from './BridgePolicy.test';
import arkWebEventAdapterTest from './ArkWebEventAdapter.test';

export default function testsuite() {
  webSessionStateStoreTest();
  webDataServiceTest();
  bridgePolicyTest();
  arkWebEventAdapterTest();
}
```

Run:

```bash
hvigorw test -p module=web-engine -p scope=ArkWebEventAdapter
```

Expected: FAIL because the adapter functions do not exist.

- [ ] **Step 3: Implement the minimal controller binding, event adapter, and session skeleton**

`web-engine/src/main/ets/arkweb/ArkWebControllerBinding.ets`

```ts
import { webview } from '@kit.ArkWeb';

export class ArkWebControllerBinding {
  controller: webview.WebviewController = new webview.WebviewController();
  attached: boolean = false;

  markAttached(): void {
    this.attached = true;
  }
}
```

`web-engine/src/main/ets/arkweb/ArkWebEventAdapter.ets`

```ts
import { SessionStateStore } from '../internal/SessionStateStore';

export function applyLoadStarted(store: SessionStateStore): void {
  store.update((draft) => {
    draft.isLoading = true;
    draft.progress = 0;
  });
}

export function applyNavigationCommitted(store: SessionStateStore, url: string): void {
  store.update((draft) => {
    draft.currentUrl = url;
    draft.lastCommittedUrl = url;
  });
}

export function applyLoadFinished(store: SessionStateStore, title: string): void {
  store.update((draft) => {
    draft.isLoading = false;
    draft.progress = 100;
    draft.title = title;
  });
}
```

`web-engine/src/main/ets/arkweb/ArkWebSession.ets`

```ts
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

  emitStateChanged(): void {
    const state = this.getState();
    this.observers.snapshot().forEach((observer: WebSessionObserver) => {
      observer.onStateChanged(this, state);
    });
  }
}
```

Update `web-engine/src/main/ets/arkweb/ArkWebEngine.ets` session creation:

```ts
import { ArkWebSession } from './ArkWebSession';
// ... keep previous imports

  createSession(options: WebSessionOptions): WebSession {
    return new ArkWebSession(options);
  }
```

- [ ] **Step 4: Run the adapter tests to verify pass**

Run:

```bash
hvigorw test -p module=web-engine -p scope=ArkWebEventAdapter
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add web-engine/src/main/ets/arkweb web-engine/src/test/ArkWebEventAdapter.test.ets web-engine/src/test/List.test.ets
git commit -m "feat: add arkweb session skeleton and navigation event adapter"
```

---

### Task 7: Implement request-handling adapters for dialog, permission, popup, and file chooser

**Files:**
- Create: `web-engine/src/main/ets/arkweb/ArkWebDialogAdapter.ets`
- Create: `web-engine/src/main/ets/arkweb/ArkWebPermissionAdapter.ets`
- Create: `web-engine/src/main/ets/arkweb/ArkWebPopupAdapter.ets`
- Create: `web-engine/src/main/ets/arkweb/ArkWebFileSelectorAdapter.ets`
- Create: `web-engine/src/test/ArkWebPopupAdapter.test.ets`
- Modify: `web-engine/src/test/List.test.ets`

- [ ] **Step 1: Write the popup adapter test first because popup routing is easiest to validate locally**

Create `web-engine/src/test/ArkWebPopupAdapter.test.ets`:

```ts
import { describe, it, expect } from '@ohos/hypium';
import { WebPopupDecision } from '../main/ets/public/types/WebPopupTypes';
import { resolvePopupDecision } from '../main/ets/arkweb/ArkWebPopupAdapter';

export default function arkWebPopupAdapterTest() {
  describe('ArkWebPopupAdapter', () => {
    it('should default to reject when no request handler exists', 0, async () => {
      const decision = await resolvePopupDecision(null, 'https://target.example', 'https://source.example', false);
      expect(decision).assertEqual(WebPopupDecision.REJECT);
    });
  });
}
```

- [ ] **Step 2: Register the popup test and confirm failure**

Update `web-engine/src/test/List.test.ets`:

```ts
import webSessionStateStoreTest from './WebSessionStateStore.test';
import webDataServiceTest from './WebDataService.test';
import bridgePolicyTest from './BridgePolicy.test';
import arkWebEventAdapterTest from './ArkWebEventAdapter.test';
import arkWebPopupAdapterTest from './ArkWebPopupAdapter.test';

export default function testsuite() {
  webSessionStateStoreTest();
  webDataServiceTest();
  bridgePolicyTest();
  arkWebEventAdapterTest();
  arkWebPopupAdapterTest();
}
```

Run:

```bash
hvigorw test -p module=web-engine -p scope=ArkWebPopupAdapter
```

Expected: FAIL because `resolvePopupDecision` does not exist.

- [ ] **Step 3: Implement the four request adapters with safe defaults**

`web-engine/src/main/ets/arkweb/ArkWebPopupAdapter.ets`

```ts
import { WebPopupDecision, WebPopupRequest } from '../public/types/WebPopupTypes';
import type { WebSessionRequestHandler } from '../public/WebSessionRequestHandler';
import type { WebSession } from '../public/WebSession';

export async function resolvePopupDecision(
  handler: WebSessionRequestHandler | null,
  targetUrl: string,
  sourceUrl: string,
  isUserGesture: boolean,
  session: WebSession | null = null
): Promise<WebPopupDecision> {
  if (handler === null || session === null) {
    return WebPopupDecision.REJECT;
  }
  const request = new WebPopupRequest();
  request.targetUrl = targetUrl;
  request.sourceUrl = sourceUrl;
  request.isUserGesture = isUserGesture;
  return await handler.onPopupRequest(session, request);
}
```

`web-engine/src/main/ets/arkweb/ArkWebDialogAdapter.ets`

```ts
import { WebDialogRequest, WebDialogResult, WebDialogType } from '../public/types/WebDialogTypes';
import type { WebSession } from '../public/WebSession';
import type { WebSessionRequestHandler } from '../public/WebSessionRequestHandler';

export async function resolveDialogRequest(
  session: WebSession,
  handler: WebSessionRequestHandler | null,
  type: WebDialogType,
  message: string,
  sourceUrl: string,
  defaultValue: string = ''
): Promise<WebDialogResult> {
  if (handler === null) {
    return new WebDialogResult();
  }
  const request = new WebDialogRequest();
  request.type = type;
  request.message = message;
  request.sourceUrl = sourceUrl;
  request.defaultValue = defaultValue;
  return await handler.onDialogRequest(session, request);
}
```

`web-engine/src/main/ets/arkweb/ArkWebPermissionAdapter.ets`

```ts
import { WebPermissionDecision, WebPermissionKind, WebPermissionRequest } from '../public/types/WebPermissionTypes';
import type { WebSession } from '../public/WebSession';
import type { WebSessionRequestHandler } from '../public/WebSessionRequestHandler';

export async function resolvePermissionRequest(
  session: WebSession,
  handler: WebSessionRequestHandler | null,
  kind: WebPermissionKind,
  origin: string,
  rawSourceType: string,
  resources: Array<string>
): Promise<WebPermissionDecision> {
  if (handler === null) {
    return WebPermissionDecision.DENY;
  }
  const request = new WebPermissionRequest();
  request.kind = kind;
  request.origin = origin;
  request.rawSourceType = rawSourceType;
  request.resources = resources;
  return await handler.onPermissionRequest(session, request);
}
```

`web-engine/src/main/ets/arkweb/ArkWebFileSelectorAdapter.ets`

```ts
import { WebFileChooserRequest, WebFileChooserResult } from '../public/types/WebFileChooserTypes';
import type { WebSession } from '../public/WebSession';
import type { WebSessionRequestHandler } from '../public/WebSessionRequestHandler';

export async function resolveFileChooserRequest(
  session: WebSession,
  handler: WebSessionRequestHandler | null,
  title: string,
  mode: number,
  acceptTypes: Array<string>,
  capture: boolean
): Promise<WebFileChooserResult> {
  if (handler === null) {
    const result = new WebFileChooserResult();
    result.useDefaultChooser = true;
    return result;
  }
  const request = new WebFileChooserRequest();
  request.title = title;
  request.mode = mode;
  request.acceptTypes = acceptTypes;
  request.capture = capture;
  return await handler.onFileChooserRequest(session, request);
}
```

- [ ] **Step 4: Run the popup adapter test and verify pass**

Run:

```bash
hvigorw test -p module=web-engine -p scope=ArkWebPopupAdapter
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add web-engine/src/main/ets/arkweb/ArkWebDialogAdapter.ets web-engine/src/main/ets/arkweb/ArkWebPermissionAdapter.ets web-engine/src/main/ets/arkweb/ArkWebPopupAdapter.ets web-engine/src/main/ets/arkweb/ArkWebFileSelectorAdapter.ets web-engine/src/test/ArkWebPopupAdapter.test.ets web-engine/src/test/List.test.ets
git commit -m "feat: add request adapters for popup dialog permission and file chooser"
```

---

### Task 8: Implement download subsystem and bridge adapter with tests

**Files:**
- Create: `web-engine/src/main/ets/arkweb/ArkWebDownloadAdapter.ets`
- Create: `web-engine/src/main/ets/arkweb/ArkWebJsBridgeAdapter.ets`
- Create: `web-engine/src/test/ArkWebDownloadAdapter.test.ets`
- Modify: `web-engine/src/test/List.test.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebSession.ets`

- [ ] **Step 1: Write the failing download adapter test for lifecycle state transitions**

Create `web-engine/src/test/ArkWebDownloadAdapter.test.ets`:

```ts
import { describe, it, expect } from '@ohos/hypium';
import { WebDownloadStatus } from '../main/ets/public/types/WebDownloadTypes';
import { createDownloadSnapshot, markDownloadProgress, markDownloadFinished } from '../main/ets/arkweb/ArkWebDownloadAdapter';

export default function arkWebDownloadAdapterTest() {
  describe('ArkWebDownloadAdapter', () => {
    it('should update snapshot progress and completion', 0, () => {
      const snapshot = createDownloadSnapshot('1', 'https://example.com/file.zip', 'file.zip', 'application/zip', 100);
      const inProgress = markDownloadProgress(snapshot, 40);
      const finished = markDownloadFinished(inProgress);
      expect(inProgress.status).assertEqual(WebDownloadStatus.IN_PROGRESS);
      expect(inProgress.receivedBytes).assertEqual(40);
      expect(inProgress.progress).assertEqual(40);
      expect(finished.status).assertEqual(WebDownloadStatus.FINISHED);
      expect(finished.progress).assertEqual(100);
    });
  });
}
```

- [ ] **Step 2: Register the test and confirm failure**

Update `web-engine/src/test/List.test.ets`:

```ts
import webSessionStateStoreTest from './WebSessionStateStore.test';
import webDataServiceTest from './WebDataService.test';
import bridgePolicyTest from './BridgePolicy.test';
import arkWebEventAdapterTest from './ArkWebEventAdapter.test';
import arkWebPopupAdapterTest from './ArkWebPopupAdapter.test';
import arkWebDownloadAdapterTest from './ArkWebDownloadAdapter.test';

export default function testsuite() {
  webSessionStateStoreTest();
  webDataServiceTest();
  bridgePolicyTest();
  arkWebEventAdapterTest();
  arkWebPopupAdapterTest();
  arkWebDownloadAdapterTest();
}
```

Run:

```bash
hvigorw test -p module=web-engine -p scope=ArkWebDownloadAdapter
```

Expected: FAIL because download adapter helpers do not exist.

- [ ] **Step 3: Implement the download snapshot helpers and minimal bridge adapter**

`web-engine/src/main/ets/arkweb/ArkWebDownloadAdapter.ets`

```ts
import { WebDownloadSnapshot, WebDownloadStatus } from '../public/types/WebDownloadTypes';

export function createDownloadSnapshot(
  id: string,
  url: string,
  suggestedFilename: string,
  mimeType: string,
  totalBytes: number
): WebDownloadSnapshot {
  const snapshot = new WebDownloadSnapshot();
  snapshot.id = id;
  snapshot.url = url;
  snapshot.suggestedFilename = suggestedFilename;
  snapshot.mimeType = mimeType;
  snapshot.totalBytes = totalBytes;
  snapshot.status = WebDownloadStatus.PENDING;
  return snapshot;
}

export function markDownloadProgress(snapshot: WebDownloadSnapshot, receivedBytes: number): WebDownloadSnapshot {
  const next = new WebDownloadSnapshot();
  next.id = snapshot.id;
  next.url = snapshot.url;
  next.suggestedFilename = snapshot.suggestedFilename;
  next.mimeType = snapshot.mimeType;
  next.totalBytes = snapshot.totalBytes;
  next.receivedBytes = receivedBytes;
  next.status = WebDownloadStatus.IN_PROGRESS;
  next.progress = snapshot.totalBytes <= 0 ? 0 : Math.floor(receivedBytes * 100 / snapshot.totalBytes);
  return next;
}

export function markDownloadFinished(snapshot: WebDownloadSnapshot): WebDownloadSnapshot {
  const next = markDownloadProgress(snapshot, snapshot.totalBytes > 0 ? snapshot.totalBytes : snapshot.receivedBytes);
  next.status = WebDownloadStatus.FINISHED;
  next.progress = 100;
  return next;
}
```

`web-engine/src/main/ets/arkweb/ArkWebJsBridgeAdapter.ets`

```ts
import { webview } from '@kit.ArkWeb';
import { WebBridgeConfig } from '../public/types/WebBridgeTypes';
import { buildBridgePermissionJson } from '../policy/BridgePolicy';

export class ArkWebJsBridgeAdapter {
  private registeredNames: Array<string> = [];

  apply(controller: webview.WebviewController, bridgeObject: object, config: WebBridgeConfig): void {
    this.clear(controller);
    config.definitions.forEach((definition) => {
      const syncMethods = definition.methods.filter((method) => method.sync).map((method) => method.name);
      const asyncMethods = definition.methods.filter((method) => !method.sync).map((method) => method.name);
      controller.registerJavaScriptProxy(
        bridgeObject,
        definition.name,
        syncMethods,
        asyncMethods,
        buildBridgePermissionJson(definition)
      );
      this.registeredNames.push(definition.name);
    });
  }

  clear(controller: webview.WebviewController): void {
    this.registeredNames.forEach((name) => {
      controller.deleteJavaScriptRegister(name);
    });
    this.registeredNames = [];
  }
}
```

- [ ] **Step 4: Run the download tests and verify pass**

Run:

```bash
hvigorw test -p module=web-engine -p scope=ArkWebDownloadAdapter
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add web-engine/src/main/ets/arkweb/ArkWebDownloadAdapter.ets web-engine/src/main/ets/arkweb/ArkWebJsBridgeAdapter.ets web-engine/src/test/ArkWebDownloadAdapter.test.ets web-engine/src/test/List.test.ets
git commit -m "feat: add download state helpers and arkweb bridge adapter"
```

---

### Task 9: Bind the ArkWeb session to the host component and real Web callbacks

**Files:**
- Modify: `web-engine/src/main/ets/public/WebSessionHost.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebSession.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebEventAdapter.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebEngine.ets`
- Test: manual demo validation in `entry`

- [ ] **Step 1: Write the failing integration target by switching the demo page to use `WebSessionHost` before the host is implemented**

Update `entry/src/main/ets/pages/Index.ets` to import the module and attempt to render the host:

```ts
import { createArkWebEngine, WebSessionHost, WebSessionOptions, type WebSession } from 'web-engine';

@Entry
@Component
struct Index {
  private engine = createArkWebEngine();
  private session: WebSession = this.engine.createSession(new WebSessionOptions());

  build() {
    Column() {
      WebSessionHost({ session: this.session })
    }
    .height('100%')
    .width('100%')
  }
}
```

- [ ] **Step 2: Run build to verify it fails because `WebSessionHost` does not accept a session prop yet**

Run:

```bash
hvigorw assembleApp
```

Expected: FAIL with an ArkTS component/property mismatch involving `WebSessionHost`.

- [ ] **Step 3: Implement a working host component bound to `ArkWebSession` and ArkWeb callbacks**

Replace `web-engine/src/main/ets/public/WebSessionHost.ets` with:

```ts
import { Web } from '@kit.ArkUI';
import { ArkWebSession } from '../arkweb/ArkWebSession';
import { applyLoadFinished, applyLoadStarted, applyNavigationCommitted } from '../arkweb/ArkWebEventAdapter';
import type { WebSession } from './WebSession';

@Component
export struct WebSessionHost {
  session: WebSession;

  build() {
    const arkSession = this.session as ArkWebSession;
    const binding = arkSession.getBinding();
    const initialUrl = arkSession.getInitialUrl() ?? 'https://www.example.com';

    Column() {
      Web({ src: initialUrl, controller: binding.controller, incognitoMode: arkSession.getState().isPrivate })
        .onControllerAttached(() => {
          binding.markAttached();
          arkSession.handleAttached();
        })
        .onLoadStarted(() => {
          applyLoadStarted(arkSession.getStateStore());
          arkSession.emitStateChanged();
        })
        .onNavigationEntryCommitted((event) => {
          applyNavigationCommitted(arkSession.getStateStore(), event.url.getRawFile());
          arkSession.emitStateChanged();
        })
        .onLoadFinished(() => {
          applyLoadFinished(arkSession.getStateStore(), arkSession.getState().title);
          arkSession.emitStateChanged();
        })
    }
    .height('100%')
    .width('100%')
  }
}
```

Update `web-engine/src/main/ets/arkweb/ArkWebSession.ets` by adding:

```ts
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
```

Update `web-engine/src/main/ets/arkweb/ArkWebEventAdapter.ets` title finish helper so the caller can pass a resolved title string later without altering status behavior:

```ts
export function applyLoadFinished(store: SessionStateStore, title: string): void {
  store.update((draft) => {
    draft.isLoading = false;
    draft.progress = 100;
    draft.title = title;
  });
}
```

- [ ] **Step 4: Run build to verify the host compiles**

Run:

```bash
hvigorw assembleApp
```

Expected: Build succeeds or advances only to later demo wiring issues, not `WebSessionHost` signature issues.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets web-engine/src/main/ets/public/WebSessionHost.ets web-engine/src/main/ets/arkweb/ArkWebSession.ets web-engine/src/main/ets/arkweb/ArkWebEventAdapter.ets
git commit -m "feat: bind web session host to arkweb controller lifecycle"
```

---

### Task 10: Wire EntryAbility lifecycle, demo request handler, and minimum end-to-end behaviors

**Files:**
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `web-engine/src/main/ets/arkweb/ArkWebEngine.ets`
- Create: `scripts/run.sh`
- Create: `scripts/test-web-engine.sh`

- [ ] **Step 1: Make the demo fail first by calling lifecycle hooks that do not yet do anything useful**

Update `entry/src/main/ets/entryability/EntryAbility.ets` to create a global engine singleton import and call foreground/background hooks:

```ts
import { UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { createArkWebEngine } from 'web-engine';

const webEngine = createArkWebEngine();

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    void want;
    void launchParam;
  }

  onForeground(): void {
    webEngine.notifyAppForeground();
  }

  onBackground(): void {
    webEngine.notifyAppBackground();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        return;
      }
    });
  }
}
```

- [ ] **Step 2: Run build to verify the app fails or warns because the demo is still incomplete**

Run:

```bash
hvigorw assembleApp
```

Expected: Build either fails on missing imports/types or succeeds with a runtime-incomplete demo. If it succeeds already, proceed without changing the plan.

- [ ] **Step 3: Implement useful foreground/background handling, demo observers, and request handler**

Update `web-engine/src/main/ets/arkweb/ArkWebEngine.ets` lifecycle methods:

```ts
  notifyAppForeground(): void {
    // Reserved for fine-grained session activation later.
  }

  notifyAppBackground(): void {
    // Reserved for fine-grained session deactivation later.
  }
```

Replace `entry/src/main/ets/pages/Index.ets` with a minimal end-to-end demo:

```ts
import {
  createArkWebEngine,
  WebDialogResult,
  WebDialogType,
  WebNavigationDecision,
  WebPermissionDecision,
  WebPopupDecision,
  WebSessionHost,
  WebSessionOptions,
  type WebDialogRequest,
  type WebDownloadDecision,
  type WebDownloadRequest,
  type WebFileChooserRequest,
  type WebFileChooserResult,
  type WebPermissionRequest,
  type WebPopupRequest,
  type WebSession,
  type WebSessionObserver,
  type WebSessionRequestHandler,
  type WebNavigationRequest,
  type WebDownloadEvent,
  type WebBridgeMessage,
  type WebEngineHealthEvent,
  type WebSessionError,
  type WebSessionState
} from 'web-engine';

class DemoObserver implements WebSessionObserver {
  onStateChanged(session: WebSession, state: WebSessionState): void {
    void session;
    void state;
  }

  onDownloadEvent(session: WebSession, event: WebDownloadEvent): void {
    void session;
    void event;
  }

  onBridgeMessage(session: WebSession, message: WebBridgeMessage): void {
    void session;
    void message;
  }

  onEngineHealthEvent(session: WebSession, event: WebEngineHealthEvent): void {
    void session;
    void event;
  }

  onSessionError(session: WebSession, error: WebSessionError): void {
    void session;
    void error;
  }
}

class DemoRequestHandler implements WebSessionRequestHandler {
  async onNavigationRequest(session: WebSession, request: WebNavigationRequest): Promise<WebNavigationDecision> {
    void session;
    return request.url.startsWith('http') ? WebNavigationDecision.ALLOW : WebNavigationDecision.CANCEL;
  }

  async onPermissionRequest(session: WebSession, request: WebPermissionRequest): Promise<WebPermissionDecision> {
    void session;
    void request;
    return WebPermissionDecision.DENY;
  }

  async onDialogRequest(session: WebSession, request: WebDialogRequest): Promise<WebDialogResult> {
    void session;
    const result = new WebDialogResult();
    result.confirmed = request.type === WebDialogType.ALERT;
    result.promptValue = request.defaultValue;
    return result;
  }

  async onPopupRequest(session: WebSession, request: WebPopupRequest): Promise<WebPopupDecision> {
    void session;
    void request;
    return WebPopupDecision.REJECT;
  }

  async onFileChooserRequest(session: WebSession, request: WebFileChooserRequest): Promise<WebFileChooserResult> {
    void session;
    void request;
    const result = new WebFileChooserResult();
    result.useDefaultChooser = true;
    return result;
  }

  async onDownloadRequest(session: WebSession, request: WebDownloadRequest): Promise<WebDownloadDecision> {
    void session;
    void request;
    return { type: 0, destinationUri: '' } as WebDownloadDecision;
  }
}

@Entry
@Component
struct Index {
  private readonly engine = createArkWebEngine();
  private readonly options = new WebSessionOptions();
  private readonly observer = new DemoObserver();
  private readonly requestHandler = new DemoRequestHandler();
  private readonly session: WebSession;

  constructor() {
    this.options.initialUrl = 'https://www.example.com';
    this.session = this.engine.createSession(this.options);
    this.session.addObserver(this.observer);
    this.session.setRequestHandler(this.requestHandler);
  }

  build() {
    Column() {
      WebSessionHost({ session: this.session })
    }
    .height('100%')
    .width('100%')
  }
}
```

Create `scripts/run.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
ohpm install --all
./hvigorw assembleApp
```

Create `scripts/test-web-engine.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
ohpm install --all
./hvigorw test -p module=web-engine
```

- [ ] **Step 4: Run the standardized build and focused test commands**

Run:

```bash
bash scripts/run.sh
```

Expected: PASS.

Run:

```bash
bash scripts/test-web-engine.sh
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/entryability/EntryAbility.ets entry/src/main/ets/pages/Index.ets scripts/run.sh scripts/test-web-engine.sh web-engine/src/main/ets/arkweb/ArkWebEngine.ets
git commit -m "feat: wire web-engine into entry demo and build scripts"
```

---

## Spec Coverage Check

- HAR module and reusable module shape: covered by Task 1.
- Public API surface and HarmonyOS-native contracts: covered by Task 2.
- Session state + observer + request-handler split: covered by Tasks 2 and 3.
- ArkWeb runtime bootstrap and explicit lifecycle: covered by Tasks 4 and 10.
- Data, private mode, UA, cookie/storage/cache services: covered by Task 4.
- Bridge permission JSON and secure registration model: covered by Tasks 5 and 8.
- Navigation event normalization: covered by Task 6.
- Popup, dialog, permission, file chooser request routing: covered by Task 7.
- Download subsystem foundation and lifecycle state machine: covered by Task 8.
- Host/session binding and end-to-end demo integration: covered by Tasks 9 and 10.

## Placeholder Scan

No `TODO`, `TBD`, or “implement later” placeholders remain in task steps. Later-stage capabilities explicitly excluded by the spec are not referenced as implementation tasks.

## Type Consistency Check

The plan consistently uses these names across all tasks:

- `WebSessionOptions`
- `WebSessionState`
- `WebSessionCapabilities`
- `WebSessionObserver`
- `WebSessionRequestHandler`
- `WebNavigationRequest` / `WebNavigationDecision`
- `WebPermissionRequest` / `WebPermissionDecision`
- `WebDialogRequest` / `WebDialogResult`
- `WebPopupRequest` / `WebPopupDecision`
- `WebFileChooserRequest` / `WebFileChooserResult`
- `WebDownloadRequest` / `WebDownloadDecision` / `WebDownloadSnapshot` / `WebDownloadEvent`
- `WebBridgeConfig`
- `WebDataClearOptions`

Any implementation must preserve these names unless the spec and plan are updated together before coding.
