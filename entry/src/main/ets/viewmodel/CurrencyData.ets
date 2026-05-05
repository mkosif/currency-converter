export class CurrencyData {
  code: string = '';
  name: string = '';
  flag: Resource;
  symbol: string = '';
  rate: number = 1.0;
  isSelected = false;

  constructor(code: string, name: string, flag: Resource, symbol: string, rate: number = 1.0, isSelected = false) {
    this.code = code;
    this.name = name;
    this.flag = flag;
    this.symbol = symbol;
    this.rate = rate;
    this.isSelected = isSelected
  }
}

// Frankfurter returns `rates` as an object keyed by ISO currency code.
export interface FrankfurterResponse {
  amount: number;
  base: string;
  date: string;
  rates: Record<string, number>;
}
