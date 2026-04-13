import { Trip, ArrivalStep, Phrase, ContextAlert, SpeechReply } from './types';

export const DEMO_TRIP: Trip = {
  id: 'demo-jp-001',
  countryCode: 'JP',
  countryName: 'Japan',
  flag: '🇯🇵',
  languageName: 'Japanese',
  languageLocale: 'ja-JP',
  startTimestamp: Date.now() - 1000 * 60 * 60,
  endTimestamp: Date.now() + 1000 * 60 * 60 * 24 * 7,
};

export const DEMO_ARRIVAL_STEPS: ArrivalStep[] = [
  { stepIndex: 0, title: 'Complete Visit Japan Web / Arrival Card', description: 'Register on Visit Japan Web or fill out the paper Disembarkation Card. Provide name, passport number, flight number, and purpose of visit.', riskLevel: 'NORM' },
  { stepIndex: 1, title: 'Quarantine / Health Screening', description: 'Proceed through the health/quarantine checkpoint after deplaning. Declare any restricted items (fresh produce, meat).', riskLevel: 'NORM' },
  { stepIndex: 2, title: 'Immigration (Passport Control)', description: 'Join the foreigner queue. Present passport, disembarkation card or Visit Japan Web QR code. All visitors aged 16+ must provide fingerprints and a photo.', riskLevel: 'SENSITIVE' },
  { stepIndex: 3, title: 'Baggage Claim', description: 'Collect checked baggage from the designated carousel. Keep baggage claim tags as officers may check them.', riskLevel: 'NORM' },
  { stepIndex: 4, title: 'Customs Declaration', description: 'Submit the Customs Declaration form. Declare cash exceeding JPY 1,000,000, gifts over JPY 200,000 duty-free value, and any restricted goods.', riskLevel: 'LEGAL' },
  { stepIndex: 5, title: 'Plant / Animal Quarantine', description: 'If carrying fresh fruit, vegetables, meat, or live animals, present them at the Quarantine counter. Undeclared items can result in fines or deportation.', riskLevel: 'LEGAL' },
];

export const DEMO_PHRASES: Phrase[] = [
  { english: 'Please take me to this address.', nativeScript: 'この住所まで連れて行ってください。', romanized: 'Kono jūsho made tsurete itte kudasai.' },
  { english: 'How much will it cost?', nativeScript: 'いくらかかりますか？', romanized: 'Ikura kakarimasu ka?' },
  { english: 'Please stop here.', nativeScript: 'ここで止めてください。', romanized: 'Koko de tomete kudasai.' },
  { english: 'Where is the immigration counter?', nativeScript: '入国審査はどこですか？', romanized: 'Nyūkoku shinsa wa doko desu ka?' },
  { english: 'I have nothing to declare.', nativeScript: '申告するものはありません。', romanized: 'Shinkoku suru mono wa arimasen.' },
];

export const DEMO_ALERTS: ContextAlert[] = [
  { alertId: 'jp_taxi_door',   message: 'Taxi doors open and close automatically — never touch the handle or you may cause damage.', riskLevel: 'NORM',      locationName: 'Taxi' },
  { alertId: 'jp_temple_photo', message: 'Photography inside main halls is usually prohibited. Look for no-camera signs.', riskLevel: 'SENSITIVE', locationName: 'Temple' },
  { alertId: 'jp_immigration_drugs', message: 'Several common medications are controlled substances in Japan. Undeclared prescription drugs can result in arrest.', riskLevel: 'LEGAL', locationName: 'Immigration' },
];

export const DEMO_SPEECH_REPLIES: SpeechReply[] = [
  { english: 'Yes, please proceed.',       local: 'はい、どうぞ。' },
  { english: 'I don\'t understand.',        local: 'わかりません。' },
  { english: 'Can you say that again?',    local: 'もう一度言っていただけますか？' },
];
