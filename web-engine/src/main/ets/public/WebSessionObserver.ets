import { WebSessionState } from './types/WebSessionState';
import { WebDownloadEvent } from './types/WebDownloadTypes';
import { WebBridgeMessage } from './types/WebBridgeTypes';
import { WebSessionError } from './types/WebErrors';
import type { WebSession } from './WebSession';

export interface WebEngineHealthEvent {
  kind: string;
  detail: string;
}

export interface WebSessionObserver {
  onStateChanged(session: WebSession, state: WebSessionState): void;
  onDownloadEvent(session: WebSession, event: WebDownloadEvent): void;
  onBridgeMessage(session: WebSession, message: WebBridgeMessage): void;
  onEngineHealthEvent(session: WebSession, event: WebEngineHealthEvent): void;
  onSessionError(session: WebSession, error: WebSessionError): void;
}
