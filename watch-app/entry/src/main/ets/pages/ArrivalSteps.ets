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
      // ── Header (compact for watch) ──────────────────────────────────────────
      Row() {
        Text('←')
          .fontSize(16)
          .fontColor('#8B949E')
          .onClick(() => router.back())
          .padding(8)
        Text(this.steps.length > 0 ? `Step ${this.currentIdx + 1}/${this.steps.length}` : 'Steps')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E6EDF3')
          .layoutWeight(1)
      }
      .width('100%')
      .height(36)
      .alignItems(VerticalAlign.Center)

      Divider().color('#21262D').height(0.5)

      if (this.loading) {
        // Loading state
        Column() {
          LoadingProgress()
            .color('#00E5C8')
            .width(40)
            .height(40)
          Text('Loading steps...')
            .fontSize(11)
            .fontColor('#8B949E')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.steps.length === 0) {
        // No steps available
        Column() {
          Text('😕')
            .fontSize(32)
          Text('No steps available')
            .fontSize(12)
            .fontColor('#8B949E')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.currentIdx >= this.steps.length) {
        // Completed all steps
        Column() {
          Text('✅')
            .fontSize(40)
          Text('Complete!')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00E5C8')
            .margin({ top: 8 })
          Text('All arrival steps done')
            .fontSize(10)
            .fontColor('#8B949E')
            .margin({ top: 4 })
          Button('← Back')
            .onClick(() => router.back())
            .backgroundColor('#21262D')
            .fontColor('#8B949E')
            .fontSize(10)
            .width('60%')
            .height(32)
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // Display current step with optimized watch layout
        Scroll() {
          Column({ space: 8 }) {
            // Step title (prominent)
            Text(this.currentStep?.title ?? '')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E6EDF3')
              .textAlign(TextAlign.Center)
              .width('95%')
              .lineHeight(18)

            // Step description (full height)
            Text(this.currentStep?.description ?? '')
              .fontSize(10)
              .fontColor('#C9D1D9')
              .textAlign(TextAlign.Start)
              .width('95%')
              .lineHeight(16)

            // Progress dots (compact)
            Row() {
              ForEach(this.steps, (_: ArrivalStep, idx: number) => {
                Row()
                  .width(idx === this.currentIdx ? 12 : 5)
                  .height(5)
                  .borderRadius(2.5)
                  .backgroundColor(idx === this.currentIdx ? '#00E5C8' :
                    idx < this.currentIdx ? '#238636' : '#21262D')
                  .margin({ right: 4 })
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 4, bottom: 8 })

            // Navigation buttons (stack on watch for space)
            Column({ space: 6 }) {
              Button(this.isLastStep ? '✓ Done' : 'Next ›')
                .onClick(() => { this.currentIdx += 1; })
                .backgroundColor(this.isLastStep ? '#238636' : '#1F6FEB')
                .fontColor('#FFFFFF')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .width('100%')
                .height(36)

              if (this.currentIdx > 0) {
                Button('‹ Back')
                  .onClick(() => { this.currentIdx -= 1; })
                  .backgroundColor('#21262D')
                  .fontColor('#8B949E')
                  .fontSize(10)
                  .width('100%')
                  .height(32)
              }
            }
            .width('90%')
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ left: 6, right: 6, top: 8, bottom: 8 })
        }
        .layoutWeight(1)
        .width('100%')
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
