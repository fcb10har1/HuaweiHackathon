package com.arrivalritual.data

/**
 * CountryPack.kt
 * Data classes that mirror the JSON schema in assets/countries/{code}.json.
 * One file per country; Gson deserialises directly into these types.
 */

data class CountryPack(
    val countryCode: String,
    val name: String,
    val flag: String,
    val tagline: String,
    val language: LanguageInfo,
    val scenarios: List<ScenarioPack>
)

data class LanguageInfo(
    val name: String,
    /** BCP-47 locale tag, e.g. "ja-JP" */
    val locale: String,
    val nativeScriptName: String
)

data class ScenarioPack(
    val id: String,
    val displayName: String,
    val icon: String,
    val description: String,
    val geofence: String,
    /** Keywords used for offline fuzzy matching against the watch's locationType string */
    val locationKeywords: List<String>,
    /** Ordered arrival checklist steps shown on the watch */
    val arrivalSteps: List<ArrivalStepData>,
    /** Pre-authored alerts served when the LLM is unavailable */
    val fallbackAlerts: List<FallbackAlertData>,
    /** Phrases shown in Convo Assist, each with English + native script + romanization */
    val phrases: List<ConvoPhrase>
)

data class ArrivalStepData(
    val stepIndex: Int,
    val title: String,
    val description: String,
    /** "NORM" | "SENSITIVE" | "LEGAL" */
    val riskLevel: String
)

data class FallbackAlertData(
    val alertId: String,
    val message: String,
    /** "NORM" | "SENSITIVE" | "LEGAL" */
    val riskLevel: String
)

data class ConvoPhrase(
    val english: String,
    val nativeScript: String,
    val romanized: String
)
