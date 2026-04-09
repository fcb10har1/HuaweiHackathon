package com.arrivalritual.services

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.Locale
import kotlin.coroutines.resume

/**
 * SpeechService
 *
 * Wraps Android's built-in SpeechRecognizer for the USER'S OWN VOICE.
 * Used when the traveller wants to speak a phrase and have it matched
 * against the current scenario's phrase list.
 *
 * This path is complementary to WhisperService, which handles ambient
 * audio (what a LOCAL is saying to the traveller).
 *
 * Must be called from the main thread (SpeechRecognizer requirement).
 */
class SpeechService(private val context: Context) {

    /**
     * Starts a one-shot speech recognition session.
     *
     * @param locale  BCP-47 locale for recognition (e.g. "en-US", "ja-JP").
     *                Defaults to the device locale.
     * @param maxDurationMs  Max recording time in ms before auto-stopping.
     * @return The recognised text, or null on error / no speech detected.
     */
    suspend fun recognise(
        locale: String = Locale.getDefault().toLanguageTag(),
        maxDurationMs: Int = 5000
    ): String? = suspendCancellableCoroutine { cont ->

        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            cont.resume(null)
            return@suspendCancellableCoroutine
        }

        val recognizer = SpeechRecognizer.createSpeechRecognizer(context)

        recognizer.setRecognitionListener(object : RecognitionListener {
            override fun onResults(results: Bundle?) {
                val matches = results
                    ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                recognizer.destroy()
                cont.resume(matches?.firstOrNull())
            }

            override fun onError(error: Int) {
                recognizer.destroy()
                cont.resume(null)
            }

            // Unused lifecycle callbacks
            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onPartialResults(partialResults: Bundle?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 1000)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 1500)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, maxDurationMs.toLong())
        }

        recognizer.startListening(intent)

        cont.invokeOnCancellation {
            recognizer.stopListening()
            recognizer.destroy()
        }
    }
}
