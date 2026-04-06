package com.arrivalritual.comm

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MessageRouterTest {

    private val router = MessageRouter()

    @Test
    fun ping_returnsPong() {
        val response = router.route(MessageType.PING.name)

        assertEquals(MessageType.PONG.name, response["type"])
        val payload = response["payload"] as Map<*, *>
        assertTrue(payload.isEmpty())
    }

    @Test
    fun requestNextStep_returnsArrivalStep() {
        val response = router.route(MessageType.REQUEST_NEXT_STEP.name)

        assertEquals(MessageType.ARRIVAL_STEP.name, response["type"])

        val payload = response["payload"] as Map<*, *>
        assertEquals("Prepare passport", payload["title"])
        assertEquals("NORM", payload["riskLevel"])
    }

    @Test
    fun requestContextAlert_returnsContextAlert() {
        val response = router.route(MessageType.REQUEST_CONTEXT_ALERT.name)

        assertEquals(MessageType.CONTEXT_ALERT.name, response["type"])

        val payload = response["payload"] as Map<*, *>
        assertEquals("airport_security_01", payload["alertId"])
        assertEquals("SENSITIVE", payload["riskLevel"])
    }

    @Test
    fun requestConvoOptions_returnsConversationOptions() {
        val response = router.route(MessageType.REQUEST_CONVO_OPTIONS.name)

        assertEquals(MessageType.CONVO_OPTIONS.name, response["type"])

        val payload = response["payload"] as Map<*, *>
        val options = payload["options"] as List<*>

        assertTrue(options.contains("Please take me to this address."))
    }

    @Test
    fun unknownMessage_returnsError() {
        val response = router.route("SOMETHING_RANDOM")

        assertEquals(MessageType.ERROR.name, response["type"])
        val payload = response["payload"] as Map<*, *>
        assertEquals("UNKNOWN_MESSAGE_TYPE", payload["code"])
    }
}