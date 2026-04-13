/**
 * EntryAbility.ets
 * Requests runtime permissions on first launch.
 * No phone/WearEngine communication — the watch app is fully standalone.
 */
import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';

const DOMAIN = 0x0000;

const REQUIRED_PERMISSIONS: Permissions[] = [
  'ohos.permission.LOCATION',
  'ohos.permission.APPROXIMATELY_LOCATION',
  'ohos.permission.MICROPHONE',
];

export default class EntryAbility extends UIAbility {

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'ArrivalRitual', 'Failed to set colorMode: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'ArrivalRitual', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'ArrivalRitual', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'ArrivalRitual', 'Ability onWindowStageCreate');

    // Request runtime permissions
    const atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(this.context, REQUIRED_PERMISSIONS).then(() => {
      hilog.info(DOMAIN, 'ArrivalRitual', 'Permissions granted');
    }).catch((err: Error) => {
      hilog.warn(DOMAIN, 'ArrivalRitual', 'Permission request failed: %{public}s', err.message);
    });

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'ArrivalRitual', 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'ArrivalRitual', 'Content loaded successfully');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'ArrivalRitual', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'ArrivalRitual', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'ArrivalRitual', 'Ability onBackground');
  }
}
