import { BaseCurrencyRow } from '../view/BaseCurrencyRow';
import { TargetCurrencyRowComponent } from '../view/TargetCurrencyRow';
import { CurrencyData } from '../viewmodel/CurrencyData';
import { CurrencyViewModel } from '../viewmodel/CurrencyViewModel';
import { common2D, drawing } from '@kit.ArkGraphics2D';

@Observed
export class TmpClass {
  currencyType: string;
  currencyCode: string;

  constructor(_currencyType: string, _currencyCode: string) {
    this.currencyType = _currencyType;
    this.currencyCode = _currencyCode;
  }
}

type UpdateStatus = 'idle' | 'loading' | 'updated' | 'error';

@Builder
export function ExchangePageBuilder(name: string, param: Object) {
  ExchangePage()
}

@Component
export struct ExchangePage {
  @Consume('pageInfos') pageInfos: NavPathStack;
  @Consume baseAmount: string
  @Consume targetAmount: string
  @Consume @Watch('OnSelected') selectedBaseCurrency: CurrencyData
  @Consume @Watch('OnSelected') selectedTargetCurrency: CurrencyData
  @Consume viewModel: CurrencyViewModel
  @Consume @Watch('OnTriggerMechanism') triggerMechanism: number
  private color1: common2D.Color = {
    alpha: 255,
    red: 32,
    green: 80,
    blue: 224
  };
  @State drawingColorFilterFirst: ColorFilter | undefined =
    drawing.ColorFilter.createBlendModeColorFilter(this.color1, drawing.BlendMode.SRC_IN);
  @State updateStatus: UpdateStatus = 'idle';
  private statusResetTimer: number = -1;
  // Bumped on every new update tap and on aboutToDisappear; an in-flight
  // fetch's `.then()` checks its captured id against this and bails out if
  // it has been superseded or the page has gone away.
  private updateRequestId: number = 0;

  aboutToAppear(): void {
    this.recalcTarget();
  }

  aboutToDisappear(): void {
    this.updateRequestId++;
    if (this.statusResetTimer !== -1) {
      clearTimeout(this.statusResetTimer);
      this.statusResetTimer = -1;
    }
  }

  onPageShow(): void {
    this.recalcTarget();
  }

  recalcTarget() {
    this.targetAmount = this.viewModel.calculateConversion(this.baseAmount);
  }

  OnSelected(changedPropertyName: string) {
    this.recalcTarget();
  }

  OnTriggerMechanism(changedPropertyName: string) {
    this.recalcTarget();
  }

  toggleCurrency() {
    const tempBaseCurrency: CurrencyData = this.selectedBaseCurrency;
    const tempTargetCurrency: CurrencyData = this.selectedTargetCurrency;
    this.selectedBaseCurrency = tempTargetCurrency;
    this.selectedTargetCurrency = tempBaseCurrency;
    this.viewModel.selectedBaseCurrency = tempTargetCurrency;
    this.viewModel.selectedTargetCurrency = tempBaseCurrency;
    this.recalcTarget();
  }

  private updateLabel(): Resource {
    if (this.updateStatus === 'loading') return $r('app.string.update_loading');
    if (this.updateStatus === 'updated') return $r('app.string.updated');
    if (this.updateStatus === 'error') return $r('app.string.update_failed');
    return $r('app.string.update');
  }

  // Loading / updated / error share the muted (gray) style; idle uses the
  // active blue style. Error keeps muted style so it doesn't look like a CTA.
  private updateFontColor(): Resource {
    return this.updateStatus === 'idle'
      ? $r('app.color.update_font')
      : $r('app.color.updated_font');
  }

  private updateBgColor(): Resource {
    return this.updateStatus === 'idle'
      ? $r('app.color.update_bg')
      : $r('app.color.updated_bg');
  }

  private onUpdateTap() {
    if (this.updateStatus === 'loading') return;
    if (this.statusResetTimer !== -1) {
      clearTimeout(this.statusResetTimer);
      this.statusResetTimer = -1;
    }
    const requestId = ++this.updateRequestId;
    this.updateStatus = 'loading';
    this.viewModel.fetchAndUpdateRates().then((ok: boolean) => {
      // Stale guard: page gone or a newer tap has taken over.
      if (requestId !== this.updateRequestId) return;
      this.updateStatus = ok ? 'updated' : 'error';
      this.recalcTarget();
      this.statusResetTimer = setTimeout(() => {
        if (requestId !== this.updateRequestId) return;
        if (this.updateStatus !== 'loading') {
          this.updateStatus = 'idle';
        }
        this.statusResetTimer = -1;
      }, 5000);
    });
  }

  build() {
    NavDestination() {
      Column() {
        Column() {
          Blank().backgroundColor(Color.Transparent).height('11vp')
          Column() {
            Text($r('app.string.title'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .margin({ top: 4, bottom: 0 })

            Text($r('app.string.sub_title'))
              .fontSize(11)
              .fontColor(Color.White)
              .margin({ top: 8, bottom: 7 })
              .opacity(0.8)
          }
          .width($r('app.string.w_100'))
          .alignItems(HorizontalAlign.Center)
        }
        .width($r('app.string.w_100'))

        Column() {

          Stack() {
            Row() {

              Blank().width('7%')

              Image($r('app.media.icon_convert'))
                .width('21vp')
                .fillColor($r('app.color.inputBackground'))
                .backgroundColor(Color.Transparent)
                .foregroundColor(Color.Blue)
                .colorFilter(this.drawingColorFilterFirst)
                .margin({ top: '1vp' })
                .onClick(() => {
                  this.toggleCurrency()
                })

            }
            .width($r('app.string.w_100'))
            .alignSelf(ItemAlign.Center)
            .align(Alignment.Center)
            .height('33vp')

            Text(this.updateLabel())
              .fontSize(11)
              .fontColor(this.updateFontColor())
              .backgroundColor(this.updateBgColor())
              .opacity(this.updateStatus === 'loading' ? 0.7 : 1)
              .borderRadius(16)
              .padding({
                left: 12,
                right: 12,
                top: 4,
                bottom: 4
              })
              .onClick(() => {
                this.onUpdateTap();
              })
              .alignSelf(ItemAlign.Center)
              .margin({ top: 6, bottom: 6 })
          }

          BaseCurrencyRow({
            amount: this.baseAmount,
            onAmountChange: (value: string) => {
              this.baseAmount = value;
              this.targetAmount = this.viewModel.calculateConversion(value);
            },
            onCurrencySelect: () => {
              this.pageInfos.pushPathByName(
                'SelectCurrencyPage', new TmpClass('base', this.selectedBaseCurrency.code)
              );
            }
          })

          Divider()
            .height(5)
            .opacity(0.2)
            .color($r('app.color.divider'))
            .margin({ left: 16, right: 16 })

          TargetCurrencyRowComponent({
            amount: this.targetAmount,
            onCurrencySelect: () => {
              this.pageInfos.pushPathByName(
                'SelectCurrencyPage', new TmpClass('target', this.selectedTargetCurrency.code)
              );
            }
          })

          Column() {
            Blank().height(7)
            Text($r('app.string.reference'))
              .fontSize(9)
              .width('70%')
              .fontColor(Color.Gray)
              .padding({ top: 8, left: 12 })
              .opacity(0.8)
              .textAlign(TextAlign.Start)

            Column() {

              Image($r('app.media.logo2'))
                .width('35%')
                .height('75%')
            }
            .width('40%')
            .height('25vp')
          }
        }
        .width($r('app.string.w_100'))
        .backgroundColor(Color.White)
        .layoutWeight(1)
        .borderRadius({ topLeft: 16, topRight: 16 })

      }
      .width($r('app.string.w_100'))
      .height($r('app.string.w_100'))
      .backgroundColor($r('app.color.exchange_bg'))
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
    })
  }
}
