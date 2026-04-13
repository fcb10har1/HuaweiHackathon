/**
 * LlmService.ets
 * OpenAI API calls:
 *   - generateContextAlert    → cultural/legal alert for a country + location type
 *   - generateExtraPhrases    → additional situational phrases
 *   - transcribeAndReply      → record 5s audio → Whisper transcription → GPT replies
 */
import http from '@ohos.net.http';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import media from '@ohos.multimedia.media';
import { OPENAI_API_KEY, LLM_MODEL, MIC_DURATION_MS } from '../common/Config';
import { SpeechReply } from '../common/Types';

interface ChatMessage {
  role: string;
  content: string;
}

export interface LlmAlertResult {
  alertId: string;
  message: string;
  riskLevel: string;
}

export interface TranscribeResult {
  transcribedEnglish: string;  // what the local said, in English
  replies: SpeechReply[];      // suggested traveller replies: { english, local }
}

export class LlmService {

  // ── Context alert ────────────────────────────────────────────────────────────

  async generateContextAlert(country: string, locationType: string): Promise<LlmAlertResult | null> {
    if (!OPENAI_API_KEY) return null;
    try {
      const req = http.createHttp();
      const resp = await req.request('https://api.openai.com/v1/chat/completions', {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': `Bearer ${OPENAI_API_KEY}`,
          'Content-Type': 'application/json',
        },
        extraData: JSON.stringify({
          model: LLM_MODEL,
          response_format: { type: 'json_object' },
          max_tokens: 200,
          temperature: 0.7,
          messages: [
            { role: 'system', content: 'You are a travel cultural guidance assistant. Always respond with valid JSON only.' } as ChatMessage,
            {
              role: 'user',
              content:
                `A traveler is in ${country} at a/an ${locationType}. ` +
                `Generate ONE concise cultural or legal alert. ` +
                `Respond ONLY with valid JSON: ` +
                `{"alertId":"snake_case_id","message":"1-2 sentence alert","riskLevel":"NORM"} ` +
                `riskLevel must be NORM, SENSITIVE, or LEGAL.`,
            } as ChatMessage,
          ] as ChatMessage[],
        }),
      });
      req.destroy();
      if (resp.responseCode !== 200) return null;
      const body = JSON.parse(resp.result as string) as Record<string, Object>;
      const choices = body['choices'] as Array<Record<string, Object>>;
      const content = JSON.parse((choices[0]['message'] as Record<string, string>)['content']) as LlmAlertResult;
      return content;
    } catch (_) {
      return null;
    }
  }

  // ── Extra phrases ────────────────────────────────────────────────────────────

  async generateExtraPhrases(country: string, locationType: string): Promise<string[]> {
    if (!OPENAI_API_KEY) return [];
    try {
      const req = http.createHttp();
      const resp = await req.request('https://api.openai.com/v1/chat/completions', {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': `Bearer ${OPENAI_API_KEY}`,
          'Content-Type': 'application/json',
        },
        extraData: JSON.stringify({
          model: LLM_MODEL,
          response_format: { type: 'json_object' },
          max_tokens: 150,
          messages: [
            { role: 'system', content: 'You are a travel assistant. Always respond with valid JSON only.' } as ChatMessage,
            {
              role: 'user',
              content:
                `A traveler is in ${country} at a/an ${locationType}. ` +
                `Provide exactly 3 short practical English phrases they might need. ` +
                `Respond ONLY with: {"phrases":["phrase one","phrase two","phrase three"]}`,
            } as ChatMessage,
          ] as ChatMessage[],
        }),
      });
      req.destroy();
      if (resp.responseCode !== 200) return [];
      const body = JSON.parse(resp.result as string) as Record<string, Object>;
      const choices = body['choices'] as Array<Record<string, Object>>;
      const content = JSON.parse((choices[0]['message'] as Record<string, string>)['content']) as Record<string, string[]>;
      return content['phrases'] ?? [];
    } catch (_) {
      return [];
    }
  }

  // ── Speech: record → transcribe → generate replies ───────────────────────────

  async transcribeAndReply(
    context: common.UIAbilityContext,
    country: string,
    locationType: string,
    language: string,
    languageLocale: string,
  ): Promise<TranscribeResult> {
    const langHint = languageLocale.substring(0, 2); // e.g. "ja" from "ja-JP"
    let rawTranscription = '';

    // ── Step 1: Record 5 seconds of audio ──────────────────────────────────────
    const filePath = context.tempDir + '/ar_recording.m4a';
    try {
      try { fs.unlinkSync(filePath); } catch (_) { /* file may not exist */ }

      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      const recorder = await media.createAVRecorder();

      await recorder.prepare({
        audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
        profile: {
          audioBitrate: 48000,
          audioChannels: 1,
          audioCodec: media.CodecMimeType.AUDIO_AAC,
          audioSampleRate: 16000,
          fileFormat: media.ContainerFormatType.CFT_MPEG_4A,
        },
        url: `fd://${file.fd}`,
      });

      await recorder.start();
      await new Promise<void>(r => setTimeout(r, MIC_DURATION_MS));
      await recorder.stop();
      await recorder.release();
      fs.closeSync(file.fd);
    } catch (e) {
      console.error('[LlmService] Recording failed:', JSON.stringify(e));
      return this.fallbackResult();
    }

    // ── Step 2: Transcribe with Whisper ────────────────────────────────────────
    if (OPENAI_API_KEY) {
      try {
        const req = http.createHttp();
        const resp = await req.request('https://api.openai.com/v1/audio/transcriptions', {
          method: http.RequestMethod.POST,
          header: { 'Authorization': `Bearer ${OPENAI_API_KEY}` },
          multiFormDataList: [
            { name: 'file', contentType: 'audio/m4a', filePath, remoteFileName: 'recording.m4a' },
            { name: 'model', data: 'whisper-1', contentType: 'text/plain' },
            { name: 'language', data: langHint, contentType: 'text/plain' },
          ],
        });
        req.destroy();
        if (resp.responseCode === 200) {
          const result = JSON.parse(resp.result as string) as Record<string, string>;
          rawTranscription = result['text'] ?? '';
        }
      } catch (e) {
        console.error('[LlmService] Whisper failed:', JSON.stringify(e));
      }
    }

    if (!rawTranscription) {
      return this.fallbackResult();
    }

    // ── Step 3: Translate + generate replies via GPT ───────────────────────────
    try {
      const req = http.createHttp();
      const resp = await req.request('https://api.openai.com/v1/chat/completions', {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': `Bearer ${OPENAI_API_KEY}`,
          'Content-Type': 'application/json',
        },
        extraData: JSON.stringify({
          model: LLM_MODEL,
          response_format: { type: 'json_object' },
          max_tokens: 400,
          messages: [
            { role: 'system', content: 'You are a travel language assistant. Always respond with valid JSON only.' } as ChatMessage,
            {
              role: 'user',
              content:
                `A traveler is in ${country} at a/an ${locationType}. ` +
                `A local just said: "${rawTranscription}" (in ${language}). ` +
                `Translate what was said to English, then suggest 3 short practical replies the traveler could say back. ` +
                `Each reply must have both an English version and a ${language} version. ` +
                `Respond ONLY with valid JSON: ` +
                `{"translated":"English translation of what was said",` +
                `"replies":[{"english":"reply","local":"${language} reply"},` +
                `{"english":"reply","local":"${language} reply"},` +
                `{"english":"reply","local":"${language} reply"}]}`,
            } as ChatMessage,
          ] as ChatMessage[],
        }),
      });
      req.destroy();
      if (resp.responseCode === 200) {
        const body = JSON.parse(resp.result as string) as Record<string, Object>;
        const choices = body['choices'] as Array<Record<string, Object>>;
        const content = JSON.parse((choices[0]['message'] as Record<string, string>)['content']) as Record<string, Object>;
        return {
          transcribedEnglish: content['translated'] as string ?? rawTranscription,
          replies: content['replies'] as SpeechReply[] ?? [],
        };
      }
    } catch (e) {
      console.error('[LlmService] Reply generation failed:', JSON.stringify(e));
    }

    return this.fallbackResult();
  }

  private fallbackResult(): TranscribeResult {
    return {
      transcribedEnglish: '',
      replies: [
        { english: "I don't understand.",    local: '' },
        { english: 'Could you repeat that?', local: '' },
        { english: 'Do you speak English?',  local: '' },
      ],
    };
  }
}
