const API_SCHEME: string = 'https';
const API_HOST: string = 'api.frankfurter.app';

export class AppConstants {
  static readonly API_BASE_URL: string = `${API_SCHEME}://${API_HOST}`;

  static readonly SPLASH_DURATION_MS: number = 2000;

  static readonly STATUS_RESET_MS: number = 5000;

  static readonly NETWORK_TIMEOUT_MS: number = 8000;

  static readonly MAX_AMOUNT_INPUT_LENGTH: number = 12;

  static readonly DEFAULT_BASE_CODE: string = 'USD';
  static readonly DEFAULT_TARGET_CODE: string = 'EUR';

  static readonly ZERO_DECIMAL_CODES: ReadonlySet<string> = new Set<string>(['JPY', 'KRW']);

  static readonly RECENT_MAX: number = 3;

  static readonly EMPTY_TARGET_PLACEHOLDER: string = '—';

  static readonly AUTO_REFRESH_OPTIONS_MIN: ReadonlyArray<number> = [0, 15, 30, 60];

  static readonly CROWN_AMOUNT_STEP: number = 1;

  static readonly STALE_THRESHOLD_MS: number = 60 * 60 * 1000;
}
