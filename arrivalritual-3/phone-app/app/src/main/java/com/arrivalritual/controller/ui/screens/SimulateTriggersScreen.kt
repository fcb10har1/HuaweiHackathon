package com.arrivalritual.controller.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
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
 * SimulateTriggersScreen.kt  — v2
 *
 * New in this version:
 *   1. Hand-over mode toggle — fires BLE event to flip watch/phone screen for other party
 *   2. Reverse-translate trigger — simulates the other party responding
 *   3. GPS auto-suggest indicator per scenario
 *   4. Camera-lift detection badge for restricted zones
 */
@Composable
fun SimulateTriggersScreen(
    country: Country,
    activeScenario: Scenario?,
    gestureDetectionActive: Boolean,
    eventLog: List<EventLogEntry>,
    onTriggerScenario: (Scenario) -> Unit,
    onTriggerReverse: () -> Unit,
    onToggleHandover: () -> Unit,
    handoverActive: Boolean,
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

        Spacer(Modifier.height(14.dp))

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
                    Text("Active scenario", fontSize = 10.sp, color = TextMuted)
                    Text(activeScenario.displayName, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Cyan400)
                    // GPS auto-suggest label
                    Text("GPS: ${activeScenario.geofence}", fontSize = 9.sp, color = Green400.copy(alpha = 0.7f))
                }
                StatusBadge("● LIVE", Green400)
            }
            Spacer(Modifier.height(10.dp))
        }

        // ── Camera-lift detection banner ──────────────────────────
        if (gestureDetectionActive) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(Red400.copy(alpha = 0.08f))
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("📷", fontSize = 13.sp)
                Spacer(Modifier.width(8.dp))
                Text("Camera-lift detection active", fontSize = 11.sp, color = Red400, modifier = Modifier.weight(1f))
                StatusBadge("Gyro ON", Red400)
            }
            Spacer(Modifier.height(10.dp))
        }

        // ── Hand-over mode toggle ─────────────────────────────────
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(Navy800)
                .clickable { onToggleHandover() }
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(RoundedCornerShape(9.dp))
                    .background(Cyan400.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center
            ) { Text("↕", fontSize = 16.sp, color = Cyan400) }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text("Hand-over mode", fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = TextPrimary)
                Text(
                    if (handoverActive) "Screen flipped — they can read & tap reply"
                    else "Flip screen so other party can read & reply",
                    fontSize = 10.sp, color = TextMuted
                )
            }
            StatusBadge(if (handoverActive) "● ON" else "○ OFF", if (handoverActive) Cyan400 else TextMuted)
        }
        Spacer(Modifier.height(10.dp))

        SectionLabel("Trigger scenarios")

        // ── Scenario cards ────────────────────────────────────────
        Scenario.values().forEach { scenario ->
            ScenarioCard(
                scenario = scenario,
                isActive = activeScenario == scenario,
                onClick = { onTriggerScenario(scenario) }
            )
            Spacer(Modifier.height(8.dp))
        }

        // ── Reverse-translate trigger ─────────────────────────────
        if (activeScenario != null) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(Navy800)
                    .clickable { onTriggerReverse() }
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(Amber400.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) { Text("↩", fontSize = 18.sp, color = Amber400) }
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text("Simulate: they respond", fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = TextPrimary)
                    Text("Triggers reverse-translate on both devices", fontSize = 10.sp, color = TextMuted)
                }
                Text("›", fontSize = 18.sp, color = Amber400)
            }
            Spacer(Modifier.height(10.dp))
        }

        // ── Event log ─────────────────────────────────────────────
        if (eventLog.isNotEmpty()) {
            SectionLabel("Event log")
            LazyColumn(modifier = Modifier.weight(1f)) {
                items(eventLog.take(20)) { entry -> EventRow(entry) }
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
            .clip(RoundedCornerShape(14.dp))
            .background(if (isActive) Navy700 else Navy800)
            .clickable { onClick() }
            .padding(13.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier.size(44.dp).clip(RoundedCornerShape(11.dp))
                .background(if (isActive) Cyan400.copy(alpha = 0.2f) else Navy600),
            contentAlignment = Alignment.Center
        ) { Text(scenario.icon, fontSize = 19.sp) }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(scenario.displayName, fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
                color = if (isActive) TextPrimary else TextSecondary)
            Text(scenario.description, fontSize = 10.sp, color = TextMuted, lineHeight = 14.sp)
            // GPS auto-suggest indicator
            Text("📍 GPS: ${scenario.geofence}", fontSize = 8.sp, color = Green400.copy(alpha = 0.6f))
            if (scenario == Scenario.TEMPLE || scenario == Scenario.IMMIGRATION) {
                Text("📷 Camera-lift detection", fontSize = 8.sp, color = Red400.copy(alpha = 0.7f))
            }
        }
        Text(if (isActive) "●" else "›", fontSize = if (isActive) 12.sp else 18.sp,
            color = if (isActive) Cyan400 else TextMuted)
    }
}

@Composable
private fun EventRow(entry: EventLogEntry) {
    val fmt = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
    val typeColor = when (entry.type) {
        EventType.ALERT         -> Red400
        EventType.JOURNEY_START -> Green400
        EventType.RESET         -> TextMuted
        else                    -> Cyan400
    }
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(fmt.format(Date(entry.timestamp)), fontSize = 10.sp, color = TextMuted,
            modifier = Modifier.width(54.dp))
        Text(entry.scenario.icon, fontSize = 11.sp, modifier = Modifier.width(18.dp))
        Spacer(Modifier.width(6.dp))
        Text(entry.description, fontSize = 11.sp, color = typeColor, modifier = Modifier.weight(1f))
    }
}
