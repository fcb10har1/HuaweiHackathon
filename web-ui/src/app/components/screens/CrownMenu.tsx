const ITEMS = [
  { icon: '✈️', label: 'Arrival Steps',   sub: '4 steps · Japan',      active: false },
  { icon: '🎤', label: 'Convo Assist',    sub: 'Crown press to speak',  active: true  },
  { icon: '📡', label: 'Local Radar',     sub: 'Alerts active',         active: false },
  { icon: '🛡️', label: 'Safety Status',  sub: 'All clear',             active: false },
];

export function CrownMenu() {
  return (
    <div style={{ width: '100%', height: '100%', background: '#080810', position: 'relative' }}>
      {/* Slightly less vertical inset to fit 4 menu items */}
      <div style={{
        position: 'absolute', inset: '36px 42px',
        display: 'flex', flexDirection: 'column',
      }}>
        {/* App header */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '4px',
        }}>
          <svg width="11" height="11" viewBox="0 0 32 32" fill="none">
            <path d="M16 2C8.268 2 2 8.268 2 16C2 23.732 8.268 30 16 30C23.732 30 30 23.732 30 16"
              stroke="#2DD4BF" strokeWidth="2.5" strokeLinecap="round" />
          </svg>
          <span style={{ color: '#F8F8FF', fontSize: '10px', fontWeight: 700, letterSpacing: '0.05em' }}>
            ARRIVALRITUAL
          </span>
          <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: '3px' }}>
            <div style={{ width: '5px', height: '5px', borderRadius: '50%', background: '#2DD4BF' }} />
          </div>
        </div>

        <p style={{ color: '#8888A0', fontSize: '8px', margin: '0 0 8px', letterSpacing: '0.04em' }}>
          ↕ CROWN to scroll
        </p>

        {/* Menu items */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '5px', flex: 1 }}>
          {ITEMS.map((item) => (
            <div key={item.label} style={{
              display: 'flex', alignItems: 'center', gap: '7px',
              background: item.active ? 'rgba(45,212,191,0.1)' : 'rgba(255,255,255,0.03)',
              border: `1px solid ${item.active ? 'rgba(45,212,191,0.28)' : 'rgba(255,255,255,0.06)'}`,
              borderRadius: '8px', padding: '5px 7px',
            }}>
              <span style={{ fontSize: '12px', width: '16px', textAlign: 'center', flexShrink: 0 }}>
                {item.icon}
              </span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <p style={{
                  color: item.active ? '#2DD4BF' : '#F8F8FF',
                  fontSize: '10px', fontWeight: item.active ? 700 : 500,
                  margin: 0, lineHeight: 1.2,
                }}>
                  {item.label}
                </p>
                <p style={{ color: '#8888A0', fontSize: '8px', margin: 0, lineHeight: 1.2 }}>
                  {item.sub}
                </p>
              </div>
              {item.active && (
                <span style={{ color: '#2DD4BF', fontSize: '11px', flexShrink: 0 }}>›</span>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
