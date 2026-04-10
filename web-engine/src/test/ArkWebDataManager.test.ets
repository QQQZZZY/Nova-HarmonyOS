import { describe, it, expect } from '@ohos/hypium';
import { WebDataClearOptions, WebDataScope } from '../main/ets/public/types/WebDataTypes';
import { mapOfficialDataActions } from '../main/ets/arkweb/ArkWebDataManager';

export default function arkWebDataManagerTest() {
  describe('ArkWebDataManager', () => {
    it('should map clear options to official ArkWeb resource operations', 0, () => {
      const options = new WebDataClearOptions();
      options.clearCookies = true;
      options.clearMemoryCache = true;
      options.clearDiskCache = true;
      options.clearSslState = true;
      options.clearClientAuthState = true;
      options.target = WebDataScope.BOTH;

      const plan = mapOfficialDataActions(options);
      expect(plan.clearCookies).assertTrue();
      expect(plan.clearCache).assertTrue();
      expect(plan.clearSslState).assertTrue();
      expect(plan.clearClientAuthState).assertTrue();
      expect(plan.bothModes).assertTrue();
    });
  });
}
