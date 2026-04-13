const BARS = [4, 8, 12, 7, 14, 9, 5, 11, 7, 4, 10, 6];

interface ConvoListeningProps { onBack?: () => void; onDone?: (transcribed: string) => void; venueType?: string; }
export function ConvoListening({ onBack: _ob, onDone: _od, venueType }: ConvoListeningProps = {}) {
  return (
    <div style={{ width: '100%', height: '100%', background: '#080810', position: 'relative' }}>
      <div style={{
        position: 'absolute', inset: '42px',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        justifyContent: 'center', textAlign: 'center',
      }}>
        {/* Mic with rings */}
        <div style={{ position: 'relative', marginBottom: '10px' }}>
          {[54, 42].map((s, i) => (
            <div key={i} style={{
              position: 'absolute', top: '50%', left: '50%',
              transform: 'translate(-50%, -50%)',
              width: `${s}px`, height: `${s}px`, borderRadius: '50%',
              border: `1px solid rgba(45,212,191,${0.14 + i * 0.1})`,
            }} />
          ))}
          <div style={{
            width: '36px', height: '36px', borderRadius: '50%',
            background: 'rgba(45,212,191,0.14)', border: '1.5px solid #2DD4BF',
            display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative',
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <rect x="9" y="2" width="6" height="12" rx="3" fill="#2DD4BF" />
              <path d="M5 10c0 3.866 3.134 7 7 7s7-3.134 7-7"
                stroke="#2DD4BF" strokeWidth="1.5" strokeLinecap="round" />
              <line x1="12" y1="17" x2="12" y2="21"
                stroke="#2DD4BF" strokeWidth="1.5" strokeLinecap="round" />
            </svg>
          </div>
        </div>

        <p style={{ color: '#2DD4BF', fontSize: '14px', fontWeight: 700, margin: '0 0 8px' }}>
          Listening…
        </p>

        {/* Waveform */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: '3px',
          height: '18px', marginBottom: '8px',
        }}>
          {BARS.map((h, i) => (
            <div key={i} style={{
              width: '3px', height: `${h}px`, borderRadius: '2px',
              background: `rgba(45,212,191,${0.35 + (i % 3) * 0.2})`,
            }} />
          ))}
        </div>

        <p style={{ color: '#8888A0', fontSize: '9px', margin: '0 0 8px' }}>
          Hold near speaker · 5 sec
        </p>

        {/* Context chip */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: '4px',
          background: 'rgba(255,255,255,0.04)', borderRadius: '6px', padding: '4px 10px',
        }}>
          <span style={{ fontSize: '9px' }}>🛺</span>
          <span style={{ color: '#8888A0', fontSize: '8.5px' }}>{venueType ? `${venueType} context active` : 'Taxi context active'}</span>
        </div>
      </div>
    </div>
  );
}
