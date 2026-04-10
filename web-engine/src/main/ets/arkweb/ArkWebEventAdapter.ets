import { SessionStateStore } from '../internal/SessionStateStore';

export interface WebControllerStateSnapshot {
  title: string;
  currentUrl: string | null;
  canGoBack: boolean;
  canGoForward: boolean;
}

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

export function applyControllerStateSnapshot(store: SessionStateStore, snapshot: WebControllerStateSnapshot): void {
  store.update((draft) => {
    draft.title = snapshot.title;
    draft.canGoBack = snapshot.canGoBack;
    draft.canGoForward = snapshot.canGoForward;
    if (snapshot.currentUrl !== null && snapshot.currentUrl.length > 0) {
      draft.currentUrl = snapshot.currentUrl;
    }
  });
}

export function applyLoadFinished(store: SessionStateStore): void {
  store.update((draft) => {
    draft.isLoading = false;
    draft.progress = 100;
  });
}
