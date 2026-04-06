package com.arrivalritual.controller.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// ── Colour palette ─────────────────────────────────────────────────────────────
val Navy900    = Color(0xFF0A0E1A)
val Navy800    = Color(0xFF111827)
val Navy700    = Color(0xFF1C2638)
val Navy600    = Color(0xFF243044)
val Cyan400    = Color(0xFF4FC3F7)
val Cyan300    = Color(0xFF81D4FA)
val Amber400   = Color(0xFFFFB300)
val Red400     = Color(0xFFEF5350)
val Green400   = Color(0xFF81C784)
val TextPrimary   = Color(0xFFEEEEEE)
val TextSecondary = Color(0xFF9E9E9E)
val TextMuted     = Color(0xFF616161)

private val DarkColors = darkColorScheme(
    primary          = Cyan400,
    onPrimary        = Navy900,
    secondary        = Amber400,
    onSecondary      = Navy900,
    background       = Navy900,
    onBackground     = TextPrimary,
    surface          = Navy800,
    onSurface        = TextPrimary,
    surfaceVariant   = Navy700,
    onSurfaceVariant = TextSecondary,
    error            = Red400,
)

@Composable
fun ArrivalRitualTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = DarkColors, content = content)
}
