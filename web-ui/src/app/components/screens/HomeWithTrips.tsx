import { Trip, getTripStatus, formatDate } from '../../types';

interface Props {
  trips?: Trip[];
  onAddTrip?: () => void;
  onOpenTrip?: (trip: Trip) => void;
}

function statusBadge(trip: Trip) {
  const s = getTripStatus(trip);
  if (s === 'active')   return { label: 'ACTIVE',   color: '#00E5C8' };
  if (s === 'upcoming') return { label: 'UPCOMING', color: '#1F6FEB' };
  return { label: 'ENDED', color: '#8B949E' };
}

export default function HomeWithTrips({ trips = [], onAddTrip, onOpenTrip }: Props) {
  return (
    <div className="flex flex-col w-full h-full bg-[#0D1117]">
      <div className="flex items-center justify-between px-3 pt-2.5 pb-1.5">
        <span className="text-[13px] font-bold text-[#E6EDF3]">ArrivalRitual</span>
        <button onClick={onAddTrip} className="text-[22px] text-[#00E5C8] leading-none pb-0.5">+</button>
      </div>
      <div className="h-px bg-[#21262D]" />
      <div className="flex flex-col flex-1 gap-2 px-2.5 py-2 overflow-y-auto">
        {trips.map(trip => {
          const badge = statusBadge(trip);
          return (
            <button
              key={trip.id}
              onClick={() => onOpenTrip?.(trip)}
              className="flex items-center gap-2.5 w-full bg-[#161B22] rounded-lg px-3 py-2.5 text-left"
            >
              <span className="text-xl">{trip.flag}</span>
              <div className="flex-1 min-w-0">
                <div className="text-[13px] font-bold text-[#E6EDF3] truncate">{trip.countryName}</div>
                <div className="text-[9px] text-[#8B949E]">{formatDate(trip.startTimestamp)} – {formatDate(trip.endTimestamp)}</div>
              </div>
              <span
                className="text-[9px] px-1.5 py-0.5 bg-[#21262D] rounded"
                style={{ color: badge.color }}
              >
                {badge.label}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
