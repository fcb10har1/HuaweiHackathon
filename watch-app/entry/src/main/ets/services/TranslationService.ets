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
      console.info('[TranslationService] Uploading audio:', filePath);
      
      // Upload to backend
      const req = http.createHttp();
      
      // Send filename as query parameter
      const url = `${TRANSLATION_API_BASE_URL}${TRANSLATION_API_ENDPOINT}?filename=${encodeURIComponent(filePath)}`;
      const response = await req.request(url, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
      });

      req.destroy();

      if (response.responseCode === 200 && response.result) {
        try {
          const result = JSON.parse(response.result as string) as TranslationResponse;
          this.validateResponse(result);
          console.info('[TranslationService] Translation received:', result.translationEnglish);
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
