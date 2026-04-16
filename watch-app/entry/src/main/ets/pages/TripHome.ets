/**
 * TripHome.ets — Active trip home screen
 *
 * "Ready for [Country]?" hub with circular icon buttons.
 * GPS polls every 5 min → venue detect → cultural alert.
 * Trip end date check on show. Navigates to TripEnded when expired.
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
    }
  }

  onPageShow(): void {
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
    const llmResult = await this.llmService.generateContextAlert(this.trip.countryName, venueType);
    if (llmResult) {
      return {
        alertId:      llmResult.alertId,
        message:      llmResult.message,
        riskLevel:    llmResult.riskLevel,
        locationName: venueType,
      };
    }
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
    Column() {
      // Minimal back arrow
      Text('←')
        .fontSize(14)
        .fontColor('#8B949E')
        .onClick(() => router.back())
        .alignSelf(ItemAlign.Start)
        .padding({ left: 14, top: 10, bottom: 4 })

      // ── Main hub content ─────────────────────────────────────────────────────
      Column({ space: 4 }) {
        // Country flag + "Ready for X?" headline
        Text(this.trip.flag)
          .fontSize(30)

        Text('Ready for')
          .fontSize(10)
          .fontColor('#8B949E')

        Text(this.trip.countryName + '?')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E6EDF3')

        Text(`${formatDate(this.trip.startTimestamp)} – ${formatDate(this.trip.endTimestamp)}`)
          .fontSize(8)
          .fontColor('#6E7681')
          .margin({ bottom: 10 })

        // Action buttons — teal neon-glow circles with icon shapes
        Row({ space: 28 }) {

          // ── Arrival Steps ──────────────────────────────────────────────────
          Column({ space: 8 }) {
            Stack({ alignContent: Alignment.Center }) {
              // Glow circle background
              Column()
                .width(72)
                .height(72)
                .borderRadius(36)
                .backgroundColor('#071A15')
                .border({ width: 1.5, color: '#00E5C8', style: BorderStyle.Solid })
                .shadow({ radius: 18, color: '#00E5C850', offsetX: 0, offsetY: 0 })

              // Document icon: rect outline + 3 lines
              Stack({ alignContent: Alignment.Center }) {
                // Document outline
                Column()
                  .width(26)
                  .height(32)
                  .borderRadius(4)
                  .backgroundColor('transparent')
                  .border({ width: 1.5, color: '#00E5C8', style: BorderStyle.Solid })

                // Three horizontal lines inside
                Column({ space: 5 }) {
                  Row()
                    .width(16).height(1.5)
                    .backgroundColor('#00E5C8').borderRadius(1)
                  Row()
                    .width(16).height(1.5)
                    .backgroundColor('#00E5C8').borderRadius(1)
                  Row()
                    .width(11).height(1.5)
                    .backgroundColor('#00E5C8').borderRadius(1)
                }
              }
            }
            .onClick(() => {
              router.pushUrl({
                url: 'pages/ArrivalSteps',
                params: { tripJson: this.params['tripJson'] },
              });
            })

            Text('Arrival Steps')
              .fontSize(9)
              .fontColor('#8B949E')
              .textAlign(TextAlign.Center)
          }
          .alignItems(HorizontalAlign.Center)

          // ── Convo Assist ───────────────────────────────────────────────────
          Column({ space: 8 }) {
            Stack({ alignContent: Alignment.Center }) {
              // Glow circle background
              Column()
                .width(72)
                .height(72)
                .borderRadius(36)
                .backgroundColor('#071A15')
                .border({ width: 1.5, color: '#00E5C8', style: BorderStyle.Solid })
                .shadow({ radius: 18, color: '#00E5C850', offsetX: 0, offsetY: 0 })

              // Microphone icon
              Column({ space: 0 }) {
                // Mic capsule (rounded rect outline)
                Column()
                  .width(16)
                  .height(22)
                  .borderRadius(8)
                  .backgroundColor('transparent')
                  .border({ width: 1.5, color: '#00E5C8', style: BorderStyle.Solid })

                // Mic stand arc — left arm, bottom curve, right arm
                Row({ space: 0 }) {
                  // Left arm
                  Column()
                    .width(1.5).height(8)
                    .backgroundColor('#00E5C8')
                  // Bottom curve (approximated as a rounded bottom column)
                  Column()
                    .width(14).height(8)
                    .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 7, bottomRight: 7 })
                    .backgroundColor('transparent')
                    .border({ width: 1.5, color: '#00E5C8', style: BorderStyle.Solid })
                    .margin({ left: -1.5 })
                  // Right arm
                  Column()
                    .width(1.5).height(8)
                    .backgroundColor('#00E5C8')
                    .margin({ left: -1.5 })
                }
                .alignItems(VerticalAlign.Top)
                .margin({ top: 2 })

                // Vertical stem
                Column()
                  .width(1.5).height(5)
                  .backgroundColor('#00E5C8')
                  .alignSelf(ItemAlign.Center)

                // Base line
                Column()
                  .width(14).height(1.5)
                  .backgroundColor('#00E5C8')
                  .borderRadius(1)
                  .alignSelf(ItemAlign.Center)
              }
              .alignItems(HorizontalAlign.Center)
            }
            .onClick(() => {
              router.pushUrl({
                url: 'pages/ConvoAssist',
                params: {
                  tripJson: this.params['tripJson'],
                  currentVenueType: this.currentVenueType,
                },
              });
            })

            Text('Convo')
              .fontSize(9)
              .fontColor('#8B949E')
              .textAlign(TextAlign.Center)
          }
          .alignItems(HorizontalAlign.Center)
        }
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
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
