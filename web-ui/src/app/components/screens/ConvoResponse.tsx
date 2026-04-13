import { useState } from 'react';
import { SpeechReply } from '../../types';

interface Props {
  transcribedEnglish?: string;
  languageName?: string;
  replies?: SpeechReply[];
  onBack?: () => void;
}

export default function ConvoResponse({ transcribedEnglish, languageName = 'Japanese', replies = [], onBack }: Props) {
  const [idx, setIdx] = useState(0);
  const current = replies[idx];

  return (
    <div
      className="flex flex-col w-full h-full bg-[#0D1117]"
      onTouchStart={() => {}}
    >
      <div className="flex items-center gap-2 px-2 pt-2 pb-1.5 h-10">
        <button onClick={onBack} className="text-[18px] text-[#8B949E] px-2">←</button>
        <span className="text-[13px] font-bold text-[#E6EDF3]">Convo Result</span>
      </div>
      <div className="h-px bg-[#21262D]" />

      <div className="flex flex-col flex-1 items-center overflow-y-auto py-3 gap-3">
        {transcribedEnglish && (
          <>
            <div className="flex flex-col items-center gap-1 w-full px-3">
              <span className="text-[10px] text-[#8B949E]">They said:</span>
              <span className="text-[12px] text-[#C9D1D9] italic text-center leading-snug">"{transcribedEnglish}"</span>
            </div>
            <div className="h-px bg-[#21262D] w-4/5" />
          </>
        )}

        <span className="text-[10px] text-[#8B949E]">You can say:</span>

        {current && (
          <div className="flex flex-col items-center gap-2 w-[90%] bg-[#161B22] rounded-lg p-3">
            <span className="text-[13px] font-bold text-[#E6EDF3] text-center leading-5">{current.english}</span>
            {current.local && (
              <>
                <div className="h-px bg-[#21262D] w-[60%]" />
                <span className="text-[9px] text-[#8B949E]">({languageName}):</span>
                <span className="text-[13px] text-[#00E5C8] text-center leading-5">{current.local}</span>
              </>
            )}
          </div>
        )}

        {replies.length > 1 && (
          <>
            <span className="text-[10px] text-[#8B949E]">{idx + 1} / {replies.length}</span>
            <div className="flex gap-4">
              <button
                onClick={() => setIdx(Math.max(0, idx - 1))}
                disabled={idx === 0}
                className="bg-[#21262D] text-[#E6EDF3] text-[20px] rounded-full w-[35%] h-9 disabled:opacity-20"
                style={{ minWidth: '60px' }}
              >‹</button>
              <button
                onClick={() => setIdx(Math.min(replies.length - 1, idx + 1))}
                disabled={idx === replies.length - 1}
                className="bg-[#21262D] text-[#E6EDF3] text-[20px] rounded-full w-[35%] h-9 disabled:opacity-20"
                style={{ minWidth: '60px' }}
              >›</button>
            </div>
          </>
        )}

        <span className="text-[9px] text-[#6E7681] mt-1">Tap ← to go back</span>
      </div>
    </div>
  );
}
