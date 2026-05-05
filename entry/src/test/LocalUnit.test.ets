import { beforeAll, describe, expect, it } from '@ohos/hypium';
import { CurrencyViewModel } from '../main/ets/viewmodel/CurrencyViewModel';
import { FrankfurterResponse } from '../main/ets/viewmodel/CurrencyData';

export default function localUnitTest() {
  describe('CurrencyViewModel', () => {

    describe('isValidAmount', () => {
      it('accepts valid positive numbers and zero', 0, () => {
        expect(CurrencyViewModel.isValidAmount('1')).assertTrue();
        expect(CurrencyViewModel.isValidAmount('1.50')).assertTrue();
        expect(CurrencyViewModel.isValidAmount('0')).assertTrue();
        expect(CurrencyViewModel.isValidAmount('1234567')).assertTrue();
      });
      it('rejects empty input', 0, () => {
        expect(CurrencyViewModel.isValidAmount('')).assertFalse();
      });
      it('rejects negative numbers', 0, () => {
        expect(CurrencyViewModel.isValidAmount('-1')).assertFalse();
        expect(CurrencyViewModel.isValidAmount('-0.5')).assertFalse();
      });
      it('rejects non-numeric and malformed strings', 0, () => {
        expect(CurrencyViewModel.isValidAmount('abc')).assertFalse();
        expect(CurrencyViewModel.isValidAmount('1.2.3')).assertFalse();
        expect(CurrencyViewModel.isValidAmount('Infinity')).assertFalse();
        expect(CurrencyViewModel.isValidAmount('NaN')).assertFalse();
        expect(CurrencyViewModel.isValidAmount('1e10')).assertFalse();
        expect(CurrencyViewModel.isValidAmount('  ')).assertFalse();
      });
    });

    describe('formatAmount', () => {
      it('pads short results to two decimals', 0, () => {
        expect(CurrencyViewModel.formatAmount(1)).assertEqual('1.00');
        expect(CurrencyViewModel.formatAmount(92.5)).assertEqual('92.50');
      });
      it('trims trailing zeros past two decimals', 0, () => {
        expect(CurrencyViewModel.formatAmount(1.234)).assertEqual('1.234');
        expect(CurrencyViewModel.formatAmount(1.2345)).assertEqual('1.2345');
      });
      it('rounds beyond four decimals', 0, () => {
        expect(CurrencyViewModel.formatAmount(1.23456)).assertEqual('1.2346');
      });
      it('returns 0.00 for non-finite values', 0, () => {
        expect(CurrencyViewModel.formatAmount(Number.NaN)).assertEqual('0.00');
        expect(CurrencyViewModel.formatAmount(Number.POSITIVE_INFINITY)).assertEqual('0.00');
      });
    });

    describe('searchCurrency', () => {
      let vm: CurrencyViewModel;
      beforeAll(() => { vm = new CurrencyViewModel(); });

      it('returns full list for empty or whitespace query', 0, () => {
        expect(vm.searchCurrency('').length).assertEqual(14);
        expect(vm.searchCurrency('   ').length).assertEqual(14);
      });
      it('matches by code case-insensitively', 0, () => {
        const r = vm.searchCurrency('eur');
        expect(r.length).assertEqual(1);
        expect(r[0].code).assertEqual('EUR');
      });
      it('matches by name case-insensitively', 0, () => {
        const r = vm.searchCurrency('YEN');
        expect(r.length).assertEqual(1);
        expect(r[0].code).assertEqual('JPY');
      });
      it('returns empty when nothing matches', 0, () => {
        expect(vm.searchCurrency('xyz').length).assertEqual(0);
      });
    });

    describe('getCurrencyByCode', () => {
      let vm: CurrencyViewModel;
      beforeAll(() => { vm = new CurrencyViewModel(); });

      it('finds a known code', 0, () => {
        const c = vm.getCurrencyByCode('USD');
        expect(c === undefined).assertFalse();
        if (c) expect(c.name).assertEqual('US Dollar');
      });
      it('returns undefined for an unknown code', 0, () => {
        expect(vm.getCurrencyByCode('XYZ') === undefined).assertTrue();
      });
    });

    describe('applyRates', () => {
      it('applies a well-formed Frankfurter response', 0, () => {
        const vm = new CurrencyViewModel();
        const rates: Record<string, number> = { EUR: 0.95, GBP: 0.80, TRY: 33.0 };
        const payload: FrankfurterResponse = {
          amount: 1, base: 'USD', date: '2026-05-01', rates
        };
        expect(vm.applyRates(payload)).assertTrue();
        const usd = vm.getCurrencyByCode('USD');
        const eur = vm.getCurrencyByCode('EUR');
        const tryC = vm.getCurrencyByCode('TRY');
        if (usd) expect(usd.rate).assertEqual(1.0);
        if (eur) expect(eur.rate).assertEqual(0.95);
        if (tryC) expect(tryC.rate).assertEqual(33.0);
      });
      it('keeps fallback rates for currencies missing from the response', 0, () => {
        const vm = new CurrencyViewModel();
        const jpy = vm.getCurrencyByCode('JPY');
        const fallbackJpy = jpy ? jpy.rate : 0;
        const rates: Record<string, number> = { EUR: 0.95 };
        const payload: FrankfurterResponse = {
          amount: 1, base: 'USD', date: '2026-05-01', rates
        };
        vm.applyRates(payload);
        const jpyAfter = vm.getCurrencyByCode('JPY');
        if (jpyAfter) expect(jpyAfter.rate).assertEqual(fallbackJpy);
      });
      it('rejects payload with non-USD base and preserves rates', 0, () => {
        const vm = new CurrencyViewModel();
        const eur = vm.getCurrencyByCode('EUR');
        const fallbackEur = eur ? eur.rate : 0;
        const rates: Record<string, number> = { USD: 1.05 };
        const payload: FrankfurterResponse = {
          amount: 1, base: 'EUR', date: '2026-05-01', rates
        };
        expect(vm.applyRates(payload)).assertFalse();
        const eurAfter = vm.getCurrencyByCode('EUR');
        if (eurAfter) expect(eurAfter.rate).assertEqual(fallbackEur);
      });
      it('rejects null payload', 0, () => {
        const vm = new CurrencyViewModel();
        expect(vm.applyRates(null)).assertFalse();
      });
      it('skips non-positive or non-numeric rate entries', 0, () => {
        const vm = new CurrencyViewModel();
        const eur = vm.getCurrencyByCode('EUR');
        const fallbackEur = eur ? eur.rate : 0;
        const rates: Record<string, number> = { EUR: -1, GBP: 0.81 };
        const payload: FrankfurterResponse = {
          amount: 1, base: 'USD', date: '2026-05-01', rates
        };
        vm.applyRates(payload);
        const eurAfter = vm.getCurrencyByCode('EUR');
        const gbpAfter = vm.getCurrencyByCode('GBP');
        if (eurAfter) expect(eurAfter.rate).assertEqual(fallbackEur);
        if (gbpAfter) expect(gbpAfter.rate).assertEqual(0.81);
      });
    });
  });
}
