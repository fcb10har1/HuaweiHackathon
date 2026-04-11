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

export default function App() {
  const [current, setCurrent] = useState(0);
  const [showAll, setShowAll] = useState(false);

  const screen = SCREENS[current];
  const prev = () => setCurrent((i) => Math.max(0, i - 1));
  const next = () => setCurrent((i) => Math.min(SCREENS.length - 1, i + 1));

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

        {/* View toggle */}
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
          {(['Single Frame', 'All Frames'] as const).map((label) => {
            const active = label === 'All Frames' ? showAll : !showAll;
            return (
              <button
                key={label}
                onClick={() => setShowAll(label === 'All Frames')}
                style={{
                  background: active ? 'rgba(45,212,191,0.15)' : 'transparent',
                  border: active ? '1px solid rgba(45,212,191,0.28)' : '1px solid transparent',
                  color: active ? '#2DD4BF' : '#8888A0',
                  fontSize: '11px',
                  fontWeight: active ? 600 : 400,
                  padding: '5px 14px',
                  borderRadius: '7px',
                  cursor: 'pointer',
                  transition: 'all 0.15s',
                }}
              >
                {label}
              </button>
            );
          })}
        </div>
      </div>

      {/* ── Single Frame View ── */}
      {!showAll && (
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '28px', padding: '0 24px 48px' }}>
          {/* Watch */}
          <WatchFrame>{screen.component}</WatchFrame>

          {/* Screen info */}
          <div style={{ textAlign: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', marginBottom: '4px' }}>
              <span
                style={{
                  background: 'rgba(255,255,255,0.05)',
                  border: '1px solid rgba(255,255,255,0.1)',
                  color: '#8888A0',
                  fontSize: '9px',
                  fontWeight: 700,
                  padding: '2px 8px',
                  borderRadius: '99px',
                  letterSpacing: '0.08em',
                }}
              >
                SCREEN {screen.id}
              </span>
              <span
                style={{
                  background: 'rgba(45,212,191,0.08)',
                  border: '1px solid rgba(45,212,191,0.18)',
                  color: '#2DD4BF',
                  fontSize: '9px',
                  fontWeight: 600,
                  padding: '2px 8px',
                  borderRadius: '99px',
                  letterSpacing: '0.06em',
                  fontFamily: 'monospace',
                }}
              >
                {screen.watchScreen}
              </span>
            </div>
            <h2 style={{ color: '#F8F8FF', fontSize: '20px', fontWeight: 700, margin: '0 0 3px' }}>
              {screen.title}
            </h2>
            <p style={{ color: '#8888A0', fontSize: '13px', margin: 0 }}>{screen.subtitle}</p>
          </div>

          {/* Navigation controls */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <button
              onClick={prev}
              disabled={current === 0}
              style={{
                width: '40px',
                height: '40px',
                borderRadius: '50%',
                background: current === 0 ? 'rgba(255,255,255,0.03)' : 'rgba(255,255,255,0.07)',
                border: '1px solid rgba(255,255,255,0.1)',
                color: current === 0 ? '#333350' : '#F8F8FF',
                fontSize: '18px',
                cursor: current === 0 ? 'not-allowed' : 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              ‹
            </button>

            {/* Step dots */}
            <div style={{ display: 'flex', gap: '6px', alignItems: 'center' }}>
              {SCREENS.map((_, i) => (
                <button
                  key={i}
                  onClick={() => setCurrent(i)}
                  style={{
                    width: i === current ? '20px' : '7px',
                    height: '7px',
                    borderRadius: '99px',
                    background: i === current ? '#2DD4BF' : 'rgba(255,255,255,0.15)',
                    border: 'none',
                    cursor: 'pointer',
                    padding: 0,
                    transition: 'all 0.2s',
                  }}
                />
              ))}
            </div>

            <button
              onClick={next}
              disabled={current === SCREENS.length - 1}
              style={{
                width: '40px',
                height: '40px',
                borderRadius: '50%',
                background: current === SCREENS.length - 1 ? 'rgba(255,255,255,0.03)' : 'rgba(45,212,191,0.12)',
                border: `1px solid ${current === SCREENS.length - 1 ? 'rgba(255,255,255,0.08)' : 'rgba(45,212,191,0.28)'}`,
                color: current === SCREENS.length - 1 ? '#333350' : '#2DD4BF',
                fontSize: '18px',
                cursor: current === SCREENS.length - 1 ? 'not-allowed' : 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              ›
            </button>
          </div>

          {/* Screen index strip */}
          <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap', justifyContent: 'center', maxWidth: '340px' }}>
            {SCREENS.map((s, i) => (
              <button
                key={s.id}
                onClick={() => setCurrent(i)}
                style={{
                  background: i === current ? 'rgba(45,212,191,0.1)' : 'rgba(255,255,255,0.03)',
                  border: `1px solid ${i === current ? 'rgba(45,212,191,0.28)' : 'rgba(255,255,255,0.06)'}`,
                  color: i === current ? '#2DD4BF' : '#8888A0',
                  fontSize: '10px',
                  fontWeight: i === current ? 700 : 400,
                  padding: '4px 10px',
                  borderRadius: '6px',
                  cursor: 'pointer',
                }}
              >
                {s.id}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* ── All Frames Gallery ── */}
      {showAll && (
        <div
          style={{
            width: '100%',
            maxWidth: '1280px',
            padding: '0 32px 64px',
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(310px, 1fr))',
            gap: '48px',
            justifyItems: 'center',
          }}
        >
          {SCREENS.map((s, i) => (
            <div
              key={s.id}
              style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '14px', cursor: 'pointer' }}
              onClick={() => { setCurrent(i); setShowAll(false); }}
            >
              {/* Highlight ring on hover handled via opacity only (no hover state in inline styles) */}
              <div style={{ opacity: 1 }}>
                <WatchFrame>{s.component}</WatchFrame>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ display: 'flex', justifyContent: 'center', gap: '6px', marginBottom: '4px' }}>
                  <span style={{ color: '#8888A0', fontSize: '9px', fontWeight: 700, letterSpacing: '0.1em' }}>
                    {s.id}
                  </span>
                  <span style={{ color: '#333350', fontSize: '9px' }}>·</span>
                  <span style={{ color: '#2DD4BF', fontSize: '9px', fontFamily: 'monospace' }}>
                    {s.watchScreen}
                  </span>
                </div>
                <h3 style={{ color: '#F8F8FF', fontSize: '15px', fontWeight: 700, margin: '0 0 2px' }}>
                  {s.title}
                </h3>
                <p style={{ color: '#8888A0', fontSize: '12px', margin: 0 }}>{s.subtitle}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ── Footer ── */}
      <div
        style={{
          width: '100%',
          maxWidth: '560px',
          padding: '24px 24px 40px',
          borderTop: '1px solid rgba(255,255,255,0.05)',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: '12px',
        }}
      >
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', justifyContent: 'center' }}>
          {RISK_CHIPS.map(({ label, color }) => (
            <div
              key={label}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '5px',
                background: `${color}14`,
                border: `1px solid ${color}33`,
                borderRadius: '99px',
                padding: '4px 12px',
              }}
            >
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
