import { describe, it, expect } from '@ohos/hypium';
import { createDefaultWebSessionState, createDefaultSessionCapabilities } from '../main/ets/public/types/WebSessionState';
import { SessionStateStore } from '../main/ets/internal/SessionStateStore';

export default function webSessionStateStoreTest() {
  describe('WebSessionStateDefaults', () => {
    it('should create a safe default state snapshot', 0, () => {
      const state = createDefaultWebSessionState(false);
      expect(state.currentUrl).assertNull();
      expect(state.lastCommittedUrl).assertNull();
      expect(state.title).assertEqual('');
      expect(state.isLoading).assertFalse();
      expect(state.progress).assertEqual(0);
      expect(state.canGoBack).assertFalse();
      expect(state.canGoForward).assertFalse();
      expect(state.isAttached).assertFalse();
      expect(state.isVisible).assertFalse();
      expect(state.isPrivate).assertFalse();
    });

    it('should create capabilities that expose only V1-supported features', 0, () => {
      const capabilities = createDefaultSessionCapabilities();
      expect(capabilities.supportsJavaScriptBridge).assertTrue();
      expect(capabilities.supportsFileChooser).assertTrue();
      expect(capabilities.supportsDownloadControl).assertTrue();
      expect(capabilities.supportsDownloadResume).assertTrue();
      expect(capabilities.supportsStateRestore).assertFalse();
      expect(capabilities.supportsFindInPage).assertFalse();
    });

    it('should update state snapshots immutably', 0, () => {
      const store = new SessionStateStore(false);
      const initial = store.getState();
      store.update((draft) => {
        draft.title = 'Nova';
        draft.progress = 42;
        draft.isLoading = true;
      });
      const next = store.getState();
      expect(initial === next).assertFalse();
      expect(next.title).assertEqual('Nova');
      expect(next.progress).assertEqual(42);
      expect(next.isLoading).assertTrue();
    });
  });
}
