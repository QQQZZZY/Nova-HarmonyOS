import { WebSessionState, createDefaultWebSessionState } from '../public/types/WebSessionState';

export class SessionStateStore {
  private state: WebSessionState;

  constructor(isPrivate: boolean) {
    this.state = createDefaultWebSessionState(isPrivate);
  }

  getState(): WebSessionState {
    return this.cloneState(this.state);
  }

  update(mutator: (draft: WebSessionState) => void): WebSessionState {
    const draft = this.cloneState(this.state);
    mutator(draft);
    this.state = draft;
    return this.cloneState(this.state);
  }

  private cloneState(source: WebSessionState): WebSessionState {
    const snapshot = new WebSessionState();
    snapshot.currentUrl = source.currentUrl;
    snapshot.lastCommittedUrl = source.lastCommittedUrl;
    snapshot.title = source.title;
    snapshot.isLoading = source.isLoading;
    snapshot.progress = source.progress;
    snapshot.canGoBack = source.canGoBack;
    snapshot.canGoForward = source.canGoForward;
    snapshot.isAttached = source.isAttached;
    snapshot.isVisible = source.isVisible;
    snapshot.isPrivate = source.isPrivate;
    snapshot.securityState = source.securityState;
    return snapshot;
  }
}
