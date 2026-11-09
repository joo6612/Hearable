package com.hearable.music

import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.Virtualizer
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.hearable.music/audio_effects"
    private val TAG = "HearableAudioFX"

    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var currentSessionId: Int = 0
    private var isTuningEnabled: Boolean = false

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initEffects" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0
                    initAudioEffects(sessionId)
                    result.success(true)
                }
                "setAppleSignatureTuning" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    val customBass = call.argument<Int>("bassStrength") ?: 700
                    val customVirtualizer = call.argument<Int>("virtualizerStrength") ?: 500
                    val success = applyAppleSignatureTuning(enabled, customBass, customVirtualizer)
                    result.success(success)
                }
                "setBassBoost" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    val strength = call.argument<Int>("strength") ?: 700
                    setBassBoostLevel(enabled, strength.toShort())
                    result.success(true)
                }
                "setVirtualizer" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    val strength = call.argument<Int>("strength") ?: 500
                    setVirtualizerLevel(enabled, strength.toShort())
                    result.success(true)
                }
                "setCustomBandLevel" -> {
                    val band = call.argument<Int>("band") ?: 0
                    val levelMb = call.argument<Int>("levelMb") ?: 0
                    setEqualizerBandLevel(band.toShort(), levelMb.toShort())
                    result.success(true)
                }
                "getAudioEffectsState" -> {
                    result.success(getEffectsStateMap())
                }
                "releaseEffects" -> {
                    releaseAudioEffects()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun initAudioEffects(sessionId: Int) {
        try {
            if (currentSessionId == sessionId && equalizer != null) {
                return
            }
            releaseAudioEffects()
            currentSessionId = sessionId
            Log.d(TAG, "Initializing AudioEffects on session $sessionId")

            equalizer = Equalizer(0, sessionId).apply {
                enabled = true
            }

            bassBoost = BassBoost(0, sessionId).apply {
                enabled = true
            }

            virtualizer = Virtualizer(0, sessionId).apply {
                enabled = true
            }

            if (isTuningEnabled) {
                applyAppleSignatureTuning(true, 700, 500)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing native audio effects: ${e.message}", e)
        }
    }

    private fun applyAppleSignatureTuning(enabled: Boolean, bassStrength: Int, virtualizerStrength: Int): Boolean {
        isTuningEnabled = enabled
        try {
            if (equalizer == null) {
                initAudioEffects(currentSessionId)
            }

            val eq = equalizer
            if (eq != null) {
                eq.enabled = enabled
                if (enabled) {
                    val minBand = eq.bandLevelRange[0]
                    val maxBand = eq.bandLevelRange[1]

                    // Target acoustic curve specifications:
                    // 60Hz: +3.5dB (+350mB)
                    // 250Hz: +1.5dB (+150mB)
                    // 1kHz: -1.0dB (-100mB)
                    // 4kHz: +2.0dB (+200mB)
                    // 12kHz: +3.0dB (+300mB)
                    val targets = listOf(
                        Pair(60 * 1000, 350),      // 60Hz
                        Pair(250 * 1000, 150),     // 250Hz
                        Pair(1000 * 1000, -100),   // 1kHz
                        Pair(4000 * 1000, 200),    // 4kHz
                        Pair(12000 * 1000, 300)    // 12kHz
                    )

                    val numBands = eq.numberOfBands.toInt()
                    for (b in 0 until numBands) {
                        val centerFreq = eq.getCenterFreq(b.toShort())
                        // Find closest target frequency
                        var closestTarget = targets[0]
                        var minDiff = abs(centerFreq - targets[0].first)
                        for (target in targets) {
                            val diff = abs(centerFreq - target.first)
                            if (diff < minDiff) {
                                minDiff = diff
                                closestTarget = target
                            }
                        }

                        val targetMb = closestTarget.second.coerceIn(minBand.toInt(), maxBand.toInt())
                        eq.setBandLevel(b.toShort(), targetMb.toShort())
                        Log.d(TAG, "Band $b ($centerFreq mHz) set to $targetMb mB (range: $minBand - $maxBand)")
                    }
                } else {
                    // Reset to flat
                    val numBands = eq.numberOfBands.toInt()
                    for (b in 0 until numBands) {
                        eq.setBandLevel(b.toShort(), 0)
                    }
                }
            }

            val bb = bassBoost
            if (bb != null && bb.strengthSupported) {
                bb.enabled = enabled
                if (enabled) {
                    val strength = bassStrength.coerceIn(0, 1000).toShort()
                    bb.setStrength(strength)
                }
            }

            val vz = virtualizer
            if (vz != null && vz.strengthSupported) {
                vz.enabled = enabled
                if (enabled) {
                    // Hardware Virtualizer: 50% strength (500/1000)
                    val strength = virtualizerStrength.coerceIn(0, 1000).toShort()
                    vz.setStrength(strength)
                }
            }

            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error applying Apple signature tuning: ${e.message}", e)
            return false
        }
    }

    private fun setBassBoostLevel(enabled: Boolean, strength: Short) {
        try {
            bassBoost?.let {
                it.enabled = enabled
                if (enabled && it.strengthSupported) {
                    it.setStrength(strength.coerceIn(0, 1000))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting bass boost: ${e.message}")
        }
    }

    private fun setVirtualizerLevel(enabled: Boolean, strength: Short) {
        try {
            virtualizer?.let {
                it.enabled = enabled
                if (enabled && it.strengthSupported) {
                    it.setStrength(strength.coerceIn(0, 1000))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting virtualizer: ${e.message}")
        }
    }

    private fun setEqualizerBandLevel(band: Short, levelMb: Short) {
        try {
            equalizer?.let {
                val clamped = levelMb.coerceIn(it.bandLevelRange[0], it.bandLevelRange[1])
                it.setBandLevel(band, clamped)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting equalizer band: ${e.message}")
        }
    }

    private fun getEffectsStateMap(): Map<String, Any> {
        val map = mutableMapOf<String, Any>()
        try {
            map["isTuningEnabled"] = isTuningEnabled
            equalizer?.let { eq ->
                map["numberOfBands"] = eq.numberOfBands.toInt()
                map["minLevel"] = eq.bandLevelRange[0].toInt()
                map["maxLevel"] = eq.bandLevelRange[1].toInt()
                val bands = mutableListOf<Map<String, Any>>()
                for (b in 0 until eq.numberOfBands) {
                    bands.add(
                        mapOf(
                            "band" to b,
                            "centerFreq" to eq.getCenterFreq(b.toShort()),
                            "level" to eq.getBandLevel(b.toShort()).toInt()
                        )
                    )
                }
                map["bands"] = bands
            }
            bassBoost?.let { bb ->
                map["bassBoostEnabled"] = bb.enabled
                map["bassBoostStrength"] = if (bb.strengthSupported) bb.roundedStrength.toInt() else 0
            }
            virtualizer?.let { vz ->
                map["virtualizerEnabled"] = vz.enabled
                map["virtualizerStrength"] = if (vz.strengthSupported) vz.roundedStrength.toInt() else 0
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error querying audio effects state: ${e.message}")
        }
        return map
    }

    private fun releaseAudioEffects() {
        try {
            equalizer?.release()
            equalizer = null
            bassBoost?.release()
            bassBoost = null
            virtualizer?.release()
            virtualizer = null
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing audio effects: ${e.message}")
        }
    }

    override fun onDestroy() {
        releaseAudioEffects()
        super.onDestroy()
    }
}

