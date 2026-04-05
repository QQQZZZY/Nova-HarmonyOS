import { WebPopupDecision, WebPopupRequest } from '../public/types/WebPopupTypes';
import type { WebSessionRequestHandler } from '../public/WebSessionRequestHandler';
import type { WebSession } from '../public/WebSession';

export async function resolvePopupDecision(
  handler: WebSessionRequestHandler | null,
  targetUrl: string,
  sourceUrl: string,
  isUserGesture: boolean,
  session: WebSession | null = null
): Promise<WebPopupDecision> {
  if (handler === null || session === null) {
    return WebPopupDecision.REJECT;
  }
  const request = new WebPopupRequest();
  request.targetUrl = targetUrl;
  request.sourceUrl = sourceUrl;
  request.isUserGesture = isUserGesture;
  return await handler.onPopupRequest(session, request);
}
