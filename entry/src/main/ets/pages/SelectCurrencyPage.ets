import { CurrencyItem } from '../view/CurrencyItem';
import { SearchBar } from '../view/SearchBar';
import { CurrencyData } from '../viewmodel/CurrencyData';
import { CurrencyViewModel } from '../viewmodel/CurrencyViewModel';
import { TmpClass } from './ExchangePage';
import { Haptics } from '../common/Haptics';

@Builder
export function SelectCurrencyPageBuilder(name: string, param: Object) {
  SelectCurrencyPage()
}

@Component
export struct SelectCurrencyPage {
  @Consume('pageInfos') pageInfos: NavPathStack;
  @State searchResult: CurrencyData[] = [];
  private currentCurrencyType: string = '';
  @State currentCurrencyCode: string = 'TRY';
  @Consume viewModel: CurrencyViewModel;
  @Consume selectedBaseCurrency: CurrencyData
  @Consume selectedTargetCurrency: CurrencyData
  @Consume triggerMechanism: number

  aboutToAppear() {
    this.init()
  }

  onPageShow(): void {
    this.init()
  }

  init() {
    this.searchResult = this.viewModel.getCurrencyData();
  }

  private applySelection(currency: CurrencyData): void {
    if (this.currentCurrencyType === 'base') {
      this.viewModel.selectedBaseCurrency = currency;
      this.selectedBaseCurrency = currency;
    } else if (this.currentCurrencyType === 'target') {
      this.viewModel.selectedTargetCurrency = currency;
      this.selectedTargetCurrency = currency;
    }
    this.viewModel.persistSelection();
    this.viewModel.pushRecent(currency.code);
    Haptics.tap();
    this.pageInfos.pop();
  }

  private resolveRecents(): CurrencyData[] {
    const out: CurrencyData[] = [];
    for (const code of this.viewModel.recentCodes) {
      const c = this.viewModel.getCurrencyByCode(code);
      if (c) {
        out.push(c);
      }
    }
    return out;
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Blank().width('16%')
          Column() {
            Image($r('app.media.ic_arrow_left'))
              .width(25)
              .height(25)
              .margin({ top: '19vp' })
              .accessibilityText($r('app.string.a11y_back'))
              .onClick(() => {
                this.triggerMechanism++;
                this.pageInfos.pop()
              })
          }
          .alignSelf(ItemAlign.Center)
          .width(25)

          SearchBar({
            placeholder: $r('app.string.search'),
            color: $r('app.color.updated_bg'),
            onSearch: (value: string) => {
              this.searchResult = this.viewModel.searchCurrency(value);
            }
          })
        }
        .alignItems(VerticalAlign.Bottom)
        .height('60vp')
        .width($r('app.string.w_100'))

        if (this.resolveRecents().length > 0) {
          Row({ space: 8 }) {
            ForEach(this.resolveRecents(), (c: CurrencyData) => {
              Row() {
                Image(c.flag)
                  .width(14)
                  .height(14)
                  .borderRadius(2)
                  .margin({ right: 4 })
                Text(c.code)
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.currency_code'))
              }
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(12)
              .backgroundColor($r('app.color.updated_bg'))
              .accessibilityText(c.name)
              .onClick(() => {
                this.applySelection(c);
              })
            }, (c: CurrencyData) => c.code)
          }
          .width($r('app.string.w_100'))
          .padding({ left: 12, right: 12, bottom: 6 })
          .justifyContent(FlexAlign.Center)
        }

        if (this.searchResult.length === 0) {
          Column() {
            Text($r('app.string.no_results'))
              .fontSize(13)
              .fontColor($r('app.color.currency_name'))
              .textAlign(TextAlign.Center)
          }
          .backgroundColor($r('app.color.exchange_panel_bg'))
          .layoutWeight(1)
          .width($r('app.string.w_100'))
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.searchResult, (currencyData: CurrencyData) => {
              ListItem() {
                CurrencyItem({
                  currency: currencyData,
                  isSelected: currencyData.code === this.currentCurrencyCode,
                  onItemClick: (currency: CurrencyData) => {
                    this.applySelection(currency);
                  }
                })
              }
            }, (item: CurrencyData) => item.code)

            ListItem() {
              Text($r('app.string.blank'))
                .visibility(Visibility.Hidden)
                .height('55vp')
            }
          }
          .backgroundColor($r('app.color.exchange_panel_bg'))
          .layoutWeight(1)
          .width($r('app.string.w_100'))
          .height($r('app.string.w_100'))
        }
      }
      .height($r('app.string.w_100'))
      .width($r('app.string.w_100'))
      .backgroundColor($r('app.color.currency_bg'))
      .alignItems(HorizontalAlign.Center)

    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
      this.currentCurrencyType = (context.pathInfo.param as TmpClass).currencyType
      this.currentCurrencyCode = (context.pathInfo.param as TmpClass).currencyCode
    })

  }
}
