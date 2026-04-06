package com.arrivalritual.services

class ConversationService {
    fun getConversationOptions(): Map<String, Any> {
        return mapOf(
            "options" to listOf(
                "Please take me to this address.",
                "Use the meter.",
                "How much will the ride cost?"
            )
        )
    }
}



