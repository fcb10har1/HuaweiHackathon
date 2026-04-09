package com.arrivalritual.controller.viewmodel

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.arrivalritual.controller.model.*
import com.arrivalritual.services.GestureDetectionService
import com.arrivalritual.services.LocationService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * AppViewModel.kt
 * Single source of truth for all phone controller state.
 *
 * Extended from the original with:
 *   - speechListening / speechPhrases — Convo Assist speech pipeline state
 *   - autoDetectedLocationType        — scenario resolved from GPS + Places API
 *   - cameraLiftDetected              — set true when gesture service fires
 *   - onGestureCameraLift()           — callback from GestureDetectionService
 *   - onLocationScenarioDetected()    — callback from LocationService polling
 *   - startSpeechAssist()             — triggers Convo Assist pipeline
 */
class AppViewModel : ViewModel() {

    private val _state = MutableStateFlow(AppState())
    val state: StateFlow<AppState> = _state.asStateFlow()

    // Services — initialised lazily once context is available (set from MainActivity)
    private var gestureService: GestureDetectionService? = null
    private var locationService: LocationService? = null

    // ── Service initialisation ─────────────────────────────────────────────────

    fun initServices(context: Context) {
        gestureService  = GestureDetectionService(context)
        locationService = LocationService(context)
    }

    // ── Journey lifecycle ──────────────────────────────────────────────────────

    fun selectCountry(country: Country) {
        _state.update { it.copy(selectedCountry = country) }
    }

    fun startJourney() {
        val country = _state.value.selectedCountry ?: return
        val entry = EventLogEntry(
            scenario    = Scenario.AIRPORT,
            country     = country,
            description = "Journey started → ${country.displayName}",
            type        = EventType.JOURNEY_START
        )
        _state.update {
            it.copy(
                journeyStarted     = true,
                lastTriggeredEvent = entry,
                eventLog           = listOf(entry) + it.eventLog
            )
        }
        // Begin auto-location polling once journey starts
        startLocationPolling()
    }

    fun triggerScenario(scenario: Scenario) {
        val country = _state.value.selectedCountry ?: return
        val entry = EventLogEntry(
            scenario    = scenario,
            country     = country,
            description = "${scenario.displayName} — ${country.displayName}",
            type        = EventType.TRIGGER
        )
        val restricted = scenario == Scenario.TEMPLE || scenario == Scenario.IMMIGRATION

        _state.update {
            it.copy(
                activeScenario         = scenario,
                gestureDetectionActive = restricted,
                lastTriggeredEvent     = entry,
                eventLog               = listOf(entry) + it.eventLog
            )
        }

        // Wire gesture detection to the scenario
        if (restricted) startGestureDetection() else stopGestureDetection()
    }

    fun forceAlert(scenario: Scenario?) {
        val s       = scenario ?: _state.value.activeScenario ?: Scenario.TEMPLE
        val country = _state.value.selectedCountry ?: return
        val entry = EventLogEntry(
            scenario    = s,
            country     = country,
            description = "Force alert sent → ${s.displayName}",
            type        = EventType.ALERT
        )
        _state.update {
            it.copy(
                lastTriggeredEvent = entry,
                eventLog           = listOf(entry) + it.eventLog
            )
        }
    }

    fun toggleWatchConnection() {
        _state.update { it.copy(watchConnected = !it.watchConnected) }
    }

    fun resetAll() {
        stopGestureDetection()
        _state.update {
            AppState(
                eventLog = listOf(
                    EventLogEntry(
                        scenario    = Scenario.AIRPORT,
                        country     = Country.JAPAN,
                        description = "All state reset",
                        type        = EventType.RESET
                    )
                )
            )
        }
    }

    // ── Gesture detection ──────────────────────────────────────────────────────

    /** Called by GestureDetectionService when a camera-lift is detected. */
    fun onGestureCameraLift() {
        val country = _state.value.selectedCountry ?: return
        val scenario = _state.value.activeScenario ?: return
        val entry = EventLogEntry(
            scenario    = scenario,
            country     = country,
            description = "📷 Camera-lift detected in ${scenario.displayName}",
            type        = EventType.ALERT
        )
        _state.update {
            it.copy(
                cameraLiftDetected = true,
                lastTriggeredEvent = entry,
                eventLog           = listOf(entry) + it.eventLog
            )
        }
    }

    fun clearCameraLift() {
        _state.update { it.copy(cameraLiftDetected = false) }
    }

    private fun startGestureDetection() {
        gestureService?.start { onGestureCameraLift() }
    }

    private fun stopGestureDetection() {
        gestureService?.stop()
    }

    // ── Auto-location detection ────────────────────────────────────────────────

    /** Called when LocationService resolves a scenario from GPS + Places API. */
    fun onLocationScenarioDetected(locationType: String) {
        val matched = Scenario.values().find { s ->
            s.name.equals(locationType, ignoreCase = true) ||
            s.geofence.contains(locationType, ignoreCase = true)
        } ?: return

        if (matched == _state.value.activeScenario) return // no change

        val country = _state.value.selectedCountry ?: return
        val entry = EventLogEntry(
            scenario    = matched,
            country     = country,
            description = "📍 Auto-detected: ${matched.displayName}",
            type        = EventType.TRIGGER
        )
        _state.update {
            it.copy(
                activeScenario             = matched,
                autoDetectedLocationType   = locationType,
                gestureDetectionActive     = matched == Scenario.TEMPLE || matched == Scenario.IMMIGRATION,
                lastTriggeredEvent         = entry,
                eventLog                   = listOf(entry) + it.eventLog
            )
        }
        if (matched == Scenario.TEMPLE || matched == Scenario.IMMIGRATION) {
            startGestureDetection()
        } else {
            stopGestureDetection()
        }
    }

    private fun startLocationPolling() {
        viewModelScope.launch {
            // Poll every 30 seconds while journey is active
            while (_state.value.journeyStarted) {
                try {
                    val locationType = locationService?.resolveScenarioFromLocation()
                    if (locationType != null) onLocationScenarioDetected(locationType)
                } catch (_: Exception) { }
                kotlinx.coroutines.delay(30_000L)
            }
        }
    }

    // ── Speech assist ──────────────────────────────────────────────────────────

    fun setSpeechListening(listening: Boolean) {
        _state.update { it.copy(speechListening = listening) }
    }

    fun onSpeechAssistResult(phrases: List<String>) {
        _state.update { it.copy(speechPhrases = phrases, speechListening = false) }
    }

    // ── Cleanup ────────────────────────────────────────────────────────────────

    override fun onCleared() {
        super.onCleared()
        stopGestureDetection()
    }
}
