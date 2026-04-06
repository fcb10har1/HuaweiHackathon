package com.arrivalritual.services

class ArrivalService {
    fun getNextStep(): Map<String, Any> {
        return mapOf(
            "stepIndex" to 1,
            "title" to "Prepare passport",
            "description" to "Keep your passport ready for inspection.",
            "riskLevel" to "NORM"
        )
    }
}
