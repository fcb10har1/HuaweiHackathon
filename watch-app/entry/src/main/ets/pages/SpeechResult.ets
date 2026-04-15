/**
 * SpeechResult.ets — Shows translation result and suggested Japanese replies
 * Includes TTS audio playback for the translated English text.
 */
import router from '@ohos.router';
import media from '@ohos.multimedia.media';
import http from '@ohos.net.http';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import { TranslationResponse } from '../common/Types';

// Base64 decoder helper function for HarmonyOS
function base64ToUint8Array(base64Str: string): Uint8Array {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  const bytes: number[] = [];
  
  for (let i = 0; i < base64Str.length; i += 4) {
    const a = chars.indexOf(base64Str[i] ?? '');
    const b = chars.indexOf(base64Str[i + 1] ?? '');
    const c = chars.indexOf(base64Str[i + 2] ?? '');
    const d = chars.indexOf(base64Str[i + 3] ?? '');
    
    bytes.push((a << 2) | (b >> 4));
    if (c !== -1) {
      bytes.push(((b & 15) << 4) | (c >> 2));
    }
    if (d !== -1) {
      bytes.push(((c & 3) << 6) | d);
    }
  }
  
  return new Uint8Array(bytes);
}

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
    let audioUrl: string = '';
    
    // Determine which audio to play
    if (this.selectedIdx >= 0 && this.response.suggestionAudios && this.response.suggestionAudios.length > this.selectedIdx) {
      // Play audio for the selected suggestion
      audioUrl = this.response.suggestionAudios[this.selectedIdx];
      console.info('[SpeechResult] Playing suggestion audio at index:', this.selectedIdx);
    } else if (this.response.ttsAudioUrl) {
      // Fall back to translation audio
      audioUrl = this.response.ttsAudioUrl;
      console.info('[SpeechResult] Playing translation audio');
    } else {
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
      await this.downloadAudio(audioUrl, tempFilePath);

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
        // Handle base64 data URLs (data:audio/wav;base64,...)
        if (url.startsWith('data:')) {
          try {
            const base64Part = url.split(',')[1];
            if (!base64Part) {
              reject(new Error('Invalid data URL format'));
              return;
            }
            
            console.info('[SpeechResult] Decoding base64 audio data...');
            
            // Decode base64 string to bytes using helper function
            const bytes: Uint8Array = base64ToUint8Array(base64Part);
            
            // Write to file
            const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
            fs.writeSync(file.fd, bytes);
            fs.closeSync(file.fd);
            console.info('[SpeechResult] ✓ Wrote base64 audio to file');
            resolve();
          } catch (e) {
            console.error('[SpeechResult] Failed to decode base64:', JSON.stringify(e));
            reject(e);
          }
          return;
        }

        // Handle regular HTTP URLs
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
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)

      Divider().color('#21262D')

      Scroll() {
        Column({ space: 8 }) {

          // ── Original transcript (if available) ────────────────────────────────
          if (this.response.transcript) {
            Column({ space: 3 }) {
              Text('They said:')
                .fontSize(9)
                .fontColor('#8B949E')
              Text(`"${this.response.transcript}"`)
                .fontSize(10)
                .fontColor('#C9D1D9')
                .fontStyle(FontStyle.Italic)
                .textAlign(TextAlign.Center)
                .width('90%')
                .lineHeight(16)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 8, bottom: 6 })

            Divider().color('#21262D').width('70%')
          }

          // ── Translation (English) ──────────────────────────────────────────────
          if (this.response.translationEnglish) {
            Column({ space: 6 }) {
              Text('Translation:')
                .fontSize(9)
                .fontColor('#8B949E')
              Text(this.response.translationEnglish)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#E6EDF3')
                .textAlign(TextAlign.Center)
                .width('90%')
                .lineHeight(18)

              // Play TTS button
              Button('▶ Play Audio')
                .onClick(() => this.playTtsAudio())
                .enabled(!this.isPlayingAudio)
                .backgroundColor(this.isPlayingAudio ? '#21262D' : '#238636')
                .fontColor('#FFFFFF')
                .fontSize(10)
                .width('70%')
                .height(32)
                .margin({ top: 6 })

              // Audio error or playing indicator
              if (this.audioPlayError) {
                Text(this.audioPlayError)
                  .fontSize(9)
                  .fontColor('#FF4444')
              } else if (this.isPlayingAudio) {
                Text('Playing audio...')
                  .fontSize(9)
                  .fontColor('#00E5C8')
              }
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#161B22')
            .borderRadius(6)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 8, right: 8, top: 4, bottom: 6 })
          }

          // ── Japanese reply suggestions ─────────────────────────────────────────
          if (this.response.replySuggestionsJapanese && this.response.replySuggestionsJapanese.length > 0) {
            Column({ space: 6 }) {
              Text('Reply (Japanese):')
                .fontSize(9)
                .fontColor('#8B949E')

              // Display current selected suggestion
              if (this.currentSuggestion) {
                Column({ space: 2 }) {
                  Text(this.currentSuggestion)
                    .fontSize(12)
                    .fontColor('#00E5C8')
                    .textAlign(TextAlign.Center)
                    .width('88%')
                    .lineHeight(18)
                }
                .width('100%')
                .padding(10)
                .backgroundColor('#0D2818')
                .borderRadius(6)
                .alignItems(HorizontalAlign.Center)
              }

              // Pagination indicator
              if (this.response.replySuggestionsJapanese.length > 1) {
                Text(`${this.selectedIdx + 1} / ${this.response.replySuggestionsJapanese.length}`)
                  .fontSize(8)
                  .fontColor('#8B949E')
              }

              // Navigation buttons (smaller for circular screen)
              if (this.response.replySuggestionsJapanese.length > 1) {
                Row({ space: 8 }) {
                  Button('‹')
                    .onClick(() => {
                      if (this.selectedIdx > 0) this.selectedIdx -= 1;
                    })
                    .backgroundColor(this.selectedIdx > 0 ? '#21262D' : '#0D1117')
                    .fontColor(this.selectedIdx > 0 ? '#E6EDF3' : '#21262D')
                    .fontSize(14)
                    .width('32%')
                    .height(28)
                    .enabled(this.selectedIdx > 0)

                  Button('›')
                    .onClick(() => {
                      if (this.selectedIdx < this.response.replySuggestionsJapanese.length - 1) {
                        this.selectedIdx += 1;
                      }
                    })
                    .backgroundColor(this.selectedIdx < this.response.replySuggestionsJapanese.length - 1 ? '#21262D' : '#0D1117')
                    .fontColor(this.selectedIdx < this.response.replySuggestionsJapanese.length - 1 ? '#E6EDF3' : '#21262D')
                    .fontSize(14)
                    .width('32%')
                    .height(28)
                    .enabled(this.selectedIdx < this.response.replySuggestionsJapanese.length - 1)
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
              }
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#161B22')
            .borderRadius(6)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 8, right: 8, top: 4, bottom: 8 })
          }

          Text('← Swipe or tap back')
            .fontSize(8)
            .fontColor('#6E7681')
            .margin({ top: 4, bottom: 8 })
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
