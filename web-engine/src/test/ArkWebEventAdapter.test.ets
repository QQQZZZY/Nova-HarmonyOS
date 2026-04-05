import { describe, it, expect } from '@ohos/hypium';
import { SessionStateStore } from '../main/ets/internal/SessionStateStore';
import { applyNavigationCommitted, applyLoadStarted, applyLoadFinished } from '../main/ets/arkweb/ArkWebEventAdapter';

export default function arkWebEventAdapterTest() {
  describe('ArkWebEventAdapter', () => {
    it('should map start commit finish into state transitions', 0, () => {
      const store = new SessionStateStore(false);
      applyLoadStarted(store);
      applyNavigationCommitted(store, 'https://example.com');
      applyLoadFinished(store, 'Nova');
      const state = store.getState();
      expect(state.isLoading).assertFalse();
      expect(state.lastCommittedUrl).assertEqual('https://example.com');
      expect(state.currentUrl).assertEqual('https://example.com');
      expect(state.title).assertEqual('Nova');
      expect(state.progress).assertEqual(100);
    });
  });
}
