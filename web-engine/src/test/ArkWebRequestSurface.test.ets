import { describe, it, expect } from '@ohos/hypium';
import { createArkWebEngine, WebSessionOptions } from '../../Index';
import { WebPopupDecision } from '../main/ets/public/types/WebPopupTypes';
import { WebPermissionDecision, WebPermissionKind } from '../main/ets/public/types/WebPermissionTypes';
import { WebDownloadDecisionType } from '../main/ets/public/types/WebDownloadTypes';
import { resolvePermissionRequest } from '../main/ets/arkweb/ArkWebPermissionAdapter';
import { resolvePopupDecision } from '../main/ets/arkweb/ArkWebPopupAdapter';
import { resolveDownloadDecision } from '../main/ets/arkweb/ArkWebDownloadAdapter';

export default function arkWebRequestSurfaceTest() {
  describe('ArkWebRequestSurface', () => {
    it('should reject popup requests when no session-aware handler is present', 0, async () => {
      const decision = await resolvePopupDecision(null, 'https://example.com', 'https://source.com', true, null);
      expect(decision).assertEqual(WebPopupDecision.REJECT);
    });

    it('should deny permission requests when no request handler exists', 0, async () => {
      const session = createArkWebEngine().createSession(new WebSessionOptions());
      const decision = await resolvePermissionRequest(
        session,
        null,
        WebPermissionKind.CAMERA,
        'https://example.com',
        'camera',
        ['camera']
      );
      expect(decision).assertEqual(WebPermissionDecision.DENY);
    });

    it('should allow default download handling when no request handler exists', 0, async () => {
      const session = createArkWebEngine().createSession(new WebSessionOptions());
      const decision = await resolveDownloadDecision(
        session,
        null,
        'https://example.com/file.txt',
        'file.txt',
        'text/plain',
        128
      );
      expect(decision.type).assertEqual(WebDownloadDecisionType.ALLOW);
    });
  });
}
