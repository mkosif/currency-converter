import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME = 'currency_state';
const STATE_KEY = 'currency_state_v1';

export interface CachedState {
  rates: Record<string, number>;
  base: string;
  lastUpdatedAt: number;
  selectedBaseCode: string;
  selectedTargetCode: string;
  lastBaseAmount?: string;
  recentCodes?: string[];
  autoRefreshIntervalMin?: number;
}

export class RatesCache {
  private readonly context: common.Context;
  private prefPromise: Promise<preferences.Preferences>;

  constructor(context: common.Context) {
    this.context = context;
    this.prefPromise = preferences.getPreferences(context, STORE_NAME);
  }

  async load(): Promise<CachedState | null> {
    try {
      const pref = await this.prefPromise;
      const raw = await pref.get(STATE_KEY, '') as string;
      if (!raw || raw.length === 0) {
        return null;
      }
      const parsed = JSON.parse(raw) as CachedState;
      if (!parsed || typeof parsed !== 'object') {
        return null;
      }
      return parsed;
    } catch (err) {
      console.info('RatesCache: load failed; returning null.');
      return null;
    }
  }

  async save(state: CachedState): Promise<void> {
    try {
      const pref = await this.prefPromise;
      await pref.put(STATE_KEY, JSON.stringify(state));
      await pref.flush();
    } catch (err) {
      console.info('RatesCache: save failed.');
    }
  }

  async patchSelection(baseCode: string, targetCode: string): Promise<void> {
    const cur = await this.load();
    if (cur) {
      cur.selectedBaseCode = baseCode;
      cur.selectedTargetCode = targetCode;
      await this.save(cur);
      return;
    }
    await this.save({
      rates: {},
      base: 'USD',
      lastUpdatedAt: 0,
      selectedBaseCode: baseCode,
      selectedTargetCode: targetCode
    });
  }

  async patchAmount(amount: string): Promise<void> {
    const cur = await this.load();
    if (cur) {
      cur.lastBaseAmount = amount;
      await this.save(cur);
      return;
    }
    await this.save({
      rates: {},
      base: 'USD',
      lastUpdatedAt: 0,
      selectedBaseCode: 'USD',
      selectedTargetCode: 'EUR',
      lastBaseAmount: amount
    });
  }

  async patchAutoRefresh(intervalMin: number): Promise<void> {
    const cur = await this.load();
    if (cur) {
      cur.autoRefreshIntervalMin = intervalMin;
      await this.save(cur);
      return;
    }
    await this.save({
      rates: {},
      base: 'USD',
      lastUpdatedAt: 0,
      selectedBaseCode: 'USD',
      selectedTargetCode: 'EUR',
      autoRefreshIntervalMin: intervalMin
    });
  }

  async patchRecents(codes: string[]): Promise<void> {
    const cur = await this.load();
    if (cur) {
      cur.recentCodes = codes;
      await this.save(cur);
      return;
    }
    await this.save({
      rates: {},
      base: 'USD',
      lastUpdatedAt: 0,
      selectedBaseCode: 'USD',
      selectedTargetCode: 'EUR',
      recentCodes: codes
    });
  }
}
