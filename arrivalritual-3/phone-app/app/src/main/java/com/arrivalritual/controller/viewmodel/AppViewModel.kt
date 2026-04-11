package com.arrivalritual.controller.viewmodel

import androidx.lifecycle.ViewModel
import com.arrivalritual.controller.model.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

/**
 * AppViewModel.kt — v2
 *
 * New state:
 *   handoverActive     — hand-over mode (screen flipped for other party)
 *   reverseActive      — reverse-translate triggered
 *   gpsContextSuggestion — GPS-suggested context chip label
 */
class AppViewModel : ViewModel() {

    private val _state = MutableStateFlow(AppState())
    val state: StateFlow<AppState> = _state.asStateFlow()

    fun selectCountry(country: Country) {
        _state.update { it.copy(selectedCountry = country) }
    }

    fun startJourney() {
        val country = _state.value.selectedCountry ?: return
        val entry = EventLogEntry(
            scenario = Scenario.AIRPORT, country = country,
            description = "Journey started → ${country.displayName}",
            type = EventType.JOURNEY_START
        )
        _state.update { it.copy(journeyStarted = true, lastTriggeredEvent = entry,
            eventLog = listOf(entry) + it.eventLog) }
    }

    fun triggerScenario(scenario: Scenario) {
        val country = _state.value.selectedCountry ?: return
        val entry = EventLogEntry(scenario = scenario, country = country,
            description = "${scenario.displayName} — ${country.displayName}",
            type = EventType.TRIGGER)
        _state.update {
            it.copy(
                activeScenario = scenario,
                gestureDetectionActive = scenario == Scenario.TEMPLE || scenario == Scenario.IMMIGRATION,
                gpsContextSuggestion = "GPS: ${scenario.geofence}",
                reverseActive = false,
                lastTriggeredEvent = entry,
                eventLog = listOf(entry) + it.eventLog
            )
        }
    }

    /** Simulate the other party responding → reverse-translate flow */
    fun triggerReverseTranslate() {
        val country = _state.value.selectedCountry ?: return
        val scenario = _state.value.activeScenario ?: return
        val entry = EventLogEntry(scenario = scenario, country = country,
            description = "They responded — reverse translating",
            type = EventType.ALERT)
        _state.update { it.copy(reverseActive = true, lastTriggeredEvent = entry,
            eventLog = listOf(entry) + it.eventLog) }
    }

    /** Toggle hand-over mode — flips screen for the other party */
    fun toggleHandover() {
        val handover = !_state.value.handoverActive
        val country = _state.value.selectedCountry ?: return
        val scenario = _state.value.activeScenario ?: return
        val entry = EventLogEntry(scenario = scenario, country = country,
            description = if (handover) "Hand-over mode ON" else "Hand-over mode OFF",
            type = EventType.TRIGGER)
        _state.update { it.copy(handoverActive = handover, lastTriggeredEvent = entry,
            eventLog = listOf(entry) + it.eventLog) }
    }

    fun forceAlert(scenario: Scenario?) {
        val s = scenario ?: _state.value.activeScenario ?: Scenario.TEMPLE
        val country = _state.value.selectedCountry ?: return
        val entry = EventLogEntry(scenario = s, country = country,
            description = "Force alert sent → ${s.displayName}", type = EventType.ALERT)
        _state.update { it.copy(lastTriggeredEvent = entry, eventLog = listOf(entry) + it.eventLog) }
    }

    fun toggleWatchConnection() {
        _state.update { it.copy(watchConnected = !it.watchConnected) }
    }

    fun resetAll() {
        _state.update { AppState() }
    }
}
