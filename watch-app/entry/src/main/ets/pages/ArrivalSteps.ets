/**
 * ArrivalSteps.ets — Scrollable arrival checklist.
 * All steps shown simultaneously. Tap the circle to tick a step.
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

  @State steps: ArrivalStep[]       = [];
  @State completedSteps: boolean[]  = [];
  @State loading: boolean           = true;
  @State loadError: boolean         = false;

  private dataService: CountryDataService | null = null;

  aboutToAppear(): void {
    this.dataService = new CountryDataService(getContext(this) as common.UIAbilityContext);
    this.dataService.getArrivalSteps(this.trip.countryCode)
      .then(steps => {
        this.steps = steps;
        this.completedSteps = new Array<boolean>(steps.length).fill(false);
        this.loading = false;
      })
      .catch(() => {
        this.loading = false;
        this.loadError = true;
      });
  }

  private toggleStep(idx: number): void {
    const updated = [...this.completedSteps];
    updated[idx] = !updated[idx];
    this.completedSteps = updated;
  }

  private get completedCount(): number {
    return this.completedSteps.filter(v => v).length;
  }

  build() {
    Column() {
      // ── Header ─────────────────────────────────────────────────────────────
      Row() {
        Text('←')
          .fontSize(13)
          .fontColor('#8B949E')
          .onClick(() => router.back())
          .padding({ left: 12, right: 8 })

        Text(
          this.loading    ? 'Arrival Steps' :
          this.loadError  ? 'Arrival Steps' :
          this.steps.length === 0 ? 'Arrival Steps' :
          `${this.completedCount} of ${this.steps.length} done`
        )
          .fontSize(11)
          .fontColor(this.completedCount === this.steps.length && this.steps.length > 0 ? '#00E5C8' : '#8B949E')
          .letterSpacing(0.5)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 30 })
      }
      .width('100%')
      .height(34)
      .alignItems(VerticalAlign.Center)

      Divider().color('#21262D').strokeWidth(0.5)

      // ── Body ───────────────────────────────────────────────────────────────
      if (this.loading) {
        Column({ space: 8 }) {
          LoadingProgress().color('#00E5C8').width(32).height(32)
          Text('Loading steps...')
            .fontSize(11)
            .fontColor('#8B949E')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

      } else if (this.loadError) {
        Column({ space: 8 }) {
          Text('Could not load steps')
            .fontSize(12)
            .fontColor('#FF4444')
          Text('Check rawfile assets')
            .fontSize(9)
            .fontColor('#6E7681')
          Button('Back')
            .onClick(() => router.back())
            .backgroundColor('#21262D')
            .fontColor('#8B949E')
            .fontSize(10)
            .height(30)
            .width('55%')
            .margin({ top: 8 })
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
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .friction(0.85)
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
