/**
 * ArrivalSteps.ets — Step-by-step arrival checklist.
 * Teal arc ring around watch face edge tracks progress.
 * < > circle buttons for navigation. No emoji.
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

  build() {
    Stack({ alignContent: Alignment.Center }) {

      // ── Teal progress arc ring ─────────────────────────────────────────────
      if (!this.loading && this.steps.length > 0) {
        Progress({
          value: Math.min(this.currentIdx, this.steps.length),
          total: this.steps.length,
          type:  ProgressType.Ring,
        })
          .width('100%')
          .height('100%')
          .style({ strokeWidth: 4 })
          .color('#00E5C8')
          .backgroundColor('#1A2230')
      }

      // ── Content column (transparent — ring shows at edges) ─────────────────
      Column() {

        // Header
        Row() {
          Text('←')
            .fontSize(13)
            .fontColor('#8B949E')
            .onClick(() => router.back())
            .padding({ left: 12, right: 6 })
          Text(
            this.loading                         ? 'Arrival Steps' :
            this.steps.length === 0              ? 'Arrival Steps' :
            this.currentIdx >= this.steps.length ? 'Complete'      :
            `${this.currentIdx + 1} of ${this.steps.length}`
          )
            .fontSize(11)
            .fontColor('#8B949E')
            .letterSpacing(0.5)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ right: 30 })
        }
        .width('100%')
        .height(32)
        .alignItems(VerticalAlign.Center)

        Divider().color('#21262D').strokeWidth(0.5)

        // ── Loading ──────────────────────────────────────────────────────────
        if (this.loading) {
          Column() {
            LoadingProgress().color('#00E5C8').width(32).height(32)
            Text('Loading steps...')
              .fontSize(11)
              .fontColor('#8B949E')
              .margin({ top: 8 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

        // ── No steps ────────────────────────────────────────────────────────
        } else if (this.steps.length === 0) {
          Column() {
            Text('No steps available')
              .fontSize(13)
              .fontColor('#8B949E')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

        // ── Complete ─────────────────────────────────────────────────────────
        } else if (this.currentIdx >= this.steps.length) {
          Column({ space: 10 }) {
            // Teal checkmark circle — no emoji
            Text('✓')
              .fontSize(24)
              .fontColor('#0D1117')
              .width(54)
              .height(54)
              .textAlign(TextAlign.Center)
              .lineHeight(54)
              .backgroundColor('#00E5C8')
              .borderRadius(27)

            Text('All Done')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')

            Text('Arrival checklist complete')
              .fontSize(10)
              .fontColor('#8B949E')
              .textAlign(TextAlign.Center)

            Button('Back to Trip')
              .onClick(() => router.back())
              .backgroundColor('#21262D')
              .fontColor('#8B949E')
              .fontSize(10)
              .width('62%')
              .height(32)
              .margin({ top: 6 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

        // ── Current step ──────────────────────────────────────────────────────
        } else {
          Column() {

            // Title — teal, no box
            Text(this.steps[this.currentIdx]?.title ?? '')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#00E5C8')
              .textAlign(TextAlign.Center)
              .width('86%')
              .lineHeight(20)
              .padding({ top: 10, bottom: 6 })

            // Scrollable description — fills all remaining space
            Scroll() {
              Column() {
                Text(this.steps[this.currentIdx]?.description ?? '')
                  .fontSize(10)
                  .fontColor('#C9D1D9')
                  .textAlign(TextAlign.Center)
                  .width('86%')
                  .lineHeight(16)

                // Bottom spacer so last line stays above the nav buttons
                Text('').height(56)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            }
            .layoutWeight(1)
            .width('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .friction(0.85)

            // ── Fixed < > nav buttons ──────────────────────────────────────
            Row({ space: 32 }) {
              // < Previous
              Text('<')
                .fontSize(20)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
                .width(38)
                .height(38)
                .textAlign(TextAlign.Center)
                .lineHeight(38)
                .backgroundColor(this.currentIdx > 0 ? '#00C4AE' : '#1C2430')
                .borderRadius(19)
                .onClick(() => { if (this.currentIdx > 0) this.currentIdx -= 1; })

              // > Next
              Text('>')
                .fontSize(20)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
                .width(38)
                .height(38)
                .textAlign(TextAlign.Center)
                .lineHeight(38)
                .backgroundColor('#00C4AE')
                .borderRadius(19)
                .onClick(() => { this.currentIdx += 1; })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 6, bottom: 12 })

          }
          .width('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
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
