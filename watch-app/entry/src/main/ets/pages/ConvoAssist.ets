/**
 * ConvoAssist.ets — Conversational assistance screen
 *
 * Modes:
 *   phrases   — scrollable list of useful phrases (JSON + LLM extras)
 *   picking   — sample audio file selector
 *   processing — uploading and translating
 */
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { vibrator } from '@kit.SensorServiceKit';
import { Trip, Phrase, TranslationResponse, AudioFile } from '../common/Types';
import { CountryDataService } from '../services/CountryDataService';
import { LlmService } from '../services/LlmService';
import { TranslationService } from '../services/TranslationService';

type ConvoMode = 'phrases' | 'picking' | 'processing';

@Entry
@Component
struct ConvoAssist {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private trip: Trip = JSON.parse(this.params['tripJson'] ?? '{}') as Trip;
  private venueType: string = this.params['currentVenueType'] ?? '';

  @State mode: ConvoMode        = 'phrases';
  @State phrases: Phrase[]      = [];
  @State extraPhrases: string[] = [];   // LLM-generated extras (English only)
  @State loadingPhrases: boolean = true;
  @State audioFiles: AudioFile[] = [
    { name: '🇯🇵 Japanese Sample', file: 'japanese_sample.wav' },
    { name: '🇹🇭 Thai Sample',     file: 'thai_sample.wav'     },
    { name: '🇮🇩 Indonesian Sample', file: 'indonesian_sample.wav' },
  ];
  @State selectedAudioIdx: number = -1;

  private dataService: CountryDataService | null = null;
  private llmService: LlmService = new LlmService();
  private translationService: TranslationService = new TranslationService();
  private ctx: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    this.ctx = getContext(this) as common.UIAbilityContext;
    this.dataService = new CountryDataService(this.ctx);
    this.loadPhrases();
  }

  private loadPhrases(): void {
    // Load JSON phrases (location-aware if venueType known)
    const scenarioId = this.venueType || '';
    this.dataService?.getPhrases(this.trip.countryCode, scenarioId).then(phrases => {
      this.phrases = phrases;
      this.loadingPhrases = false;
      // Load LLM extras concurrently (show when ready)
      this.llmService.generateExtraPhrases(this.trip.countryName, this.venueType || 'general')
        .then(extras => { this.extraPhrases = extras; });
    });
  }

  private async startFilePicker(): Promise<void> {
    this.mode = 'picking';
    try {
      vibrator.startVibration({ type: 'time', duration: 80 }, { id: 0, usage: 'notification' });
    } catch (_) {}
  }

  private async selectAudioFile(index: number): Promise<void> {
    this.selectedAudioIdx = index;
    this.mode = 'processing';

    const audioFile = this.audioFiles[index];
    console.info('[ConvoAssist] Selected audio:', audioFile.name);

    try {
      await this.uploadAndTranslate(audioFile.file);
    } catch (e) {
      console.error('[ConvoAssist] Upload failed:', JSON.stringify(e));
      this.mode = 'picking';
    }
  }

  private async uploadAndTranslate(filePath: string): Promise<void> {
    try {
      const result = await this.translationService.translateAudio(filePath);
      this.navigateToResult(result);
    } catch (e) {
      console.error('[ConvoAssist] Translation failed:', JSON.stringify(e));
      this.mode = 'phrases';
    }
  }

  private navigateToResult(result: TranslationResponse): void {
    router.pushUrl({
      url: 'pages/SpeechResult',
      params: {
        translationResponseJson: JSON.stringify(result),
        languageName: this.trip.languageName,
      },
    });
    // Reset mode for when user comes back
    this.mode = 'phrases';
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  build() {
    Column() {
      // ── Header ──────────────────────────────────────────────────────────────
      Row() {
        Text('←')
          .fontSize(16)
          .fontColor('#8B949E')
          .onClick(() => {
            if (this.mode !== 'phrases') {
              this.mode = 'phrases';
            } else {
              router.back();
            }
          })
          .padding({ left: 12, right: 8 })
        Text(
          this.mode === 'picking'    ? 'Choose Audio' :
          this.mode === 'processing' ? 'Translating...' :
                                       'Convo Assist'
        )
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

      // ── Phrases mode ─────────────────────────────────────────────────────────
      if (this.mode === 'phrases') {
        if (this.loadingPhrases) {
          Column() {
            LoadingProgress().color('#00E5C8').width(30).height(30)
            Text('Loading phrases...')
              .fontSize(11)
              .fontColor('#8B949E')
              .margin({ top: 8 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          Column() {
            if (this.venueType) {
              Text(this.venueType.toUpperCase())
                .fontSize(8)
                .fontColor('#00E5C8')
                .letterSpacing(1.5)
                .margin({ top: 6, bottom: 2 })
            }

            Scroll() {
              Column({ space: 7 }) {
                ForEach(this.phrases, (p: Phrase) => {
                  Column({ space: 4 }) {
                    Text(p.english)
                      .fontSize(11)
                      .fontColor('#E6EDF3')
                      .fontWeight(FontWeight.Medium)
                      .textAlign(TextAlign.Center)
                    if (p.nativeScript) {
                      Text(p.nativeScript)
                        .fontSize(10)
                        .fontColor('#00E5C8')
                        .textAlign(TextAlign.Center)
                        .lineHeight(15)
                    }
                  }
                  .width('100%')
                  .padding({ left: 10, right: 10, top: 9, bottom: 9 })
                  .backgroundColor('#161B22')
                  .borderRadius(10)
                })
                ForEach(this.extraPhrases, (ep: string) => {
                  Text(ep)
                    .fontSize(10)
                    .fontColor('#C9D1D9')
                    .textAlign(TextAlign.Center)
                    .width('100%')
                    .padding({ left: 10, right: 10, top: 7, bottom: 7 })
                    .backgroundColor('#0D1B2A')
                    .borderRadius(10)
                })
                Text('').height(64)
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
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ left: 16, right: 16 })

          // Speak button — teal circle, no emoji
          Column({ space: 4 }) {
            Button('Speak')
              .onClick(() => this.startFilePicker())
              .backgroundColor('#00C4AE')
              .fontColor('#0D1117')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .width(56)
              .height(56)
              .borderRadius(28)
            Text('Translate')
              .fontSize(8)
              .fontColor('#6E7681')
          }
          .alignItems(HorizontalAlign.Center)
          .margin({ bottom: 12 })
        }
      }

      // ── Picking mode ──────────────────────────────────────────────────────────
      if (this.mode === 'picking') {
        Column({ space: 14 }) {
          Text('Select a language sample')
            .fontSize(11)
            .fontColor('#8B949E')
            .textAlign(TextAlign.Center)
            .letterSpacing(0.3)
            .margin({ top: 4 })

          Column({ space: 12 }) {
            ForEach(this.audioFiles, (audioFile: AudioFile, index: number) => {
              Row() {
                Text(audioFile.name)
                  .fontSize(13)
                  .fontColor('#E6EDF3')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
                  .padding({ left: 8 })
                Text('›')
                  .fontSize(18)
                  .fontColor('#00E5C8')
                  .padding({ right: 10 })
              }
              .width('86%')
              .padding({ left: 10, right: 4, top: 16, bottom: 16 })
              .backgroundColor('#161B22')
              .borderRadius(12)
              .border({ width: 0.5, color: '#2A3B50', style: BorderStyle.Solid })
              .onClick(() => this.selectAudioFile(index))
            })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // ── Processing mode ───────────────────────────────────────────────────────
      if (this.mode === 'processing') {
        Column({ space: 12 }) {
          LoadingProgress()
            .color('#00E5C8')
            .width(36)
            .height(36)
          Text('Translating...')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E6EDF3')
          Text('Please wait')
            .fontSize(9)
            .fontColor('#8B949E')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0D1117')
    .gesture(
      PanGesture({ direction: PanDirection.Right, distance: 50 })
        .onActionEnd(() => {
          if (this.mode !== 'phrases') {
            this.mode = 'phrases';
          } else {
            router.back();
          }
        })
    )
  }
}
