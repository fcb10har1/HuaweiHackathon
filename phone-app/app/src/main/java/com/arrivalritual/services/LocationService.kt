package com.arrivalritual.services

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.os.Looper
import com.arrivalritual.controller.BuildConfig
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume

/**
 * LocationService
 *
 * Two responsibilities:
 *
 * 1. [getCurrentLocation] — one-shot GPS fix via FusedLocationProvider.
 *
 * 2. [resolveScenarioFromLocation] — calls Google Places Nearby Search with
 *    the current GPS coordinates to determine what type of place the user is at
 *    (airport, temple, taxi stand, etc.) and maps it to one of our scenario IDs.
 *
 * Place-type → scenario-id mapping:
 *   airport                       → "airport"
 *   hindu_temple / mosque / church / place_of_worship  → "temple"
 *   taxi_stand / transit_station / bus_station         → "taxi"
 *   shopping_mall                 → "mall"
 *   restaurant / food / cafe      → "restaurant"
 *   natural_feature / park        → "beach" (fallback for outdoor areas)
 *
 * Falls back to null if location permission is denied, Places API key is blank,
 * or the network is unavailable.
 */
class LocationService(private val context: Context) {

    private val fusedClient = LocationServices.getFusedLocationProviderClient(context)
    private val httpClient  = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    private val placesApiKey get() = BuildConfig.GOOGLE_PLACES_API_KEY

    companion object {
        private const val NEARBY_SEARCH_RADIUS_M = 300

        /** Google Place types → our scenario IDs (evaluated in order — first match wins) */
        private val PLACE_TYPE_MAP: List<Pair<Set<String>, String>> = listOf(
            setOf("airport") to "airport",
            setOf("immigration", "customs") to "immigration",
            setOf("hindu_temple", "buddhist_temple", "mosque", "church",
                   "synagogue", "place_of_worship", "shrine") to "temple",
            setOf("taxi_stand", "transit_station", "bus_station",
                   "train_station", "subway_station", "light_rail_station") to "taxi",
            setOf("shopping_mall", "department_store") to "mall",
            setOf("restaurant", "food", "cafe", "bakery", "bar") to "restaurant",
            setOf("beach", "park", "natural_feature") to "beach"
        )
    }

    // ── Public API ─────────────────────────────────────────────────────────────

    /**
     * Returns the detected scenario ID (e.g. "temple") for the user's current GPS
     * position, or null on any failure.
     *
     * Requires ACCESS_FINE_LOCATION permission to be granted before calling.
     */
    @SuppressLint("MissingPermission")
    suspend fun resolveScenarioFromLocation(): String? {
        val location = getCurrentLocation() ?: return null
        return queryNearbyPlaces(location.latitude, location.longitude)
    }

    // ── Location fix ───────────────────────────────────────────────────────────

    @SuppressLint("MissingPermission")
    private suspend fun getCurrentLocation(): Location? =
        suspendCancellableCoroutine { cont ->
            val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 5000L)
                .setMaxUpdates(1)
                .build()

            val callback = object : LocationCallback() {
                override fun onLocationResult(result: LocationResult) {
                    fusedClient.removeLocationUpdates(this)
                    cont.resume(result.lastLocation)
                }
            }

            try {
                fusedClient.requestLocationUpdates(request, callback, Looper.getMainLooper())
                cont.invokeOnCancellation { fusedClient.removeLocationUpdates(callback) }
            } catch (e: Exception) {
                cont.resume(null)
            }
        }

    // ── Places API ─────────────────────────────────────────────────────────────

    private fun queryNearbyPlaces(lat: Double, lng: Double): String? {
        if (placesApiKey.isBlank() || placesApiKey == "your-google-places-api-key-here") return null

        return try {
            val url = buildString {
                append("https://maps.googleapis.com/maps/api/place/nearbysearch/json")
                append("?location=$lat,$lng")
                append("&radius=$NEARBY_SEARCH_RADIUS_M")
                append("&key=$placesApiKey")
            }

            val response = httpClient.newCall(Request.Builder().url(url).build()).execute()
            if (!response.isSuccessful) return null

            val root    = JSONObject(response.body?.string() ?: return null)
            val results = root.optJSONArray("results") ?: return null

            // Collect all place types from all nearby results
            val allTypes = mutableSetOf<String>()
            for (i in 0 until results.length()) {
                val typesArray = results.getJSONObject(i).optJSONArray("types") ?: continue
                for (j in 0 until typesArray.length()) {
                    allTypes.add(typesArray.getString(j))
                }
            }

            // First matching rule wins (most specific first)
            PLACE_TYPE_MAP.firstOrNull { (placeTypes, _) ->
                allTypes.any { it in placeTypes }
            }?.second
        } catch (e: Exception) {
            null
        }
    }
}
