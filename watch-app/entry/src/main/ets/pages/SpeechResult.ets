/**
 * SpeechResult.ets — Shows what was said (translated to English)
 * and tap-friendly reply options in the local language.
 */
import router from '@ohos.router';
import http from '@ohos.net.http';
import { TranslationResponse } from '../common/Types';

@Entry
@Component
struct SpeechResult {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private response: TranslationResponse =
    JSON.parse(this.params['translationResponseJson'] ?? '{}') as TranslationResponse;
  private languageName: string = this.params['languageName'] ?? 'local language';

  @State selectedIdx: number = 0;
  @State isPlayingAudio: boolean = false;
  @State audioPlayError: string = '';

  private getSuggestions(): string[] {
    const raw = this.response.replySuggestionsJapanese as Object;
    return Array.isArray(raw) ? raw as string[] : [];
  }

  private getEnglishTranslations(): string[] {
    const raw = this.response.suggestionTranslations as Object;
    return Array.isArray(raw) ? raw as string[] : [];
  }

  private get currentReply(): string {
    const suggestions = this.getSuggestions();
    return suggestions[this.selectedIdx] ?? '';
  }

  private get currentEnglish(): string {
    const englishTranslations = this.getEnglishTranslations();
    return englishTranslations[this.selectedIdx] ?? '';
  }

  private async playTtsAudio(): Promise<void> {
    this.isPlayingAudio = true;
    this.audioPlayError = '';
    try {
      const httpClient = http.createHttp();
      const requestUrl: string = `http://10.0.2.2:5000/api/save-audio/${this.selectedIdx}`;
      const response: http.HttpResponse = await httpClient.request(requestUrl, {
        method: http.RequestMethod.POST,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 30000,
        readTimeout: 30000,
      });
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as Record<string, string>;
        this.audioPlayError = `Saved: ${result['file'] ?? 'audio file'}`;
      } else {
        this.audioPlayError = 'Failed to play audio';
      }
      httpClient.destroy();
    } catch (_) {
      this.audioPlayError = 'Failed to play audio';
    } finally {
      this.isPlayingAudio = false;
    }
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

              Button(this.isPlayingAudio ? 'Playing...' : '▶ Play Audio')
                .onClick(() => this.playTtsAudio())
                .enabled(!this.isPlayingAudio)
                .backgroundColor(this.isPlayingAudio ? '#21262D' : '#238636')
                .fontColor('#FFFFFF')
                .fontSize(10)
                .width('72%')
                .height(30)
                .margin({ top: 6 })

              if (this.audioPlayError) {
                Text(this.audioPlayError)
                  .fontSize(8)
                  .fontColor('#8B949E')
              }
            }
            .width('100%')
            .padding({ top: 10, bottom: 10, left: 4, right: 4 })
            .backgroundColor('#161B22')
            .borderRadius(8)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 14, right: 14, top: 8 })
          }

          // ── Reply suggestions ──────────────────────────────────────────────
          if (this.getSuggestions().length > 0) {
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
                .backgroundColor('#0D2818')
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
              if (this.getSuggestions().length > 1) {
                Row({ space: 10 }) {
                  Button('‹')
                    .onClick(() => { if (this.selectedIdx > 0) this.selectedIdx -= 1; })
                    .backgroundColor(this.selectedIdx > 0 ? '#21262D' : '#0D1117')
                    .fontColor(this.selectedIdx > 0 ? '#E6EDF3' : '#313940')
                    .fontSize(16)
                    .width(38)
                    .height(30)
                    .enabled(this.selectedIdx > 0)

                  Text(`${this.selectedIdx + 1} / ${this.getSuggestions().length}`)
                    .fontSize(9)
                    .fontColor('#8B949E')

                  Button('›')
                    .onClick(() => {
                      if (this.selectedIdx < this.getSuggestions().length - 1) this.selectedIdx += 1;
                    })
                    .backgroundColor(this.selectedIdx < this.getSuggestions().length - 1 ? '#21262D' : '#0D1117')
                    .fontColor(this.selectedIdx < this.getSuggestions().length - 1 ? '#E6EDF3' : '#313940')
                    .fontSize(16)
                    .width(38)
                    .height(30)
                    .enabled(this.selectedIdx < this.getSuggestions().length - 1)
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
