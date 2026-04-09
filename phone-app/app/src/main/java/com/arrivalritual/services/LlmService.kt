package com.arrivalritual.services

import com.arrivalritual.controller.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

data class LlmAlertResponse(
    val alertId: String,
    val message: String,
    /** "NORM" | "SENSITIVE" | "LEGAL" */
    val riskLevel: String
)

/**
 * LlmService
 *
 * Wraps OpenAI chat completions for two purposes:
 *   1. generateContextAlert  — produces a cultural/legal alert for a country + location
 *   2. generateExtraPhrases  — supplements Convo Assist with additional situational phrases
 *
 * API key is read from BuildConfig.OPENAI_API_KEY (injected from local.properties at build time).
 * Both functions return null / empty list on any network or API error so callers can fall back
 * gracefully to the JSON-defined data.
 */
class LlmService {

    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    private val apiKey get() = BuildConfig.OPENAI_API_KEY

    // ── Public API ─────────────────────────────────────────────────────────────

    /**
     * Asks GPT to generate ONE cultural or legal alert for [country] + [locationType].
     * Returns null if the key is blank, the network is unavailable, or parsing fails.
     */
    suspend fun generateContextAlert(
        country: String,
        locationType: String
    ): LlmAlertResponse? = withContext(Dispatchers.IO) {
        if (apiKey.isBlank() || apiKey == "sk-your-openai-api-key-here") return@withContext null
        try {
            val userPrompt = """
                A traveler has just arrived in $country and is currently at a/an $locationType.
                Generate ONE concise, practical cultural or legal alert for this exact situation.

                Respond ONLY with valid JSON — no markdown, no extra text:
                {
                  "alertId": "short_snake_case_id",
                  "message": "1–2 sentence alert that is specific and actionable",
                  "riskLevel": "NORM"
                }

                riskLevel must be exactly one of:
                  "NORM"      — general etiquette, good to know
                  "SENSITIVE" — socially important; mistakes cause offense
                  "LEGAL"     — legal requirement; violation risks fine or arrest
            """.trimIndent()

            val body = buildChatRequest(userPrompt, maxTokens = 200)
            val content = callApi(body) ?: return@withContext null
            parseAlert(content)
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Asks GPT for 3 additional English phrases a traveler might need in [country] at [locationType].
     * Returns an empty list on any failure.
     */
    suspend fun generateExtraPhrases(
        country: String,
        locationType: String,
        language: String
    ): List<String> = withContext(Dispatchers.IO) {
        if (apiKey.isBlank() || apiKey == "sk-your-openai-api-key-here") return@withContext emptyList()
        try {
            val userPrompt = """
                A traveler is in $country at a/an $locationType.
                Provide exactly 3 additional short, practical English phrases they might need to say.

                Respond ONLY with valid JSON — no markdown:
                {"phrases": ["phrase one", "phrase two", "phrase three"]}
            """.trimIndent()

            val body = buildChatRequest(userPrompt, maxTokens = 150)
            val content = callApi(body) ?: return@withContext emptyList()
            parsePhrases(content)
        } catch (e: Exception) {
            emptyList()
        }
    }

    // ── Private helpers ────────────────────────────────────────────────────────

    private fun buildChatRequest(userPrompt: String, maxTokens: Int): String =
        JSONObject().apply {
            put("model", "gpt-5-mini")
            put("response_format", JSONObject().put("type", "json_object"))
            put("max_tokens", maxTokens)
            put("temperature", 0.7)
            put("messages", JSONArray().apply {
                put(JSONObject().apply {
                    put("role", "system")
                    put("content", "You are a travel cultural guidance assistant. Always respond with valid JSON only.")
                })
                put(JSONObject().apply {
                    put("role", "user")
                    put("content", userPrompt)
                })
            })
        }.toString()

    private fun callApi(requestBody: String): String? {
        val request = Request.Builder()
            .url("https://api.openai.com/v1/chat/completions")
            .addHeader("Authorization", "Bearer $apiKey")
            .addHeader("Content-Type", "application/json")
            .post(requestBody.toRequestBody("application/json".toMediaType()))
            .build()

        val response = client.newCall(request).execute()
        if (!response.isSuccessful) return null

        return response.body?.string()?.let { body ->
            JSONObject(body)
                .getJSONArray("choices")
                .getJSONObject(0)
                .getJSONObject("message")
                .getString("content")
        }
    }

    private fun parseAlert(content: String): LlmAlertResponse? {
        val json = JSONObject(content)
        val message = json.optString("message").takeIf { it.isNotBlank() } ?: return null
        return LlmAlertResponse(
            alertId = json.optString("alertId", "llm_${System.currentTimeMillis()}"),
            message = message,
            riskLevel = json.optString("riskLevel", "NORM")
                .uppercase()
                .let { if (it in setOf("NORM", "SENSITIVE", "LEGAL")) it else "NORM" }
        )
    }

    private fun parsePhrases(content: String): List<String> {
        val arr = JSONObject(content).optJSONArray("phrases") ?: return emptyList()
        return (0 until arr.length()).mapNotNull { arr.optString(it).takeIf { s -> s.isNotBlank() } }
    }
}
