import { CurrencyData, FrankfurterResponse } from './CurrencyData';
import { rcp } from '@kit.RemoteCommunicationKit';

const API_BASE_URL = `https://` + $r('app.string.core_url');
const session = rcp.createSession();

@Observed
export class CurrencyViewModel {
  private allCurrencyData: CurrencyData[] = [];

  constructor() {
    this.allCurrencyData = this.initCurrencyData();
    this._selectedBaseCurrency = this.allCurrencyData[0]; // USD
    this._selectedTargetCurrency = this.allCurrencyData[1]; // EUR
    this.fetchAndUpdateRates();
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

  // Positive decimal numbers only; rejects empty / NaN / negative / Infinity.
  static isValidAmount(amount: string): boolean {
    if (!amount) return false;
    if (!/^\d+(\.\d+)?$/.test(amount.trim())) return false;
    const n = parseFloat(amount);
    return Number.isFinite(n) && n >= 0;
  }

  // Up to 4 decimals, trim trailing zeros, but always show at least 2.
  static formatAmount(value: number): string {
    if (!Number.isFinite(value)) return '0.00';
    const fixed = value.toFixed(4);
    const trimmed = fixed.replace(/0+$/, '').replace(/\.$/, '');
    const dot = trimmed.indexOf('.');
    if (dot === -1) return trimmed + '.00';
    const decimals = trimmed.length - dot - 1;
    if (decimals < 2) return trimmed + '0'.repeat(2 - decimals);
    return trimmed;
  }

  calculateConversion(amount: string): string {
    if (!CurrencyViewModel.isValidAmount(amount)) return '0.00';
    const base = this._selectedBaseCurrency;
    const target = this._selectedTargetCurrency;
    if (!base || !target || base.rate <= 0) return '0.00';
    const rate = target.rate / base.rate;
    return CurrencyViewModel.formatAmount(parseFloat(amount) * rate);
  }

  // Validate a Frankfurter payload and merge rates into `allCurrencyData`.
  // Currencies missing from the response keep their previous (fallback) rate,
  // so a malformed/partial response can never zero them out.
  // Returns true if at least one rate was applied.
  applyRates(response: FrankfurterResponse | null | undefined): boolean {
    if (!response || !response.rates || typeof response.rates !== 'object') return false;
    // We always request `from=USD`; reject any payload claiming a different base
    // so a malformed/swapped response can't silently rewrite rates.
    if (response.base !== 'USD') return false;
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

  async fetchAndUpdateRates(): Promise<boolean> {
    const baseCode = 'USD';
    const url = `${API_BASE_URL}/latest?from=${baseCode}`;
    const request = new rcp.Request(url, 'GET');
    try {
      const response = await session.fetch(request);
      const parsed = response.toJSON() as FrankfurterResponse;
      return this.applyRates(parsed);
    } catch (err) {
      console.info('CurrencyViewModel: rate fetch failed; keeping previous rates.');
      return false;
    }
  }
}
