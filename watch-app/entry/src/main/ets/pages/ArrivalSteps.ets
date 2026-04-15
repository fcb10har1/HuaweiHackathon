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
      // ── Header (minimal for circular) ──────────────────────────────────────┐─
      Row() {
        Text('←')
          .fontSize(13)
          .fontColor('#8B949E')
          .onClick(() => router.back())
          .padding(6)
        Text(this.steps.length > 0 ? `${this.currentIdx + 1}/${this.steps.length}` : '')
          .fontSize(9)
          .fontColor('#8B949E')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(28)
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
        // Display current step (scrollable content)
        Scroll() {
          Column({ space: 6 }) {
            // Step title
            Text(this.currentStep?.title ?? '')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E6EDF3')
              .textAlign(TextAlign.Center)
              .width('90%')
              .lineHeight(15)

            Divider().color('#21262D').width('80%').height(0.5)

            // Step description  
            Text(this.currentStep?.description ?? '')
              .fontSize(9)
              .fontColor('#C9D1D9')
              .textAlign(TextAlign.Start)
              .width('90%')
              .lineHeight(13)

            // Progress dots
            Row() {
              ForEach(this.steps, (_: ArrivalStep, idx: number) => {
                Row()
                  .width(idx === this.currentIdx ? 10 : 4)
                  .height(4)
                  .borderRadius(2)
                  .backgroundColor(idx === this.currentIdx ? '#00E5C8' :
                    idx < this.currentIdx ? '#238636' : '#21262D')
                  .margin({ right: 3 })
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 6, bottom: 6 })

            // Navigation buttons
            Button(this.isLastStep ? '✓ Done' : 'Next ›')
              .onClick(() => { this.currentIdx += 1; })
              .backgroundColor(this.isLastStep ? '#238636' : '#1F6FEB')
              .fontColor('#FFFFFF')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .width('60%')
              .height(34)

            if (this.currentIdx > 0) {
              Button('‹ Back')
                .onClick(() => { this.currentIdx -= 1; })
                .backgroundColor('#21262D')
                .fontColor('#8B949E')
                .fontSize(9)
                .width('60%')
                .height(30)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ left: 4, right: 4, top: 6, bottom: 6 })
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
