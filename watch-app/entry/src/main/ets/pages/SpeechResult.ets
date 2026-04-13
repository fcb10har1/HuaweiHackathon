/**
 * SpeechResult.ets — Shows what the local said (in English) and
 * suggested replies in both English and the local language.
 * User stays on this screen until they navigate back manually.
 */
import router from '@ohos.router';
import { SpeechReply } from '../common/Types';

@Entry
@Component
struct SpeechResult {
  private params: Record<string, string> = router.getParams() as Record<string, string>;
  private transcribedEnglish: string = this.params['transcribedEnglish'] ?? '';
  private languageName: string        = this.params['languageName'] ?? '';
  private replies: SpeechReply[]      = JSON.parse(this.params['repliesJson'] ?? '[]') as SpeechReply[];

  @State selectedIdx: number = 0;

  private get current(): SpeechReply | null {
    return this.replies[this.selectedIdx] ?? null;
  }

  build() {
    Column() {
      // ── Header ──────────────────────────────────────────────────────────────
      Row() {
        Text('←')
          .fontSize(18)
          .fontColor('#8B949E')
          .onClick(() => router.back())
          .padding({ left: 8, right: 8 })
        Text('Convo Result')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E6EDF3')
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)

      Divider().color('#21262D')

      Scroll() {
        Column({ space: 12 }) {

          // ── What was said ──────────────────────────────────────────────────
          if (this.transcribedEnglish) {
            Column({ space: 4 }) {
              Text('They said:')
                .fontSize(10)
                .fontColor('#8B949E')
              Text(`"${this.transcribedEnglish}"`)
                .fontSize(12)
                .fontColor('#C9D1D9')
                .fontStyle(FontStyle.Italic)
                .textAlign(TextAlign.Center)
                .width('90%')
                .lineHeight(18)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 12, bottom: 4 })

            Divider().color('#21262D').width('80%')
          }

          // ── Reply navigation ───────────────────────────────────────────────
          Text('You can say:')
            .fontSize(10)
            .fontColor('#8B949E')
            .margin({ top: 8 })

          // Selected reply card
          if (this.current) {
            Column({ space: 8 }) {
              Text(this.current.english)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#E6EDF3')
                .textAlign(TextAlign.Center)
                .width('90%')
                .lineHeight(20)

              if (this.current.local) {
                Divider().color('#21262D').width('60%')
                Text(`(${this.languageName}):`)
                  .fontSize(9)
                  .fontColor('#8B949E')
                Text(this.current.local)
                  .fontSize(13)
                  .fontColor('#00E5C8')
                  .textAlign(TextAlign.Center)
                  .width('90%')
                  .lineHeight(20)
              }
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#161B22')
            .borderRadius(8)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 10, right: 10 })
          }

          // Pagination indicator
          if (this.replies.length > 1) {
            Text(`${this.selectedIdx + 1} / ${this.replies.length}`)
              .fontSize(10)
              .fontColor('#8B949E')
          }

          // ← → navigation buttons
          if (this.replies.length > 1) {
            Row({ space: 16 }) {
              Button('‹')
                .onClick(() => {
                  if (this.selectedIdx > 0) this.selectedIdx -= 1;
                })
                .backgroundColor(this.selectedIdx > 0 ? '#21262D' : '#0D1117')
                .fontColor(this.selectedIdx > 0 ? '#E6EDF3' : '#21262D')
                .fontSize(20)
                .width('35%')
                .height(36)
                .enabled(this.selectedIdx > 0)

              Button('›')
                .onClick(() => {
                  if (this.selectedIdx < this.replies.length - 1) this.selectedIdx += 1;
                })
                .backgroundColor(this.selectedIdx < this.replies.length - 1 ? '#21262D' : '#0D1117')
                .fontColor(this.selectedIdx < this.replies.length - 1 ? '#E6EDF3' : '#21262D')
                .fontSize(20)
                .width('35%')
                .height(36)
                .enabled(this.selectedIdx < this.replies.length - 1)
            }
          }

          Text('Swipe right or tap ← to go back')
            .fontSize(9)
            .fontColor('#6E7681')
            .margin({ top: 8, bottom: 12 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
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
