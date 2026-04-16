/**
 * AddTripDates.ets — Step 3: pick departure + return dates, then confirm.
 *
 * Flow:
 *   Step 1 — Pick departure date
 *   Step 2 — Pick return date → saves trip → Step 3
 *   Step 3 — "Trip Added" confirmation, then auto-navigate back to Index
 */
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { Trip, formatDate } from '../common/Types';
import { StorageService } from '../services/StorageService';

@Entry
@Component
struct AddTripDates {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private tripName:      string = this.params['tripName']      ?? '';
  private countryCode:   string = this.params['countryCode']   ?? '';
  private countryName:   string = this.params['countryName']   ?? '';
  private flag:          string = this.params['flag']          ?? '';
  private languageName:  string = this.params['languageName']  ?? '';
  private languageLocale: string = this.params['languageLocale'] ?? '';

  @State step: number    = 1;
  @State startDate: Date = new Date();
  @State endDate: Date   = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  @State saving: boolean = false;

  private storage: StorageService | null = null;

  aboutToAppear(): void {
    this.storage = new StorageService(getContext(this) as common.UIAbilityContext);
  }

  private saveAndConfirm(): void {
    if (this.saving) return;
    this.saving = true;

    const trip: Trip = {
      id:             Date.now().toString(),
      tripName:       this.tripName,
      countryCode:    this.countryCode,
      countryName:    this.countryName,
      flag:           this.flag,
      languageName:   this.languageName,
      languageLocale: this.languageLocale,
      startTimestamp: this.startDate.setHours(0, 0, 0, 0),
      endTimestamp:   this.endDate.setHours(23, 59, 59, 999),
    };

    this.storage?.addTrip(trip).then(() => {
      this.step = 3;
      // Auto-navigate back to Index after 2.5 seconds
      setTimeout(() => {
        router.back({ url: 'pages/Index' });
      }, 2500);
    }).catch(() => {
      this.saving = false;
    });
  }

  build() {
    Column() {

      // ── Step 3: Confirmation screen ──────────────────────────────────────────
      if (this.step === 3) {
        Column({ space: 10 }) {
          Text(this.flag)
            .fontSize(44)
            .margin({ bottom: 4 })

          Text(`${this.tripName} Added`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
            .width('85%')
            .lineHeight(22)

          Text(this.countryName)
            .fontSize(11)
            .fontColor('#8B949E')
            .textAlign(TextAlign.Center)

          Text(`${formatDate(this.startDate.getTime())} – ${formatDate(this.endDate.getTime())}`)
            .fontSize(10)
            .fontColor('#8B949E')
            .textAlign(TextAlign.Center)

          // Teal divider line
          Divider()
            .color('#00E5C8')
            .strokeWidth(2)
            .width('40%')
            .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#0D1117')

      } else {
        // ── Header (steps 1 & 2) ─────────────────────────────────────────────
        Row() {
          Text('←')
            .fontSize(18)
            .fontColor('#8B949E')
            .onClick(() => { if (this.step > 1) { this.step -= 1; } else { router.back(); } })
            .padding({ left: 10, right: 8 })
          Text(this.step === 1 ? 'Start Date' : 'End Date')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E6EDF3')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ right: 28 })
        }
        .width('100%')
        .height(40)
        .alignItems(VerticalAlign.Center)

        Divider().color('#21262D')

        // Country banner
        Row({ space: 8 }) {
          Text(this.flag).fontSize(18)
          Text(this.countryName)
            .fontSize(12)
            .fontColor('#00E5C8')
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding({ left: 18, top: 6, bottom: 2 })
        .alignItems(VerticalAlign.Center)

        // ── Step 1: Departure date ─────────────────────────────────────────────
        if (this.step === 1) {
          Column({ space: 8 }) {
            Text('When do you depart?')
              .fontSize(11)
              .fontColor('#8B949E')
              .margin({ top: 4 })

            DatePicker({
              start:    new Date('2024-01-01'),
              end:      new Date('2030-12-31'),
              selected: this.startDate,
            })
            .onChange((val: DatePickerResult) => {
              this.startDate = new Date(val.year ?? 0, val.month ?? 0, val.day ?? 1);
            })
            .width('100%')
            .layoutWeight(1)

            Button('Next →')
              .onClick(() => {
                if (this.endDate < this.startDate) {
                  this.endDate = new Date(this.startDate.getTime() + 7 * 24 * 60 * 60 * 1000);
                }
                this.step = 2;
              })
              .backgroundColor('#00C4AE')
              .fontColor('#0D1117')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .width('75%')
              .margin({ bottom: 14 })
          }
          .width('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }

        // ── Step 2: Return date ────────────────────────────────────────────────
        if (this.step === 2) {
          Column({ space: 8 }) {
            Text('When do you return?')
              .fontSize(11)
              .fontColor('#8B949E')
              .margin({ top: 4 })

            DatePicker({
              start:    this.startDate,
              end:      new Date('2030-12-31'),
              selected: this.endDate,
            })
            .onChange((val: DatePickerResult) => {
              this.endDate = new Date(val.year ?? 0, val.month ?? 0, val.day ?? 1);
            })
            .width('100%')
            .layoutWeight(1)

            Button(this.saving ? 'Saving...' : 'Add Trip')
              .onClick(() => this.saveAndConfirm())
              .enabled(!this.saving)
              .backgroundColor(this.saving ? '#21262D' : '#00C4AE')
              .fontColor(this.saving ? '#8B949E' : '#0D1117')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .width('75%')
              .margin({ bottom: 14 })
          }
          .width('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0D1117')
    .gesture(
      PanGesture({ direction: PanDirection.Right, distance: 50 })
        .onActionEnd(() => {
          if (this.step === 3) return; // lock swipe during confirmation
          if (this.step > 1) { this.step -= 1; } else { router.back(); }
        })
    )
  }
}
