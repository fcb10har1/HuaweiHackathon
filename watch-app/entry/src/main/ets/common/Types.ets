/**
 * Types.ets — Shared type definitions for ArrivalRitual watch app
 */

export interface Trip {
  id: string;
  countryCode: string;
  countryName: string;
  flag: string;
  languageName: string;
  languageLocale: string;
  startTimestamp: number;  // ms since epoch
  endTimestamp: number;    // ms since epoch
}

export interface ArrivalStep {
  stepIndex: number;
  title: string;
  description: string;
  riskLevel: string;
}

export interface Phrase {
  english: string;
  nativeScript: string;
  romanized: string;
}

export interface FallbackAlert {
  alertId: string;
  message: string;
  riskLevel: string;
}

export interface Scenario {
  id: string;
  displayName: string;
  icon: string;
  geofence: string;
  locationKeywords: string[];
  arrivalSteps: ArrivalStep[];
  fallbackAlerts: FallbackAlert[];
  phrases: Phrase[];
}

export interface CountryLanguage {
  name: string;
  locale: string;
  nativeScriptName: string;
}

export interface CountryPack {
  countryCode: string;
  name: string;
  flag: string;
  tagline: string;
  language: CountryLanguage;
  scenarios: Scenario[];
}

export interface ContextAlert {
  alertId: string;
  message: string;
  riskLevel: string;
  locationName: string;
}

export interface SpeechReply {
  english: string;
  local: string;
}

export interface TranslationResponse {
  sourceLanguage: string;
  transcript: string;
  translationEnglish: string;
  replySuggestionsJapanese: string[];
  ttsAudioUrl: string;
}

export interface CountryEntry {
  code: string;
  name: string;
  flag: string;
  languageName: string;
  languageLocale: string;
}

export interface AudioFile {
  name: string;
  file: string;
}

export const SUPPORTED_COUNTRIES: CountryEntry[] = [
  { code: 'AE', name: 'UAE',        flag: '🇦🇪', languageName: 'Arabic',      languageLocale: 'ar-AE' },
  { code: 'ID', name: 'Indonesia',  flag: '🇮🇩', languageName: 'Indonesian',  languageLocale: 'id-ID' },
  { code: 'IN', name: 'India',      flag: '🇮🇳', languageName: 'Hindi',       languageLocale: 'hi-IN' },
  { code: 'JP', name: 'Japan',      flag: '🇯🇵', languageName: 'Japanese',    languageLocale: 'ja-JP' },
  { code: 'KH', name: 'Cambodia',   flag: '🇰🇭', languageName: 'Khmer',       languageLocale: 'km-KH' },
  { code: 'LA', name: 'Laos',       flag: '🇱🇦', languageName: 'Lao',         languageLocale: 'lo-LA' },
  { code: 'MY', name: 'Malaysia',   flag: '🇲🇾', languageName: 'Malay',       languageLocale: 'ms-MY' },
  { code: 'SG', name: 'Singapore',  flag: '🇸🇬', languageName: 'English',     languageLocale: 'en-SG' },
  { code: 'TH', name: 'Thailand',   flag: '🇹🇭', languageName: 'Thai',        languageLocale: 'th-TH' },
  { code: 'VN', name: 'Vietnam',    flag: '🇻🇳', languageName: 'Vietnamese',  languageLocale: 'vi-VN' },
];

// ── UI helpers ─────────────────────────────────────────────────────────────────

export function riskColor(level: string): string {
  if (level === 'LEGAL')     return '#FF4444';
  if (level === 'SENSITIVE') return '#FFB800';
  return '#00E5C8';
}

export function riskLabel(level: string): string {
  if (level === 'LEGAL')     return '🔴 LEGAL';
  if (level === 'SENSITIVE') return '🟡 SENSITIVE';
  return '🟢 NORM';
}

export function formatDate(ts: number): string {
  const d = new Date(ts);
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return `${d.getDate()} ${months[d.getMonth()]} ${d.getFullYear()}`;
}

export function getTripStatus(trip: Trip): string {
  const now = Date.now();
  if (now < trip.startTimestamp) return 'upcoming';
  if (now > trip.endTimestamp)   return 'ended';
  return 'active';
}
