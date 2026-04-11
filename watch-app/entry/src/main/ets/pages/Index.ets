/**
 * Index.ets — ArrivalRitual Watch App
 *
 * Full wearable UI covering:
 *   1. Idle / splash screen
 *   2. Arrival checklist (step-by-step)
 *   3. Context alert (cultural / legal)
 *   4. Convo Assist (phrase list + speech result)
 *   5. Camera-lift warning (red screen, triple haptic)
 *
 * Sensor integration:
 *   - Accelerometer + Gyroscope → camera-lift gesture detection
 *   - Vibrator → risk-level haptic pulses
 *
 * Message bridge:
 *   All phone communication is via placeholder functions (sendToPhone / onPhoneMessage)
 *   that map to the Huawei WearEngine P2P API in production.
 *   Replace the TODO blocks with your WearEngine P2pClient calls.
 */

import { sensor, vibrator } from '@kit.SensorServiceKit';
import wearEngine from '@ohos.wearEngine';

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

interface SpeechResult {
  transcribedText: string;
  suggestedPhrases: string[];
  detectedLanguage: string;
}

// ── Risk colours ───────────────────────────────────────────────────────────────

function riskColor(level: string): string {
  if (level === 'LEGAL') return '#FF4444';
  if (level === 'SENSITIVE') return '#FFB800';
  return '#00E5C8';
}

function riskLabel(level: string): string {
  if (level === 'LEGAL') return '🔴 LEGAL';
  if (level === 'SENSITIVE') return '🟡 SENSITIVE';
  return '🟢 NORM';
}

// ── Haptic helpers ─────────────────────────────────────────────────────────────

async function hapticForRisk(level: string): Promise<void> {
  try {
    if (level === 'LEGAL') {
      // 3× firm buzz
      for (let i = 0; i < 3; i++) {
        await vibrator.startVibration({ type: 'time', duration: 150 }, { id: 0, usage: 'notification' });
        await new Promise(r => setTimeout(r, 200));
      }
    } else if (level === 'SENSITIVE') {
      // 2× soft pulse
      for (let i = 0; i < 2; i++) {
        await vibrator.startVibration({ type: 'time', duration: 80 }, { id: 0, usage: 'notification' });
        await new Promise(r => setTimeout(r, 150));
      }
    }
    // NORM: no haptic
  } catch (_) { /* vibrator not available in all emulators */ }
}

// ── Camera-lift gesture constants ──────────────────────────────────────────────

const LIFT_PITCH_THRESHOLD = 50.0;   // degrees — phone tilted to "camera up"
const REST_PITCH_THRESHOLD = 20.0;   // degrees — phone at rest / by side
const GYRO_LIFT_MIN        = 0.8;    // rad/s — minimum backward rotation
const DEBOUNCE_MS          = 3000;   // ms between detections

// ── Component ─────────────────────────────────────────────────────────────────

@Entry
@Component
struct Index {

  // ── Screen state ─────────────────────────────────────────────────────────────
  @State screen: Screen            = 'idle';
  @State country: string           = '';
  @State countryFlag: string       = '';

  // Arrival checklist
  @State currentStep: ArrivalStep | null = null;
  @State stepIndex: number         = 0;

  // Context alert
  @State activeAlert: ContextAlert | null = null;

  // Convo Assist
  @State phrases: string[]         = [];
  @State transcription: string     = '';
  @State selectedPhraseIdx: number = 0;

  // Speech
  @State isListening: boolean      = false;

  // Gesture
  @State gestureZoneActive: boolean = false;

  // ── WearEngine P2P ───────────────────────────────────────────────────────────
  private p2pClient: wearEngine.P2pClient | null = null;
  private targetDevice: wearEngine.Device | null = null;
  private readonly APP_ID: string                = 'com.arrivalritual.app';

  // ── Sensor state (not @State — updated at high frequency) ────────────────────
  private gravity: number[]  = [0, 0, 0];
  private gyroX: number      = 0;
  private wasResting: boolean = false;
  private lastLiftMs: number  = 0;
  private alpha: number       = 0.8;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  aboutToAppear() {
    this.startSensors();
    try {
      this.p2pClient = wearEngine.getP2pClient();
      const devices = wearEngine.getConnectedDevices();
      if (devices?.length) {
        this.targetDevice = devices[0];
      }
      this.p2pClient.registerReceiver(this.APP_ID, (message: wearEngine.Message) => {
        const raw = String.fromCharCode(...new Uint8Array(message.data));
        this.parseAndRoute(raw);
      });
    } catch (err) {
      console.error('[WearEngine] Init failed:', JSON.stringify(err));
    }
  }

  aboutToDisappear() {
    this.stopSensors();
    try {
      this.p2pClient?.unregisterReceiver(this.APP_ID);
    } catch (err) {
      console.error('[WearEngine] Cleanup failed:', JSON.stringify(err));
    } finally {
      this.p2pClient    = null;
      this.targetDevice = null;
    }
  }

  // ── Sensor setup ──────────────────────────────────────────────────────────────

  private startSensors() {
    try {
      sensor.on(sensor.SensorType.SENSOR_TYPE_ID_ACCELEROMETER, (data) => {
        this.handleAccelerometer(data.x, data.y, data.z);
      }, { interval: 'game' });

      sensor.on(sensor.SensorType.SENSOR_TYPE_ID_GYROSCOPE, (data) => {
        this.gyroX = data.x;
      }, { interval: 'game' });
    } catch (_) { /* Sensor API not available on all emulators */ }
  }

  private stopSensors() {
    try {
      sensor.off(sensor.SensorType.SENSOR_TYPE_ID_ACCELEROMETER);
      sensor.off(sensor.SensorType.SENSOR_TYPE_ID_GYROSCOPE);
    } catch (_) {}
  }

  private handleAccelerometer(ax: number, ay: number, az: number) {
    // Low-pass filter to isolate gravity
    this.gravity[0] = this.alpha * this.gravity[0] + (1 - this.alpha) * ax;
    this.gravity[1] = this.alpha * this.gravity[1] + (1 - this.alpha) * ay;
    this.gravity[2] = this.alpha * this.gravity[2] + (1 - this.alpha) * az;

    const pitch = this.calculatePitchDeg();

    if (pitch < REST_PITCH_THRESHOLD) {
      this.wasResting = true;
    }

    // Camera-lift: was resting → now above threshold + upward gyro motion + debounce
    const now = Date.now();
    if (
      this.gestureZoneActive &&
      this.wasResting &&
      pitch > LIFT_PITCH_THRESHOLD &&
      this.gyroX < -GYRO_LIFT_MIN &&
      (now - this.lastLiftMs) > DEBOUNCE_MS
    ) {
      this.lastLiftMs  = now;
      this.wasResting  = false;
      this.onCameraLiftDetected();
    }
  }

  private calculatePitchDeg(): number {
    const ax = this.gravity[0];
    const ay = this.gravity[1];
    const az = this.gravity[2];
    return (Math.atan2(ax, Math.sqrt(ay * ay + az * az)) * 180) / Math.PI;
  }

  // ── Gesture callback ──────────────────────────────────────────────────────────

  private async onCameraLiftDetected() {
    // Immediately show red warning screen
    this.screen = 'gesture_warning';
    await hapticForRisk('LEGAL');

    // Notify phone to fetch the applicable rule
    this.sendToPhone('GESTURE_DETECTED', {
      country:      this.country,
      locationType: this.activeAlert?.alertId ?? 'restricted_zone'
    });

    // Auto-dismiss after 4 s if not replaced by a proper alert from phone
    setTimeout(() => {
      if (this.screen === 'gesture_warning') this.screen = 'idle';
    }, 4000);
  }

  // ── Phone message handler ─────────────────────────────────────────────────────

  private async onPhoneMessage(type: string, payload: object) {
    switch (type) {
      case 'ARRIVAL_STEP': {
        const p = payload as ArrivalStep;
        this.currentStep = p;
        this.stepIndex   = p.stepIndex;
        this.screen      = 'checklist';
        await hapticForRisk(p.riskLevel);
        break;
      }
      case 'CONTEXT_ALERT': {
        const p = payload as ContextAlert;
        this.activeAlert = p;
        this.screen      = 'alert';
        await hapticForRisk(p.riskLevel);
        // If this came from a gesture, replace the red screen with the real alert
        break;
      }
      case 'CONVO_OPTIONS': {
        const p = payload as { options: string[] };
        this.phrases           = p.options ?? [];
        this.selectedPhraseIdx = 0;
        this.screen            = 'convo';
        break;
      }
      case 'SPEECH_ASSIST_RESULT': {
        const p = payload as SpeechResult;
        this.transcription     = p.transcribedText ?? '';
        this.phrases           = p.suggestedPhrases ?? [];
        this.selectedPhraseIdx = 0;
        this.isListening       = false;
        this.screen            = 'convo';
        break;
      }
      case 'PONG':
      default:
        break;
    }
  }

  // ── Send to phone ─────────────────────────────────────────────────────────────

  private sendToPhone(type: string, payload: object) {
    const message = JSON.stringify({ type, payload });
    if (!this.p2pClient || !this.targetDevice) {
      console.warn('[Watch→Phone] No WearEngine connection, dropping:', type);
      return;
    }
    try {
      this.p2pClient.send(this.targetDevice, { data: new Uint8Array(Buffer.from(message)) });
    } catch (err) {
      console.error('[Watch→Phone] Send failed:', JSON.stringify(err));
    }
  }

  // ── Message router ────────────────────────────────────────────────────────────

  private parseAndRoute(raw: string) {
    // Wire format: TRIGGER:SCREEN:CONTEXT_JSON
    // e.g. TRIGGER:checklist:{"stepIndex":0,"title":"Passport Control","riskLevel":"LEGAL"}
    if (!raw.startsWith('TRIGGER:')) {
      console.warn('[WearEngine] Unexpected message format:', raw);
      return;
    }
    const firstSep  = raw.indexOf(':');
    const secondSep = raw.indexOf(':', firstSep + 1);
    if (secondSep === -1) {
      console.warn('[WearEngine] Malformed TRIGGER message (missing context):', raw);
      return;
    }
    const targetScreen = raw.substring(firstSep + 1, secondSep);
    // Context JSON may itself contain colons, so rejoin everything after the second separator
    const contextJson  = raw.substring(secondSep + 1);

    try {
      const ctx = JSON.parse(contextJson);
      switch (targetScreen) {
        case 'checklist':
          this.onPhoneMessage('ARRIVAL_STEP', ctx as object);
          break;
        case 'alert':
          this.onPhoneMessage('CONTEXT_ALERT', ctx as object);
          break;
        case 'convo':
          this.onPhoneMessage('CONVO_OPTIONS', ctx as object);
          break;
        case 'speech_result':
          this.onPhoneMessage('SPEECH_ASSIST_RESULT', ctx as object);
          break;
        case 'idle':
          if (ctx.country) this.country     = ctx.country as string;
          if (ctx.flag)    this.countryFlag = ctx.flag as string;
          this.screen = 'idle';
          break;
        default:
          console.warn('[WearEngine] Unknown screen target:', targetScreen);
      }
    } catch (e) {
      console.error('[WearEngine] Context JSON parse failed for:', raw);
    }
  }

  // ── Request helpers ───────────────────────────────────────────────────────────

  private requestNextStep() {
    this.sendToPhone('REQUEST_NEXT_STEP', {
      country:          this.country,
      currentStepIndex: this.stepIndex
    });
  }

  private requestContextAlert(locationType: string) {
    this.sendToPhone('REQUEST_CONTEXT_ALERT', {
      country:      this.country,
      locationType: locationType
    });
  }

  private async startSpeechAssist() {
    this.isListening = true;
    this.screen      = 'listening';
    this.sendToPhone('REQUEST_SPEECH_ASSIST', {
      country:      this.country,
      locationType: this.activeAlert?.alertId ?? 'general',
      locale:       'en'
    });
    await hapticForRisk('NORM');
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  build() {
    Stack() {
      if (this.screen === 'idle')            { this.IdleScreen() }
      else if (this.screen === 'checklist')  { this.ChecklistScreen() }
      else if (this.screen === 'alert')      { this.AlertScreen() }
      else if (this.screen === 'convo')      { this.ConvoScreen() }
      else if (this.screen === 'listening')  { this.ListeningScreen() }
      else if (this.screen === 'gesture_warning') { this.GestureWarningScreen() }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0D1117')
  }

  // ── Screens ───────────────────────────────────────────────────────────────────

  @Builder
  IdleScreen() {
    Column({ space: 12 }) {
      Text('ArrivalRitual')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E6EDF3')

      if (this.country) {
        Text(`${this.countryFlag} ${this.country}`)
          .fontSize(14)
          .fontColor('#00E5C8')
      } else {
        Text('Waiting for journey…')
          .fontSize(11)
          .fontColor('#8B949E')
      }

      Divider().color('#21262D').width('80%')

      Button('Arrival Steps')
        .onClick(() => this.requestNextStep())
        .backgroundColor('#1F6FEB')
        .fontColor('#FFFFFF')
        .fontSize(12)
        .width('80%')

      Button('Convo Assist')
        .onClick(() => this.startSpeechAssist())
        .backgroundColor('#238636')
        .fontColor('#FFFFFF')
        .fontSize(12)
        .width('80%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ChecklistScreen() {
    Column({ space: 10 }) {
      // Header
      Row() {
        Text(`Step ${(this.currentStep?.stepIndex ?? 0) + 1}`)
          .fontSize(10)
          .fontColor('#8B949E')
        Blank()
        Text(riskLabel(this.currentStep?.riskLevel ?? 'NORM'))
          .fontSize(9)
          .fontColor(riskColor(this.currentStep?.riskLevel ?? 'NORM'))
      }
      .width('90%')

      // Title
      Text(this.currentStep?.title ?? '')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E6EDF3')
        .textAlign(TextAlign.Center)
        .width('90%')

      // Description
      Text(this.currentStep?.description ?? '')
        .fontSize(11)
        .fontColor('#C9D1D9')
        .textAlign(TextAlign.Center)
        .width('90%')
        .lineHeight(16)

      // Risk bar
      Divider()
        .color(riskColor(this.currentStep?.riskLevel ?? 'NORM'))
        .width('60%')
        .strokeWidth(2)

      // Next step button
      Button('Next Step ›')
        .onClick(() => {
          this.stepIndex += 1;
          this.requestNextStep();
        })
        .backgroundColor('#1F6FEB')
        .fontColor('#FFFFFF')
        .fontSize(12)
        .width('75%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(16)
  }

  @Builder
  AlertScreen() {
    Column({ space: 10 }) {
      // Risk badge
      Row() {
        Text(riskLabel(this.activeAlert?.riskLevel ?? 'NORM'))
          .fontSize(11)
          .fontColor(riskColor(this.activeAlert?.riskLevel ?? 'NORM'))
          .fontWeight(FontWeight.Bold)
      }

      // Alert message
      Text(this.activeAlert?.message ?? '')
        .fontSize(12)
        .fontColor('#E6EDF3')
        .textAlign(TextAlign.Center)
        .width('90%')
        .lineHeight(18)

      Divider().color('#21262D').width('80%')

      Row({ space: 10 }) {
        Button('OK')
          .onClick(() => { this.screen = 'idle'; })
          .backgroundColor('#21262D')
          .fontColor('#8B949E')
          .fontSize(11)
          .width('40%')

        Button('Phrases')
          .onClick(() => { this.startSpeechAssist(); })
          .backgroundColor('#238636')
          .fontColor('#FFFFFF')
          .fontSize(11)
          .width('40%')
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(16)
    .backgroundColor(
      this.activeAlert?.riskLevel === 'LEGAL' ? '#1A0000' :
      this.activeAlert?.riskLevel === 'SENSITIVE' ? '#1A1200' : '#0D1117'
    )
  }

  @Builder
  ConvoScreen() {
    Column({ space: 8 }) {
      // Transcription (if available)
      if (this.transcription) {
        Text(`"${this.transcription}"`)
          .fontSize(10)
          .fontColor('#8B949E')
          .fontStyle(FontStyle.Italic)
          .textAlign(TextAlign.Center)
          .width('90%')

        Divider().color('#21262D').width('80%')
      }

      Text('Say this:')
        .fontSize(10)
        .fontColor('#8B949E')

      // Selected phrase (large)
      Text(this.phrases[this.selectedPhraseIdx] ?? '')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00E5C8')
        .textAlign(TextAlign.Center)
        .width('90%')
        .lineHeight(20)

      // Swipe indicator
      Text(`${this.selectedPhraseIdx + 1} / ${this.phrases.length}`)
        .fontSize(9)
        .fontColor('#8B949E')

      // Navigation
      Row({ space: 12 }) {
        Button('‹')
          .onClick(() => {
            if (this.selectedPhraseIdx > 0) this.selectedPhraseIdx -= 1;
          })
          .backgroundColor('#21262D')
          .fontColor('#E6EDF3')
          .fontSize(16)
          .width('30%')

        Button('›')
          .onClick(() => {
            if (this.selectedPhraseIdx < this.phrases.length - 1)
              this.selectedPhraseIdx += 1;
          })
          .backgroundColor('#21262D')
          .fontColor('#E6EDF3')
          .fontSize(16)
          .width('30%')
      }

      Button('Listen Again')
        .onClick(() => { this.startSpeechAssist(); })
        .backgroundColor('#238636')
        .fontColor('#FFFFFF')
        .fontSize(10)
        .width('70%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(12)
  }

  @Builder
  ListeningScreen() {
    Column({ space: 14 }) {
      Text('🎤')
        .fontSize(36)

      Text('Listening…')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00E5C8')

      Text('Recording for 5 seconds')
        .fontSize(10)
        .fontColor('#8B949E')

      Text('Hold steady near the speaker')
        .fontSize(9)
        .fontColor('#6E7681')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#0D1117')
  }

  @Builder
  GestureWarningScreen() {
    Column({ space: 14 }) {
      Text('📷')
        .fontSize(40)

      Text('CAMERA RESTRICTED')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF4444')
        .textAlign(TextAlign.Center)

      Text('Photography may not be\npermitted here.')
        .fontSize(11)
        .fontColor('#E6EDF3')
        .textAlign(TextAlign.Center)
        .lineHeight(18)

      Text('🔴 LEGAL RISK')
        .fontSize(10)
        .fontColor('#FF4444')

      Button('Dismiss')
        .onClick(() => { this.screen = this.activeAlert ? 'alert' : 'idle'; })
        .backgroundColor('#21262D')
        .fontColor('#8B949E')
        .fontSize(11)
        .width('60%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(16)
    .backgroundColor('#1A0000')
  }
}
