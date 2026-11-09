package com.gestioncomida.gestioncomida_front

import io.flutter.embedding.android.FlutterFragmentActivity
import android.content.Intent

// FlutterFragmentActivity requerido por local_auth (BiometricPrompt).
class MainActivity: FlutterFragmentActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
