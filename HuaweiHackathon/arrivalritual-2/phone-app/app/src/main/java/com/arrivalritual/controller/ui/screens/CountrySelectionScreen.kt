package com.arrivalritual.controller.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.arrivalritual.controller.model.Country
import com.arrivalritual.controller.ui.components.PrimaryButton
import com.arrivalritual.controller.ui.components.SectionLabel
import com.arrivalritual.controller.ui.theme.*

/**
 * CountrySelectionScreen.kt
 * Step 1 — presenter picks destination country.
 * 2-column grid, selection state, continue CTA.
 */
@Composable
fun CountrySelectionScreen(
    selectedCountry: Country?,
    onCountrySelect: (Country) -> Unit,
    onContinue: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Navy900)
            .padding(horizontal = 20.dp)
    ) {
        Spacer(Modifier.height(56.dp))

        Text("Choose Destination", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = TextPrimary)
        Spacer(Modifier.height(6.dp))
        Text(
            "Select the country your traveller is visiting.",
            fontSize = 14.sp, color = TextSecondary, lineHeight = 20.sp
        )
        Spacer(Modifier.height(28.dp))
        SectionLabel("Destinations")

        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.weight(1f)
        ) {
            items(Country.values().toList()) { country ->
                CountryCard(
                    country = country,
                    isSelected = selectedCountry == country,
                    onClick = { onCountrySelect(country) }
                )
            }
        }

        Spacer(Modifier.height(20.dp))
        PrimaryButton(
            text = if (selectedCountry != null) "Continue →" else "Select a Country",
            onClick = onContinue,
            enabled = selectedCountry != null,
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(32.dp))
    }
}

@Composable
private fun CountryCard(country: Country, isSelected: Boolean, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .clip(RoundedCornerShape(16.dp))
            .background(if (isSelected) Navy700 else Navy800)
            .border(
                width = if (isSelected) 1.5.dp else 1.dp,
                color = if (isSelected) Cyan400 else Navy700,
                shape = RoundedCornerShape(16.dp)
            )
            .clickable { onClick() }
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(country.flag, fontSize = 36.sp)
        Spacer(Modifier.height(8.dp))
        Text(
            country.displayName,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = if (isSelected) TextPrimary else TextSecondary
        )
        Spacer(Modifier.height(4.dp))
        Text(country.tagline, fontSize = 9.sp, color = TextMuted, lineHeight = 13.sp)
        if (isSelected) {
            Spacer(Modifier.height(8.dp))
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(6.dp))
                    .background(Cyan400)
                    .padding(horizontal = 8.dp, vertical = 3.dp)
            ) {
                Text("✓ Selected", fontSize = 9.sp, color = Navy900, fontWeight = FontWeight.Bold)
            }
        }
    }
}
