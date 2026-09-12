package com.affluentlabs.cairn

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Keep-screen-on for the recording view (Settings > Recording). A window
        // flag, cleared when the view goes away or the recording ends.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.affluentlabs.cairn/screen")
            .setMethodCallHandler { call, result ->
                if (call.method == "keepOn") {
                    val on = call.arguments as? Boolean ?: false
                    if (on) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
