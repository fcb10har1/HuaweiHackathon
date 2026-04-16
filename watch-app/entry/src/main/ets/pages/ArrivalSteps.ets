/**
 * ArrivalSteps.ets — Step-by-step arrival checklist loaded from bundled JSON.
 * Fully offline. Current step is prominently emphasized. One step at a time.
 */
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { Trip, ArrivalStep } from '../common/Types';
import { CountryDataService } from '../services/CountryDataService';

@Entry
@Component
struct ArrivalSteps {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private trip: Trip = JSON.parse(this.params['tripJson'] ?? '{}') as Trip;

  @State steps: ArrivalStep[] = [];
  @State currentIdx: number   = 0;
  @State loading: boolean     = true;

  private dataService: CountryDataService | null = null;

  aboutToAppear(): void {
    this.dataService = new CountryDataService(getContext(this) as common.UIAbilityContext);
    this.dataService.getArrivalSteps(this.trip.countryCode).then(steps => {
      this.steps   = steps;
      this.loading = false;
    });
  }

  private get currentStep(): ArrivalStep | null {
    return this.steps[this.currentIdx] ?? null;
  }

  private get isLastStep(): boolean {
    return this.currentIdx >= this.steps.length - 1;
  }

  build() {
    Column() {
      // ── Header ──────────────────────────────────────────────────────────────
      Row() {
        Text('←')
          .fontSize(13)
          .fontColor('#8B949E')
          .onClick(() => router.back())
          .padding({ left: 10, right: 6 })
        Text(
          this.loading ? 'Arrival Steps' :
          this.steps.length === 0 ? 'Arrival Steps' :
          this.currentIdx >= this.steps.length ? 'Complete' :
          `Step ${this.currentIdx + 1} of ${this.steps.length}`
        )
          .fontSize(11)
          .fontColor('#8B949E')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 28 })
      }
      .width('100%')
      .height(30)
      .alignItems(VerticalAlign.Center)

      Divider().color('#21262D').height(0.5)

      // ── Loading ──────────────────────────────────────────────────────────────
      if (this.loading) {
        Column() {
          LoadingProgress().color('#00E5C8').width(36).height(36)
          Text('Loading steps...')
            .fontSize(11)
            .fontColor('#8B949E')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

      // ── No steps ─────────────────────────────────────────────────────────────
      } else if (this.steps.length === 0) {
        Column() {
          Text('😕').fontSize(30)
          Text('No steps available')
            .fontSize(12)
            .fontColor('#8B949E')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

      // ── Completed ─────────────────────────────────────────────────────────────
      } else if (this.currentIdx >= this.steps.length) {
        Column({ space: 8 }) {
          Text('✅').fontSize(42)
          Text('All Done!')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00E5C8')
          Text('Arrival complete')
            .fontSize(10)
            .fontColor('#8B949E')
          Button('← Back to Trip')
            .onClick(() => router.back())
            .backgroundColor('#21262D')
            .fontColor('#8B949E')
            .fontSize(10)
            .width('65%')
            .height(32)
            .margin({ top: 10 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

      // ── Current step ──────────────────────────────────────────────────────────
      } else {
        Column({ space: 0 }) {
          // Progress dots
          Row() {
            ForEach(this.steps, (_: ArrivalStep, idx: number) => {
              Row()
                .width(idx === this.currentIdx ? 14 : 5)
                .height(5)
                .borderRadius(2.5)
                .backgroundColor(
                  idx === this.currentIdx ? '#00E5C8' :
                  idx < this.currentIdx   ? '#238636' : '#21262D'
                )
                .margin({ right: 3 })
                .animation({ duration: 200 })
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 8, bottom: 8 })

          // Step card — prominent, centered
          Column({ space: 6 }) {
            Text(this.currentStep?.title ?? '')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E6EDF3')
              .textAlign(TextAlign.Center)
              .width('90%')
              .lineHeight(20)

            Divider().color('#2D3B4E').width('70%').height(0.5).margin({ top: 2, bottom: 2 })

            Scroll() {
              Text(this.currentStep?.description ?? '')
                .fontSize(10)
                .fontColor('#C9D1D9')
                .textAlign(TextAlign.Start)
                .width('90%')
                .lineHeight(15)
            }
            .height(90)
            .width('100%')
          }
          .width('88%')
          .padding({ left: 10, right: 10, top: 12, bottom: 12 })
          .backgroundColor('#161B22')
          .borderRadius(12)
          .alignItems(HorizontalAlign.Center)
          .border({ width: 1, color: '#1F6FEB', style: BorderStyle.Solid })

          // Nav buttons
          Column({ space: 6 }) {
            Button(this.isLastStep ? '✓ Complete' : 'Next ›')
              .onClick(() => { this.currentIdx += 1; })
              .backgroundColor(this.isLastStep ? '#238636' : '#1F6FEB')
              .fontColor('#FFFFFF')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .width('62%')
              .height(36)

            if (this.currentIdx > 0) {
              Button('‹ Back')
                .onClick(() => { this.currentIdx -= 1; })
                .backgroundColor('#21262D')
                .fontColor('#8B949E')
                .fontSize(10)
                .width('50%')
                .height(28)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 10, bottom: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 4, right: 4 })
      }
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
