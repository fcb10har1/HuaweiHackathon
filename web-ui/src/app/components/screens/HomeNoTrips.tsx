interface Props {
  onAddTrip?: () => void;
}

export default function HomeNoTrips({ onAddTrip }: Props) {
  return (
    <div className="flex flex-col w-full h-full bg-[#0D1117]">
      <div className="flex items-center justify-between px-3 pt-2.5 pb-1.5">
        <span className="text-[13px] font-bold text-[#E6EDF3]">ArrivalRitual</span>
        <button onClick={onAddTrip} className="text-[22px] text-[#00E5C8] leading-none pb-0.5">+</button>
      </div>
      <div className="h-px bg-[#21262D]" />
      <div className="flex flex-col flex-1 items-center justify-center gap-2.5">
        <span className="text-3xl">✈️</span>
        <span className="text-[13px] text-[#8B949E]">No trips yet</span>
        <span className="text-[10px] text-[#6E7681]">Tap + to add your first trip</span>
        <button
          onClick={onAddTrip}
          className="mt-1 bg-[#1F6FEB] text-white text-[12px] rounded-full px-5 py-1.5"
        >
          + Add Trip
        </button>
      </div>
    </div>
  );
}
