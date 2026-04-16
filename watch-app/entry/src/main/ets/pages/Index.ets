/**
 * Index.ets — Trip List (Home Screen)
 *
 * Empty state: "No Upcoming Trips" with centered teal add button.
 * Trips state: "My Trips" header + scrollable trip cards.
 * Long-press a trip to delete. Tap to open.
 */
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { vibrator } from '@kit.SensorServiceKit';
import { Trip, getTripStatus, formatDate } from '../common/Types';
import { StorageService } from '../services/StorageService';

@Entry
@Component
struct Index {
  @State trips: Trip[]      = [];
  @State deletingId: string = '';

  private storage: StorageService | null = null;

  aboutToAppear(): void {
    this.storage = new StorageService(getContext(this) as common.UIAbilityContext);
    this.loadTrips();
  }

  onPageShow(): void {
    this.loadTrips();
  }

  private loadTrips(): void {
    this.storage?.loadTrips().then(trips => { this.trips = trips; });
  }

  private deleteTrip(id: string): void {
    this.storage?.deleteTrip(id).then(updated => {
      this.trips = updated;
      this.deletingId = '';
    });
  }

  private openTrip(trip: Trip): void {
    const status = getTripStatus(trip);
    const url = status === 'ended' ? 'pages/TripEnded' : 'pages/TripHome';
    router.pushUrl({ url, params: { tripJson: JSON.stringify(trip) } });
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
    if (s === 'upcoming') return '#4D9FFF';
    return '#6E7681';
  }

  build() {
    Column() {
      if (this.trips.length === 0) {
        // ── Empty state ────────────────────────────────────────────────────────
        Column({ space: 10 }) {
          Text('No Upcoming\nTrips')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E6EDF3')
            .textAlign(TextAlign.Center)
            .lineHeight(22)

          // Circular teal add button
          Text('+')
            .fontSize(28)
            .fontColor('#0D1117')
            .fontWeight(FontWeight.Bold)
            .width(56)
            .height(56)
            .textAlign(TextAlign.Center)
            .lineHeight(54)
            .backgroundColor('#00C4AE')
            .borderRadius(28)
            .onClick(() => router.pushUrl({ url: 'pages/AddTripCountry' }))
            .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#0D1117')
      } else {
        // ── Trips state ────────────────────────────────────────────────────────
        Column() {
          // Header
          Stack({ alignContent: Alignment.Center }) {
            Text('My Trips')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E6EDF3')
              .textAlign(TextAlign.Center)
              .width('100%')

            Row() {
              Blank()
              Text('+')
                .fontSize(22)
                .fontColor('#00C4AE')
                .fontWeight(FontWeight.Bold)
                .padding({ right: 14 })
                .onClick(() => router.pushUrl({ url: 'pages/AddTripCountry' }))
            }
            .width('100%')
          }
          .width('100%')
          .padding({ top: 12, bottom: 8 })

          Divider().color('#21262D')

          // Trip list
          List({ space: 10 }) {
            ForEach(this.trips, (trip: Trip) => {
              ListItem() {
                if (this.deletingId === trip.id) {
                  // Delete confirmation
                  Row({ space: 8 }) {
                    Text('Delete?')
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
                  .padding({ left: 10, right: 10, top: 8, bottom: 8 })
                  .backgroundColor('#1A0000')
                  .borderRadius(8)
                } else {
                  // Trip card
                  Row({ space: 10 }) {
                    Text(trip.flag).fontSize(22)
                    Column({ space: 3 }) {
                      Text(trip.countryName)
                        .fontSize(13)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#E6EDF3')
                      Text(`${formatDate(trip.startTimestamp)} – ${formatDate(trip.endTimestamp)}`)
                        .fontSize(9)
                        .fontColor('#8B949E')
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    Column({ space: 3 }) {
                      Text(this.statusBadge(trip))
                        .fontSize(7)
                        .fontColor(this.statusColor(trip))
                        .letterSpacing(0.5)
                      Text('›')
                        .fontSize(16)
                        .fontColor('#8B949E')
                    }
                    .alignItems(HorizontalAlign.End)
                  }
                  .width('100%')
                  .padding({ left: 14, right: 12, top: 12, bottom: 12 })
                  .backgroundColor('#161B22')
                  .borderRadius(10)
                  .alignItems(VerticalAlign.Center)
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
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .friction(0.85)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#0D1117')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0D1117')
  }
}
