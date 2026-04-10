import publicContractTest from './PublicContract.test';
import webSessionStateStoreTest from './WebSessionStateStore.test';
import webDataServiceTest from './WebDataService.test';
import arkWebDataManagerTest from './ArkWebDataManager.test';
import bridgePolicyTest from './BridgePolicy.test';
import arkWebEventAdapterTest from './ArkWebEventAdapter.test';
import arkWebSessionLifecycleTest from './ArkWebSessionLifecycle.test';
import arkWebRequestSurfaceTest from './ArkWebRequestSurface.test';
import arkWebBridgeRuntimeTest from './ArkWebBridgeRuntime.test';
import arkWebSessionExtensionsTest from './ArkWebSessionExtensions.test';
import arkWebPopupAdapterTest from './ArkWebPopupAdapter.test';
import arkWebDownloadAdapterTest from './ArkWebDownloadAdapter.test';

export default function testsuite() {
  publicContractTest();
  webSessionStateStoreTest();
  webDataServiceTest();
  arkWebDataManagerTest();
  bridgePolicyTest();
  arkWebEventAdapterTest();
  arkWebSessionLifecycleTest();
  arkWebRequestSurfaceTest();
  arkWebBridgeRuntimeTest();
  arkWebSessionExtensionsTest();
  arkWebPopupAdapterTest();
  arkWebDownloadAdapterTest();
}
