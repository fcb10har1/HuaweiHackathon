import { ContextAlert, riskColor, riskLabel } from '../../types';

interface Props {
  alert?: ContextAlert;
  countryName?: string;
  onDismiss?: () => void;
}

export default function ContextAlertScreen({ alert, countryName: _cn, onDismiss }: Props) {
  if (!alert) return null;

  const color = riskColor(alert.riskLevel);
  const bg = alert.riskLevel === 'LEGAL' ? '#1A0000' : alert.riskLevel === 'SENSITIVE' ? '#1A1200' : '#0D1117';

  return (
    <div
      className="flex flex-col w-full h-full items-center justify-center gap-3"
      style={{ backgroundColor: bg }}
    >
      <span className="text-[13px] font-bold mt-5" style={{ color }}>{riskLabel(alert.riskLevel)}</span>
      {alert.locationName && (
        <span className="text-[10px] text-[#8B949E]">📍 {alert.locationName}</span>
      )}
      <div className="h-0.5 w-[60%] rounded" style={{ backgroundColor: color }} />
      <div className="overflow-y-auto max-h-28 px-4">
        <p className="text-[12px] text-[#E6EDF3] text-center leading-[19px]">{alert.message}</p>
      </div>
      <button
        onClick={onDismiss}
        className="bg-[#21262D] text-[#8B949E] text-[12px] rounded-full px-8 py-1.5 mb-4"
      >
        OK, Got It
      </button>
    </div>
  );
}
