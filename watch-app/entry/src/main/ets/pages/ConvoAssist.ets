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
  @State extraPhrases: string[] = [];
  @State loadingPhrases: boolean = true;
  @State audioFiles: AudioFile[] = [
    { name: '🇯🇵 Japanese Sample', file: 'japanese_sample.wav' },
    { name: '🇹🇭 Thai Sample',     file: 'thai_sample.wav'     },
    { name: '🇮🇩 Indonesian Sample', file: 'indonesian_sample.wav' },
  ];

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
    this.dataService?.getPhrases(this.trip.countryCode, this.venueType).then(phrases => {
      this.phrases = phrases;
      this.loadingPhrases = false;
      this.llmService.generateExtraPhrases(this.trip.countryName, this.venueType || 'general')
        .then(extras => { this.extraPhrases = extras; });
    });
  }

  private openPicker(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 60 }, { id: 0, usage: 'notification' });
    } catch (_) {}
    this.mode = 'picking';
  }

  private async selectAudio(index: number): Promise<void> {
    this.mode = 'processing';
    try {
      await this.uploadAndTranslate(this.audioFiles[index].file);
    } catch (_) {
      this.mode = 'picking';
    }
  }

  private async uploadAndTranslate(filePath: string): Promise<void> {
    try {
      const result = await this.translationService.translateAudio(filePath);
      router.pushUrl({
        url: 'pages/SpeechResult',
        params: {
          translationResponseJson: JSON.stringify(result),
          languageName: this.trip.languageName,
        },
      });
      this.mode = 'phrases';
    } catch (_) {
      this.mode = 'phrases';
    }
  }

  private goBack(): void {
    if (this.mode !== 'phrases') {
      this.mode = 'phrases';
    } else {
      router.back();
    }
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
          this.mode === 'picking'    ? 'Select Audio' :
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
              Column({ space: 6 }) {
                ForEach(this.phrases, (p: Phrase) => {
                  Column({ space: 3 }) {
                    Text(p.english)
                      .fontSize(11)
                      .fontColor('#E6EDF3')
                      .fontWeight(FontWeight.Medium)
                      .textAlign(TextAlign.Center)
                    Text(p.nativeScript)
                      .fontSize(10)
                      .fontColor('#00E5C8')
                      .textAlign(TextAlign.Center)
                      .lineHeight(14)
                  }
                  .width('100%')
                  .padding({ left: 8, right: 8, top: 8, bottom: 8 })
                  .backgroundColor('#161B22')
                  .borderRadius(8)
                })
                ForEach(this.extraPhrases, (ep: string) => {
                  Text(ep)
                    .fontSize(10)
                    .fontColor('#C9D1D9')
                    .textAlign(TextAlign.Center)
                    .width('100%')
                    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
                    .backgroundColor('#0D1B2A')
                    .borderRadius(8)
                })
                Text('').height(60)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
          }
          .width('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ left: 16, right: 16 })

          // Record button — circular teal at bottom
          Button('🎤')
            .onClick(() => this.openPicker())
            .backgroundColor('#00C4AE')
            .fontColor('#0D1117')
            .fontSize(22)
            .width(54)
            .height(54)
            .borderRadius(27)
            .margin({ bottom: 14 })
        }
      }

      // ── Picking mode ──────────────────────────────────────────────────────────
      if (this.mode === 'picking') {
        Column({ space: 10 }) {
          Text('Choose a sample')
            .fontSize(11)
            .fontColor('#8B949E')
            .margin({ top: 10 })

          ForEach(this.audioFiles, (audioFile: AudioFile, index: number) => {
            Button(audioFile.name)
              .onClick(() => this.selectAudio(index))
              .backgroundColor('#161B22')
              .fontColor('#E6EDF3')
              .fontSize(11)
              .width('82%')
              .height(38)
              .borderRadius(10)
              .border({ width: 1, color: '#00E5C8', style: BorderStyle.Solid })
          })

          Text('Tap to translate')
            .fontSize(8)
            .fontColor('#6E7681')
            .margin({ top: 4 })
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
