package com.example.aquanav

import android.util.Log
import com.chaquo.python.PyObject
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    private val CHANNEL = "celestial_navigation"
    private var bridgeService: PyObject? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize Python (once only)
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(this))
        }

        val py = Python.getInstance()

        // Initialize the bridge service
        try {
            val androidServiceModule = py.getModule("android_service")
            bridgeService = androidServiceModule.callAttr("get_service_instance")
            Log.d("CELESTIAL_NAV", "Bridge service initialized successfully")
        } catch (e: Exception) {
            Log.e("CELESTIAL_NAV", "Failed to initialize bridge service: ${e.message}")
        }

        // MethodChannel for celestial navigation
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "process_image" -> {
                        val imagePath = call.argument<String>("image_path") ?: ""
                        val altitudes = call.argument<Map<String, Double>>("altitudes")
                        val time = call.argument<String>("time")
                        val estimatedPosition = call.argument<Map<String, Double>>("estimated_position")

                        val data = mutableMapOf<String, Any?>()
                        data["image_path"] = imagePath
                        if (altitudes != null) data["altitudes"] = altitudes
                        if (time != null) data["time"] = time
                        if (estimatedPosition != null) data["estimated_position"] = estimatedPosition

                        val response = bridgeService?.callAttr("handle_request", "process_image", data)
                        result.success(response?.toJava(Map::class.java))
                    }

                    "calculate_from_names" -> {
                        val observations = call.argument<List<Map<String, Any>>>("observations") ?: emptyList()
                        val time = call.argument<String>("time")
                        val estimatedPosition = call.argument<Map<String, Double>>("estimated_position")

                        val data = mutableMapOf<String, Any?>()
                        data["observations"] = observations
                        if (time != null) data["time"] = time
                        if (estimatedPosition != null) data["estimated_position"] = estimatedPosition

                        val response = bridgeService?.callAttr("handle_request", "calculate_from_names", data)
                        result.success(response?.toJava(Map::class.java))
                    }

                    "list_stars" -> {
                        val minMagnitude = call.argument<Double>("min_magnitude") ?: 2.0

                        val data = mapOf("min_magnitude" to minMagnitude)
                        val response = bridgeService?.callAttr("handle_request", "list_stars", data)
                        result.success(response?.toJava(Map::class.java))
                    }

                    "get_star_info" -> {
                        val name = call.argument<String>("name")
                        val arabicName = call.argument<String>("arabic_name")

                        val data = mutableMapOf<String, Any?>()
                        if (name != null) data["name"] = name
                        if (arabicName != null) data["arabic_name"] = arabicName

                        val response = bridgeService?.callAttr("handle_request", "get_star_info", data)
                        result.success(response?.toJava(Map::class.java))
                    }

                    "calculate_position" -> {
                        val stars = call.argument<List<Map<String, Any>>>("stars") ?: emptyList()

                        val data = mapOf("stars" to stars)
                        val response = bridgeService?.callAttr("handle_request", "calculate_position", data)
                        result.success(response?.toJava(Map::class.java))
                    }

                    "detect_stars" -> {
                        val imagePath = call.argument<String>("image_path") ?: ""
                        val fovEstimate = call.argument<Double>("fov_estimate")

                        val data = mutableMapOf<String, Any?>()
                        data["image_path"] = imagePath
                        if (fovEstimate != null) data["fov_estimate"] = fovEstimate

                        val response = bridgeService?.callAttr("handle_request", "detect_stars", data)
                        result.success(response?.toJava(Map::class.java))
                    }

                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e("CELESTIAL_NAV", "Error handling ${call.method}: ${e.message}")
                result.error("CELESTIAL_ERROR", e.message, e.stackTraceToString())
            }
        }
    }
}
