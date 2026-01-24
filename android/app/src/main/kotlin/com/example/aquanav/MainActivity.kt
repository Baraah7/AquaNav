package com.example.aquanav

import android.util.Log
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "celestial_navigation"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize Python (once only)
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(this))
        }

        // TEST: Run Python directly
        val py = Python.getInstance()
        val testModule = py.getModule("test")   // test.py
        val testResult = testModule.callAttr("hello")
        Log.d("PYTHON_TEST", testResult.toString())

        // MethodChannel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            val module = py.getModule("android_service")

            when (call.method) {
                "process_image" -> {
                    val path = call.argument<String>("image_path")
                    val res = module.callAttr("process_image", path)
                    result.success(res.toJava(Map::class.java))
                }
                else -> result.notImplemented()
            }
        }
    }
}
