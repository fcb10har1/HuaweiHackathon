package com.arrivalritual.controller.model

/**
 * TravelModels.kt
 * All data types and mock data for the phone controller app.
 * Mirrors the watch app's data model for easy sync.
 */

// ── Enums ─────────────────────────────────────────────────────────────────────

enum class Country(
    val displayName: String,
    val flag: String,
    val tagline: String,
    val countryCode: String,
    val language: String
) {
    JAPAN("Japan", "🇯🇵", "Precision, respect, and quiet discipline", "JP", "Japanese"),
    THAILAND("Thailand", "🇹🇭", "Warmth, temples, and gracious smiles", "TH", "Thai"),
    INDIA("India", "🇮🇳", "Vibrant, spiritual, and warmly chaotic", "IN", "Hindi"),
    UAE("United Arab Emirates", "🇦🇪", "Modern luxury meets ancient tradition", "AE", "Arabic"),
    SINGAPORE("Singapore", "🇸🇬", "Where strict rules meet incredible food", "SG", "English"),
    VIETNAM("Vietnam", "🇻🇳", "Ancient temples, bustling streets, and pho", "VN", "Vietnamese"),
    INDONESIA("Indonesia", "🇮🇩", "17,000 islands of culture, spice, and ceremony", "ID", "Indonesian"),
    MALAYSIA("Malaysia", "🇲🇾", "Multicultural melting pot of Asia", "MY", "Malay"),
    LAOS("Laos", "🇱🇦", "Landlocked serenity of temples and rivers", "LA", "Lao"),
    CAMBODIA("Cambodia", "🇰🇭", "Ancient Khmer empire and resilient spirit", "KH", "Khmer")
}

enum class Scenario(
    val displayName: String,
    val icon: String,
    val description: String,
    val geofence: String
) {
    AIRPORT(
        "Airport Arrival",
        "✈️",
        "Immigration, customs, and arrival procedures",
        "airport_arrivals"
    ),
    TEMPLE(
        "Temple / Sacred Site",
        "🏯",
        "Dress codes, sacred spaces, and quiet protocol",
        "temple_zone"
    ),
    TAXI(
        "Taxi / Transport",
        "🛺",
        "Meter etiquette, fare negotiation, payment norms",
        "taxi_stand"
    ),
    IMMIGRATION(
        "Immigration Desk",
        "🛂",
        "Passport control, declarations, and customs",
        "airport_immigration"
    )
}

enum class RiskLevel(val label: String, val emoji: String) {
    NORM("Norm", "🟢"),
    SENSITIVITY("Sensitive", "🟡"),
    LEGAL("Legal", "🔴")
}

// ── Data Classes ──────────────────────────────────────────────────────────────

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
    val lastTriggeredEvent: EventLogEntry? = null,
    val eventLog: List<EventLogEntry> = emptyList(),
    /** True while WhisperService is recording ambient audio (crown-press active) */
    val speechListening: Boolean = false,
    /** Phrases returned by SpeechAssistService after a crown-press session */
    val speechPhrases: List<String> = emptyList(),
    /** Scenario ID last resolved automatically from GPS + Places API */
    val autoDetectedLocationType: String? = null,
    /** True immediately after the gesture service fires a camera-lift event */
    val cameraLiftDetected: Boolean = false
)
