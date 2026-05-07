// Single source of truth for app-wide tuning constants. Centralised here so
// network endpoints, timing, and default values are easy to scan and change.
export class AppConstants {
  static readonly API_BASE_URL: string = 'https://api.frankfurter.app';

  // Splash auto-advance — user can also tap to skip.
  static readonly SPLASH_DURATION_MS: number = 2000;

  // After a successful/failed/offline update the chip resets to 'idle' after this.
  static readonly STATUS_RESET_MS: number = 5000;

  // RCP socket timeouts; an unreachable host should not hang the chip.
  static readonly NETWORK_TIMEOUT_MS: number = 8000;

  // Hard cap on the amount input field — keeps the row from layout-overflow.
  static readonly MAX_AMOUNT_INPUT_LENGTH: number = 12;

  static readonly DEFAULT_BASE_CODE: string = 'USD';
  static readonly DEFAULT_TARGET_CODE: string = 'EUR';

  // Currencies whose smallest unit is 1 — render integer, no decimals.
  static readonly ZERO_DECIMAL_CODES: ReadonlySet<string> = new Set<string>(['JPY', 'KRW']);

  // How many "recently selected" currencies to keep in the cache.
  static readonly RECENT_MAX: number = 3;

  // Empty/invalid input placeholder shown in the target row.
  static readonly EMPTY_TARGET_PLACEHOLDER: string = '—';

  // Selectable auto-refresh intervals (minutes). 0 = off.
  static readonly AUTO_REFRESH_OPTIONS_MIN: ReadonlyArray<number> = [0, 15, 30, 60];

  // Crown rotation step on baseAmount. Watch crown emits one event per detent.
  static readonly CROWN_AMOUNT_STEP: number = 1;

  // After this many ms since lastUpdatedAt, the timestamp UI gets a warning
  // tint and the widget shows a stale indicator.
  static readonly STALE_THRESHOLD_MS: number = 60 * 60 * 1000;
}
