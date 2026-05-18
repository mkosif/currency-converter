import { FormExtensionAbility, formBindingData, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { RatesCache, CachedState } from '../services/RatesCache';
import { CurrencyApi } from '../services/CurrencyApi';
import { AppConstants } from '../common/AppConstants';

const TAG = 'EntryFormAbility';
const FORM_ID_KEY = 'ohos.extra.param.key.form_identity';

class FormPayload {
  pair: string = 'USD → EUR';
  rate: string = '—';
  lastUpdated: string = '—';
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const params = want.parameters as Record<string, Object> | undefined;
    const formId = params ? params[FORM_ID_KEY] as string : '';
    if (formId && formId.length > 0) {
      this.refresh(formId, true);
    }
    const placeholder: FormPayload = new FormPayload();
    return formBindingData.createFormBindingData(placeholder);
  }

  onUpdateForm(formId: string): void {
    this.refresh(formId, true);
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(0, TAG, 'onFormEvent %{public}s msg=%{public}s', formId, message);
    this.refresh(formId, true);
  }

  onRemoveForm(formId: string): void {
    hilog.info(0, TAG, 'onRemoveForm %{public}s', formId);
  }

  private async refresh(formId: string, tryNetwork: boolean): Promise<void> {
    try {
      const cache = new RatesCache(this.context);
      let snapshot: CachedState | null = await cache.load();

      if (tryNetwork) {
        const live = await this.fetchLive();
        if (live) {
          snapshot = this.mergeLive(snapshot, live);
          await cache.save(snapshot);
        }
      }

      const payload = this.toPayload(snapshot);
      const data = formBindingData.createFormBindingData(payload);
      await formProvider.updateForm(formId, data);
    } catch (err) {
      hilog.warn(0, TAG, 'refresh failed: %{public}s', JSON.stringify(err));
    }
  }

  private mergeLive(prior: CachedState | null, live: CachedState): CachedState {
    if (!prior) {
      return live;
    }
    return {
      rates: live.rates,
      base: live.base,
      lastUpdatedAt: live.lastUpdatedAt,
      selectedBaseCode: prior.selectedBaseCode || live.selectedBaseCode,
      selectedTargetCode: prior.selectedTargetCode || live.selectedTargetCode,
      lastBaseAmount: prior.lastBaseAmount,
      recentCodes: prior.recentCodes,
      autoRefreshIntervalMin: prior.autoRefreshIntervalMin
    };
  }

  private async fetchLive(): Promise<CachedState | null> {
    const online = await CurrencyApi.isOnline();
    if (!online) {
      return null;
    }
    const parsed = await CurrencyApi.fetchLatest(AppConstants.DEFAULT_BASE_CODE);
    if (!parsed || parsed.base !== AppConstants.DEFAULT_BASE_CODE
      || !parsed.rates || typeof parsed.rates !== 'object') {
      return null;
    }
    const next: CachedState = {
      rates: parsed.rates,
      base: parsed.base,
      lastUpdatedAt: Date.now(),
      selectedBaseCode: AppConstants.DEFAULT_BASE_CODE,
      selectedTargetCode: AppConstants.DEFAULT_TARGET_CODE
    };
    return next;
  }

  private toPayload(snapshot: CachedState | null): FormPayload {
    const out: FormPayload = new FormPayload();
    if (!snapshot) {
      return out;
    }
    const baseCode: string = snapshot.selectedBaseCode || AppConstants.DEFAULT_BASE_CODE;
    const targetCode: string = snapshot.selectedTargetCode || AppConstants.DEFAULT_TARGET_CODE;
    const rates: Record<string, number> = snapshot.rates || {};
    const baseRate: number = baseCode === AppConstants.DEFAULT_BASE_CODE ? 1.0 : rates[baseCode];
    const targetRate: number = targetCode === AppConstants.DEFAULT_BASE_CODE ? 1.0 : rates[targetCode];
    if (typeof baseRate === 'number' && typeof targetRate === 'number'
      && baseRate > 0 && targetRate > 0) {
      const conv: number = targetRate / baseRate;
      const decimals: number = AppConstants.ZERO_DECIMAL_CODES.has(targetCode) ? 0 : 2;
      out.rate = conv.toFixed(decimals);
    }
    if (snapshot.lastUpdatedAt && snapshot.lastUpdatedAt > 0) {
      const d = new Date(snapshot.lastUpdatedAt);
      const hh: string = d.getHours().toString().padStart(2, '0');
      const mm: string = d.getMinutes().toString().padStart(2, '0');
      out.lastUpdated = `${hh}:${mm}`;
    }
    out.pair = `${baseCode} → ${targetCode}`;
    return out;
  }
}
