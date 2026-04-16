/**
 * Index.ets — Trip List (Home Screen)
 *
 * Empty state: "No Upcoming Trips" with centered teal add button.
 * Trips state: "My Trips" header + scrollable trip cards + teal add button at bottom.
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
    if (s === 'upcoming') return '#00E5C8';  // teal for upcoming
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
          Stack({ alignContent: Alignment.Center }) {
            Column()
              .width(34)
              .height(34)
              .borderRadius(17)
              .backgroundColor('#00C4AE')
            Text('+')
              .fontSize(18)
              .fontColor('#0D1117')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 2 })
          }
          .onClick(() => router.pushUrl({ url: 'pages/AddTripName' }))
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
          // Header — title only, no + in header
          Text('My Trips')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E6EDF3')
            .textAlign(TextAlign.Center)
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
                  Row({ space: 8 }) {
                    Text(trip.flag).fontSize(20).flexShrink(0)
                    Column({ space: 3 }) {
                      Text(trip.tripName || trip.countryName)
                        .fontSize(12)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#E6EDF3')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(`${formatDate(trip.startTimestamp)} – ${formatDate(trip.endTimestamp)}`)
                        .fontSize(8)
                        .fontColor('#8B949E')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    // Status + arrow
                    Column({ space: 3 }) {
                      Text(this.statusBadge(trip))
                        .fontSize(7)
                        .fontColor(this.statusColor(trip))
                        .letterSpacing(0.5)
                      Text('›')
                        .fontSize(14)
                        .fontColor('#8B949E')
                    }
                    .alignItems(HorizontalAlign.End)
                    .flexShrink(0)

                    // Small red trash button
                    Stack({ alignContent: Alignment.Center }) {
                      Column()
                        .width(22)
                        .height(22)
                        .borderRadius(5)
                        .backgroundColor('#3A0000')
                        .border({ width: 1, color: '#FF4444', style: BorderStyle.Solid })

                      Column({ space: 1 }) {
                        // Lid
                        Column()
                          .width(12).height(2)
                          .backgroundColor('#FF4444')
                          .borderRadius(1)
                        // Body
                        Column()
                          .width(10).height(8)
                          .backgroundColor('transparent')
                          .border({ width: 1.5, color: '#FF4444', style: BorderStyle.Solid })
                          .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 2, bottomRight: 2 })
                      }
                      .alignItems(HorizontalAlign.Center)
                    }
                    .onClick(() => { this.deletingId = trip.id; })
                    .flexShrink(0)
                  }
                  .width('100%')
                  .padding({ left: 12, right: 10, top: 10, bottom: 10 })
                  .backgroundColor('#161B22')
                  .borderRadius(10)
                  .alignItems(VerticalAlign.Center)
                  .onClick(() => this.openTrip(trip))
                }
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 18, right: 18, top: 8, bottom: 4 })
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .friction(6.0)

          // ── Bottom teal add button ───────────────────────────────────────────
          Stack({ alignContent: Alignment.Center }) {
            Column()
              .width(34)
              .height(34)
              .borderRadius(17)
              .backgroundColor('#00C4AE')
            Text('+')
              .fontSize(18)
              .fontColor('#0D1117')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 2 })
          }
          .onClick(() => router.pushUrl({ url: 'pages/AddTripName' }))
          .margin({ bottom: 14 })
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#0D1117')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0D1117')
  }
}
