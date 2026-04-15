/**
 * TranslationService.ets
 * Handles audio file upload and backend translation API calls.
 * Supports mock mode for reliable demo when backend is unavailable.
 */
import http from '@ohos.net.http';
import fs from '@ohos.file.fs';
import { TRANSLATION_API_BASE_URL, TRANSLATION_API_ENDPOINT, USE_MOCK_TRANSLATION } from '../common/Config';
import { TranslationResponse } from '../common/Types';

export class TranslationService {
  /**
   * Upload audio file to backend and get translation response.
   * Falls back to mock data if enabled or if backend fails.
   */
  async translateAudio(filePath: string): Promise<TranslationResponse> {
    // Use mock mode if enabled (for demo reliability)
    if (USE_MOCK_TRANSLATION) {
      return this.getMockResponse();
    }

    try {
      // Verify file exists and is readable
      if (!fs.accessSync(filePath)) {
        console.error('[TranslationService] File not found:', filePath);
        return this.getMockResponse();
      }

      // Upload to backend
      const req = http.createHttp();
      const response = await req.request(TRANSLATION_API_BASE_URL + TRANSLATION_API_ENDPOINT, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/octet-stream' },
        multiFormDataList: [
          { name: 'audio', contentType: 'audio/mp4', filePath, remoteFileName: 'audio.m4a' },
        ],
      });

      req.destroy();

      if (response.responseCode === 200 && response.result) {
        try {
          const result = JSON.parse(response.result as string) as TranslationResponse;
          this.validateResponse(result);
          return result;
        } catch (e) {
          console.error('[TranslationService] Failed to parse response:', JSON.stringify(e));
        }
      } else {
        console.warn('[TranslationService] API returned status:', response.responseCode);
      }
    } catch (e) {
      console.error('[TranslationService] Upload failed:', JSON.stringify(e));
    }

    // Fallback to mock on any error
    return this.getMockResponse();
  }

  private validateResponse(resp: TranslationResponse): void {
    // Basic validation
    if (!resp.sourceLanguage || !resp.translationEnglish || !Array.isArray(resp.replySuggestionsJapanese)) {
      throw new Error('Invalid response structure');
    }
  }

  /**
   * Mock response for demo when backend is unavailable.
   * Simulates the expected API response format.
   */
  private getMockResponse(): TranslationResponse {
    return {
      sourceLanguage: 'ja',
      transcript: 'すみません、道に迷いました。',
      translationEnglish: 'Excuse me, I am lost.',
      replySuggestionsJapanese: [
        '駅はどちらですか？',
        '助けていただけますか？',
        '英語を話せますか？',
      ],
      ttsAudioUrl: 'https://example.com/audio/result.mp3',
    };
  }
}
