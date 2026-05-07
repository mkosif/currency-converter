import { rcp } from '@kit.RemoteCommunicationKit';
import { connection } from '@kit.NetworkKit';
import { FrankfurterResponse } from '../viewmodel/CurrencyData';
import { AppConstants } from '../common/AppConstants';

// Single dedicated session with hard timeouts. Module-scope so the underlying
// connection pool is shared across callers (ViewModel + FormAbility).
const session: rcp.Session = rcp.createSession({
  requestConfiguration: {
    transfer: {
      timeout: {
        connectMs: AppConstants.NETWORK_TIMEOUT_MS,
        transferMs: AppConstants.NETWORK_TIMEOUT_MS
      }
    }
  }
});

// Network IO for the Frankfurter rate API. Pure data layer — does not touch
// caches, ViewModel state, or UI. All errors swallowed and surfaced as
// `null` / `false` so callers can branch on success.
export class CurrencyApi {
  // Fetches `/latest?from=<baseCode>` and returns the parsed payload.
  // Returns null on network error, malformed JSON, or non-200 response.
  static async fetchLatest(baseCode: string): Promise<FrankfurterResponse | null> {
    const url = `${AppConstants.API_BASE_URL}/latest?from=${baseCode}`;
    try {
      const request = new rcp.Request(url, 'GET');
      const response = await session.fetch(request);
      return response.toJSON() as FrankfurterResponse;
    } catch (_err) {
      return null;
    }
  }

  // Wraps `connection.hasDefaultNet()` with a permissive fallback: if the
  // connectivity API itself fails, we optimistically attempt the fetch — the
  // request-level timeout will catch real hangs.
  static async isOnline(): Promise<boolean> {
    try {
      return await connection.hasDefaultNet();
    } catch (_err) {
      return true;
    }
  }
}
