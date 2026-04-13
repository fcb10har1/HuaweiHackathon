/**
 * LocationService.ets
 * Polls GPS every N milliseconds and invokes a callback with (lat, lng).
 * Call startPolling() on page show and stopPolling() on page hide.
 */
import geoLocationManager from '@ohos.geoLocationManager';

export type LocationCallback = (lat: number, lng: number) => void;

export class LocationService {
  private intervalId: number = -1;
  private callback: LocationCallback | null = null;

  startPolling(callback: LocationCallback, intervalMs: number): void {
    this.callback = callback;
    // Trigger once immediately, then on interval
    this.pollOnce();
    this.intervalId = setInterval(() => {
      this.pollOnce();
    }, intervalMs);
  }

  stopPolling(): void {
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
      this.intervalId = -1;
    }
    this.callback = null;
  }

  private pollOnce(): void {
    geoLocationManager.getCurrentLocation({
      priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
      scenario: geoLocationManager.LocationRequestScenario.UNSET,
      timeoutMs: 10000,
      maxAccuracy: 500,
    }).then((location) => {
      if (this.callback) {
        this.callback(location.latitude, location.longitude);
      }
    }).catch((e: Error) => {
      console.warn('[LocationService] GPS poll failed:', e.message);
    });
  }
}
