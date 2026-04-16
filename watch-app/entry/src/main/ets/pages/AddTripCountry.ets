/**
 * AddTripCountry.ets — Step 2: select destination country
 */
import router from '@ohos.router';
import { SUPPORTED_COUNTRIES, CountryEntry } from '../common/Types';

@Entry
@Component
struct AddTripCountry {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private tripName: string = this.params['tripName'] ?? '';

  build() {
    Column() {
      // ── Header ──────────────────────────────────────────────────────────────
      Row() {
        Text('←')
          .fontSize(18)
          .fontColor('#8B949E')
          .onClick(() => router.back())
          .padding({ left: 10, right: 8 })
        Text('Where are you going?')
          .fontSize(12)
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

      // ── Country list ─────────────────────────────────────────────────────────
      List({ space: 7 }) {
        ForEach(SUPPORTED_COUNTRIES, (entry: CountryEntry) => {
          ListItem() {
            Row({ space: 10 }) {
              Text(entry.flag).fontSize(22)
              Column({ space: 2 }) {
                Text(entry.name)
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E6EDF3')
                Text(entry.languageName)
                  .fontSize(9)
                  .fontColor('#8B949E')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text('›')
                .fontSize(14)
                .fontColor('#00E5C8')
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor('#161B22')
            .borderRadius(8)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/AddTripDates',
                params: {
                  tripName:       this.tripName,
                  countryCode:    entry.code,
                  countryName:    entry.name,
                  flag:           entry.flag,
                  languageName:   entry.languageName,
                  languageLocale: entry.languageLocale,
                },
              });
            })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 18, right: 18, top: 6, bottom: 6 })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .friction(6.0)
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
