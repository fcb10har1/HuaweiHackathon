import { SUPPORTED_COUNTRIES, CountryEntry } from '../../types';

interface Props {
  onBack?: () => void;
  onSelect?: (country: CountryEntry) => void;
}

export default function SelectCountry({ onBack, onSelect }: Props) {
  return (
    <div className="flex flex-col w-full h-full bg-[#0D1117]">
      <div className="flex items-center gap-2 px-2 pt-2 pb-1.5 h-10">
        <button onClick={onBack} className="text-[18px] text-[#8B949E] px-2">←</button>
        <span className="text-[13px] font-bold text-[#E6EDF3]">Select Country</span>
      </div>
      <div className="h-px bg-[#21262D]" />
      <div className="flex flex-col flex-1 gap-1.5 px-2.5 py-2 overflow-y-auto">
        {SUPPORTED_COUNTRIES.map(c => (
          <button
            key={c.code}
            onClick={() => onSelect?.(c)}
            className="flex items-center gap-3 w-full bg-[#161B22] rounded-lg px-3 py-2.5 text-left"
          >
            <span className="text-xl">{c.flag}</span>
            <div className="flex-1">
              <div className="text-[13px] font-bold text-[#E6EDF3]">{c.name}</div>
              <div className="text-[9px] text-[#8B949E]">{c.languageName}</div>
            </div>
            <span className="text-[10px] text-[#8B949E]">›</span>
          </button>
        ))}
      </div>
    </div>
  );
}
