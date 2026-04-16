/**
 * ArrivalSteps.ets — One step at a time with < > navigation.
 * Teal progress ring (inset from edge) tracks progress.
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
  @State loadError: boolean   = false;

  // Scroller lets us jump back to top whenever the step changes
  private scroller: Scroller = new Scroller();

  private dataService: CountryDataService | null = null;

  aboutToAppear(): void {
    this.dataService = new CountryDataService(getContext(this) as common.UIAbilityContext);
    this.dataService.getArrivalSteps(this.trip.countryCode)
      .then(steps => {
        this.steps = steps;
        this.loading = false;
      })
      .catch(() => {
        this.loading = false;
        this.loadError = true;
      });
  }

  private goNext(): void {
    this.currentIdx += 1;
    this.scroller.scrollEdge(Edge.Top);
  }

  private goPrev(): void {
    if (this.currentIdx > 0) {
      this.currentIdx -= 1;
      this.scroller.scrollEdge(Edge.Top);
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {

      // ── Teal progress ring — inset so a gap shows between ring and bezel ──
      if (!this.loading && this.steps.length > 0) {
        Progress({
          value: Math.min(this.currentIdx + 1, this.steps.length),
          total: this.steps.length,
          type: ProgressType.Ring,
        })
          .width('88%')
          .height('88%')
          .style({ strokeWidth: 4 })
          .color('#00E5C8')
          .backgroundColor('#1C2430')
      }

      // ── Content ────────────────────────────────────────────────────────────
      Column() {

        // Back arrow
        Text('←')
          .fontSize(12)
          .fontColor('#8B949E')
          .onClick(() => router.back())
          .alignSelf(ItemAlign.Start)
          .padding({ left: 14, top: 8, bottom: 0 })

        // ── Loading ──────────────────────────────────────────────────────────
        if (this.loading) {
          Column({ space: 6 }) {
            LoadingProgress().color('#00E5C8').width(26).height(26)
            Text('Loading...').fontSize(10).fontColor('#8B949E')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

        // ── Error / Empty ────────────────────────────────────────────────────
        } else if (this.loadError || this.steps.length === 0) {
          Column({ space: 6 }) {
            Text(this.loadError ? 'Could not load steps' : 'No steps available')
              .fontSize(11)
              .fontColor(this.loadError ? '#FF4444' : '#8B949E')
              .textAlign(TextAlign.Center)
            Button('Back')
              .onClick(() => router.back())
              .backgroundColor('#21262D')
              .fontColor('#8B949E')
              .fontSize(10)
              .height(28)
              .width('52%')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

        // ── All done ─────────────────────────────────────────────────────────
        } else if (this.currentIdx >= this.steps.length) {
          Column({ space: 8 }) {
            Stack({ alignContent: Alignment.Center }) {
              // Teal circle background
              Column()
                .width(52).height(52)
                .borderRadius(26)
                .backgroundColor('#00E5C8')

              // Checkmark — two rotated bars meeting at the knee
              Stack() {
                // Short left arm (down-left stroke)
                Column()
                  .width(3.5).height(11)
                  .backgroundColor('#0D1117')
                  .borderRadius(2)
                  .rotate({ angle: -42 })
                  .translate({ x: -7, y: 4 })
                // Long right arm (up-right stroke)
                Column()
                  .width(3.5).height(20)
                  .backgroundColor('#0D1117')
                  .borderRadius(2)
                  .rotate({ angle: 38 })
                  .translate({ x: 5, y: -2 })
              }
              .width(44).height(44)
            }

            Text('All Done')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')

            Button('Back to Trip')
              .onClick(() => router.back())
              .backgroundColor('#00C4AE')
              .fontColor('#0D1117')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .height(30)
              .width('58%')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

        // ── Current step ─────────────────────────────────────────────────────
        } else {
          Column() {

            // Scroll viewport has top padding so even when fully scrolled up,
            // content starts at ~75px from screen top — safely inside the ring.
            // Width '52%' is calculated to never overlap the 88% ring arc at
            // that y position (ring inner edge ≈ 124px from centre on a 466px
            // screen; 52% half-width ≈ 121px < 124px ✓).
            Scroll(this.scroller) {
              Column({ space: 6 }) {
                Text(this.steps[this.currentIdx]?.title ?? '')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#00E5C8')
                  .textAlign(TextAlign.Center)
                  .width('52%')
                  .lineHeight(18)

                Divider()
                  .color('#21262D')
                  .width('36%')
                  .strokeWidth(0.5)
                  .margin({ top: 2, bottom: 2 })

                Text(this.steps[this.currentIdx]?.description ?? '')
                  .fontSize(11)
                  .fontColor('#C9D1D9')
                  .textAlign(TextAlign.Center)
                  .width('52%')
                  .lineHeight(16)

                // Bottom spacer keeps last line above nav buttons
                Text('').height(50)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            }
            .layoutWeight(1)
            .width('100%')
            // Top padding ensures the first line of content sits at ~75px from
            // the screen top, well within the safe horizontal zone of the ring.
            .padding({ top: 46 })
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .friction(35.0)

            // ── < > navigation ───────────────────────────────────────────────
            Row({ space: 24 }) {
              Stack({ alignContent: Alignment.Center }) {
                Column()
                  .width(32).height(32)
                  .borderRadius(16)
                  .backgroundColor(this.currentIdx > 0 ? '#00C4AE' : '#1C2430')
                Text('<')
                  .fontSize(16)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Bold)
              }
              .onClick(() => this.goPrev())

              Stack({ alignContent: Alignment.Center }) {
                Column()
                  .width(32).height(32)
                  .borderRadius(16)
                  .backgroundColor('#00C4AE')
                Text('>')
                  .fontSize(16)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Bold)
              }
              .onClick(() => this.goNext())
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ bottom: 14 })

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
