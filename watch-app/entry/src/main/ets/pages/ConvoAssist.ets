/**
 * ConvoAssist.ets — Conversational assistance screen
 *
 * Two modes:
 *   Normal — scrollable list of useful phrases (English + local script)
 *            sourced from JSON (always) + LLM extras (when online)
 *            Phrases are context-aware based on currentVenueType from GPS
 *   Listening — file picker UI, then navigates to SpeechResult
 *   Processing — uploading and translating
 */
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { vibrator } from '@kit.SensorServiceKit';
import { picker } from '@kit.CoreFileKit';
import { Trip, Phrase, TranslationResponse } from '../common/Types';
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

  @State mode: ConvoMode       = 'phrases';
  @State phrases: Phrase[]     = [];
  @State extraPhrases: string[] = [];   // LLM-generated extras (English only)
  @State loadingPhrases: boolean = true;

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
        .then(extras => {
          this.extraPhrases = extras;
        });
    });
  }

  private async startFilePicker(): Promise<void> {
    this.mode = 'picking';
    try {
      vibrator.startVibration({ type: 'time', duration: 80 }, { id: 0, usage: 'notification' });
    } catch (_) {}

    try {
      const result = await picker.pick({
        filterExtensions: [],
      }) as Promise<string[]>;

      if (result && result.length > 0) {
        const pickedUri: string = result[0];
        console.info('[ConvoAssist] Selected file:', pickedUri);
        this.mode = 'processing';
        await this.uploadAndTranslate(pickedUri);
      } else {
        // User cancelled picker
        this.mode = 'phrases';
      }
    } catch (e) {
      console.error('[ConvoAssist] File picker failed:', JSON.stringify(e));
      this.mode = 'phrases';
    }
  }

  private async uploadAndTranslate(filePath: string): Promise<void> {
    try {
      const result = await this.translationService.translateAudio(filePath);
      this.navigateToResult(result);
    } catch (e) {
      console.error('[ConvoAssist] Translation failed:', JSON.stringify(e));
      // Show error and go back to phrases
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
          .fontSize(18)
          .fontColor('#8B949E')
          .onClick(() => {
            if (this.mode !== 'phrases') {
              this.mode = 'phrases';
            } else {
              router.back();
            }
          })
          .padding({ left: 8, right: 8 })
        Text(this.mode === 'phrases' ? 'Convo Assist' :
             this.mode === 'picking' ? 'Select Audio…' : 'Processing...')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E6EDF3')
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)

      Divider().color('#21262D')

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
            // Context label
            if (this.venueType) {
              Text(`📍 ${this.venueType}`)
                .fontSize(10)
                .fontColor('#00E5C8')
                .padding({ left: 14, top: 6, bottom: 4 })
                .width('100%')
            }

            Text('Useful Phrases')
              .fontSize(11)
              .fontColor('#8B949E')
              .padding({ left: 14, bottom: 4 })
              .width('100%')

            // Scrollable phrase list
            Scroll() {
              Column({ space: 8 }) {
                // JSON phrases (English + native script)
                ForEach(this.phrases, (p: Phrase) => {
                  Column({ space: 4 }) {
                    Text(p.english)
                      .fontSize(12)
                      .fontColor('#E6EDF3')
                      .fontWeight(FontWeight.Medium)
                    Text(p.nativeScript)
                      .fontSize(11)
                      .fontColor('#00E5C8')
                  }
                  .width('100%')
                  .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                  .backgroundColor('#161B22')
                  .borderRadius(6)
                })
                // LLM extras (English only, shown when loaded)
                ForEach(this.extraPhrases, (ep: string) => {
                  Text(ep)
                    .fontSize(11)
                    .fontColor('#C9D1D9')
                    .width('100%')
                    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                    .backgroundColor('#0D1B2A')
                    .borderRadius(6)
                })
                // Bottom spacer so mic button doesn't overlap last phrase
                Text('').height(60)
              }
              .width('100%')
              .padding({ left: 10, right: 10 })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          // Mic button — now opens file picker (still feels natural for demo)
          Button('🎤  Listen')
            .onClick(() => this.startFilePicker())
            .backgroundColor('#238636')
            .fontColor('#FFFFFF')
            .fontSize(13)
            .width('75%')
            .height(40)
            .margin({ bottom: 14 })
        }
      }

      // ── Picking mode ──────────────────────────────────────────────────────────
      if (this.mode === 'picking') {
        Column({ space: 16 }) {
          Text('🎤')
            .fontSize(40)
            .fontColor('#00E5C8')
          Text('Selecting...')
            .fontSize(14)
            .fontColor('#E6EDF3')
          Text('Choose an audio file')
            .fontSize(10)
            .fontColor('#8B949E')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // ── Processing mode ───────────────────────────────────────────────────────
      if (this.mode === 'processing') {
        Column({ space: 14 }) {
          Text('⚙️')
            .fontSize(36)
          Text('Processing...')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E6EDF3')
          Text('Translating audio')
            .fontSize(10)
            .fontColor('#8B949E')
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
