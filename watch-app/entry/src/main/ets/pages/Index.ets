/**
 * Index.ets — Trip List (Home Screen)
 *
 * Shows all saved trips. User can:
 *   - Tap a trip to open it (active trips go to TripHome, ended trips go to TripEnded)
 *   - Long-press a trip to delete it
 *   - Tap + to add a new trip
 */
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { vibrator } from '@kit.SensorServiceKit';
import { Trip, getTripStatus, formatDate, riskColor } from '../common/Types';
import { StorageService } from '../services/StorageService';

@Entry
@Component
struct Index {
  @State trips: Trip[]            = [];
  @State deletingId: string       = '';  // trip being long-pressed (shows confirm)
  private storage: StorageService | null = null;

  aboutToAppear(): void {
    this.storage = new StorageService(getContext(this) as common.UIAbilityContext);
    this.loadTrips();
  }

  onPageShow(): void {
    // Refresh when navigating back from add/trip screens
    this.loadTrips();
  }

  private loadTrips(): void {
    this.storage?.loadTrips().then(trips => {
      this.trips = trips;
    });
  }

  private deleteTrip(id: string): void {
    this.storage?.deleteTrip(id).then(updated => {
      this.trips = updated;
      this.deletingId = '';
    });
  }

  private openTrip(trip: Trip): void {
    const status = getTripStatus(trip);
    if (status === 'ended') {
      router.pushUrl({ url: 'pages/TripEnded', params: { tripJson: JSON.stringify(trip) } });
    } else {
      router.pushUrl({ url: 'pages/TripHome', params: { tripJson: JSON.stringify(trip) } });
    }
  }

  private statusBadge(trip: Trip): string {
    const s = getTripStatus(trip);
    if (s === 'active')   return 'ACTIVE';
    if (s === 'upcoming') return 'UPCOMING';
    return 'ENDED';
  }

  private statusColor(trip: Trip): string {
    const s = getTripStatus(trip);
    if (s === 'active')   return '#00E5C8';
    if (s === 'upcoming') return '#1F6FEB';
    return '#8B949E';
  }

  build() {
    Column() {
      // ── Header ──────────────────────────────────────────────────────────────
      Row() {
        Text('ArrivalRitual')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E6EDF3')
        Blank()
        Text('+')
          .fontSize(22)
          .fontColor('#00E5C8')
          .onClick(() => router.pushUrl({ url: 'pages/AddTripCountry' }))
          .padding(4)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 6 })

      Divider().color('#21262D').width('100%')

      // ── Trip list ────────────────────────────────────────────────────────────
      if (this.trips.length === 0) {
        Column({ space: 10 }) {
          Text('✈️').fontSize(32)
          Text('No trips yet')
            .fontSize(13)
            .fontColor('#8B949E')
          Text('Tap + to add your first trip')
            .fontSize(10)
            .fontColor('#6E7681')
          Button('+ Add Trip')
            .onClick(() => router.pushUrl({ url: 'pages/AddTripCountry' }))
            .backgroundColor('#1F6FEB')
            .fontColor('#FFFFFF')
            .fontSize(12)
            .width('70%')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.trips, (trip: Trip) => {
            ListItem() {
              if (this.deletingId === trip.id) {
                // Delete confirmation row
                Row({ space: 8 }) {
                  Text('Delete trip?')
                    .fontSize(11)
                    .fontColor('#FF4444')
                    .layoutWeight(1)
                  Button('Yes')
                    .onClick(() => this.deleteTrip(trip.id))
                    .backgroundColor('#FF4444')
                    .fontColor('#FFFFFF')
                    .fontSize(10)
                    .height(28)
                  Button('No')
                    .onClick(() => { this.deletingId = ''; })
                    .backgroundColor('#21262D')
                    .fontColor('#8B949E')
                    .fontSize(10)
                    .height(28)
                }
                .width('100%')
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .backgroundColor('#1A0000')
                .borderRadius(8)
              } else {
                // Normal trip card
                Column({ space: 4 }) {
                  Row() {
                    Text(trip.flag)
                      .fontSize(20)
                    Column({ space: 2 }) {
                      Text(trip.countryName)
                        .fontSize(13)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#E6EDF3')
                      Text(`${formatDate(trip.startTimestamp)} – ${formatDate(trip.endTimestamp)}`)
                        .fontSize(9)
                        .fontColor('#8B949E')
                    }
                    .margin({ left: 10 })
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    Blank()
                    Text(this.statusBadge(trip))
                      .fontSize(9)
                      .fontColor(this.statusColor(trip))
                      .backgroundColor('#21262D')
                      .padding({ left: 6, right: 6, top: 3, bottom: 3 })
                      .borderRadius(4)
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                }
                .width('100%')
                .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                .backgroundColor('#161B22')
                .borderRadius(8)
                .onClick(() => this.openTrip(trip))
                .gesture(
                  LongPressGesture()
                    .onAction(() => {
                      this.deletingId = trip.id;
                      try {
                        vibrator.startVibration(
                          { type: 'time', duration: 60 },
                          { id: 0, usage: 'notification' }
                        );
                      } catch (_) {}
                    })
                )
              }
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 10, right: 10 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0D1117')
  }
}
