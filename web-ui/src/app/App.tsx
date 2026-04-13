import { useState } from 'react';
import { WatchFrame } from './components/WatchFrame';
import { PrivacyConsent } from './components/screens/PrivacyConsent';
import { ArrivalWelcome } from './components/screens/ArrivalWelcome';
import { SmartChecklist } from './components/screens/SmartChecklist';
import { ConvoAssist } from './components/screens/ConvoAssist';
import { ConvoListening } from './components/screens/ConvoListening';
import { LocalRadar } from './components/screens/LocalRadar';
import { RedAlert } from './components/screens/RedAlert';
import { CrownMenu } from './components/screens/CrownMenu';
import { SafetyStatus } from './components/screens/SafetyStatus';
import HomeNoTrips from './components/screens/HomeNoTrips';
import HomeWithTrips from './components/screens/HomeWithTrips';
import SelectCountry from './components/screens/SelectCountry';
import SelectDates from './components/screens/SelectDates';
import TripReady from './components/screens/TripReady';
import ChecklistScreen from './components/screens/ChecklistScreen';
import ContextAlertScreen from './components/screens/ContextAlertScreen';
import ConvoResponse from './components/screens/ConvoResponse';
import { Trip, CountryEntry, ContextAlert } from './types';
import { DEMO_ARRIVAL_STEPS, DEMO_PHRASES, DEMO_ALERTS, DEMO_SPEECH_REPLIES, DEMO_TRIP } from './mockData';

// ── Gallery screens (static preview) ──────────────────────────────────────────
const SCREENS = [
  { id: '00', title: 'Privacy & Consent',  subtitle: 'First Launch',       watchScreen: 'first_launch',      component: <PrivacyConsent /> },
  { id: '01', title: 'Arrival Welcome',    subtitle: 'GPS Triggered',      watchScreen: 'idle',              component: <ArrivalWelcome /> },
  { id: '02', title: 'Smart Checklist',    subtitle: 'Progress Tracking',  watchScreen: 'checklist',         component: <SmartChecklist /> },
  { id: '03', title: 'Convo Assist',       subtitle: 'Activated State',    watchScreen: 'convo',             component: <ConvoAssist /> },
  { id: '03b', title: 'Convo Assist',      subtitle: 'Listening State',    watchScreen: 'listening',         component: <ConvoListening /> },
  { id: '04', title: 'Local Radar',        subtitle: 'Context Awareness',  watchScreen: 'alert (SENSITIVE)', component: <LocalRadar /> },
  { id: '05', title: 'Red Alert',          subtitle: 'Restricted Zone',    watchScreen: 'gesture_warning',   component: <RedAlert /> },
  { id: '06', title: 'Crown Navigation',   subtitle: 'Menu System',        watchScreen: 'crown_menu',        component: <CrownMenu /> },
  { id: '07', title: 'Safety Status',      subtitle: 'Dashboard',          watchScreen: 'idle (connected)',  component: <SafetyStatus /> },
];

const RISK_CHIPS = [
  { label: 'Teal — Guidance', color: '#2DD4BF' },
  { label: 'Amber — Sensitive', color: '#F59E0B' },
  { label: 'Red — Legal Risk', color: '#EF4444' },
];

// ── Nav stack types ────────────────────────────────────────────────────────────
type ScreenId =
  | 'home_no_trips' | 'home_with_trips'
  | 'select_country' | 'select_dates'
  | 'trip_ready' | 'checklist' | 'convo_assist'
  | 'convo_listening' | 'convo_response'
  | 'context_alert';

interface NavEntry {
  id: ScreenId;
  country?: CountryEntry;
  trip?: Trip;
  alert?: ContextAlert;
  transcribed?: string;
}

let tripIdCounter = 1;
function buildTrip(country: CountryEntry, startTs: number, endTs: number): Trip {
  return {
    id: `sim-${tripIdCounter++}`,
    countryCode: country.code,
    countryName: country.name,
    flag: country.flag,
    languageName: country.languageName,
    languageLocale: country.languageLocale,
    startTimestamp: startTs,
    endTimestamp: endTs,
  };
}

// ── Simulate mode inner component ─────────────────────────────────────────────
function SimulateView() {
  const [trips, setTrips] = useState<Trip[]>([DEMO_TRIP]);
  const [stack, setStack] = useState<NavEntry[]>([
    { id: trips.length > 0 ? 'home_with_trips' : 'home_no_trips' },
  ]);

  const push = (entry: NavEntry) => setStack(s => [...s, entry]);
  const pop  = () => setStack(s => s.length > 1 ? s.slice(0, -1) : s);
  const top  = stack[stack.length - 1];

  function renderScreen() {
    switch (top.id) {
      case 'home_no_trips':
        return <HomeNoTrips onAddTrip={() => push({ id: 'select_country' })} />;

      case 'home_with_trips':
        return (
          <HomeWithTrips
            trips={trips}
            onAddTrip={() => push({ id: 'select_country' })}
            onOpenTrip={trip => push({ id: 'trip_ready', trip })}
          />
        );

      case 'select_country':
        return (
          <SelectCountry
            onBack={pop}
            onSelect={country => push({ id: 'select_dates', country })}
          />
        );

      case 'select_dates':
        return (
          <SelectDates
            country={top.country}
            onBack={pop}
            onConfirm={(startTs, endTs) => {
              const trip = buildTrip(top.country!, startTs, endTs);
              setTrips(prev => [...prev, trip]);
              // Replace stack: go home then trip
              setStack([
                { id: 'home_with_trips' },
                { id: 'trip_ready', trip },
              ]);
            }}
          />
        );

      case 'trip_ready':
        return (
          <TripReady
            trip={top.trip}
            onBack={pop}
            onArrivalSteps={() => push({ id: 'checklist', trip: top.trip })}
            onConvoAssist={() => push({ id: 'convo_assist', trip: top.trip })}
          />
        );

      case 'checklist':
        return (
          <ChecklistScreen
            steps={DEMO_ARRIVAL_STEPS}
            countryName={top.trip?.countryName}
            onBack={pop}
          />
        );

      case 'convo_assist':
        return (
          <ConvoAssist
            phrases={DEMO_PHRASES}
            languageName={top.trip?.languageName}
            countryName={top.trip?.countryName}
            venueType="Taxi"
            onListen={() => push({ id: 'convo_listening', trip: top.trip })}
            onBack={pop}
          />
        );

      case 'convo_listening':
        return (
          <ConvoListening
            venueType="Taxi"
            onBack={pop}
            onDone={transcribed => push({ id: 'convo_response', trip: top.trip, transcribed })}
          />
        );

      case 'convo_response':
        return (
          <ConvoResponse
            transcribedEnglish={top.transcribed ?? 'いくらかかりますか？'}
            languageName={top.trip?.languageName}
            replies={DEMO_SPEECH_REPLIES}
            onBack={pop}
          />
        );

      case 'context_alert':
        return (
          <ContextAlertScreen
            alert={top.alert ?? DEMO_ALERTS[1]}
            countryName={top.trip?.countryName}
            onDismiss={pop}
          />
        );

      default:
        return <HomeWithTrips trips={trips} onAddTrip={() => push({ id: 'select_country' })} />;
    }
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '20px' }}>
      <WatchFrame>{renderScreen()}</WatchFrame>

      {/* Demo alert triggers */}
      <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap', justifyContent: 'center', maxWidth: '340px' }}>
        {DEMO_ALERTS.map(a => (
          <button
            key={a.alertId}
            onClick={() => push({ id: 'context_alert', alert: a })}
            style={{
              background: 'rgba(255,255,255,0.04)',
              border: '1px solid rgba(255,255,255,0.08)',
              color: '#8888A0',
              fontSize: '10px',
              padding: '4px 10px',
              borderRadius: '6px',
              cursor: 'pointer',
            }}
          >
            📍 {a.locationName} ({a.riskLevel})
          </button>
        ))}
      </div>

      {/* Breadcrumb */}
      <div style={{ display: 'flex', gap: '4px', alignItems: 'center', flexWrap: 'wrap', justifyContent: 'center' }}>
        {stack.map((e, i) => (
          <span key={i} style={{ color: i === stack.length - 1 ? '#2DD4BF' : '#444460', fontSize: '10px' }}>
            {i > 0 && <span style={{ margin: '0 3px', color: '#333350' }}>›</span>}
            {e.id.replace(/_/g, ' ')}
          </span>
        ))}
      </div>
    </div>
  );
}

// ── Main App ──────────────────────────────────────────────────────────────────
type Mode = 'preview' | 'gallery' | 'simulate';

export default function App() {
  const [mode, setMode] = useState<Mode>('preview');
  const [current, setCurrent] = useState(0);

  const screen = SCREENS[current];

  return (
    <div
      style={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #0a0a0f 0%, #13131a 50%, #0a0a0f 100%)',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        fontFamily: "'Inter', sans-serif",
      }}
    >
      {/* ── Header ── */}
      <div style={{ width: '100%', maxWidth: '560px', padding: '40px 24px 0', textAlign: 'center' }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: '10px', marginBottom: '6px' }}>
          <svg width="22" height="22" viewBox="0 0 32 32" fill="none">
            <path d="M16 2C8.268 2 2 8.268 2 16C2 23.732 8.268 30 16 30C23.732 30 30 23.732 30 16"
              stroke="#2DD4BF" strokeWidth="2.5" strokeLinecap="round" />
          </svg>
          <span style={{ color: '#F8F8FF', fontSize: '20px', fontWeight: 800, letterSpacing: '-0.02em' }}>
            ArrivalRitual
          </span>
        </div>
        <p style={{ color: '#8888A0', fontSize: '12px', margin: '0 0 16px' }}>
          Huawei GT4 · HarmonyOS · Watch UI Preview
        </p>

        {/* Mode toggle */}
        <div
          style={{
            display: 'inline-flex',
            background: 'rgba(255,255,255,0.04)',
            border: '1px solid rgba(255,255,255,0.08)',
            borderRadius: '10px',
            padding: '3px',
            gap: '2px',
            marginBottom: '32px',
          }}
        >
          {(['preview', 'gallery', 'simulate'] as Mode[]).map((m) => (
            <button
              key={m}
              onClick={() => setMode(m)}
              style={{
                background: mode === m ? 'rgba(45,212,191,0.15)' : 'transparent',
                border: mode === m ? '1px solid rgba(45,212,191,0.28)' : '1px solid transparent',
                color: mode === m ? '#2DD4BF' : '#8888A0',
                fontSize: '11px',
                fontWeight: mode === m ? 600 : 400,
                padding: '5px 14px',
                borderRadius: '7px',
                cursor: 'pointer',
                textTransform: 'capitalize',
              }}
            >
              {m === 'preview' ? 'Single Frame' : m === 'gallery' ? 'All Frames' : '▶ Simulate'}
            </button>
          ))}
        </div>
      </div>

      {/* ── Single Frame View ── */}
      {mode === 'preview' && (
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '28px', padding: '0 24px 48px' }}>
          <WatchFrame>{screen.component}</WatchFrame>
          <div style={{ textAlign: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', marginBottom: '4px' }}>
              <span style={{ background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', color: '#8888A0', fontSize: '9px', fontWeight: 700, padding: '2px 8px', borderRadius: '99px', letterSpacing: '0.08em' }}>
                SCREEN {screen.id}
              </span>
              <span style={{ background: 'rgba(45,212,191,0.08)', border: '1px solid rgba(45,212,191,0.18)', color: '#2DD4BF', fontSize: '9px', fontWeight: 600, padding: '2px 8px', borderRadius: '99px', letterSpacing: '0.06em', fontFamily: 'monospace' }}>
                {screen.watchScreen}
              </span>
            </div>
            <h2 style={{ color: '#F8F8FF', fontSize: '20px', fontWeight: 700, margin: '0 0 3px' }}>{screen.title}</h2>
            <p style={{ color: '#8888A0', fontSize: '13px', margin: 0 }}>{screen.subtitle}</p>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <button onClick={() => setCurrent(i => Math.max(0, i - 1))} disabled={current === 0}
              style={{ width: '40px', height: '40px', borderRadius: '50%', background: current === 0 ? 'rgba(255,255,255,0.03)' : 'rgba(255,255,255,0.07)', border: '1px solid rgba(255,255,255,0.1)', color: current === 0 ? '#333350' : '#F8F8FF', fontSize: '18px', cursor: current === 0 ? 'not-allowed' : 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>‹</button>
            <div style={{ display: 'flex', gap: '6px', alignItems: 'center' }}>
              {SCREENS.map((_, i) => (
                <button key={i} onClick={() => setCurrent(i)}
                  style={{ width: i === current ? '20px' : '7px', height: '7px', borderRadius: '99px', background: i === current ? '#2DD4BF' : 'rgba(255,255,255,0.15)', border: 'none', cursor: 'pointer', padding: 0, transition: 'all 0.2s' }} />
              ))}
            </div>
            <button onClick={() => setCurrent(i => Math.min(SCREENS.length - 1, i + 1))} disabled={current === SCREENS.length - 1}
              style={{ width: '40px', height: '40px', borderRadius: '50%', background: current === SCREENS.length - 1 ? 'rgba(255,255,255,0.03)' : 'rgba(45,212,191,0.12)', border: `1px solid ${current === SCREENS.length - 1 ? 'rgba(255,255,255,0.08)' : 'rgba(45,212,191,0.28)'}`, color: current === SCREENS.length - 1 ? '#333350' : '#2DD4BF', fontSize: '18px', cursor: current === SCREENS.length - 1 ? 'not-allowed' : 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>›</button>
          </div>
          <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap', justifyContent: 'center', maxWidth: '340px' }}>
            {SCREENS.map((s, i) => (
              <button key={s.id} onClick={() => setCurrent(i)}
                style={{ background: i === current ? 'rgba(45,212,191,0.1)' : 'rgba(255,255,255,0.03)', border: `1px solid ${i === current ? 'rgba(45,212,191,0.28)' : 'rgba(255,255,255,0.06)'}`, color: i === current ? '#2DD4BF' : '#8888A0', fontSize: '10px', fontWeight: i === current ? 700 : 400, padding: '4px 10px', borderRadius: '6px', cursor: 'pointer' }}>
                {s.id}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* ── All Frames Gallery ── */}
      {mode === 'gallery' && (
        <div style={{ width: '100%', maxWidth: '1280px', padding: '0 32px 64px', display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(310px, 1fr))', gap: '48px', justifyItems: 'center' }}>
          {SCREENS.map((s, i) => (
            <div key={s.id} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '14px', cursor: 'pointer' }}
              onClick={() => { setCurrent(i); setMode('preview'); }}>
              <WatchFrame>{s.component}</WatchFrame>
              <div style={{ textAlign: 'center' }}>
                <div style={{ display: 'flex', justifyContent: 'center', gap: '6px', marginBottom: '4px' }}>
                  <span style={{ color: '#8888A0', fontSize: '9px', fontWeight: 700, letterSpacing: '0.1em' }}>{s.id}</span>
                  <span style={{ color: '#333350', fontSize: '9px' }}>·</span>
                  <span style={{ color: '#2DD4BF', fontSize: '9px', fontFamily: 'monospace' }}>{s.watchScreen}</span>
                </div>
                <h3 style={{ color: '#F8F8FF', fontSize: '15px', fontWeight: 700, margin: '0 0 2px' }}>{s.title}</h3>
                <p style={{ color: '#8888A0', fontSize: '12px', margin: 0 }}>{s.subtitle}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ── Simulate Mode ── */}
      {mode === 'simulate' && (
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '12px', padding: '0 24px 48px' }}>
          <p style={{ color: '#8888A0', fontSize: '11px', margin: '0 0 8px', textAlign: 'center' }}>
            Full watch navigation flow · tap buttons on the watch screen
          </p>
          <SimulateView />
        </div>
      )}

      {/* ── Footer ── */}
      <div style={{ width: '100%', maxWidth: '560px', padding: '24px 24px 40px', borderTop: '1px solid rgba(255,255,255,0.05)', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '12px' }}>
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', justifyContent: 'center' }}>
          {RISK_CHIPS.map(({ label, color }) => (
            <div key={label} style={{ display: 'flex', alignItems: 'center', gap: '5px', background: `${color}14`, border: `1px solid ${color}33`, borderRadius: '99px', padding: '4px 12px' }}>
              <div style={{ width: '5px', height: '5px', borderRadius: '50%', background: color }} />
              <span style={{ color, fontSize: '11px', fontWeight: 600 }}>{label}</span>
            </div>
          ))}
        </div>
        <p style={{ color: '#444460', fontSize: '11px', margin: 0, textAlign: 'center' }}>
          Screens mirror live data from <code style={{ color: '#666680' }}>Index.ets</code> on the watch ·
          WearEngine P2P bridge · Real country JSON + LLM phrases
        </p>
      </div>
    </div>
  );
}
