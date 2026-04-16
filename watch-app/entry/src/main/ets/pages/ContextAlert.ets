/**
 * ContextAlert.ets — Full-screen cultural/legal alert pushed by TripHome's GPS pipeline.
 * Risk levels: NORM (cyan), SENSITIVE (amber), LEGAL (red).
 */
import router from '@ohos.router';
import { ContextAlert, riskColor, riskLabel } from '../common/Types';

@Entry
@Component
struct ContextAlertPage {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private alert: ContextAlert = JSON.parse(this.params['alertJson'] ?? '{}') as ContextAlert;
  private countryName: string = this.params['countryName'] ?? '';

  private get bgColor(): string {
    if (this.alert.riskLevel === 'LEGAL')     return '#1A0000';
    if (this.alert.riskLevel === 'SENSITIVE') return '#1A1200';
    return '#0D1117';
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

      // Dismiss button
      Button('Got It')
        .onClick(() => router.back())
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
    .backgroundColor(this.bgColor)
    .gesture(
      PanGesture({ direction: PanDirection.Right, distance: 50 })
        .onActionEnd(() => router.back())
    )
  }
}
