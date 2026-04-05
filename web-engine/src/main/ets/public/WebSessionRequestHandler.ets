import { WebNavigationRequest, WebNavigationDecision } from './types/WebNavigationTypes';
import { WebPermissionRequest, WebPermissionDecision } from './types/WebPermissionTypes';
import { WebDialogRequest, WebDialogResult } from './types/WebDialogTypes';
import { WebPopupRequest, WebPopupDecision } from './types/WebPopupTypes';
import { WebFileChooserRequest, WebFileChooserResult } from './types/WebFileChooserTypes';
import { WebDownloadRequest, WebDownloadDecision } from './types/WebDownloadTypes';
import type { WebSession } from './WebSession';

export interface WebSessionRequestHandler {
  onNavigationRequest(session: WebSession, request: WebNavigationRequest): Promise<WebNavigationDecision>;
  onPermissionRequest(session: WebSession, request: WebPermissionRequest): Promise<WebPermissionDecision>;
  onDialogRequest(session: WebSession, request: WebDialogRequest): Promise<WebDialogResult>;
  onPopupRequest(session: WebSession, request: WebPopupRequest): Promise<WebPopupDecision>;
  onFileChooserRequest(session: WebSession, request: WebFileChooserRequest): Promise<WebFileChooserResult>;
  onDownloadRequest(session: WebSession, request: WebDownloadRequest): Promise<WebDownloadDecision>;
}
