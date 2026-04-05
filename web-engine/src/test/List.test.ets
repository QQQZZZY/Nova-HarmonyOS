import webSessionStateStoreTest from './WebSessionStateStore.test';
import webDataServiceTest from './WebDataService.test';
import bridgePolicyTest from './BridgePolicy.test';
import arkWebEventAdapterTest from './ArkWebEventAdapter.test';

export default function testsuite() {
  webSessionStateStoreTest();
  webDataServiceTest();
  bridgePolicyTest();
  arkWebEventAdapterTest();
}
