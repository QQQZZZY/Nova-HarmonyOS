import { describe, it, expect } from '@ohos/hypium';
import { createArkWebEngine, WebSessionCapabilities, WebSessionOptions } from '../../Index';

export default function arkWebSessionExtensionsTest() {
  describe('ArkWebSessionExtensions', () => {
    it('should expose extension capability flags without changing the core session contract again', 0, async () => {
      const capabilities = new WebSessionCapabilities();
      const session = createArkWebEngine().createSession(new WebSessionOptions());
      const savedState: ArrayBuffer | null = await session.saveState();

      expect(capabilities.supportsFindInPage).assertFalse();
      expect(capabilities.supportsStateRestore).assertFalse();
      expect(savedState).assertNull();

      await session.showFindInPage();
      await session.restoreState(new ArrayBuffer(0));
    });
  });
}
