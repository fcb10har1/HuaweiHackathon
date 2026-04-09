package com.arrivalritual.services

import android.content.Context
import org.json.JSONObject

/**
 * AlertCacheManager
 *
 * Persists LLM-generated context alerts to SharedPreferences so the same
 * country + locationType combination is never sent to the API twice.
 *
 * Cache key format: "{country_lower}:{locationType_lower}"
 * Cache value: JSON string with alertId, message, riskLevel fields.
 */
class AlertCacheManager(context: Context?) {

    private val prefs = context?.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun get(country: String, locationType: String): LlmAlertResponse? {
        val raw = prefs?.getString(key(country, locationType), null) ?: return null
        return try {
            val obj = JSONObject(raw)
            LlmAlertResponse(
                alertId  = obj.getString("alertId"),
                message  = obj.getString("message"),
                riskLevel = obj.getString("riskLevel")
            )
        } catch (e: Exception) {
            null
        }
    }

    fun put(country: String, locationType: String, response: LlmAlertResponse) {
        val value = JSONObject().apply {
            put("alertId",   response.alertId)
            put("message",   response.message)
            put("riskLevel", response.riskLevel)
        }.toString()
        prefs?.edit()?.putString(key(country, locationType), value)?.apply()
    }

    fun clear() {
        prefs?.edit()?.clear()?.apply()
    }

    private fun key(country: String, locationType: String) =
        "${country.lowercase().trim()}:${locationType.lowercase().trim()}"

    companion object {
        private const val PREFS_NAME = "arrival_ritual_alert_cache"
    }
}
