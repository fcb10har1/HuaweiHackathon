/**
 * ArrivalSteps.ets — Step-by-step arrival checklist loaded from bundled JSON.
 * Canvas arc ring shows step progress around the screen edge.
 * Fully offline — no network required.
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
  private arcSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private arcCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.arcSettings);

  aboutToAppear(): void {
    this.dataService = new CountryDataService(getContext(this) as common.UIAbilityContext);
    this.dataService.getArrivalSteps(this.trip.countryCode).then(steps => {
      this.steps   = steps;
      this.loading = false;
    });
  }

  private arcColor(): string {
    const r = this.currentStep?.riskLevel ?? 'NORM';
    if (r === 'LEGAL')     return '#FF4444';
    if (r === 'SENSITIVE') return '#FFB800';
    return '#2DD4BF';
  }

  private drawArc(): void {
    if (this.steps.length === 0) return;
    const w = this.arcCtx.width;
    const h = this.arcCtx.height;
    const cx = w / 2;
    const cy = h / 2;
    const r  = Math.min(w, h) / 2 - 4;
    const startAngle = -Math.PI / 2;
    const fullAngle  = 2 * Math.PI;

    this.arcCtx.clearRect(0, 0, w, h);

    // Track ring (background)
    this.arcCtx.beginPath();
    this.arcCtx.arc(cx, cy, r, 0, fullAngle);
    this.arcCtx.strokeStyle = '#0D2035';
    this.arcCtx.lineWidth = 4;
    this.arcCtx.stroke();

    // Progress arc
    const progress = (this.currentIdx + 1) / this.steps.length;
    this.arcCtx.beginPath();
    this.arcCtx.arc(cx, cy, r, startAngle, startAngle + fullAngle * progress);
    this.arcCtx.strokeStyle = this.arcColor();
    this.arcCtx.lineWidth = 4;
    this.arcCtx.lineCap = 'round';
    this.arcCtx.stroke();
  }

  private get currentStep(): ArrivalStep | null {
    return this.steps[this.currentIdx] ?? null;
  }

  private get isLastStep(): boolean {
    return this.currentIdx >= this.steps.length - 1;
  }

  build() {
    Stack() {
      // ── Content ─────────────────────────────────────────────────────────────
      Column() {
        Row() {
          Text('\u2190')
            .fontSize(17)
            .fontColor('#4A7A8A')
            .onClick(() => router.back())
            .padding({ left: 10, right: 8 })
          Text('Arrival Steps')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E8F4F8')
          Blank()
          if (this.steps.length > 0) {
            Text(`${this.currentIdx + 1}/${this.steps.length}`)
              .fontSize(9)
              .fontColor('#4A7A8A')
              .padding({ right: 12 })
          }
        }
        .width('100%')
        .height(36)
        .alignItems(VerticalAlign.Center)

        Divider().color('#0D2035')

        if (this.loading) {
          Column() {
            Text('Loading...')
              .fontSize(11)
              .fontColor('#4A7A8A')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else if (this.steps.length === 0) {
          Column() {
            Text('No steps available')
              .fontSize(11)
              .fontColor('#4A7A8A')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          Column({ space: 8 }) {
            // Risk label
            Text(this.currentStep?.riskLevel ?? '')
              .fontSize(9)
              .fontColor(this.arcColor())
              .fontWeight(FontWeight.Bold)
              .margin({ top: 8 })

            // Step title
            Text(this.currentStep?.title ?? '')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E8F4F8')
              .textAlign(TextAlign.Center)
              .width('82%')
              .lineHeight(17)

            // Step description
            Scroll() {
              Text(this.currentStep?.description ?? '')
                .fontSize(10)
                .fontColor('#A0BEC8')
                .textAlign(TextAlign.Start)
                .width('100%')
                .lineHeight(15)
            }
            .width('82%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)

            // Navigation buttons
            Row({ space: 8 }) {
              if (this.currentIdx > 0) {
                Button('Back')
                  .onClick(() => {
                    this.currentIdx -= 1;
                    this.drawArc();
                  })
                  .backgroundColor('#0D2035')
                  .fontColor('#4A7A8A')
                  .fontSize(11)
                  .width('36%')
                  .height(34)
                  .borderRadius(17)
              }
              Button(this.isLastStep ? 'Done' : 'Next')
                .onClick(() => {
                  if (this.isLastStep) {
                    router.back();
                  } else {
                    this.currentIdx += 1;
                    this.drawArc();
                  }
                })
                .backgroundColor(this.isLastStep ? '#2DD4BF' : '#1F6FEB')
                .fontColor(this.isLastStep ? '#060D1A' : '#FFFFFF')
                .fontWeight(this.isLastStep ? FontWeight.Bold : FontWeight.Normal)
                .fontSize(11)
                .width(this.currentIdx > 0 ? '36%' : '60%')
                .height(34)
                .borderRadius(17)
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
      .backgroundColor('#060D1A')

      // ── Arc progress ring overlay ────────────────────────────────────────────
      if (!this.loading && this.steps.length > 0) {
        Canvas(this.arcCtx)
          .width('100%')
          .height('100%')
          .onReady(() => { this.drawArc(); })
          .hitTestBehavior(HitTestMode.None)
      }
    }
    .width('100%')
    .height('100%')
    .gesture(
      PanGesture({ direction: PanDirection.Right, distance: 50 })
        .onActionEnd(() => router.back())
    )
  }
}
