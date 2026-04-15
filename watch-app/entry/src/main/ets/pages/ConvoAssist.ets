/**
 * ConvoAssist.ets — Conversational assistance screen
 *
 * Two modes:
 *   Normal — scrollable list of useful phrases (English + local script)
 *            sourced from JSON (always) + LLM extras (when online)
 *            Phrases are context-aware based on currentVenueType from GPS
 *   Listening — 5-second recording UI, then navigates to SpeechResult
 */
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { vibrator } from '@kit.SensorServiceKit';
import { Trip, Phrase } from '../common/Types';
import { CountryDataService } from '../services/CountryDataService';
import { LlmService }         from '../services/LlmService';

type ConvoMode = 'phrases' | 'listening' | 'processing';

@Entry
@Component
struct ConvoAssist {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private trip: Trip = JSON.parse(this.params['tripJson'] ?? '{}') as Trip;
  private venueType: string = this.params['currentVenueType'] ?? '';

  @State mode: ConvoMode       = 'phrases';
  @State phrases: Phrase[]     = [];
  @State extraPhrases: string[] = [];   // LLM-generated extras (English only)
  @State loadingPhrases: boolean = true;
  @State countdown: number     = 5;

  private countdownTimer: number = -1;
  private dataService: CountryDataService | null = null;
  private llmService: LlmService = new LlmService();
  private ctx: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    this.ctx = getContext(this) as common.UIAbilityContext;
    this.dataService = new CountryDataService(this.ctx);
    this.loadPhrases();
  }

  aboutToDisappear(): void {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer);
    }
  }

  private loadPhrases(): void {
    // Load JSON phrases (location-aware if venueType known)
    const scenarioId = this.venueType || '';
    this.dataService?.getPhrases(this.trip.countryCode, scenarioId).then(phrases => {
      this.phrases = phrases;
      this.loadingPhrases = false;
      // Load LLM extras concurrently (show when ready)
      this.llmService.generateExtraPhrases(this.trip.countryName, this.venueType || 'general')
        .then(extras => {
          this.extraPhrases = extras;
        });
    });
  }

  private startListening(): void {
    this.mode      = 'listening';
    this.countdown = 5;
    try {
      vibrator.startVibration({ type: 'time', duration: 80 }, { id: 0, usage: 'notification' });
    } catch (_) {}

    this.countdownTimer = setInterval(() => {
      this.countdown -= 1;
      if (this.countdown <= 0) {
        clearInterval(this.countdownTimer);
        this.countdownTimer = -1;
        this.mode = 'processing';
        this.runSpeechPipeline();
      }
    }, 1000);
  }

  private runSpeechPipeline(): void {
    if (!this.ctx) return;
    this.llmService.transcribeAndReply(
      this.ctx,
      this.trip.countryName,
      this.venueType || 'general',
      this.trip.languageName,
      this.trip.languageLocale,
    ).then(result => {
      router.pushUrl({
        url: 'pages/SpeechResult',
        params: {
          transcribedEnglish: result.transcribedEnglish,
          repliesJson:        JSON.stringify(result.replies),
          languageName:       this.trip.languageName,
        },
      });
      // Reset mode for when user comes back
      this.mode = 'phrases';
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  build() {
    Column() {
      // ── Header ──────────────────────────────────────────────────────────────
      Row() {
        Text('\u2190')
          .fontSize(17)
          .fontColor('#4A7A8A')
          .onClick(() => {
            if (this.mode !== 'phrases') {
              if (this.countdownTimer !== -1) {
                clearInterval(this.countdownTimer);
                this.countdownTimer = -1;
              }
              this.mode = 'phrases';
            } else {
              router.back();
            }
          })
          .padding({ left: 10, right: 8 })
        Text(this.mode === 'phrases' ? 'Convo Assist' :
             this.mode === 'listening' ? 'Listening...' : 'Processing...')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E8F4F8')
      }
      .width('100%')
      .height(36)
      .alignItems(VerticalAlign.Center)

      Divider().color('#0D2035')

      // ── Phrases mode ─────────────────────────────────────────────────────────
      if (this.mode === 'phrases') {
        if (this.loadingPhrases) {
          Column() {
            Text('Loading phrases...')
              .fontSize(12)
              .fontColor('#8B949E')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          Column() {
            if (this.venueType) {
              Text(this.venueType)
                .fontSize(9)
                .fontColor('#2DD4BF')
                .padding({ left: 12, top: 4, bottom: 2 })
                .width('100%')
            }

            Text('Useful Phrases')
              .fontSize(10)
              .fontColor('#4A7A8A')
              .padding({ left: 12, bottom: 4 })
              .width('100%')

            Scroll() {
              Column({ space: 7 }) {
                ForEach(this.phrases, (p: Phrase) => {
                  Column({ space: 3 }) {
                    Text(p.english)
                      .fontSize(11)
                      .fontColor('#E8F4F8')
                      .fontWeight(FontWeight.Medium)
                    Text(p.nativeScript)
                      .fontSize(10)
                      .fontColor('#2DD4BF')
                  }
                  .width('100%')
                  .padding({ left: 12, right: 12, top: 7, bottom: 7 })
                  .backgroundColor('#0D2035')
                  .borderRadius(6)
                  .border({ width: 1, color: '#143050' })
                })
                ForEach(this.extraPhrases, (ep: string) => {
                  Text(ep)
                    .fontSize(10)
                    .fontColor('#A0BEC8')
                    .width('100%')
                    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
                    .backgroundColor('#0A1828')
                    .borderRadius(6)
                })
                Text('').height(50)
              }
              .width('100%')
              .padding({ left: 10, right: 10 })
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
          }
          .width('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button('Mic — Listen')
            .onClick(() => this.startListening())
            .backgroundColor('transparent')
            .fontColor('#2DD4BF')
            .fontSize(12)
            .width('75%')
            .height(34)
            .borderRadius(17)
            .border({ width: 1, color: '#2DD4BF' })
            .margin({ bottom: 12 })
        }
      }

      // ── Listening mode ───────────────────────────────────────────────────────
      if (this.mode === 'listening') {
        Column({ space: 14 }) {
          Text(`${this.countdown}`)
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2DD4BF')
          Text('Listening')
            .fontSize(13)
            .fontColor('#E8F4F8')
          Text('Hold near the speaker')
            .fontSize(10)
            .fontColor('#4A7A8A')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      if (this.mode === 'processing') {
        Column({ space: 12 }) {
          Text('Processing...')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E8F4F8')
          Text('Translating and generating replies')
            .fontSize(10)
            .fontColor('#4A7A8A')
            .textAlign(TextAlign.Center)
            .width('80%')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#060D1A')
    .gesture(
      PanGesture({ direction: PanDirection.Right, distance: 50 })
        .onActionEnd(() => {
          if (this.mode !== 'phrases') {
            if (this.countdownTimer !== -1) {
              clearInterval(this.countdownTimer);
              this.countdownTimer = -1;
            }
            this.mode = 'phrases';
          } else {
            router.back();
          }
        })
    )
  }
}
