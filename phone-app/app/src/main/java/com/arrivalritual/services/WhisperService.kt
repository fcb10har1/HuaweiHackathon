package com.arrivalritual.services

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import com.arrivalritual.controller.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.util.concurrent.TimeUnit

/**
 * WhisperService
 *
 * Captures raw PCM audio from the phone microphone for a fixed duration,
 * then sends it to OpenAI's Whisper API for transcription.
 *
 * This is the AMBIENT / "LOCAL SPEAKING" path:
 *   Crown press → phone records 5 seconds → Whisper transcribes whatever language
 *   is captured → SpeechAssistService uses the text to generate a reply phrase.
 *
 * Differs from SpeechService (which uses Android's built-in STT for the traveller's
 * own English speech) in that Whisper handles any language and background noise better.
 */
class WhisperService {

    private val client = OkHttpClient.Builder()
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .build()

    private val apiKey get() = BuildConfig.OPENAI_API_KEY

    companion object {
        private const val SAMPLE_RATE    = 16000
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT   = AudioFormat.ENCODING_PCM_16BIT
        private const val RECORD_DURATION_MS = 5000L
    }

    /**
     * Records [RECORD_DURATION_MS] ms of audio and transcribes it via Whisper.
     *
     * @param languageHint  Optional BCP-47 hint (e.g. "th" for Thai). Leave null
     *                      to let Whisper auto-detect the language.
     * @return Transcribed text, or null on any failure.
     */
    suspend fun transcribeAmbient(languageHint: String? = null): String? =
        withContext(Dispatchers.IO) {
            if (apiKey.isBlank() || apiKey == "sk-your-openai-api-key-here") return@withContext null

            val pcmBytes = recordPcm() ?: return@withContext null
            val wavBytes = pcmToWav(pcmBytes)
            transcribeWithWhisper(wavBytes, languageHint)
        }

    // ── Audio recording ────────────────────────────────────────────────────────

    private fun recordPcm(): ByteArray? {
        val bufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
            .coerceAtLeast(8192)

        val recorder = try {
            AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                bufferSize
            )
        } catch (e: SecurityException) {
            return null // RECORD_AUDIO permission not granted
        }

        if (recorder.state != AudioRecord.STATE_INITIALIZED) {
            recorder.release()
            return null
        }

        val output = ByteArrayOutputStream()
        val buffer = ByteArray(bufferSize)
        val endTime = System.currentTimeMillis() + RECORD_DURATION_MS

        recorder.startRecording()
        while (System.currentTimeMillis() < endTime) {
            val read = recorder.read(buffer, 0, buffer.size)
            if (read > 0) output.write(buffer, 0, read)
        }
        recorder.stop()
        recorder.release()

        return output.toByteArray()
    }

    /** Wraps raw PCM bytes in a minimal WAV header so Whisper can parse them. */
    private fun pcmToWav(pcm: ByteArray): ByteArray {
        val totalDataLen = pcm.size + 36
        val byteRate = SAMPLE_RATE * 1 * 2 // sampleRate * channels * bytesPerSample

        return ByteArrayOutputStream().apply {
            // RIFF header
            write("RIFF".toByteArray())
            writeInt32Le(totalDataLen)
            write("WAVE".toByteArray())
            // fmt chunk
            write("fmt ".toByteArray())
            writeInt32Le(16)          // chunk size
            writeInt16Le(1)           // PCM format
            writeInt16Le(1)           // mono
            writeInt32Le(SAMPLE_RATE)
            writeInt32Le(byteRate)
            writeInt16Le(2)           // block align
            writeInt16Le(16)          // bits per sample
            // data chunk
            write("data".toByteArray())
            writeInt32Le(pcm.size)
            write(pcm)
        }.toByteArray()
    }

    // ── Whisper API ────────────────────────────────────────────────────────────

    private fun transcribeWithWhisper(wavBytes: ByteArray, languageHint: String?): String? {
        return try {
            val bodyBuilder = MultipartBody.Builder()
                .setType(MultipartBody.FORM)
                .addFormDataPart(
                    "file", "audio.wav",
                    wavBytes.toRequestBody("audio/wav".toMediaType())
                )
                .addFormDataPart("model", "whisper-1")
                .addFormDataPart("response_format", "json")

            languageHint?.let { bodyBuilder.addFormDataPart("language", it) }

            val request = Request.Builder()
                .url("https://api.openai.com/v1/audio/transcriptions")
                .addHeader("Authorization", "Bearer $apiKey")
                .post(bodyBuilder.build())
                .build()

            val response = client.newCall(request).execute()
            if (!response.isSuccessful) return null

            JSONObject(response.body?.string() ?: return null).optString("text")
                .takeIf { it.isNotBlank() }
        } catch (e: Exception) {
            null
        }
    }

    // ── Little-endian write helpers ────────────────────────────────────────────

    private fun ByteArrayOutputStream.writeInt32Le(v: Int) {
        write(v and 0xFF)
        write((v shr 8) and 0xFF)
        write((v shr 16) and 0xFF)
        write((v shr 24) and 0xFF)
    }

    private fun ByteArrayOutputStream.writeInt16Le(v: Int) {
        write(v and 0xFF)
        write((v shr 8) and 0xFF)
    }
}
