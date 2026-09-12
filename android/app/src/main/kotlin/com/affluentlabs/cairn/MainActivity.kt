package com.affluentlabs.cairn

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var intentChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Keep-screen-on for the recording view (Settings > Recording). A window
        // flag, cleared when the view goes away or the recording ends.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.affluentlabs.cairn/screen")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "keepOn" -> {
                        val on = call.arguments as? Boolean ?: false
                        if (on) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                        result.success(null)
                    }
                    // FLAG_SECURE while the sync passphrase is on screen: no
                    // screenshots, no recents thumbnail (security audit finding 14).
                    "secure" -> {
                        val on = call.arguments as? Boolean ?: false
                        if (on) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // "Open with Cairn" for .gpx files (the VIEW intent filter in the
        // manifest). Dart asks for the launch intent's file once at startup;
        // a file opened while the app is running arrives through onNewIntent.
        intentChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.affluentlabs.cairn/intent")
        intentChannel?.setMethodCallHandler { call, result ->
            if (call.method == "initialFile") {
                result.success(fileFromIntent(intent))
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val file = fileFromIntent(intent) ?: return
        intentChannel?.invokeMethod("file", file)
    }

    /** Reads the file a VIEW intent points at: {name, bytes}, capped at 20 MB. */
    private fun fileFromIntent(intent: Intent?): Map<String, Any>? {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return null
        val uri: Uri = intent.data ?: return null
        return try {
            val resolver = contentResolver
            var name = uri.lastPathSegment ?: "import.gpx"
            if (uri.scheme == "content") {
                resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                    if (c.moveToFirst()) {
                        val i = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (i >= 0) c.getString(i)?.let { name = it }
                    }
                }
            }
            val bytes = resolver.openInputStream(uri)?.use { it.readBytes() } ?: return null
            if (bytes.size > 20 * 1024 * 1024) return null
            mapOf("name" to name, "bytes" to bytes)
        } catch (e: Exception) {
            null
        }
    }
}
