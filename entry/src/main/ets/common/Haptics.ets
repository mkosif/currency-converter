import { vibrator } from '@kit.SensorServiceKit';

export class Haptics {
  static tap(): void {
    Haptics.fire(20, 80);
  }

  static success(): void {
    Haptics.fire(35, 100);
  }

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
    }
  }
}
