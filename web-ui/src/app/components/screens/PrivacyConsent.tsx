// Safe area: inset 42px → 176×176px content (corners at 124.5px < 130px radius)
export function PrivacyConsent() {
  return (
    <div style={{ width: '100%', height: '100%', background: '#080810', position: 'relative' }}>
      <div style={{
        position: 'absolute', inset: '42px',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        justifyContent: 'center', textAlign: 'center', gap: '0',
      }}>
        {/* Shield */}
        <div style={{
          width: '40px', height: '40px', borderRadius: '50%',
          background: 'rgba(45,212,191,0.12)', border: '1.5px solid rgba(45,212,191,0.35)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '8px',
        }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <path d="M12 2L3 7v6c0 5.25 3.75 10.15 9 11.35C17.25 23.15 21 18.25 21 13V7l-9-5z"
              fill="rgba(45,212,191,0.2)" stroke="#2DD4BF" strokeWidth="1.5" />
            <path d="M9 12l2 2 4-4" stroke="#2DD4BF" strokeWidth="1.5"
              strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div>

        <p style={{ color: '#F8F8FF', fontSize: '13px', fontWeight: 700, margin: '0 0 4px' }}>
          Privacy First
        </p>
        <p style={{ color: '#8888A0', fontSize: '9px', margin: '0 0 10px', lineHeight: 1.4 }}>
          Data used only during<br />active journeys
        </p>

        {/* Permissions */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '4px', width: '100%', marginBottom: '12px' }}>
          {[['📍', 'GPS — scene detection'], ['🎤', 'Mic — phrase assist'], ['📳', 'Haptics — risk alerts']].map(([icon, text]) => (
            <div key={text} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <span style={{ fontSize: '10px' }}>{icon}</span>
              <span style={{ color: '#C8C8E0', fontSize: '9px' }}>{text}</span>
            </div>
          ))}
        </div>

        {/* CTA */}
        <div style={{
          background: '#2DD4BF', color: '#080810', fontSize: '10px', fontWeight: 700,
          padding: '6px 0', borderRadius: '8px', width: '100%', textAlign: 'center',
          letterSpacing: '0.04em',
        }}>
          ALLOW &amp; CONTINUE
        </div>
      </div>
    </div>
  );
}
