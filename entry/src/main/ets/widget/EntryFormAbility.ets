import { FormExtensionAbility, formBindingData, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'EntryFormAbility';
const STORE_NAME = 'currency_state';
const STATE_KEY = 'currency_state_v1';
const FORM_ID_KEY = 'ohos.extra.param.key.form_identity';

class FormPayload {
  pair: string = 'USD → EUR';
  rate: string = '—';
  lastUpdated: string = '—';
}

interface CachedSnapshot {
  rates: Record<string, number>;
  selectedBaseCode: string;
  selectedTargetCode: string;
  lastUpdatedAt: number;
}

// Form ability that powers the home-screen rate tile. onAddForm must return
// synchronously, so it returns a placeholder and kicks off an async refresh
// via formProvider.updateForm once the cache has been read.
export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const params = want.parameters as Record<string, Object> | undefined;
    const formId = params ? params[FORM_ID_KEY] as string : '';
    if (formId && formId.length > 0) {
      this.refreshAsync(formId);
    }
    const placeholder: FormPayload = new FormPayload();
    return formBindingData.createFormBindingData(placeholder);
  }

  onUpdateForm(formId: string): void {
    this.refreshAsync(formId);
  }

  // Triggered by `postCardAction({action: 'message', ...})` from the widget
  // UI. Re-reads the cache and pushes the latest payload back to the widget.
  onFormEvent(formId: string, message: string): void {
    hilog.info(0, TAG, 'onFormEvent %{public}s msg=%{public}s', formId, message);
    this.refreshAsync(formId);
  }

  onRemoveForm(formId: string): void {
    hilog.info(0, TAG, 'onRemoveForm %{public}s', formId);
  }

  private async refreshAsync(formId: string): Promise<void> {
    try {
      const snapshot = await this.readSnapshot();
      const payload = this.toPayload(snapshot);
      const data = formBindingData.createFormBindingData(payload);
      await formProvider.updateForm(formId, data);
    } catch (err) {
      hilog.warn(0, TAG, 'refreshAsync failed: %{public}s', JSON.stringify(err));
    }
  }

  private async readSnapshot(): Promise<CachedSnapshot | null> {
    try {
      const pref = await preferences.getPreferences(this.context, STORE_NAME);
      const raw = await pref.get(STATE_KEY, '') as string;
      if (!raw || raw.length === 0) {
        return null;
      }
      return JSON.parse(raw) as CachedSnapshot;
    } catch (_err) {
      return null;
    }
  }

  private toPayload(snapshot: CachedSnapshot | null): FormPayload {
    const out: FormPayload = new FormPayload();
    if (!snapshot) {
      return out;
    }
    const baseCode: string = snapshot.selectedBaseCode || 'USD';
    const targetCode: string = snapshot.selectedTargetCode || 'EUR';
    const rates: Record<string, number> = snapshot.rates || {};
    const baseRate: number = baseCode === 'USD' ? 1.0 : rates[baseCode];
    const targetRate: number = targetCode === 'USD' ? 1.0 : rates[targetCode];
    if (typeof baseRate === 'number' && typeof targetRate === 'number'
      && baseRate > 0 && targetRate > 0) {
      const conv: number = targetRate / baseRate;
      const decimals: number = (targetCode === 'JPY' || targetCode === 'KRW') ? 0 : 2;
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
