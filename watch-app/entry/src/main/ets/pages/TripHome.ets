/**
 * TripHome.ets — Active trip home (idle screen).
 *
 * Logo with glow rings + sheen, country name, pulsing dots, pill buttons.
 * GPS polling every 5 min → context alerts via LLM or JSON fallback.
 */
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { vibrator } from '@kit.SensorServiceKit';
import { Trip, ContextAlert, getTripStatus, formatDate } from '../common/Types';
import { LocationService } from '../services/LocationService';
import { PlacesService }   from '../services/PlacesService';
import { CountryDataService } from '../services/CountryDataService';
import { LlmService }     from '../services/LlmService';
import { AlertCooldownService } from '../services/AlertCooldownService';
import { GPS_POLL_INTERVAL_MS } from '../common/Config';

@Entry
@Component
struct TripHome {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  @State trip: Trip = JSON.parse(this.params['tripJson'] ?? '{}') as Trip;

  @State sheenOpacity: number  = 0;
  @State dot1Opacity: number   = 0.8;
  @State dot2Opacity: number   = 0.45;
  @State dot3Opacity: number   = 0.2;
  private dotTimer: number     = -1;
  private dotPhase: number     = 0;

  private locationService: LocationService     = new LocationService();
  private placesService:   PlacesService       = new PlacesService();
  private dataService:     CountryDataService  | null = null;
  private llmService:      LlmService          = new LlmService();
  private cooldown:        AlertCooldownService = new AlertCooldownService();
  private currentVenueType: string = '';

  aboutToAppear(): void {
    this.dataService = new CountryDataService(getContext(this) as common.UIAbilityContext);
    if (getTripStatus(this.trip) === 'ended') {
      router.replaceUrl({ url: 'pages/TripEnded', params: { tripJson: this.params['tripJson'] } });
      return;
    }
    // Sheen sweep on logo
    setTimeout(() => {
      animateTo({ duration: 350, curve: Curve.EaseIn }, () => { this.sheenOpacity = 0.55; });
    }, 100);
    setTimeout(() => {
      animateTo({ duration: 400, curve: Curve.EaseOut }, () => { this.sheenOpacity = 0; });
    }, 450);
    // Pulsing dots
    this.dotTimer = setInterval(() => {
      this.dotPhase = (this.dotPhase + 1) % 3;
      const p = this.dotPhase;
      animateTo({ duration: 350, curve: Curve.EaseInOut }, () => {
        this.dot1Opacity = p === 0 ? 0.8 : p === 1 ? 0.45 : 0.2;
        this.dot2Opacity = p === 1 ? 0.8 : p === 2 ? 0.45 : 0.2;
        this.dot3Opacity = p === 2 ? 0.8 : p === 0 ? 0.45 : 0.2;
      });
    }, 700);
  }

  onPageShow(): void {
    // Re-check end date each time user returns to this screen
    if (getTripStatus(this.trip) === 'ended') {
      router.replaceUrl({ url: 'pages/TripEnded', params: { tripJson: this.params['tripJson'] } });
      return;
    }
    this.startLocationPolling();
  }

  onPageHide(): void {
    this.locationService.stopPolling();
  }

  aboutToDisappear(): void {
    this.locationService.stopPolling();
    if (this.dotTimer !== -1) clearInterval(this.dotTimer);
  }

  // ── GPS & Alert pipeline ────────────────────────────────────────────────────

  private startLocationPolling(): void {
    this.locationService.startPolling(
      (lat, lng) => this.onLocationUpdate(lat, lng),
      GPS_POLL_INTERVAL_MS,
    );
  }

  private async onLocationUpdate(lat: number, lng: number): Promise<void> {
    const venueType = await this.placesService.getVenueType(lat, lng);
    if (!venueType) return;
    this.currentVenueType = venueType;

    if (!this.cooldown.canAlert(this.trip.countryCode, venueType)) return;

    const alert = await this.resolveAlert(venueType);
    if (!alert) return;

    this.cooldown.markAlerted(this.trip.countryCode, venueType);
    this.triggerAlert(alert);
  }

  private async resolveAlert(venueType: string): Promise<ContextAlert | null> {
    const llmResult = await this.llmService.generateContextAlert(this.trip.countryName, venueType);
    if (llmResult) {
      return { alertId: llmResult.alertId, message: llmResult.message, riskLevel: llmResult.riskLevel, locationName: venueType };
    }
    const fallback = await this.dataService?.getFallbackAlert(this.trip.countryCode, venueType);
    if (fallback) {
      return { alertId: fallback.alertId, message: fallback.message, riskLevel: fallback.riskLevel, locationName: venueType };
    }
    return null;
  }

  private triggerAlert(alert: ContextAlert): void {
    try {
      const pulses = alert.riskLevel === 'LEGAL' ? 3 : alert.riskLevel === 'SENSITIVE' ? 2 : 0;
      let count = 0;
      const buzz = (): void => {
        if (count >= pulses) return;
        vibrator.startVibration({ type: 'time', duration: 120 }, { id: 0, usage: 'notification' });
        count++;
        setTimeout(buzz, 250);
      };
      if (pulses > 0) buzz();
    } catch (_) {}
    router.pushUrl({
      url: 'pages/ContextAlert',
      params: { alertJson: JSON.stringify(alert), countryName: this.trip.countryName },
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  build() {
    Column({ space: 0 }) {
      // ── Back header ─────────────────────────────────────────────────────────
      Row() {
        Text('\u2190')
          .fontSize(17)
          .fontColor('#4A7A8A')
          .onClick(() => router.back())
          .padding({ left: 10, right: 8 })
        Text('My Trip')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E8F4F8')
      }
      .width('100%')
      .height(36)
      .alignItems(VerticalAlign.Center)

      Divider().color('#0D2035')

      // ── Logo + glow rings + sheen ────────────────────────────────────────────
      Column({ space: 0 }) {
        Stack() {
          Circle().width(90).height(90)
            .fillColor('transparent')
            .border({ width: 1, color: '#0A2840', radius: 45 })
          Circle().width(78).height(78)
            .fillColor('transparent')
            .border({ width: 1, color: '#163550', radius: 39 })
          Image($r('app.media.foreground'))
            .width(68).height(68)
            .borderRadius(34)
          Circle().width(68).height(68)
            .fillColor('#FFFFFF')
            .opacity(this.sheenOpacity)
        }
        .width(90).height(90)
        .margin({ top: 10 })

        Text(this.trip.countryName)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E8F4F8')
          .margin({ top: 8 })

        Text(`${formatDate(this.trip.startTimestamp)} \u2013 ${formatDate(this.trip.endTimestamp)}`)
          .fontSize(9)
          .fontColor('#4A7A8A')
          .margin({ top: 2 })

        Row({ space: 7 }) {
          Circle().width(5).height(5).fillColor('#2DD4BF').opacity(this.dot1Opacity)
          Circle().width(5).height(5).fillColor('#2DD4BF').opacity(this.dot2Opacity)
          Circle().width(5).height(5).fillColor('#2DD4BF').opacity(this.dot3Opacity)
        }
        .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // ── Pill buttons ─────────────────────────────────────────────────────────
      Column({ space: 10 }) {
        Button('Arrival Steps')
          .onClick(() => {
            router.pushUrl({ url: 'pages/ArrivalSteps', params: { tripJson: this.params['tripJson'] } });
          })
          .backgroundColor('transparent')
          .fontColor('#2DD4BF')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .width('80%')
          .height(34)
          .borderRadius(17)
          .border({ width: 1, color: '#2DD4BF' })

        Button('Convo Assist')
          .onClick(() => {
            router.pushUrl({
              url: 'pages/ConvoAssist',
              params: { tripJson: this.params['tripJson'], currentVenueType: this.currentVenueType },
            });
          })
          .backgroundColor('transparent')
          .fontColor('#4A7A8A')
          .fontSize(12)
          .width('80%')
          .height(34)
          .borderRadius(17)
          .border({ width: 1, color: '#1A3A50' })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#060D1A')
    .gesture(
      PanGesture({ direction: PanDirection.Right, distance: 50 })
        .onActionEnd(() => router.back())
    )
  }
}
