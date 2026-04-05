import { Web } from '@kit.ArkUI';
import { ArkWebSession } from '../arkweb/ArkWebSession';
import { applyLoadFinished, applyLoadStarted, applyNavigationCommitted } from '../arkweb/ArkWebEventAdapter';
import type { WebSession } from './WebSession';

@Component
export struct WebSessionHost {
  session: WebSession;

  build() {
    const arkSession = this.session as ArkWebSession;
    const binding = arkSession.getBinding();
    const initialUrl = arkSession.getInitialUrl() ?? 'https://www.example.com';

    Column() {
      Web({ src: initialUrl, controller: binding.controller, incognitoMode: arkSession.getState().isPrivate })
        .onControllerAttached(() => {
          binding.markAttached();
          arkSession.handleAttached();
        })
        .onLoadStarted(() => {
          applyLoadStarted(arkSession.getStateStore());
          arkSession.emitStateChanged();
        })
        .onNavigationEntryCommitted((event) => {
          applyNavigationCommitted(arkSession.getStateStore(), event.url.getRawFile());
          arkSession.emitStateChanged();
        })
        .onLoadFinished(() => {
          applyLoadFinished(arkSession.getStateStore(), arkSession.getState().title);
          arkSession.emitStateChanged();
        })
    }
    .height('100%')
    .width('100%')
  }
}
