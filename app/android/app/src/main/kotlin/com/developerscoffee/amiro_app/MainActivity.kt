package com.developerscoffee.amiro_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "amiro/nfc_hce"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "writeIdentityPayload" -> {
                        val uri = call.argument<String>("uri")
                        AmiroHceService.currentPayload = uri
                        result.success(null)
                    }
                    "stopEmulating" -> {
                        AmiroHceService.currentPayload = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
