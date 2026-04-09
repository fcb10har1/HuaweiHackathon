package com.arrivalritual.services

import android.content.Context
import com.arrivalritual.data.CountryPackRepository

/**
 * ContextService
 *
 * Resolves a country + locationType pair to a cultural/legal alert using this priority chain:
 *
 *   1. Persistent cache (SharedPreferences) — instant, free
 *   2. OpenAI LLM API — dynamic, network-required
 *   3. Keyword-matched JSON fallback alert — offline-safe
 *   4. Generic hardcoded stub — last resort / test environment
 *
 * The LLM response is cached after a successful API call so subsequent requests
 * for the same country + locationType are served from disk.
 */
class ContextService(private val context: Context? = null) {

    private val repository     = CountryPackRepository(context)
    private val cacheManager   = AlertCacheManager(context)
    private val llmService     = LlmService()
    private val locationResolver = LocationResolver(repository)

    suspend fun getContextAlert(
        country: String = "Japan",
        locationType: String = "airport"
    ): Map<String, Any> {

        // 1. Check persistent cache
        cacheManager.get(country, locationType)?.let { cached ->
            return mapOf(
                "alertId"   to cached.alertId,
                "message"   to cached.message,
                "riskLevel" to cached.riskLevel
            )
        }

        if (context != null) {
            // 2. Try LLM
            val llmResponse = llmService.generateContextAlert(country, locationType)
            if (llmResponse != null) {
                cacheManager.put(country, locationType, llmResponse)
                return mapOf(
                    "alertId"   to llmResponse.alertId,
                    "message"   to llmResponse.message,
                    "riskLevel" to llmResponse.riskLevel
                )
            }

            // 3. JSON keyword fallback
            val fallback = locationResolver.getFallbackAlert(country, locationType)
            if (fallback != null) return fallback
        }

        // 4. Generic stub
        return mapOf(
            "alertId"   to "airport_security_01",
            "message"   to "You may need to remove your shoes during screening.",
            "riskLevel" to "SENSITIVE"
        )
    }
}
