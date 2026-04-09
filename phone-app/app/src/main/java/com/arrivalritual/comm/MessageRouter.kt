package com.arrivalritual.comm

import android.content.Context
import com.arrivalritual.services.ArrivalService
import com.arrivalritual.services.ContextService
import com.arrivalritual.services.ConversationService
import com.arrivalritual.services.SpeechAssistService

/**
 * MessageRouter
 *
 * Central dispatcher for all watch ↔ phone messages.
 * Reads every field from the incoming [payload] and delegates to the appropriate service.
 *
 * Constructor accepts an optional Android [Context]; when null (unit-test environment)
 * each service uses its own hardcoded stub so existing tests keep passing.
 */
class MessageRouter(
    private val context: Context? = null,
    private val arrivalService: ArrivalService = ArrivalService(context),
    private val contextService: ContextService = ContextService(context),
    private val conversationService: ConversationService = ConversationService(context),
    private val speechAssistService: SpeechAssistService? = context?.let { SpeechAssistService(it) }
) {

    /**
     * Routes [messageType] to the correct service and returns a wire-ready response map.
     * Suspend because CONTEXT_ALERT and CONVO_OPTIONS may call the LLM over the network.
     *
     * @param messageType One of the [MessageType] enum name strings.
     * @param payload     Key/value pairs extracted from the incoming JSON message.
     */
    suspend fun route(
        messageType: String,
        payload: Map<String, Any?> = emptyMap()
    ): Map<String, Any> {

        return when (messageType) {

            MessageType.PING.name -> mapOf(
                "type"    to MessageType.PONG.name,
                "payload" to emptyMap<String, Any>()
            )

            MessageType.REQUEST_NEXT_STEP.name -> {
                val country   = payload["country"] as? String ?: "Japan"
                val stepIndex = (payload["currentStepIndex"] as? Number)?.toInt() ?: 0
                mapOf(
                    "type"    to MessageType.ARRIVAL_STEP.name,
                    "payload" to arrivalService.getNextStep(country, stepIndex)
                )
            }

            MessageType.REQUEST_CONTEXT_ALERT.name -> {
                val country      = payload["country"] as? String ?: "Japan"
                val locationType = payload["locationType"] as? String ?: "airport"
                mapOf(
                    "type"    to MessageType.CONTEXT_ALERT.name,
                    "payload" to contextService.getContextAlert(country, locationType)
                )
            }

            MessageType.REQUEST_CONVO_OPTIONS.name -> {
                val country      = payload["country"] as? String ?: "Japan"
                val locationType = payload["context"] as? String ?: "taxi"
                val locale       = payload["locale"] as? String ?: "en"
                mapOf(
                    "type"    to MessageType.CONVO_OPTIONS.name,
                    "payload" to conversationService.getConversationOptions(country, locationType, locale)
                )
            }

            MessageType.REQUEST_SPEECH_ASSIST.name -> {
                val country      = payload["country"] as? String ?: "Japan"
                val locationType = payload["locationType"] as? String ?: "airport"
                val locale       = payload["locale"] as? String ?: "en"
                val result = speechAssistService?.assist(country, locationType, locale)
                mapOf(
                    "type" to MessageType.SPEECH_ASSIST_RESULT.name,
                    "payload" to mapOf(
                        "transcribedText"  to (result?.transcribedText ?: ""),
                        "suggestedPhrases" to (result?.suggestedPhrases ?: listOf(
                            "I don't understand.", "Could you repeat that?", "Do you speak English?"
                        )),
                        "detectedLanguage" to (result?.detectedLanguage ?: "unknown")
                    )
                )
            }

            MessageType.GESTURE_DETECTED.name -> {
                // Watch detected camera-lift → look up the applicable rule for this location
                val country      = payload["country"] as? String ?: "Japan"
                val locationType = payload["locationType"] as? String ?: "temple"
                mapOf(
                    "type"    to MessageType.CONTEXT_ALERT.name,
                    "payload" to contextService.getContextAlert(country, "camera_lift_$locationType")
                )
            }

            else -> mapOf(
                "type"    to MessageType.ERROR.name,
                "payload" to mapOf(
                    "code"    to "UNKNOWN_MESSAGE_TYPE",
                    "message" to "Unsupported message type received."
                )
            )
        }
    }
}
