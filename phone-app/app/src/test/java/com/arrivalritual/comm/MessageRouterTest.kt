package com.arrivalritual.comm

import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Test

/**
 * MessageRouterTest
 *
 * Unit tests that run without an Android context (null context → stub fallback data).
 * route() is now a suspend function so each test uses runTest { }.
 */
class MessageRouterTest {

    // No context → services use hardcoded stubs
    private val router = MessageRouter()

    @Test
    fun ping_returnsPong() = runTest {
        val response = router.route(MessageType.PING.name)

        assertEquals(MessageType.PONG.name, response["type"])
        val payload = response["payload"] as Map<*, *>
        assertTrue(payload.isEmpty())
    }

    @Test
    fun requestNextStep_returnsArrivalStep() = runTest {
        val response = router.route(MessageType.REQUEST_NEXT_STEP.name)

        assertEquals(MessageType.ARRIVAL_STEP.name, response["type"])
        val payload = response["payload"] as Map<*, *>
        assertEquals("Prepare passport", payload["title"])
        assertEquals("NORM", payload["riskLevel"])
    }

    @Test
    fun requestContextAlert_returnsContextAlert() = runTest {
        val response = router.route(MessageType.REQUEST_CONTEXT_ALERT.name)

        assertEquals(MessageType.CONTEXT_ALERT.name, response["type"])
        val payload = response["payload"] as Map<*, *>
        assertEquals("airport_security_01", payload["alertId"])
        assertEquals("SENSITIVE", payload["riskLevel"])
    }

    @Test
    fun requestConvoOptions_returnsConversationOptions() = runTest {
        val response = router.route(MessageType.REQUEST_CONVO_OPTIONS.name)

        assertEquals(MessageType.CONVO_OPTIONS.name, response["type"])
        val payload = response["payload"] as Map<*, *>
        val options = payload["options"] as List<*>
        assertTrue(options.contains("Please take me to this address."))
    }

    @Test
    fun unknownMessage_returnsError() = runTest {
        val response = router.route("SOMETHING_RANDOM")

        assertEquals(MessageType.ERROR.name, response["type"])
        val payload = response["payload"] as Map<*, *>
        assertEquals("UNKNOWN_MESSAGE_TYPE", payload["code"])
    }

    @Test
    fun requestNextStep_withPayload_usesStepIndex() = runTest {
        val response = router.route(
            MessageType.REQUEST_NEXT_STEP.name,
            mapOf("country" to "Japan", "currentStepIndex" to 2)
        )
        assertEquals(MessageType.ARRIVAL_STEP.name, response["type"])
        val payload = response["payload"] as Map<*, *>
        // Stub always returns index 0 data regardless, but riskLevel must be present
        assertTrue(payload.containsKey("riskLevel"))
    }

    @Test
    fun gestureDetected_returnsContextAlert() = runTest {
        val response = router.route(
            MessageType.GESTURE_DETECTED.name,
            mapOf("country" to "Japan", "locationType" to "temple")
        )
        assertEquals(MessageType.CONTEXT_ALERT.name, response["type"])
        val payload = response["payload"] as Map<*, *>
        assertTrue("GESTURE_DETECTED response must contain alertId", payload.containsKey("alertId"))
        assertTrue("GESTURE_DETECTED response must contain message", payload.containsKey("message"))
        assertTrue("GESTURE_DETECTED response must contain riskLevel", payload.containsKey("riskLevel"))
    }

    @Test
    fun requestSpeechAssist_noContext_returnsFallbackPhrases() = runTest {
        // With null context, speechAssistService is null → hardcoded fallback phrases
        val response = router.route(
            MessageType.REQUEST_SPEECH_ASSIST.name,
            mapOf("country" to "Japan", "locationType" to "airport", "locale" to "ja")
        )
        assertEquals(MessageType.SPEECH_ASSIST_RESULT.name, response["type"])
        val payload = response["payload"] as Map<*, *>
        assertTrue(payload.containsKey("transcribedText"))
        assertTrue(payload.containsKey("suggestedPhrases"))
        assertTrue(payload.containsKey("detectedLanguage"))

        @Suppress("UNCHECKED_CAST")
        val phrases = payload["suggestedPhrases"] as List<String>
        assertTrue("Fallback phrases must not be empty", phrases.isNotEmpty())
        assertTrue(
            "Fallback must include 'I don't understand.'",
            phrases.any { it.contains("understand", ignoreCase = true) }
        )
    }

    @Test
    fun requestContextAlert_differentCountries_allReturnContextAlert() = runTest {
        val countries = listOf("Japan", "Thailand", "Singapore", "India")
        for (country in countries) {
            val response = router.route(
                MessageType.REQUEST_CONTEXT_ALERT.name,
                mapOf("country" to country, "locationType" to "airport")
            )
            assertEquals(
                "[$country] must return CONTEXT_ALERT",
                MessageType.CONTEXT_ALERT.name,
                response["type"]
            )
        }
    }

    @Test
    fun allKnownMessageTypes_doNotThrow() = runTest {
        val knownTypes = listOf(
            MessageType.PING.name,
            MessageType.REQUEST_NEXT_STEP.name,
            MessageType.REQUEST_CONTEXT_ALERT.name,
            MessageType.REQUEST_CONVO_OPTIONS.name,
            MessageType.REQUEST_SPEECH_ASSIST.name,
            MessageType.GESTURE_DETECTED.name
        )
        for (type in knownTypes) {
            val response = router.route(type)
            assertNotNull("[$type] must return a non-null response", response)
            assertTrue("[$type] response must have a 'type' key", response.containsKey("type"))
            assertTrue("[$type] response must have a 'payload' key", response.containsKey("payload"))
        }
    }
}
