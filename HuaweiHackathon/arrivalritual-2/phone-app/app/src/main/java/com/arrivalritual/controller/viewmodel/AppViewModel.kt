package com.arrivalritual.controller.viewmodel

import androidx.lifecycle.ViewModel
import com.arrivalritual.controller.model.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

/**
 * AppViewModel.kt
 * Single source of truth for all phone controller state.
 * Screens observe via StateFlow — no backend required.
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
            scenario = Scenario.AIRPORT,
            country = country,
            description = "Journey started → ${country.displayName}",
            type = EventType.JOURNEY_START
        )
        _state.update {
            it.copy(
                journeyStarted = true,
                lastTriggeredEvent = entry,
                eventLog = listOf(entry) + it.eventLog
            )
        }
    }

    fun triggerScenario(scenario: Scenario) {
        val country = _state.value.selectedCountry ?: return
        val entry = EventLogEntry(
            scenario = scenario,
            country = country,
            description = "${scenario.displayName} — ${country.displayName}",
            type = EventType.TRIGGER
        )
        _state.update {
            it.copy(
                activeScenario = scenario,
                gestureDetectionActive = scenario == Scenario.TEMPLE || scenario == Scenario.IMMIGRATION,
                lastTriggeredEvent = entry,
                eventLog = listOf(entry) + it.eventLog
            )
        }
    }

    fun forceAlert(scenario: Scenario?) {
        val s = scenario ?: _state.value.activeScenario ?: Scenario.TEMPLE
        val country = _state.value.selectedCountry ?: return
        val entry = EventLogEntry(
            scenario = s,
            country = country,
            description = "Force alert sent → ${s.displayName}",
            type = EventType.ALERT
        )
        _state.update {
            it.copy(
                lastTriggeredEvent = entry,
                eventLog = listOf(entry) + it.eventLog
            )
        }
    }

    fun toggleWatchConnection() {
        _state.update { it.copy(watchConnected = !it.watchConnected) }
    }

    fun resetAll() {
        _state.update {
            AppState(
                eventLog = listOf(
                    EventLogEntry(
                        scenario = Scenario.AIRPORT,
                        country = Country.JAPAN,
                        description = "All state reset",
                        type = EventType.RESET
                    )
                )
            )
        }
    }
}
