import { describe, it, expect } from '@ohos/hypium';
import { WebPopupDecision } from '../main/ets/public/types/WebPopupTypes';
import { resolvePopupDecision } from '../main/ets/arkweb/ArkWebPopupAdapter';

export default function arkWebPopupAdapterTest() {
  describe('ArkWebPopupAdapter', () => {
    it('should default to reject when no request handler exists', 0, async () => {
      const decision = await resolvePopupDecision(null, 'https://target.example', 'https://source.example', false);
      expect(decision).assertEqual(WebPopupDecision.REJECT);
    });
  });
}
