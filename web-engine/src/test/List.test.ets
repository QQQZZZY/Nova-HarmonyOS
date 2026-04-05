import webSessionStateStoreTest from './WebSessionStateStore.test';
import webDataServiceTest from './WebDataService.test';
import bridgePolicyTest from './BridgePolicy.test';

export default function testsuite() {
  webSessionStateStoreTest();
  webDataServiceTest();
  bridgePolicyTest();
}
