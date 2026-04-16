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
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

      } else if (this.steps.length === 0) {
        Column({ space: 8 }) {
          Text('No steps available')
            .fontSize(12)
            .fontColor('#8B949E')
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
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

      } else {
        List({ space: 8 }) {
          ForEach(this.steps, (step: ArrivalStep, idx: number) => {
            ListItem() {
              Row({ space: 10 }) {
                // Tick circle
                Text(this.completedSteps[idx] ? '✓' : '')
                  .fontSize(13)
                  .fontColor('#0D1117')
                  .width(28)
                  .height(28)
                  .textAlign(TextAlign.Center)
                  .lineHeight(28)
                  .backgroundColor(this.completedSteps[idx] ? '#00E5C8' : 'transparent')
                  .borderRadius(14)
                  .border({
                    width: 1.5,
                    color: this.completedSteps[idx] ? '#00E5C8' : '#3A4A5C',
                    style: BorderStyle.Solid,
                  })
                  .onClick(() => this.toggleStep(idx))
                  .flexShrink(0)

                // Step text
                Column({ space: 3 }) {
                  Text(step.title)
                    .fontSize(11)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.completedSteps[idx] ? '#4A5568' : '#E6EDF3')
                    .lineHeight(16)
                    .decoration(this.completedSteps[idx]
                      ? { type: TextDecorationType.LineThrough, color: '#4A5568' }
                      : { type: TextDecorationType.None })

                  if (step.description) {
                    Text(step.description)
                      .fontSize(9)
                      .fontColor(this.completedSteps[idx] ? '#3A4450' : '#8B949E')
                      .lineHeight(13)
                      .maxLines(3)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding({ left: 10, right: 10, top: 10, bottom: 10 })
              .backgroundColor(this.completedSteps[idx] ? '#0D120D' : '#161B22')
              .borderRadius(10)
              .alignItems(VerticalAlign.Center)
            }
          })

          // All done footer
          ListItem() {
            if (this.completedCount === this.steps.length) {
              Column({ space: 6 }) {
                Text('All Done')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#00E5C8')
                Button('Back to Trip')
                  .onClick(() => router.back())
                  .backgroundColor('#00C4AE')
                  .fontColor('#0D1117')
                  .fontSize(11)
                  .fontWeight(FontWeight.Bold)
                  .height(34)
                  .width('65%')
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .alignItems(HorizontalAlign.Center)
            }
          }
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
