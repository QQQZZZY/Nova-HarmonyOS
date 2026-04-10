# Repository Guidelines

## Project Context
本仓库是 `Nova-HarmonyOS`，当前重点在于把 `web-engine/` 打造成可长期演进的 HarmonyOS 原生 WebEngine 底座，而不是一次性的业务页封装。默认以 **HarmonyOS API 23** 作为能力基线；`build-profile.json5` 当前目标与兼容 SDK 均为 `6.1.0(23)`，因此所有 ArkWeb 相关判断、设计与实现都应优先对齐 API 23 官方语义。

协作时默认假设使用者已经熟悉工程化、客户端架构与跨端抽象，不需要再重复基础概念。优先输出能直接落地的判断、方案、实现与验证路径。

## Project Structure & Module Organization
`entry/` 是应用壳与演示集成层：

- 页面位于 `entry/src/main/ets/pages`
- Ability 位于 `entry/src/main/ets/entryability`
- 资源文件位于 `entry/src/main/resources`

`web-engine/` 是核心 HAR 模块：

- `web-engine/src/main/ets/public`：对外契约、值类型、会话接口、Host 与观察者
- `web-engine/src/main/ets/arkweb`：ArkWeb 适配层与运行时实现
- `web-engine/src/main/ets/data`：Cookie、UA、Web 数据等平台能力包装
- `web-engine/src/main/ets/internal`：内部状态、注册表、派发器
- `web-engine/src/main/ets/policy`：策略建模与桥接权限等规则

测试与文档：

- `web-engine/src/test`：`web-engine` 单元测试
- `entry/src/ohosTest/ets/test`：设备侧测试
- `docs/superpowers/plans`：执行计划
- `docs/superpowers/specs`：设计与架构说明

## Architecture Rules
默认遵守以下边界，不要为了局部方便破坏它们：

1. `entry/` 和更上层业务代码只依赖 `web-engine` 根导出面，不直接 import `web-engine/src/main/ets/arkweb/*`。
2. 新能力先收敛到 `public/` 契约与类型，再落到 `arkweb/` 适配实现，不要先暴露实现细节再补抽象。
3. 如果当前 V1 helper 行为与 ArkWeb 官方语义冲突，优先修正 public contract 与实现，使之回到官方语义，而不是继续叠兼容胶水。
4. 对资源管理、session 生命周期、安全相关行为，**优先使用 ArkWeb 官方 API**，不要用自定义状态或猜测行为替代官方能力。
5. 不要把具体 `ArkWebSession`、`WebviewController`、attach glue 或临时修复逻辑泄漏到 app-facing API。

## Documentation Workflow
涉及 HarmonyOS、ArkWeb、ArkTS、ArkUI、Hvigor 或相关 SDK/API 时，默认按下面顺序查文档并做判断：

1. **优先使用 Chrome MCP 查询华为官方文档页面**
2. 必要时再使用 `[$find-docs](/Users/qu/.agents/skills/find-docs/SKILL.md)` 或 `ctx7` 做补充检索
3. 如果多个来源冲突，以 **HarmonyOS API 23 官方文档语义** 为准

针对 ArkWeb，优先使用华为开发者文档搜索页，而不是猜测 URL：

- 推荐入口：[`https://developer.huawei.com/consumer/cn/doc/search?type=all&val=ArkWeb`](https://developer.huawei.com/consumer/cn/doc/search?type=all&val=ArkWeb)
- 同类查询可替换 `val=` 参数，例如 `WebviewController`、`registerJavaScriptProxy`、`cookie manager`
- 不要依赖 `search?keyword=...` 这类猜测路径，实际站点上该入口可能直接落到 404

使用 Chrome MCP 时注意：

1. 先打开官方搜索结果页，再通过页面快照、页面内搜索、按钮与结构化文本定位目标文档。
2. 华为站点结果页有较重的前端渲染，某些“查看文档”按钮不一定暴露稳定 href；这时优先提取结果标题、来源路径、关键词，再继续页面内定位。
3. 如果 Chrome MCP 无法稳定拿到具体正文，再退回 `find-docs` 或 `ctx7`，但结论仍应回到官方 API23 语义上。

## Build, Test, and Development Commands
先执行：

```bash
ohpm install --all
```

常用验证入口：

```bash
bash scripts/test-web-engine.sh
hvigorw test -p module=webengine
hvigorw test -p module=webengine -p scope=PublicContract
hvigorw assembleApp
```

补充约束：

1. `scripts/test-web-engine.sh` 会安装依赖并运行 `web-engine` 全量 Hypium 测试。
2. `scripts/run.sh` 会安装依赖并执行 `hvigorw assembleApp -p module=webengine`，适合做集成构建回归。
3. 这个仓库里应优先使用 `assembleApp` 作为项目级构建入口，不要假设 `hvigorw build` 可用。
4. 开发中可使用 `-p scope=...` 聚焦单个测试套件，例如 `PublicContract`、`ArkWebSessionLifecycle`、`ArkWebDataManager`、`ArkWebBridgeRuntime`。

## Coding Style & Naming Conventions
ArkTS 文件保持 2 空格缩进。类型、组件使用 `PascalCase`，变量与函数使用 `camelCase`，测试文件命名为 `*.test.ets`。

实现时优先遵守：

1. 公共 API 放在 `public/`，实现细节留在 `arkweb/`、`data/`、`internal/`。
2. 单个文件尽量只承担一个主要职责，不要把生命周期、桥接、资源管理再次混回 `ArkWebSession.ets`。
3. 只有在行为或意图不清楚时才添加注释，且注释优先解释“为什么这样做”。
4. 新增测试文件后同步注册到 `web-engine/src/test/List.test.ets`。
5. `code-linter.json5` 重点约束性能、推荐 TypeScript/ArkTS 规则与不安全加密 API，改动前后都应留意这些约束。

## Testing Guidelines
当前测试栈以 `@ohos/hypium` 为主，并已引入 `@ohos/hamock`。对 `web-engine` 的非平凡改动，至少补一个与改动直接对应的回归测试，优先覆盖以下高风险区域：

- public contract 与导出面
- session lifecycle 与 attach/foreground/background 状态同步
- data manager、cookie、storage、cache 清理等资源能力
- permission、popup、file chooser、download 等 request/decision surface
- JavaScript bridge、script runtime 与注册/反注册生命周期

如果改动影响 `entry/` 页面行为或集成 wiring，再补 `ohosTest` 或集成构建验证。

## Change Strategy
对当前仓库做 HarmonyOS WebEngine 演进时，默认采用以下顺序：

1. 先稳定 contract，再补实现细节
2. 先稳定 lifecycle/state，再扩展 resource/security surface
3. 先稳定 bridge substrate，再做更高层浏览器能力

如果需要参考 iPadOS 端实现，只把它当成分层和职责划分参考，不要直接复制 API 形状、命名或对象布局到 HarmonyOS。

## Commit & Pull Request Guidelines
提交信息沿用 Conventional Commit，并优先使用“类型前缀 + 中文摘要”，例如：

- `feat: 补齐 ArkWeb 官方资源管理接口`
- `fix: 修正 WebSession 生命周期状态同步`
- `docs: 更新 HarmonyOS 文档查询规范`

Pull Request 说明中至少应包含：

1. 影响模块与核心行为变化
2. 是否涉及 public API 或 breaking change
3. 验证命令
4. 若有可见 UI 变化，对应截图或录屏
5. 若实现依据 `docs/superpowers/` 中的 plan/spec，附对应文档路径

## Security & Configuration Tips
1. 不要提交 `build/`、`.hvigor/`、`web-engine/.test/`、`oh_modules/` 等生成物。
2. `local.properties` 属于本机配置，不要把环境特定改动带入提交。
3. 涉及 bridge、下载、权限、cookie、缓存或隐私相关行为时，先确认是否已有 ArkWeb 官方 API，可用时优先采用官方能力。
4. 涉及安全或资源行为的结论，默认需要有官方文档依据，不要仅凭记忆下判断。
