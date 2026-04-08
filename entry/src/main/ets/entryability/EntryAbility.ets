import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { createArkWebEngine } from 'web-engine';

const webEngine = createArkWebEngine();

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    void want;
    void launchParam;
  }

  onForeground(): void {
    webEngine.notifyAppForeground();
  }

  onBackground(): void {
    webEngine.notifyAppBackground();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        return;
      }
    });
  }
}
