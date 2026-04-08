---
id: MB-PROGRESS-0001
status: active
last_updated: 2026-04-08
owner: Qu
tags: [progress, changelog]
scope: "全项目"
---

# Progress Log

## Recent Changes

### [Changed] WebEngine merged into main - 2026-04-08
- Summary: Fast-forward merged `feature/harmonyos-webengine` into `main`
- Tech impact: `main` now contains the `webengine` HAR module, entry wiring, demo host, scripts, and test coverage added on the feature branch
- Files/Modules touched: `build-profile.json5`, `entry/**`, `scripts/**`, `web-engine/**`
- Related: `feature/harmonyos-webengine`, commit `1d9cbf5`

### [Changed] WebEngine post-merge blockers fixed on main - 2026-04-08
- Summary: Fixed module naming, ArkTS component/property issues, missing module rule files, demo wiring, and several silent session no-op behaviors after merge
- Tech impact: `bash scripts/test-web-engine.sh` and `bash scripts/run.sh` both pass on `main`
- Files/Modules touched: `build-profile.json5`, `entry/src/main/ets/**`, `scripts/**`, `web-engine/src/main/**`
- Related: commit `47d1906`

### [Added] WebEngine HAR module scaffold - 2026-04-05
- Summary: Created `web-engine` HAR module with hvigor/harTasks, registered in workspace
- Tech impact: New module `web-engine/` at project root, entry depends on it via `file:../web-engine`
- Files/Modules touched: `build-profile.json5`, `entry/oh-package.json5`, `web-engine/*`
- Related: docs/superpowers/plans/2026-04-05-harmonyos-webengine.md Task 1

### [Added] WebEngine public types and interface contracts - 2026-04-05
- Summary: Defined 12 type files (state, capabilities, navigation, dialog, permission, popup, file chooser, download, bridge, data, errors) and 4 public interface files (WebEngine, WebSession, WebSessionObserver, WebSessionRequestHandler)
- Tech impact: Public API surface now fully typed; all subsequent tasks consume these types
- Files/Modules touched: `web-engine/src/main/ets/public/**`
- Related: docs/superpowers/plans/2026-04-05-harmonyos-webengine.md Task 2
