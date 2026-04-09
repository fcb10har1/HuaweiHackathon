package com.arrivalritual.controller

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.arrivalritual.comm.MessageRouter
import com.arrivalritual.comm.MessageType
import com.arrivalritual.controller.navigation.Routes
import com.arrivalritual.controller.ui.screens.*
import com.arrivalritual.controller.ui.theme.*
import com.arrivalritual.controller.viewmodel.AppViewModel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * MainActivity
 *
 * Single Activity — NavHost + bottom navigation.
 *
 * Now also:
 *  - Passes application context to MessageRouter (enables real data layer).
 *  - Initialises GestureDetectionService and LocationService via ViewModel.
 *  - Requests location + audio permissions on first launch.
 *  - Observes cameraLiftDetected state to send an alert to the watch.
 */
class MainActivity : ComponentActivity() {

    private val viewModel: AppViewModel by viewModels()

    // Permission launcher — requests FINE_LOCATION + RECORD_AUDIO together
    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { /* permissions handled silently; services degrade gracefully if denied */ }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialise services with application context
        viewModel.initServices(applicationContext)

        // Build router with real context (enables JSON + LLM data layer)
        val router = MessageRouter(applicationContext)

        // Request runtime permissions
        requestRuntimePermissions()

        // Smoke-test the router on startup (logged to Logcat)
        CoroutineScope(Dispatchers.IO).launch {
            android.util.Log.d("RouterTest", "PING         → ${router.route(MessageType.PING.name)}")
            android.util.Log.d("RouterTest", "NEXT_STEP    → ${router.route(MessageType.REQUEST_NEXT_STEP.name, mapOf("country" to "Japan", "currentStepIndex" to 0))}")
            android.util.Log.d("RouterTest", "CONTEXT_ALERT→ ${router.route(MessageType.REQUEST_CONTEXT_ALERT.name, mapOf("country" to "Thailand", "locationType" to "temple"))}")
            android.util.Log.d("RouterTest", "CONVO_OPTIONS→ ${router.route(MessageType.REQUEST_CONVO_OPTIONS.name, mapOf("country" to "Japan", "context" to "taxi"))}")
        }

        setContent {
            ArrivalRitualTheme {
                val navController = rememberNavController()
                val state by viewModel.state.collectAsState()
                val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route

                // React to camera-lift gesture: send alert to watch + log event
                LaunchedEffect(state.cameraLiftDetected) {
                    if (state.cameraLiftDetected) {
                        val country = state.selectedCountry?.displayName ?: "Japan"
                        val locationType = state.activeScenario?.geofence ?: "temple_zone"
                        // TODO: send via Huawei WearEngine bridge:
                        // watchBridge.send(router.route(MessageType.GESTURE_DETECTED.name,
                        //     mapOf("country" to country, "locationType" to locationType)))
                        viewModel.clearCameraLift()
                    }
                }

                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Navy900)
                ) {
                    Box(modifier = Modifier.weight(1f)) {
                        NavHost(
                            navController   = navController,
                            startDestination = Routes.COUNTRY_SELECTION
                        ) {
                            composable(Routes.COUNTRY_SELECTION) {
                                CountrySelectionScreen(
                                    selectedCountry = state.selectedCountry,
                                    onCountrySelect = viewModel::selectCountry,
                                    onContinue = {
                                        if (state.selectedCountry != null)
                                            navController.navigate(Routes.START_JOURNEY)
                                    }
                                )
                            }

                            composable(Routes.START_JOURNEY) {
                                val country = state.selectedCountry ?: return@composable
                                StartJourneyScreen(
                                    country        = country,
                                    journeyStarted = state.journeyStarted,
                                    onStartJourney = viewModel::startJourney,
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
                                    onTriggerScenario      = viewModel::triggerScenario,
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

                    // ── Bottom Navigation ───────────────────────────────────────
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Navy800)
                            .padding(bottom = 4.dp),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        listOf(
                            Triple(Routes.COUNTRY_SELECTION,  "🌍", "Country"),
                            Triple(Routes.START_JOURNEY,      "🚀", "Journey"),
                            Triple(Routes.SIMULATE_TRIGGERS,  "⚡", "Simulate"),
                            Triple(Routes.DEBUG_PANEL,        "🔧", "Debug"),
                        ).forEach { (route, icon, label) ->
                            val active = currentRoute == route
                            Column(
                                modifier = Modifier
                                    .clickable {
                                        if (route == Routes.SIMULATE_TRIGGERS && !state.journeyStarted) return@clickable
                                        navController.navigate(route) {
                                            launchSingleTop = true
                                            restoreState    = true
                                        }
                                    }
                                    .padding(vertical = 10.dp, horizontal = 16.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(icon, fontSize = 18.sp)
                                Spacer(Modifier.height(2.dp))
                                Text(
                                    label,
                                    fontSize   = 9.sp,
                                    color      = if (active) Cyan400 else TextMuted,
                                    fontWeight = if (active) FontWeight.Bold else FontWeight.Normal
                                )
                                if (active) {
                                    Spacer(Modifier.height(3.dp))
                                    Box(
                                        modifier = Modifier
                                            .size(4.dp)
                                            .background(Cyan400, androidx.compose.foundation.shape.CircleShape)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Permissions ────────────────────────────────────────────────────────────

    private fun requestRuntimePermissions() {
        val needed = buildList {
            if (!granted(Manifest.permission.ACCESS_FINE_LOCATION))   add(Manifest.permission.ACCESS_FINE_LOCATION)
            if (!granted(Manifest.permission.ACCESS_COARSE_LOCATION)) add(Manifest.permission.ACCESS_COARSE_LOCATION)
            if (!granted(Manifest.permission.RECORD_AUDIO))           add(Manifest.permission.RECORD_AUDIO)
        }
        if (needed.isNotEmpty()) permissionLauncher.launch(needed.toTypedArray())
    }

    private fun granted(permission: String) =
        ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
}
