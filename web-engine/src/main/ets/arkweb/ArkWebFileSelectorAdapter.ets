import { WebFileChooserRequest, WebFileChooserResult } from '../public/types/WebFileChooserTypes';
import type { WebSession } from '../public/WebSession';
import type { WebSessionRequestHandler } from '../public/WebSessionRequestHandler';

export async function resolveFileChooserRequest(
  session: WebSession,
  handler: WebSessionRequestHandler | null,
  title: string,
  mode: number,
  acceptTypes: Array<string>,
  capture: boolean
): Promise<WebFileChooserResult> {
  if (handler === null) {
    const result = new WebFileChooserResult();
    result.useDefaultChooser = true;
    return result;
  }
  const request = new WebFileChooserRequest();
  request.title = title;
  request.mode = mode;
  request.acceptTypes = acceptTypes;
  request.capture = capture;
  return await handler.onFileChooserRequest(session, request);
}
