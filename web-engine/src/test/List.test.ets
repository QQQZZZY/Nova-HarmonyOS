import webSessionStateStoreTest from './WebSessionStateStore.test';
import webDataServiceTest from './WebDataService.test';
import bridgePolicyTest from './BridgePolicy.test';
import arkWebEventAdapterTest from './ArkWebEventAdapter.test';
import arkWebPopupAdapterTest from './ArkWebPopupAdapter.test';
import arkWebDownloadAdapterTest from './ArkWebDownloadAdapter.test';

export default function testsuite() {
  webSessionStateStoreTest();
  webDataServiceTest();
  bridgePolicyTest();
  arkWebEventAdapterTest();
  arkWebPopupAdapterTest();
  arkWebDownloadAdapterTest();
}
