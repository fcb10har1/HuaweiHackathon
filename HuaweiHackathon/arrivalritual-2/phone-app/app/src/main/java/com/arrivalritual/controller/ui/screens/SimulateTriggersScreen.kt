package com.arrivalritual.controller.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.arrivalritual.controller.model.Country
import com.arrivalritual.controller.model.EventLogEntry
import com.arrivalritual.controller.model.EventType
import com.arrivalritual.controller.model.Scenario
import com.arrivalritual.controller.ui.components.*
import com.arrivalritual.controller.ui.theme.*
import java.text.SimpleDateFormat
import java.util.*

/**
 * SimulateTriggersScreen.kt
 * Step 3 — live demo control panel.
 * Fire any scenario, watch the event log update in real time.
 * Shows gesture detection status for restricted zones.
 */
@Composable
fun SimulateTriggersScreen(
    country: Country,
    activeScenario: Scenario?,
    gestureDetectionActive: Boolean,
    eventLog: List<EventLogEntry>,
    onTriggerScenario: (Scenario) -> Unit,
    onReset: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Navy900)
            .padding(horizontal = 20.dp)
    ) {
        Spacer(Modifier.height(56.dp))

        // ── Header ────────────────────────────────────────────────
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text("Simulator", fontSize = 26.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                Text("${country.flag} ${country.displayName}", fontSize = 13.sp, color = TextSecondary)
            }
            GhostButton(text = "Reset", onClick = onReset)
        }

        Spacer(Modifier.height(16.dp))

        // ── Active scenario banner ────────────────────────────────
        if (activeScenario != null) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(Navy700)
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(activeScenario.icon, fontSize = 22.sp)
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text("Active Scenario", fontSize = 10.sp, color = TextMuted)
                    Text(activeScenario.displayName, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Cyan400)
                    Text("Geofence: ${activeScenario.geofence}", fontSize = 9.sp, color = TextMuted)
                }
                StatusBadge("● LIVE", Green400)
            }
            Spacer(Modifier.height(10.dp))
        }

        // ── Gesture detection status ──────────────────────────────
        if (gestureDetectionActive) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(Red400.copy(alpha = 0.1f))
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("📷", fontSize = 14.sp)
                Spacer(Modifier.width(8.dp))
                Text(
                    "Camera-lift gesture detection active",
                    fontSize = 11.sp,
                    color = Red400,
                    modifier = Modifier.weight(1f)
                )
                StatusBadge("Gyro ON", Red400)
            }
            Spacer(Modifier.height(10.dp))
        }

        SectionLabel("Trigger Scenarios")

        // ── Scenario cards ────────────────────────────────────────
        Scenario.values().forEach { scenario ->
            ScenarioCard(
                scenario = scenario,
                isActive = activeScenario == scenario,
                onClick = { onTriggerScenario(scenario) }
            )
            Spacer(Modifier.height(8.dp))
        }

        Spacer(Modifier.height(8.dp))

        // ── Event log ─────────────────────────────────────────────
        if (eventLog.isNotEmpty()) {
            SectionLabel("Event Log")
            LazyColumn(modifier = Modifier.weight(1f)) {
                items(eventLog.take(20)) { entry ->
                    EventRow(entry)
                }
            }
        } else {
            Spacer(Modifier.weight(1f))
        }

        Spacer(Modifier.height(16.dp))
    }
}

@Composable
private fun ScenarioCard(scenario: Scenario, isActive: Boolean, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(if (isActive) Navy700 else Navy800)
            .clickable { onClick() }
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(46.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(if (isActive) Cyan400.copy(alpha = 0.2f) else Navy600),
            contentAlignment = Alignment.Center
        ) {
            Text(scenario.icon, fontSize = 20.sp)
        }
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            Text(
                scenario.displayName,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = if (isActive) TextPrimary else TextSecondary
            )
            Text(scenario.description, fontSize = 10.sp, color = TextMuted, lineHeight = 15.sp)
            if (scenario == Scenario.TEMPLE || scenario == Scenario.IMMIGRATION) {
                Spacer(Modifier.height(4.dp))
                Text("📷 Camera-lift detection", fontSize = 9.sp, color = Red400.copy(alpha = 0.8f))
            }
        }
        if (isActive)
            Text("●", fontSize = 12.sp, color = Cyan400)
        else
            Text("›", fontSize = 18.sp, color = TextMuted)
    }
}

@Composable
private fun EventRow(entry: EventLogEntry) {
    val fmt = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
    val typeColor = when (entry.type) {
        EventType.ALERT        -> Red400
        EventType.JOURNEY_START -> Green400
        EventType.RESET        -> TextMuted
        else                   -> Cyan400
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            fmt.format(Date(entry.timestamp)),
            fontSize = 10.sp, color = TextMuted,
            modifier = Modifier.width(54.dp)
        )
        Text(entry.scenario.icon, fontSize = 12.sp, modifier = Modifier.width(20.dp))
        Spacer(Modifier.width(6.dp))
        Text(entry.description, fontSize = 11.sp, color = typeColor, modifier = Modifier.weight(1f))
    }
}
