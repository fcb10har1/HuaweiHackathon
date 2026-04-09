package com.arrivalritual.services

import android.content.Context
import com.arrivalritual.data.CountryPackRepository

/**
 * ConversationService
 *
 * Builds the Convo Assist phrase list for a given country + locationType:
 *   1. Pre-authored phrases from the country JSON pack (English text)
 *   2. LLM-generated extras appended when network is available
 *
 * Falls back to a hardcoded taxi stub when context is null (test environment).
 */
class ConversationService(private val context: Context? = null) {

    private val repository     = CountryPackRepository(context)
    private val llmService     = LlmService()
    private val locationResolver = LocationResolver(repository)

    suspend fun getConversationOptions(
        country: String = "Japan",
        locationType: String = "taxi",
        locale: String = "en"
    ): Map<String, Any> {

        if (context != null) {
            // 1. JSON pre-authored phrases
            val scenario = locationResolver.resolve(country, locationType)
            val jsonPhrases = scenario?.phrases?.map { it.english } ?: emptyList()

            // 2. LLM extras
            val languageName = repository.getCountryPack(country)?.language?.name ?: "local"
            val llmExtras = llmService.generateExtraPhrases(country, locationType, languageName)

            val combined = (jsonPhrases + llmExtras).distinct()
            if (combined.isNotEmpty()) {
                return mapOf("options" to combined)
            }
        }

        // Stub fallback
        return mapOf(
            "options" to listOf(
                "Please take me to this address.",
                "Use the meter.",
                "How much will the ride cost?"
            )
        )
    }
}
