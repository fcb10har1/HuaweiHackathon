/**
 * ArrivalSteps.ets — Step-by-step arrival checklist loaded from bundled JSON.
 * Fully offline — no network required. No risk level badges on steps.
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
          .fontSize(18)
          .fontColor('#8B949E')
          .onClick(() => router.back())
          .padding({ left: 8, right: 8 })
        Text('Arrival Steps')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E6EDF3')
        Blank()
        if (this.steps.length > 0) {
          Text(`${this.currentIdx + 1}/${this.steps.length}`)
            .fontSize(10)
            .fontColor('#8B949E')
            .padding({ right: 12 })
        }
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)

      Divider().color('#21262D')

      if (this.loading) {
        Column() {
          Text('Loading steps...')
            .fontSize(12)
            .fontColor('#8B949E')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.steps.length === 0) {
        Column() {
          Text('No steps available')
            .fontSize(12)
            .fontColor('#8B949E')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.currentIdx >= this.steps.length) {
        // All steps done
        Column({ space: 12 }) {
          Text('✅').fontSize(36)
          Text('All Steps Done!')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00E5C8')
          Text('You have completed all arrival steps.')
            .fontSize(11)
            .fontColor('#8B949E')
            .textAlign(TextAlign.Center)
            .width('85%')
          Button('Start Over')
            .onClick(() => { this.currentIdx = 0; })
            .backgroundColor('#21262D')
            .fontColor('#8B949E')
            .fontSize(11)
            .width('70%')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // Current step card
        Column({ space: 10 }) {
          // Step number indicator
          Row({ space: 6 }) {
            ForEach(this.steps, (_: ArrivalStep, idx: number) => {
              Row()
                .width(idx === this.currentIdx ? 14 : 6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(idx === this.currentIdx ? '#00E5C8' :
                  idx < this.currentIdx ? '#238636' : '#21262D')
            })
          }
          .margin({ top: 10 })

          // Step title
          Text(this.currentStep?.title ?? '')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E6EDF3')
            .textAlign(TextAlign.Center)
            .width('90%')

          // Step description (scrollable)
          Scroll() {
            Text(this.currentStep?.description ?? '')
              .fontSize(11)
              .fontColor('#C9D1D9')
              .textAlign(TextAlign.Start)
              .width('100%')
              .lineHeight(17)
          }
          .width('90%')
          .layoutWeight(1)

          // Navigation buttons
          Row({ space: 10 }) {
            if (this.currentIdx > 0) {
              Button('‹ Back')
                .onClick(() => { this.currentIdx -= 1; })
                .backgroundColor('#21262D')
                .fontColor('#8B949E')
                .fontSize(11)
                .width('38%')
                .height(36)
            }
            Button(this.isLastStep ? 'Done ✓' : 'Next ›')
              .onClick(() => { this.currentIdx += 1; })
              .backgroundColor(this.isLastStep ? '#238636' : '#1F6FEB')
              .fontColor('#FFFFFF')
              .fontSize(11)
              .width(this.currentIdx > 0 ? '38%' : '70%')
              .height(36)
          }
          .margin({ bottom: 14 })
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
        .onActionEnd(() => router.back())
    )
  }
}
