package com.arrivalritual.controller.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Divider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.arrivalritual.controller.model.AppState
import com.arrivalritual.controller.ui.components.*
import com.arrivalritual.controller.ui.theme.*

/**
 * DebugPanelScreen.kt
 * Full state inspector — for internal use during demo prep.
 * Shows all live state vars, watch connection toggle, force alert,
 * gesture detection status, and hard reset.
 */
@Composable
fun DebugPanelScreen(
    state: AppState,
    onForceAlert: () -> Unit,
    onToggleWatch: () -> Unit,
    onResetAll: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Navy900)
            .padding(horizontal = 20.dp)
            .verticalScroll(rememberScrollState())
    ) {
        Spacer(Modifier.height(56.dp))
        Text("Debug Panel", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
        Text("Internal state inspector — not shown in demo", fontSize = 12.sp, color = TextMuted)

        Spacer(Modifier.height(20.dp))

        // ── App State ─────────────────────────────────────────────
        CardSurface(modifier = Modifier.fillMaxWidth()) {
            SectionLabel("App State")
            Spacer(Modifier.height(6.dp))
            DebugRow("Selected Country",  state.selectedCountry?.displayName ?: "None")
            DebugRow("Journey Started",   state.journeyStarted.toString())
            DebugRow("Active Scenario",   state.activeScenario?.displayName ?: "None")
            DebugRow("Active Geofence",   state.activeScenario?.geofence ?: "None")
            DebugRow("Gesture Detection", state.gestureDetectionActive.toString())
            DebugRow("Watch Connected",   state.watchConnected.toString())
            DebugRow("Events Logged",     state.eventLog.size.toString())
            DebugRow("Last Event",        state.lastTriggeredEvent?.description ?: "None", small = true)
        }

        Spacer(Modifier.height(14.dp))

        // ── Watch Connection ──────────────────────────────────────
        CardSurface(modifier = Modifier.fillMaxWidth()) {
            SectionLabel("Watch Connection")
            Spacer(Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                StatusBadge(
                    if (state.watchConnected) "● Connected" else "○ Disconnected",
                    if (state.watchConnected) Green400 else Red400
                )
                Spacer(Modifier.weight(1f))
                GhostButton(
                    text = if (state.watchConnected) "Disconnect" else "Connect",
                    onClick = onToggleWatch
                )
            }
            Spacer(Modifier.height(8.dp))
            Text(
                if (state.watchConnected)
                    "Watch is receiving scenario triggers and haptic commands."
                else
                    "Watch is disconnected. Triggers will not be delivered.",
                fontSize = 11.sp,
                color = TextMuted,
                lineHeight = 16.sp
            )
        }

        Spacer(Modifier.height(14.dp))

        // ── Sensor Status ─────────────────────────────────────────
        CardSurface(modifier = Modifier.fillMaxWidth()) {
            SectionLabel("Sensor Status")
            Spacer(Modifier.height(6.dp))
            SensorRow("GPS",       active = state.journeyStarted)
            SensorRow("Microphone",active = state.activeScenario != null)
            SensorRow("Haptics",   active = state.watchConnected)
            SensorRow("Gyroscope", active = state.gestureDetectionActive)
            SensorRow("Accelerometer", active = state.journeyStarted)
        }

        Spacer(Modifier.height(14.dp))

        // ── Force Actions ─────────────────────────────────────────
        CardSurface(modifier = Modifier.fillMaxWidth()) {
            SectionLabel("Force Actions")
            Spacer(Modifier.height(8.dp))
            PrimaryButton(
                text = "⚠️ Force Alert to Watch",
                onClick = onForceAlert,
                modifier = Modifier.fillMaxWidth(),
                color = Amber400
            )
        }

        Spacer(Modifier.height(14.dp))

        // ── Danger Zone ───────────────────────────────────────────
        CardSurface(modifier = Modifier.fillMaxWidth()) {
            SectionLabel("Danger Zone")
            Spacer(Modifier.height(8.dp))
            PrimaryButton(
                text = "🗑 Reset All State",
                onClick = onResetAll,
                modifier = Modifier.fillMaxWidth(),
                color = Red400
            )
        }

        Spacer(Modifier.height(40.dp))
    }
}

@Composable
private fun DebugRow(label: String, value: String, small: Boolean = false) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.Top
    ) {
        Text(label, fontSize = 12.sp, color = TextSecondary, modifier = Modifier.weight(1f))
        Text(
            value,
            fontSize = if (small) 10.sp else 12.sp,
            color = Cyan400,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.weight(1f),
            textAlign = androidx.compose.ui.text.style.TextAlign.End
        )
    }
    Divider(color = Navy700, thickness = 0.5.dp)
}

@Composable
private fun SensorRow(name: String, active: Boolean) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 5.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(name, fontSize = 12.sp, color = TextSecondary)
        StatusBadge(
            if (active) "● Active" else "○ Idle",
            if (active) Green400 else TextMuted
        )
    }
}
