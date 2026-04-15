/**
 * TripEnded.ets — Farewell screen shown when a trip's end date has passed.
 * User taps Done to return to the trip list.
 */
import router from '@ohos.router';
import { Trip } from '../common/Types';

@Entry
@Component
struct TripEnded {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private trip: Trip = JSON.parse(this.params['tripJson'] ?? '{}') as Trip;

  build() {
    Column({ space: 10 }) {
      Text(this.trip.flag)
        .fontSize(34)
        .margin({ top: 24 })

      Text('Your trip to')
        .fontSize(11)
        .fontColor('#4A7A8A')

      Text(this.trip.countryName)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E8F4F8')

      Text('has ended.')
        .fontSize(11)
        .fontColor('#4A7A8A')

      Divider().color('#0D2035').width('55%')

      Text('Safe travels!')
        .fontSize(13)
        .fontColor('#2DD4BF')
        .fontWeight(FontWeight.Bold)

      Text('We hope the journey was wonderful.')
        .fontSize(10)
        .fontColor('#4A7A8A')
        .textAlign(TextAlign.Center)
        .width('76%')

      Button('Done')
        .onClick(() => router.back())
        .backgroundColor('#0D2035')
        .fontColor('#2DD4BF')
        .fontSize(12)
        .width('65%')
        .height(34)
        .borderRadius(17)
        .margin({ top: 6 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#060D1A')
    .gesture(
      PanGesture({ direction: PanDirection.Right, distance: 50 })
        .onActionEnd(() => router.back())
    )
  }
}
