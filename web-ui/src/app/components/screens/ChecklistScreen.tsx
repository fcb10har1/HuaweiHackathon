import { useState } from 'react';
import { ArrivalStep, riskColor } from '../../types';

interface Props {
  steps?: ArrivalStep[];
  countryName?: string;
  onBack?: () => void;
}

export default function ChecklistScreen({ steps = [], countryName = 'Japan', onBack }: Props) {
  const [idx, setIdx] = useState(0);
  const [done, setDone] = useState(false);

  const step = steps[idx];
  const total = steps.length;

  if (!step) return null;

  const color = riskColor(step.riskLevel);

  return (
    <div className="flex flex-col w-full h-full bg-[#0D1117]">
      <div className="flex items-center gap-2 px-2 pt-2 pb-1.5 h-10">
        <button onClick={onBack} className="text-[18px] text-[#8B949E] px-2">←</button>
        <span className="text-[13px] font-bold text-[#E6EDF3]">Arrival Steps</span>
      </div>
      <div className="h-px bg-[#21262D]" />

      {done ? (
        <div className="flex flex-col flex-1 items-center justify-center gap-3">
          <span className="text-3xl">✅</span>
          <span className="text-[13px] font-bold text-[#E6EDF3]">All Done!</span>
          <span className="text-[10px] text-[#8B949E]">Enjoy {countryName}</span>
          <button onClick={onBack} className="mt-2 bg-[#21262D] text-[#8B949E] text-[11px] rounded-full px-5 py-1.5">
            Back to Trip
          </button>
        </div>
      ) : (
        <>
          <div className="px-3 pt-2">
            <div className="h-1.5 bg-[#21262D] rounded-full overflow-hidden">
              <div
                className="h-full rounded-full transition-all"
                style={{ width: `${((idx + 1) / total) * 100}%`, backgroundColor: color }}
              />
            </div>
            <span className="text-[9px] text-[#8B949E] mt-0.5 block text-right">
              {idx + 1} / {total}
            </span>
          </div>

          <div className="flex flex-col flex-1 px-3 py-2 gap-2 overflow-y-auto">
            <span
              className="text-[9px] font-bold uppercase tracking-wide"
              style={{ color }}
            >
              {step.riskLevel}
            </span>
            <span className="text-[12px] font-bold text-[#E6EDF3] leading-snug">{step.title}</span>
            <span className="text-[10px] text-[#8B949E] leading-snug">{step.description}</span>
          </div>

          <div className="flex gap-3 justify-center pb-3">
            <button
              onClick={() => setIdx(Math.max(0, idx - 1))}
              disabled={idx === 0}
              className="bg-[#21262D] text-[#8B949E] text-[11px] rounded-full px-4 py-1.5 disabled:opacity-30"
            >
              ‹ Back
            </button>
            <button
              onClick={() => {
                if (idx < total - 1) setIdx(idx + 1);
                else setDone(true);
              }}
              className="bg-[#1F6FEB] text-white text-[11px] rounded-full px-4 py-1.5"
            >
              {idx < total - 1 ? 'Next ›' : 'Done ✓'}
            </button>
          </div>
        </>
      )}
    </div>
  );
}
