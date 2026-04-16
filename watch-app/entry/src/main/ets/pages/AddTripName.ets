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
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(40).height(40)
            .borderRadius(20)
            .backgroundColor('#00C4AE')
          // Arrow: shaft + two bars meeting at the same tip point
          // Geometry: shaft spans -5→+5 (centre 0). Each arrowhead bar is
          // length 8 rotated ±40°. Half-length projected: x=3.06, y=2.57.
          // Bar centres at (2, ±3) put both right ends at ≈ (5, 0) — the tip.
          Stack({ alignContent: Alignment.Center }) {
            Row()
              .width(10).height(2.5)
              .backgroundColor('#0D1117')
              .borderRadius(1)
            Row()
              .width(8).height(2.5)
              .backgroundColor('#0D1117')
              .borderRadius(1)
              .rotate({ angle: 40 })
              .translate({ x: 2, y: -3 })
            Row()
              .width(8).height(2.5)
              .backgroundColor('#0D1117')
              .borderRadius(1)
              .rotate({ angle: -40 })
              .translate({ x: 2, y: 3 })
          }
          .width(30).height(30)
        }
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
