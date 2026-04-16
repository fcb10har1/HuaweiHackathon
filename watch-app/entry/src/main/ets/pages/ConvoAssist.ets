/**
 * ConvoAssist.ets — Conversational assistance screen
 *
 * Two modes:
 *   phrases   — scrollable list of useful phrases; tap card to flip and see translation
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
  @State flippedIdx: number     = -1;   // which phrase card is showing translation
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

  private getFixedPhrases(): Phrase[] {
    const jpPhrases: Phrase[] = [
      { english: 'Hello', nativeScript: 'こんにちは', romanized: 'Konnichiwa' } as Phrase,
      { english: 'Goodbye', nativeScript: 'さようなら', romanized: 'Sayonara' } as Phrase,
      { english: 'Please', nativeScript: 'お願いします', romanized: 'Onegaishimasu' } as Phrase,
      { english: 'Thank you', nativeScript: 'ありがとうございます', romanized: 'Arigatou gozaimasu' } as Phrase,
      { english: 'Yes', nativeScript: 'はい', romanized: 'Hai' } as Phrase,
      { english: 'No', nativeScript: 'いいえ', romanized: 'Iie' } as Phrase,
      { english: 'Excuse me', nativeScript: 'すみません', romanized: 'Sumimasen' } as Phrase,
      { english: 'Sorry', nativeScript: '申し訳ありません', romanized: 'Moushiwake arimasen' } as Phrase,
      { english: 'Do you speak English?', nativeScript: '英語を話せますか？', romanized: 'Eigo o hanasemasu ka?' } as Phrase,
      { english: 'Where is the bathroom?', nativeScript: 'お手洗いはどこですか？', romanized: 'Otearai wa doko desu ka?' } as Phrase,
    ];
    const thPhrases: Phrase[] = [
      { english: 'Hello', nativeScript: 'สวัสดี', romanized: 'Sawasdee' } as Phrase,
      { english: 'Goodbye', nativeScript: 'ลาก่อน', romanized: 'Laa gon' } as Phrase,
      { english: 'Please', nativeScript: 'กรุณา', romanized: 'Karuna' } as Phrase,
      { english: 'Thank you', nativeScript: 'ขอบคุณ', romanized: 'Khop khun' } as Phrase,
      { english: 'Yes', nativeScript: 'ใช่', romanized: 'Chai' } as Phrase,
      { english: 'No', nativeScript: 'ไม่', romanized: 'Mai' } as Phrase,
      { english: 'Excuse me', nativeScript: 'ขอโทษ', romanized: 'Khor thot' } as Phrase,
      { english: 'Sorry', nativeScript: 'ขอโทษ', romanized: 'Khor thot' } as Phrase,
      { english: 'Do you speak English?', nativeScript: 'คุณพูดภาษาอังกฤษได้ไหม', romanized: 'Khun phut phasa angkrit dai mai?' } as Phrase,
      { english: 'Where is the bathroom?', nativeScript: 'ห้องน้ำอยู่ที่ไหน', romanized: 'Hong nam yu thi nai?' } as Phrase,
    ];
    const idPhrases: Phrase[] = [
      { english: 'Hello', nativeScript: 'Halo', romanized: 'Halo' } as Phrase,
      { english: 'Goodbye', nativeScript: 'Selamat tinggal', romanized: 'Selamat tinggal' } as Phrase,
      { english: 'Please', nativeScript: 'Tolong', romanized: 'Tolong' } as Phrase,
      { english: 'Thank you', nativeScript: 'Terima kasih', romanized: 'Terima kasih' } as Phrase,
      { english: 'Yes', nativeScript: 'Ya', romanized: 'Ya' } as Phrase,
      { english: 'No', nativeScript: 'Tidak', romanized: 'Tidak' } as Phrase,
      { english: 'Excuse me', nativeScript: 'Permisi', romanized: 'Permisi' } as Phrase,
      { english: 'Sorry', nativeScript: 'Maaf', romanized: 'Maaf' } as Phrase,
      { english: 'Do you speak English?', nativeScript: 'Apakah Anda bisa berbahasa Inggris?', romanized: 'Apakah Anda bisa berbahasa Inggris?' } as Phrase,
      { english: 'Where is the bathroom?', nativeScript: 'Di mana kamar mandi?', romanized: 'Di mana kamar mandi?' } as Phrase,
    ];
    
    const phraseSets: Record<string, Phrase[]> = {};
    phraseSets['jp'] = jpPhrases;
    phraseSets['th'] = thPhrases;
    phraseSets['id'] = idPhrases;

    const countryCode = this.trip.countryCode.toLowerCase();
    return phraseSets[countryCode] ?? jpPhrases;
  }

  aboutToAppear(): void {
    this.ctx = getContext(this) as common.UIAbilityContext;
    this.dataService = new CountryDataService(this.ctx);
    this.loadPhrases();
  }

  private loadPhrases(): void {
    this.phrases = this.getFixedPhrases();
    this.extraPhrases = [];
    this.loadingPhrases = false;
  }

  private flipCard(idx: number): void {
    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
      this.flippedIdx = this.flippedIdx === idx ? -1 : idx;
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
    this.mode = 'phrases';
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  build() {
    Column() {

      // ── Header — title truly centred via Stack overlay ───────────────────────
      Stack({ alignContent: Alignment.Center }) {
        Text(
          this.mode === 'picking'    ? 'Select Audio' :
          this.mode === 'processing' ? 'Translating...' :
                                       'Convo Assist'
        )
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .width('100%')

        Row() {
          Text('←')
            .fontSize(18)
            .fontColor('#8B949E')
            .padding({ left: 12, right: 8 })
            .onClick(() => {
              if (this.mode !== 'phrases') {
                this.mode = 'phrases';
              } else {
                router.back();
              }
            })
          Blank()
        }
        .width('100%')
      }
      .width('100%')
      .height(40)

      Divider().color('#21262D')

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

            // Venue context label
            if (this.venueType) {
              Text(this.venueType.toUpperCase())
                .fontSize(8)
                .fontColor('#00E5C8')
                .letterSpacing(1.5)
                .margin({ top: 8, bottom: 2 })
            }

            // Section label — padded away from divider
            Text('Useful Phrases')
              .fontSize(10)
              .fontColor('#8B949E')
              .margin({ top: 10, bottom: 8 })

            // Scrollable phrase cards
            Scroll() {
              Column({ space: 8 }) {

                // JSON phrases — English on front, native on back (flip on tap)
                ForEach(this.phrases, (p: Phrase, idx: number) => {
                  Column({ space: 6 }) {
                    if (this.flippedIdx === idx) {
                      // ── Flipped: native script large so locals can read it ──
                      Text(p.nativeScript || p.english)
                        .fontSize(22)
                        .fontColor('#00E5C8')
                        .fontWeight(FontWeight.Bold)
                        .textAlign(TextAlign.Center)
                        .width('100%')
                        .lineHeight(30)
                      if (p.romanized) {
                        Text(p.romanized)
                          .fontSize(10)
                          .fontColor('#6E9E98')
                          .textAlign(TextAlign.Center)
                          .width('100%')
                          .lineHeight(15)
                      }
                      Text('Tap to go back')
                        .fontSize(8)
                        .fontColor('#3A5050')
                        .textAlign(TextAlign.Center)
                        .margin({ top: 4 })
                    } else {
                      // ── Default: English ──
                      Text(p.english)
                        .fontSize(12)
                        .fontColor('#E6EDF3')
                        .fontWeight(FontWeight.Medium)
                        .textAlign(TextAlign.Center)
                        .width('100%')
                        .lineHeight(18)
                      Text('Tap to translate')
                        .fontSize(8)
                        .fontColor('#4A5568')
                        .textAlign(TextAlign.Center)
                        .margin({ top: 4 })
                    }
                  }
                  .width('86%')
                  .padding({ left: 14, right: 14, top: 14, bottom: 14 })
                  .backgroundColor(this.flippedIdx === idx ? '#0A1E1A' : '#161B22')
                  .borderRadius(12)
                  .border({
                    width: 1,
                    color: this.flippedIdx === idx ? '#00E5C8' : '#21262D',
                    style: BorderStyle.Solid,
                  })
                  .alignItems(HorizontalAlign.Center)
                  .onClick(() => this.flipCard(idx))
                })

                // LLM extras (English only, no flip)
                ForEach(this.extraPhrases, (ep: string) => {
                  Column() {
                    Text(ep)
                      .fontSize(11)
                      .fontColor('#C9D1D9')
                      .textAlign(TextAlign.Center)
                      .width('100%')
                      .lineHeight(17)
                  }
                  .width('80%')
                  .padding({ left: 14, right: 14, top: 12, bottom: 12 })
                  .backgroundColor('#0D1B2A')
                  .borderRadius(12)
                  .alignItems(HorizontalAlign.Center)
                })

                // Bottom spacer so last card isn't hidden behind mic button
                Text('').height(44)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .friction(6.0)
          }
          .width('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          // ── Teal mic circle button — fixed, does not scroll ────────────────
          Stack({ alignContent: Alignment.Center }) {
            // Circle background
            Column()
              .width(28)
              .height(28)
              .borderRadius(14)
              .backgroundColor('#00C4AE')
              .shadow({ radius: 6, color: '#00C4AE50', offsetX: 0, offsetY: 0 })

            // Mic: just 2 shapes — pill head + U arc
            Column({ space: 1 }) {
              // Mic head — solid white pill
              Column()
                .width(6)
                .height(9)
                .borderRadius(3)
                .backgroundColor('#FFFFFF')

              // Stand — U arc only, no stem/base
              Column()
                .width(10)
                .height(4)
                .backgroundColor('transparent')
                .border({
                  width: { top: 0, left: 1.5, right: 1.5, bottom: 1.5 },
                  color: '#FFFFFF',
                  style: BorderStyle.Solid,
                  radius: { topLeft: 0, topRight: 0, bottomLeft: 5, bottomRight: 5 },
                })
            }
            .alignItems(HorizontalAlign.Center)
          }
          .onClick(() => this.startFilePicker())
          .margin({ bottom: 10 })
        }
      }

      // ── Picking mode ──────────────────────────────────────────────────────────
      if (this.mode === 'picking') {
        Column({ space: 12 }) {
          Text('Select Audio File')
            .fontSize(10)
            .fontColor('#8B949E')
            .margin({ top: 10 })

          Column({ space: 10 }) {
            ForEach(this.audioFiles, (audioFile: AudioFile, index: number) => {
              Row() {
                Text(audioFile.name)
                  .fontSize(13)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
                  .width('100%')
              }
              .width('78%')
              .height(44)
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .backgroundColor('#0A0F14')
              .borderRadius(22)
              .border({ width: 1.5, color: '#00E5C8', style: BorderStyle.Solid })
              .onClick(() => this.selectAudioFile(index))
            })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Start)
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
