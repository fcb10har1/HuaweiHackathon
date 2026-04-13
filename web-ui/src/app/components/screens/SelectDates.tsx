import { useState } from 'react';
import { CountryEntry } from '../../types';

interface Props {
  country?: CountryEntry;
  onBack?: () => void;
  onConfirm?: (startTs: number, endTs: number) => void;
}

function daysFromNow(n: number) {
  return Date.now() + n * 24 * 60 * 60 * 1000;
}

export default function SelectDates({ country, onBack, onConfirm }: Props) {
  const [step, setStep] = useState<0 | 1 | 2>(0);
  const [departDays, setDepartDays] = useState(1);
  const [returnDays, setReturnDays] = useState(8);

  const startTs = daysFromNow(departDays);
  const endTs   = daysFromNow(returnDays);

  const fmt = (ts: number) => new Date(ts).toLocaleDateString('en-GB', { day: '2-digit', month: 'short' });

  if (step === 2) {
    return (
      <div className="flex flex-col w-full h-full bg-[#0D1117] items-center justify-center gap-4">
        <span className="text-3xl">{country?.flag ?? '🌏'}</span>
        <span className="text-[14px] font-bold text-[#E6EDF3]">{country?.name}</span>
        <div className="text-center text-[11px] text-[#8B949E]">
          <div>{fmt(startTs)} → {fmt(endTs)}</div>
        </div>
        <div className="flex gap-3 mt-2">
          <button onClick={() => setStep(1)} className="bg-[#21262D] text-[#8B949E] text-[11px] rounded-full px-4 py-1.5">Back</button>
          <button onClick={() => onConfirm?.(startTs, endTs)} className="bg-[#238636] text-white text-[11px] rounded-full px-4 py-1.5">Confirm ✓</button>
        </div>
      </div>
    );
  }

  const isDepart = step === 0;
  const days = isDepart ? departDays : returnDays;
  const setDays = isDepart ? setDepartDays : setReturnDays;
  const minDays = isDepart ? 0 : departDays + 1;

  return (
    <div className="flex flex-col w-full h-full bg-[#0D1117]">
      <div className="flex items-center gap-2 px-2 pt-2 pb-1.5 h-10">
        <button onClick={step === 0 ? onBack : () => setStep(0)} className="text-[18px] text-[#8B949E] px-2">←</button>
        <span className="text-[13px] font-bold text-[#E6EDF3]">{isDepart ? 'Depart Date' : 'Return Date'}</span>
      </div>
      <div className="h-px bg-[#21262D]" />
      <div className="flex flex-col flex-1 items-center justify-center gap-4">
        <span className="text-[11px] text-[#8B949E]">{isDepart ? 'When do you leave?' : 'When do you return?'}</span>
        <span className="text-[22px] font-bold text-[#E6EDF3]">{fmt(daysFromNow(days))}</span>
        <div className="flex items-center gap-4">
          <button
            onClick={() => setDays(Math.max(minDays, days - 1))}
            className="w-9 h-9 bg-[#21262D] rounded-full text-[#E6EDF3] text-lg"
          >−</button>
          <span className="text-[11px] text-[#8B949E]">in {days}d</span>
          <button
            onClick={() => setDays(days + 1)}
            className="w-9 h-9 bg-[#21262D] rounded-full text-[#E6EDF3] text-lg"
          >+</button>
        </div>
        <button
          onClick={() => setStep(isDepart ? 1 : 2)}
          className="bg-[#1F6FEB] text-white text-[12px] rounded-full px-6 py-1.5 mt-2"
        >
          Next →
        </button>
      </div>
    </div>
  );
}
