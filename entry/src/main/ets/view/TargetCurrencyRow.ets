import { CurrencyData } from '../viewmodel/CurrencyData';

@Component
export struct TargetCurrencyRowComponent {
  @Consume selectedTargetCurrency: CurrencyData;
  @Prop amount: string = '';
  onCurrencySelect?: () => void;

  build() {
    Row() {
      Row() {
        Image(this.selectedTargetCurrency.flag)
          .width(20)
          .height(20)
          .borderRadius(4)
          .margin({ right: 12 })

        Text(this.selectedTargetCurrency.code)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .width('27.00vp')
          .fontColor(Color.Black)

        Image($r('app.media.ic_arrow_right'))
          .width(12)
          .height(12)
          .margin({ left: 6, right: 6 })

      }
      .onClick(() => {
        if (this.onCurrencySelect) {
          this.onCurrencySelect();
        }
      })

      Text(this.amount)
        .layoutWeight(1)
        .textAlign(TextAlign.Start)
        .borderRadius('25vp')
        .backgroundColor($r('app.color.inputBackground'))
        .maxFontSize(19)
        .minFontSize(11)
        .maxLines(1)
        .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ left: 17, right: 12 })
        .height('35vp')
        .fontWeight(FontWeight.Bold)

    }
    .width($r('app.string.w_100'))
    .height('35vp')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
  }
}