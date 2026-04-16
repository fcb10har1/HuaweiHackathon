/**
 * ContextAlert.ets — Full-screen cultural/legal alert pushed by TripHome's GPS pipeline.
 * Risk levels: NORM (cyan), SENSITIVE (amber), LEGAL (red).
 * SENSITIVE and LEGAL alerts are saved to storage on dismiss so they appear in AlertsList.
 */
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { ContextAlert, riskColor, riskLabel } from '../common/Types';
import { StorageService } from '../services/StorageService';

@Entry
@Component
struct ContextAlertPage {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private alert: ContextAlert = JSON.parse(this.params['alertJson'] ?? '{}') as ContextAlert;
  private countryName: string = this.params['countryName'] ?? '';
  private countryCode: string = this.params['countryCode'] ?? '';

  private storage: StorageService | null = null;

  aboutToAppear(): void {
    this.storage = new StorageService(getContext(this) as common.UIAbilityContext);
  }

  private dismiss(): void {
    // Persist SENSITIVE and LEGAL alerts so they appear in the Alerts list
    if (this.countryCode && (this.alert.riskLevel === 'SENSITIVE' || this.alert.riskLevel === 'LEGAL')) {
      this.storage?.saveTriggeredAlert(this.countryCode, this.alert);
    }
    router.back();
  }

  build() {
    Column({ space: 12 }) {
      // ── Risk badge ───────────────────────────────────────────────────────────
      Text(riskLabel(this.alert.riskLevel))
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(riskColor(this.alert.riskLevel))

      // Location name (if available)
      if (this.alert.locationName) {
        Text(this.alert.locationName.toUpperCase())
          .fontSize(9)
          .fontColor('#8B949E')
          .letterSpacing(1.5)
      }

      Divider()
        .color(riskColor(this.alert.riskLevel))
        .width('60%')
        .strokeWidth(2)

      // Alert message
      Scroll() {
        Text(this.alert.message)
          .fontSize(11)
          .fontColor('#E6EDF3')
          .textAlign(TextAlign.Center)
          .width('88%')
          .lineHeight(18)
          .padding({ left: 8, right: 8 })
      }
      .height(110)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .friction(35.0)

      // Dismiss button
      Button('Got It')
        .onClick(() => this.dismiss())
        .backgroundColor('#21262D')
        .fontColor('#8B949E')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .width('65%')
        .margin({ bottom: 14 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(
      this.alert.riskLevel === 'LEGAL'     ? '#1A0000' :
      this.alert.riskLevel === 'SENSITIVE' ? '#1A1200' :
      '#0D1117'
    )
    .gesture(
      PanGesture({ direction: PanDirection.Right, distance: 50 })
        .onActionEnd(() => this.dismiss())
    )
  }
}
