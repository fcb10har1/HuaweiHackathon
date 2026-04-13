/**
 * PlacesService.ets
 * Calls Google Places Nearby Search to identify the venue type at a given coordinate.
 * Returns a venue type string matching our scenario IDs (e.g. 'temple', 'airport').
 */
import http from '@ohos.net.http';
import { GOOGLE_PLACES_API_KEY, PLACES_TYPE_MAP } from '../common/Config';

export class PlacesService {

  /**
   * Returns a venue type string (e.g. 'temple', 'airport', 'market') or null if none found.
   */
  async getVenueType(lat: number, lng: number): Promise<string | null> {
    if (!GOOGLE_PLACES_API_KEY) return null;
    try {
      const url =
        `https://maps.googleapis.com/maps/api/place/nearbysearch/json` +
        `?location=${lat},${lng}&radius=100&key=${GOOGLE_PLACES_API_KEY}`;

      const req = http.createHttp();
      const resp = await req.request(url, {
        method: http.RequestMethod.GET,
        header: { 'Accept': 'application/json' },
        connectTimeout: 8000,
        readTimeout: 8000,
      });
      req.destroy();

      if (resp.responseCode !== 200) return null;

      const body = JSON.parse(resp.result as string) as Record<string, Object>;
      const results = body['results'] as Array<Record<string, Object>>;
      if (!results || results.length === 0) return null;

      // Check top 3 results for a recognisable type
      for (let i = 0; i < Math.min(3, results.length); i++) {
        const types = results[i]['types'] as string[];
        if (!types) continue;
        for (const t of types) {
          const mapped = PLACES_TYPE_MAP[t];
          if (mapped) return mapped;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
