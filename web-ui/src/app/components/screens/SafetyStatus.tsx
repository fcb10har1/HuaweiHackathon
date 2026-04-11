const STATS = [
  { icon: '📍', label: 'GPS',     value: 'Active',      color: '#2DD4BF' },
  { icon: '⌚', label: 'Watch',   value: 'Connected',   color: '#2DD4BF' },
  { icon: '📡', label: 'Alerts',  value: '1 active',    color: '#F59E0B' },
  { icon: '✈️', label: 'Journey', value: 'In progress', color: '#2DD4BF' },
];

export function SafetyStatus() {
  return (
    <div style={{ width: '100%', height: '100%', background: '#080810', position: 'relative' }}>
      <div style={{
        position: 'absolute', inset: '38px 42px',
        display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center',
      }}>
        {/* Shield icon */}
        <div style={{ position: 'relative', marginBottom: '6px' }}>
          <div style={{
            position: 'absolute', inset: '-5px', borderRadius: '50%',
            border: '1px solid rgba(45,212,191,0.2)',
          }} />
          <div style={{
            width: '34px', height: '34px', borderRadius: '50%',
            background: 'rgba(45,212,191,0.12)', border: '1.5px solid rgba(45,212,191,0.4)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none">
              <path d="M12 2L3 7v6c0 5.25 3.75 10.15 9 11.35C17.25 23.15 21 18.25 21 13V7l-9-5z"
                fill="rgba(45,212,191,0.2)" stroke="#2DD4BF" strokeWidth="1.5" />
              <path d="M9 12l2 2 4-4" stroke="#2DD4BF" strokeWidth="1.5"
                strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </div>
        </div>

        <p style={{ color: '#2DD4BF', fontSize: '13px', fontWeight: 700, margin: '0 0 2px' }}>
          All Clear
        </p>
        <p style={{ color: '#8888A0', fontSize: '9px', margin: '0 0 10px' }}>
          🇯🇵 Japan · Temple Zone
        </p>

        {/* Stats grid */}
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr',
          gap: '5px', width: '100%', marginBottom: '8px',
        }}>
          {STATS.map((s) => (
            <div key={s.label} style={{
              background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)',
              borderRadius: '8px', padding: '5px 6px',
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '4px', marginBottom: '2px' }}>
                <span style={{ fontSize: '9px' }}>{s.icon}</span>
                <span style={{ color: '#8888A0', fontSize: '8px' }}>{s.label}</span>
              </div>
              <p style={{ color: s.color, fontSize: '9px', fontWeight: 600, margin: 0 }}>
                {s.value}
              </p>
            </div>
          ))}
        </div>

        {/* Alert strip */}
        <div style={{
          width: '100%', paddingTop: '7px',
          borderTop: '1px solid rgba(255,255,255,0.06)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '5px',
        }}>
          <div style={{ width: '5px', height: '5px', borderRadius: '50%', background: '#F59E0B', flexShrink: 0 }} />
          <span style={{ color: '#F59E0B', fontSize: '9px', fontWeight: 600 }}>
            1 sensitive alert nearby
          </span>
        </div>
      </div>
    </div>
  );
}
