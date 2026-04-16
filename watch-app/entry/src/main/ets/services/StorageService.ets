/**
 * StorageService.ets
 * Persists trips to device preferences storage.
 */
import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { Trip, ContextAlert } from '../common/Types';

const PREFS_NAME = 'arrivalritual_prefs';
const TRIPS_KEY  = 'trips';

export class StorageService {
  private context: common.UIAbilityContext;

  constructor(ctx: common.UIAbilityContext) {
    this.context = ctx;
  }

  private async getStore(): Promise<dataPreferences.Preferences> {
    return dataPreferences.getPreferences(this.context, PREFS_NAME);
  }

  async loadTrips(): Promise<Trip[]> {
    try {
      const prefs = await this.getStore();
      const raw = await prefs.get(TRIPS_KEY, '[]') as string;
      return JSON.parse(raw) as Trip[];
    } catch (_) {
      return [];
    }
  }

  async saveTrips(trips: Trip[]): Promise<void> {
    try {
      const prefs = await this.getStore();
      await prefs.put(TRIPS_KEY, JSON.stringify(trips));
      await prefs.flush();
    } catch (e) {
      console.error('[StorageService] saveTrips failed:', JSON.stringify(e));
    }
  }

  async addTrip(trip: Trip): Promise<Trip[]> {
    const trips = await this.loadTrips();
    trips.push(trip);
    await this.saveTrips(trips);
    return trips;
  }

  async deleteTrip(tripId: string): Promise<Trip[]> {
    const trips = await this.loadTrips();
    const updated = trips.filter(t => t.id !== tripId);
    await this.saveTrips(updated);
    return updated;
  }

  // ── Triggered alerts (SENSITIVE / LEGAL dismissed by user) ───────────────────

  private triggeredKey(countryCode: string): string {
    return `triggered_alerts_${countryCode.toLowerCase()}`;
  }

  async saveTriggeredAlert(countryCode: string, alert: ContextAlert): Promise<void> {
    try {
      const prefs  = await this.getStore();
      const key    = this.triggeredKey(countryCode);
      const raw    = await prefs.get(key, '[]') as string;
      const alerts = JSON.parse(raw) as ContextAlert[];
      if (!alerts.find(a => a.alertId === alert.alertId)) {
        alerts.push(alert);
        await prefs.put(key, JSON.stringify(alerts));
        await prefs.flush();
      }
    } catch (e) {
      console.error('[StorageService] saveTriggeredAlert failed:', JSON.stringify(e));
    }
  }

  async loadTriggeredAlerts(countryCode: string): Promise<ContextAlert[]> {
    try {
      const prefs = await this.getStore();
      const raw   = await prefs.get(this.triggeredKey(countryCode), '[]') as string;
      return JSON.parse(raw) as ContextAlert[];
    } catch (_) {
      return [];
    }
  }
}
