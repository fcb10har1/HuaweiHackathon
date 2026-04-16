/**
 * AddTripName.ets — Step 1 of add-trip flow: name your trip.
 */
import router from '@ohos.router';

@Entry
@Component
struct AddTripName {
  @State tripName: string = '';

  build() {
    Column() {
      // ── Header ──────────────────────────────────────────────────────────────
      Row() {
        Text('←')
          .fontSize(18)
          .fontColor('#8B949E')
          .onClick(() => router.back())
          .padding({ left: 10, right: 8 })
        Text('Name your trip')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E6EDF3')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 28 })
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)

      Divider().color('#21262D')

      // ── Content ─────────────────────────────────────────────────────────────
      Column({ space: 20 }) {
        TextInput({ placeholder: 'e.g. Tokyo Spring', text: this.tripName })
          .onChange((val: string) => { this.tripName = val; })
          .fontSize(12)
          .fontColor('#E6EDF3')
          .placeholderColor('#6E7681')
          .backgroundColor('#161B22')
          .borderRadius(8)
          .width('80%')
          .height(42)

        // Teal circle arrow button
        Text('→')
          .fontSize(22)
          .fontColor('#0D1117')
          .fontWeight(FontWeight.Bold)
          .width(56)
          .height(56)
          .textAlign(TextAlign.Center)
          .lineHeight(54)
          .backgroundColor('#00C4AE')
          .borderRadius(28)
          .opacity(this.tripName.trim().length > 0 ? 1.0 : 0.35)
          .onClick(() => {
            if (this.tripName.trim().length > 0) {
              router.pushUrl({
                url: 'pages/AddTripCountry',
                params: { tripName: this.tripName.trim() },
              });
            }
          })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0D1117')
    .gesture(
      PanGesture({ direction: PanDirection.Right, distance: 50 })
        .onActionEnd(() => router.back())
    )
  }
}
