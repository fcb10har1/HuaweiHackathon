
/**
 * ArrivalSteps.ets — Step-by-step arrival checklist.
 * Fully offline. Progress arc ring around watch face edge. One step at a time.
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

  private get progressValue(): number {
    if (this.steps.length === 0) return 0;
    return Math.min(this.currentIdx, this.steps.length);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {

      // ── Teal progress arc ring — drawn at screen edge ──────────────────────
      if (!this.loading && this.steps.length > 0) {
        Progress({
          value: this.progressValue,
          total: this.steps.length,
          type:  ProgressType.Ring,
        })
          .width('100%')
          .height('100%')
          .style({ strokeWidth: 5 })
          .color('#00E5C8')
          .backgroundColor('#1C2430')
      }

      // ── Content (transparent bg, ring shows at edge) ────────────────────────
      Column() {
        // Header
        Row() {
          Text('←')
            .fontSize(13)
            .fontColor('#8B949E')
            .onClick(() => router.back())
            .padding({ left: 10, right: 6 })
          Text(
            this.loading                          ? 'Arrival Steps' :
            this.steps.length === 0               ? 'Arrival Steps' :
            this.currentIdx >= this.steps.length  ? 'Complete'      :
            `${this.currentIdx + 1} / ${this.steps.length}`
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

        // ── Loading ────────────────────────────────────────────────────────────
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

        // ── No steps ──────────────────────────────────────────────────────────
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

        // ── Complete ───────────────────────────────────────────────────────────
        } else if (this.currentIdx >= this.steps.length) {
          Column({ space: 8 }) {
            Text('✅').fontSize(40)
            Text('All Done!')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#00E5C8')
            Text('Arrival complete')
              .fontSize(10)
              .fontColor('#8B949E')
            Button('← Back')
              .onClick(() => router.back())
              .backgroundColor('#21262D')
              .fontColor('#8B949E')
              .fontSize(10)
              .width('60%')
              .height(30)
              .margin({ top: 8 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

        // ── Current step ───────────────────────────────────────────────────────
        } else {
          Column({ space: 0 }) {
            // Step card — prominent
            Column({ space: 6 }) {
              Text(this.currentStep?.title ?? '')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#E6EDF3')
                .textAlign(TextAlign.Center)
                .width('90%')
                .lineHeight(19)

              Divider().color('#2A3B50').width('65%').height(0.5)
                .margin({ top: 2, bottom: 2 })

              Scroll() {
                Text(this.currentStep?.description ?? '')
                  .fontSize(10)
                  .fontColor('#C9D1D9')
                  .textAlign(TextAlign.Start)
                  .width('90%')
                  .lineHeight(15)
              }
              .maxHeight(86)
              .width('100%')
              .scrollBar(BarState.Off)
            }
            .width('84%')
            .padding({ left: 10, right: 10, top: 12, bottom: 12 })
            .backgroundColor('#161B22')
            .borderRadius(12)
            .alignItems(HorizontalAlign.Center)
            .border({ width: 1, color: '#00E5C8', style: BorderStyle.Solid })
            .margin({ top: 8 })

            // Nav buttons
            Column({ space: 6 }) {
              Button(this.isLastStep ? '✓ Complete' : 'Next ›')
                .onClick(() => { this.currentIdx += 1; })
                .backgroundColor(this.isLastStep ? '#00C4AE' : '#00C4AE')
                .fontColor('#0D1117')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .width('60%')
                .height(34)

              if (this.currentIdx > 0) {
                Button('‹ Back')
                  .onClick(() => { this.currentIdx -= 1; })
                  .backgroundColor('#21262D')
                  .fontColor('#8B949E')
                  .fontSize(10)
                  .width('48%')
                  .height(26)
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
          .padding({ left: 6, right: 6 })
        }
      }
      .width('100%')
      .height('100%')
      // No backgroundColor — Stack's dark bg + ring shows at edges
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
