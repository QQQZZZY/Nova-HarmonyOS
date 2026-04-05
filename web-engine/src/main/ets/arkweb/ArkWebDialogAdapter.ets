import { WebDialogRequest, WebDialogResult, WebDialogType } from '../public/types/WebDialogTypes';
import type { WebSession } from '../public/WebSession';
import type { WebSessionRequestHandler } from '../public/WebSessionRequestHandler';

export async function resolveDialogRequest(
  session: WebSession,
  handler: WebSessionRequestHandler | null,
  type: WebDialogType,
  message: string,
  sourceUrl: string,
  defaultValue: string = ''
): Promise<WebDialogResult> {
  if (handler === null) {
    return new WebDialogResult();
  }
  const request = new WebDialogRequest();
  request.type = type;
  request.message = message;
  request.sourceUrl = sourceUrl;
  request.defaultValue = defaultValue;
  return await handler.onDialogRequest(session, request);
}
