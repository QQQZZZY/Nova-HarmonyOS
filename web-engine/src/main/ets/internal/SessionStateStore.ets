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
