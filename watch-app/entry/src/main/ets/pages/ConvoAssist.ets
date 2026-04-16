/**
 * ConvoAssist.ets — Conversational assistance screen
 *
 * phrases   — scrollable phrase cards + Speak button
 * picking   — clean audio sample list
 * processing — translating spinner
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
    { name: '🇯🇵  Japanese',   file: 'japanese_sample.wav'   },
    { name: '🇹🇭  Thai',       file: 'thai_sample.wav'       },
    { name: '🇮🇩  Indonesian', file: 'indonesian_sample.wav' },
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
      vibrator.startVibration({ type: 'time', duration: 40 }, { id: 0, usage: 'notification' });
    } catch (_) {}
    this.mode = 'picking';
  }

  private async selectAudio(index: number): Promise<void> {
    this.mode = 'processing';
    try {
      const result = await this.translationService.translateAudio(this.audioFiles[index].file);
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
          .fontSize(16)
          .fontColor('#8B949E')
          .onClick(() => this.goBack())
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
              .onClick(() => this.openPicker())
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
              .onClick(() => this.selectAudio(index))
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
        .onActionEnd(() => this.goBack())
    )
  }
}
