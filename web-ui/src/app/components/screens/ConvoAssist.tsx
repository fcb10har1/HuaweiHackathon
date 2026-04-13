import { useState } from 'react';
import { Phrase } from '../../types';

const PHRASES = [
  'Please take me to this address.',
  'Please use the meter.',
  'How much will the ride cost?',
  'Can you slow down please?',
];

interface ConvoAssistProps {
  phrases?: Phrase[];
  languageName?: string;
  venueType?: string;
  countryName?: string;
  onListen?: () => void;
  onBack?: () => void;
}

export function ConvoAssist({ phrases, languageName, venueType, countryName, onListen }: ConvoAssistProps = {}) {
  const [idx, setIdx] = useState(0);
  const useRich = phrases && phrases.length > 0;
  const total = useRich ? phrases!.length : PHRASES.length;
  const currentEnglish = useRich ? phrases![idx].english : PHRASES[idx];
  const currentLocal = useRich ? phrases![idx].nativeScript : '';

  return (
    <div style={{ width: '100%', height: '100%', background: '#080810', position: 'relative' }}>
      <div style={{
        position: 'absolute', inset: '42px',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        justifyContent: 'center', textAlign: 'center',
      }}>
        {/* Context badge */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: '4px',
          background: 'rgba(45,212,191,0.08)', border: '1px solid rgba(45,212,191,0.22)',
          borderRadius: '99px', padding: '3px 10px', marginBottom: '8px',
        }}>
          <span style={{ fontSize: '9px' }}>🛺</span>
          <span style={{ color: '#2DD4BF', fontSize: '8px', fontWeight: 600, letterSpacing: '0.06em' }}>
            {venueType ? venueType.toUpperCase() : 'TAXI'} · {countryName ? countryName.toUpperCase() : 'JAPAN'}
          </span>
        </div>

        <p style={{ color: '#8888A0', fontSize: '9px', margin: '0 0 5px', letterSpacing: '0.05em' }}>
          SAY THIS
        </p>

        {/* Main phrase */}
        <p style={{
          color: '#2DD4BF', fontSize: '13px', fontWeight: 700,
          lineHeight: 1.4, margin: '0 0 5px',
        }}>
          {currentEnglish}
        </p>

        {/* Translation */}
        {currentLocal && (
          <p style={{ color: '#8888A0', fontSize: '9px', margin: '0 0 10px' }}>
            {currentLocal}
          </p>
        )}

        {/* Dots */}
        <div style={{ display: 'flex', gap: '5px', marginBottom: '10px' }}>
          {Array.from({ length: total }).map((_, i) => (
            <div key={i} style={{
              width: i === idx ? '14px' : '6px', height: '6px', borderRadius: '99px',
              background: i === idx ? '#2DD4BF' : 'rgba(255,255,255,0.15)',
            }} />
          ))}
        </div>

        {/* Nav row */}
        <div style={{ display: 'flex', gap: '6px', width: '100%' }}>
          <div style={{
            flex: 1, background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)',
            color: idx > 0 ? '#F8F8FF' : 'rgba(255,255,255,0.2)', fontSize: '14px', padding: '6px 0',
            borderRadius: '7px', textAlign: 'center', cursor: 'pointer',
          }} onClick={() => setIdx(Math.max(0, idx - 1))}>‹</div>
          <div style={{
            flex: 2, background: 'rgba(45,212,191,0.1)', border: '1px solid rgba(45,212,191,0.25)',
            color: '#2DD4BF', fontSize: '9px', fontWeight: 600, padding: '6px 0',
            borderRadius: '7px', textAlign: 'center', cursor: 'pointer',
          }} onClick={onListen}>🎤 LISTEN</div>
          <div style={{
            flex: 1, background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)',
            color: idx < total - 1 ? '#F8F8FF' : 'rgba(255,255,255,0.2)', fontSize: '14px', padding: '6px 0',
            borderRadius: '7px', textAlign: 'center', cursor: 'pointer',
          }} onClick={() => setIdx(Math.min(total - 1, idx + 1))}>›</div>
        </div>
      </div>
    </div>
  );
}
