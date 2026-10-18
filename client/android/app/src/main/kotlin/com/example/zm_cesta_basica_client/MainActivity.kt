package com.example.zm_cesta_basica_client

import io.flutter.embedding.android.FlutterActivity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zm_cesta_basica/printing_setup")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "supportsPrinting" -> result.success(
                        packageManager.hasSystemFeature(PackageManager.FEATURE_PRINTING) &&
                            getSystemService(Context.PRINT_SERVICE) != null
                    )
                    "openPrintSettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_PRINT_SETTINGS))
                            result.success(true)
                        } catch (_: ActivityNotFoundException) {
                            result.success(false)
                        } catch (_: SecurityException) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
