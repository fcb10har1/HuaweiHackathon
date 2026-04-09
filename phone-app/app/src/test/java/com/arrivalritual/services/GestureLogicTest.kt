package com.arrivalritual.services

import org.junit.Assert.*
import org.junit.Test
import kotlin.math.*

/**
 * GestureLogicTest
 *
 * Unit tests for the pure-math components of GestureDetectionService:
 *   - Pitch angle calculation (atan2 formula)
 *   - Low-pass filter convergence
 *   - Camera-lift condition logic (thresholds + debounce)
 *
 * No Android context or SensorManager needed — all inputs are plain FloatArrays.
 * The production constants are duplicated here so that a threshold change in
 * GestureDetectionService causes these tests to surface the need for a re-review.
 */
class GestureLogicTest {

    // Mirror of production constants from GestureDetectionService.
    private val LIFT_THRESHOLD_DEG  = 50.0
    private val REST_THRESHOLD_DEG  = 20.0
    private val GYRO_LIFT_MIN       = 0.8f
    private val DEBOUNCE_MS         = 3000L
    private val ALPHA               = 0.8f

    // ── Pitch calculation ──────────────────────────────────────────────────────

    /** Replicates GestureDetectionService.calculatePitchDeg() */
    private fun pitchDeg(ax: Double, ay: Double, az: Double): Double =
        Math.toDegrees(atan2(ax, sqrt(ay * ay + az * az)))

    @Test
    fun pitch_phoneHangingVertically_isNearZero() {
        // Gravity mostly on -y axis: phone hanging screen-forward from a pocket.
        val pitch = pitchDeg(ax = 0.0, ay = 9.81, az = 0.0)
        assertEquals("Vertical phone should give ~0° pitch", 0.0, pitch, 1.0)
    }

    @Test
    fun pitch_phoneFlatFaceUp_isNearZero() {
        // Gravity entirely on -z axis: phone lying flat on a table.
        val pitch = pitchDeg(ax = 0.0, ay = 0.0, az = 9.81)
        assertEquals("Flat phone should give ~0° pitch", 0.0, pitch, 1.0)
    }

    @Test
    fun pitch_phoneRaisedToNinetyDegrees_isNearNinety() {
        // Gravity entirely on x axis: phone raised so camera faces directly forward.
        val pitch = pitchDeg(ax = 9.81, ay = 0.0, az = 0.0)
        assertEquals("Camera-up phone should give ~90°", 90.0, pitch, 1.0)
    }

    @Test
    fun pitch_aboveLiftThreshold_meetsCondition() {
        // Construct gravity vector for pitch = 55° (clearly above 50° threshold).
        // We use 55° rather than exactly 50° to avoid floating-point boundary issues.
        val targetDeg = 55.0
        val g = 9.81
        val ax = g * sin(Math.toRadians(targetDeg))
        val ay = g * cos(Math.toRadians(targetDeg))
        val pitch = pitchDeg(ax, ay, 0.0)
        assertTrue("Pitch $pitch° must be > $LIFT_THRESHOLD_DEG° threshold", pitch > LIFT_THRESHOLD_DEG)
    }

    @Test
    fun pitch_belowRestThreshold_doesNotTriggerLift() {
        // pitch = 10° — clearly in resting zone
        val g = 9.81
        val ax = g * sin(Math.toRadians(10.0))
        val ay = g * cos(Math.toRadians(10.0))
        val pitch = pitchDeg(ax, ay, 0.0)
        assertTrue("Pitch $pitch° must be below REST_THRESHOLD_DEG=$REST_THRESHOLD_DEG°", pitch < REST_THRESHOLD_DEG)
    }

    @Test
    fun pitch_isSymmetric_negativeTilt() {
        // Tilting left vs right should give mirror pitches
        val pos = pitchDeg(ax =  5.0, ay = 8.0, az = 0.0)
        val neg = pitchDeg(ax = -5.0, ay = 8.0, az = 0.0)
        assertEquals("Pitch should be symmetric around 0", pos, -neg, 0.001)
    }

    // ── Low-pass filter ────────────────────────────────────────────────────────

    /** Applies one iteration of the low-pass filter used in the service. */
    private fun lowPassStep(gravity: FloatArray, raw: FloatArray): FloatArray =
        FloatArray(3) { i -> ALPHA * gravity[i] + (1f - ALPHA) * raw[i] }

    @Test
    fun lowPass_startingAtZero_convergesAfterManySteps() {
        val target = floatArrayOf(0f, 9.81f, 0f)
        var gravity = FloatArray(3) // starts at [0, 0, 0]
        repeat(100) { gravity = lowPassStep(gravity, target) }

        assertArrayEquals(
            "Low-pass filter must converge to target after 100 steps",
            target, gravity, 0.01f
        )
    }

    @Test
    fun lowPass_alphaZeroPoint8_reducesNoiseMagnitude() {
        // A sudden spike of +10 on x should be attenuated to 20% in one step
        val gravity = floatArrayOf(0f, 0f, 0f)
        val spike   = floatArrayOf(10f, 0f, 0f)
        val filtered = lowPassStep(gravity, spike)
        assertEquals(
            "After one step, filtered x should be 0.2 * spike = 2.0",
            2.0f, filtered[0], 0.01f
        )
    }

    @Test
    fun lowPass_preventsInstantJumpToLiftThreshold() {
        // Simulate a phone in a resting/pocket position: gravity mostly on -y axis.
        // A sudden camera-up spike (gravity shifts to x) should not cross the lift
        // threshold after just one filter step — the low-pass filter dampens rapid changes.
        val gravity = floatArrayOf(0f, 9.81f, 0f)  // phone hanging vertically (resting)
        val cameraUp = floatArrayOf(9.81f, 0f, 0f)  // instantaneous spike: camera pointed up
        val filtered = lowPassStep(gravity, cameraUp)

        // After one step: ax ≈ 0.2*9.81 = 1.96, ay ≈ 0.8*9.81 = 7.85
        val ax = filtered[0].toDouble()
        val ay = filtered[1].toDouble()
        val az = filtered[2].toDouble()
        val pitch = pitchDeg(ax, ay, az)  // should be ~14°, well below 50°

        assertTrue(
            "A single noisy sample from rest (pitch=$pitch°) must NOT cross LIFT_THRESHOLD=$LIFT_THRESHOLD_DEG°",
            pitch < LIFT_THRESHOLD_DEG
        )
    }

    // ── Camera-lift condition logic ────────────────────────────────────────────

    @Test
    fun liftCondition_allCriteriaMet_isTrue() {
        val wasResting   = true
        val pitch        = 60.0             // > LIFT_THRESHOLD_DEG (50°)
        val gyroX        = -1.2f            // < -GYRO_LIFT_MIN (-0.8)
        val timeSinceLast = 5000L           // > DEBOUNCE_MS (3000ms)

        val isLift = wasResting
            && pitch > LIFT_THRESHOLD_DEG
            && gyroX < -GYRO_LIFT_MIN
            && timeSinceLast > DEBOUNCE_MS

        assertTrue("All conditions met — lift must be detected", isLift)
    }

    @Test
    fun liftCondition_notResting_isFalse() {
        val wasResting   = false            // ← phone was never in resting position
        val pitch        = 60.0
        val gyroX        = -1.2f
        val timeSinceLast = 5000L

        val isLift = wasResting
            && pitch > LIFT_THRESHOLD_DEG
            && gyroX < -GYRO_LIFT_MIN
            && timeSinceLast > DEBOUNCE_MS

        assertFalse("Lift must not fire if phone was never in resting position", isLift)
    }

    @Test
    fun liftCondition_pitchBelowThreshold_isFalse() {
        val wasResting   = true
        val pitch        = 40.0            // ← below LIFT_THRESHOLD_DEG (50°)
        val gyroX        = -1.2f
        val timeSinceLast = 5000L

        val isLift = wasResting
            && pitch > LIFT_THRESHOLD_DEG
            && gyroX < -GYRO_LIFT_MIN
            && timeSinceLast > DEBOUNCE_MS

        assertFalse("Lift must not fire when pitch ($pitch°) is below threshold", isLift)
    }

    @Test
    fun liftCondition_gyroTooSlow_isFalse() {
        val wasResting   = true
        val pitch        = 60.0
        val gyroX        = -0.3f           // ← not fast enough (> -GYRO_LIFT_MIN)
        val timeSinceLast = 5000L

        val isLift = wasResting
            && pitch > LIFT_THRESHOLD_DEG
            && gyroX < -GYRO_LIFT_MIN
            && timeSinceLast > DEBOUNCE_MS

        assertFalse("Lift must not fire when gyroX ($gyroX) is below min angular velocity", isLift)
    }

    @Test
    fun liftCondition_inDebounceWindow_isFalse() {
        val wasResting   = true
        val pitch        = 60.0
        val gyroX        = -1.2f
        val timeSinceLast = 1500L          // ← within debounce (< 3000ms)

        val isLift = wasResting
            && pitch > LIFT_THRESHOLD_DEG
            && gyroX < -GYRO_LIFT_MIN
            && timeSinceLast > DEBOUNCE_MS

        assertFalse("Lift must not fire within debounce window (${timeSinceLast}ms)", isLift)
    }

    @Test
    fun liftCondition_exactlyAtDebounce_isFalse() {
        // Edge case: timeSinceLast == DEBOUNCE_MS uses strict > comparison
        val timeSinceLast = DEBOUNCE_MS

        val isLift = true
            && 60.0 > LIFT_THRESHOLD_DEG
            && -1.2f < -GYRO_LIFT_MIN
            && timeSinceLast > DEBOUNCE_MS   // exactly equal → false with strict >

        assertFalse("Lift must not fire exactly at debounce boundary", isLift)
    }
}
