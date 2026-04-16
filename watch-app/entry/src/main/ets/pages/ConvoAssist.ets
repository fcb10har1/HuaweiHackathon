/**
 * ConvoAssist.ets — Conversational assistance screen
 *
 * Modes:
 *   phrases   — scrollable list of useful phrases (JSON + LLM extras)
 *   listening — mic active, 5-second recording countdown
 *   processing — transcribing and generating replies via LLM
 */
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { vibrator } from '@kit.SensorServiceKit';
import { Trip, Phrase, SpeechReply, TranslationResponse } from '../common/Types';
import { CountryDataService } from '../services/CountryDataService';
import { LlmService, TranscribeResult } from '../services/LlmService';
import { MIC_DURATION_MS } from '../common/Config';

type ConvoMode = 'phrases' | 'listening' | 'processing';

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
  @State secondsLeft: number    = 0;

  private dataService: CountryDataService | null = null;
  private llmService: LlmService = new LlmService();
  private ctx: common.UIAbilityContext | null = null;
  private countdownTimer: number = -1;
  private cancelled: boolean = false;

  aboutToAppear(): void {
    this.ctx = getContext(this) as common.UIAbilityContext;
    this.dataService = new CountryDataService(this.ctx);
    this.loadPhrases();
  }

  aboutToDisappear(): void {
    this.stopCountdown();
    this.cancelled = true;
  }

  private loadPhrases(): void {
    this.dataService?.getPhrases(this.trip.countryCode, this.venueType).then(phrases => {
      this.phrases = phrases;
      this.loadingPhrases = false;
      this.llmService.generateExtraPhrases(this.trip.countryName, this.venueType || 'general')
        .then(extras => { this.extraPhrases = extras; });
    });
  }

  private startCountdown(): void {
    this.secondsLeft = Math.ceil(MIC_DURATION_MS / 1000);
    this.countdownTimer = setInterval(() => {
      if (this.secondsLeft > 1) {
        this.secondsLeft--;
      } else {
        this.stopCountdown();
      }
    }, 1000);
  }

  private stopCountdown(): void {
    if (this.countdownTimer >= 0) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = -1;
    }
  }

  private goBack(): void {
    this.cancelled = true;
    this.stopCountdown();
    if (this.mode !== 'phrases') {
      this.mode = 'phrases';
    } else {
      router.back();
    }
  }

  private async startListening(): Promise<void> {
    if (!this.ctx) return;
    this.cancelled = false;

    try {
      vibrator.startVibration({ type: 'time', duration: 80 }, { id: 0, usage: 'notification' });
    } catch (_) {}

    this.mode = 'listening';
    this.startCountdown();

    // Switch to processing display after the recording phase ends
    setTimeout(() => {
      this.stopCountdown();
      if (this.mode === 'listening') {
        this.mode = 'processing';
      }
    }, MIC_DURATION_MS + 300);

    try {
      const result: TranscribeResult = await this.llmService.transcribeAndReply(
        this.ctx,
        this.trip.countryName,
        this.venueType || 'general',
        this.trip.languageName,
        this.trip.languageLocale,
      );

      if (this.cancelled) return;

      // Map TranscribeResult → TranslationResponse for SpeechResult page
      const localReplies: string[] = result.replies.map((r: SpeechReply) => r.local || r.english);
      const englishReplies: string[] = result.replies.map((r: SpeechReply) => r.english);

      const translationResp: TranslationResponse = {
        sourceLanguage: this.trip.languageLocale,
        transcript: '',
        translationEnglish: result.transcribedEnglish,
        replySuggestionsJapanese: localReplies,
        ttsAudioUrl: '',
        suggestionTranslations: englishReplies,
      };

      this.navigateToResult(translationResp);
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
          this.mode === 'listening'  ? 'Listening...' :
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
            .onClick(() => this.startListening())
            .backgroundColor('#238636')
            .fontColor('#FFFFFF')
            .fontSize(22)
            .width(54)
            .height(54)
            .borderRadius(27)
            .margin({ bottom: 14 })
        }
      }

      // ── Listening mode ────────────────────────────────────────────────────────
      if (this.mode === 'listening') {
        Column({ space: 10 }) {
          Text('🎤')
            .fontSize(42)
          Text('Listening')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00E5C8')
          Text(`${this.secondsLeft}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E6EDF3')
          Text(`Speak in ${this.trip.languageName}`)
            .fontSize(9)
            .fontColor('#8B949E')
            .textAlign(TextAlign.Center)
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
