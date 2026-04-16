/**
 * ConvoAssist.ets — Conversational assistance screen
 *
 * Modes:
 *   phrases    — phrase list (JSON + LLM extras)
 *   picking    — choose one of the demo sample audio files
 *   processing — upload selected sample and translate via backend
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
  @State extraPhrases: string[] = [];
  @State loadingPhrases: boolean = true;
  @State selectedAudioIdx: number = -1;

  private dataService: CountryDataService | null = null;
  private llmService: LlmService = new LlmService();
  private translationService: TranslationService = new TranslationService();
  private ctx: common.UIAbilityContext | null = null;
  private cancelled: boolean = false;
  private sampleAudios: AudioFile[] = [
    { name: '🇯🇵 Japanese Sample', file: 'japanese_sample.wav' },
    { name: '🇹🇭 Thai Sample', file: 'thai_sample.wav' },
    { name: '🇮🇩 Indonesian Sample', file: 'indonesian_sample.wav' },
  ];

  aboutToAppear(): void {
    this.ctx = getContext(this) as common.UIAbilityContext;
    this.dataService = new CountryDataService(this.ctx);
    this.loadPhrases();
  }

  aboutToDisappear(): void {
    this.cancelled = true;
  }

  private loadPhrases(): void {
    this.dataService?.getPhrases(this.trip.countryCode, this.venueType).then(phrases => {
      this.phrases = phrases;
      this.loadingPhrases = false;
      this.llmService.generateExtraPhrases(this.trip.countryName, this.venueType || 'general')
        .then(extras => { this.extraPhrases = extras; })
        .catch(() => { this.extraPhrases = []; });
    });
  }

  private goBack(): void {
    this.cancelled = true;
    if (this.mode !== 'phrases') {
      this.mode = 'phrases';
    } else {
      router.back();
    }
  }

  private async startSamplePicker(): Promise<void> {
    this.cancelled = false;
    this.mode = 'picking';
    try {
      vibrator.startVibration({ type: 'time', duration: 80 }, { id: 0, usage: 'notification' });
    } catch (_) {}
  }

  private async selectAudioFile(index: number): Promise<void> {
    this.selectedAudioIdx = index;
    const audioFile = this.sampleAudios[index];
    await this.translateSample(audioFile.file);
  }

  private async translateSample(filePath: string): Promise<void> {
    this.cancelled = false;
    this.mode = 'processing';
    try {
      const result = await this.translationService.translateAudio(filePath);
      if (this.cancelled) return;
      this.navigateToResult(result);
    } catch (_) {
      if (!this.cancelled) this.mode = 'phrases';
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
    this.mode = 'phrases';
  }

  build() {
    Column() {
      // ── Header ──────────────────────────────────────────────────────────────
      Row() {
        Text('←')
          .fontSize(18)
          .fontColor('#8B949E')
          .onClick(() => this.goBack())
          .padding({ left: 10, right: 8 })
        Text(
          this.mode === 'picking'    ? 'Select Audio...' :
          this.mode === 'processing' ? 'Processing...' :
                                       'Convo Assist'
        )
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

      // ── Phrases mode ─────────────────────────────────────────────────────────
      if (this.mode === 'phrases') {
        if (this.loadingPhrases) {
          Column() {
            LoadingProgress().color('#00E5C8').width(32).height(32)
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
              Text(`📍 ${this.venueType}`)
                .fontSize(9)
                .fontColor('#00E5C8')
                .margin({ top: 4, bottom: 2 })
            }

            Scroll() {
              Column({ space: 5 }) {
                ForEach(this.phrases, (p: Phrase) => {
                  Column({ space: 2 }) {
                    Text(p.english)
                      .fontSize(10)
                      .fontColor('#E6EDF3')
                      .fontWeight(FontWeight.Medium)
                      .textAlign(TextAlign.Center)
                    Text(p.nativeScript)
                      .fontSize(9)
                      .fontColor('#00E5C8')
                      .textAlign(TextAlign.Center)
                      .lineHeight(13)
                  }
                  .width('100%')
                  .padding({ left: 6, right: 6, top: 6, bottom: 6 })
                  .backgroundColor('#161B22')
                  .borderRadius(6)
                })
                ForEach(this.extraPhrases, (ep: string) => {
                  Text(ep)
                    .fontSize(9)
                    .fontColor('#C9D1D9')
                    .textAlign(TextAlign.Center)
                    .width('100%')
                    .padding({ left: 6, right: 6, top: 5, bottom: 5 })
                    .backgroundColor('#0D1B2A')
                    .borderRadius(6)
                })
                // Spacer so content doesn't hide behind mic button
                Text('').height(56)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            }
            .layoutWeight(1)
          }
          .width('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ left: 14, right: 14 })

          // Mic button — circular, centered at bottom
          Button('🎤')
            .onClick(() => this.startSamplePicker())
            .backgroundColor('#238636')
            .fontColor('#FFFFFF')
            .fontSize(22)
            .width(54)
            .height(54)
            .borderRadius(27)
            .margin({ bottom: 14 })
          Text('Choose sample audio')
            .fontSize(8)
            .fontColor('#8B949E')
            .margin({ bottom: 10 })
        }
      }

      // ── Picking mode ──────────────────────────────────────────────────────────
      if (this.mode === 'picking') {
        Column({ space: 8 }) {
          Text('Select Audio File')
            .fontSize(12)
            .fontColor('#8B949E')
            .margin({ top: 6, bottom: 4 })

          ForEach(this.sampleAudios, (audio: AudioFile, index: number) => {
            Button(audio.name)
              .onClick(() => this.selectAudioFile(index))
              .backgroundColor('#238636')
              .fontColor('#FFFFFF')
              .fontSize(10)
              .fontWeight(FontWeight.Medium)
              .width('86%')
              .height(34)
              .borderRadius(6)
          })
          Text('Tap a sample to translate and play')
            .fontSize(8)
            .fontColor('#8B949E')
            .textAlign(TextAlign.Center)
            .width('84%')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // ── Processing mode ───────────────────────────────────────────────────────
      if (this.mode === 'processing') {
        Column({ space: 10 }) {
          LoadingProgress()
            .color('#00E5C8')
            .width(40)
            .height(40)
          Text('Translating...')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E6EDF3')
          Text('Finding replies')
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
        .onActionEnd(() => this.goBack())
    )
  }
}
