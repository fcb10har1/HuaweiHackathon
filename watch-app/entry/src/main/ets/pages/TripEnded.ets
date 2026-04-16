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
    Column({ space: 14 }) {
      Text(this.trip.flag)
        .fontSize(40)
        .margin({ top: 30 })

      Text(`Your trip to`)
        .fontSize(12)
        .fontColor('#8B949E')

      Text(this.trip.countryName)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E6EDF3')

      Text('has ended.')
        .fontSize(12)
        .fontColor('#8B949E')

      Divider().color('#21262D').width('60%')

      Text('Safe travels!')
        .fontSize(14)
        .fontColor('#00E5C8')
        .fontWeight(FontWeight.Bold)

      Text('We hope the journey was wonderful.')
        .fontSize(10)
        .fontColor('#6E7681')
        .textAlign(TextAlign.Center)
        .width('80%')

      Button('Done')
        .onClick(() => {
          // Pop back to the trip list (Index)
          router.back();
        })
        .backgroundColor('#00C4AE')
        .fontColor('#0D1117')
        .fontSize(13)
        .width('70%')
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#0D1117')
    .gesture(
      PanGesture({ direction: PanDirection.Right, distance: 50 })
        .onActionEnd(() => router.back())
    )
  }
}
