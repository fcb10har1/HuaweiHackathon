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
        Text('\u2190')
          .fontSize(17)
          .fontColor('#4A7A8A')
          .onClick(() => router.back())
          .padding({ left: 10, right: 8 })
        Text('Select Country')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E8F4F8')
      }
      .width('100%')
      .height(36)
      .alignItems(VerticalAlign.Center)

      Divider().color('#0D2035')

      List({ space: 6 }) {
        ForEach(SUPPORTED_COUNTRIES, (entry: CountryEntry) => {
          ListItem() {
            Row({ space: 10 }) {
              Text(entry.flag).fontSize(20)
              Column({ space: 2 }) {
                Text(entry.name)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E8F4F8')
                Text(entry.languageName)
                  .fontSize(9)
                  .fontColor('#4A7A8A')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text('\u203A')
                .fontSize(14)
                .fontColor('#4A7A8A')
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 9, bottom: 9 })
            .backgroundColor('#0D2035')
            .borderRadius(8)
            .border({ width: 1, color: '#143050' })
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
    .backgroundColor('#060D1A')
    .gesture(
      PanGesture({ direction: PanDirection.Right, distance: 50 })
        .onActionEnd(() => router.back())
    )
  }
}
