const RISK_COLOR: Record<string, string> = {
  LEGAL: '#EF4444', SENSITIVE: '#F59E0B', NORM: '#2DD4BF',
};
const RISK_LABEL: Record<string, string> = {
  LEGAL: '🔴 LEGAL', SENSITIVE: '🟡 SENSITIVE', NORM: '🟢 NORM',
};

// Demo: step 2 of 5, LEGAL risk
const STEP = {
  index: 1, total: 5,
  title: 'Customs Declaration',
  desc: 'Declare all items over ¥200,000. Undeclared goods risk confiscation.',
  risk: 'LEGAL',
};

export function SmartChecklist() {
  const color = RISK_COLOR[STEP.risk];

  return (
    <div style={{ width: '100%', height: '100%', background: '#080810', position: 'relative' }}>
      {/* Use slightly less vertical inset to fit progress bar + button */}
      <div style={{
        position: 'absolute', inset: '38px 42px',
        display: 'flex', flexDirection: 'column',
        justifyContent: 'center',
      }}>
        {/* Step + risk row */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '5px' }}>
          <span style={{ color: '#8888A0', fontSize: '9px', fontWeight: 600 }}>
            STEP {STEP.index + 1} / {STEP.total}
          </span>
          <span style={{ color, fontSize: '9px', fontWeight: 600 }}>
            {RISK_LABEL[STEP.risk]}
          </span>
        </div>

        {/* Progress bar */}
        <div style={{
          height: '3px', background: 'rgba(255,255,255,0.07)', borderRadius: '99px',
          marginBottom: '10px', overflow: 'hidden',
        }}>
          <div style={{
            height: '100%', width: `${((STEP.index) / STEP.total) * 100}%`,
            background: color, borderRadius: '99px',
          }} />
        </div>

        {/* Title */}
        <p style={{
          color: '#F8F8FF', fontSize: '14px', fontWeight: 700,
          margin: '0 0 6px', lineHeight: 1.25,
        }}>
          {STEP.title}
        </p>

        {/* Description */}
        <p style={{
          color: '#C8C8E0', fontSize: '10px', lineHeight: 1.5,
          margin: '0 0 12px',
        }}>
          {STEP.desc}
        </p>

        {/* Colour divider */}
        <div style={{
          height: '1px', marginBottom: '10px',
          background: `linear-gradient(90deg, transparent, ${color}60, transparent)`,
        }} />

        {/* Next button */}
        <div style={{
          background: color, color: '#080810', fontSize: '10px', fontWeight: 700,
          padding: '7px 0', borderRadius: '8px', textAlign: 'center',
        }}>
          NEXT STEP ›
        </div>
      </div>
    </div>
  );
}
