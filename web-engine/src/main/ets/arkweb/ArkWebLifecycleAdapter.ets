import { SessionStateStore } from '../internal/SessionStateStore';

export interface ControllerLifecycleSnapshot {
  attached: boolean;
  visible: boolean;
  loading: boolean;
  currentUrl?: string | null;
  lastCommittedUrl?: string | null;
  title: string;
  canGoBack: boolean;
  canGoForward: boolean;
  progress?: number;
}

export function applyControllerLifecycleSnapshot(
  store: SessionStateStore,
  snapshot: ControllerLifecycleSnapshot
): void {
  store.update((draft) => {
    draft.isAttached = snapshot.attached;
    draft.isVisible = snapshot.visible;
    draft.isLoading = snapshot.loading;
    draft.title = snapshot.title;
    draft.canGoBack = snapshot.canGoBack;
    draft.canGoForward = snapshot.canGoForward;

    if (snapshot.progress !== undefined) {
      draft.progress = snapshot.progress;
    }

    if (snapshot.currentUrl !== undefined && snapshot.currentUrl !== null && snapshot.currentUrl.length > 0) {
      draft.currentUrl = snapshot.currentUrl;
    }

    if (snapshot.lastCommittedUrl !== undefined &&
      snapshot.lastCommittedUrl !== null &&
      snapshot.lastCommittedUrl.length > 0) {
      draft.lastCommittedUrl = snapshot.lastCommittedUrl;
    } else if (snapshot.currentUrl !== undefined && snapshot.currentUrl !== null && snapshot.currentUrl.length > 0) {
      draft.lastCommittedUrl = snapshot.currentUrl;
    }
  });
}
