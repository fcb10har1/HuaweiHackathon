import { ReactNode } from 'react';

interface WatchFrameProps {
  children: ReactNode;
}

export function WatchFrame({ children }: WatchFrameProps) {
  return (
    <div className="relative flex-shrink-0" style={{ width: '296px', height: '296px' }}>
      {/* Outer bezel */}
      <div
        className="absolute inset-0 rounded-full"
        style={{
          background: 'linear-gradient(150deg, #252535 0%, #0c0c18 45%, #181825 100%)',
          boxShadow:
            '0 0 0 1px rgba(255,255,255,0.07), 0 30px 80px rgba(0,0,0,0.95), inset 0 1px 0 rgba(255,255,255,0.08), inset 0 -1px 0 rgba(0,0,0,0.5)',
        }}
      />

      {/* Inner bezel ring */}
      <div
        className="absolute rounded-full"
        style={{
          inset: '10px',
          background: 'linear-gradient(150deg, #14141f, #080810)',
          boxShadow:
            'inset 0 2px 6px rgba(0,0,0,0.9), inset 0 0 0 1px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.03)',
        }}
      />

      {/* Screen */}
      <div
        className="absolute rounded-full overflow-hidden"
        style={{ inset: '18px', background: '#080810' }}
      >
        {children}
      </div>

      {/* Screen glare */}
      <div
        className="absolute rounded-full pointer-events-none"
        style={{
          inset: '18px',
          background:
            'linear-gradient(160deg, rgba(255,255,255,0.05) 0%, transparent 45%)',
        }}
      />

      {/* Crown */}
      <div
        className="absolute"
        style={{
          right: '-16px',
          top: '50%',
          transform: 'translateY(-55%)',
          width: '20px',
          height: '48px',
          background: 'linear-gradient(90deg, #1c1c2c, #24243a)',
          borderRadius: '0 7px 7px 0',
          boxShadow:
            '3px 0 12px rgba(0,0,0,0.7), inset -1px 0 1px rgba(255,255,255,0.05)',
        }}
      >
        {/* Crown ridges */}
        {[8, 16, 24, 32, 40].map((top) => (
          <div
            key={top}
            style={{
              position: 'absolute',
              top: `${top}px`,
              left: 0,
              right: 0,
              height: '1px',
              background: 'rgba(255,255,255,0.06)',
            }}
          />
        ))}
      </div>

      {/* Side button */}
      <div
        className="absolute"
        style={{
          right: '-12px',
          top: '34%',
          transform: 'translateY(-50%)',
          width: '14px',
          height: '24px',
          background: 'linear-gradient(90deg, #161625, #1e1e30)',
          borderRadius: '0 4px 4px 0',
          boxShadow: '2px 0 6px rgba(0,0,0,0.6)',
        }}
      />
    </div>
  );
}
