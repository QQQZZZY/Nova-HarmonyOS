# HarmonyOS WebEngine Design

## 概述

本设计旨在为 `Nova-HarmonyOS` 构建一个面向 HarmonyOS 的原生 `WebEngine` 模块。该模块以 **ArkWeb API 23** 为能力基线，以 **ArkTS / ArkUI / HarmonyOS 生命周期** 为设计第一原则，同时参考 iOS `WebEngine` 在模块边界、职责拆分和工程组织上的成熟经验。

设计目标不是复刻 iOS 端语义，而是交付一个适合顶级 HarmonyOS app 的 Web 容器基础设施：

- HarmonyOS native-first
- ArkWeb-first
- 明确的模块边界
- 默认安全、按需放开
- 可扩展到多 tab、popup、下载中心、桥接、安全策略和后续高级能力

当前仓库仍是初始化状态，尚未接入 ArkWeb；同时目标 SDK 已明确为 `6.1.0(23)`，因此本设计以 API 23 为实现基线。

## 背景与依据

### 当前仓库状态

- HarmonyOS 仓库当前没有任何 ArkWeb 接入实现。
- 目标 SDK 与兼容 SDK 都为 `6.1.0(23)`，可以直接以 ArkWeb API 23 为能力基线。
- iOS 侧已有 `Engine / EngineSession / EngineView` 等稳定抽象，可作为架构参考，但不作为 HarmonyOS public API 的约束来源。

### 主要参考资料

#### HarmonyOS 项目

- `build-profile.json5:8-10`
- `entry/src/main/ets/pages/Index.ets`
- `entry/src/main/ets/entryability/EntryAbility.ets`

#### iOS WebEngine 参考

- `/Users/qu/Work/projects/iOS/Nova-ios/WebEngine/Sources/WebEngine/Public/Engine.swift`
- `/Users/qu/Work/projects/iOS/Nova-ios/WebEngine/Sources/WebEngine/Public/EngineSession.swift`
- `/Users/qu/Work/projects/iOS/Nova-ios/WebEngine/Sources/WebEngine/Public/EngineSessionDelegate.swift`
- `/Users/qu/Work/projects/iOS/Nova-ios/WebEngine/Sources/WebEngine/Public/Types/DownloadInfo.swift`
- `/Users/qu/Work/projects/iOS/Nova-ios/WebEngine/Sources/WebEngine/Public/Permissions/PermissionRequest.swift`
- `/Users/qu/Work/projects/iOS/Nova-ios/WebEngine/Sources/WebEngine/Public/Dialogs/JavaScriptDialog.swift`

#### ArkWeb SDK 声明与官方文档依据

- `/Users/qu/Work/environment/command-line-tools/sdk/default/openharmony/ets/api/@ohos.web.webview.d.ts`
- `/Users/qu/Work/environment/command-line-tools/sdk/default/openharmony/ets/build-tools/ets-loader/declarations/web.d.ts`
- HarmonyOS 官方 ArkWeb 文档（通过官方文档索引和 Context7 检索）

## 目标

V1 交付一个 **核心可用** 的独立 `WebEngine` 模块，覆盖以下能力：

- 全局 engine runtime
- session 与 host 分离
- URL 加载、停止、刷新、前进、后退
- title、URL、progress、loading、back-forward 状态
- popup / new window
- JavaScript dialog
- permission request
- download lifecycle
- file chooser
- JavaScript bridge
- custom user agent
- cookie / storage / cache 管理
- private mode

## 非目标

以下能力明确不纳入 V1：

- content extraction
- tracking protection
- state restore
- find in page
- zoom / scroll helper
- internal pages
- 高级多窗口策略矩阵
- 复杂浏览器 UI

这些能力应在 V1 架构稳定后按 capability 扩展，而不挤入首版范围。

## 设计原则

1. **HarmonyOS native-first**
   - public API 以 HarmonyOS 与 ArkTS 习惯为准，不追求 iOS 语义镜像。

2. **ArkWeb-first**
   - 子系统设计优先围绕 ArkWeb 官方能力建模，再向上收敛成稳定 public API。

3. **不泄漏平台细节**
   - `WebviewController`、ArkWeb 原始事件与底层异常不直接暴露给业务层。

4. **默认安全**
   - 高风险能力默认关闭，例如 `fileAccess`、`multiWindowAccess`、宽松 bridge 权限、宽松 mixed mode。

5. **显式生命周期与时序**
   - engine init、session attach、app foreground/background 不隐藏在“魔法”行为中。

6. **结构化强类型 API**
   - request / decision / result / state / capability 采用明确类型，而不是松散 map 或动态对象。

## 总体架构

建议以独立模块形式引入仓库根目录，由 `entry` 作为接入层和 demo 容器使用。模块内部拆分为五层：

```text
web-engine/
  src/main/ets/
    public/
      WebEngine.ets
      WebSession.ets
      WebSessionHost.ets
      WebSessionObserver.ets
      WebSessionRequestHandler.ets
      types/
    arkweb/
      ArkWebEngine.ets
      ArkWebSession.ets
      ArkWebEventAdapter.ets
      ArkWebDownloadAdapter.ets
      ArkWebPermissionAdapter.ets
      ArkWebJsBridgeAdapter.ets
      ArkWebPopupAdapter.ets
      ArkWebFileSelectorAdapter.ets
    policy/
      BridgePolicy.ets
      PopupPolicy.ets
      PermissionPolicy.ets
      DownloadPolicy.ets
      FileChooserPolicy.ets
    data/
      WebDataService.ets
      UserAgentService.ets
      CookieService.ets
    internal/
      SessionStateStore.ets
      EventDispatcher.ets
      Errors.ets
```

架构职责划分如下：

- `public/`：稳定的业务接口层
- `arkweb/`：ArkWeb 适配层
- `policy/`：安全与策略决策层
- `data/`：cookie、storage、UA、clear-data 等服务层
- `internal/`：状态管理与内部工具层

## 核心对象模型

### WebEngine

`WebEngine` 是全局 ArkWeb runtime，而不是普通工具类。

职责：

- 管理 ArkWeb bootstrap
- 管理 app foreground/background 生命周期联动
- 创建 `WebSession`
- 暴露 engine-level capability
- 提供全局数据清理与全局 UA 入口

### WebSession

`WebSession` 是浏览上下文实体，代表一个 tab 或一个独立 Web context。

职责：

- 管理单个 session 的配置、导航、桥接、下载、权限、弹窗和状态
- 持有内部 controller 绑定关系
- 不直接承担 UI 渲染职责

### WebSessionHost

`WebSessionHost` 是 ArkUI 组件，用于承载 `Web(...)` 组件。

职责：

- 绑定 `WebSession`
- 管理 host attach / detach
- 将 ArkUI 生命周期桥接给 session
- 作为 `Web({ src, controller, incognitoMode })` 的真正载体

### WebSessionObserver

多订阅通知接口，负责消费状态变化以外的事件，例如：

- bridge message
- download event
- engine health event
- page-level error event

### WebSessionRequestHandler

单点交互决策接口，负责处理必须返回结果的请求，例如：

- navigation policy
- permission request
- JS dialog
- popup / new window
- file chooser
- download request

## 生命周期与状态机

### Engine bootstrap

ArkWeb 运行时初始化应明确纳入架构，而不是隐藏在首次加载逻辑里。

#### 规则

- `initializeWebEngine()` 必须在任何 `Web` 组件加载前调用。
- `setActiveWebEngineVersion(...)` 如果需要设置，必须在 `initializeWebEngine()` 之前调用。

#### 设计结论

- `WebEngine` 提供单一 bootstrap 入口。
- `EntryAbility` 在合适的 app 启动时机初始化 `WebEngine`。
- 运行时状态分为 `uninitialized -> initialized -> active/inactive -> closed`。

### Session 状态机

建议 `WebSession` 最少包含以下状态：

- `created`
- `configured`
- `attached`
- `visible`
- `background`
- `closed`

### 关键约束

- session 可先创建，再绑定 host。
- host 消失不等于 session 关闭。
- `Ability` 退后台不等于关闭所有 session。
- 关闭必须显式调用 `close()`。

### Attach 规则

attach 之前和 attach 之后的可用操作必须分层：

#### attach 前允许

- 写入 `WebSessionOptions`
- 配置 private mode
- 配置 initial navigation
- 配置 user agent
- 配置 bridge policy
- 配置 popup / permission / download / file chooser policy

#### attach 后允许

- `evaluateJavaScript`
- 读取历史栈
- 页面相关 controller 操作
- 依赖真实 web context 的操作

设计上只缓存 **初始配置**，不实现任意 controller 命令排队。

## Public API 草图

以下为规范性草图，用于明确边界和职责，不要求实现阶段逐字符保持一致，但必须保持同等语义与结构。

```ts
export interface WebEngine {
  getCapabilities(): WebEngineCapabilities;
  createSession(options: WebSessionOptions): WebSession;
  notifyAppForeground(): void;
  notifyAppBackground(): void;
  clearData(options: WebDataClearOptions): Promise<void>;
  close(): void;
}

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
  close(): void;

  evaluateJavaScript(script: string): Promise<string | null>;
  setCustomUserAgent(userAgent: string): Promise<void>;
  setBridgeConfig(config: WebBridgeConfig): Promise<void>;
}

export interface WebSessionObserver {
  onStateChanged(session: WebSession, state: WebSessionState): void;
  onDownloadEvent(session: WebSession, event: WebDownloadEvent): void;
  onBridgeMessage(session: WebSession, message: WebBridgeMessage): void;
  onEngineHealthEvent(session: WebSession, event: WebEngineHealthEvent): void;
  onSessionError(session: WebSession, error: WebSessionError): void;
}

export interface WebSessionRequestHandler {
  onNavigationRequest(session: WebSession, request: WebNavigationRequest): Promise<WebNavigationDecision>;
  onPermissionRequest(session: WebSession, request: WebPermissionRequest): Promise<WebPermissionDecision>;
  onDialogRequest(session: WebSession, request: WebDialogRequest): Promise<WebDialogResult>;
  onPopupRequest(session: WebSession, request: WebPopupRequest): Promise<WebPopupDecision>;
  onFileChooserRequest(session: WebSession, request: WebFileChooserRequest): Promise<WebFileChooserResult>;
  onDownloadRequest(session: WebSession, request: WebDownloadRequest): Promise<WebDownloadDecision>;
}
```

## 状态、通知与请求分层

### WebSessionState

`WebSessionState` 用于表达当前状态快照，应至少包含：

- `currentUrl`
- `lastCommittedUrl`
- `title`
- `isLoading`
- `progress`
- `canGoBack`
- `canGoForward`
- `isAttached`
- `isVisible`
- `isPrivate`
- `securityState`

### WebSessionObserver

用于广播瞬时事件，允许多个订阅者。

典型消费者：

- 页面 UI
- 下载中心
- telemetry
- debug 工具

### WebSessionRequestHandler

用于处理需要最终决策的交互请求。整个 session 只允许配置一个 request handler。

## 事件映射策略

ArkWeb 原始事件不直接暴露给业务层，而是由 `ArkWebEventAdapter` 转换成高层语义。

### Navigation start

主要依据：

- `onLoadStarted`
- `onPageBegin`

映射为：

- `isLoading = true`
- progress 进入新一轮加载阶段

### Navigation committed

主要依据：

- `onNavigationEntryCommitted`

映射为：

- 更新 `lastCommittedUrl`
- 更新地址栏 URL
- 更新导航状态

### Navigation finish

主要依据：

- `onLoadFinished`
- 视需要辅助 `onPageEnd`

映射为：

- `isLoading = false`
- progress 完成
- 可触发 metadata / bridge ready 流程

### History state

主要依据：

- `onRefreshAccessedHistory`
- controller history 能力

映射为：

- `canGoBack`
- `canGoForward`
- history snapshot（如需要）

## 核心子系统

### JavaScript bridge

V1 以 ArkWeb JavaScript Proxy 机制为核心：

- `registerJavaScriptProxy(...)`
- `deleteJavaScriptRegister(...)`

设计结论：

- bridge 默认禁用
- bridge 注册必须带结构化权限配置
- object-level 与 method-level 权限都支持
- 内部生成 ArkWeb 所需 permission JSON
- close / detach 时必须正确 unregister
- public 层不直接暴露原始 JS proxy API

推荐 public 类型：

- `WebBridgeDefinition`
- `WebBridgeMethod`
- `WebBridgePermission`
- `WebBridgeConfig`
- `WebBridgeMessage`

V1 bridge payload 建议使用 `string` 或受控 envelope，而不是松散对象，确保 ArkTS public surface 保持稳定和可验证。

### Permission

ArkWeb permission 模型并非单一入口，因此必须保留来源信息。

设计结论：

- internal 层保留不同原始来源
- public 层统一为 `WebPermissionRequest`
- request 中包含 `kind`、`origin`、`resources`、`rawSourceType`
- handler 返回 `allow / deny / partial allow`
- 系统权限状态与 web permission decision 分离建模

### Download

V1 下载体系以 ArkWeb 官方能力为基线：

- `setDownloadDelegate(...)`
- `WebDownloadDelegate`
- `WebDownloadItem`
- `WebDownloadManager`
- `serialize()` / `deserialize()` / `resumeDownload(...)`

设计结论：

- 下载是独立子系统，不作为零散页面事件实现
- 拆分为 request 阶段与 task lifecycle 阶段
- 内部维护稳定的 `WebDownloadTask` 与 snapshot
- 架构上预留恢复能力，即使 V1 UI 不完整也不破坏后续扩展

推荐 public 类型：

- `WebDownloadRequest`
- `WebDownloadDecision`
- `WebDownloadTask`
- `WebDownloadSnapshot`
- `WebDownloadEvent`

### File chooser

V1 以 `onShowFileSelector` 为核心入口。

设计结论：

- file chooser 单独建模，不与 dialog 合并
- 支持基于 `acceptType` 与 `capture` 做路由
- 默认由 app 接管，可选择回退到系统默认选择器
- 支持 camera、photo library、document picker 等路由扩展

推荐 public 类型：

- `WebFileChooserRequest`
- `WebFileChooserResult`
- `WebFileChooserPolicy`

### Popup / new window

V1 以 ArkWeb controller handoff 模型为核心：

- `onWindowNew(...)`
- `onWindowNewExt(...)`
- `ControllerHandler.setWebController(...)`

设计结论：

- popup 到来时先创建 `PendingPopupSession`
- 交给 `WebSessionRequestHandler` 决策
- 支持 `openInForegroundTab`、`openInBackgroundTab`、`reject`
- 不覆盖当前 session
- third-party iframe popup 默认更严格

### JavaScript dialog

V1 将以下原始能力统一为 dialog request：

- `onAlert`
- `onConfirm`
- `onPrompt`
- `onBeforeUnload`

设计结论：

- `onBeforeUnload` 保留单独 subtype，不伪装为普通 confirm
- dialog request 属于 request handler 而不是 observer

## 数据、隐私与默认安全策略

### Private mode

private mode 是 session 创建时的不可变属性，而不是运行期切换项。

设计结论：

- `WebSessionOptions.isPrivate` 为一等字段
- private session 与 normal session 数据域必须分离
- cookie / storage / clear-data API 内部显式区分 mode

### Cookie 与 storage

ArkWeb `WebCookieManager` 和 `WebStorage` 都是强平台语义能力，因此统一通过 `data/` 服务层包装，不直接暴露为全局静态 API。

推荐职责：

- `CookieService`
- `WebDataService`

public 层只暴露受控能力：

- get cookies
- set cookie
- clear cookies
- clear storage
- clear cache

### Data clear

`WebDataClearOptions` 建议采用结构化字段：

```ts
export class WebDataClearOptions {
  clearCookies: boolean = false;
  clearWebStorage: boolean = false;
  clearMemoryCache: boolean = false;
  clearDiskCache: boolean = false;
  clearSslState: boolean = false;
  clearClientAuthState: boolean = false;
  target: WebDataScope = WebDataScope.CurrentMode;
}
```

### User agent

ArkWeb 原生支持分层 UA：

- current context：`setCustomUserAgent(...)`
- host level：`setUserAgentForHosts(...)`
- app global：`setAppCustomUserAgent(...)`

设计结论：

- V1 默认开放 session-level UA
- 预留 engine-level host/app UA 配置入口
- public 层显式建模为 hierarchical override，而不是单字符串字段

### 安全默认值

V1 默认策略建议为：

- `fileAccess = false`
- `multiWindowAccess = false`
- `geolocationAccess = false`
- `databaseAccess = false`
- `domStorageAccess` 按 option 显式控制
- `mixedMode` 使用安全默认值
- bridge 默认禁用
- popup 默认阻止

原则：默认收敛，按需放开。

## Capability 模型

V1 不强行假装所有能力都完美一致，因此 public API 中必须存在 capability 对象。

推荐字段：

```ts
export class WebSessionCapabilities {
  supportsJavaScriptBridge: boolean = false;
  supportsFileChooser: boolean = false;
  supportsDownloadControl: boolean = false;
  supportsDownloadResume: boolean = false;
  supportsStateRestore: boolean = false;
  supportsFindInPage: boolean = false;
}
```

该对象用于：

- 向上层明确能力边界
- 避免“未实现但看起来应该可用”的虚假承诺
- 支撑后续分阶段扩展

## 错误模型

不直接向业务层抛出 ArkWeb 或 `BusinessError` 原始类型。推荐定义 domain error：

- `WebEngineError`
- `WebSessionError`
- `WebDownloadError`
- `WebBridgeError`

内部保留原始错误 code / message / cause，用于日志、debug 与 telemetry。

## 测试与验证策略

### Unit tests

重点验证：

- navigation event mapping
- request / decision mapping
- bridge permission config generation
- data clear option mapping
- popup routing
- download state transition

### Demo / integration pages

建议在 `entry` 或 demo 模块中准备至少以下验证页：

- basic navigation
- JS dialog
- permission request
- file chooser
- popup / new window
- download
- JS bridge
- private mode + cookie / storage

### 编译验证

进入实现阶段后，应先建立仓库统一的构建入口，再将其作为 ArkTS 代码验证标准。

建议 implementation plan 明确两件事：

1. 在仓库中补齐统一脚本（例如 `scripts/run.sh` / `scripts/run.ps1`）作为规范化入口。
2. 在脚本内部执行标准 HarmonyOS 构建链路，例如：

```bash
ohpm install --all
hvigorw assembleApp
```

如果实现开始时仓库尚未包含 `hvigorw` wrapper，则应将生成或补齐 wrapper 视为模块脚手架的一部分，而不是跳过编译验证。


## 风险与应对

### 风险 1：强行做 iOS 语义镜像

后果：public API 不自然，ArkWeb 能力被压扁，HarmonyOS 生命周期问题被隐藏。

应对：以 ArkWeb 与 HarmonyOS 规范为主，仅借鉴 iOS 边界设计。

### 风险 2：attach 时序被“命令队列”掩盖

后果：实际生命周期 bug 难以暴露，行为不可预测。

应对：只缓存初始配置，不缓存任意 controller 命令。

### 风险 3：bridge、popup、file access 默认过宽

后果：安全边界过弱。

应对：默认禁用高风险能力，必须显式配置与 allowlist。

### 风险 4：下载实现成零散回调

后果：后续恢复下载、下载中心和任务管理无法演进。

应对：将下载从一开始建模为独立子系统。

## 最终决策

本设计最终确定以下关键决策：

1. HarmonyOS `WebEngine` 采用 **HarmonyOS native-first** 设计，不追求 iOS public API 一一对齐。
2. ArkWeb 官方能力是子系统设计主模型。
3. `WebEngine / WebSession / WebSessionHost` 三层职责严格分离。
4. 对外交互采用 **state + observer + request handler** 三通道模型。
5. JS bridge、download、popup、file chooser、permission 都按独立子系统设计。
6. private mode 是 session 固有属性。
7. 默认安全收敛，高风险能力按策略显式开启。
8. V1 聚焦“核心可用”，高级能力延后到后续迭代。

## 后续计划入口

该设计文档批准后，下一步进入 implementation planning，输出内容应至少包括：

- 模块创建与仓库结构调整计划
- public types 与接口骨架落地顺序
- ArkWeb runtime bootstrap 实现顺序
- WebSession / Host / EventAdapter 实现顺序
- download / permission / popup / bridge / file chooser 子系统拆分计划
- demo / integration 页面与测试计划
