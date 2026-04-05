import webSessionStateStoreTest from './WebSessionStateStore.test';
import webDataServiceTest from './WebDataService.test';
import bridgePolicyTest from './BridgePolicy.test';
import arkWebEventAdapterTest from './ArkWebEventAdapter.test';
import arkWebPopupAdapterTest from './ArkWebPopupAdapter.test';

export default function testsuite() {
  webSessionStateStoreTest();
  webDataServiceTest();
  bridgePolicyTest();
  arkWebEventAdapterTest();
  arkWebPopupAdapterTest();
}
