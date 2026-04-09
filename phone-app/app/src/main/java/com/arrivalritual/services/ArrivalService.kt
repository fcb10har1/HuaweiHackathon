package com.arrivalritual.services

import android.content.Context
import com.arrivalritual.data.CountryPackRepository

/**
 * ArrivalService
 *
 * Returns a single ordered arrival-checklist step for the given country and step index.
 * Steps are pre-authored in assets/countries/{code}.json under the "airport" scenario.
 *
 * Falls back to a hardcoded stub when context is null (test environment).
 */
class ArrivalService(private val context: Context? = null) {

    private val repository = CountryPackRepository(context)

    fun getNextStep(country: String = "Japan", stepIndex: Int = 0): Map<String, Any> {
        if (context != null) {
            val steps = repository.getArrivalSteps(country)
            val step = steps.getOrNull(stepIndex)
            if (step != null) {
                return mapOf(
                    "stepIndex"   to step.stepIndex,
                    "title"       to step.title,
                    "description" to step.description,
                    "riskLevel"   to step.riskLevel
                )
            }
            // If index is out of range, signal end of checklist
            if (steps.isNotEmpty()) {
                return mapOf(
                    "stepIndex"   to stepIndex,
                    "title"       to "Checklist Complete",
                    "description" to "You have completed all arrival steps. Enjoy your trip!",
                    "riskLevel"   to "NORM"
                )
            }
        }

        // Stub fallback (no context / no JSON loaded)
        return mapOf(
            "stepIndex"   to stepIndex,
            "title"       to "Prepare passport",
            "description" to "Keep your passport ready for inspection.",
            "riskLevel"   to "NORM"
        )
    }
}
