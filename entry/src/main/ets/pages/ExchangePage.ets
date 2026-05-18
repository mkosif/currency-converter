import { BaseCurrencyRow } from '../view/BaseCurrencyRow';
import { TargetCurrencyRowComponent } from '../view/TargetCurrencyRow';
import { CurrencyData } from '../viewmodel/CurrencyData';
import { CurrencyViewModel, FetchResult } from '../viewmodel/CurrencyViewModel';
import { common2D, drawing } from '@kit.ArkGraphics2D';
import { AppConstants } from '../common/AppConstants';
import { Haptics } from '../common/Haptics';

@Observed
export class TmpClass {
  currencyType: string;
  currencyCode: string;

  constructor(_currencyType: string, _currencyCode: string) {
    this.currencyType = _currencyType;
    this.currencyCode = _currencyCode;
  }
}

type UpdateStatus = 'idle' | 'loading' | 'updated' | 'error' | 'offline';

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
  @Consume lastUpdatedAt: number
  private readonly color1: common2D.Color = {
    alpha: 255,
    red: 32,
    green: 80,
    blue: 224
  };
  private readonly drawingColorFilterFirst: ColorFilter | undefined =
    drawing.ColorFilter.createBlendModeColorFilter(this.color1, drawing.BlendMode.SRC_IN);
  @State updateStatus: UpdateStatus = 'idle';
  @State isRefreshing: boolean = false;
  @State autoRefreshIntervalMin: number = 0;
  private statusResetTimer: number = -1;
  private updateRequestId: number = 0;
  private autoRefreshTimer: number = -1;

  aboutToAppear(): void {
    this.autoRefreshIntervalMin = this.viewModel.autoRefreshIntervalMin;
    this.recalcTarget();
    this.scheduleAutoRefresh();
  }

  aboutToDisappear(): void {
    this.updateRequestId++;
    if (this.statusResetTimer !== -1) {
      clearTimeout(this.statusResetTimer);
      this.statusResetTimer = -1;
    }
    if (this.autoRefreshTimer !== -1) {
      clearInterval(this.autoRefreshTimer);
      this.autoRefreshTimer = -1;
    }
    this.viewModel.persistAmount(this.baseAmount);
  }

  private scheduleAutoRefresh(): void {
    if (this.autoRefreshTimer !== -1) {
      clearInterval(this.autoRefreshTimer);
      this.autoRefreshTimer = -1;
    }
    if (this.autoRefreshIntervalMin <= 0) {
      return;
    }
    const periodMs = this.autoRefreshIntervalMin * 60 * 1000;
    this.autoRefreshTimer = setInterval(() => {
      if (this.updateStatus === 'loading') {
        return;
      }
      this.startFetch(() => {});
    }, periodMs);
  }

  private applyAutoRefresh(min: number): void {
    this.viewModel.setAutoRefreshIntervalMin(min);
    this.autoRefreshIntervalMin = min;
    this.scheduleAutoRefresh();
    Haptics.tap();
  }

  onPageShow(): void {
    this.recalcTarget();
  }

  recalcTarget() {
    if (!this.baseAmount || this.baseAmount.trim().length === 0) {
      this.targetAmount = AppConstants.EMPTY_TARGET_PLACEHOLDER;
      return;
    }
    this.targetAmount = this.viewModel.calculateConversion(this.baseAmount);
  }

  OnSelected(changedPropertyName: string) {
    this.recalcTarget();
  }

  OnTriggerMechanism(changedPropertyName: string) {
    this.recalcTarget();
  }

  private onCrownEvent(velocity: number): void {
    try {
      const dir = velocity > 0 ? 1 : -1;
      const cur = parseFloat(this.baseAmount);
      const base = Number.isFinite(cur) && cur >= 0 ? cur : 0;
      const next = Math.max(0, base + dir * AppConstants.CROWN_AMOUNT_STEP);
      this.baseAmount = CurrencyViewModel.formatAmount(next, 2);
      this.recalcTarget();
    } catch (_err) {
    }
  }

  toggleCurrency() {
    const tempBaseCurrency: CurrencyData = this.selectedBaseCurrency;
    const tempTargetCurrency: CurrencyData = this.selectedTargetCurrency;
    this.selectedBaseCurrency = tempTargetCurrency;
    this.selectedTargetCurrency = tempBaseCurrency;
    this.viewModel.selectedBaseCurrency = tempTargetCurrency;
    this.viewModel.selectedTargetCurrency = tempBaseCurrency;
    this.viewModel.persistSelection();
    Haptics.tap();
    this.recalcTarget();
  }

  private updateLabel(): Resource {
    if (this.updateStatus === 'loading') {
      return $r('app.string.update_loading');
    }
    if (this.updateStatus === 'updated') {
      return $r('app.string.updated');
    }
    if (this.updateStatus === 'error') {
      return $r('app.string.update_failed');
    }
    if (this.updateStatus === 'offline') {
      return $r('app.string.update_offline');
    }
    return $r('app.string.update');
  }

  private updatedAtText(): string {
    if (!this.lastUpdatedAt || this.lastUpdatedAt <= 0) {
      return '';
    }
    const d = new Date(this.lastUpdatedAt);
    let timeStr: string;
    try {
      timeStr = d.toLocaleTimeString('en', {
        hour: '2-digit',
        minute: '2-digit',
        hour12: false
      } as Intl.DateTimeFormatOptions);
    } catch (_err) {
      const hh = d.getHours().toString().padStart(2, '0');
      const mm = d.getMinutes().toString().padStart(2, '0');
      timeStr = `${hh}:${mm}`;
    }
    let prefix = 'Updated';
    try {
      prefix = this.getUIContext().getHostContext()
        ?.resourceManager.getStringSync($r('app.string.updated_at_prefix').id) ?? prefix;
    } catch (_err) {
    }
    return `${prefix} ${timeStr}`;
  }

  private isStale(): boolean {
    if (!this.lastUpdatedAt || this.lastUpdatedAt <= 0) {
      return false;
    }
    return (Date.now() - this.lastUpdatedAt) > AppConstants.STALE_THRESHOLD_MS;
  }

  private updatedAtFontColor(): Resource {
    return this.isStale()
      ? $r('app.color.text_warning')
      : $r('app.color.text_secondary');
  }

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

  private startFetch(onComplete: () => void): void {
    if (this.updateStatus === 'loading') {
      return;
    }
    if (this.statusResetTimer !== -1) {
      clearTimeout(this.statusResetTimer);
      this.statusResetTimer = -1;
    }
    const requestId = ++this.updateRequestId;
    this.updateStatus = 'loading';
    this.viewModel.fetchAndUpdateRates().then((result: FetchResult) => {
      if (requestId !== this.updateRequestId) {
        return;
      }
      if (result === 'ok') {
        this.updateStatus = 'updated';
        this.lastUpdatedAt = this.viewModel.lastUpdatedAt;
        Haptics.success();
      } else if (result === 'offline') {
        this.updateStatus = 'offline';
        Haptics.error();
      } else {
        this.updateStatus = 'error';
        Haptics.error();
      }
      this.recalcTarget();
      onComplete();
      this.statusResetTimer = setTimeout(() => {
        if (requestId !== this.updateRequestId) {
          return;
        }
        if (this.updateStatus !== 'loading') {
          this.updateStatus = 'idle';
        }
        this.statusResetTimer = -1;
      }, AppConstants.STATUS_RESET_MS);
    });
  }

  private onUpdateTap(): void {
    this.startFetch(() => {});
  }

  @Builder
  private autoRefreshMenu() {
    Menu() {
      MenuItem({ content: $r('app.string.auto_refresh_off') })
        .selected(this.autoRefreshIntervalMin === 0)
        .onClick(() => { this.applyAutoRefresh(0); })
      MenuItem({ content: $r('app.string.auto_refresh_15') })
        .selected(this.autoRefreshIntervalMin === 15)
        .onClick(() => { this.applyAutoRefresh(15); })
      MenuItem({ content: $r('app.string.auto_refresh_30') })
        .selected(this.autoRefreshIntervalMin === 30)
        .onClick(() => { this.applyAutoRefresh(30); })
      MenuItem({ content: $r('app.string.auto_refresh_60') })
        .selected(this.autoRefreshIntervalMin === 60)
        .onClick(() => { this.applyAutoRefresh(60); })
    }
  }

  private onPullRefresh(): void {
    if (this.updateStatus === 'loading') {
      this.isRefreshing = false;
      return;
    }
    this.startFetch(() => {
      this.isRefreshing = false;
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
              .fontWeight(700)
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

        Refresh({ refreshing: $$this.isRefreshing }) {
          Scroll() {
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
                    .accessibilityText($r('app.string.a11y_swap'))
                    .onClick(() => {
                      this.toggleCurrency()
                    })

                }
            .width($r('app.string.w_100'))
            .alignSelf(ItemAlign.Center)
            .align(Alignment.Center)
            .height('33vp')

            Row() {
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
                .accessibilityText($r('app.string.a11y_update'))
                .onClick(() => {
                  this.onUpdateTap();
                })
                .bindContextMenu(this.autoRefreshMenu, ResponseType.LongPress)

              if (this.updatedAtText().length > 0) {
                Text(this.updatedAtText())
                  .fontSize(9)
                  .fontColor(this.updatedAtFontColor())
                  .opacity(0.8)
                  .margin({ left: 6 })
              }
            }
            .alignSelf(ItemAlign.Center)
            .margin({ top: 6, bottom: 6 })
          }

          BaseCurrencyRow({
            amount: this.baseAmount,
            onAmountChange: (value: string) => {
              this.baseAmount = value;
              this.recalcTarget();
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
              .fontColor($r('app.color.text_secondary'))
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
          }
          .scrollBar(BarState.Off)
          .width($r('app.string.w_100'))
        }
        .width($r('app.string.w_100'))
        .backgroundColor($r('app.color.exchange_panel_bg'))
        .layoutWeight(1)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .onRefreshing(() => {
          this.onPullRefresh();
        })

      }
      .width($r('app.string.w_100'))
      .height($r('app.string.w_100'))
      .backgroundColor($r('app.color.exchange_bg'))
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
    })
    .onDigitalCrown((event: CrownEvent) => {
      this.onCrownEvent(event.angularVelocity);
    })
  }
}
