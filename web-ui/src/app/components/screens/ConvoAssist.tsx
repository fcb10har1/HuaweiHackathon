const PHRASES = [
  'Please take me to this address.',
  'Please use the meter.',
  'How much will the ride cost?',
  'Can you slow down please?',
];

export function ConvoAssist() {
  const idx = 0;

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
            TAXI · JAPAN
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
          {PHRASES[idx]}
        </p>

        {/* Translation */}
        <p style={{ color: '#8888A0', fontSize: '9px', margin: '0 0 10px' }}>
          この住所へ連れて行って
        </p>

        {/* Dots */}
        <div style={{ display: 'flex', gap: '5px', marginBottom: '10px' }}>
          {PHRASES.map((_, i) => (
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
            color: '#F8F8FF', fontSize: '14px', padding: '6px 0', borderRadius: '7px', textAlign: 'center',
          }}>‹</div>
          <div style={{
            flex: 2, background: 'rgba(45,212,191,0.1)', border: '1px solid rgba(45,212,191,0.25)',
            color: '#2DD4BF', fontSize: '9px', fontWeight: 600, padding: '6px 0',
            borderRadius: '7px', textAlign: 'center',
          }}>🎤 LISTEN</div>
          <div style={{
            flex: 1, background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)',
            color: '#F8F8FF', fontSize: '14px', padding: '6px 0', borderRadius: '7px', textAlign: 'center',
          }}>›</div>
        </div>
      </div>
    </div>
  );
}
