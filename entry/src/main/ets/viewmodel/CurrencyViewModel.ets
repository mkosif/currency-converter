import { CurrencyData, FrankfurterResponse } from './CurrencyData';
import { common } from '@kit.AbilityKit';
import { RatesCache, CachedState } from '../services/RatesCache';
import { CurrencyApi } from '../services/CurrencyApi';
import { AppConstants } from '../common/AppConstants';

export type FetchResult = 'ok' | 'offline' | 'error';

@Observed
export class CurrencyViewModel {
  private allCurrencyData: CurrencyData[] = [];
  private cache: RatesCache | null = null;
  lastUpdatedAt: number = 0;
  restoredBaseAmount: string = '';
  recentCodes: string[] = [];
  autoRefreshIntervalMin: number = 0;

  constructor() {
    this.allCurrencyData = this.initCurrencyData();
    this._selectedBaseCurrency = this.allCurrencyData[0];
    this._selectedTargetCurrency = this.allCurrencyData[1];
  }

  private _selectedBaseCurrency: CurrencyData;

  get selectedBaseCurrency(): CurrencyData {
    return this._selectedBaseCurrency;
  }

  set selectedBaseCurrency(currency: CurrencyData) {
    this._selectedBaseCurrency = currency;
  }

  private _selectedTargetCurrency: CurrencyData;

  get selectedTargetCurrency(): CurrencyData {
    return this._selectedTargetCurrency;
  }

  set selectedTargetCurrency(currency: CurrencyData) {
    this._selectedTargetCurrency = currency;
  }

  public initCurrencyData(): CurrencyData[] {
    return [
      new CurrencyData('USD', 'US Dollar', $r('app.media.flag_usd'), '$', 1.0),
      new CurrencyData('EUR', 'Euro', $r('app.media.flag_eur'), '€', 0.92),
      new CurrencyData('GBP', 'British Pound', $r('app.media.flag_gbp'), '£', 0.77),
      new CurrencyData('JPY', 'Japanese Yen', $r('app.media.flag_jpy'), '¥', 151.23),
      new CurrencyData('TRY', 'Turkish Lira', $r('app.media.flag_try'), '₺', 32.45),
      new CurrencyData('CAD', 'Canadian Dollar', $r('app.media.flag_cad'), 'C$', 1.34),
      new CurrencyData('CHF', 'Swiss Franc', $r('app.media.flag_chf'), 'CHF', 0.90),
      new CurrencyData('CNY', 'Chinese Yuan', $r('app.media.flag_cny'), '¥', 7.18),
      new CurrencyData('INR', 'Indian Rupee', $r('app.media.flag_inr'), '₹', 82.96),
      new CurrencyData('BRL', 'Brazilian Real', $r('app.media.flag_brl'), 'R$', 5.04),
      new CurrencyData('MXN', 'Mexican Peso', $r('app.media.flag_mxn'), '$', 17.27),
      new CurrencyData('ZAR', 'South African Rand', $r('app.media.flag_zar'), 'R', 18.56),
      new CurrencyData('KRW', 'South Korean Won', $r('app.media.flag_krw'), '₩', 1310.50),
      new CurrencyData('RUB', 'Russian Ruble', $r('app.media.flag_rub'), '₽', 92.76)
    ];
  }

  getCurrencyData(): CurrencyData[] {
    return this.allCurrencyData;
  }

  searchCurrency(query: string): CurrencyData[] {
    if (!query || query.trim() === '') {
      return this.allCurrencyData;
    }
    const q = query.toLowerCase().trim();
    return this.allCurrencyData.filter(c =>
      c.name.toLowerCase().includes(q) || c.code.toLowerCase().includes(q)
    );
  }

  getCurrencyByCode(code: string): CurrencyData | undefined {
    return this.allCurrencyData.find(c => c.code === code);
  }

  static isValidAmount(amount: string): boolean {
    if (!amount) {
      return false;
    }
    if (!/^\d+(\.\d+)?$/.test(amount.trim())) {
      return false;
    }
    const n = parseFloat(amount);
    return Number.isFinite(n) && n >= 0;
  }

  static decimalsForCurrency(code: string): number {
    return AppConstants.ZERO_DECIMAL_CODES.has(code) ? 0 : 2;
  }

  static formatAmount(value: number, minDecimals: number = 2): string {
    if (!Number.isFinite(value)) {
      return minDecimals > 0 ? `0.${'0'.repeat(minDecimals)}` : '0';
    }
    if (minDecimals <= 0) {
      return Math.round(value).toString();
    }
    const fixed = value.toFixed(4);
    const trimmed = fixed.replace(/0+$/, '').replace(/\.$/, '');
    const dot = trimmed.indexOf('.');
    if (dot === -1) {
      return `${trimmed}.${'0'.repeat(minDecimals)}`;
    }
    const decimals = trimmed.length - dot - 1;
    if (decimals < minDecimals) {
      return `${trimmed}${'0'.repeat(minDecimals - decimals)}`;
    }
    return trimmed;
  }

  calculateConversion(amount: string): string {
    const target = this._selectedTargetCurrency;
    const targetDecimals = target
      ? CurrencyViewModel.decimalsForCurrency(target.code)
      : 2;
    if (!CurrencyViewModel.isValidAmount(amount)) {
      return CurrencyViewModel.formatAmount(0, targetDecimals);
    }
    const base = this._selectedBaseCurrency;
    if (!base || !target || base.rate <= 0) {
      return CurrencyViewModel.formatAmount(0, targetDecimals);
    }
    const rate = target.rate / base.rate;
    return CurrencyViewModel.formatAmount(parseFloat(amount) * rate, targetDecimals);
  }

  applyRates(response: FrankfurterResponse | null | undefined): boolean {
    if (!response || !response.rates || typeof response.rates !== 'object') {
      return false;
    }
    if (response.base !== 'USD') {
      return false;
    }
    const baseCode: string = response.base;
    let updated = 0;
    this.allCurrencyData.forEach((currency) => {
      if (currency.code === baseCode) {
        currency.rate = 1.0;
        updated++;
        return;
      }
      const r = response.rates[currency.code];
      if (typeof r === 'number' && Number.isFinite(r) && r > 0) {
        currency.rate = r;
        updated++;
      }
    });
    return updated > 0;
  }

  async init(context: common.Context): Promise<void> {
    this.cache = new RatesCache(context);
    const state = await this.cache.load();
    if (state) {
      if (state.rates && Object.keys(state.rates).length > 0) {
        this.applyRates({
          amount: 1,
          base: state.base || 'USD',
          date: '',
          rates: state.rates
        });
        this.lastUpdatedAt = state.lastUpdatedAt || 0;
      }
      const persistedBase = state.selectedBaseCode
        ? this.getCurrencyByCode(state.selectedBaseCode)
        : undefined;
      const persistedTarget = state.selectedTargetCode
        ? this.getCurrencyByCode(state.selectedTargetCode)
        : undefined;
      if (persistedBase) {
        this._selectedBaseCurrency = persistedBase;
      }
      if (persistedTarget) {
        this._selectedTargetCurrency = persistedTarget;
      }
      if (state.lastBaseAmount && CurrencyViewModel.isValidAmount(state.lastBaseAmount)) {
        this.restoredBaseAmount = state.lastBaseAmount;
      }
      if (state.recentCodes && Array.isArray(state.recentCodes)) {
        this.recentCodes = state.recentCodes
          .filter(c => this.getCurrencyByCode(c) !== undefined)
          .slice(0, AppConstants.RECENT_MAX);
      }
      if (typeof state.autoRefreshIntervalMin === 'number' &&
        AppConstants.AUTO_REFRESH_OPTIONS_MIN.includes(state.autoRefreshIntervalMin)) {
        this.autoRefreshIntervalMin = state.autoRefreshIntervalMin;
      }
    }
    this.fetchAndUpdateRates();
  }

  async persistSelection(): Promise<void> {
    if (!this.cache) {
      return;
    }
    await this.cache.patchSelection(
      this._selectedBaseCurrency.code,
      this._selectedTargetCurrency.code
    );
  }

  async persistAmount(amount: string): Promise<void> {
    if (!this.cache) {
      return;
    }
    if (!CurrencyViewModel.isValidAmount(amount)) {
      return;
    }
    await this.cache.patchAmount(amount);
  }

  setAutoRefreshIntervalMin(min: number): void {
    if (!AppConstants.AUTO_REFRESH_OPTIONS_MIN.includes(min)) {
      return;
    }
    this.autoRefreshIntervalMin = min;
    if (this.cache) {
      this.cache.patchAutoRefresh(min);
    }
  }

  pushRecent(code: string): void {
    if (!code || !this.getCurrencyByCode(code)) {
      return;
    }
    const next = [code].concat(this.recentCodes.filter(c => c !== code));
    this.recentCodes = next.slice(0, AppConstants.RECENT_MAX);
    if (this.cache) {
      this.cache.patchRecents(this.recentCodes);
    }
  }

  async fetchAndUpdateRates(): Promise<FetchResult> {
    const online = await CurrencyApi.isOnline();
    if (!online) {
      return 'offline';
    }
    const parsed = await CurrencyApi.fetchLatest(AppConstants.DEFAULT_BASE_CODE);
    if (!parsed) {
      return 'error';
    }
    const ok = this.applyRates(parsed);
    if (!ok) {
      return 'error';
    }
    this.lastUpdatedAt = Date.now();
    if (this.cache) {
      const snapshot: CachedState = {
        rates: parsed.rates,
        base: parsed.base,
        lastUpdatedAt: this.lastUpdatedAt,
        selectedBaseCode: this._selectedBaseCurrency.code,
        selectedTargetCode: this._selectedTargetCurrency.code
      };
      this.cache.save(snapshot);
    }
    return 'ok';
  }
}
