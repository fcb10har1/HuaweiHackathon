export function RedAlert() {
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: 'radial-gradient(circle at center, #160404 0%, #080810 65%)',
    }}>
      <div style={{
        position: 'absolute', inset: '42px',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        justifyContent: 'center', textAlign: 'center',
      }}>
        {/* Camera banned icon */}
        <div style={{ position: 'relative', marginBottom: '8px' }}>
          {[50, 40].map((s, i) => (
            <div key={i} style={{
              position: 'absolute', top: '50%', left: '50%',
              transform: 'translate(-50%, -50%)',
              width: `${s}px`, height: `${s}px`, borderRadius: '50%',
              border: `1px solid rgba(239,68,68,${0.15 + i * 0.12})`,
            }} />
          ))}
          <div style={{
            width: '38px', height: '38px', borderRadius: '50%',
            background: 'rgba(239,68,68,0.14)', border: '1.5px solid #EF4444',
            display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative',
          }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
              <path d="M23 19a2 2 0 01-2 2H3a2 2 0 01-2-2V8a2 2 0 012-2h4l2-3h6l2 3h4a2 2 0 012 2z"
                stroke="#EF4444" strokeWidth="1.5" strokeLinejoin="round" />
              <circle cx="12" cy="13" r="4" stroke="#EF4444" strokeWidth="1.5" />
              <line x1="3" y1="3" x2="21" y2="21" stroke="#EF4444" strokeWidth="1.5" strokeLinecap="round" />
            </svg>
          </div>
        </div>

        {/* Title */}
        <p style={{
          color: '#EF4444', fontSize: '12px', fontWeight: 800,
          letterSpacing: '0.06em', margin: '0 0 6px',
        }}>
          CAMERA RESTRICTED
        </p>

        {/* Message */}
        <p style={{
          color: '#C8C8E0', fontSize: '10px', lineHeight: 1.45,
          margin: '0 0 8px',
        }}>
          Photography not permitted in this sacred area.
        </p>

        {/* Legal badge */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: '4px',
          background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)',
          borderRadius: '99px', padding: '3px 10px', marginBottom: '12px',
        }}>
          <span style={{ fontSize: '9px' }}>🔴</span>
          <span style={{ color: '#EF4444', fontSize: '9px', fontWeight: 700, letterSpacing: '0.05em' }}>
            LEGAL RISK
          </span>
        </div>

        {/* Dismiss */}
        <div style={{
          background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)',
          color: '#8888A0', fontSize: '10px', fontWeight: 600,
          padding: '6px 0', borderRadius: '7px', width: '100%', textAlign: 'center',
        }}>
          Dismiss
        </div>
      </div>
    </div>
  );
}
