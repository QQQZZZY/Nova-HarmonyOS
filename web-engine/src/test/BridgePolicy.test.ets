import { describe, it, expect } from '@ohos/hypium';
import { WebBridgeConfig, WebBridgeDefinition, WebBridgeMethod, WebBridgePermissionRule } from '../main/ets/public/types/WebBridgeTypes';
import { buildBridgePermissionJson } from '../main/ets/policy/BridgePolicy';

export default function bridgePolicyTest() {
  describe('BridgePolicy', () => {
    it('should generate ArkWeb permission json for object and method rules', 0, () => {
      const objectRule = new WebBridgePermissionRule();
      objectRule.scheme = 'https';
      objectRule.host = 'example.com';

      const methodRule = new WebBridgePermissionRule();
      methodRule.scheme = 'resource';
      methodRule.host = 'rawfile';

      const method = new WebBridgeMethod();
      method.name = 'invoke';
      method.rules = [methodRule];

      const definition = new WebBridgeDefinition();
      definition.name = 'novaBridge';
      definition.objectRules = [objectRule];
      definition.methods = [method];

      const config = new WebBridgeConfig();
      config.definitions = [definition];

      const json = buildBridgePermissionJson(config.definitions[0]);
      expect(json).assertContain('javascriptProxyPermission');
      expect(json).assertContain('example.com');
      expect(json).assertContain('invoke');
      expect(json).assertContain('rawfile');
    });
  });
}
