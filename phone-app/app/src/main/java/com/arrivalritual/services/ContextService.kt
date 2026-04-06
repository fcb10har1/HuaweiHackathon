package com.arrivalritual.services

class ContextService {
    fun getContextAlert(): Map<String, Any> {
        return mapOf(
            "alertId" to "airport_security_01",
            "message" to "You may need to remove your shoes during screening.",
            "riskLevel" to "SENSITIVE"
        )
    }
}
