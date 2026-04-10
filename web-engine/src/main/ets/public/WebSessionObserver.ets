import { WebSessionState } from './types/WebSessionState';
import { WebDownloadEvent } from './types/WebDownloadTypes';
import { WebSessionError } from './types/WebErrors';
import type { WebSession } from './WebSession';

export interface WebEngineHealthEvent {
  kind: string;
  detail: string;
}

export interface WebSessionObserver {
  onStateChanged(session: WebSession, state: WebSessionState): void;
  onDownloadEvent(session: WebSession, event: WebDownloadEvent): void;
  onSessionError(session: WebSession, error: WebSessionError): void;
}
