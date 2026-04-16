/**
 * SpeechResult.ets — Shows what was said (translated to English)
 * and tap-friendly reply options in the local language.
 */
import router from '@ohos.router';
import { TranslationResponse } from '../common/Types';

@Entry
@Component
struct SpeechResult {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private response: TranslationResponse =
    JSON.parse(this.params['translationResponseJson'] ?? '{}') as TranslationResponse;
  private languageName: string = this.params['languageName'] ?? 'local language';

  @State selectedIdx: number = 0;

  private get suggestions(): string[] {
    return this.response.replySuggestionsJapanese ?? [];
  }

  private get englishTranslations(): string[] {
    return this.response.suggestionTranslations ?? [];
  }

  private get currentReply(): string {
    return this.suggestions[this.selectedIdx] ?? '';
  }

  private get currentEnglish(): string {
    return this.englishTranslations[this.selectedIdx] ?? '';
  }

  build() {
    Column() {
      // ── Header ──────────────────────────────────────────────────────────────
      Row() {
        Text('←')
          .fontSize(18)
          .fontColor('#8B949E')
          .onClick(() => router.back())
          .padding({ left: 10, right: 8 })
        Text('Translation')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E6EDF3')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 30 })
      }
      .width('100%')
      .height(38)
      .alignItems(VerticalAlign.Center)

      Divider().color('#21262D')

      Scroll() {
        Column({ space: 8 }) {

          // ── What they said (English translation) ───────────────────────────
          if (this.response.translationEnglish) {
            Column({ space: 4 }) {
              Text('They said:')
                .fontSize(9)
                .fontColor('#8B949E')
              Text(this.response.translationEnglish)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#E6EDF3')
                .textAlign(TextAlign.Center)
                .width('88%')
                .lineHeight(19)
            }
            .width('100%')
            .padding({ top: 10, bottom: 10, left: 4, right: 4 })
            .backgroundColor('#161B22')
            .borderRadius(8)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 14, right: 14, top: 8 })
          }

          // ── Reply suggestions ──────────────────────────────────────────────
          if (this.suggestions.length > 0) {
            Column({ space: 6 }) {
              Text(`Reply in ${this.languageName}:`)
                .fontSize(9)
                .fontColor('#8B949E')

              // Local-language reply (large, teal, tap-to-use)
              Text(this.currentReply || this.currentEnglish)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#00E5C8')
                .textAlign(TextAlign.Center)
                .width('88%')
                .lineHeight(19)
                .padding({ top: 8, bottom: 8, left: 6, right: 6 })
                .backgroundColor('#0A1E1A')
                .borderRadius(8)

              // English meaning below
              if (this.currentEnglish && this.currentReply !== this.currentEnglish) {
                Text(this.currentEnglish)
                  .fontSize(9)
                  .fontColor('#8B949E')
                  .textAlign(TextAlign.Center)
                  .width('86%')
                  .lineHeight(13)
              }

              // Pagination
              if (this.suggestions.length > 1) {
                Row({ space: 10 }) {
                  Button('‹')
                    .onClick(() => { if (this.selectedIdx > 0) this.selectedIdx -= 1; })
                    .backgroundColor(this.selectedIdx > 0 ? '#21262D' : '#0D1117')
                    .fontColor(this.selectedIdx > 0 ? '#E6EDF3' : '#313940')
                    .fontSize(16)
                    .width(38)
                    .height(30)
                    .enabled(this.selectedIdx > 0)

                  Text(`${this.selectedIdx + 1} / ${this.suggestions.length}`)
                    .fontSize(9)
                    .fontColor('#8B949E')

                  Button('›')
                    .onClick(() => {
                      if (this.selectedIdx < this.suggestions.length - 1) this.selectedIdx += 1;
                    })
                    .backgroundColor(this.selectedIdx < this.suggestions.length - 1 ? '#21262D' : '#0D1117')
                    .fontColor(this.selectedIdx < this.suggestions.length - 1 ? '#E6EDF3' : '#313940')
                    .fontSize(16)
                    .width(38)
                    .height(30)
                    .enabled(this.selectedIdx < this.suggestions.length - 1)
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
              }
            }
            .width('100%')
            .padding({ top: 8, bottom: 10, left: 4, right: 4 })
            .backgroundColor('#161B22')
            .borderRadius(8)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 14, right: 14, top: 4, bottom: 8 })
          }

          Text('← Swipe to go back')
            .fontSize(8)
            .fontColor('#6E7681')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 8 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
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
