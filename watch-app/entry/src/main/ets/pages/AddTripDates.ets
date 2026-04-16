/**
 * AddTripDates.ets — Step 2: pick departure + return dates, then save.
 *
 * 3-step flow within this page:
 *   Step 1 — Pick departure date
 *   Step 2 — Pick return date
 *   Step 3 — Confirm and save
 */
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { Trip, formatDate } from '../common/Types';
import { StorageService } from '../services/StorageService';

@Entry
@Component
struct AddTripDates {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private countryCode:    string = this.params['countryCode']    ?? '';
  private countryName:    string = this.params['countryName']    ?? '';
  private flag:           string = this.params['flag']           ?? '';
  private languageName:   string = this.params['languageName']   ?? '';
  private languageLocale: string = this.params['languageLocale'] ?? '';

  @State step: number    = 1;
  @State startDate: Date = new Date();
  @State endDate: Date   = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  @State saving: boolean = false;

  private storage: StorageService | null = null;

  aboutToAppear(): void {
    this.storage = new StorageService(getContext(this) as common.UIAbilityContext);
  }

  private saveTrip(): void {
    if (this.saving) return;
    this.saving = true;

    const trip: Trip = {
      id:             Date.now().toString(),
      countryCode:    this.countryCode,
      countryName:    this.countryName,
      flag:           this.flag,
      languageName:   this.languageName,
      languageLocale: this.languageLocale,
      startTimestamp: this.startDate.setHours(0, 0, 0, 0),
      endTimestamp:   this.endDate.setHours(23, 59, 59, 999),
    };

    this.storage?.addTrip(trip).then(() => {
      router.back();
      router.back();
    }).catch(() => {
      this.saving = false;
    });
  }

  build() {
    Column() {
      // ── Header ──────────────────────────────────────────────────────────────
      Row() {
        Text('←')
          .fontSize(18)
          .fontColor('#8B949E')
          .onClick(() => { if (this.step > 1) { this.step -= 1; } else { router.back(); } })
          .padding({ left: 10, right: 8 })
        Text(this.step === 1 ? 'Departure' : this.step === 2 ? 'Return' : 'Confirm')
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
      .padding({ left: 18, top: 8, bottom: 4 })
      .alignItems(VerticalAlign.Center)

      // ── Step 1: Departure date ───────────────────────────────────────────────
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
            .backgroundColor('#1F6FEB')
            .fontColor('#FFFFFF')
            .fontSize(12)
            .width('75%')
            .margin({ bottom: 14 })
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }

      // ── Step 2: Return date ──────────────────────────────────────────────────
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

          Button('Next →')
            .onClick(() => { this.step = 3; })
            .backgroundColor('#1F6FEB')
            .fontColor('#FFFFFF')
            .fontSize(12)
            .width('75%')
            .margin({ bottom: 14 })
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }

      // ── Step 3: Confirm ──────────────────────────────────────────────────────
      if (this.step === 3) {
        Column({ space: 12 }) {
          Text('Trip Summary')
            .fontSize(11)
            .fontColor('#8B949E')
            .margin({ top: 8 })

          Column({ space: 8 }) {
            Row({ space: 8 }) {
              Text('START').fontSize(9).fontColor('#8B949E').width(42)
              Text(formatDate(this.startDate.getTime()))
                .fontSize(12)
                .fontColor('#E6EDF3')
                .fontWeight(FontWeight.Bold)
            }
            .alignItems(VerticalAlign.Center)

            Row({ space: 8 }) {
              Text('END').fontSize(9).fontColor('#8B949E').width(42)
              Text(formatDate(this.endDate.getTime()))
                .fontSize(12)
                .fontColor('#E6EDF3')
                .fontWeight(FontWeight.Bold)
            }
            .alignItems(VerticalAlign.Center)
          }
          .backgroundColor('#161B22')
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .borderRadius(8)
          .width('84%')
          .alignItems(HorizontalAlign.Start)

          Button(this.saving ? 'Saving...' : 'Save Trip ✓')
            .onClick(() => this.saveTrip())
            .backgroundColor(this.saving ? '#21262D' : '#238636')
            .fontColor('#FFFFFF')
            .fontSize(13)
            .width('75%')
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0D1117')
    .gesture(
      PanGesture({ direction: PanDirection.Right, distance: 50 })
        .onActionEnd(() => { if (this.step > 1) { this.step -= 1; } else { router.back(); } })
    )
  }
}
