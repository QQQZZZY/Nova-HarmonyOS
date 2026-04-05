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
