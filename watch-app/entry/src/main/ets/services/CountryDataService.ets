/**
 * CountryDataService.ets
 * Loads and caches country JSON packs from rawfile assets.
 * Files live at: resources/rawfile/countries/{code}.json
 */
import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import { CountryPack, ArrivalStep, Scenario, FallbackAlert, Phrase, ContextAlert } from '../common/Types';

export class CountryDataService {
  private context: common.UIAbilityContext;
  private cache: Map<string, CountryPack> = new Map();

  constructor(ctx: common.UIAbilityContext) {
    this.context = ctx;
  }

  async loadCountryPack(countryCode: string): Promise<CountryPack | null> {
    const code = countryCode.toLowerCase();
    if (this.cache.has(code)) {
      return this.cache.get(code) as CountryPack;
    }
    try {
      const rm = this.context.resourceManager;
      const uint8Array = await rm.getRawFileContent(`countries/${code}.json`);
      const decoder = new util.TextDecoder('utf-8');
      const text = decoder.decode(uint8Array);
      const pack = JSON.parse(text) as CountryPack;
      this.cache.set(code, pack);
      return pack;
    } catch (e) {
      console.error(`[CountryDataService] Failed to load ${code}.json:`, JSON.stringify(e));
      return null;
    }
  }

  async getArrivalSteps(countryCode: string): Promise<ArrivalStep[]> {
    const pack = await this.loadCountryPack(countryCode);
    const airport = pack?.scenarios.find(s => s.id === 'airport');
    return airport?.arrivalSteps ?? [];
  }

  // Find scenario whose locationKeywords contain the given venue type string
  async getScenarioByVenueType(countryCode: string, venueType: string): Promise<Scenario | null> {
    const pack = await this.loadCountryPack(countryCode);
    if (!pack) return null;
    const vt = venueType.toLowerCase();
    return pack.scenarios.find(s =>
      s.locationKeywords.some(k => vt.includes(k) || k.includes(vt))
    ) ?? null;
  }

  // Get phrases for a specific scenario, or all scenarios if scenarioId is empty
  async getPhrases(countryCode: string, scenarioId: string): Promise<Phrase[]> {
    const pack = await this.loadCountryPack(countryCode);
    if (!pack) return [];
    if (scenarioId) {
      const s = pack.scenarios.find(sc => sc.id === scenarioId);
      return s?.phrases ?? [];
    }
    return pack.scenarios.flatMap(s => s.phrases);
  }

  async getFallbackAlert(countryCode: string, venueType: string): Promise<FallbackAlert | null> {
    const scenario = await this.getScenarioByVenueType(countryCode, venueType);
    if (!scenario || scenario.fallbackAlerts.length === 0) return null;
    return scenario.fallbackAlerts[0];
  }

  // Returns all fallbackAlerts across every scenario as ContextAlert[]
  async getAllFallbackAlerts(countryCode: string): Promise<ContextAlert[]> {
    const pack = await this.loadCountryPack(countryCode);
    if (!pack) return [];
    const result: ContextAlert[] = [];
    for (const scenario of pack.scenarios) {
      for (const fa of scenario.fallbackAlerts) {
        result.push({
          alertId:      fa.alertId,
          message:      fa.message,
          riskLevel:    fa.riskLevel,
          locationName: scenario.displayName,
        });
      }
    }
    return result;
  }
}
