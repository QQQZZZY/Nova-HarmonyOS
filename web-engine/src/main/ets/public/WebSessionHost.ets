import { ArkWebSession } from '../arkweb/ArkWebSession';
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
        .onLoadStarted(() => {
          const arkSession = this.getArkSession();
          arkSession.handleLoadStarted();
        })
        .onNavigationEntryCommitted((event: LoadCommittedDetails) => {
          const arkSession = this.getArkSession();
          arkSession.handleNavigationCommitted(event.url);
        })
        .onLoadFinished(() => {
          const arkSession = this.getArkSession();
          arkSession.handleLoadFinished();
        })
    }
    .height('100%')
    .width('100%')
  }
}
