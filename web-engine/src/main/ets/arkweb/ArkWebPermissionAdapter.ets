import { WebPermissionDecision, WebPermissionKind, WebPermissionRequest } from '../public/types/WebPermissionTypes';
import type { WebSession } from '../public/WebSession';
import type { WebSessionRequestHandler } from '../public/WebSessionRequestHandler';

export async function resolvePermissionRequest(
  session: WebSession,
  handler: WebSessionRequestHandler | null,
  kind: WebPermissionKind,
  origin: string,
  rawSourceType: string,
  resources: Array<string>
): Promise<WebPermissionDecision> {
  if (handler === null) {
    return WebPermissionDecision.DENY;
  }
  const request = new WebPermissionRequest();
  request.kind = kind;
  request.origin = origin;
  request.rawSourceType = rawSourceType;
  request.resources = resources;
  return await handler.onPermissionRequest(session, request);
}
