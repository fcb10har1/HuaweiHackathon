
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

  private get currentStep(): ArrivalStep | null {
    return this.steps[this.currentIdx] ?? null;
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

            // Step card
            Column({ space: 6 }) {
              Text(this.currentStep?.title ?? '')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .textAlign(TextAlign.Center)
                .width('90%')
                .lineHeight(19)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Divider().color('#2A3B50').width('60%').strokeWidth(0.5)
                .margin({ top: 2, bottom: 2 })

              Scroll() {
                Text(this.currentStep?.description ?? '')
                  .fontSize(10)
                  .fontColor('#C9D1D9')
                  .textAlign(TextAlign.Center)
                  .width('88%')
                  .lineHeight(15)
              }
              .height(78)
              .width('100%')
              .scrollBar(BarState.Off)
            }
            .width('78%')
            .padding({ left: 12, right: 12, top: 12, bottom: 12 })
            .backgroundColor('#161B22')
            .borderRadius(14)
            .alignItems(HorizontalAlign.Center)
            .border({ width: 1, color: '#00E5C8', style: BorderStyle.Solid })
            .margin({ top: 10 })

            // < > navigation buttons
            Row({ space: 28 }) {
              // Back <
              Button('<')
                .onClick(() => { if (this.currentIdx > 0) this.currentIdx -= 1; })
                .backgroundColor(this.currentIdx > 0 ? '#00C4AE' : '#1C2430')
                .fontColor(this.currentIdx > 0 ? '#0D1117' : '#3A4450')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .width(46)
                .height(46)
                .borderRadius(23)

              // Next >
              Button('>')
                .onClick(() => { this.currentIdx += 1; })
                .backgroundColor('#00C4AE')
                .fontColor('#0D1117')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .width(46)
                .height(46)
                .borderRadius(23)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 14, bottom: 8 })

          }
          .width('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween)
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
