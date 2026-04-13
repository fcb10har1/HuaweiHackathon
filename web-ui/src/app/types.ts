export interface Trip {
  id: string;
  countryCode: string;
  countryName: string;
  flag: string;
  languageName: string;
  languageLocale: string;
  startTimestamp: number;
  endTimestamp: number;
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

export interface ContextAlert {
  alertId: string;
  message: string;
  riskLevel: string;
  locationName?: string;
}

export interface SpeechReply {
  english: string;
  local: string;
}

export interface CountryEntry {
  code: string;
  name: string;
  flag: string;
  languageName: string;
  languageLocale: string;
}

export const SUPPORTED_COUNTRIES: CountryEntry[] = [
  { code: 'AE', name: 'United Arab Emirates', flag: '🇦🇪', languageName: 'Arabic',     languageLocale: 'ar-AE' },
  { code: 'ID', name: 'Indonesia',            flag: '🇮🇩', languageName: 'Indonesian', languageLocale: 'id-ID' },
  { code: 'IN', name: 'India',                flag: '🇮🇳', languageName: 'Hindi',      languageLocale: 'hi-IN' },
  { code: 'JP', name: 'Japan',                flag: '🇯🇵', languageName: 'Japanese',   languageLocale: 'ja-JP' },
  { code: 'KH', name: 'Cambodia',             flag: '🇰🇭', languageName: 'Khmer',      languageLocale: 'km-KH' },
  { code: 'LA', name: 'Laos',                 flag: '🇱🇦', languageName: 'Lao',        languageLocale: 'lo-LA' },
  { code: 'MY', name: 'Malaysia',             flag: '🇲🇾', languageName: 'Malay',      languageLocale: 'ms-MY' },
  { code: 'SG', name: 'Singapore',            flag: '🇸🇬', languageName: 'English',    languageLocale: 'en-SG' },
  { code: 'TH', name: 'Thailand',             flag: '🇹🇭', languageName: 'Thai',       languageLocale: 'th-TH' },
  { code: 'VN', name: 'Vietnam',              flag: '🇻🇳', languageName: 'Vietnamese', languageLocale: 'vi-VN' },
];

export function riskColor(level: string): string {
  if (level === 'LEGAL')     return '#EF4444';
  if (level === 'SENSITIVE') return '#F59E0B';
  return '#2DD4BF';
}

export function riskLabel(level: string): string {
  if (level === 'LEGAL')     return '⚠️ LEGAL RISK';
  if (level === 'SENSITIVE') return '⚡ HEADS UP';
  return 'ℹ️ GOOD TO KNOW';
}

export function formatDate(ts: number): string {
  return new Date(ts).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: '2-digit' });
}

export function getTripStatus(trip: Trip): 'upcoming' | 'active' | 'ended' {
  const now = Date.now();
  if (now < trip.startTimestamp) return 'upcoming';
  if (now > trip.endTimestamp)   return 'ended';
  return 'active';
}
