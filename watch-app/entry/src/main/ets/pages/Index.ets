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
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E8F4F8')
        Blank()
        Text('+')
          .fontSize(20)
          .fontColor('#2DD4BF')
          .onClick(() => router.pushUrl({ url: 'pages/AddTripCountry' }))
          .padding(6)
      }
      .width('100%')
      .padding({ left: 12, right: 10, top: 8, bottom: 6 })

      Divider().color('#0D2035').width('100%')

      // ── Trip list ────────────────────────────────────────────────────────────
      if (this.trips.length === 0) {
        Column({ space: 10 }) {
          Text('No trips yet')
            .fontSize(13)
            .fontColor('#E8F4F8')
            .fontWeight(FontWeight.Bold)
          Text('Tap + to add your first trip')
            .fontSize(10)
            .fontColor('#4A7A8A')
          Button('Add Trip')
            .onClick(() => router.pushUrl({ url: 'pages/AddTripCountry' }))
            .backgroundColor('transparent')
            .fontColor('#2DD4BF')
            .fontSize(12)
            .width('70%')
            .height(34)
            .borderRadius(17)
            .border({ width: 1, color: '#2DD4BF' })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 7 }) {
          ForEach(this.trips, (trip: Trip) => {
            ListItem() {
              if (this.deletingId === trip.id) {
                Row({ space: 6 }) {
                  Text('Delete?')
                    .fontSize(11)
                    .fontColor('#FF4444')
                    .layoutWeight(1)
                  Button('Yes')
                    .onClick(() => this.deleteTrip(trip.id))
                    .backgroundColor('#FF4444')
                    .fontColor('#FFFFFF')
                    .fontSize(10)
                    .height(30)
                    .borderRadius(15)
                  Button('No')
                    .onClick(() => { this.deletingId = ''; })
                    .backgroundColor('#0D2035')
                    .fontColor('#4A7A8A')
                    .fontSize(10)
                    .height(30)
                    .borderRadius(15)
                }
                .width('100%')
                .padding({ left: 10, right: 10, top: 8, bottom: 8 })
                .backgroundColor('#1A0A0A')
                .borderRadius(8)
              } else {
                Row({ space: 0 }) {
                  Text(trip.flag)
                    .fontSize(18)
                  Column({ space: 2 }) {
                    Text(trip.countryName)
                      .fontSize(12)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#E8F4F8')
                    Text(`${formatDate(trip.startTimestamp)} \u2013 ${formatDate(trip.endTimestamp)}`)
                      .fontSize(9)
                      .fontColor('#4A7A8A')
                  }
                  .margin({ left: 8 })
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  Blank()
                  Text(this.statusBadge(trip))
                    .fontSize(8)
                    .fontColor(this.statusColor(trip))
                    .backgroundColor('#0D2035')
                    .padding({ left: 5, right: 5, top: 3, bottom: 3 })
                    .borderRadius(4)
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
                .padding({ left: 10, right: 10, top: 9, bottom: 9 })
                .backgroundColor('#0D2035')
                .borderRadius(8)
                .border({ width: 1, color: '#143050' })
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
    .backgroundColor('#060D1A')
  }
}
