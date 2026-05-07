import { CurrencyData } from '../viewmodel/CurrencyData';
import { CurrencyViewModel } from '../viewmodel/CurrencyViewModel';
import { ExchangePage } from './ExchangePage';
import { SelectCurrencyPage } from './SelectCurrencyPage';
import { SplashPage } from './SplashPage';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct NavigationRouter {
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @Provide viewModel: CurrencyViewModel = new CurrencyViewModel();
  @Provide allCurrencyData: CurrencyData[] = this.viewModel.initCurrencyData()
  @Provide selectedBaseCurrency: CurrencyData = this.viewModel.selectedBaseCurrency
  @Provide selectedTargetCurrency: CurrencyData = this.viewModel.selectedTargetCurrency
  @Provide baseAmount: string = '1.00';
  @Provide targetAmount: string = '';
  @Provide triggerMechanism: number = 1;
  // Mirror of viewModel.lastUpdatedAt, surfaced as a Provide slot so the
  // ExchangePage chip can react when cache load or a fetch completes.
  @Provide lastUpdatedAt: number = 0;

  aboutToAppear() {
    this.init();
    this.bootstrapViewModel();
  }

  init() {
    this.selectedBaseCurrency = this.viewModel.selectedBaseCurrency;
    this.selectedTargetCurrency = this.viewModel.selectedTargetCurrency;
    this.targetAmount = this.viewModel.calculateConversion(this.baseAmount);
    this.pageInfos.pushPathByName('SplashPage', null);
  }

  // Async cache + initial fetch. Updates @Provide slots once persisted
  // selection and rates are restored.
  private async bootstrapViewModel(): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await this.viewModel.init(ctx);
    } catch (err) {
      console.info('NavigationRouter: viewModel init failed.');
    }
    this.selectedBaseCurrency = this.viewModel.selectedBaseCurrency;
    this.selectedTargetCurrency = this.viewModel.selectedTargetCurrency;
    this.lastUpdatedAt = this.viewModel.lastUpdatedAt;
    if (this.viewModel.restoredBaseAmount.length > 0) {
      this.baseAmount = this.viewModel.restoredBaseAmount;
    }
    this.targetAmount = this.viewModel.calculateConversion(this.baseAmount);
    this.triggerMechanism++;
  }

  @Builder
  routerMap(builderName: string, param: object) {
    if (builderName === 'SplashPage') {
      SplashPage()
    } else if (builderName === 'ExchangePage') {
      ExchangePage()
    } else if (builderName === 'SelectCurrencyPage') {
      SelectCurrencyPage()
    }
  }

  build() {
    Navigation(this.pageInfos) {
    }
    .mode(NavigationMode.Stack)
    .navDestination(this.routerMap)
  }
}
