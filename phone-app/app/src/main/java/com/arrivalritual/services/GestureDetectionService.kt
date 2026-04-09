package com.arrivalritual.services

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import kotlin.math.atan2
import kotlin.math.sqrt

/**
 * GestureDetectionService
 *
 * Listens to the accelerometer and gyroscope to detect a "camera-lift" gesture:
 * the motion of raising the phone from a resting/pocket position to eye-level
 * with the camera pointed outward (as if about to take a photo).
 *
 * Detection algorithm:
 *   - The accelerometer pitch angle is derived from (ax, ay, az).
 *   - "Hanging" position ≈ pitch near 0° (gravity mostly on -y axis).
 *   - "Camera up" position ≈ pitch > LIFT_THRESHOLD_DEG (gravity shifts to -z axis).
 *   - A lift is confirmed when the pitch crosses the threshold AND the previous
 *     position was below it, within a short debounce window.
 *
 * Usage:
 *   1. Call [start] when entering a restricted scenario.
 *   2. Provide [onCameraLift] callback — fires once per detected gesture.
 *   3. Call [stop] when leaving the restricted scenario.
 *
 * Only active in restricted zones (TEMPLE, IMMIGRATION) — the ViewModel controls this.
 */
class GestureDetectionService(private val context: Context) {

    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val gyroscope     = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)

    private var onCameraLift: (() -> Unit)? = null
    private var isRunning = false

    // Smoothed gravity vector (low-pass filtered from accelerometer)
    private val gravity = FloatArray(3)
    private val alpha   = 0.8f   // low-pass filter coefficient

    // Gyroscope: track angular velocity in x-axis (tilt forward/backward)
    private var gyroX = 0f

    // State tracking for lift detection
    private var wasInRestingPosition = false
    private var lastLiftTime = 0L

    companion object {
        /** Pitch angle above which we consider the phone "raised to camera position" */
        private const val LIFT_THRESHOLD_DEG = 50.0

        /** Minimum pitch angle below which we consider the phone "at rest" */
        private const val REST_THRESHOLD_DEG = 20.0

        /** Minimum gyro angular velocity (rad/s) confirming active upward motion */
        private const val GYRO_LIFT_MIN = 0.8f

        /** Debounce: minimum ms between two lift events */
        private const val DEBOUNCE_MS = 3000L
    }

    private val listener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            when (event.sensor.type) {
                Sensor.TYPE_ACCELEROMETER -> handleAccelerometer(event.values)
                Sensor.TYPE_GYROSCOPE     -> handleGyroscope(event.values)
            }
        }
        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }

    /** Start listening for camera-lift gestures. [callback] fires on each detection. */
    fun start(callback: () -> Unit) {
        if (isRunning) return
        onCameraLift = callback
        isRunning    = true

        val delay = SensorManager.SENSOR_DELAY_GAME
        accelerometer?.let { sensorManager.registerListener(listener, it, delay) }
        gyroscope    ?.let { sensorManager.registerListener(listener, it, delay) }
    }

    /** Stop sensor listening. Call when leaving a restricted scenario. */
    fun stop() {
        if (!isRunning) return
        sensorManager.unregisterListener(listener)
        onCameraLift = null
        isRunning    = false
        wasInRestingPosition = false
    }

    // ── Sensor processing ──────────────────────────────────────────────────────

    private fun handleAccelerometer(values: FloatArray) {
        // Low-pass filter to isolate gravity
        gravity[0] = alpha * gravity[0] + (1 - alpha) * values[0]
        gravity[1] = alpha * gravity[1] + (1 - alpha) * values[1]
        gravity[2] = alpha * gravity[2] + (1 - alpha) * values[2]

        val pitch = calculatePitchDeg()

        // Track resting position
        if (pitch < REST_THRESHOLD_DEG) {
            wasInRestingPosition = true
        }

        // Detect lift: was resting, now above threshold, with upward gyro motion, debounced
        if (wasInRestingPosition
            && pitch > LIFT_THRESHOLD_DEG
            && gyroX < -GYRO_LIFT_MIN  // negative x = phone tilting backward (camera up)
            && (System.currentTimeMillis() - lastLiftTime) > DEBOUNCE_MS
        ) {
            lastLiftTime = System.currentTimeMillis()
            wasInRestingPosition = false
            onCameraLift?.invoke()
        }
    }

    private fun handleGyroscope(values: FloatArray) {
        gyroX = values[0] // rotation around x-axis (tilt forward/back)
    }

    /**
     * Calculates the pitch angle of the phone in degrees.
     * 0° = hanging vertically, 90° = lying flat face-up, used as camera-up proxy.
     */
    private fun calculatePitchDeg(): Double {
        val ax = gravity[0].toDouble()
        val ay = gravity[1].toDouble()
        val az = gravity[2].toDouble()
        // Angle between the gravity vector and the y-z plane
        return Math.toDegrees(atan2(ax, sqrt(ay * ay + az * az)))
    }
}
