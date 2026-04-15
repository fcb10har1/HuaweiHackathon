/**
 * TripHome.ets — Active trip home screen
 *
 * Shows country banner, "Arrival Steps" and "Convo Assist" buttons.
 * Runs GPS polling every 5 min while visible → detects venue type via Google Places
 * → generates cultural alert via LLM (or JSON fallback) → pushes ContextAlert page.
 *
 * GPS polling starts on onPageShow() and stops on onPageHide().
 * When the trip end date has passed, navigates to TripEnded.
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

  @State statusText: string = '';   // e.g. "Detecting location..."

  private locationService: LocationService     = new LocationService();
  private placesService:   PlacesService       = new PlacesService();
  private dataService:     CountryDataService  | null = null;
  private llmService:      LlmService          = new LlmService();
  private cooldown:        AlertCooldownService = new AlertCooldownService();
  // Current detected venue type — passed to ConvoAssist for context-aware phrases
  private currentVenueType: string = '';

  aboutToAppear(): void {
    this.dataService = new CountryDataService(getContext(this) as common.UIAbilityContext);
    // Check if trip already ended
    if (getTripStatus(this.trip) === 'ended') {
      router.replaceUrl({ url: 'pages/TripEnded', params: { tripJson: this.params['tripJson'] } });
    }
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
    // 1. Try LLM
    const llmResult = await this.llmService.generateContextAlert(this.trip.countryName, venueType);
    if (llmResult) {
      return {
        alertId:      llmResult.alertId,
        message:      llmResult.message,
        riskLevel:    llmResult.riskLevel,
        locationName: venueType,
      };
    }
    // 2. JSON fallback
    const fallback = await this.dataService?.getFallbackAlert(this.trip.countryCode, venueType);
    if (fallback) {
      return {
        alertId:      fallback.alertId,
        message:      fallback.message,
        riskLevel:    fallback.riskLevel,
        locationName: venueType,
      };
    }
    return null;
  }

  private triggerAlert(alert: ContextAlert): void {
    // Haptic based on risk
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
      params: {
        alertJson:   JSON.stringify(alert),
        countryName: this.trip.countryName,
      },
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  build() {
    Column() {
      // Header
      Text('←')
        .fontSize(14)
        .fontColor('#8B949E')
        .onClick(() => router.back())
        .width('100%')
        .padding(8)

      // Country info (centered)
      Column({ space: 1 }) {
        Text(this.trip.flag)
          .fontSize(22)
        Text(this.trip.countryName)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E6EDF3')
        Text(`${formatDate(this.trip.startTimestamp)} – ${formatDate(this.trip.endTimestamp)}`)
          .fontSize(7)
          .fontColor('#8B949E')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 4, bottom: 8 })

      // Buttons (MUST be visible)
      Column({ space: 6 }) {
        Button('Arrival\nSteps')
          .onClick(() => {
            router.pushUrl({
              url: 'pages/ArrivalSteps',
              params: { tripJson: this.params['tripJson'] },
            });
          })
          .backgroundColor('#1F6FEB')
          .fontColor('#FFFFFF')
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .width('50%')
          .height(36)

        Button('Convo\nAssist')
          .onClick(() => {
            router.pushUrl({
              url: 'pages/ConvoAssist',
              params: {
                tripJson: this.params['tripJson'],
                currentVenueType: this.currentVenueType,
              },
            });
          })
          .backgroundColor('#238636')
          .fontColor('#FFFFFF')
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .width('50%')
          .height(36)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0D1117')
    .gesture(
      PanGesture({ direction: PanDirection.Right, distance: 50 })
        .onActionEnd(() => router.back())
    )
  }
}
