package com.arrivalritual.comm

import com.arrivalritual.services.ArrivalService
import com.arrivalritual.services.ContextService
import com.arrivalritual.services.ConversationService

class MessageRouter(
    private val arrivalService: ArrivalService = ArrivalService(),
    private val contextService: ContextService = ContextService(),
    private val conversationService: ConversationService = ConversationService()
) {

    fun route(messageType: String): Map<String, Any> {
        return when (messageType) {
            MessageType.PING.name -> {
                mapOf(
                    "type" to MessageType.PONG.name,
                    "payload" to emptyMap<String, Any>()
                )
            }

            MessageType.REQUEST_NEXT_STEP.name -> {
                mapOf(
                    "type" to MessageType.ARRIVAL_STEP.name,
                    "payload" to arrivalService.getNextStep()
                )
            }

            MessageType.REQUEST_CONTEXT_ALERT.name -> {
                mapOf(
                    "type" to MessageType.CONTEXT_ALERT.name,
                    "payload" to contextService.getContextAlert()
                )
            }

            MessageType.REQUEST_CONVO_OPTIONS.name -> {
                mapOf(
                    "type" to MessageType.CONVO_OPTIONS.name,
                    "payload" to conversationService.getConversationOptions()
                )
            }

            else -> {
                mapOf(
                    "type" to MessageType.ERROR.name,
                    "payload" to mapOf(
                        "code" to "UNKNOWN_MESSAGE_TYPE",
                        "message" to "Unsupported message type received."
                    )
                )
            }
        }
    }
}