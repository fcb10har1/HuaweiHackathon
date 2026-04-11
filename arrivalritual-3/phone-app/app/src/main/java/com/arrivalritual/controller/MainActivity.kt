package com.arrivalritual.controller

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.arrivalritual.controller.navigation.Routes
import com.arrivalritual.controller.ui.screens.*
import com.arrivalritual.controller.ui.theme.*
import com.arrivalritual.controller.viewmodel.AppViewModel

class MainActivity : ComponentActivity() {

    private val viewModel: AppViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            ArrivalRitualTheme {
                val navController = rememberNavController()
                val state by viewModel.state.collectAsState()
                val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route

                Column(modifier = Modifier.fillMaxSize().background(Navy900)) {
                    Box(modifier = Modifier.weight(1f)) {
                        NavHost(navController = navController, startDestination = Routes.COUNTRY_SELECTION) {

                            composable(Routes.COUNTRY_SELECTION) {
                                CountrySelectionScreen(
                                    selectedCountry = state.selectedCountry,
                                    onCountrySelect  = viewModel::selectCountry,
                                    onContinue = {
                                        if (state.selectedCountry != null)
                                            navController.navigate(Routes.START_JOURNEY)
                                    }
                                )
                            }

                            composable(Routes.START_JOURNEY) {
                                val country = state.selectedCountry ?: return@composable
                                StartJourneyScreen(
                                    country         = country,
                                    journeyStarted  = state.journeyStarted,
                                    onStartJourney  = viewModel::startJourney,
                                    onOpenSimulator = { navController.navigate(Routes.SIMULATE_TRIGGERS) },
                                    onChangeCountry = { navController.popBackStack() }
                                )
                            }

                            composable(Routes.SIMULATE_TRIGGERS) {
                                val country = state.selectedCountry ?: return@composable
                                SimulateTriggersScreen(
                                    country                = country,
                                    activeScenario         = state.activeScenario,
                                    gestureDetectionActive = state.gestureDetectionActive,
                                    eventLog               = state.eventLog,
                                    handoverActive         = state.handoverActive,
                                    onTriggerScenario      = viewModel::triggerScenario,
                                    onTriggerReverse       = viewModel::triggerReverseTranslate,
                                    onToggleHandover       = viewModel::toggleHandover,
                                    onReset = {
                                        viewModel.resetAll()
                                        navController.navigate(Routes.COUNTRY_SELECTION) {
                                            popUpTo(0) { inclusive = true }
                                        }
                                    }
                                )
                            }

                            composable(Routes.DEBUG_PANEL) {
                                DebugPanelScreen(
                                    state         = state,
                                    onForceAlert  = { viewModel.forceAlert(state.activeScenario) },
                                    onToggleWatch = viewModel::toggleWatchConnection,
                                    onResetAll    = {
                                        viewModel.resetAll()
                                        navController.navigate(Routes.COUNTRY_SELECTION) {
                                            popUpTo(0) { inclusive = true }
                                        }
                                    }
                                )
                            }
                        }
                    }

                    // ── Bottom Nav ──────────────────────────────────
                    Row(
                        modifier = Modifier.fillMaxWidth().background(Navy800)
                            .padding(bottom = 4.dp),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        listOf(
                            Triple(Routes.COUNTRY_SELECTION, "🌍", "Country"),
                            Triple(Routes.START_JOURNEY,     "🚀", "Journey"),
                            Triple(Routes.SIMULATE_TRIGGERS, "⚡", "Simulate"),
                            Triple(Routes.DEBUG_PANEL,       "🔧", "Debug"),
                        ).forEach { (route, icon, label) ->
                            val active = currentRoute == route
                            Column(
                                modifier = Modifier
                                    .clickable {
                                        if (route == Routes.SIMULATE_TRIGGERS && !state.journeyStarted) return@clickable
                                        navController.navigate(route) { launchSingleTop = true; restoreState = true }
                                    }
                                    .padding(vertical = 10.dp, horizontal = 16.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(icon, fontSize = 18.sp)
                                Spacer(Modifier.height(2.dp))
                                Text(label, fontSize = 9.sp,
                                    color = if (active) Cyan400 else TextMuted,
                                    fontWeight = if (active) FontWeight.Bold else FontWeight.Normal)
                                if (active) {
                                    Spacer(Modifier.height(3.dp))
                                    Box(modifier = Modifier.size(4.dp).clip(CircleShape).background(Cyan400))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
