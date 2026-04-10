import { describe, it, expect } from '@ohos/hypium';
import { SessionStateStore } from '../main/ets/internal/SessionStateStore';
import {
  applyControllerStateSnapshot,
  applyNavigationCommitted,
  applyLoadStarted,
  applyLoadFinished
} from '../main/ets/arkweb/ArkWebEventAdapter';

export default function arkWebEventAdapterTest() {
  describe('ArkWebEventAdapter', () => {
    it('should map start commit finish into state transitions', 0, () => {
      const store = new SessionStateStore(false);
      applyLoadStarted(store);
      applyNavigationCommitted(store, 'https://example.com');
      applyControllerStateSnapshot(store, {
        title: 'Nova',
        currentUrl: 'https://example.com',
        canGoBack: true,
        canGoForward: false
      });
      applyLoadFinished(store);
      const state = store.getState();
      expect(state.isLoading).assertFalse();
      expect(state.lastCommittedUrl).assertEqual('https://example.com');
      expect(state.currentUrl).assertEqual('https://example.com');
      expect(state.title).assertEqual('Nova');
      expect(state.progress).assertEqual(100);
      expect(state.canGoBack).assertTrue();
      expect(state.canGoForward).assertFalse();
    });
  });
}
