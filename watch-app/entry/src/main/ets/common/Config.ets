/**
 * Config.ets — Build-time constants for ArrivalRitual
 *
 * API keys are injected via build-profile.json5 > buildOption.arkOptions.buildProfileFields.
 * Set OPENAI_API_KEY and GOOGLE_PLACES_API_KEY in entry/build-profile.json5 before building.
 */
import BuildProfile from 'BuildProfile';

// ── API Keys (set in entry/build-profile.json5) ────────────────────────────────
export const OPENAI_API_KEY: string = BuildProfile.OPENAI_API_KEY as string;
export const GOOGLE_PLACES_API_KEY: string = BuildProfile.GOOGLE_PLACES_API_KEY as string;

// ── Timing ─────────────────────────────────────────────────────────────────────
export const GPS_POLL_INTERVAL_MS: number = 5 * 60 * 1000;  // 5 minutes
export const ALERT_COOLDOWN_MS: number    = 60 * 60 * 1000; // 1 hour per location type
export const MIC_DURATION_MS: number      = 5000;            // 5-second recording window

// ── LLM ───────────────────────────────────────────────────────────────────────
export const LLM_MODEL: string = 'gpt-4o-mini';

// ── Backend API (for demo file-based translation) ────────────────────────────
export const TRANSLATION_API_BASE_URL: string = 'http://localhost:5000';
export const TRANSLATION_API_ENDPOINT: string = '/api/translate';
export const USE_MOCK_TRANSLATION: boolean = true;  // Set to false when backend is ready

// ── Places ────────────────────────────────────────────────────────────────────
// Map Google Places types → our scenario IDs
export const PLACES_TYPE_MAP: Record<string, string> = {
  'place_of_worship': 'temple',
  'hindu_temple':     'temple',
  'mosque':           'temple',
  'buddhist_temple':  'temple',
  'airport':          'airport',
  'transit_station':  'transit',
  'train_station':    'transit',
  'bus_station':      'transit',
  'shopping_mall':    'market',
  'market':           'market',
  'food_market':      'market',
  'taxi_stand':       'taxi',
  'restaurant':       'restaurant',
  'night_club':       'nightlife',
};
