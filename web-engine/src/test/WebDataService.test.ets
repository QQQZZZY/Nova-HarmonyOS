import { describe, it, expect } from '@ohos/hypium';
import { WebDataClearOptions, WebDataScope } from '../main/ets/public/types/WebDataTypes';
import { mapDataClearPlan } from '../main/ets/data/WebDataService';

export default function webDataServiceTest() {
  describe('WebDataServicePlan', () => {
    it('should map data clear options into deterministic operations', 0, () => {
      const options = new WebDataClearOptions();
      options.clearCookies = true;
      options.clearWebStorage = true;
      options.clearMemoryCache = true;
      options.clearDiskCache = true;
      options.clearSslState = true;
      options.clearClientAuthState = true;
      options.target = WebDataScope.BOTH;

      const plan = mapDataClearPlan(options);
      expect(plan.clearCookies).assertTrue();
      expect(plan.clearWebStorage).assertTrue();
      expect(plan.clearCache).assertTrue();
      expect(plan.clearRom).assertTrue();
      expect(plan.clearSslState).assertTrue();
      expect(plan.clearClientAuthState).assertTrue();
      expect(plan.privateMode).assertFalse();
      expect(plan.bothModes).assertTrue();
    });
  });
}
