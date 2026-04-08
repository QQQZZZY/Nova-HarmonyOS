import { ArkWebSession } from '../arkweb/ArkWebSession';
import { applyLoadFinished, applyLoadStarted, applyNavigationCommitted } from '../arkweb/ArkWebEventAdapter';
import type { WebSession } from './WebSession';

@Component
export struct WebSessionHost {
  @Require @Prop session: WebSession;

  private getArkSession(): ArkWebSession {
    return this.session as ArkWebSession;
  }

  private getInitialUrl(): string {
    return this.getArkSession().getInitialUrl() ?? 'https://www.example.com';
  }

  build() {
    Column() {
      Web({
        src: this.getInitialUrl(),
        controller: this.getArkSession().getBinding().controller,
        incognitoMode: this.getArkSession().getState().isPrivate
      })
        .onControllerAttached(() => {
          const arkSession = this.getArkSession();
          const binding = arkSession.getBinding();
          binding.markAttached();
          arkSession.handleAttached();
        })
        .onLoadStarted(() => {
          const arkSession = this.getArkSession();
          applyLoadStarted(arkSession.getStateStore());
          arkSession.emitStateChanged();
        })
        .onNavigationEntryCommitted((event: LoadCommittedDetails) => {
          const arkSession = this.getArkSession();
          applyNavigationCommitted(arkSession.getStateStore(), event.url);
          arkSession.emitStateChanged();
        })
        .onLoadFinished(() => {
          const arkSession = this.getArkSession();
          applyLoadFinished(arkSession.getStateStore(), arkSession.getState().title);
          arkSession.emitStateChanged();
        })
    }
    .height('100%')
    .width('100%')
  }
}
