import { describe, it, expect } from '@ohos/hypium';
import { WebScriptRegistration } from '../main/ets/public/types/WebScriptTypes';
import { ArkWebBridgeRuntime } from '../main/ets/arkweb/ArkWebBridgeRuntime';

export default function arkWebBridgeRuntimeTest() {
  describe('ArkWebBridgeRuntime', () => {
    it('should return a stable registration when a session-scoped bridge is installed', 0, () => {
      const runtime = new ArkWebBridgeRuntime();
      const registration: WebScriptRegistration = runtime.createRegistration('historyBridge', true);
      expect(registration.name).assertEqual('historyBridge');
      expect(registration.sessionScoped).assertTrue();
    });
  });
}
