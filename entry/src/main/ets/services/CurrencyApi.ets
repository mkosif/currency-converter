import { rcp } from '@kit.RemoteCommunicationKit';
import { connection } from '@kit.NetworkKit';
import { FrankfurterResponse } from '../viewmodel/CurrencyData';
import { AppConstants } from '../common/AppConstants';

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

export class CurrencyApi {
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

  static async isOnline(): Promise<boolean> {
    try {
      return await connection.hasDefaultNet();
    } catch (_err) {
      return true;
    }
  }
}
