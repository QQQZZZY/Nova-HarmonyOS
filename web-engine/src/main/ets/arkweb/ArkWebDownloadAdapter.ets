import { WebDownloadDecision, WebDownloadDecisionType, WebDownloadRequest, WebDownloadSnapshot, WebDownloadStatus } from '../public/types/WebDownloadTypes';
import type { WebSession } from '../public/WebSession';
import type { WebSessionRequestHandler } from '../public/WebSessionRequestHandler';

export function createDownloadSnapshot(
  id: string,
  url: string,
  suggestedFilename: string,
  mimeType: string,
  totalBytes: number
): WebDownloadSnapshot {
  const snapshot = new WebDownloadSnapshot();
  snapshot.id = id;
  snapshot.url = url;
  snapshot.suggestedFilename = suggestedFilename;
  snapshot.mimeType = mimeType;
  snapshot.totalBytes = totalBytes;
  snapshot.status = WebDownloadStatus.PENDING;
  return snapshot;
}

export function markDownloadProgress(snapshot: WebDownloadSnapshot, receivedBytes: number): WebDownloadSnapshot {
  const next = new WebDownloadSnapshot();
  next.id = snapshot.id;
  next.url = snapshot.url;
  next.suggestedFilename = snapshot.suggestedFilename;
  next.mimeType = snapshot.mimeType;
  next.totalBytes = snapshot.totalBytes;
  next.receivedBytes = receivedBytes;
  next.status = WebDownloadStatus.IN_PROGRESS;
  next.progress = snapshot.totalBytes <= 0 ? 0 : Math.floor(receivedBytes * 100 / snapshot.totalBytes);
  return next;
}

export function markDownloadFinished(snapshot: WebDownloadSnapshot): WebDownloadSnapshot {
  const next = markDownloadProgress(snapshot, snapshot.totalBytes > 0 ? snapshot.totalBytes : snapshot.receivedBytes);
  next.status = WebDownloadStatus.FINISHED;
  next.progress = 100;
  return next;
}

export async function resolveDownloadDecision(
  session: WebSession,
  handler: WebSessionRequestHandler | null,
  url: string,
  suggestedFilename: string,
  mimeType: string,
  contentLength: number
): Promise<WebDownloadDecision> {
  if (handler === null) {
    const decision = new WebDownloadDecision();
    decision.type = WebDownloadDecisionType.ALLOW;
    return decision;
  }

  const request = new WebDownloadRequest();
  request.url = url;
  request.suggestedFilename = suggestedFilename;
  request.mimeType = mimeType;
  request.contentLength = contentLength;
  return await handler.onDownloadRequest(session, request);
}
