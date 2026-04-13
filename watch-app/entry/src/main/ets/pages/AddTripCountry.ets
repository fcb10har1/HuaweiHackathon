/**
 * AddTripCountry.ets — Step 1 of adding a trip: scroll and select country
 */
import router from '@ohos.router';
import { SUPPORTED_COUNTRIES, CountryEntry } from '../common/Types';

@Entry
@Component
struct AddTripCountry {
  build() {
    Column() {
      // ── Header ──────────────────────────────────────────────────────────────
      Row() {
        Text('←')
          .fontSize(18)
          .fontColor('#8B949E')
          .onClick(() => router.back())
          .padding({ left: 8, right: 8 })
        Text('Select Country')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E6EDF3')
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)

      Divider().color('#21262D')

      // ── Country scroll list ──────────────────────────────────────────────────
      List({ space: 6 }) {
        ForEach(SUPPORTED_COUNTRIES, (entry: CountryEntry) => {
          ListItem() {
            Row({ space: 12 }) {
              Text(entry.flag).fontSize(24)
              Column({ space: 2 }) {
                Text(entry.name)
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E6EDF3')
                Text(entry.languageName)
                  .fontSize(10)
                  .fontColor('#8B949E')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text('›')
                .fontSize(16)
                .fontColor('#8B949E')
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 10, bottom: 10 })
            .backgroundColor('#161B22')
            .borderRadius(8)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/AddTripDates',
                params: {
                  countryCode:     entry.code,
                  countryName:     entry.name,
                  flag:            entry.flag,
                  languageName:    entry.languageName,
                  languageLocale:  entry.languageLocale,
                },
              });
            })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 10, right: 10 })
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
