import { Trip, formatDate } from '../../types';

interface Props {
  trip?: Trip;
  onBack?: () => void;
  onArrivalSteps?: () => void;
  onConvoAssist?: () => void;
}

export default function TripReady({ trip, onBack, onArrivalSteps, onConvoAssist }: Props) {
  return (
    <div className="flex flex-col w-full h-full bg-[#0D1117]">
      <div className="flex items-center gap-2 px-2 pt-2 pb-1.5 h-10">
        <button onClick={onBack} className="text-[18px] text-[#8B949E] px-2">←</button>
        <span className="text-[13px] font-bold text-[#E6EDF3]">My Trip</span>
      </div>
      <div className="h-px bg-[#21262D]" />
      <div className="flex flex-col items-center py-3.5 gap-1">
        <span className="text-3xl">{trip?.flag ?? '🌏'}</span>
        <span className="text-[16px] font-bold text-[#E6EDF3]">{trip?.countryName ?? 'Country'}</span>
        {trip && (
          <span className="text-[10px] text-[#8B949E]">
            {formatDate(trip.startTimestamp)} – {formatDate(trip.endTimestamp)}
          </span>
        )}
      </div>
      <div className="h-px bg-[#21262D] mx-5" />
      <div className="flex flex-col flex-1 items-center justify-center gap-3">
        <button
          onClick={onArrivalSteps}
          className="bg-[#1F6FEB] text-white text-[13px] rounded-full w-[85%] py-2.5"
        >
          ✈️  Arrival Steps
        </button>
        <button
          onClick={onConvoAssist}
          className="bg-[#238636] text-white text-[13px] rounded-full w-[85%] py-2.5"
        >
          💬  Convo Assist
        </button>
      </div>
    </div>
  );
}
