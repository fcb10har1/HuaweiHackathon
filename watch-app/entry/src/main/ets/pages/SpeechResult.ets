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
      Row() {
        Text('\u2190')
          .fontSize(17)
          .fontColor('#4A7A8A')
          .onClick(() => router.back())
          .padding({ left: 10, right: 8 })
        Text('Convo Result')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E8F4F8')
      }
      .width('100%')
      .height(36)
      .alignItems(VerticalAlign.Center)

      Divider().color('#0D2035')

      Scroll() {
        Column({ space: 12 }) {

          // ── What was said ──────────────────────────────────────────────────
          if (this.transcribedEnglish) {
            Column({ space: 4 }) {
              Text('They said:')
                .fontSize(9)
                .fontColor('#4A7A8A')
              Text(`"${this.transcribedEnglish}"`)
                .fontSize(11)
                .fontColor('#A0BEC8')
                .fontStyle(FontStyle.Italic)
                .textAlign(TextAlign.Center)
                .width('84%')
                .lineHeight(16)
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
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#E8F4F8')
                .textAlign(TextAlign.Center)
                .width('84%')
                .lineHeight(18)

              if (this.current.local) {
                Divider().color('#0D2035').width('55%')
                Text(`(${this.languageName}):`)
                  .fontSize(9)
                  .fontColor('#4A7A8A')
                Text(this.current.local)
                  .fontSize(12)
                  .fontColor('#2DD4BF')
                  .textAlign(TextAlign.Center)
                  .width('84%')
                  .lineHeight(18)
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
              Button('\u2039')
                .onClick(() => {
                  if (this.selectedIdx > 0) this.selectedIdx -= 1;
                })
                .backgroundColor(this.selectedIdx > 0 ? '#0D2035' : '#060D1A')
                .fontColor(this.selectedIdx > 0 ? '#E8F4F8' : '#0D2035')
                .fontSize(20)
                .width('35%')
                .height(34)
                .borderRadius(17)
                .enabled(this.selectedIdx > 0)

              Button('\u203A')
                .onClick(() => {
                  if (this.selectedIdx < this.replies.length - 1) this.selectedIdx += 1;
                })
                .backgroundColor(this.selectedIdx < this.replies.length - 1 ? '#0D2035' : '#060D1A')
                .fontColor(this.selectedIdx < this.replies.length - 1 ? '#E8F4F8' : '#0D2035')
                .fontSize(20)
                .width('35%')
                .height(34)
                .borderRadius(17)
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
    .backgroundColor('#060D1A')
    .gesture(
      PanGesture({ direction: PanDirection.Right, distance: 50 })
        .onActionEnd(() => router.back())
    )
  }
}
