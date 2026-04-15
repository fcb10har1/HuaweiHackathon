/**
 * Splash.ets — Launch screen shown for ~1.5s on app open.
 * Plays a sheen sweep over the logo, then navigates to the trip list.
 */
import router from '@ohos.router';

@Entry
@Component
struct Splash {
  @State sheenOpacity: number  = 0;
  @State rootOpacity: number   = 1;
  @State dot1Opacity: number   = 0.8;
  @State dot2Opacity: number   = 0.5;
  @State dot3Opacity: number   = 0.25;

  aboutToAppear(): void {
    // Sheen: fade in then out over 800 ms starting at 200 ms
    setTimeout(() => {
      animateTo({ duration: 350, curve: Curve.EaseIn }, () => {
        this.sheenOpacity = 0.6;
      });
    }, 200);
    setTimeout(() => {
      animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
        this.sheenOpacity = 0;
      });
    }, 550);

    // Pulse the dots once for visual life
    setTimeout(() => {
      animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
        this.dot1Opacity = 0.25;
        this.dot2Opacity = 0.8;
        this.dot3Opacity = 0.5;
      });
    }, 700);
    setTimeout(() => {
      animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
        this.dot1Opacity = 0.5;
        this.dot2Opacity = 0.25;
        this.dot3Opacity = 0.8;
      });
    }, 1000);

    // Fade out and navigate at 1.5 s
    setTimeout(() => {
      animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
        this.rootOpacity = 0;
      });
    }, 1400);
    setTimeout(() => {
      router.replaceUrl({ url: 'pages/Index' });
    }, 1720);
  }

  build() {
    Stack() {
      Column({ space: 14 }) {
        // ── Logo with glow rings + sheen ────────────────────────────────────────
        Stack() {
          Circle()
            .width(96).height(96)
            .fillColor('transparent')
            .border({ width: 1, color: '#0A2840', radius: 48 })
          Circle()
            .width(82).height(82)
            .fillColor('transparent')
            .border({ width: 1, color: '#163550', radius: 41 })
          Image($r('app.media.foreground'))
            .width(68).height(68)
            .borderRadius(34)
          // Sheen overlay — white sweep
          Circle()
            .width(68).height(68)
            .fillColor('#FFFFFF')
            .opacity(this.sheenOpacity)
        }
        .width(96).height(96)

        Text('ArrivalRitual')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E8F4F8')

        // ── Pulsing status dots ─────────────────────────────────────────────────
        Row({ space: 7 }) {
          Circle().width(5).height(5).fillColor('#2DD4BF').opacity(this.dot1Opacity)
          Circle().width(5).height(5).fillColor('#2DD4BF').opacity(this.dot2Opacity)
          Circle().width(5).height(5).fillColor('#2DD4BF').opacity(this.dot3Opacity)
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#060D1A')
    .opacity(this.rootOpacity)
  }
}
