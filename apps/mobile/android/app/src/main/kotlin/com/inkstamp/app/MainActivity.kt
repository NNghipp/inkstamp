package com.inkstamp.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val widgetChannel = "com.inkstamp.app/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            widgetChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateLatestStamp" -> {
                    val stampId = call.argument<String>("stampId")
                    val senderName = call.argument<String>("senderName")
                    val thumbnailPath = call.argument<String>("thumbnailPath")
                    getSharedPreferences("inkstamp_widget", MODE_PRIVATE)
                        .edit()
                        .putString("latest_stamp_id", stampId)
                        .putString("latest_sender", senderName)
                        .putString("latest_thumbnail_path", thumbnailPath)
                        .apply()
                    refreshWidget()
                    result.success(null)
                }
                "clearWidget" -> {
                    getSharedPreferences("inkstamp_widget", MODE_PRIVATE)
                        .edit()
                        .clear()
                        .apply()
                    refreshWidget()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun refreshWidget() {
        InkstampWidgetReceiver.updateAll(this)
    }
}
