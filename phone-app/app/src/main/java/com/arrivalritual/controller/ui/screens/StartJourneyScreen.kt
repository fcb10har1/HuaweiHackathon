package com.arrivalritual.controller.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.arrivalritual.controller.model.Country
import com.arrivalritual.controller.ui.components.*
import com.arrivalritual.controller.ui.theme.*

/**
 * StartJourneyScreen.kt
 * Step 2 — country summary, three feature overview, journey start CTA.
 * Once started, button pivots to open the simulator.
 */
@Composable
fun StartJourneyScreen(
    country: Country,
    journeyStarted: Boolean,
    onStartJourney: () -> Unit,
    onOpenSimulator: () -> Unit,
    onChangeCountry: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Navy900)
            .padding(horizontal = 20.dp)
    ) {
        Spacer(Modifier.height(56.dp))

        Text("Ready to Go", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
        Spacer(Modifier.height(6.dp))
        Text(
            "Your journey is configured and ready to launch.",
            fontSize = 14.sp, color = TextSecondary
        )
        Spacer(Modifier.height(24.dp))

        // ── Country card ─────────────────────────────────────────
        CardSurface(modifier = Modifier.fillMaxWidth()) {
            Row(modifier = Modifier.fillMaxWidth()) {
                Text(country.flag, fontSize = 48.sp)
                Spacer(Modifier.width(16.dp))
                Column {
                    Text(country.displayName, fontSize = 20.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
                    Spacer(Modifier.height(4.dp))
                    Text(country.tagline, fontSize = 12.sp, color = TextSecondary, lineHeight = 18.sp)
                    Spacer(Modifier.height(6.dp))
                    Text("Language: ${country.language}", fontSize = 11.sp, color = TextMuted)
                    Spacer(Modifier.height(8.dp))
                    if (journeyStarted)
                        StatusBadge("● Journey Active", Green400)
                    else
                        StatusBadge("○ Not Started", TextMuted)
                }
            }
        }

        Spacer(Modifier.height(14.dp))

        // ── Three features overview ──────────────────────────────
        CardSurface(modifier = Modifier.fillMaxWidth()) {
            SectionLabel("What Activates on the Watch")
            Spacer(Modifier.height(8.dp))
            InfoRow("✅", "Arrival Checklist — GPS-triggered, offline-ready steps")
            InfoRow("🎤", "Convo Assist — Crown press → phrase in seconds")
            InfoRow("📡", "Local Radar — Passive risk alerts, camera-lift detection")
        }

        Spacer(Modifier.height(14.dp))

        // ── Sensor info ──────────────────────────────────────────
        CardSurface(modifier = Modifier.fillMaxWidth()) {
            SectionLabel("Active Sensors")
            Spacer(Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                SensorBadge("GPS")
                SensorBadge("Mic")
                SensorBadge("Haptics")
                SensorBadge("Gyro")
            }
        }

        Spacer(Modifier.weight(1f))

        if (!journeyStarted) {
            PrimaryButton(
                text = "🚀 Start Journey",
                onClick = onStartJourney,
                modifier = Modifier.fillMaxWidth()
            )
        } else {
            PrimaryButton(
                text = "⚡ Open Simulator",
                onClick = onOpenSimulator,
                modifier = Modifier.fillMaxWidth()
            )
        }
        Spacer(Modifier.height(10.dp))
        GhostButton(
            text = "← Change Country",
            onClick = onChangeCountry,
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(32.dp))
    }
}

@Composable
private fun SensorBadge(label: String) {
    androidx.compose.foundation.layout.Box(
        modifier = Modifier
            .background(Navy700, androidx.compose.foundation.shape.RoundedCornerShape(8.dp))
            .padding(horizontal = 10.dp, vertical = 5.dp)
    ) {
        Text(label, fontSize = 10.sp, color = Cyan400, fontWeight = FontWeight.SemiBold)
    }
}
