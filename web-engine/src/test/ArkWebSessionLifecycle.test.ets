import { describe, it, expect } from '@ohos/hypium';
import { SessionStateStore } from '../main/ets/internal/SessionStateStore';
import { applyControllerLifecycleSnapshot } from '../main/ets/arkweb/ArkWebLifecycleAdapter';

export default function arkWebSessionLifecycleTest() {
  describe('ArkWebSessionLifecycle', () => {
    it('should synchronize attach visibility and navigation state from one lifecycle snapshot', 0, () => {
      const store = new SessionStateStore(false);

      applyControllerLifecycleSnapshot(store, {
        attached: true,
        visible: true,
        loading: true,
        currentUrl: 'https://example.com',
        title: 'Example',
        canGoBack: false,
        canGoForward: true
      });

      const state = store.getState();
      expect(state.isAttached).assertTrue();
      expect(state.isVisible).assertTrue();
      expect(state.isLoading).assertTrue();
      expect(state.progress).assertEqual(0);
      expect(state.currentUrl).assertEqual('https://example.com');
      expect(state.lastCommittedUrl).assertEqual('https://example.com');
      expect(state.title).assertEqual('Example');
      expect(state.canGoBack).assertFalse();
      expect(state.canGoForward).assertTrue();
    });
  });
}
