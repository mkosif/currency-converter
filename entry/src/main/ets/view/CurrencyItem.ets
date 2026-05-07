import { CurrencyData } from '../viewmodel/CurrencyData';

@Component
export struct CurrencyItem {
  @Prop currency: CurrencyData;
  @Prop isSelected: boolean = false;
  onItemClick?: (currency: CurrencyData) => void;

  build() {
    Row() {
      Image(this.currency.flag)
        .width(21)
        .height(21)
        .margin({ left: 16, right: 12 })
        .objectFit(ImageFit.Cover)
        .borderRadius(4)

      Row() {
        Text(this.currency.code)
          .fontSize(13)
          .fontWeight(500)
          .fontColor($r('app.color.currency_code'))

        Text(this.currency.name)
          .fontSize(11)
          .margin({ left: 12 })
          .fontColor($r('app.color.currency_name'))
      }
      .justifyContent(FlexAlign.Start)
      .layoutWeight(1)

      if (this.isSelected) {
        Image($r('app.media.ic_check'))
          .width(24)
          .height(24)
          .margin({ right: 16 })
          .fillColor($r('app.color.currency_check'))
      }
    }
    .width($r('app.string.w_100'))
    .height(48)
    .backgroundColor($r('app.color.currency_item_bg'))
    .accessibilityText(`${this.currency.code} ${this.currency.name}`)
    .onClick(() => {
      if (this.onItemClick) {
        this.onItemClick(this.currency);
      }
    })
  }
}
