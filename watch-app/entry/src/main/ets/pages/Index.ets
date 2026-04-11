/**
 * Index.ets — ArrivalRitual Watch App (Polished UI v2)
 */

import { sensor, vibrator } from '@kit.SensorServiceKit';

// ── Types ──────────────────────────────────────────────────────────────────────

type Screen = 'idle' | 'checklist' | 'alert' | 'convo' | 'gesture_warning' | 'listening';

interface ArrivalStep {
  stepIndex: number;
  title: string;
  description: string;
  riskLevel: 'NORM' | 'SENSITIVE' | 'LEGAL';
}

interface ContextAlert {
  alertId: string;
  message: string;
  riskLevel: 'NORM' | 'SENSITIVE' | 'LEGAL';
}

interface PhonePayloadStep {
  stepIndex: number;
  title: string;
  description: string;
  riskLevel: 'NORM' | 'SENSITIVE' | 'LEGAL';
}

interface PhonePayloadAlert {
  alertId: string;
  message: string;
  riskLevel: 'NORM' | 'SENSITIVE' | 'LEGAL';
}

interface PhonePayloadOptions {
  options: string[];
}

interface PhonePayloadSpeech {
  transcribedText: string;
  suggestedPhrases: string[];
  detectedLanguage: string;
}

interface PhonePayloadIdle {
  country: string;
  flag: string;
}

interface SendPayloadNextStep {
  country: string;
  currentStepIndex: number;
}

interface SendPayloadSpeechAssist {
  country: string;
  locationType: string;
  locale: string;
}

interface SendPayloadGesture {
  country: string;
  locationType: string;
}

// ── Helpers ────────────────────────────────────────────────────────────────────

function riskColor(level: string): string {
  if (level === 'LEGAL') return '#FF4444';
  if (level === 'SENSITIVE') return '#FFB800';
  return '#2DD4BF';
}

function riskBg(level: string): string {
  if (level === 'LEGAL') return '#2A0000';
  if (level === 'SENSITIVE') return '#2A1A00';
  return '#060D1A';
}

function riskLabel(level: string): string {
  if (level === 'LEGAL') return 'LEGAL';
  if (level === 'SENSITIVE') return 'SENSITIVE';
  return 'NORM';
}

async function hapticForRisk(level: string): Promise<void> {
  try {
    if (level === 'LEGAL') {
      for (let i = 0; i < 3; i++) {
        await vibrator.startVibration(
          { type: 'time', duration: 150 },
          { id: 0, usage: 'notification' }
        );
        await new Promise<void>((r) => setTimeout(r, 200));
      }
    } else if (level === 'SENSITIVE') {
      for (let i = 0; i < 2; i++) {
        await vibrator.startVibration(
          { type: 'time', duration: 80 },
          { id: 0, usage: 'notification' }
        );
        await new Promise<void>((r) => setTimeout(r, 150));
      }
    }
  } catch (_e) {}
}

const LIFT_PITCH_THRESHOLD: number = 50.0;
const REST_PITCH_THRESHOLD: number = 20.0;
const GYRO_LIFT_MIN: number        = 0.8;
const DEBOUNCE_MS: number          = 3000;

// ── Component ──────────────────────────────────────────────────────────────────

@Entry
@Component
struct Index {

  @State screen: Screen                   = 'idle';
  @State country: string                  = '';
  @State countryFlag: string              = '';
  @State currentStep: ArrivalStep | null  = null;
  @State stepIndex: number                = 0;
  @State totalSteps: number               = 5;
  @State activeAlert: ContextAlert | null = null;
  @State phrases: string[]                = [];
  @State transcription: string            = '';
  @State selectedPhraseIdx: number        = 0;
  @State isListening: boolean             = false;
  @State gestureZoneActive: boolean       = false;
  @State dotOpacity1: number              = 1.0;
  @State dotOpacity2: number              = 0.4;
  @State dotOpacity3: number              = 0.2;

  private gravity: number[]   = [0, 0, 0];
  private gyroX: number       = 0;
  private wasResting: boolean = false;
  private lastLiftMs: number  = 0;
  private alpha: number       = 0.8;
  private pulseTimer: number  = -1;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  aboutToAppear(): void {
    this.startSensors();
    this.startPulseAnimation();
  }

  aboutToDisappear(): void {
    this.stopSensors();
    clearInterval(this.pulseTimer);
  }

  private startPulseAnimation(): void {
    let step: number = 0;
    this.pulseTimer = setInterval(() => {
      step = (step + 1) % 3;
      if (step === 0) {
        this.dotOpacity1 = 1.0;
        this.dotOpacity2 = 0.4;
        this.dotOpacity3 = 0.2;
      } else if (step === 1) {
        this.dotOpacity1 = 0.4;
        this.dotOpacity2 = 1.0;
        this.dotOpacity3 = 0.4;
      } else {
        this.dotOpacity1 = 0.2;
        this.dotOpacity2 = 0.4;
        this.dotOpacity3 = 1.0;
      }
    }, 600);
  }

  // ── Sensors ──────────────────────────────────────────────────────────────────

  private startSensors(): void {
    try {
      sensor.on(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse) => {
        this.handleAccelerometer(data.x, data.y, data.z);
      }, { interval: 100000000 });
      sensor.on(sensor.SensorId.GYROSCOPE, (data: sensor.GyroscopeResponse) => {
        this.gyroX = data.x;
      }, { interval: 100000000 });
    } catch (_e) {}
  }

  private stopSensors(): void {
    try {
      sensor.off(sensor.SensorId.ACCELEROMETER);
      sensor.off(sensor.SensorId.GYROSCOPE);
    } catch (_e) {}
  }

  private handleAccelerometer(ax: number, ay: number, az: number): void {
    this.gravity[0] = this.alpha * this.gravity[0] + (1 - this.alpha) * ax;
    this.gravity[1] = this.alpha * this.gravity[1] + (1 - this.alpha) * ay;
    this.gravity[2] = this.alpha * this.gravity[2] + (1 - this.alpha) * az;
    const pitch: number = this.calculatePitchDeg();
    if (pitch < REST_PITCH_THRESHOLD) { this.wasResting = true; }
    const now: number = Date.now();
    if (
      this.gestureZoneActive && this.wasResting &&
        pitch > LIFT_PITCH_THRESHOLD && this.gyroX < -GYRO_LIFT_MIN &&
        (now - this.lastLiftMs) > DEBOUNCE_MS
    ) {
      this.lastLiftMs = now;
      this.wasResting = false;
      this.onCameraLiftDetected();
    }
  }

  private calculatePitchDeg(): number {
    const ax: number = this.gravity[0];
    const ay: number = this.gravity[1];
    const az: number = this.gravity[2];
    return (Math.atan2(ax, Math.sqrt(ay * ay + az * az)) * 180) / Math.PI;
  }

  private async onCameraLiftDetected(): Promise<void> {
    this.screen = 'gesture_warning';
    await hapticForRisk('LEGAL');
    const payload: SendPayloadGesture = {
      country: this.country,
      locationType: this.activeAlert?.alertId ?? 'restricted_zone'
    };
    this.sendToPhone('GESTURE_DETECTED', JSON.stringify(payload));
    setTimeout(() => {
      if (this.screen === 'gesture_warning') { this.screen = 'idle'; }
    }, 4000);
  }

  // ── Message handling ──────────────────────────────────────────────────────────

  private async onPhoneMessage(type: string, payload: string): Promise<void> {
    switch (type) {
      case 'ARRIVAL_STEP': {
        const p: PhonePayloadStep = JSON.parse(payload) as PhonePayloadStep;
        this.currentStep = { stepIndex: p.stepIndex, title: p.title, description: p.description, riskLevel: p.riskLevel };
        this.stepIndex   = p.stepIndex;
        this.screen      = 'checklist';
        await hapticForRisk(p.riskLevel);
        break;
      }
      case 'CONTEXT_ALERT': {
        const p: PhonePayloadAlert = JSON.parse(payload) as PhonePayloadAlert;
        this.activeAlert = { alertId: p.alertId, message: p.message, riskLevel: p.riskLevel };
        this.screen      = 'alert';
        await hapticForRisk(p.riskLevel);
        break;
      }
      case 'CONVO_OPTIONS': {
        const p: PhonePayloadOptions = JSON.parse(payload) as PhonePayloadOptions;
        this.phrases           = p.options ?? [];
        this.selectedPhraseIdx = 0;
        this.screen            = 'convo';
        break;
      }
      case 'SPEECH_ASSIST_RESULT': {
        const p: PhonePayloadSpeech = JSON.parse(payload) as PhonePayloadSpeech;
        this.transcription     = p.transcribedText ?? '';
        this.phrases           = p.suggestedPhrases ?? [];
        this.selectedPhraseIdx = 0;
        this.isListening       = false;
        this.screen            = 'convo';
        break;
      }
      default: break;
    }
  }

  private sendToPhone(type: string, payloadJson: string): void {
    console.info('[Watch→Phone]', `TRIGGER:${type}:${payloadJson}`);
  }

  private parseAndRoute(raw: string): void {
    if (!raw.startsWith('TRIGGER:')) { return; }
    const firstSep: number  = raw.indexOf(':');
    const secondSep: number = raw.indexOf(':', firstSep + 1);
    if (secondSep === -1) { return; }
    const targetScreen: string = raw.substring(firstSep + 1, secondSep);
    const contextJson: string  = raw.substring(secondSep + 1);
    try {
      const parsed: PhonePayloadIdle = JSON.parse(contextJson) as PhonePayloadIdle;
      switch (targetScreen) {
        case 'checklist':     this.onPhoneMessage('ARRIVAL_STEP', contextJson); break;
        case 'alert':         this.onPhoneMessage('CONTEXT_ALERT', contextJson); break;
        case 'convo':         this.onPhoneMessage('CONVO_OPTIONS', contextJson); break;
        case 'speech_result': this.onPhoneMessage('SPEECH_ASSIST_RESULT', contextJson); break;
        case 'idle':
          if (parsed.country) { this.country = parsed.country; }
          if (parsed.flag)    { this.countryFlag = parsed.flag; }
          this.screen = 'idle';
          break;
        default: break;
      }
    } catch (_e) {}
  }

  private requestNextStep(): void {
    const payload: SendPayloadNextStep = { country: this.country, currentStepIndex: this.stepIndex };
    this.sendToPhone('REQUEST_NEXT_STEP', JSON.stringify(payload));
  }

  private async startSpeechAssist(): Promise<void> {
    this.isListening = true;
    this.screen      = 'listening';
    const payload: SendPayloadSpeechAssist = {
      country: this.country,
      locationType: this.activeAlert?.alertId ?? 'general',
      locale: 'en'
    };
    this.sendToPhone('REQUEST_SPEECH_ASSIST', JSON.stringify(payload));
    await hapticForRisk('NORM');
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  build() {
    Stack() {
      if (this.screen === 'idle')                 { this.IdleScreen() }
      else if (this.screen === 'checklist')       { this.ChecklistScreen() }
      else if (this.screen === 'alert')           { this.AlertScreen() }
      else if (this.screen === 'convo')           { this.ConvoScreen() }
      else if (this.screen === 'listening')       { this.ListeningScreen() }
      else if (this.screen === 'gesture_warning') { this.GestureWarningScreen() }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#060D1A')
  }

  @Builder
  IdleScreen() {
    Column({ space: 0 }) {

      Image($r('app.media.foreground'))
        .width(68)
        .height(68)
        .borderRadius(34)
        .margin({ bottom: 6 })

      Text('ArrivalRitual')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E8F4F8')
        .letterSpacing(0.5)
        .margin({ bottom: 4 })

      if (this.country) {
        Text(`${this.countryFlag}  ${this.country}`)
          .fontSize(12)
          .fontColor('#2DD4BF')
          .margin({ bottom: 10 })
      } else {
        Row({ space: 4 }) {
          Circle({ width: 5, height: 5 }).fill('#2DD4BF').opacity(this.dotOpacity1)
          Circle({ width: 5, height: 5 }).fill('#2DD4BF').opacity(this.dotOpacity2)
          Circle({ width: 5, height: 5 }).fill('#2DD4BF').opacity(this.dotOpacity3)
        }
        .margin({ bottom: 3 })

        Text('Ready')
          .fontSize(10)
          .fontColor('#4A7A8A')
          .margin({ bottom: 10 })
      }

      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Text('✈')
            .fontSize(12)
            .fontColor('#2DD4BF')
          Text('Arrival Steps')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#E8F4F8')
        }
        .width('78%')
        .height(34)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#0D2035')
        .borderRadius(17)
        .border({ width: 1, color: '#2DD4BF', style: BorderStyle.Solid })
        .onClick(() => { this.requestNextStep(); })

        Row({ space: 8 }) {
          Text('🎤')
            .fontSize(12)
          Text('Convo Assist')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#E8F4F8')
        }
        .width('78%')
        .height(34)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#0D2035')
        .borderRadius(17)
        .border({ width: 1, color: '#1A4A6A', style: BorderStyle.Solid })
        .onClick(() => { this.startSpeechAssist(); })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 22, right: 22 })
  }

  @Builder
  ChecklistScreen() {
    Column({ space: 0 }) {

      Row() {
        Text(`${(this.currentStep?.stepIndex ?? 0) + 1} of ${this.totalSteps}`)
          .fontSize(10)
          .fontColor('#4A7A8A')
          .letterSpacing(0.5)
        Blank()
        Text(riskLabel(this.currentStep?.riskLevel ?? 'NORM'))
          .fontSize(9)
          .fontColor(riskColor(this.currentStep?.riskLevel ?? 'NORM'))
          .fontWeight(FontWeight.Bold)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(riskBg(this.currentStep?.riskLevel ?? 'NORM'))
          .borderRadius(10)
          .border({ width: 1, color: riskColor(this.currentStep?.riskLevel ?? 'NORM'), style: BorderStyle.Solid })
      }
      .width('88%')
      .margin({ bottom: 8 })

      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('88%')
          .height(3)
          .backgroundColor('#0D2035')
          .borderRadius(2)
        Row()
          .width(`${((this.stepIndex + 1) / this.totalSteps) * 88}%`)
          .height(3)
          .backgroundColor(riskColor(this.currentStep?.riskLevel ?? 'NORM'))
          .borderRadius(2)
      }
      .margin({ bottom: 12 })

      Text(this.currentStep?.title ?? '')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E8F4F8')
        .textAlign(TextAlign.Center)
        .width('88%')
        .margin({ bottom: 8 })

      Text(this.currentStep?.description ?? '')
        .fontSize(11)
        .fontColor('#7A9AAA')
        .textAlign(TextAlign.Center)
        .width('88%')
        .lineHeight(16)
        .margin({ bottom: 16 })

      Row() {
        Text('Next  ›')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#060D1A')
      }
      .width('72%')
      .height(36)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#2DD4BF')
      .borderRadius(18)
      .onClick(() => {
        this.stepIndex += 1;
        this.requestNextStep();
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(16)
    .backgroundColor('#060D1A')
  }

  @Builder
  AlertScreen() {
    Column({ space: 0 }) {

      Text(riskLabel(this.activeAlert?.riskLevel ?? 'NORM'))
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor(riskColor(this.activeAlert?.riskLevel ?? 'NORM'))
        .letterSpacing(2)
        .padding({ left: 12, right: 12, top: 4, bottom: 4 })
        .backgroundColor(riskBg(this.activeAlert?.riskLevel ?? 'NORM'))
        .borderRadius(12)
        .border({ width: 1, color: riskColor(this.activeAlert?.riskLevel ?? 'NORM'), style: BorderStyle.Solid })
        .margin({ bottom: 12 })

      Row()
        .width('70%')
        .height(1)
        .backgroundColor(riskColor(this.activeAlert?.riskLevel ?? 'NORM'))
        .opacity(0.4)
        .margin({ bottom: 12 })

      Text(this.activeAlert?.message ?? '')
        .fontSize(13)
        .fontColor('#E8F4F8')
        .textAlign(TextAlign.Center)
        .width('88%')
        .lineHeight(20)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      Row({ space: 10 }) {
        Row() {
          Text('OK')
            .fontSize(12)
            .fontColor('#4A7A8A')
            .fontWeight(FontWeight.Medium)
        }
        .width('38%')
        .height(34)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#0D2035')
        .borderRadius(17)
        .border({ width: 1, color: '#1A4A6A', style: BorderStyle.Solid })
        .onClick(() => { this.screen = 'idle'; })

        Row() {
          Text('Phrases')
            .fontSize(12)
            .fontColor('#060D1A')
            .fontWeight(FontWeight.Medium)
        }
        .width('38%')
        .height(34)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#2DD4BF')
        .borderRadius(17)
        .onClick(() => { this.startSpeechAssist(); })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(16)
    .backgroundColor(riskBg(this.activeAlert?.riskLevel ?? 'NORM'))
  }

  @Builder
  ConvoScreen() {
    Column({ space: 0 }) {

      Text('CONVO ASSIST')
        .fontSize(9)
        .fontColor('#4A7A8A')
        .letterSpacing(2)
        .margin({ bottom: 10 })

      if (this.transcription) {
        Text(`"${this.transcription}"`)
          .fontSize(10)
          .fontColor('#4A7A8A')
          .fontStyle(FontStyle.Italic)
          .textAlign(TextAlign.Center)
          .width('88%')
          .margin({ bottom: 8 })

        Row()
          .width('60%')
          .height(1)
          .backgroundColor('#1A3A5A')
          .margin({ bottom: 8 })
      }

      Column({ space: 4 }) {
        Text(this.phrases[this.selectedPhraseIdx] ?? 'No phrase available')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2DD4BF')
          .textAlign(TextAlign.Center)
          .width('100%')
          .lineHeight(22)
      }
      .width('84%')
      .padding({ left: 12, right: 12, top: 14, bottom: 14 })
      .backgroundColor('#0A1E30')
      .borderRadius(14)
      .border({ width: 1, color: '#1A4A6A', style: BorderStyle.Solid })
      .margin({ bottom: 10 })

      Row({ space: 6 }) {
        ForEach(this.phrases, (phrase: string, index: number) => {
          Circle({ width: 5, height: 5 })
            .fill(index === this.selectedPhraseIdx ? '#2DD4BF' : '#1A3A5A')
        })
      }
      .margin({ bottom: 10 })

      Row({ space: 10 }) {
        Row() {
          Text('‹')
            .fontSize(18)
            .fontColor('#2DD4BF')
        }
        .width(36).height(36)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#0D2035')
        .borderRadius(18)
        .border({ width: 1, color: '#1A4A6A', style: BorderStyle.Solid })
        .onClick(() => {
          if (this.selectedPhraseIdx > 0) { this.selectedPhraseIdx -= 1; }
        })

        Row() {
          Text('🎤').fontSize(14)
        }
        .width(36).height(36)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#2DD4BF')
        .borderRadius(18)
        .onClick(() => { this.startSpeechAssist(); })

        Row() {
          Text('›')
            .fontSize(18)
            .fontColor('#2DD4BF')
        }
        .width(36).height(36)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#0D2035')
        .borderRadius(18)
        .border({ width: 1, color: '#1A4A6A', style: BorderStyle.Solid })
        .onClick(() => {
          if (this.selectedPhraseIdx < this.phrases.length - 1) {
            this.selectedPhraseIdx += 1;
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(14)
    .backgroundColor('#060D1A')
  }

  @Builder
  ListeningScreen() {
    Column({ space: 0 }) {

      Stack() {
        Circle({ width: 72, height: 72 })
          .fill('transparent')
          .stroke('#2DD4BF')
          .strokeWidth(1)
          .opacity(0.2)

        Circle({ width: 56, height: 56 })
          .fill('transparent')
          .stroke('#2DD4BF')
          .strokeWidth(1.5)
          .opacity(0.4)

        Circle({ width: 42, height: 42 })
          .fill('#0D2035')
          .stroke('#2DD4BF')
          .strokeWidth(2)

        Text('🎤').fontSize(18)
      }
      .width(72).height(72)
      .margin({ bottom: 14 })

      Text('Listening')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2DD4BF')
        .margin({ bottom: 6 })

      Row({ space: 5 }) {
        Circle({ width: 5, height: 5 }).fill('#2DD4BF').opacity(this.dotOpacity1)
        Circle({ width: 5, height: 5 }).fill('#2DD4BF').opacity(this.dotOpacity2)
        Circle({ width: 5, height: 5 }).fill('#2DD4BF').opacity(this.dotOpacity3)
      }
      .margin({ bottom: 10 })

      Text('Hold near the speaker')
        .fontSize(10)
        .fontColor('#4A7A8A')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#060D1A')
  }

  @Builder
  GestureWarningScreen() {
    Column({ space: 0 }) {

      Stack() {
        Circle({ width: 80, height: 80 })
          .fill('transparent')
          .stroke('#FF4444')
          .strokeWidth(1)
          .opacity(0.2)

        Circle({ width: 62, height: 62 })
          .fill('transparent')
          .stroke('#FF4444')
          .strokeWidth(1.5)
          .opacity(0.4)

        Circle({ width: 48, height: 48 })
          .fill('#2A0000')
          .stroke('#FF4444')
          .strokeWidth(2)

        Text('📵').fontSize(20)
      }
      .width(80).height(80)
      .margin({ bottom: 12 })

      Text('RESTRICTED')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF4444')
        .letterSpacing(2)
        .margin({ bottom: 2 })

      Text('ZONE')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF4444')
        .letterSpacing(3)
        .opacity(0.8)
        .margin({ bottom: 8 })

      Text('Put device away')
        .fontSize(10)
        .fontColor('#AA6666')
        .margin({ bottom: 14 })

      Row({ space: 6 }) {
        Circle({ width: 5, height: 5 }).fill('#FF4444')
        Circle({ width: 5, height: 5 }).fill('#FF4444').opacity(0.4)
        Circle({ width: 5, height: 5 }).fill('#FF4444').opacity(0.2)
      }
      .margin({ bottom: 14 })

      Row() {
        Text('Dismiss')
          .fontSize(11)
          .fontColor('#AA6666')
      }
      .width('55%')
      .height(32)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#1A0808')
      .borderRadius(16)
      .border({ width: 1, color: '#440000', style: BorderStyle.Solid })
      .onClick(() => { this.screen = this.activeAlert ? 'alert' : 'idle'; })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(16)
    .backgroundColor('#0A0000')
  }
}