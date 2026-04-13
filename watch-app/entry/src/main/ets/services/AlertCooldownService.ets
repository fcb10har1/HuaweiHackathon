/**
 * AlertCooldownService.ets
 * Tracks per-location-type alert cooldowns (1 hour) to prevent notification spam.
 * In-memory only — resets when the app restarts.
 */
import { ALERT_COOLDOWN_MS } from '../common/Config';

export class AlertCooldownService {
  private lastAlertTime: Map<string, number> = new Map();

  private key(countryCode: string, locationType: string): string {
    return `${countryCode.toLowerCase()}_${locationType.toLowerCase()}`;
  }

  canAlert(countryCode: string, locationType: string): boolean {
    const k = this.key(countryCode, locationType);
    const last = this.lastAlertTime.get(k) ?? 0;
    return (Date.now() - last) > ALERT_COOLDOWN_MS;
  }

  markAlerted(countryCode: string, locationType: string): void {
    const k = this.key(countryCode, locationType);
    this.lastAlertTime.set(k, Date.now());
  }

  reset(): void {
    this.lastAlertTime.clear();
  }
}
