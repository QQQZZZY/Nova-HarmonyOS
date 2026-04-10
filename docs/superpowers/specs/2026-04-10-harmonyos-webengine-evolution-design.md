# HarmonyOS WebEngine Evolution Design

## Goal

Define the development order for the HarmonyOS `WebEngine` capability layer so it can evolve from the current V1 implementation into a stable browser foundation.

This design does not cover browser UI, tabs, omnibox, history presentation, or feature-shell orchestration. It focuses only on the engine layer and the order in which that layer should be hardened.

## Current Context

- Current project scope still marks `WebEngine V1` as `in_progress`.
- The current HarmonyOS implementation already contains a dedicated `web-engine` HAR module, public contracts, ArkWeb adapters, and basic tests.
- The iPadOS project provides useful architectural reference, but its API shape should not be copied directly.

Key constraint confirmed for this design:

1. HarmonyOS engine design should remain HarmonyOS-native rather than mirroring iPadOS naming or object layout.
2. The engine is being designed first as a browser foundation.
3. If ArkWeb official semantics conflict with the current V1 public contract, ArkWeb official semantics win, even if that requires early breaking changes.
4. For resource and session management, official ArkWeb APIs should be preferred whenever they exist.

## Non-Goals

- Reproducing iPadOS `WebEngine` APIs one-to-one.
- Preserving V1 public compatibility at all costs.
- Designing browser UI or browser-state architecture in this document.
- Defining every implementation task or file-level patch sequence.

## Reference Baseline

### HarmonyOS Side

- `web-engine/src/main/ets/public/*`
- `web-engine/src/main/ets/arkweb/*`
- `web-engine/src/main/ets/data/*`
- `docs/superpowers/specs/2026-04-05-harmonyos-webengine-design.md`
- `docs/superpowers/plans/2026-04-05-harmonyos-webengine.md`

### iPadOS Side

- `/Users/qu/Work/projects/iOS/Nova-ios/WebEngine/README.md`
- `/Users/qu/Work/projects/iOS/Nova-ios/WebEngine/Sources/WebEngine/Public/Engine.swift`
- `/Users/qu/Work/projects/iOS/Nova-ios/WebEngine/Sources/WebEngine/Public/EngineSession.swift`
- `/Users/qu/Work/projects/iOS/Nova-ios/WebEngine/Sources/WebEngine/Public/EngineSessionDelegate.swift`
- `/Users/qu/Work/projects/iOS/Nova-ios/memory-bank/architecture.md`

The iPadOS project is used here only as an architectural reference for layering discipline:

- engine layer separated from browser UI
- session as the core per-tab lifecycle object
- feature code should not directly depend on low-level web implementation details

## Design Principles

### 1. Official Behavior, Local Contract

ArkWeb should remain the source of truth for behavior semantics whenever official APIs exist.

HarmonyOS `WebEngine` should define the stable abstraction boundary that higher layers use.

In practice:

- ArkWeb owns lifecycle behavior.
- ArkWeb owns resource and session semantics.
- HarmonyOS `WebEngine` owns public contracts, value types, observer flow, and request/response boundaries.

### 2. Contract Before Completeness

The engine should not grow by opportunistically exposing whatever ArkWeb API was easiest to wire first.

Instead:

- stabilize the public contract first
- absorb official ArkWeb semantics into that contract
- only then expand into browser-critical extensions

### 3. Browser-Foundation Priority

The engine is being optimized first for browser scenarios, not generic embedded-web business pages.

That means the early phases prioritize:

- session lifecycle
- navigation state
- permissions
- downloads
- popup handling
- script and bridge infrastructure
- data and privacy surfaces

### 4. Early Breaking Changes Are Acceptable

The current V1 public API should be treated as transitional. If it conflicts with ArkWeb semantics or creates long-term ambiguity, it should be changed early rather than preserved as technical debt.

## Recommended Development Order

The engine should evolve in five phases:

1. `Contract Reset`
2. `Lifecycle & State Core`
3. `Official Resource & Security Surface`
4. `Script & Bridge Substrate`
5. `Browser-Critical Extensions`

This order is mandatory because later phases depend on earlier boundary decisions.

## Phase 1: Contract Reset

### Objective

Replace the current transitional V1 contract with a long-lived HarmonyOS-native engine contract.

### What This Phase Stabilizes

- `WebEngine`
- `WebSession`
- `WebSessionHost`
- `WebSessionObserver`
- `WebSessionRequestHandler`
- `WebDataManager` or an equivalent resource-management surface
- stable value types for state, navigation, metadata, permissions, downloads, and errors

### Core Requirement

Higher layers must stop depending on implementation details such as:

- `ArkWebSession`
- `ArkWebControllerBinding`
- `webview.WebviewController`
- ArkUI host glue logic for state reconstruction

### Completion Criteria

- public responsibilities are explicitly separated
- implementation-specific types are not part of the intended app-facing API
- known breaking changes are intentionally introduced here, not deferred to later phases

### Primary Risk

If this phase is skipped or softened, every later capability addition will continue mutating the public API, and upper layers will anchor themselves to unstable details.

## Phase 2: Lifecycle & State Core

### Objective

Stabilize the session lifecycle and page-state model before expanding into broader browser capabilities.

### Official ArkWeb Abilities To Absorb First

- `initializeWebEngine`
- controller attach state and attach-state change events
- `onActive()`
- `onInactive()`
- `loadUrl()`
- `refresh()`
- `stop()`
- `accessBackward()`
- `accessForward()`
- `backward()`
- `forward()`
- `getTitle()`
- `getUrl()`
- official page-load and navigation callbacks

### Completion Criteria

- attach and detach semantics are stable
- foreground and background semantics are stable
- `title`, `url`, `loading`, `progress`, `canGoBack`, `canGoForward`, and `securityState` come from one coherent state model
- `WebSessionHost` becomes a rendering host rather than a hidden state-repair layer

### Primary Risk

If lifecycle and state are not stabilized here, tabs, chrome, history, and bridge code will consume stale or contradictory session data.

## Phase 3: Official Resource & Security Surface

### Objective

Define a unified resource and security layer whose behavior maps to ArkWeb official capabilities instead of app-defined approximations.

### Official ArkWeb Abilities To Prefer

- cookie manager APIs
- web storage APIs
- cache clearing APIs
- SSL cache clearing APIs
- client-auth cache clearing APIs
- app-level and host-level User-Agent APIs
- official popup, permission, file chooser, and download callbacks or delegates
- navigation policy and external-open handling supported by ArkWeb

### Completion Criteria

- clear boundaries exist between engine-level and session-level resource operations
- privacy-sensitive operations are defined in terms of official semantics
- permission, popup, file chooser, and download flows all use one request/decision model
- data clearing no longer depends on guessed or emulated behavior

### Primary Risk

If this phase is delayed, high-risk areas such as privacy mode, cache behavior, permission routing, and download safety will drift away from the platform’s real behavior.

## Phase 4: Script & Bridge Substrate

### Objective

Build the long-term script and bridge infrastructure only after lifecycle and resource semantics are already stable.

### Official ArkWeb Abilities To Prefer

- `runJavaScript()`
- `runJavaScriptExt()`
- `registerJavaScriptProxy()`
- `deleteJavaScriptRegister()`
- official proxy lifecycle and permission restrictions

### Design Guidance

This layer should not copy the iPadOS bridge shape.

Instead it should define a HarmonyOS-native substrate for:

- session-level bridge registration
- optional global bridge or script registration
- message envelope design
- permission gating
- lifecycle-safe install and uninstall

### Completion Criteria

- JavaScript execution is contract-stable
- proxy registration and deregistration follow session lifecycle
- message routing no longer depends on ad-hoc ArkWeb glue
- future browser features can consume one unified bridge surface

### Primary Risk

If bridge work starts before lifecycle and resource surfaces are stable, the bridge layer will inherit unstable assumptions and become expensive to rework.

## Phase 5: Browser-Critical Extensions

### Objective

Add important browser-facing capabilities that should sit on top of the stable engine foundation, not define it.

### Typical Capabilities In This Phase

- session restore and save-state
- find-in-page
- zoom and scroll APIs
- content extraction
- diagnostics and devtools hooks
- preload and warmup helpers
- more advanced download continuation or retry integration

### Completion Criteria

- extensions plug into the stable contract without rewriting earlier phases
- browser shell work can begin on top of the engine with reduced contract churn

### Primary Risk

These capabilities are useful and visible, but if they are done too early they will force premature expansion of the core contract.

## Why HarmonyOS Needs This Order

HarmonyOS has a different risk profile from the iPadOS implementation:

- more behavior is exposed through ArkWeb controller, component, and manager APIs
- lifecycle and host-binding semantics need more explicit control
- it is easier for ArkWeb implementation details to leak into app code
- resource and privacy operations are too sensitive to re-implement casually

Because of that, the first priority is not “feature completeness.”

The first priority is:

`capture official ArkWeb behavior inside a stable HarmonyOS-native contract`

Only after that should browser features rely on the engine.

## Acceptance Criteria For The Overall Direction

This development order is successful only if all of the following become true:

- higher layers do not directly depend on ArkWeb implementation types
- public contracts are no longer rewritten every time a new ArkWeb capability is wired
- resource and privacy operations follow ArkWeb official semantics
- bridge and script capabilities are built on top of a stable session lifecycle
- later browser work can depend on the engine without needing a second contract reset

## Recommended Next Step

The next document should be an implementation plan derived from this design.

That plan should:

- define the concrete contract changes introduced in Phase 1
- identify exact files to create, split, or replace
- sequence the work so each phase has verifiable stopping points
- separate breaking contract cleanup from runtime capability wiring
