/**
 * SpeechResult.ets — Shows translation result and suggested Japanese replies
 * Includes TTS audio playback for the translated English text.
 */
import router from '@ohos.router';
import media from '@ohos.multimedia.media';
import http from '@ohos.net.http';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { TranslationResponse } from '../common/Types';

@Entry
@Component
struct SpeechResult {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private response: TranslationResponse = JSON.parse(this.params['translationResponseJson'] ?? '{}') as TranslationResponse;
  private languageName: string = this.params['languageName'] ?? '';

  @State selectedIdx: number = 0;
  @State isPlayingAudio: boolean = false;
  @State audioPlayError: string = '';

  private ctx: common.UIAbilityContext | null = null;
  private audioPlayer: media.AVPlayer | null = null;

  aboutToAppear(): void {
    this.ctx = getContext(this) as common.UIAbilityContext;
  }

  aboutToDisappear(): void {
    if (this.audioPlayer) {
      try {
        this.audioPlayer.reset();
        this.audioPlayer.release();
      } catch (_) {}
      this.audioPlayer = null;
    }
  }

  private get currentSuggestion(): string {
    const suggestions = this.response.replySuggestionsJapanese ?? [];
    return suggestions[this.selectedIdx] ?? '';
  }

  private async playTtsAudio(): Promise<void> {
    if (!this.response.ttsAudioUrl) {
      this.audioPlayError = 'No audio available';
      return;
    }

    this.isPlayingAudio = true;
    this.audioPlayError = '';

    try {
      // Download audio file to temp directory
      const fileName = 'tts_result.mp3';
      const tempFilePath = (this.ctx?.tempDir ?? '/tmp') + '/' + fileName;

      // Clean up any existing file
      try {
        fs.unlinkSync(tempFilePath);
      } catch (_) {}

      // Download the audio
      await this.downloadAudio(this.response.ttsAudioUrl, tempFilePath);

      // Play the audio
      if (this.audioPlayer) {
        try {
          this.audioPlayer.reset();
          this.audioPlayer.release();
        } catch (_) {}
      }

      this.audioPlayer = await media.createAVPlayer();
      const fileObj = fs.openSync(tempFilePath, fs.OpenMode.READ_ONLY);
      const avFileDescriptor: media.AVFileDescriptor = {
        fd: fileObj.fd,
        offset: 0,
        length: -1,
      };
      this.audioPlayer.fdSrc = avFileDescriptor;

      // Play when ready
      await new Promise<void>((resolve: () => void) => {
        const onStateChange = (state: string | number): void => {
          console.info('[SpeechResult] Audio state:', state);
          if (state === 'prepared' || state === 1) {
            this.audioPlayer?.play();
          } else if (state === 'completed' || state === 'stopped' || state === 'error' || state === 3 || state === 4 || state === 5) {
            this.isPlayingAudio = false;
            if (state === 'error' || state === 5) {
              this.audioPlayError = 'Playback failed';
            }
            resolve();
          }
        };

        if (this.audioPlayer) {
          this.audioPlayer.on('stateChange', onStateChange);
          this.audioPlayer.prepare();
        }
      });
    } catch (e) {
      console.error('[SpeechResult] Audio playback failed:', JSON.stringify(e));
      this.audioPlayError = 'Playback failed';
      this.isPlayingAudio = false;
    }
  }

  private downloadAudio(url: string, filePath: string): Promise<void> {
    return new Promise((resolve: () => void, reject: (err: Error) => void) => {
      try {
        const req = http.createHttp();
        req.request(url, {
          method: http.RequestMethod.GET,
        }).then((resp: http.HttpResponse) => {
          req.destroy();
          if (resp.responseCode === 200 && resp.result) {
            try {
              const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
              fs.writeSync(file.fd, resp.result as ArrayBuffer);
              fs.closeSync(file.fd);
              resolve();
            } catch (e) {
              reject(e);
            }
          } else {
            reject(new Error('Failed to download audio'));
          }
        }).catch((e: Error) => {
          req.destroy();
          reject(e);
        });
      } catch (e) {
        reject(e as Error);
      }
    });
  }

  build() {
    Column() {
      // ── Header ──────────────────────────────────────────────────────────────
      Row() {
        Text('←')
          .fontSize(18)
          .fontColor('#8B949E')
          .onClick(() => router.back())
          .padding({ left: 8, right: 8 })
        Text('Translation Result')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E6EDF3')
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)

      Divider().color('#21262D')

      Scroll() {
        Column({ space: 12 }) {

          // ── Original transcript (if available) ────────────────────────────────
          if (this.response.transcript) {
            Column({ space: 4 }) {
              Text('They said:')
                .fontSize(10)
                .fontColor('#8B949E')
              Text(`"${this.response.transcript}"`)
                .fontSize(11)
                .fontColor('#C9D1D9')
                .fontStyle(FontStyle.Italic)
                .textAlign(TextAlign.Center)
                .width('90%')
                .lineHeight(18)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 12, bottom: 8 })

            Divider().color('#21262D').width('80%')
          }

          // ── Translation (English) ──────────────────────────────────────────────
          if (this.response.translationEnglish) {
            Column({ space: 8 }) {
              Text('Translation:')
                .fontSize(10)
                .fontColor('#8B949E')
              Text(this.response.translationEnglish)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#E6EDF3')
                .textAlign(TextAlign.Center)
                .width('95%')
                .lineHeight(22)

              // Play TTS button
              Button('▶ Play Audio')
                .onClick(() => this.playTtsAudio())
                .enabled(!this.isPlayingAudio)
                .backgroundColor(this.isPlayingAudio ? '#21262D' : '#238636')
                .fontColor('#FFFFFF')
                .fontSize(11)
                .width('80%')
                .height(32)
                .margin({ top: 8 })

              // Audio error or playing indicator
              if (this.audioPlayError) {
                Text(this.audioPlayError)
                  .fontSize(10)
                  .fontColor('#FF4444')
              } else if (this.isPlayingAudio) {
                Text('Playing audio...')
                  .fontSize(10)
                  .fontColor('#00E5C8')
              }
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#161B22')
            .borderRadius(8)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 10, right: 10, top: 8, bottom: 8 })
          }

          // ── Japanese reply suggestions ─────────────────────────────────────────
          if (this.response.replySuggestionsJapanese && this.response.replySuggestionsJapanese.length > 0) {
            Column({ space: 8 }) {
              Text('You can reply (in Japanese):')
                .fontSize(10)
                .fontColor('#8B949E')

              // Display current selected suggestion
              if (this.currentSuggestion) {
                Column({ space: 4 }) {
                  Text(this.currentSuggestion)
                    .fontSize(14)
                    .fontColor('#00E5C8')
                    .textAlign(TextAlign.Center)
                    .width('90%')
                    .lineHeight(24)
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#0D2818')
                .borderRadius(8)
                .alignItems(HorizontalAlign.Center)
              }

              // Pagination indicator
              if (this.response.replySuggestionsJapanese.length > 1) {
                Text(`${this.selectedIdx + 1} / ${this.response.replySuggestionsJapanese.length}`)
                  .fontSize(10)
                  .fontColor('#8B949E')
              }

              // Navigation buttons
              if (this.response.replySuggestionsJapanese.length > 1) {
                Row({ space: 12 }) {
                  Button('‹')
                    .onClick(() => {
                      if (this.selectedIdx > 0) this.selectedIdx -= 1;
                    })
                    .backgroundColor(this.selectedIdx > 0 ? '#21262D' : '#0D1117')
                    .fontColor(this.selectedIdx > 0 ? '#E6EDF3' : '#21262D')
                    .fontSize(18)
                    .width('40%')
                    .height(32)
                    .enabled(this.selectedIdx > 0)

                  Button('›')
                    .onClick(() => {
                      if (this.selectedIdx < this.response.replySuggestionsJapanese.length - 1) {
                        this.selectedIdx += 1;
                      }
                    })
                    .backgroundColor(this.selectedIdx < this.response.replySuggestionsJapanese.length - 1 ? '#21262D' : '#0D1117')
                    .fontColor(this.selectedIdx < this.response.replySuggestionsJapanese.length - 1 ? '#E6EDF3' : '#21262D')
                    .fontSize(18)
                    .width('40%')
                    .height(32)
                    .enabled(this.selectedIdx < this.response.replySuggestionsJapanese.length - 1)
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
              }
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#161B22')
            .borderRadius(8)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 10, right: 10, top: 4, bottom: 12 })
          }

          Text('Swipe right or tap ← to go back')
            .fontSize(9)
            .fontColor('#6E7681')
            .margin({ top: 8, bottom: 12 })
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
        .onActionEnd(() => {
          router.back();
        })
    )
  }
}
