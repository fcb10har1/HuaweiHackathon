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
    if (this.alert.riskLevel === 'LEGAL')     return '#150008';
    if (this.alert.riskLevel === 'SENSITIVE') return '#130E00';
    return '#060D1A';
  }

  build() {
    Column({ space: 10 }) {
      Text(riskLabel(this.alert.riskLevel))
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(riskColor(this.alert.riskLevel))
        .margin({ top: 18 })

      if (this.alert.locationName) {
        Text(this.alert.locationName)
          .fontSize(9)
          .fontColor('#4A7A8A')
      }

      Divider()
        .color(riskColor(this.alert.riskLevel))
        .width('55%')
        .strokeWidth(2)

      Scroll() {
        Text(this.alert.message)
          .fontSize(11)
          .fontColor('#E8F4F8')
          .textAlign(TextAlign.Center)
          .width('84%')
          .lineHeight(17)
      }
      .height(110)
      .scrollBar(BarState.Off)

      Button('OK')
        .onClick(() => router.back())
        .backgroundColor('#0D2035')
        .fontColor('#4A7A8A')
        .fontSize(12)
        .width('65%')
        .height(34)
        .borderRadius(17)
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
