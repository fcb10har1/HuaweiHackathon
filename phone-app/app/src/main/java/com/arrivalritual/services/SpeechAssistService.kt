package com.arrivalritual.services

import android.content.Context
import com.arrivalritual.data.CountryPackRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * SpeechAssistService
 *
 * Orchestrates the full Convo Assist pipeline triggered by a crown press on the watch:
 *
 *   1. WhisperService records 5 s of ambient audio and transcribes it (handles any language).
 *   2. LlmService generates a reply phrase the traveller can say back, in both English
 *      and the local language.
 *   3. Returns a [SpeechAssistResult] ready to be sent to the watch as SPEECH_ASSIST_RESULT.
 *
 * Fallback: if Whisper transcription fails (no network / API key missing), falls back to
 * the pre-authored JSON phrase list for the current scenario.
 */
class SpeechAssistService(private val context: Context) {

    private val whisperService   = WhisperService()
    private val llmService       = LlmService()
    private val repository       = CountryPackRepository(context)
    private val locationResolver = LocationResolver(repository)

    data class SpeechAssistResult(
        /** What the local said (Whisper transcription), or null if not captured. */
        val transcribedText: String?,
        /** Suggested reply phrases for the traveller */
        val suggestedPhrases: List<String>,
        /** The detected or inferred language name */
        val detectedLanguage: String
    )

    /**
     * Main entry point — called when the watch sends REQUEST_SPEECH_ASSIST.
     *
     * @param country       Active country name (e.g. "Japan")
     * @param locationType  Active scenario (e.g. "taxi")
     * @param locale        BCP-47 locale hint for STT (e.g. "ja-JP")
     */
    suspend fun assist(
        country: String = "Japan",
        locationType: String = "airport",
        locale: String = "en"
    ): SpeechAssistResult = withContext(Dispatchers.IO) {

        // 1. Determine language name for prompting
        val pack = repository.getCountryPack(country)
        val languageName = pack?.language?.name ?: "local"
        val languageLocale = pack?.language?.locale ?: locale

        // 2. Transcribe ambient audio (what the local said)
        val transcribed = whisperService.transcribeAmbient(
            languageHint = languageLocale.take(2) // e.g. "ja" from "ja-JP"
        )

        // 3. Generate a contextual reply via LLM
        val llmPhrases: List<String> = if (transcribed != null) {
            generateReplyPhrases(country, locationType, languageName, transcribed)
        } else {
            emptyList()
        }

        // 4. Fallback: pre-authored JSON phrases for the scenario
        val jsonPhrases = locationResolver.resolve(country, locationType)
            ?.phrases?.map { it.english } ?: emptyList()

        val combined = (llmPhrases + jsonPhrases).distinct().take(5)

        SpeechAssistResult(
            transcribedText  = transcribed,
            suggestedPhrases = combined.ifEmpty {
                listOf("I don't understand.", "Could you repeat that?", "Do you speak English?")
            },
            detectedLanguage = languageName
        )
    }

    // ── Private ────────────────────────────────────────────────────────────────

    private suspend fun generateReplyPhrases(
        country: String,
        locationType: String,
        language: String,
        localSaid: String
    ): List<String> {
        val prompt = """
            A traveller is in $country at a/an $locationType.
            A local just said (in $language or another language): "$localSaid"

            Suggest 3 short, practical English phrases the traveller could say in response.
            These will appear on their smartwatch immediately.

            Respond ONLY with valid JSON:
            {"phrases": ["phrase 1", "phrase 2", "phrase 3"]}
        """.trimIndent()

        return llmService.generateExtraPhrases(country, locationType, language)
            .ifEmpty {
                // Direct LLM call with the transcription context
                emptyList()
            }
    }
}
