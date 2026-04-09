package com.arrivalritual.data

import android.content.Context
import com.google.gson.Gson

/**
 * CountryPackRepository
 *
 * Loads country JSON packs from assets/countries/{code}.json and caches them
 * in memory for the app session. Also resolves a free-form locationType string
 * to the best matching ScenarioPack via keyword matching (offline fallback path).
 */
class CountryPackRepository(private val context: Context?) {

    private val gson = Gson()
    private val memCache = mutableMapOf<String, CountryPack?>()

    /** Maps display names and aliases → ISO country code (lowercase) */
    private val nameToCode = mapOf(
        "japan" to "jp",
        "thailand" to "th",
        "india" to "in",
        "united arab emirates" to "ae",
        "uae" to "ae",
        "singapore" to "sg",
        "vietnam" to "vn",
        "indonesia" to "id",
        "malaysia" to "my",
        "laos" to "la",
        "cambodia" to "kh"
    )

    /**
     * Returns the CountryPack for [countryNameOrCode] (display name OR ISO code),
     * or null if the asset file cannot be found / parsed.
     */
    fun getCountryPack(countryNameOrCode: String): CountryPack? {
        val code = resolveCode(countryNameOrCode)
        if (memCache.containsKey(code)) return memCache[code]

        val pack = loadFromAssets(code)
        memCache[code] = pack
        return pack
    }

    /**
     * Finds the ScenarioPack whose locationKeywords best match [locationType].
     * Matching order:
     *   1. Exact id match (e.g. locationType == "temple")
     *   2. Any keyword is a substring of locationType, or vice-versa
     */
    fun findScenario(countryNameOrCode: String, locationType: String): ScenarioPack? {
        val pack = getCountryPack(countryNameOrCode) ?: return null
        val lower = locationType.lowercase().trim()

        // 1. Exact scenario id match
        pack.scenarios.find { it.id.lowercase() == lower }?.let { return it }

        // 2. Keyword substring match (bidirectional)
        return pack.scenarios.maxByOrNull { scenario ->
            scenario.locationKeywords.count { kw ->
                val k = kw.lowercase()
                lower.contains(k) || k.contains(lower)
            }
        }?.takeIf { scenario ->
            scenario.locationKeywords.any { kw ->
                val k = kw.lowercase()
                lower.contains(k) || k.contains(lower)
            }
        }
    }

    /**
     * Returns the ordered arrival steps for a country.
     * Looks for the scenario with id "airport" first, then falls back to the
     * first scenario whose keywords include "airport".
     */
    fun getArrivalSteps(countryNameOrCode: String): List<ArrivalStepData> {
        val pack = getCountryPack(countryNameOrCode) ?: return emptyList()
        val scenario = pack.scenarios.find { it.id == "airport" }
            ?: pack.scenarios.find { it.locationKeywords.contains("airport") }
            ?: return emptyList()
        return scenario.arrivalSteps.sortedBy { it.stepIndex }
    }

    // ── Private helpers ────────────────────────────────────────────────────────

    private fun resolveCode(input: String): String =
        nameToCode[input.lowercase().trim()] ?: input.lowercase().trim()

    private fun loadFromAssets(code: String): CountryPack? {
        return try {
            val json = context?.assets
                ?.open("countries/$code.json")
                ?.bufferedReader()
                ?.readText()
                ?: return null
            gson.fromJson(json, CountryPack::class.java)
        } catch (e: Exception) {
            null
        }
    }
}
