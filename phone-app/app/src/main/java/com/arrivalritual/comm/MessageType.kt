package com.arrivalritual.comm

enum class MessageType {
    // Watch → Phone
    PING,
    REQUEST_NEXT_STEP,
    REQUEST_CONTEXT_ALERT,
    REQUEST_CONVO_OPTIONS,
    /** Watch crown pressed — start speech capture and return a reply phrase */
    REQUEST_SPEECH_ASSIST,
    /** Watch detected a camera-lift gesture — phone should look up the applicable rule */
    GESTURE_DETECTED,

    // Phone → Watch
    PONG,
    ARRIVAL_STEP,
    CONTEXT_ALERT,
    CONVO_OPTIONS,
    /** Result of speech capture: transcription + suggested reply phrases */
    SPEECH_ASSIST_RESULT,
    ERROR
}