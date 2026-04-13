interface LocalRadarProps { onDismiss?: () => void; onPhrases?: () => void; }
export function LocalRadar({ onDismiss, onPhrases }: LocalRadarProps = {}) {
  return (
    <div style={{ width: '100%', height: '100%', background: '#080810', position: 'relative' }}>
      <div style={{
        position: 'absolute', inset: '42px',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        justifyContent: 'center', textAlign: 'center',
      }}>
        {/* Risk badge */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: '4px',
          background: 'rgba(245,158,11,0.08)', border: '1px solid rgba(245,158,11,0.25)',
          borderRadius: '99px', padding: '3px 10px', marginBottom: '8px',
        }}>
          <div style={{ width: '5px', height: '5px', borderRadius: '50%', background: '#F59E0B' }} />
          <span style={{ color: '#F59E0B', fontSize: '9px', fontWeight: 600, letterSpacing: '0.06em' }}>
            SENSITIVE
          </span>
        </div>

        {/* Icon */}
        <div style={{
          width: '38px', height: '38px', borderRadius: '50%',
          background: 'rgba(245,158,11,0.1)', border: '1.5px solid rgba(245,158,11,0.35)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: '18px', marginBottom: '8px',
        }}>
          🏯
        </div>

        {/* Alert text */}
        <p style={{
          color: '#F8F8FF', fontSize: '11px', fontWeight: 600,
          lineHeight: 1.45, margin: '0 0 6px',
        }}>
          Remove shoes before entering. Avoid pointing at sacred objects.
        </p>

        <p style={{ color: '#8888A0', fontSize: '9px', margin: '0 0 10px' }}>
          📍 Temple Zone · Japan
        </p>

        {/* Divider */}
        <div style={{ height: '1px', width: '100%', background: 'rgba(255,255,255,0.07)', marginBottom: '10px' }} />

        {/* Buttons */}
        <div style={{ display: 'flex', gap: '6px', width: '100%' }}>
          <div style={{
            flex: 1, background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)',
            color: '#8888A0', fontSize: '10px', fontWeight: 600,
            padding: '6px 0', borderRadius: '7px', textAlign: 'center', cursor: 'pointer',
          }} onClick={onDismiss}>OK</div>
          <div style={{
            flex: 2, background: 'rgba(45,212,191,0.08)', border: '1px solid rgba(45,212,191,0.22)',
            color: '#2DD4BF', fontSize: '10px', fontWeight: 600,
            padding: '6px 0', borderRadius: '7px', textAlign: 'center', cursor: 'pointer',
          }} onClick={onPhrases}>🎤 Phrases</div>
        </div>
      </div>
    </div>
  );
}
