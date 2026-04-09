package com.arrivalritual.data

import com.google.gson.Gson
import com.google.gson.JsonSyntaxException
import org.junit.Assert.*
import org.junit.Test
import java.io.File

/**
 * CountryPackJsonTest
 *
 * Validates every country JSON asset file against the CountryPack schema.
 * Runs on JVM (no Android context needed) by reading files directly from the
 * src/main/assets/countries/ directory on disk.
 *
 * What this checks:
 *  - File is valid JSON and parses into CountryPack without error
 *  - Required top-level fields are present and non-blank
 *  - At least one scenario exists
 *  - An "airport" scenario exists in every country pack
 *  - Every airport scenario has ≥ 5 arrivalSteps (we authored 6 per country)
 *  - Every step has sequential stepIndex, non-blank title, non-blank description,
 *    and a riskLevel in the allowed set {NORM, SENSITIVE, LEGAL}
 *  - Every fallbackAlert has a non-blank alertId, message, and valid riskLevel
 *  - Every phrase has non-blank english, nativeScript, and romanized fields
 */
class CountryPackJsonTest {

    private val gson = Gson()

    private val validRiskLevels = setOf("NORM", "SENSITIVE", "LEGAL")

    /** Supported country codes — must match the files in assets/countries/. */
    private val countryCodes = listOf("jp", "th", "in", "ae", "sg", "vn", "id", "my", "la", "kh")

    // ── Helpers ────────────────────────────────────────────────────────────────

    private fun assetsDir(): File {
        // Android Gradle unit tests typically run with the module dir as working dir.
        val moduleRelative = File("src/main/assets/countries")
        if (moduleRelative.exists()) return moduleRelative
        // Fallback when run from project root.
        val projectRelative = File("phone-app/app/src/main/assets/countries")
        if (projectRelative.exists()) return projectRelative
        error("Cannot locate assets/countries directory. Working dir: ${File(".").absolutePath}")
    }

    private fun loadPack(code: String): CountryPack {
        val file = File(assetsDir(), "$code.json")
        assertTrue("Asset file $code.json must exist", file.exists())
        return try {
            gson.fromJson(file.readText(Charsets.UTF_8), CountryPack::class.java)
        } catch (e: JsonSyntaxException) {
            fail("$code.json is not valid JSON: ${e.message}")
            throw e
        }
    }

    // ── Per-file structure tests ───────────────────────────────────────────────

    @Test fun jp_isValidAndComplete() = assertCountryPack("jp", "Japan", "ja-JP")
    @Test fun th_isValidAndComplete() = assertCountryPack("th", "Thailand", "th-TH")
    @Test fun in_isValidAndComplete()  = assertCountryPack("in", "India", "hi-IN")
    @Test fun ae_isValidAndComplete() = assertCountryPack("ae", "United Arab Emirates", "ar-AE")
    @Test fun sg_isValidAndComplete() = assertCountryPack("sg", "Singapore", "en-SG")
    @Test fun vn_isValidAndComplete() = assertCountryPack("vn", "Vietnam", "vi-VN")
    @Test fun id_isValidAndComplete() = assertCountryPack("id", "Indonesia", "id-ID")
    @Test fun my_isValidAndComplete() = assertCountryPack("my", "Malaysia", "ms-MY")
    @Test fun la_isValidAndComplete() = assertCountryPack("la", "Laos", "lo-LA")
    @Test fun kh_isValidAndComplete() = assertCountryPack("kh", "Cambodia", "km-KH")

    // ── Cross-file invariant tests ─────────────────────────────────────────────

    @Test
    fun allCountries_haveAirportScenarioWithAtLeastFiveSteps() {
        for (code in countryCodes) {
            val pack = loadPack(code)
            val airport = pack.scenarios.find { it.id == "airport" }
            assertNotNull("[$code] must have an 'airport' scenario", airport)
            assertTrue(
                "[$code] airport scenario must have ≥ 5 steps, got ${airport!!.arrivalSteps.size}",
                airport.arrivalSteps.size >= 5
            )
        }
    }

    @Test
    fun allCountries_airportStepIndicesAreSequential() {
        for (code in countryCodes) {
            val pack  = loadPack(code)
            val steps = pack.scenarios.first { it.id == "airport" }.arrivalSteps
                .sortedBy { it.stepIndex }
            steps.forEachIndexed { idx, step ->
                assertEquals("[$code] step at position $idx must have stepIndex=$idx", idx, step.stepIndex)
            }
        }
    }

    @Test
    fun allCountries_everyStepHasValidRiskLevel() {
        for (code in countryCodes) {
            val pack = loadPack(code)
            for (scenario in pack.scenarios) {
                for (step in scenario.arrivalSteps) {
                    assertTrue(
                        "[$code/${scenario.id}] step '${step.title}' has invalid riskLevel '${step.riskLevel}'",
                        step.riskLevel in validRiskLevels
                    )
                }
            }
        }
    }

    @Test
    fun allCountries_everyAlertHasValidRiskLevel() {
        for (code in countryCodes) {
            val pack = loadPack(code)
            for (scenario in pack.scenarios) {
                for (alert in scenario.fallbackAlerts) {
                    assertFalse("[$code/${scenario.id}] alert alertId must not be blank", alert.alertId.isBlank())
                    assertFalse("[$code/${scenario.id}] alert message must not be blank", alert.message.isBlank())
                    assertTrue(
                        "[$code/${scenario.id}] alert '${alert.alertId}' has invalid riskLevel '${alert.riskLevel}'",
                        alert.riskLevel in validRiskLevels
                    )
                }
            }
        }
    }

    @Test
    fun allCountries_everyPhraseHasAllFields() {
        for (code in countryCodes) {
            val pack = loadPack(code)
            for (scenario in pack.scenarios) {
                for (phrase in scenario.phrases) {
                    assertFalse("[$code/${scenario.id}] phrase english must not be blank", phrase.english.isBlank())
                    assertFalse("[$code/${scenario.id}] phrase nativeScript must not be blank", phrase.nativeScript.isBlank())
                    assertFalse("[$code/${scenario.id}] phrase romanized must not be blank", phrase.romanized.isBlank())
                }
            }
        }
    }

    @Test
    fun allCountries_airportScenarioHasAtLeastOneLegalStep() {
        // Every country must warn travellers about at least one legal risk at the airport.
        for (code in countryCodes) {
            val pack  = loadPack(code)
            val steps = pack.scenarios.first { it.id == "airport" }.arrivalSteps
            assertTrue(
                "[$code] airport scenario must contain at least one LEGAL-risk step",
                steps.any { it.riskLevel == "LEGAL" }
            )
        }
    }

    // ── Private assertion helper ───────────────────────────────────────────────

    private fun assertCountryPack(code: String, expectedName: String, expectedLocale: String) {
        val pack = loadPack(code)

        assertEquals("[$code] countryCode must match file name (uppercase)", code.uppercase(), pack.countryCode)
        assertEquals("[$code] name mismatch", expectedName, pack.name)
        assertFalse("[$code] flag must not be blank", pack.flag.isBlank())
        assertFalse("[$code] tagline must not be blank", pack.tagline.isBlank())

        // Language
        assertFalse("[$code] language.name must not be blank", pack.language.name.isBlank())
        assertEquals("[$code] language.locale mismatch", expectedLocale, pack.language.locale)
        assertFalse("[$code] language.nativeScriptName must not be blank", pack.language.nativeScriptName.isBlank())

        // Scenarios
        assertTrue("[$code] must have at least one scenario", pack.scenarios.isNotEmpty())

        // All scenario ids are non-blank and unique
        val ids = pack.scenarios.map { it.id }
        assertEquals("[$code] scenario ids must be unique", ids.distinct(), ids)

        for (scenario in pack.scenarios) {
            assertFalse("[$code] scenario id must not be blank", scenario.id.isBlank())
            assertFalse("[$code/${scenario.id}] displayName must not be blank", scenario.displayName.isBlank())
            assertTrue("[$code/${scenario.id}] locationKeywords must not be empty", scenario.locationKeywords.isNotEmpty())

            for (step in scenario.arrivalSteps) {
                assertFalse("[$code/${scenario.id}] step title must not be blank", step.title.isBlank())
                assertFalse("[$code/${scenario.id}] step description must not be blank", step.description.isBlank())
            }
        }
    }
}
