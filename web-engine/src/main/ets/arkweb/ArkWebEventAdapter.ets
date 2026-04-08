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
