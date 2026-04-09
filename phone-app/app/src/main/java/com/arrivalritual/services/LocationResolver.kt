package com.arrivalritual.services

import com.arrivalritual.data.CountryPackRepository
import com.arrivalritual.data.FallbackAlertData
import com.arrivalritual.data.ScenarioPack

/**
 * LocationResolver
 *
 * Offline keyword-based fallback for matching a free-form locationType string
 * (sent by the watch) to a ScenarioPack inside the country JSON pack.
 *
 * This is the fallback path used when the OpenAI API is unreachable.
 * The primary path is LlmService.generateContextAlert().
 */
class LocationResolver(private val repository: CountryPackRepository) {

    /** Returns the best-matching ScenarioPack for [locationType], or null if nothing matches. */
    fun resolve(country: String, locationType: String): ScenarioPack? =
        repository.findScenario(country, locationType)

    /**
     * Returns a random fallback alert from the matched scenario as a wire-ready map,
     * or null if no scenario or alerts are found.
     */
    fun getFallbackAlert(country: String, locationType: String): Map<String, Any>? {
        val scenario = resolve(country, locationType) ?: return null
        val alert: FallbackAlertData = scenario.fallbackAlerts.randomOrNull() ?: return null
        return mapOf(
            "alertId"   to alert.alertId,
            "message"   to alert.message,
            "riskLevel" to alert.riskLevel
        )
    }

    /**
     * Returns all fallback alerts for a scenario as wire-ready maps.
     * Useful when you want to cycle through multiple alerts.
     */
    fun getAllFallbackAlerts(country: String, locationType: String): List<Map<String, Any>> {
        val scenario = resolve(country, locationType) ?: return emptyList()
        return scenario.fallbackAlerts.map { alert ->
            mapOf(
                "alertId"   to alert.alertId,
                "message"   to alert.message,
                "riskLevel" to alert.riskLevel
            )
        }
    }
}
