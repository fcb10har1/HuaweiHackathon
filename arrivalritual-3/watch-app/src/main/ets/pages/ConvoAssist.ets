/**
 * ConvoAssist.ets  — v2
 * ─────────────────────────────────────────────────────────────────────────────
 * Feature 2: Convo Assist — Language Shield (full UX flow)
 *
 * Changes from v1:
 *   1. Watch can initiate a new phrase from the result screen (crown press)
 *   2. Reverse-translate screen — "They said" when other party responds
 *   3. GPS context auto-suggested via AppStore geofence zone
 *   4. Processing skeleton state between recording and result
 */

import router from '@ohos.router';
import { VoiceRecorderService, SuggestedPhrase } from '../services/VoiceRecorderService';
import { appStore } from '../store/AppStore';
import { RecordingState, ConvoPhrase, EMERGENCY_PHRASES } from '../model/TravelData';
import { HapticsService, HapticPattern } from '../services/HapticsService';

enum ConvoScreen {
  IDLE = 'idle', LISTEN = 'listen', PROCESS = 'process',
  RESULT = 'result', REVERSE = 'reverse', ERROR = 'error',
}

interface ReversePhrase { foreign: string; english: string; fromLang: string; }

const DEMO_REVERSE: Record<string, ReversePhrase> = {
  taxi:        { foreign: 'メーターを使ってください',    english: 'Use the meter',           fromLang: 'JP' },
  temple:      { foreign: 'ขอบคุณมากครับ',              english: 'Thank you very much',     fromLang: 'TH' },
  airport:     { foreign: 'こちらへどうぞ',              english: 'Please come this way',    fromLang: 'JP' },
  immigration: { foreign: 'جواز السفر من فضلك',         english: 'Passport please',         fromLang: 'AR' },
};

@Entry
@Component
struct ConvoAssist {
  @State private screen: ConvoScreen = ConvoScreen.RESULT;
  @State private suggestedPhrase: SuggestedPhrase | null = {
    local: '新宿駅までお願いします',
    english: 'Take me to Shinjuku Station',
    pronunciation: 'shinjuku-eki made onegaishimasu',
    canPlayback: true,
  };
  @State private reversePhrase: ReversePhrase | null = null;
  @State private showEmergency: boolean = false;
  @State private playingBack: boolean = false;

  private _listener = (state: RecordingState, phrase?: SuggestedPhrase) => {
    switch (state) {
      case RecordingState.RECORDING:   this.screen = ConvoScreen.LISTEN;  break;
      case RecordingState.PROCESSING:  this.screen = ConvoScreen.PROCESS; break;
      case RecordingState.COMPLETE:
        if (phrase) this.suggestedPhrase = phrase;
        this.screen = ConvoScreen.RESULT;
        HapticsService.trigger(HapticPattern.DOUBLE_SOFT);
        break;
      case RecordingState.ERROR:
        this.screen = ConvoScreen.ERROR;
        HapticsService.trigger(HapticPattern.LONG_BUZZ);
        setTimeout(() => { this.screen = ConvoScreen.IDLE; }, 2000);
        break;
    }
  };

  aboutToAppear() {
    VoiceRecorderService.setContext(appStore.currentScenario.type);
    VoiceRecorderService.addListener(this._listener);
  }

  aboutToDisappear() {
    VoiceRecorderService.removeListener(this._listener);
    VoiceRecorderService.reset();
  }

  private get emergencyPhrases(): ConvoPhrase[] {
    return (EMERGENCY_PHRASES[appStore.currentScenario.country.code] ?? [])
      .filter(p => p.isEmergency);
  }

  private onCrownPress(): void {
    switch (this.screen) {
      case ConvoScreen.IDLE:
      case ConvoScreen.RESULT:
      case ConvoScreen.ERROR:
        this.suggestedPhrase = null;
        VoiceRecorderService.reset();
        VoiceRecorderService.startRecording();
        break;
      case ConvoScreen.LISTEN:
        VoiceRecorderService.stopEarly();
        break;
      case ConvoScreen.REVERSE:
        this.reversePhrase = null;
        this.screen = ConvoScreen.RESULT;
        break;
    }
  }

  /** Called when BLE event arrives from phone: other party responded */
  showReverseTranslate(): void {
    const ctx = appStore.currentScenario.type;
    this.reversePhrase = DEMO_REVERSE[ctx] ?? DEMO_REVERSE.taxi;
    this.screen = ConvoScreen.REVERSE;
    HapticsService.trigger(HapticPattern.DOUBLE_SOFT);
  }

  build() {
    Column() {
      // ── Header ──────────────────────────────────────────
      Row() {
        Text('←').fontSize(16).fontColor('#666666').padding(6).onClick(() => router.back())
        Text('Convo Assist').fontSize(12).fontColor('#CCCCCC').layoutWeight(1).textAlign(TextAlign.Center)
        Text(appStore.currentScenario.country.flag).fontSize(14).padding(6)
      }
      .width('100%').padding({ top: 8, left: 2, right: 2 })

      // GPS context auto-suggest badge
      Row() {
        Text('📍 GPS: ' + appStore.currentScenario.label)
          .fontSize(8).fontColor('#81C784')
      }
      .backgroundColor('#81C78411').borderRadius(5)
      .padding({ left: 7, right: 7, top: 3, bottom: 3 }).margin({ bottom: 5 })

      Text(`EN → ${appStore.currentScenario.country.languageCode.toUpperCase()}`)
        .fontSize(9).fontColor('#555555').margin({ bottom: 5 })

      // ── Screen: RESULT (Language Shield) ────────────────
      if (this.screen === ConvoScreen.RESULT && this.suggestedPhrase) {
        Column() {
          Text(this.suggestedPhrase!.local)
            .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
            .textAlign(TextAlign.Center).margin({ bottom: 4 }).padding({ left: 6, right: 6 })
          Text(this.suggestedPhrase!.english)
            .fontSize(10).fontColor('#AAAAAA').margin({ bottom: 3 })
          Text(`/${this.suggestedPhrase!.pronunciation}/`)
            .fontSize(9).fontColor('#555555').fontStyle(FontStyle.Italic).margin({ bottom: 10 })
          Button(this.playingBack ? '▶ Playing…' : '▶ Play for them')
            .width('80%').height(34).fontSize(10).fontWeight(FontWeight.Bold)
            .fontColor('#0D0D0D').backgroundColor('#4FC3F7').borderRadius(10)
            .onClick(() => {
              this.playingBack = true;
              HapticsService.trigger(HapticPattern.SINGLE_SOFT);
              setTimeout(() => { this.playingBack = false; }, 2000);
            })
        }
        .layoutWeight(1).width('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        .backgroundColor('#0D1A0D').borderRadius(14).margin({ left: 8, right: 8, bottom: 6 })

      // ── Screen: LISTEN ───────────────────────────────────
      } else if (this.screen === ConvoScreen.LISTEN) {
        Column() {
          Text('●').fontSize(20).fontColor('#EF5350').margin({ bottom: 6 })
          Text('Listening…').fontSize(12).fontColor('#CCCCCC').margin({ bottom: 4 })
          Text('Crown press to stop early').fontSize(9).fontColor('#555555')
        }
        .layoutWeight(1).width('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)

      // ── Screen: PROCESSING (skeleton) ────────────────────
      } else if (this.screen === ConvoScreen.PROCESS) {
        Column() {
          Text('⏳').fontSize(18).margin({ bottom: 8 })
          Text('Translating…').fontSize(10).fontColor('#FFB300').margin({ bottom: 12 })
          Column() {
            Divider().strokeWidth(6).color('#1C1C1E').borderRadius(3).margin({ bottom: 6 })
            Divider().strokeWidth(6).color('#1C1C1E').borderRadius(3).width('70%')
          }
          .width('80%')
        }
        .layoutWeight(1).width('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)

      // ── Screen: REVERSE ──────────────────────────────────
      } else if (this.screen === ConvoScreen.REVERSE) {
        Column() {
          Text('THEY SAID')
            .fontSize(7).fontColor('#FFB300').fontWeight(FontWeight.Bold)
            .letterSpacing(2).margin({ bottom: 6 })
          Text(this.reversePhrase?.foreign ?? '')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFB300')
            .textAlign(TextAlign.Center).margin({ bottom: 4 }).lineHeight(22)
            .padding({ left: 6, right: 6 })
          Text(this.reversePhrase?.english ?? '')
            .fontSize(11).fontColor('#CCCCCC').textAlign(TextAlign.Center).margin({ bottom: 6 })
          Text('Reverse translated from ' + (this.reversePhrase?.fromLang ?? ''))
            .fontSize(8).fontColor('#666666')
        }
        .layoutWeight(1).width('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        .backgroundColor('#1A1A0D').borderRadius(14).margin({ left: 8, right: 8, bottom: 6 })
        .border({ width: 0.5, color: '#FFB30033' })

      // ── Screen: IDLE / ERROR ─────────────────────────────
      } else {
        Column() {
          Text(this.screen === ConvoScreen.ERROR ? '✗' : '🎤').fontSize(24).margin({ bottom: 8 })
          Text(this.screen === ConvoScreen.ERROR
            ? 'Not recognised.\nSpeak closer.'
            : 'Press crown to\ncapture speech')
            .fontSize(10).fontColor('#888888').textAlign(TextAlign.Center).lineHeight(15)
        }
        .layoutWeight(1).width('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      }

      // ── Emergency phrases ────────────────────────────────
      Text(this.showEmergency ? '▴ Hide emergency phrases' : '▾ Emergency phrases')
        .fontSize(9).fontColor('#555555').margin({ bottom: 4 })
        .onClick(() => { this.showEmergency = !this.showEmergency; })

      if (this.showEmergency) {
        Scroll() {
          Column() {
            ForEach(this.emergencyPhrases, (phrase: ConvoPhrase) => {
              Row() {
                Text(phrase.local).fontSize(10).fontColor('#FFFFFF').layoutWeight(1)
                Text(phrase.english).fontSize(9).fontColor('#888888')
              }
              .width('100%').padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor('#1C1C1E').borderRadius(8).margin({ bottom: 4 })
            })
          }.padding({ left: 8, right: 8 })
        }
        .maxHeight(80).scrollBar(BarState.Off).margin({ bottom: 4 })
      }

      // ── Crown button ─────────────────────────────────────
      Button(
        this.screen === ConvoScreen.LISTEN  ? '● Stop recording' :
        this.screen === ConvoScreen.PROCESS ? '⏳ Translating…'  :
        this.screen === ConvoScreen.RESULT  ? '🎤 New phrase'    :
        this.screen === ConvoScreen.REVERSE ? '← Back'          :
        '🎤 Press crown'
      )
        .width('84%').height(42).fontSize(11).fontWeight(FontWeight.Bold)
        .fontColor(this.screen === ConvoScreen.LISTEN ? '#FFFFFF' : '#0D0D0D')
        .backgroundColor(
          this.screen === ConvoScreen.LISTEN  ? '#EF5350' :
          this.screen === ConvoScreen.PROCESS ? '#FFB300' :
          this.screen === ConvoScreen.RESULT  ? '#81C784' :
          this.screen === ConvoScreen.REVERSE ? '#FFB300' :
          '#4FC3F7'
        )
        .borderRadius(14).margin({ bottom: 12 })
        .enabled(this.screen !== ConvoScreen.PROCESS)
        .onClick(() => this.onCrownPress())
    }
    .width('100%').height('100%').backgroundColor('#0D0D0D')
    .alignItems(HorizontalAlign.Center)
  }
}
