export function ArrivalWelcome() {
  return (
    <div style={{ width: '100%', height: '100%', background: '#080810', position: 'relative' }}>
      <div style={{
        position: 'absolute', inset: '42px',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        justifyContent: 'center', textAlign: 'center',
      }}>
        {/* Flag with ring */}
        <div style={{ position: 'relative', marginBottom: '8px' }}>
          <div style={{
            position: 'absolute', inset: '-6px', borderRadius: '50%',
            border: '1px solid rgba(45,212,191,0.25)',
          }} />
          <div style={{
            width: '42px', height: '42px', borderRadius: '50%',
            background: 'rgba(45,212,191,0.08)', border: '1.5px solid rgba(45,212,191,0.4)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '22px',
          }}>
            🇯🇵
          </div>
        </div>

        {/* GPS pill */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: '4px',
          marginBottom: '4px',
        }}>
          <div style={{ width: '5px', height: '5px', borderRadius: '50%', background: '#2DD4BF' }} />
          <span style={{ color: '#2DD4BF', fontSize: '8px', fontWeight: 600, letterSpacing: '0.07em' }}>
            GPS TRIGGERED
          </span>
        </div>

        <p style={{ color: '#F8F8FF', fontSize: '14px', fontWeight: 700, margin: '0 0 2px' }}>
          Welcome to Japan
        </p>
        <p style={{ color: '#8888A0', fontSize: '9px', margin: '0 0 12px' }}>
          Ritual ready · 4 steps
        </p>

        {/* Buttons */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', width: '100%' }}>
          <div style={{
            background: '#2DD4BF', color: '#080810', fontSize: '10px', fontWeight: 700,
            padding: '7px 0', borderRadius: '8px', textAlign: 'center',
          }}>
            ✓  ARRIVAL STEPS
          </div>
          <div style={{
            background: 'rgba(45,212,191,0.08)', border: '1px solid rgba(45,212,191,0.28)',
            color: '#2DD4BF', fontSize: '10px', fontWeight: 600,
            padding: '7px 0', borderRadius: '8px', textAlign: 'center',
          }}>
            🎤  CONVO ASSIST
          </div>
        </div>
      </div>
    </div>
  );
}
