package com.arrivalritual.services

import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Test

/**
 * ServiceStubTest
 *
 * Verifies that each service (ArrivalService, ContextService, ConversationService)
 * returns well-formed stub data when context is null (i.e. in the unit-test JVM
 * environment where no Android AssetManager or network is available).
 *
 * This ensures the services degrade gracefully when called from the watch without
 * a fully-initialised phone app (e.g. during startup or in offline mode).
 */
class ServiceStubTest {

    private val validRiskLevels = setOf("NORM", "SENSITIVE", "LEGAL")

    // ── ArrivalService ─────────────────────────────────────────────────────────

    private val arrivalService = ArrivalService(context = null)

    @Test
    fun arrivalService_stub_returnsNonBlankTitle() {
        val step = arrivalService.getNextStep()
        assertFalse("Stub title must not be blank", (step["title"] as String).isBlank())
    }

    @Test
    fun arrivalService_stub_returnsValidRiskLevel() {
        val step = arrivalService.getNextStep()
        assertTrue(
            "Stub riskLevel must be in $validRiskLevels",
            step["riskLevel"] as String in validRiskLevels
        )
    }

    @Test
    fun arrivalService_stub_stepIndexMatchesRequest() {
        // The stub echoes back whatever stepIndex was asked for
        for (index in listOf(0, 1, 5, 99)) {
            val step = arrivalService.getNextStep(stepIndex = index)
            assertEquals("Stub should echo back stepIndex=$index", index, step["stepIndex"] as Int)
        }
    }

    @Test
    fun arrivalService_stub_hasRequiredKeys() {
        val step = arrivalService.getNextStep()
        assertTrue(step.containsKey("stepIndex"))
        assertTrue(step.containsKey("title"))
        assertTrue(step.containsKey("description"))
        assertTrue(step.containsKey("riskLevel"))
    }

    // ── ContextService ─────────────────────────────────────────────────────────

    private val contextService = ContextService(context = null)

    @Test
    fun contextService_stub_returnsAlertId() = runTest {
        val alert = contextService.getContextAlert()
        assertFalse("Stub alertId must not be blank", (alert["alertId"] as String).isBlank())
    }

    @Test
    fun contextService_stub_returnsMessage() = runTest {
        val alert = contextService.getContextAlert()
        assertFalse("Stub message must not be blank", (alert["message"] as String).isBlank())
    }

    @Test
    fun contextService_stub_returnsValidRiskLevel() = runTest {
        val alert = contextService.getContextAlert()
        assertTrue(
            "Stub riskLevel '${alert["riskLevel"]}' must be in $validRiskLevels",
            alert["riskLevel"] as String in validRiskLevels
        )
    }

    @Test
    fun contextService_stub_hasRequiredKeys() = runTest {
        val alert = contextService.getContextAlert()
        assertTrue(alert.containsKey("alertId"))
        assertTrue(alert.containsKey("message"))
        assertTrue(alert.containsKey("riskLevel"))
    }

    @Test
    fun contextService_stub_differentLocationTypes_allReturnSameStub() = runTest {
        // Without context, all locationTypes fall through to the generic stub
        val locationTypes = listOf("airport", "temple", "mosque", "taxi", "beach", "custom_zone")
        for (lt in locationTypes) {
            val alert = contextService.getContextAlert(locationType = lt)
            assertFalse("[$lt] stub alertId must not be blank", (alert["alertId"] as String).isBlank())
        }
    }

    // ── ConversationService ────────────────────────────────────────────────────

    private val conversationService = ConversationService(context = null)

    @Test
    fun conversationService_stub_returnsOptionsList() = runTest {
        val result = conversationService.getConversationOptions()
        @Suppress("UNCHECKED_CAST")
        val options = result["options"] as List<String>
        assertTrue("Stub must return at least one conversation option", options.isNotEmpty())
    }

    @Test
    fun conversationService_stub_optionsAreNonBlank() = runTest {
        @Suppress("UNCHECKED_CAST")
        val options = conversationService.getConversationOptions()["options"] as List<String>
        for (opt in options) {
            assertFalse("Each stub option must be non-blank", opt.isBlank())
        }
    }

    @Test
    fun conversationService_stub_hasTaxiOption() = runTest {
        // The taxi stub must contain at least one address-related phrase
        @Suppress("UNCHECKED_CAST")
        val options = conversationService.getConversationOptions()["options"] as List<String>
        assertTrue(
            "Taxi stub must include an address phrase",
            options.any { it.contains("address", ignoreCase = true) }
        )
    }
}
