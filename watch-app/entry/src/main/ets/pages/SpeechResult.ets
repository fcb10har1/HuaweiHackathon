/**
 * SpeechResult.ets — Translation result and reply suggestions.
 * Shows: original transcript → English translation → local-language replies.
 */
import router from '@ohos.router';
import { TranslationResponse } from '../common/Types';

@Entry
@Component
struct SpeechResult {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private response: TranslationResponse =
    JSON.parse(this.params['translationResponseJson'] ?? '{}') as TranslationResponse;
  private languageName: string = this.params['languageName'] ?? '';

  @State selectedIdx: number = 0;

  build() {
    Column() {
      // ── Header ──────────────────────────────────────────────────────────────
      Row() {
        Text('←')
          .fontSize(16)
          .fontColor('#8B949E')
          .onClick(() => router.back())
          .padding({ left: 12, right: 8 })
        Text('Translation')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 32 })
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)

      Divider().color('#21262D').strokeWidth(0.5)

      Scroll() {
        Column({ space: 10 }) {

          // ── THEY SAID — original language transcript ───────────────────────
          if (this.response.transcript) {
            Column({ space: 5 }) {
              Text('THEY SAID')
                .fontSize(9)
                .fontColor('#8B949E')
                .letterSpacing(1.5)
              Text(`"${this.response.transcript}"`)
                .fontSize(12)
                .fontColor('#C9D1D9')
                .fontStyle(FontStyle.Italic)
                .textAlign(TextAlign.Center)
                .width('86%')
                .lineHeight(18)
            }
            .width('100%')
            .padding({ top: 10, bottom: 10, left: 4, right: 4 })
            .backgroundColor('#161B22')
            .borderRadius(10)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 16, right: 16, top: 8 })
          }

          // ── TRANSLATION — English meaning ─────────────────────────────────
          if (this.response.translationEnglish) {
            Column({ space: 5 }) {
              Text('TRANSLATION')
                .fontSize(9)
                .fontColor('#8B949E')
                .letterSpacing(1.5)
              Text(this.response.translationEnglish)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .textAlign(TextAlign.Center)
                .width('86%')
                .lineHeight(20)
            }
            .width('100%')
            .padding({ top: 10, bottom: 12, left: 4, right: 4 })
            .backgroundColor('#161B22')
            .borderRadius(10)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 16, right: 16 })
          }

          // ── REPLY SUGGESTIONS ─────────────────────────────────────────────
          if (this.response.replySuggestionsJapanese && this.response.replySuggestionsJapanese.length > 0) {
            Column({ space: 8 }) {
              Text(`REPLY IN ${this.languageName.toUpperCase()}`)
                .fontSize(9)
                .fontColor('#8B949E')
                .letterSpacing(1.5)

              // Current reply — teal, prominent
              Text(this.response.replySuggestionsJapanese[this.selectedIdx] || '')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#00E5C8')
                .textAlign(TextAlign.Center)
                .width('86%')
                .lineHeight(19)
                .padding({ top: 10, bottom: 10, left: 8, right: 8 })
                .backgroundColor('#0A1E1A')
                .borderRadius(8)

              // English hint below (if available and different from local)
              if (this.response.suggestionTranslations &&
                  this.response.suggestionTranslations.length > this.selectedIdx &&
                  this.response.suggestionTranslations[this.selectedIdx] &&
                  this.response.replySuggestionsJapanese[this.selectedIdx] !== this.response.suggestionTranslations[this.selectedIdx]) {
                Text(this.response.suggestionTranslations[this.selectedIdx])
                  .fontSize(9)
                  .fontColor('#6E7681')
                  .textAlign(TextAlign.Center)
                  .width('80%')
              }

              // < > navigation
              if (this.response.replySuggestionsJapanese.length > 1) {
                Row({ space: 20 }) {
                  Button('<')
                    .onClick(() => { if (this.selectedIdx > 0) this.selectedIdx -= 1; })
                    .backgroundColor(this.selectedIdx > 0 ? '#00C4AE' : '#1C2430')
                    .fontColor(this.selectedIdx > 0 ? '#0D1117' : '#444C56')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .width(36)
                    .height(36)
                    .borderRadius(18)

                  Text(`${this.selectedIdx + 1} / ${this.response.replySuggestionsJapanese.length}`)
                    .fontSize(9)
                    .fontColor('#8B949E')

                  Button('>')
                    .onClick(() => {
                      if (this.selectedIdx < this.response.replySuggestionsJapanese.length - 1) {
                        this.selectedIdx += 1;
                      }
                    })
                    .backgroundColor(this.selectedIdx < this.response.replySuggestionsJapanese.length - 1 ? '#00C4AE' : '#1C2430')
                    .fontColor(this.selectedIdx < this.response.replySuggestionsJapanese.length - 1 ? '#0D1117' : '#444C56')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .width(36)
                    .height(36)
                    .borderRadius(18)
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
              }
            }
            .width('100%')
            .padding({ top: 10, bottom: 12, left: 4, right: 4 })
            .backgroundColor('#161B22')
            .borderRadius(10)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 16, right: 16, bottom: 10 })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .friction(0.85)
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
