/**
 * AlertsList.ets — Carousel list of cultural/contextual alerts.
 * Shows all fallback alerts from the country JSON pack, plus any SENSITIVE/LEGAL
 * alerts the user has dismissed during the trip (pulled from device storage).
 * The current centre card is enlarged; adjacent cards are smaller.
 */
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { Trip, ContextAlert, riskColor } from '../common/Types';
import { CountryDataService } from '../services/CountryDataService';
import { StorageService } from '../services/StorageService';

@Entry
@Component
struct AlertsList {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private trip: Trip = JSON.parse(this.params['tripJson'] ?? '{}') as Trip;

  @State alerts: ContextAlert[] = [];
  @State loading: boolean       = true;

  private dataService: CountryDataService | null = null;
  private storage: StorageService | null         = null;

  aboutToAppear(): void {
    const ctx        = getContext(this) as common.UIAbilityContext;
    this.dataService = new CountryDataService(ctx);
    this.storage     = new StorageService(ctx);
    this.loadAlerts();
  }

  private async loadAlerts(): Promise<void> {
    const jsonAlerts = await this.dataService!.getAllFallbackAlerts(this.trip.countryCode);
    const triggered  = await this.storage!.loadTriggeredAlerts(this.trip.countryCode);
    // Merge: triggered alerts that aren't already in the JSON list
    const jsonIds    = new Set(jsonAlerts.map(a => a.alertId));
    const extra      = triggered.filter(a => !jsonIds.has(a.alertId));
    this.alerts      = [...jsonAlerts, ...extra];
    this.loading     = false;
  }

  private riskBadge(level: string): string {
    if (level === 'LEGAL')     return 'LEGAL';
    if (level === 'SENSITIVE') return 'SENSITIVE';
    return 'NORM';
  }

  build() {
    Column() {

      // ── Header ─────────────────────────────────────────────────────────────
      Stack({ alignContent: Alignment.Center }) {
        Text('Alerts')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .width('100%')

        Row() {
          Text('←')
            .fontSize(18)
            .fontColor('#8B949E')
            .padding({ left: 12, right: 8 })
            .onClick(() => router.back())
          Blank()
        }
        .width('100%')
      }
      .width('100%')
      .height(40)

      Divider().color('#21262D')

      // ── Body ───────────────────────────────────────────────────────────────
      if (this.loading) {
        Column({ space: 6 }) {
          LoadingProgress().color('#00E5C8').width(28).height(28)
          Text('Loading alerts...')
            .fontSize(10)
            .fontColor('#8B949E')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

      } else if (this.alerts.length === 0) {
        Column({ space: 6 }) {
          Text('No alerts for this trip.')
            .fontSize(12)
            .fontColor('#8B949E')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

      } else {

        // ── Alert list ──────────────────────────────────────────────────────
        List({ space: 10 }) {
          ForEach(this.alerts, (alert: ContextAlert) => {
            ListItem() {
              Column({ space: 5 }) {

                // Risk indicator row: coloured dot + level badge
                Row({ space: 5 }) {
                  Column()
                    .width(8).height(8)
                    .borderRadius(4)
                    .backgroundColor(riskColor(alert.riskLevel))
                  Text(this.riskBadge(alert.riskLevel))
                    .fontSize(8)
                    .fontColor(riskColor(alert.riskLevel))
                    .letterSpacing(0.8)
                    .fontWeight(FontWeight.Bold)
                }
                .justifyContent(FlexAlign.Center)

                // Scenario / location name
                Text(alert.locationName)
                  .fontSize(8)
                  .fontColor('#6E7681')
                  .textAlign(TextAlign.Center)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('90%')

                // Alert message
                Text(alert.message)
                  .fontSize(11)
                  .fontColor('#E6EDF3')
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .lineHeight(17)
              }
              .width('84%')
              .padding({ left: 12, right: 12, top: 14, bottom: 14 })
              .backgroundColor('#161B22')
              .borderRadius(12)
              .border({ width: 1, color: riskColor(alert.riskLevel), style: BorderStyle.Solid })
              .alignItems(HorizontalAlign.Center)
            }
            .width('100%')
          })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .friction(6.0)
        .alignListItem(ListItemAlign.Center)
        .padding({ top: 8, bottom: 8 })

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
