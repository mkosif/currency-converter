import { vibrator } from '@kit.SensorServiceKit';

// Best-effort haptic feedback. All errors swallowed — UI must never fail
// because the device has no vibrator or permission was denied.
export class Haptics {
  // Short tick for taps / selection / non-critical confirmations.
  static tap(): void {
    Haptics.fire(20, 80);
  }

  // Slightly longer pulse for successful network update or pull refresh.
  static success(): void {
    Haptics.fire(35, 100);
  }

  // Two short pulses for errors / offline.
  static error(): void {
    Haptics.fire(25, 80);
    setTimeout(() => Haptics.fire(25, 80), 90);
  }

  private static fire(durationMs: number, intensity: number): void {
    try {
      vibrator.startVibration(
        { type: 'time', duration: durationMs },
        { usage: 'notification' }
      ).catch((_err: Object) => {});
    } catch (_err) {
      // Hardware/permission unavailable — silently no-op.
    }
  }
}
