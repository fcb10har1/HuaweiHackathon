package com.arrivalritual.controller.model

/**
 * TravelModels.kt — v2
 * New fields: handoverActive, reverseActive, gpsContextSuggestion
 */

enum class Country(
    val displayName: String, val flag: String,
    val tagline: String, val countryCode: String, val language: String
) {
    JAPAN("Japan", "\uD83C\uDDEF\uD83C\uDDF5", "Precision, respect, quiet discipline", "JP", "Japanese"),
    THAILAND("Thailand", "\uD83C\uDDF9\uD83C\uDDED", "Warmth, temples, gracious smiles", "TH", "Thai"),
    INDIA("India", "\uD83C\uDDEE\uD83C\uDDF3", "Vibrant, spiritual, warmly chaotic", "IN", "Hindi"),
    UAE("United Arab Emirates", "\uD83C\uDDE6\uD83C\uDDEA", "Modern luxury meets ancient tradition", "AE", "Arabic")
}

enum class Scenario(
    val displayName: String, val icon: String,
    val description: String, val geofence: String
) {
    AIRPORT("Airport Arrival", "✈️", "Immigration, customs, arrival procedures", "airport_arrivals"),
    TEMPLE("Temple / Sacred site", "🏯", "Dress codes, sacred spaces, quiet protocol", "temple_zone"),
    TAXI("Taxi / Transport", "🛺", "Meter etiquette, fare negotiation, payment", "taxi_stand"),
    IMMIGRATION("Immigration desk", "🛂", "Passport control, declarations, customs", "airport_immigration")
}

enum class RiskLevel(val label: String, val emoji: String) {
    NORM("Norm", "🟢"), SENSITIVITY("Sensitive", "🟡"), LEGAL("Legal", "🔴")
}

data class EventLogEntry(
    val timestamp: Long = System.currentTimeMillis(),
    val scenario: Scenario,
    val country: Country,
    val description: String,
    val type: EventType = EventType.TRIGGER
)

enum class EventType { TRIGGER, ALERT, RESET, JOURNEY_START }

data class AppState(
    val selectedCountry: Country? = null,
    val journeyStarted: Boolean = false,
    val activeScenario: Scenario? = null,
    val watchConnected: Boolean = true,
    val gestureDetectionActive: Boolean = false,
    // v2 additions
    val handoverActive: Boolean = false,
    val reverseActive: Boolean = false,
    val gpsContextSuggestion: String? = null,
    val lastTriggeredEvent: EventLogEntry? = null,
    val eventLog: List<EventLogEntry> = emptyList()
)
