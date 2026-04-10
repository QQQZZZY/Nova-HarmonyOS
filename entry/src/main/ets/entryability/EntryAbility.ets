import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { createArkWebEngine } from 'web-engine';

export const appWebEngine = createArkWebEngine();

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    void want;
    void launchParam;
  }

  onForeground(): void {
    appWebEngine.notifyAppForeground();
  }

  onBackground(): void {
    appWebEngine.notifyAppBackground();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        return;
      }
    });
  }
}
